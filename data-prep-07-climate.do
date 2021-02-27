**********************************************************************************************************************
**********************************************************************************************************************
***** Replication code for "Using Machine Learning to Estimate the Effect of Racial Segregation on COVID-19 Mortality in the United States" (PNAS, 2021)
***** This file does: Data Preparation, Views on Climate Change
***** Author: Gerard Torrats-Espinosa
***** Date: Dec 24, 2020 

***** Input Data: Yale Climate Opinion Maps 2019 (https://climatecommunication.yale.edu/visualizations-data/ycom-us/)
**********************************************************************************************************************
**********************************************************************************************************************
set more off
import delimited "data/input/climate-change-yale/YCOM_2019_Data.csv",clear
keep if geotype == "County"
gen FIPS = string(geoid,"%05.0f") 
drop geotype geoid geoname totalpop

lab var happening	"% think GW is happening"
lab var regulate	"% support regulating CO2 as a pollutant"

ren * cli_*
ren *FIPS FIPS
order FIPS
compress
save "data/output/yale-climate-poll.dta",replace
