**********************************************************************************************************************
**********************************************************************************************************************
***** Replication code for "Using Machine Learning to Estimate the Effect of Racial Segregation on COVID-19 Mortality in the United States" (PNAS, 2021)
***** This file does: Data Preparation, Hospital Beds
***** Author: Gerard Torrats-Espinosa
***** Date: Dec 24, 2020 

**** Input Data: Homeland Infrastructure 2018 Foundation-Level Data (https://hifld-geoplatform.opendata.arcgis.com/datasets/hospitals)
**********************************************************************************************************************
**********************************************************************************************************************
set more off
set maxvar 10000

import delimited  "data/input/hospitals/sj-hospitals-counties.csv",clear
replace beds = 0 if beds ==-999

* Merge with state names
drop state_id
ren statefp state_id
merge m:1 state_id using "data/input/crosswalks/states_list_abbrv_num_names.dta"
drop if _merge ==1
ren geoid FIPS

* Order key variables
order FIPS namelsad state_ab state_id countyfp beds  x y address city state zip zip4 type status latitude longitude 
sort FIPS beds

*** Generate bed counts by county
collapse (sum) beds ,by(state_ab state_id  FIPS )
drop if state_id>56
drop state_*
gen FIPS_str = string(FIPS,"%05.0f")
drop FIPS
ren FIPS_str FIPS	
order FIPS 
ren * hos_*
ren *FIPS FIPS

*** Create rates by 1,000
merge 1:1 FIPS using "data/output/county-demographics.dta",keepusing(dem_totpop)
drop if _merge ==2
drop _merge

foreach v of varlist hos_beds {
	replace `v' = (`v'/dem_totpop)*1000
}

drop dem_totpop

save "data/output/beds-county.dta",replace
