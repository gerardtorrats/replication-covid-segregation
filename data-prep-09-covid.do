**********************************************************************************************************************
**********************************************************************************************************************
***** Replication code for "Using Machine Learning to Estimate the Effect of Racial Segregation on COVID-19 Mortality in the United States" (PNAS, 2021)
***** This file does: Data Preparation, COVID Outcomes
***** Author: Gerard Torrats-Espinosa
***** Date: Dec 24, 2020 

***** Input Data:
	*** The New York Times (https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv)
	*** USA Facts (https://usafacts.org/visualizations/coronavirus-covid-19-spread-map/)
	*** CDC (https://data.cdc.gov/NCHS/Provisional-COVID-19-Death-Counts-by-County-and-Ra/k8wy-p9cg)
**********************************************************************************************************************
**********************************************************************************************************************
set more off
set maxvar 10000

***********************************************************	
***********************************************************
***** COVID data NY Times
***********************************************************
***********************************************************
*** Create crosswlak to assign Kansas City and NYC to the counties they overlap with, proportional to their population
  * From NYTimes documentation: 
    * Four counties (Cass, Clay, Jackson and Platte) overlap the municipality of Kansas City, Mo. 
    * The cases and deaths that we show for these four counties are only for the portions exclusive of Kansas City. 
    * Cases and deaths for Kansas City are reported as their own line.
use "data/output/county-demographics.dta", clear
keep FIPS dem_totpop
gen FIPS_nyc_kansas = FIPS
replace FIPS_nyc_kansas = "Kansas City" if FIPS == "29037" | FIPS == "29047" |FIPS == "29095" |FIPS == "29165" 
replace FIPS_nyc_kansas = "New York City" if FIPS == "36005" | FIPS == "36047" |FIPS == "36061" |FIPS == "36081" |FIPS == "36085" 

bys FIPS_nyc_kansas: egen sum_pop = sum(dem_totpop)
gen weight = dem_totpop/sum_pop
keeporder FIPS_nyc_kansas FIPS weight
compress
save "data/intermediate/crosswalk-kansas-nyc.dta",replace

*** Download and save data from NYT Github repository
import delimited "data/input/covid-nyt/covid-nyt-2020-10-02.csv",clear

*** Drop unknown counties
drop if county =="Unknown"

*** Merge with Kansas and NYC corsswalk
gen  FIPS_nyc_kansas = string(fips,"%05.0f")
replace FIPS_nyc_kansas =  county if county == "Kansas City" | county =="New York City"

*** Create macro with unique dates
levelsof date,local(dates)

preserve
	keep FIPS_nyc_kansas
	duplicates drop
	merge 1:m FIPS_nyc_kansas using "data/intermediate/crosswalk-kansas-nyc.dta"
	drop if _merge ==2
	drop _merge
	
	*** Assign remainder from the 4 counties overlapping with Kansas City
	replace FIPS = FIPS_nyc_kansas if FIPS_nyc_kansas == "29037" | FIPS_nyc_kansas == "29047" |FIPS_nyc_kansas == "29095" |FIPS_nyc_kansas == "29165" 
	replace weight = 1 if FIPS_nyc_kansas == "29037" | FIPS_nyc_kansas == "29047" |FIPS_nyc_kansas == "29095" |FIPS_nyc_kansas == "29165" 
	
	*** Create FIPS_nyc_kansas - date panel starting 2020-01-01
	tempfile crosswalk
	save "`crosswalk'"
	gen date = "drop"
	foreach date of local dates {
	append using "`crosswalk'"
	replace date ="`date'" if date ==""
	}
	drop if date == "drop"
	tempfile crosswalk_date
	save "`crosswalk_date'"
restore


merge m:m FIPS_nyc_kansas date using "`crosswalk_date'"
drop _merge
sort FIPS_nyc_kansas  date FIPS
compress

*** Apply weights
replace cases = cases*weight
replace deaths = deaths*weight

*** Collapse by FIPS (this will aggregate the parts of Kansas that I have assigned by weight with the remainders of these 4 counties)
collapse (sum) cases deaths,by(FIPS date)

** Create date num
gen  date_num = date(date,"YMD") 
format date_num %td
drop date

order FIPS date date_num cases deaths
ren cases cases_nyt
ren deaths deaths_nyt

lab var cases_nyt "Cumulative cases from NY Times"
lab var deaths_nyt "Cumulative deaths from NY Times"

save "data/output/covid-nyt.dta",replace

***********************************************************
***********************************************************
***** Download and clean COVID data USA Facts (https://usafacts.org/visualizations/coronavirus-covid-19-spread-map/)
***********************************************************
***********************************************************
foreach d in deaths cases {
	
	import delimited "data/input/covid-usaf/covid-usaf-`d'-2020-10-02.csv",clear
	ren ïcountyfips countyfips
	drop countyname state statefips

	foreach var of varlist v* {
	 local lab`var': variable label `var'
	  local lab`var'=date("`lab`var''","MDY",2050)
	  local lab`var': display %d `lab`var''
	  rename `var'  `d'`lab`var''
	  }
	*** Drop state wide non-allocated deaths  
	drop if   countyfips ==0

	*** Drop NYC non-allocated
	drop if   countyfips ==1

	reshape long `d' ,i(countyfips ) j(date) string
	gen date_num = date(date,"DMY")
	format date_num %td
	
	drop date

	sort countyfips date_num
	
	gen FIPS=string(countyfips,"%05.0f")
	drop countyfips
	tempfile `d'
	save "``d''"
}

use "`deaths'",clear
merge 1:1 FIPS date_num using "`cases'"
drop _merge
keeporder FIPS date_num cases deaths
ren cases cases_usaf
ren deaths deaths_usaf
lab var cases_usaf "Cumulative cases from USA Facts"
lab var deaths_usaf "Cumulative deaths from USA Facts"

save "data/output/covid-usaf.dta",replace
   
***********************************************************
***********************************************************
**** Create county-level outcomes from NYTimes and USA Facts COVID data
***********************************************************
***********************************************************   
foreach dataset in usaf nyt {
	
use  "data/output/covid-`dataset'.dta",clear

* Merge with population 
merge m:1 FIPS using "data/output/county-demographics.dta",keepusing(dem_totpop)
keep if _merge ==3
drop _merge

ren deaths_`dataset' deaths_cum
ren cases_`dataset' cases_cum

*** Total number of deaths and cases
sort FIPS date_num
by FIPS: egen deaths_tot = max(deaths_cum)
by FIPS: egen cases_tot = max(cases_cum)

lab var deaths_cum "Cummulative deaths"
lab var cases_cum "Cummulative cases"

lab var deaths_tot "Total deaths"
lab var cases_tot "Total cases"

*** Keep county summaries
collapse (mean) deaths_tot cases_tot  dem_totpop,by(FIPS)

*** Labels and variable names
lab var deaths_tot "Total deaths"
lab var cases_tot "Total cases"

* Genearte rates and logs of total deaths and cases
foreach v in deaths_tot cases_tot {
	
	gen `v'_r = (`v'/dem_totpop)*100000
	gen `v'_log = ln(`v'+1)
	gen `v'_r_log = ln(((`v'+1)/dem_totpop)*100000)
	
}

drop dem_totpop

foreach v in deaths cases {
	lab var `v'_tot_r "Total `v' per 100,000"
	lab var `v'_tot_log "Total `v' (log)"
	lab var `v'_tot_r_log "Total `v' per 100,000 (log)"
}

order FIPS ///
deaths_tot  deaths_tot_r  deaths_tot_log  deaths_tot_r_log  cases_tot  cases_tot_r  cases_tot_log  cases_tot_r_log 
ren * *_`dataset'
ren FIPS* FIPS

*** Rename outcomes
ren deaths_tot_`dataset'  d_`dataset'
ren deaths_tot_r_log_`dataset' d_r_log_`dataset'
ren deaths_tot_r_`dataset'  d_r_`dataset'

ren cases_tot_`dataset'  c_`dataset'
ren cases_tot_r_log_`dataset' c_r_log_`dataset'
ren cases_tot_r_`dataset' c_r_`dataset'

*** Set log rates to 0 if rate was 0
replace d_r_log_`dataset' = 0 if d_`dataset' ==0
replace c_r_log_`dataset' = 0 if c_`dataset' ==0

save "data/output/covid-`dataset'-ouctomes.dta",replace

}

***********************************************************
***********************************************************
****  COVID data by race CDC
***********************************************************
***********************************************************
import delimited "data/input/covid-race-cdc/Provisional_COVID-19_Death_Counts_by_County_and_Race_20200930.csv", clear
keep if indicator=="Distribution of COVID-19 deaths (%)"
gen  FIPS = string(fipscode,"%05.0f")

ren  nonhispanicwhite cdc_d_white
ren nonhispanicblack cdc_d_black
ren hispanic cdc_d_hispanic

foreach v in white black hispanic {
	gen cdc_d_`v'_cov = covid19deaths * cdc_d_`v'
	ren cdc_d_`v' cdc_p_d_`v'_cov
	lab var cdc_p_d_`v'_cov "Share of all COVID-19 deaths that are `v'"
}
	
keep FIPS *_cov

*** Merge with demographics
merge 1:1 FIPS using "data/output/county-demographics.dta",keepusing(dem_totpop dem_black dem_hispanic dem_white)
keep if _merge ==3
drop _merge

*** Calcualte rates
foreach v in white black hispanic {
	gen count_`v' = (dem_`v'/100) * dem_totpop
	gen cdc_d_r_`v'_cov  = (cdc_d_`v'_cov  /count_`v')*100000
	gen cdc_d_log_r_`v'_cov  = ln(cdc_d_r_`v'_cov )
	replace cdc_d_log_r_`v'_cov  = 0 if cdc_d_r_`v'_cov  ==0
	
}
	
ren cdc_* *

*** Racial/ethnic gaps
gen d_log_r_bw_cov = d_log_r_black_cov - d_log_r_white_cov
gen d_log_r_hw_cov = d_log_r_hispanic_cov - d_log_r_white_cov

lab var d_log_r_bw_cov "Black-white COVID-19 mortality gap"
lab var d_log_r_hw_cov "Hispanic-white COVID-19 mortality gap"

keeporder FIPS d_log_r_bw_cov d_log_r_hw_cov

compress
save "data/output/cdc-covid-deaths-by-race.dta",replace
