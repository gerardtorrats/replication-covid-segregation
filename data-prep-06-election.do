**********************************************************************************************************************
**********************************************************************************************************************
***** Replication code for "Using Machine Learning to Estimate the Effect of Racial Segregation on COVID-19 Mortality in the United States" (PNAS, 2021)
***** This file does: Data Preparation, 2016 Election
***** Author: Gerard Torrats-Espinosa
***** Date: Dec 24, 2020 

***** Input Data: MIT Election Lab (https://electionlab.mit.edu/)
**********************************************************************************************************************
**********************************************************************************************************************
set more off
import delimited "data/input/2016-election/2016_US_County_Level_Presidential_Results.csv", clear 
gen FIPS = string(combined_fips,"%05.0f")
drop if state_abbr =="AK"
ren per_gop pol_rep2016
replace pol_rep2016 = pol_rep2016*100
lab var pol_rep2016 "% Voted Republican in 2016"
ren per_dem pol_dem2016
replace pol_dem2016 = pol_dem2016*100
lab var pol_dem2016 "% Voted Democrat in 2016"
keep FIPS pol_rep2016 pol_dem2016
save "data/output/2016-election.dta", replace
