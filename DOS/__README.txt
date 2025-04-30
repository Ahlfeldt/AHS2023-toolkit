This folder contains the do files used by the algorithm.

_00_Setup.do      Do file that sets up the working directory
_AUX_PROG.do		  Auxiliary do file that contains the core program.
_AUX_READCOORD.do	Auxiliary do that reads the coordinates of the target units.
_USE_PREDICT.do 	Do file that generates the index, calling the other do files. You only need to use this do file.
_MAP_ILLUSTRATION.do	After you have run _USE_PREDICT.do, you can illustrate the output based on the synthetic data and the Berlin Hexagons using this do file
_BLF_AGGREGATION.do	This do file can be used to aggregate the postcode indieces to population-weighted county or local labour market indices

+++ PLEASE EXECUTE THE DO FILES IN THE FOLLOWING ORDER +++
1. _00_Setup.do
2. _USE_PREDICT.do
3. _MAP_ILLUSTRATION.do	(optional)
4. _BLF_AGGREGATION.do (optional)
