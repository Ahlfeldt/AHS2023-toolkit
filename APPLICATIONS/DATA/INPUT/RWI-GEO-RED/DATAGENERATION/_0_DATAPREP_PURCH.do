********************************************************************************
* (C) GABRIEL M AHLFELDT, 2020
* FOR STATA 16
********************************************************************************
* GENERATING A PROPERTY PRICE INDEX ADJUSTED FOR ATTRIBUTES AND LOCATION

// THIS IS THE BRIDGE CODE USING RWI DATA ACCORDING TO 2022 ORGANIZATION


local waves = $version +5

use "$origin\WK_SUF_ohneText\WK_SUF_ohneText1", clear
forvalues i= 2/`waves' {
	append using "$origin\WK_SUF_ohneText\WK_SUF_ohneText`i'"
}
forvalues i= 1/`waves'  {
	append using "$origin\HK_SUF_ohneText\HK_SUF_ohneText`i'"
}
cap rename ergg_1km r1_id
drop if r1_id=="-9" /*drop if grid cell unknown*/
gen year=ajahr

foreach x in obid nebenkosten kaufpreis mieteinnahmenpromonat heizkosten baujahr letzte_modernisierung wohnflaeche grundstuecksflaeche nutzflaeche etage anzahletagen zimmeranzahl nebenraeume schlafzimmer badezimmer parkplatzpreis wohngeld ev_kennwert laufzeittage hits click_schnellkontakte click_customer click_weitersagen click_url immobilientyp ajahr amonat emonat aufzug balkon betreut denkmalobjekt einbaukueche einliegerwohnung ev_wwenthalten ferienhaus foerderung gaestewc garten heizkosten_in_wm_enthalten kaufvermietet keller parkplatz rollstuhlgerecht bauphase ausstattung energieeffizienzklasse energieausweistyp haustier_erlaubt heizungsart kategorie_Wohnung kategorie_Haus objektzustand{
replace `x'=. if `x'<0
}
*misstable sum, all

gen lprice=log(kaufpreis)
gen priceqm=kaufpreis/wohnflaeche
label var priceqm "Kaufpreis pro Quadratmeter"
gen lpriceqm=log(priceqm)
egen region = group(erg_amd)
label var region "identifier labor market region"
gen nkqm=nebenkosten/wohnflaeche
label var nkqm "Nebenkosten pro qm"
egen type=group(immobilientyp)
replace immobilientyp=type-1
drop type

foreach x in kaufpreis priceqm nebenkosten nkqm baujahr wohnflaeche etage anzahletagen zimmeranzahl schlafzimmer badezimmer immobilientyp ajahr balkon einbaukueche foerderung garten keller ausstattung heizungsart kategorie_Haus kategorie_Wohnung objektzustand{
gen M`x'=.
replace M`x'=1 if `x'==.
replace M`x'=0 if M`x'==.

replace `x'=0 if `x'==.  /*replace missings by zero, but control for missings by M`x'*/
label var M`x' "1 if `x' is missing"
egen temp=mean(`x') /*Use the time-invariant mean*/

gen D`x'=`x'-temp
label var D`x' "`x' minus national average"
drop temp
}

sort r1_id
merge m:1 r1_id using "$path\DATAGENERATION\grid.coordinaten.dta"
tab _merge
keep if _merge==3
drop _merge
sort erg_amd
merge m:1 erg_amd using "$path\DATAGENERATION\Centroids_CBDv1_mean.dta"
tab _merge
drop _merge
rename x d_long
label var d_long "longitude of distination"
rename y d_lat 
label var d_lat "latitude of destination"
geodist o_lat o_long d_lat d_long, gen(dist_cbd)
gen ldist=log(dist_cbd)
label var ldist "log of distance to CBD"

* Merge submarket ID
merge m:1 r1_id using "$path\DATAGENERATION\purchases_submarketID.dta"
keep if _merge==3
drop _merge

* save "APPLICATIONS\DATA\INPUT\RWI-GEO-RED\DATAGENERATION\purchases", replace

// BRIDGE CODE ENDS HERE
********************************************************************************
// FINAL PROCESSING FOR AHS ALGORITHM
	
// BRING DATA SET SET INTO REQUIRED FORMAT
	
	* DROP GEO COORDINATES AND MERGE ETRS COORDINATES
		capture drop x y
		ren r1_id ergg_1km
		merge m:1 ergg_1km using "$path\DATAGENERATION\grid.coordinaten_xy.dta"
		keep if _m == 3
		drop _m 
		merge m:1 ergg_1km using "$path\DATAGENERATION\grid_kreis.dta"
		keep if _m == 3
		drop _m 
		destring kreis_id, replace

	* PRICE SQM VARIABLE
		drop lprice*
		ren priceqm price_qm

	* More renaming
		ren Mwohnflaeche Mfloorspace
		ren Dwohnflaeche Dfloorspace
		ren wohnflaeche floorspace		
		ren Dimmobilientyp Dtype
		ren Dbalkon Dbalcony
		ren Dgarten Dgarden
		ren Dkeller Dbasement
		ren heizung heating
		
	* ATTRIBUTE VARIABLES (ALL RESCALED TO NATIONAL AVERAGE, MISSINGS TO ZERO)
		drop if Mfloorspace == 1
		drop Mfloorspace
		ren Dfloorspace Att_area
		ren Dtype Att_type
		ren Dbalcony Att_balcony
		ren Dgarden Att_garden
		ren Dbasement Att_basement
		gen Att_quality_simple = ausstattung == 1
		gen Att_quality_sophi = ausstattung == 3
		gen Att_quality_deluxe = ausstattung == 4
		tab heating, gen(Att_heating_)
		drop Att_heating_1
		replace kategorie_Haus = 0 if kategorie_Haus == .
		replace kategorie_Haus = 0 if kategorie_Haus == 1
		tab kategorie_Haus, gen(Att_house_)
		drop Att_house_1
		replace kategorie_Wohnung = 0 if kategorie_Wohnung == .
		replace kategorie_Wohnung = 0 if kategorie_Wohnung == 3
		tab kategorie_Wohnung, gen(Att_flat_)
		drop Att_flat_1
		* DROP IRRELEVANT VARIABLES
		foreach var of varlist Att_heating* Att_house* Att_flat* {
			qui sum `var'
			local AttN = r(mean)
			if `AttN' < 0.025 {
				drop `var'
				}
				else{
				}
			}
		
		
// CLEAN DATA SET FROM OUTLIERS
	drop if price_qm < 250
	drop if price_qm > 25000
	drop if floorspace < 30
	drop if floorspace > 500
	egen mprice_qm = median(price_qm), by(kreis_id)	
	gen mratio = price_qm/mprice_qm
	drop if mratio < 0.2
	drop if mratio > 5
	gen lprice_qm = ln(price_qm)
	
// KEEP KEY VARIABLES 
	keep obid lprice Att_* kreis_id origin_X origin_Y year submarket
	
// DEMEAN ATTRIBUTE VARIABLES AND DROP IRRELEVANT VARIABLES
	qui foreach var of varlist Att_* {
		sum `var'
		replace `var' = `var'-r(mean)
		}

// MAKE SURE THERE ARE NO MISSINGS IN DATA
	foreach var of varlist * {
		drop if `var' == .
		}		
	
// SAVE DATA SET 
	save "$path\IMMO_PURCH_USING.dta", replace
