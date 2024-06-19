* This do file illustrates the output of the algorithm using the Berlin hexagons

ssc install shp2dta // ado file used to map output


* Set temporary working directory
global WD TemporaryDirectory // Name of temporary directory


* Create temporary working directory
capture shell rmdir "$WD" /s /q
mkdir $WD


insheet using  "DATA\OUTPUT/AHS-Index.csv", clear

* Produce maps
	shp2dta using "SHAPES\hexagon\Berlin_Hexagon_500m", database("$WD\db_using") coordinates("$WD\coord_using") replace
	gen GRID_ID = hexagon_id
	merge 1:1 GRID_ID using  "$WD\db_using", keepusing(_ID) // merge ID variable for mapping
		drop _m 
		global PCT 500 1000 2000 3000 4000 5000 6000 7000 20000 // Defind legend categories here
		foreach year of numlist 2007/2021{
		spmap price_qm`year' using "$WD\coord_using", id(_ID) fcolor(Blues) clmethod(custom)  clbreaks($PCT) legtitle("Price/sqm `year'")  
			graph export  "MAPS/MAP_`year'.png", replace	
		}			
		
		
// Delete working directory	
	shell rmdir "$WD" /s /q		