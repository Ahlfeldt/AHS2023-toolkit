// This do file generates an rental price index for 1km Hexagons for the Berlin rental market.
// By Gabriel M Ahlfeldt 2021
// For Stata 16



* Set temporary woring directory
global WD TemporaryDirectory // Name of temporary directory


* Create temporary working direktory
capture shell rmdir "$WD" /s /q
mkdir $WD

// FULL RUN

* 0) LOAD PROGRAM
	capture drop program PREDICT // Drop program if already loaded
	do "DOS\_AUX_PROG"
* A1) PREPARE TARGET DATA SET
	u "DATA\INPUT/centroids.dta", clear
	gen target_id = hexagon_id // Create a variable target_id that contains the identifier of the target unit (here hexagon_id)
	save "$WD\TARGET.dta", replace // This one will be used	
* A2) LOAD COORDINATES
	do "DOS\_AUX_READCOORD.do"
* A3) RUN PROGRAM
	u "DATA/INPUT/transactions.dta", clear

// PREDICT SYNTAX: PREDICT A B C D E F G H I J K L M N
	* A n_id that starts the loop, usually 1
	* B n_id that ends the loop, usually $N (global for max. n_id)
	* C first year if index
	* D last year of index
	* E Search for observations within this distance threshold in km first, e.g. 10 
	* F If not enough obs within E km, switch to F, e.g. 25
	* G If not enough obs within F km, switch to G, e.g. 50
	* H If stil not enough obs, switch to H, 100
	* I Defines the number of obs in the above decision rule. e.g. 20000
	* J searches for observations within this distance in km for spatial fixed effect, e.g. 2.5
	* K If not enough obs within E km, switch to F, e.g. 5
	* L If not enough obs within E km, switch to F, e.g. 10
	* M If not enough obs within E km, switch to F, e.g. 20
	* N Defines the number of obs in the above spatial fixed effect decision rule. e.g. 1000
PREDICT  1 $N   2007 2021  5 10 25 50 20000 1 2 5 10 1000	// $N selects all observations 

// Merge target identifiers
	merge 1:1 n_id using "$WD/TARGET.dta"
		tab _m 
		drop if _m == 2
		drop _m

* Reshape into long format
	qui reshape long lprice_qm price_qm price_qm_se lprice_qm_se lnadjfactor_, i(n_id) j(year) 
	drop lnadjfactor* // Auxiliary variable used to recover the correct level from predicted log prices
// Label variables
	label var n_id "Temporary ID variable for loop, useful for rerunning PREDICT to inspect trouble makers"
	label var Obs "Number of observations used in prediction of price index"
	label var Radius "Radius of area covered bz LWR to predict price index"
	label var Obs_own "Number of observations used to identify micro-geographic fixed effect"
	label var Radius_own "Radius of the micro-geographic fixed effects area"
	label var Effect_nown "Premium for the area OUTSIDE relative to the area INSIDE the micro-geographic fixed effect area"
	label var lprice_qm "Ln price index (same units as in transactions data)"
	label var price_qm "Price index (same units as in transactions data)"
	label var lprice_qm_se "Standard error of ln price index (same units as in transactions data)"
	label var price_qm_se "Standard error of price index (same units as in transactions data)"	
	label var target_id "Identifier for the target spatial units of the index"
	label var target_x "Projected-meter x-coordinate of the spatial unit of the index"
	label var target_y "Projected-meter y-coordinate of the spatial unit of the index"
	drop n_id // Auxiliary variable that is no longer needed
	save "DATA\OUTPUT/AHS-Index", replace
	
* A4) SAVE OUTPUT ON SERVER AND H-DRIVE
	keep *_id year price_qm price_qm_se
	reshape wide price_qm price_qm_se , i(target_id) j(year)
	drop target_id // Auxiliary variable that is no longer needed
	export delimited using  "DATA\OUTPUT/AHS-Index.csv", replace		

// Delete working directory	
	shell rmdir "$WD" /s /q
