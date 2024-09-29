********************************************************************************
* (C) Gabriel M. Ahlfeldt, LSE, CEPR 2020
* For Stata 16.0
********************************************************************************

// This program loads estimates a property price index for arbitrary coordinates
// in the target data set using property information in the origin data set
// Origin and target coordinates must be in projected meter units

// PREDICT SYNTAX: PREDICT A B C D E F G H I J K L M N
	* A n_id that starts the loop, usually 1
	* B n_id that ends the loop, usually $N (global for max. n_id)
	* C first year if index
	* D last year of index
	* E Spatial window: Search for observations within this distance threshold in km first, e.g. 10 
	* F Spatial window: If not enough obs within E km, switch to F, e.g. 25
	* G Spatial window: If not enough obs within F km, switch to G, e.g. 50
	* H Spatial window: If stil not enough obs, switch to H, 100
	* I Spatial window: Defines the number of obs in the above decision rule. e.g. 20000
	* J Spatial fixed effect: Search for observations within this distance threshold in km first, e.g. 2.5 
	* K Spatial fixed effect: If not enough obs within E km, switch to F, e.g. 5
	* L Spatial fixed effect: If not enough obs within F km, switch to G, e.g. 10
	* M Spatial fixed effect: If stil not enough obs, switch to H, 20
	* N Spatial fixed effect: Defines the number of obs in the above decision rule. e.g. 1000
	
* PROGRAM BEGINS
program drop _all
program define PREDICT

// define the numinimum number of obs we want in one regression
	local minobs = `9'

display "...intital prep..."	
	
// Technical variables
	qui gen Radius = . 
	qui gen Obs = . 
	qui gen OWN = . 
	qui gen NOWN = . 
	qui gen SMD = .
	// Gen year dummies
		qui foreach year of numlist `3'/`4'{
		gen YD_`year' = year == `year'
		}
	// Drop if outside the year range
		qui drop if year > `4'
		qui drop if year < `3'
	
// Loop starts
forval num = `1'/`2' { 

	// own identifier 
	qui replace OWN = 0 
	
	// generate ln distance
	qui gen dist =  sqrt( (origin_X - target_x_`num' )^2 + (origin_Y - target_y_`num')^2 )/1000
	qui gen ldist = ln(dist+1)

	// idenfiy own submarket
		qui sum dist
		local mindist = r(min)
		qui sum submarket if dist <= `mindist' + 0.01, meanonly
		local SM = round(r(mean),1)
		qui replace SMD = submarketid != `SM'
	
	// Generate kernel weight
	qui gen W = .
		// check if we have at least minimum number of observations within 25km kernel range
		qui sum dist if dist <=`5' & lprice != . 
			local obs = r(N)
* If enough obs within first threshold			
				if `obs' >= `minobs' { 
					qui replace W = (dist <=`5') //*exp(ln(0.05)/25*dist) // This alternative would be a kernel that ensures the weight declines exponentially from 1 to 5% at the threshold, and is 0 thereafter
					local radius = `5'
					}
				else{ 
					qui sum dist if dist <=`6' & lprice != . // if not enough, check next threshoold
					local obs = r(N)
					if `obs' >= `minobs' { 
						qui replace W = (dist <=`6') //*exp(ln(0.05)/50*dist) // Same as abov
						local radius = `6'
						}
					else {
						qui sum dist if dist <=`7' & lprice != . // if not enough, check next threshoold
							local obs = r(N)
							if `obs' >= `minobs' { 
							qui replace W = (dist <=`7') //*exp(ln(0.05)/75*dist) // Same as above
							local radius = `7'
							}
						else {
						qui replace W = (dist <=`8') //*exp(ln(0.05)/100*dist)	// if still not enough, use fourth threshoold
						local radius = `8'					
					}						
				}
				}
			
// Define a fixed effect for the neighbourhood depending on the available obs
		qui replace OWN = 0
		local minown = `14'
		qui sum dist if dist <=`10' & lprice != . 
			local Ownobs = r(N)
				if `Ownobs' >= `minown' { 
					qui replace OWN = (dist <=`10')
					scalar Ownradius_`num' = `10'
					scalar OwnN_`num' = `Ownobs'
					}
				else{ 	
					qui sum dist if dist <=`11' & lprice != . 
					local Ownobs = r(N)
					if `Ownobs' >= `minown' { 
						qui replace OWN = (dist <=`11')
						scalar Ownradius_`num' = `11'
						scalar OwnN_`num' = `Ownobs'
						}
					else{ 	
						qui sum dist if dist <=`12' & lprice != . 
						local Ownobs = r(N)
						if `Ownobs' >= `minown' { 
							qui replace OWN = (dist <=`12')
							scalar Ownradius_`num' = `12'
							scalar OwnN_`num' = `Ownobs'
							}
						else{ 	
							qui sum  dist if dist <=`13' & lprice != .
							local Ownobs = r(N)
							qui replace OWN = (dist <=`13')
							scalar OwnN_`num' = `Ownobs'
							scalar Ownradius_`num' = `13'
										}	
					}
				}
	
	// Spatial trends
		qui gen trend_X = origin_X - target_x_`num'
		qui gen trend_Y = origin_Y - target_y_`num'
	
	// Generate effect for areas outside OWN radius
		qui replace NOWN = OWN*-1+1
		* display `SM'
		
	// Check if variables have no variation in the local sample and if so rename them so that they are not used in the regression
		qui foreach var of varlist Att_* {
			sum `var'
			local sdsample = r(sd)
			if `sdsample' == 0 {
				ren `var' N`var'
			}
		}
		
	// Run regression
	if `obs' > `Ownobs' { // Fixed effect is included, this cluster on fixed effect
	     qui reg lprice  Att_* c.dist#i.year YD_* NOWN trend_X trend_Y c.SMD#i.year [w=W], nocons cluster(OWN) 
		}
		else { // Fixed effect is not included, cannot cluster => Create an artificial FE for clustering to avoid inflation of t-statistic
		qui gen SECLUSTER = dist <= `radius'*0.5
		qui reg lprice  Att_* c.dist#i.year YD_* NOWN trend_X trend_Y c.SMD#i.year [w=W], nocons cluster(SECLUSTER)
		qui drop SECLUSTER
    	}
	
	// Re-rename variables so that they are considered for next LWR
		capture ren NAtt_* Att_*
	
	  
	  // Parametric specification (for binary kernel weights)
	// qui reg lprice Att_* YD_* OWN  [w=W], nocons // The non-parametric variant (for use with distance-dependent kernen)
	// Save results and iteration specific information into scalars
		scalar Effect_nown_`num' = _b[NOWN]
		scalar Radius_`num' = `radius' 
		local itobs = e(N)
		scalar Obs_`num' = `itobs' 
		foreach year of numlist `3'/`4' {
			scalar lpriceindex_`year'_`num' = _b[YD_`year'] // + _b[OWN]*OWN
			scalar lpriceindex_se_`year'_`num' = _se[YD_`year']
			scalar lnadjfactor_`year'_`num' = exp((`e(rmse)'^2)/2)
			}
			
			// Price index is a local appreciation index with a time-invariant local level index

	// drop variables being generated in the loop
	qui drop W ldist dist trend_X  trend_Y 
		// WITH THE FULL SAMPLE CONSIDER ADDING THIS IF THE EXPANDED ABS IS USED: qui drop _m W ldist FEy FEm My Mm   Mky FEky
	// display looping
	display "Iteration `num' of `2' completed, kernel radius = `radius)' km, using `itobs' observations"
}

// Generate output data set
		//local 1 1
		//local 2 $N
		//local 3 2004
		//local 4 2007

	qui clear
	qui local OBS = `2'-`1'+1
	qui set obs `OBS'
	qui gen n_id = _n + `1'-1
	qui gen Obs = .
	qui gen Radius = .
	qui gen Obs_own = . 
	qui gen Radius_own = . 
	qui gen Effect_nown = . 
	qui forval num = `1'/`2'{	
		replace Obs = Obs_`num'  if n_id == `num'
		replace Radius = Radius_`num'  if n_id == `num'
		replace Obs_own =  OwnN_`num'   if n_id == `num'
		replace Radius_own =  Ownradius_`num'   if n_id == `num'
		replace Effect_nown = Effect_nown_`num' if n_id == `num'

	}
	qui foreach year of numlist `3'/`4'{
		gen  lprice_qm`year' = .
		gen  lprice_qm_se`year' = .
		gen lnadjfactor_`year' = .
			forval num = `1'/`2' { 
				replace  lprice_qm`year'  = lpriceindex_`year'_`num' if n_id == `num'
				replace  lprice_qm_se`year'  = lpriceindex_se_`year'_`num' if n_id == `num'
				replace  lnadjfactor_`year'  = lnadjfactor_`year'_`num' if n_id == `num'
			}
			gen price_qm`year' = exp(lprice_qm`year')*lnadjfactor_`year'
			*gen price_qm_se`year' = (exp(lprice_qm_se`year')-1)*price_qm`year'*lnadjfactor_`year'
			gen price_qm_se`year' = price_qm`year'*lprice_qm_se`year'
			}
	

/*
// collapse final data set to vbg year level
	collapse lrentsqm lrentindex Obs Radius, by(gvb2018 year)
	
// simple predictive power tests	
	reg lrentindex lrentsqm
	reghdfe lrentindex lrentsqm , abs(gvb2018 year)
	gen rentindex =exp(lrentindex)
*/

* PROGRAM ENDS	
end
