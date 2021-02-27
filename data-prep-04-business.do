**********************************************************************************************************************
**********************************************************************************************************************
***** Replication code for "Using Machine Learning to Estimate the Effect of Racial Segregation on COVID-19 Mortality in the United States" (PNAS, 2021)
***** This file does: Data Preparation, County Business Patterns
***** Author: Gerard Torrats-Espinosa
***** Date: Dec 24, 2020 

***** Input Data: County Business Patterns 2018 (https://www.census.gov/programs-surveys/cbp/data/datasets.html)
**********************************************************************************************************************
**********************************************************************************************************************
set more off
set maxvar 10000

import delimited "data/input/county-business-patterns/cbp17co.txt", encoding(Big5) clear

*** Drop state totals
drop if fipscty==999

*** County FIPS
gen state_str = string(fipstate,"%02.0f")
gen county_str = string(fipscty,"%03.0f")
gen FIPS = state_str + county_str

*** Create categories
drop if naics =="------"
gen cat = ""
replace cat = "food_stores" if naics == "445///"
replace cat = "pharmacies" if naics == "44611/"
replace cat = "hospitals" if naics == "622///"
replace cat = "nursing_homes" if naics == "6231//"
replace cat = "nursing_homes" if naics == "6233//"
replace cat = "sports_center" if naics == "71394/"
replace cat = "bowling" if naics == "71395/"
replace cat = "religious" if naics == "8131//"
replace cat = "civic" if naics == "8134//"
drop if cat==""

*** Reshape wide
keep  FIPS cat  emp est ap 
ren * *_
ren FIPS_ FIPS

collapse (sum) emp_   ap_ est_,by(FIPS cat_)

reshape wide   emp_   ap_ est_ ,i(FIPS) j(cat_) string

* Create sports + bowling
foreach v in emp  ap est {
	gen `v'_sports_bowl = `v'_sports_center + `v'_bowling
}

destring FIPS,replace
foreach v of varlist _all {
	replace `v' =0 if `v'==.
}

gen FIPS_str = string(FIPS,"%05.0f")
drop FIPS
ren FIPS_str FIPS	
order FIPS
ren * cbp_*
ren *FIPS FIPS

*** Create rates by 1,000
merge 1:1 FIPS using "data/output/county-demographics.dta",keepusing(dem_totpop)
drop if _merge ==2
drop _merge

foreach v of varlist cbp* {
	replace `v' = (`v'/dem_totpop)*1000
}

drop dem_totpop

*** Shorten variable names
ren cbp_est_religious cbp_est_relig
ren cbp_emp_food_stores cbp_foodstores
ren cbp_emp_hospitals cbp_hospitals
ren cbp_emp_nursing_homes cbp_nurshomes
ren cbp_emp_pharmacies cbp_pharmacies
ren cbp_est_sports_bowl cbp_est_sport

save "data/output/cbp17.dta",replace
