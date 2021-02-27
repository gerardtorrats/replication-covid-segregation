**********************************************************************************************************************
**********************************************************************************************************************
***** Replication code for "Using Machine Learning to Estimate the Effect of Racial Segregation on COVID-19 Mortality in the United States" (PNAS, 2021)
***** This file does: Data Preparation, Airport Traffic
***** Author: Gerard Torrats-Espinosa
***** Date: Dec 24, 2020 

***** Input Data: Bureau of Transportation Statistics (https://www.transtats.bts.gov/DL_SelectFields.asp?Table_ID=292)
**********************************************************************************************************************
**********************************************************************************************************************
set more off
import delimited "data/input/airport-traffic/bts-transtats-2020.csv",clear

*** Focus on months January-March
keep if month <=3

*** Only flights that have US airport as destination
keep if dest_country =="US"

ren dest dest_airport

*** Domestic travel
gen pass_dom = 0
replace pass_dom = passengers if origin_country=="US"

*** International travel, all
gen pass_int_all = 0
replace pass_int_all = passengers if origin_country!="US"

*** International travel, Europe
gen pass_int_eur = 0
replace pass_int_eur = passengers if origin_country=="AT" || ///
origin_country=="BE" || ///
origin_country=="BG" || ///
origin_country=="HR" || ///
origin_country=="CY" || ///
origin_country=="CZ" || ///
origin_country=="DK" || ///
origin_country=="EE" || ///
origin_country=="FI" || ///
origin_country=="FR" || ///
origin_country=="DE" || ///
origin_country=="GR" || ///
origin_country=="HU" || ///
origin_country=="IE" || ///
origin_country=="IT" || ///
origin_country=="LV" || ///
origin_country=="LT" || ///
origin_country=="LU" || ///
origin_country=="MT" || ///
origin_country=="NL" || ///
origin_country=="PO" || ///
origin_country=="PT" || ///
origin_country=="RO" || ///
origin_country=="SK" || ///
origin_country=="SI" || ///
origin_country=="ES" || ///
origin_country=="SE" || ///
origin_country=="AL" || ///
origin_country=="AD" || ///
origin_country=="AM" || /// 
origin_country=="BY" || ///
origin_country=="BA" || ///
origin_country=="FO" || ///
origin_country=="GE" || ///
origin_country=="GI" || ///
origin_country=="IS" || ///
origin_country=="IM" || ///
origin_country=="XK" || ///
origin_country=="LI" || ///
origin_country=="MK" || ///
origin_country=="MD" || ///
origin_country=="MC" || ///
origin_country=="ME" || ///
origin_country=="NO" || ///
origin_country=="RU" || ///
origin_country=="SM" || ///
origin_country=="RS" || ///
origin_country=="CH" || ///
origin_country=="TR" || ///
origin_country=="UA" || ///
origin_country=="GB" || ///
origin_country=="VA"

*** International travel, Asia
gen pass_int_asia = 0
replace pass_int_asia = passengers if origin_country=="AF" || ///
origin_country=="AZ" || ///
origin_country=="BH" || ///
origin_country=="BD" || ///
origin_country=="BT" || ///
origin_country=="IO" || ///
origin_country=="BN" || ///
origin_country=="KH" || ///
origin_country=="CN" || ///
origin_country=="CX" || ///
origin_country=="CC" || ///
origin_country=="CY" || ///
origin_country=="GE" || ///
origin_country=="HK" || ///
origin_country=="IN" || ///
origin_country=="ID" || ///
origin_country=="IR" || ///
origin_country=="IQ" || ///
origin_country=="IL" || ///
origin_country=="JP" || ///
origin_country=="JO" || ///
origin_country=="KZ" || ///
origin_country=="KP" || ///
origin_country=="KR" || ///
origin_country=="KW" || ///
origin_country=="KG" || ///
origin_country=="LA" || ///
origin_country=="LB" || ///
origin_country=="MO" || ///
origin_country=="MY" || ///
origin_country=="MV" || ///
origin_country=="MN" || ///
origin_country=="MM" || ///
origin_country=="NP" || ///
origin_country=="OM" || ///
origin_country=="PK" || ///
origin_country=="PS" || ///
origin_country=="PH" || ///
origin_country=="QA" || ///
origin_country=="SA" || ///
origin_country=="SG" || ///
origin_country=="LK" || ///
origin_country=="SY" || ///
origin_country=="TW" || ///
origin_country=="TJ" || ///
origin_country=="TH" || ///
origin_country=="TL" || ///
origin_country=="TR" || ///
origin_country=="TM" || ///
origin_country=="AE" || ///
origin_country=="UZ" || ///
origin_country=="VN" || ///
origin_country=="YE"

*** Create sums of passengers arriving at each US ariport
ren dest_airport airport
collapse (sum) pass_dom pass_int_all pass_int_asia pass_int_eur,by(airport)

lab var airport "Airport of destination"
lab var pass_dom "Mean Jan-Mar passengers from flights with domestic origin"
lab var pass_int_all "Mean Jan-Mar passengers from flights with international origin"
lab var pass_int_asia "Mean Jan-Mar passengers from flights with European origin"
lab var pass_int_eur "Mean Jan-Mar passengers from flights with Asian origin"

save "data/intermediate/passengers-Q12020-by-ariport.dta",replace

*** Identify airports within 100 miles of county centroid
import delimited "data/input/airport-traffic/airports-gis/distance-matrix-county-centroid-to-all-airpors.csv", clear 

* Convert distance to miles
replace distance = distance/1609.34
* Keep if within 100 miles
keep if distance<=100

gen  FIPS = string(inputid,"%05.0f")
ren targetid airport
lab var distance "Distance between County Centroid and Airport"
keeporder FIPS airport distance
save "data/intermediate/aiports-wihin-100miles.dta",replace

*** Merge aiport traffic and county-airpot distances
use "data/intermediate/passengers-Q12020-by-ariport.dta"
merge 1:m airport using "data/intermediate/aiports-wihin-100miles.dta"
keep if _merge ==3
drop _merge

* Create sum of passengers in all airports within 100miles
collapse (sum) pass_dom   pass_int_all pass_int_asia pass_int_eur,by(FIPS)

ren * air_*
ren *FIPS FIPS

* Create rates per 1,000 and logs
merge 1:1 FIPS using "data/output/county-demographics.dta",keepusing(dem_totpop)
drop if _merge ==2
drop _merge

foreach v of varlist air* {
	gen `v'_r = (`v'/dem_totpop)*1000
	gen `v'_log = ln(`v'+1)
	gen `v'_r_log = ln(((`v'+1)/dem_totpop)*1000)
}

drop dem_totpop

lab var air_pass_dom "Pass. domestic flights landing in aiports within 100mi in Jan-Mar"
lab var air_pass_int_all "Pass. international flights landing in aiports within 100mi in Jan-Mar"
lab var air_pass_int_asia "Pass. Europe flights landing in aiports within 100mi in Jan-Mar"
lab var air_pass_int_eur "Pass. Asian flights landing in aiports within 100mi in Jan-Mar"

lab var air_pass_dom_r "Pass. domestic flights landing in aiports within 100mi in Jan-Mar (rate per 1,000)"
lab var air_pass_int_all_r "Pass. international flights landing in aiports within 100mi in Jan-Mar (rate per 1,000)"
lab var air_pass_int_asia_r "Pass. Europe flights landing in aiports within 100mi in Jan-Mar (rate per 1,000)"
lab var air_pass_int_eur_r "Pass. Asian flights landing in aiports within 100mi in Jan-Mar (rate per 1,000)"

lab var air_pass_dom_log "Pass. domestic flights landing in aiports within 100mi in Jan-Mar (log)"
lab var air_pass_int_all_log "Pass. international flights landing in aiports within 100mi in Jan-Mar (log)"
lab var air_pass_int_asia_log "Pass. Europe flights landing in aiports within 100mi in Jan-Mar (log)"
lab var air_pass_int_eur_log "Pass. Asian flights landing in aiports within 100mi in Jan-Mar (log)"

lab var air_pass_dom_r_log "Pass. domestic flights landing in aiports within 100mi in Jan-Mar (log of rate per 1,000)"
lab var air_pass_int_all_r_log "Pass. international flights landing in aiports within 100mi in Jan-Mar (log of rate per 1,000)"
lab var air_pass_int_asia_r_log "Pass. Europe flights landing in aiports within 100mi in Jan-Mar (log of rate per 1,000)"
lab var air_pass_int_eur_r_log "Pass. Asian flights landing in aiports within 100mi in Jan-Mar (log of rate per 1,000)"


* Shorten variable names
ren air_pass_dom_log air_dom
ren air_pass_int_all_log air_int

save "data/output/passenger-traffic-in100miles-Q1-2020.dta",replace
