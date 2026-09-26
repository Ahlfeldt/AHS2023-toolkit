*****************************************************************************************
* Gabriel Ahlfeldt, Felipe Carozzi, Lukas Makovsky
* (C) 2022
*****************************************************************************************

* This README file refers to the 2020 version of the LSE-REEF Index.

* General description *******************************************************************

The LSE-REEF index is a micro-geographic mix-adjusted property price index. 
Its unique feature is that it reveals house price trends in about 35,000 lower-layer 
super output areas in England and Wales from 2010 to 2020.

The index utilizes matched Land Registry price paid and Energy Performance Certificate 
data, combined with a mix of parametric and non-parametric estimation techniques, to 
track the market price per square meter of floor space of a constant-quality housing 
unit over time. Ahlfeldt, Carozzi, and, Makovsky (2023) provide a detailed description 
of the underlying data and a descriptive summary of changes in property prices over the 
2010 to 2020 period in England and Wales. Additionally, a comprehensive explanation of 
the methodology is provided by  Ahlfeldt, Heblich, Seidel (2023). 

The LSE-REEF Index is the result of a purely academic research project, with no 
involvement from private-sector parties.

* Terms of use *************************************************************************

The index is free to use under the condition that Ahlfeldt, Carozzi, Makovsky (2023) is
being cited https://cep.lse.ac.uk/pubs/download/occasional/op061.pdf 

* Description of the data repository **************************************************

The subfolder Data contains the LSE-REEF Index as a wide format csv. 
p_* are the predicted values by output area for a given year in Pounds per square meter. 
se_* are the corresponding standard errors of the predicted value.

The subfolder Shapefile contains an lower-lever super output area shapefil to which the
index variables have been merged

* Creating your own index *************************************************************

The Ahlfeldt, Heblich, Seidel (2023) paper provides a replication director containing
all codes alongside a documentation for how to create a similar index for any given
geography. It is available for down load from:
https://doi.org/10.1016/j.regsciurbeco.2022.103836

The land registry data price paid data set is available for down load from:
https://www.gov.uk/government/statistical-data-sets/price-paid-data-downloads

The energy performance certificate data are available for download from:
https://epc.opendatacommunities.org/

To generate a version of the index using the latest data, merge the land registry and
energy performance certificate data sets and use them as inputs in the 
Ahlfeldt, Heblich, Seidel (2023) algorithm. 

* References **************************************************************************

Ahlfeldt, G. M., F. Carozzi, L. Makovsky (2022): A micro-geographic house price index 
for England and Wales. http://www.gahlfeldt.de//WP/GA_FC_LM_-_MGPPI_EW.pdf 

Ahlfeldt, G. M., S. Heblich, T. Seidel (2023): Micro-geographic property price and rent 
indices. Regional Science and Urban Economics, 98. 
https://doi.org/10.1016/j.regsciurbeco.2022.103836


