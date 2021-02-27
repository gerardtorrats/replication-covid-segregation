**********************************************************************************************************************
**********************************************************************************************************************
***** Replication code for "Using Machine Learning to Estimate the Effect of Racial Segregation on COVID-19 Mortality in the United States" (PNAS, 2021)
***** This file does: Data Preparation, Merges All Data Sets for Analysis
***** Author: Gerard Torrats-Espinosa
***** Date: Dec 24, 2020 
**********************************************************************************************************************
**********************************************************************************************************************
set more off

*** Start with full sample of counties from crosswalk to flag counties not in each data set
use  "data/input/crosswalks/xwalk-county-names-states-cz.dta",clear
gen ____COVID___ = ""

*** Merge COVID USA Facts
merge 1:1 FIPS using "data/output/covid-usaf-ouctomes.dta"
drop if _merge ==2
gen in_covid_usfacts = (_merge ==3)
lab var in_covid_usfacts "County is in COVID dataset from USA Facts"
drop _merge

*** Merge COVID NY Times
merge 1:1 FIPS using "data/output/covid-nyt-ouctomes.dta"
drop if _merge ==2
gen in_covid_nyt = (_merge ==3)
lab var in_covid_nyt "County is in COVID dataset from NYTimes"
drop _merge

*** Merge COVID CDC by Race
merge 1:1 FIPS using "data/output/cdc-covid-deaths-by-race.dta"
drop if _merge ==2
gen in_covid_cdc_race = (_merge ==3)
lab var in_covid_cdc_race "County is in CDC dataset COVID deaths by race"
drop _merge

*** Merge demographics
gen ____DEMOGRAPHICS___ = ""
merge 1:1 FIPS using "data/output/county-demographics.dta"
drop if _merge ==2
gen in_demographics = (_merge ==3)
lab var in_demographics "County is in demographics dataset"
drop _merge

*** Merge segregation
gen ____SEGREGATION___ = ""
merge 1:1 FIPS using "data/output/segregation.dta"
drop if _merge ==2
gen in_segregation = (_merge ==3)
lab var in_segregation "County is in segregation dataset"
drop _merge

*** Merge health 
gen ____HEALTH_RWJ___ = ""
merge 1:1 FIPS using  "data/output/rwj-health.dta"
drop if _merge ==2
gen in_health_rwj = (_merge ==3)
lab var in_health_rwj "County is in health dataset from RWJ"
drop _merge

*** Merge hospital beds
gen ____BEDS___ = ""
merge 1:1 FIPS using "data/output/beds-county.dta"
drop if _merge ==2
gen in_beds = (_merge ==3)
lab var in_beds "County is in hospital beds dataset"
drop _merge

*** Merge County Business Patterns 
gen ____BUSINESS___ = ""
merge 1:1 FIPS using "data/output/cbp17.dta"
drop if _merge ==2
gen in_cbp = (_merge ==3)
lab var in_cbp "County is in County Business Patterns dataset"
drop _merge

*** Merge airport traffic
gen ____AIPORT___ = ""
merge 1:1 FIPS using "data/output/passenger-traffic-in100miles-Q1-2020.dta"
drop if _merge ==2
gen in_airport = (_merge ==3)
lab var in_airport "County is in  Airport Traffic dataset"
drop _merge

*** Merge 2016 election
gen ____2016_ELECTION___ = ""
merge 1:1 FIPS using "data/output/2016-election.dta"
drop if _merge ==2
gen in_2016election = (_merge ==3)
lab var in_2016election "County is in 2016 Election dataset"
drop _merge

*** Merge climante change poll
gen ____CLIMATE_CHANGE___ = ""
merge 1:1 FIPS using "data/output/yale-climate-poll.dta"
drop if _merge ==2
gen in_climate = (_merge ==3)
lab var in_climate "County is in Yale Climante Change Poll"
drop _merge

*** Merge with region
merge m:1 state_ab using "data/input/crosswalks/state-region.dta"
drop _merge

gen region_ab = "MW" if region_name == "Midwest"
replace region_ab = "NE" if region_name == "Northeast"
replace region_ab = "S" if region_name == "South"
replace region_ab = "W" if region_name == "West"

gen ___IN_SAMPLES___ = ""
order FIPS county_name_state state_ab state_name cz czname region region_ab region_name ___IN_SAMPLES___ in_covid_usfacts in_covid_nyt in_covid_cdc_race in_demographics in_segregation in_health_rwj in_beds  in_cbp in_airport in_2016election in_climate 

* Label variables
lab var dem_totpop "Population"
lab var dem_25under "% younger than 25"
lab var dem_65over "% older 65"
lab var dem_white "% white"
lab var dem_black "% black"
lab var dem_asian "% Asian"
lab var dem_hispanic "% Hispanic"

lab var dem_lesshs "% no high school"
lab var dem_college_more "% college or more"
lab var dem_med_hhinc "Median income"
lab var dem_pov "% in poverty"
lab var seg_age_all "Age segregation"

lab var seg_reldiv_all "Relative Diversity Index"
lab var seg_reldiv_bw "B-W Relative Diversity Index"
lab var seg_reldiv_hw "H-W Relative Diversity Index"

lab var seg_theil_all "Theil Index"
lab var seg_theil_bw "B-W Theil Index"
lab var seg_theil_hw "H-W Theil Index"

lab var seg_inc_all "Income segregation"
lab var dem_popdens "Population density"
lab var dem_log_popdens "Population density (log)"
lab var dem_publictrans "% public transit"
lab var dem_comm_wfh "% working from home"
lab var dem_comm_avg_time "Average commute"
lab var dem_unemployed "% unemployed"
lab var dem_pub_sect "Public sector"
lab var dem_construction "Construction"
lab var dem_hu_vacant "% vacant units"
lab var dem_hhold_6more "% households with 6+ occupants"
lab var dem_gchild "% families with grandchildren"
lab var dem_hu_50more "% units in 50+ unit buildings"
lab var air_dom "Domestic airport traffic"
lab var air_int "International airport traffic"
lab var cbp_est_civic "Civic organizations"
lab var cbp_est_relig "Religious organizations"
lab var cbp_est_sport  "Sports and bowling centers"
lab var rwj_life_expec "Life expectancy"
lab var rwj_prem_mort "% premature deaths"
lab var rwj_diabetes_rate "% diabetic"
lab var rwj_hiv_rate "% HIV positive"
lab var rwj_insuf_sleep "% sleep less 7h"
lab var rwj_smoking "% smokers"
lab var rwj_obese "% obese"
lab var rwj_phys_inact "% physically inactive"
lab var rwj_drinking "% excessive drinking"
lab var rwj_physicians_r "Primary care physicians"
lab var rwj_other_pcp_rate "Primary care providers"
lab var hos_beds "Hospital beds"
lab var dem_insured "% insured"
lab var rwj_flu_vaccine "%  flu vaccine"
lab var rwj_air_pollution "PM2.5 average"
lab var cbp_foodstores "Food stores"
lab var cbp_hospitals "Hospitals"
lab var cbp_nurshomes "Nursing homes"
lab var cbp_pharmacies "Pharmacies"
lab var pol_dem2016 "% voted democrat in 2016"
lab var cli_happening "% global warming happening"
lab var cli_regulate "% supports CO2 regulation"

compress

save "merged-for-analysis.dta",replace
