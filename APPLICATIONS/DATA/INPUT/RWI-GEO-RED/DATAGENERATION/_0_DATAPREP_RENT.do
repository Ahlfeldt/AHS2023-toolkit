********************************************************************************
* (C) GABRIEL M AHLFELDT, 2020
* FOR STATA 16
********************************************************************************
* GENERATING A PROPERTY PRICE INDEX ADJUSTED FOR ATTRIBUTES AND LOCATION

// THIS IS THE BRIDGE CODE USING RWI DATA ACCORDING TO 2022 ORGANIZATION

local waves = $version +5

use "$origin\WM_SUF_ohneText\WM_SUF_ohneText1", clear
forvalues i= 2/`waves' {
	append using "$origin\WM_SUF_ohneText\WM_SUF_ohneText`i'"
}
forvalues i= 1/`waves' {
	append using "$origin\HM_SUF_ohneText\HM_SUF_ohneText`i'"
}
cap rename ergg_1km r1_id
*drop if erg_amd==-9 /*drop if Arbeitsmarktregion unknown*/
drop if r1_id=="-9" /*drop if grid cell unknown*/
cap rename ergg_1km r1_id
gen year=ajahr

keep obid mietekalt nebenkosten baujahr wohnflaeche etage anzahletagen zimmeranzahl immobilientyp year balkon garten keller ausstattung heizungsart kategorie_Haus kategorie_Wohnung erg_amd r1_id

foreach x in obid mietekalt nebenkosten baujahr wohnflaeche etage anzahletagen zimmeranzahl immobilientyp year balkon garten keller ausstattung heizungsart kategorie_Haus kategorie_Wohnung{
replace `x'=. if `x'<0
}
*misstable sum, all

gen lrent=log(mietekalt)
gen rentsqm=mietekalt/wohnflaeche
label var rentsqm "Rent per square meter"
gen lrentsqm=log(rentsqm)
egen region = group(erg_amd)
label var region "identifier labor market region"
gen nksqm=nebenkosten/wohnflaeche
label var nksqm "Nebenkosten pro qm"
egen type=group(immobilientyp)
replace immobilientyp=type-1
drop type

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
label var d_long "longitude of destination"
rename y d_lat 
label var d_lat "latitude of destination"
geodist o_lat o_long d_lat d_long, gen(dist_cbd)
label var dist_cbd "Distance to CBD"
gen ldist=log(dist_cbd)
label var ldist "log of distance to CBD"

//Generate summary statistics table

rename wohnflaeche floorspace
label var floorspace "Living space in sqm"
rename zimmeranzahl rooms
label var rooms "Number of rooms"
rename immobilientyp type
label var type "Type of housing, 1 if apartment"
rename balkon balcony
label var balcony "Balcony"
rename garten garden
label var garden "Garden"
rename keller basement
label var basement "Basement"
rename heizungsart heating_type
label var heating_type "Type of heating"
rename mietekalt rent
label var rent "Rent net of utilities"
rename nebenkosten utilities
rename nksqm utilitiessqm
rename baujahr constr_year
rename etage floor
label var floor "Floor location of apartment"
rename anzahletagen number_floors

*tabstat rentsqm dist_cbd floorspace rooms type balcony garden basement heating_type, stat(count mean sd p10 p90) col(stat) format(%12.0gc)

// Set missings to zero and control for missings by M`x'

foreach x in obid rent utilities constr_year floorspace floor number_floors rooms type year balcony garden basement rentsqm utilitiessqm{
gen M`x'=.
replace M`x'=1 if `x'==.
replace M`x'=0 if M`x'==.

replace `x'=0 if `x'==.  
label var M`x' "1 if `x' is missing"
egen temp=mean(`x') /*take the time-invariant mean*/
gen D`x'=`x'-temp
label var D`x' "`x' minus national average"
drop temp
}
gen Mheating_type=0
replace Mheating_type=1 if heating_type==.
replace heating_type=0 if heating_type==.|heating_type==13

* Merge submarket ID

merge m:1 r1_id using "$path\DATAGENERATION\rentals_submarketID.dta"
keep if _merge==3
drop _merge

 save "$path\DATAGENERATION\rentals", replace

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
		ren rentsqm price_qm
	
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
	drop if price_qm < 1
	drop if price_qm > 50
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
	save "$path\IMMO_RENT_USING.dta", replace
