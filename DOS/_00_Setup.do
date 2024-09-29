********************************************************************************
* (C) GABRIEL M AHLFELDT, 2024
* FOR STATA 18
********************************************************************************
* GENERATING A PROPERTY PRICE INDEX ADJUSTED FOR ATTRIBUTES AND LOCATION

* Select user to set the right root directory
	* User 1 GA Linux server
	* User 2 GA Windows network drive
	* User 3 GA Surface 7 dropbox
	global user = 1
*set global root here: All other folders will be created within the unzipped directory  	
 	if $user == 1 {
		global root  	"/home/RDC/ahlfeldg/H:/ahlfeldg/Research/_AHS2023-toolkit"
		}
	if $user == 2 {
		global root "H:/Research/_AHS2023-toolkit"
		* "/run/user/1632606149/gvfs/smb-share:server=clapton.wiwi.hu-berlin.de,share=primelocations/Detecting Prime Locations"
	}
	if $user == 3 {
		global root "C:/Users/gabri/Dropbox/HousePriceTool/_AHS2023-toolkit"
	}
	cd "$root" // Changing the working directory to the root folder

* Install ados
	ssc install geodist
	ssc install spmap
* DONE	
