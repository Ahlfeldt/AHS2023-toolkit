// This do file generates an rental price index for 1km Hexagons for the Berlin rental market.
// By Gabriel M Ahlfeldt 2021
// For Stata 16


************************************************************************************
* Set base directory for application
cd "M:\_FDZ\RWI-GEO\AHS_index"

*Set global path for application:
global path = "M:\_FDZ\RWI-GEO\AHS_index\APPLICATIONS\DATA\INPUT\RWI-GEO-RED/"
* Set path for original GEO-RED Data
global origin ="M:\_FDZ\RWI-GEO\RWI-GEO-RED\daten\SUF\v7"
*set version of RED data (is important for data preparation) - only fill in the first number: v7.1 = 7 v6.2 = 6 etc. 
global version = 7


********************************************************************************


do "$path\DATAGENERATION\_0_DATAPREP_PURCH.do"   /*preparation of purchasing data */
do "$path\DATAGENERATION\_0_DATAPREP_RENT.do"   /*preparation of rental data */
