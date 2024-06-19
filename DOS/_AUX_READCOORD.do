// LOAD DESTINATION DATA SET AND READ IN SCALARS	
	u "$WD/TARGET.dta", replace
		egen n_id = group(target_id) 
	save, replace
		sum n_id 
		global N = r(N)
		qui forval num = 1/$N {
			sum target_x if n_id == `num'
			scalar target_x_`num' = r(mean)
			sum target_y if n_id == `num'
			scalar target_y_`num' = r(mean)
		}
		