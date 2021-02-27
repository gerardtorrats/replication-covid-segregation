**********************************************************************************************************************
**********************************************************************************************************************
***** Replication code for "Using Machine Learning to Estimate the Effect of Racial Segregation on COVID-19 Mortality in the United States" (PNAS, 2021)
***** This file does: Data Preparation, Health Data
***** Author: Gerard Torrats-Espinosa
***** Date: Dec 24, 2020 

**** Input Data: RWJ County Health Rankings (https://www.countyhealthrankings.org)
**********************************************************************************************************************
**********************************************************************************************************************
set more off
set maxvar 10000

local states ///
alabama ///
alaska ///
arizona ///
arkansas ///
california ///
colorado ///
connecticut ///
delaware ///
florida ///
georgia ///
hawaii ///
idaho ///
illinois ///
indiana ///
iowa ///
kansas ///
kentucky ///
louisiana ///
maine ///
maryland ///
massachusetts ///
michigan ///
minnesota ///
mississippi ///
missouri ///
montana ///
nebraska ///
nevada ///
new-hampshire ///
new-jersey ///
new-mexico ///
new-york ///
north-carolina ///
north-dakota ///
ohio ///
oklahoma ///
oregon ///
pennsylvania ///
rhode-island ///
south-carolina ///
south-dakota ///
tennessee ///
texas ///
utah ///
vermont ///
virginia ///
washington ///
west-virginia ///
wisconsin ///
wyoming

foreach s of local states {
	
*** Clean up ranked measure data
	import excel using "data/input/health/2019-`s'.xls", sheet("Ranked Measure Data") clear

	* Rename and label
	ren A county_fips_VAR
	ren B state_name_VAR
	ren C county_name_VAR
	
	ren AE smoking_VAR
	lab var smoking_VAR "\% Smoking Adults (2016)"
	
	ren AU drinking_VAR
	lab var drinking_VAR "\% Excessive Drinking (2016)"	
	
	ren AI obese_VAR
	lab var obese_VAR "\% Obese Adults (2015)"
	
	ren AO phys_inact_VAR
	lab var phys_inact_VAR "\% Physically Inactive  (2015)"

	ren BT physicians_VAR
	lab var physicians_VAR "Number of Primary Care Physicians (2016)"

	ren CP flu_vaccine_VAR
	lab var flu_vaccine_VAR "\% Medicare enrollees who receive an influenza vaccination (2016)"
	
	ren EJ air_pollution_VAR
	lab var air_pollution_VAR "Average daily density of PM2.5 in micrograms per cubic meter (2014)"
	
	keep *_VAR
	ren *_VAR *
	
	* Drop headings
	drop in 1/3

	* Convert strings to numeric
	foreach v in _all {
		destring `v',replace
	}

	save "data/intermediate/ranked_`s'",replace

*** Clean up additional measure data	
	import excel using "data/input/health/2019-`s'.xls", sheet("Additional Measure Data") clear
	
	* Rename and label
	ren A county_fips_VAR
	ren B state_name_VAR
	ren C county_name_VAR
	
	ren D life_expec_VAR
	lab var life_expec_VAR "Life expectancy (2016-2018)"
	
	ren G life_expec_b_VAR
	lab var life_expec_b_VAR "Life expectancy blacks (2016-2018)"

	ren H life_expec_h_VAR
	lab var life_expec_h_VAR "Life expectancy Hispanics (2016-2018)"
	
	ren I life_expec_w_VAR
	lab var life_expec_w_VAR "Life expectancy whites (2016-2018)"	
	
	ren K prem_mort_VAR
	lab var prem_mort_VAR "Deaths among residents under 75 per 100,000 population age-adjusted (2016-2018)"
	
	ren AK diabetes_rate_VAR
	lab var diabetes_rate_VAR "\% Adults ages 20 and above with diagnosed diabetes (2016)"
	
	ren AO hiv_rate_VAR
	lab var hiv_rate_VAR "People aged 13 and above diagnosed with HIV infection per 100,000 population (2016)"
	
	ren AZ insuf_sleep_VAR
	lab var insuf_sleep_VAR "\% Adults sleeping less than 7 hours (2016)"
		
	ren BK other_pcp_rate_VAR
	lab var other_pcp_rate_VAR "Primary care providers other than physicians per 100,000 population (2019)"
	
	keep *_VAR
	ren *_VAR *
	
	* Drop headings
	drop in 1/3

	* Convert strings to numeric
		foreach v of varlist _all {
		destring `v',replace
	}
	save "data/intermediate/additional_`s'",replace

*** Merge ranked and additional
	use "data/intermediate/ranked_`s'",clear
	merge 1:1 	county_fips using "data/intermediate/additional_`s'"
	ren _merge merge_ranked_additional
	save "data/intermediate/ranked_additional_`s'",replace
	
}

*** Append all states
clear 
foreach s of local states {
	append using  "data/intermediate/ranked_additional_`s'"
}

*** Create FIPS
gen FIPS = string(county_fips,"%05.0f")
order FIPS

drop  state_name county_name merge_ranked_additional
ren * rwj_*
ren *FIPS FIPS

*** Generate racial/ethnic gaps in life expectancy
gen rwj_life_expec_wb = rwj_life_expec_w - rwj_life_expec_b
gen rwj_life_expec_wh = rwj_life_expec_w - rwj_life_expec_h

lab var rwj_life_expec_wb "White-black life expectancy gap"
lab var rwj_life_expec_wh "White-Hispanic life expectancy gap"

*** Generate physicians rate
merge 1:1 FIPS using "data/output/county-demographics.dta",keepusing(dem_totpop)
drop _merge
gen rwj_physicians_r = (rwj_physicians/dem_totpop)*100000

save "data/output/rwj-health.dta",replace
