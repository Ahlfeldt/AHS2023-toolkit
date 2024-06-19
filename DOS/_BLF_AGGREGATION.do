* This do file aggregates postcode data to aggregates (weighted by population) at county and LLM level. 

* LLM PURCH
	u "DATA/INPUT/XWALKS/XWALK_LLM_PCODE", clear
	duplicates drop
	duplicates drop postcode_id, force
	merge 1:1 postcode_id using "DATA/INPUT/postcode_pop"
	drop if _m == 2
	drop _m
	merge 1:m postcode_id using "DATA/OUTPUT/PPRICE_INDEX_AHL_IMMO_postcode_PURCH"
	collapse price_qm price_qm_se [w=pop], by(llm_id )
	label var price_qm "Price index in Euro per sqm"
	label var price_qm_se "Standard error of price index in Euro per sqm"
	save "DATA/OUTPUT/PPRICE_INDEX_AHS_IMMO_LLM_POPWEIGHTED_PURCH", replace
	
* LLM RENT
	u "DATA/INPUT/XWALKS/XWALK_LLM_PCODE", clear
	duplicates drop
	duplicates drop postcode_id, force
	merge 1:1 postcode_id using "DATA/INPUT/postcode_pop"
	drop if _m == 2
	drop _m
	merge 1:m postcode_id using "DATA/OUTPUT/PPRICE_INDEX_AHL_IMMO_postcode_RENT"
	collapse price_qm price_qm_se [w=pop], by(llm_id)
	label var price_qm "Rent index in Euro per sqm and month"
	label var price_qm_se "Standard error of rent index in Euro per sqm and month"
	save "DATA/OUTPUT/RPRICE_INDEX_AHS_IMMO_LLM_POPWEIGHTED_RENT", replace	
	
* COUNTY PURCH
	u "DATA/INPUT/XWALKS/XWALK_COUNTY_PCODE", clear
	duplicates drop
	duplicates drop postcode_id, force
	merge 1:1 postcode_id using "DATA/INPUT/postcode_pop"
	drop if _m == 2
	drop _m
	merge 1:m postcode_id using "DATA/OUTPUT/PPRICE_INDEX_AHL_IMMO_postcode_PURCH"
	collapse price_qm price_qm_se [w=pop], by(county_id)
	label var price_qm "Price index in Euro per sqm"
	label var price_qm_se "Standard error of price index in Euro per sqm"
	save "DATA/OUTPUT/PPRICE_INDEX_AHS_IMMO_COUNTY_POPWEIGHTED_PURCH", replace
	
* COUNTY RENT
	u "DATA/INPUT/XWALKS/XWALK_COUNTY_PCODE", clear
	duplicates drop
	duplicates drop postcode_id, force
	merge 1:1 postcode_id using "DATA/INPUT/postcode_pop"
	drop if _m == 2
	drop _m
	merge 1:m postcode_id using "DATA/OUTPUT/PPRICE_INDEX_AHL_IMMO_postcode_RENT"
	collapse price_qm price_qm_se [w=pop], by(county_id)
	label var price_qm "Rent index in Euro per sqm and month"
	label var price_qm_se "Standard error of rent index in Euro per sqm and month"
	save "DATA/OUTPUT/RPRICE_INDEX_AHS_IMMO_COUNTY_POPWEIGHTED_RENT", replace		