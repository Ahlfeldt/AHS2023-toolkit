centroids.dta is the data set that contains the target units - the units for which the index is to be predicted. It includes the following variables

hexagon_id 		This is the identifier variable that identifies the target spatial units for which an index is to be predicted
			It must be named *_id where * is a placeholder 
target_x		This is the x-coordinate of the target units. It must be measured in PROJECTED METERS
target_y		This is the y-coordinate of the target units. It must be measured in PROJECTED METERS

transaction_id.dta is the data set that contains the micro transactions data that are input into the algorithm. It includes the following variables:

transactions_id		This is a variable that identifies transactions. It can be named arbitrarily. 
lprice_qm		This is the recorded log price per sqm of the transaction. It must be named exactly like this.
year			This is year in which transaction took place. It must be named exactly like this.
Att_*			Variables that contain property characteristics that should be considered in the mix-adjustment. 
			* is a placeholder that can be named arbitrarily.
			An arbitrary number of variables starting with Att_ can be included. They will all be considered as hedonic characteristics. The two included variables are for illustration only.
			ALL VARIABLES MUST BE DE-MEANED (SUBTRACT THE MEAN TO HAVE A ZERO MEAN). The algorithm will predict an index value that is representative for a property with 0-values in all Att_ characteristics
submarketid		Categorical variable (must be integer) that defines different submarkets. It must be named exactly like this. The algorithm will not smooth across borders between submarkets
			Use this variable responsibly. Do not define too many submarkets as this may result in small number of observations in locally-weighted regressions
origin_X		The transaction x-coordinate in PROJECTED METERS. It must be named exactly like this.
origin_Y		The transaction y-coordinate in PROJECTED METERS. It must be named exactly like this.	
OtherVariable		An example for additional variables in the data set. They will not be considered by the algorithm.	

postcode_pop.dta contains 2005/6 population estimates from GfK for postcodes. Only used for the aggregation of postcode price indices.

XWALK is a folder containing cross-walks from postcodes to local labour markets and counties.  Only used for the aggregation of postcode price indices.