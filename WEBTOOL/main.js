const state = {
  metadata: null, pyodide: null, api: null, country: "de", product: "de_purchase",
  geography: null, boundaries: null, geographyCache: {}, boundaryCache: {}, paths: null,
  areaLayer: null, projection: null, chart: null, year: 2025, years: [], values: {}, selected: "10117",
};

const citySets = {
  de: [
    {name:"Berlin",lon:13.405,lat:52.52},{name:"Hamburg",lon:9.9937,lat:53.5511},
    {name:"Munich",lon:11.582,lat:48.1351},{name:"Cologne",lon:6.9603,lat:50.9375,anchor:"end"},
    {name:"Frankfurt",lon:8.6821,lat:50.1109},{name:"Stuttgart",lon:9.1829,lat:48.7758},
    {name:"Düsseldorf",lon:6.7735,lat:51.2277,anchor:"end"},{name:"Leipzig",lon:12.3731,lat:51.3397},
    {name:"Dortmund",lon:7.4653,lat:51.5136},{name:"Essen",lon:7.0123,lat:51.4556},
    {name:"Bremen",lon:8.8017,lat:53.0793},{name:"Dresden",lon:13.7373,lat:51.0504},
    {name:"Hanover",lon:9.732,lat:52.3759},{name:"Nuremberg",lon:11.0767,lat:49.4521},
    {name:"Duisburg",lon:6.7623,lat:51.4344,anchor:"end"},
  ],
  gb: [
    {name:"London",lon:-0.1276,lat:51.5072},{name:"Birmingham",lon:-1.8904,lat:52.4862},
    {name:"Leeds",lon:-1.5491,lat:53.8008},{name:"Liverpool",lon:-2.9916,lat:53.4084,anchor:"end"},
    {name:"Sheffield",lon:-1.4701,lat:53.3811},{name:"Manchester",lon:-2.2426,lat:53.4808,anchor:"end"},
    {name:"Bristol",lon:-2.5879,lat:51.4545,anchor:"end"},{name:"Leicester",lon:-1.1398,lat:52.6369},
    {name:"Coventry",lon:-1.5106,lat:52.4068},{name:"Bradford",lon:-1.7594,lat:53.796,anchor:"end"},
    {name:"Cardiff",lon:-3.1791,lat:51.4816,anchor:"end"},{name:"Nottingham",lon:-1.1581,lat:52.9548},
    {name:"Newcastle",lon:-1.6178,lat:54.9783},{name:"Stoke-on-Trent",lon:-2.1794,lat:53.0027,anchor:"end"},
    {name:"Southampton",lon:-1.4044,lat:50.9097},
  ],
};

const colors = ["#f3f0e9", "#e3dccd", "#cfc1a7", "#b49f7c", "#917956", "#65523a"];
const defaults = {de:"10117", gb:"E01000001"};
const $ = (id) => document.getElementById(id);
const countryInfo = () => state.metadata.countries[state.country];
const productInfo = () => state.metadata.products[state.product];

function formatValue(value) {
  if (value == null) return "No estimate";
  return new Intl.NumberFormat("en-GB", {maximumFractionDigits: state.product === "de_rent" ? 2 : 0}).format(value);
}

async function pythonJson(functionName, ...args) {
  const fn = state.api.get(functionName);
  try { return JSON.parse(fn(...args)); } finally { fn.destroy(); }
}

async function fetchGzipJson(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`Could not fetch ${url}`);
  const stream = response.body.pipeThrough(new DecompressionStream("gzip"));
  return JSON.parse(await new Response(stream).text());
}

async function boot() {
  try {
    const base = new URL(".", window.location.href);
    state.metadata = await fetch(new URL("data/metadata.json", base)).then((r) => r.json());
    state.pyodide = await loadPyodide();
    state.pyodide.runPython(await fetch(new URL("app.py", base)).then((r) => r.text()));
    state.api = state.pyodide.globals;
    const urls = Object.fromEntries(Object.entries(state.metadata.products).map(([key,item]) => [key,new URL(item.file,base).href]));
    const loadData = state.api.get("load_data");
    try { await loadData(JSON.stringify(urls)); } finally { loadData.destroy(); }
    buildControls(); buildChart(); bindEvents();
    await switchCountry("de");
  } catch (error) {
    console.error(error); setReady("The atlas could not load. Please refresh or open it in a new tab.", true);
  }
}

function buildControls() {
  for (const [key,item] of Object.entries(state.metadata.countries)) $("country").add(new Option(item.label,key));
  for (const id of ["country","product","year","area-search","search","map-opacity","reset-map"]) $(id).disabled = false;
}

function populateProducts() {
  const select = $("product"); select.replaceChildren();
  for (const [key,item] of Object.entries(state.metadata.products)) {
    if (item.country === state.country) select.add(new Option(item.label,key));
  }
  state.product = select.options[0].value; select.value = state.product;
}

async function loadGeography(country) {
  const base = new URL(".",window.location.href); const info = state.metadata.countries[country];
  if (!state.geographyCache[country]) state.geographyCache[country] = await fetchGzipJson(new URL(info.geography,base));
  if (!state.boundaryCache[country]) state.boundaryCache[country] = await fetchGzipJson(new URL(info.boundaries,base));
  state.geography = state.geographyCache[country]; state.boundaries = state.boundaryCache[country];
}

async function switchCountry(country) {
  setReady("Loading geography…"); state.country = country; $("country").value = country;
  populateProducts(); await loadGeography(country); buildMap();
  const info = countryInfo();
  $("search-label").textContent = `Find ${info.area_label.toLowerCase()}`;
  $("area-search").placeholder = info.search_placeholder;
  state.selected = defaults[country];
  await updateProduct();
  setReady(`Ready · ${new Intl.NumberFormat("en-GB").format(info.count)} ${info.area_label === "Postcode" ? "postcode areas" : "LSOAs"}`);
}

function buildMap() {
  const container = d3.select("#map"); container.select("svg").remove();
  const width = container.node().clientWidth, height = container.node().clientHeight;
  const svg = container.insert("svg",":first-child").attr("viewBox",[0,0,width,height]);
  const tileLayer = svg.append("g").attr("class","map-tiles"), layer = svg.append("g");
  state.projection = d3.geoMercator().fitExtent([[18,16],[width-18,height-16]],state.geography);
  const path = d3.geoPath(state.projection);
  state.areaLayer = layer.append("g").attr("class","area-layer").style("opacity",Number($("map-opacity").value)/100);
  state.paths = state.areaLayer.selectAll("path").data(state.geography.features).join("path")
    .attr("class","area-shape").attr("aria-hidden","true").attr("data-area",(d)=>d.properties.area).attr("d",path)
    .on("pointermove",showTooltip).on("pointerleave",()=>$("tooltip").hidden=true).on("click",(_,d)=>selectArea(d.properties.area));
  layer.append("g").attr("class","boundaries").selectAll("path").data(state.boundaries.features).join("path").attr("d",path);

  const cityLayer = layer.append("g").attr("class","city-labels");
  const cities = cityLayer.selectAll("g").data(citySets[state.country]).join("g").attr("class","city-label")
    .attr("transform",(d)=>`translate(${state.projection([d.lon,d.lat]).join(",")})`);
  cities.append("circle").attr("r",1.8);
  cities.append("text").attr("text-anchor",(d)=>d.anchor??"start").text((d)=>d.name);

  function updateCityLabels(transform) {
    const fontSize=9.5,markerGap=4.5,labelHeight=12,padding=2,occupied=[];
    cities.each(function(d){
      const group=d3.select(this),[mapX,mapY]=state.projection([d.lon,d.lat]),[screenX,screenY]=transform.apply([mapX,mapY]);
      const width=d.name.length*fontSize*.56,isLeft=d.anchor==="end",left=isLeft?screenX-markerGap-width:screenX+markerGap;
      const box={left:left-padding,right:left+width+padding,top:screenY-labelHeight/2-padding,bottom:screenY+labelHeight/2+padding};
      const overlaps=occupied.some((o)=>!(box.right<o.left||box.left>o.right||box.bottom<o.top||box.top>o.bottom));
      group.select("text").classed("label-hidden",overlaps).attr("x",(isLeft?-markerGap:markerGap)/transform.k).attr("y",0).style("font-size",`${fontSize/transform.k}px`);
      group.select("circle").attr("r",1.8/transform.k); if(!overlaps) occupied.push(box);
    });
  }
  updateCityLabels(d3.zoomIdentity);

  const tiler=d3.tile().extent([[0,0],[width,height]]);
  function renderTiles(transform){
    const tiles=tiler.scale(state.projection.scale()*2*Math.PI*transform.k).translate(transform.apply(state.projection.translate()))();
    tileLayer.selectAll("image").data(tiles,(d)=>d.join("/")).join("image")
      .attr("x",(d)=>(d[0]+tiles.translate[0])*tiles.scale).attr("y",(d)=>(d[1]+tiles.translate[1])*tiles.scale)
      .attr("width",tiles.scale+.5).attr("height",tiles.scale+.5).attr("href",(d)=>`https://tile.openstreetmap.org/${d[2]}/${d[0]}/${d[1]}.png`);
  }
  renderTiles(d3.zoomIdentity);
  const zoom=d3.zoom().scaleExtent([1,28]).on("zoom",(event)=>{renderTiles(event.transform);layer.attr("transform",event.transform);updateCityLabels(event.transform);});
  svg.call(zoom); state.resetZoom=()=>svg.transition().duration(450).call(zoom.transform,d3.zoomIdentity);
}

function buildChart() {
  state.chart=new Chart($("history-chart"),{type:"line",data:{labels:[],datasets:[{data:[],borderColor:"#857251",backgroundColor:"rgba(133,114,81,.12)",borderWidth:2.5,pointRadius:2.5,pointHoverRadius:5,tension:.18,spanGaps:false,fill:true}]},options:{maintainAspectRatio:false,plugins:{legend:{display:false},tooltip:{callbacks:{label:(ctx)=>`${formatValue(ctx.raw)} ${productInfo().unit}`}}},scales:{x:{grid:{display:false},ticks:{maxRotation:0,autoSkipPadding:14}},y:{beginAtZero:false,grid:{color:"#e7e3da"},ticks:{callback:(v)=>formatValue(v)}}}}});
}

function bindEvents() {
  $("country").addEventListener("change",(e)=>switchCountry(e.target.value));
  $("product").addEventListener("change",async(e)=>{state.product=e.target.value;await updateProduct();});
  $("year").addEventListener("input",(e)=>{$("year-label").textContent=e.target.value;});
  $("year").addEventListener("change",async(e)=>{state.year=Number(e.target.value);await updateMap();});
  $("search").addEventListener("click",searchArea); $("area-search").addEventListener("keydown",(e)=>{if(e.key==="Enter")searchArea();});
  $("area-search").addEventListener("input",(e)=>{e.target.value=state.country==="de"?e.target.value.replace(/\D/g,"").slice(0,5):e.target.value.toUpperCase().replace(/\s/g,"").slice(0,9);});
  $("map-opacity").addEventListener("input",(e)=>{const opacity=Number(e.target.value);$("opacity-label").textContent=`${opacity}%`;state.areaLayer.style("opacity",opacity/100);});
  $("reset-map").addEventListener("click",()=>state.resetZoom());
}

async function updateProduct() {
  state.years=await pythonJson("available_years",state.product); const slider=$("year");
  slider.min=Math.min(...state.years); slider.max=Math.max(...state.years); state.year=Math.max(...state.years); slider.value=state.year;
  $("year-label").textContent=state.year; $("map-kicker").textContent=productInfo().label;
  updateContext(); await updateMap(); await selectArea(state.selected);
}

function updateContext() {
  const reef=state.country==="gb";
  $("fact-one-label").textContent=reef?"Standard error":"Transactions"; $("fact-two-label").textContent=reef?"Geography":"Within";
  $("data-note").textContent=reef?"LSE-REEF estimates cover lower-layer super output areas in England and Wales from 2010 to 2020.":"The AHS estimates use German residential listings and cover postcode areas from 2007 to 2025.";
  $("source-note").innerHTML=reef?"<p><strong>LSE-REEF Property Price Index.</strong> Data: Ahlfeldt, Carozzi &amp; Makovsky (2023), <em>A micro-geographic house price index for England and Wales</em>. Values are model-based estimates and should not be interpreted as valuations of individual properties.</p>":"<p><strong>AHS Property Price Index.</strong> Data: Ahlfeldt, Heblich &amp; Seidel (2023), <em>Micro-geographic property price and rent indices</em>. Values are model-based estimates and should not be interpreted as valuations of individual properties.</p>";
}

async function updateMap() {
  state.values=await pythonJson("snapshot",state.product,state.year);
  const values=Object.values(state.values).filter(Number.isFinite).sort((a,b)=>a-b),low=d3.quantile(values,.05),high=d3.quantile(values,.95);
  state.color=d3.scaleQuantize([low,high],colors); state.paths.attr("fill",(d)=>state.values[d.properties.area]==null?"#ddd9cf":state.color(state.values[d.properties.area]));
  $("map-title").textContent=`Price level in ${state.year}`; drawLegend(low,high);
  if(state.selected) updateSelectedYear(await pythonJson("history",state.product,state.selected));
}

function drawLegend(low,high) {
  const legend=$("legend");legend.replaceChildren();const title=document.createElement("span");title.className="legend-title";title.textContent=productInfo().unit;
  legend.append(title,Object.assign(document.createElement("span"),{className:"legend-value",textContent:formatValue(low)}));
  for(const color of colors){const swatch=document.createElement("span");swatch.className="legend-swatch";swatch.style.background=color;legend.append(swatch);}
  legend.append(Object.assign(document.createElement("span"),{className:"legend-value",textContent:formatValue(high)}));
}

function showTooltip(event,feature) {
  const area=feature.properties.area,value=state.values[area],label=countryInfo().area_label,name=feature.properties.name;
  $("tooltip").innerHTML=`<strong>${label} ${area}</strong>${name?`<br>${name}`:""}<br>${formatValue(value)}${value==null?"":` ${productInfo().unit}`}`;
  $("tooltip").style.left=`${event.clientX+14}px`;$("tooltip").style.top=`${event.clientY+12}px`;$("tooltip").hidden=false;
}

async function selectArea(area) {
  const history=await pythonJson("history",state.product,area);if(!history.length)return;
  state.selected=area;$("area-search").value=area;$("selected-area").textContent=`${countryInfo().area_label} ${area}`;
  $("selected-name").textContent=history[0].name||"";state.paths.classed("selected",(d)=>d.properties.area===area);
  state.chart.data.labels=history.map((row)=>row.year);state.chart.data.datasets[0].data=history.map((row)=>row.value);state.chart.update();updateSelectedYear(history);
}

function updateSelectedYear(history) {
  const row=history.find((item)=>item.year===state.year),reef=state.country==="gb";
  $("selected-value").textContent=row?.value==null?"No estimate":formatValue(row.value);
  $("selected-unit").textContent=row?.value==null?`${productInfo().label}, ${state.year}`:`${productInfo().unit} · ${state.year}`;
  $("fact-one").textContent=reef?(row?.se==null?"—":formatValue(row.se)):(row?.obs==null?"—":new Intl.NumberFormat("en-GB").format(row.obs));
  $("fact-two").textContent=reef?"LSOA":(row?.radius==null?"—":`${formatValue(row.radius)} km`);
}

function searchArea() {
  let area=$("area-search").value.trim().toUpperCase();if(state.country==="de")area=area.padStart(5,"0");
  if(!state.geography.features.some((feature)=>feature.properties.area===area)){setReady(`${countryInfo().area_label} not found`,true);return;}
  selectArea(area);setReady(`Ready · ${new Intl.NumberFormat("en-GB").format(countryInfo().count)} ${countryInfo().area_label==="Postcode"?"postcode areas":"LSOAs"}`);
}

function setReady(message,error=false){$("status").className=`status ${error?"error":"ready"}`;$("status").textContent=message;}
window.addEventListener("DOMContentLoaded",boot);
