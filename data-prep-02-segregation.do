**********************************************************************************************************************
**********************************************************************************************************************
***** Replication code for "Using Machine Learning to Estimate the Effect of Racial Segregation on COVID-19 Mortality in the United States" (PNAS, 2021)
***** This file does: Data Preparation, Segregation
***** Author: Gerard Torrats-Espinosa
***** Date: Dec 24, 2020 

**** Input Data: Social Explorer, ACS 2014-2018, Tract-level (https://www.socialexplorer.com/)
**********************************************************************************************************************
**********************************************************************************************************************
set more off
set maxvar 10000

infile using "data/input/demographics/tract-acs2018.dct", using("data/input/demographics/tract-acs2018.txt") clear

ren FIPS tract
gen FIPS = substr(tract,1,5)

* Drop PR
drop if STATE =="72"

* Keep counties with more than one tract
bys FIPS: gen tracts_num = _N 
drop if tracts_num ==1

***** Racial Segregation: Relative Diversity Index
***********************************************************
ren A01001_001 totpop
ren A04001_003 race_white
ren A04001_004 race_black
ren A04001_006 race_asian
ren A04001_010 race_hisp
gen race_other = totpop - race_white - race_black - race_asian - race_hisp

ren PCT_A04001_003 race_p_white
ren PCT_A04001_004 race_p_black
ren PCT_A04001_006 race_p_asian
ren PCT_A04001_010 race_p_hisp
replace race_p_white = race_p_white/100
replace race_p_black = race_p_black/100
replace race_p_asian = race_p_asian/100
replace race_p_hisp = race_p_hisp/100
gen race_p_other = 1 - race_p_white - race_p_black - race_p_asian - race_p_hisp
replace race_p_other = 0 if race_p_other<0

*** Multi-Group (Computed step-by-step)
local race_groups white black asian hisp other

* Tract Simpson Index
foreach r of local race_groups {
	gen si_t_`r' = race_p_`r' * (1 - race_p_`r')
}
gen si_t_multi = si_t_white + si_t_black + si_t_asian + si_t_hisp + si_t_other

* County Simpson Index
bys FIPS: egen c_totpop = sum(totpop)
foreach r of local race_groups {
	bys FIPS: egen c_race_`r' = sum(race_`r')
	gen c_race_p_`r' = c_race_`r'/c_totpop 
	gen si_c_`r' = c_race_p_`r' * (1 - c_race_p_`r')
}
gen si_c_multi = si_c_white + si_c_black + si_c_asian + si_c_hisp + si_c_other

* County Relative Diversity Index
gen diff_si_c_t = (si_c_multi - si_t_multi)*totpop
preserve
collapse (sum) diff_si_c_t (mean) si_c_multi c_totpop, by(FIPS)
gen seg_race_all_reldiv = diff_si_c_t/(si_c_multi*c_totpop)
tempfile reldiv_step_by_step
save "`reldiv_step_by_step'"
restore

*** Multi-Group (Computed using "seg" command)
seg race_white  race_black  race_asian race_hisp race_other, r by(FIPS)  file(data/intermediate/seg-race-all-relative-diversity.dta) replace

* Verify that step-by-step approach and the "seg" command yield the same result
preserve
use "data/intermediate/seg-race-all-relative-diversity.dta",clear
merge 1:1 FIPS using "`reldiv_step_by_step'"
corr seg_race_all_reldiv Rseg
gen diff = seg_race_all_reldiv - Rseg
sum diff
restore
* NOTE: Since the step-by-step approach and the "seg" command yield the same values, I will use the "seg" command for all remaining segregation indices

*** Black-white
seg race_white  race_black, r by(FIPS) file(data/intermediate/seg-race-black-white-relative-diversity.dta) replace

*** Hispanic-white
seg race_white  race_hisp, r by(FIPS) file(data/intermediate/seg-race-hispanic-white-relative-diversity.dta) replace

***** Racial Segregation: Theil Index
***********************************************************
*** Multi-group
seg race_white  race_black  race_asian race_hisp race_other, h by(FIPS) file(data/intermediate/seg-race-all-theil.dta) replace

*** Black-white
seg race_white  race_black, h by(FIPS) file(data/intermediate/seg-race-black-white-theil.dta) replace

*** Hispanic-white
seg race_white  race_hisp, h by(FIPS) file(data/intermediate/seg-race-hispanic-white-theil.dta) replace

***** Age Segregation: Theil Index
***********************************************************
ren A01001_006 age_1824
ren A01001_007 age_2534
ren A01001_008 age_3544
ren A01001_009 age_4554
ren A01001_010 age_5564
ren A01001_011 age_6574
ren A01001_012 age_7584
ren A01001_013 age_8599
seg age_1824 age_2534 age_3544 age_4554 age_5564 age_6574 age_7584 age_8599, h by(FIPS) file(data/intermediate/seg-age-all-theil.dta) replace

***** Income Segregation: Theil Index
***********************************************************
seg A14001_002 A14001_003 A14001_004 A14001_005 A14001_006 A14001_007 A14001_008 A14001_009 A14001_010 A14001_011 A14001_012 A14001_013 A14001_014 A14001_015 A14001_016 A14001_017, h by(FIPS) file(data/intermediate/seg-income-all-theil.dta) replace

***** Merge all segregation indices
***********************************************************
use "data/intermediate/seg-race-all-relative-diversity.dta",clear
replace Rseg = 0 if Rseg<0 & Rseg !=.
ren *seg seg_reldiv_all
keep FIPS seg_* 
lab var seg_reldiv_all "Multi-group Relative Diversity Index"

merge 1:1 FIPS using "data/intermediate/seg-race-black-white-relative-diversity.dta"
drop _merge
replace Rseg = 0 if Rseg<0 & Rseg !=.
ren *seg seg_reldiv_bw
keep FIPS seg_* 
lab var seg_reldiv_bw "Black-white Relative Diversity Index"

merge 1:1 FIPS using "data/intermediate/seg-race-hispanic-white-relative-diversity.dta"
drop _merge
replace Rseg = 0 if Rseg<0 & Rseg !=.
ren *seg seg_reldiv_hw
keep FIPS seg_* 
lab var seg_reldiv_hw "Hispanic-white Relative Diversity Index"

merge 1:1 FIPS using "data/intermediate/seg-race-all-theil.dta"
drop _merge
replace Hseg = 0 if Hseg<0 & Hseg !=.
ren *seg seg_theil_all
keep FIPS seg_* 
lab var seg_theil_all "Multi-group Theil Segregation Index"

merge 1:1 FIPS using "data/intermediate/seg-race-black-white-theil.dta"
drop _merge
replace Hseg = 0 if Hseg<0 & Hseg !=.
ren *seg seg_theil_bw
keep FIPS seg_* 
lab var seg_theil_bw "Black-white Theil Segregation Index"

merge 1:1 FIPS using "data/intermediate/seg-race-hispanic-white-theil.dta"
drop _merge
replace Hseg = 0 if Hseg<0 & Hseg !=.
ren *seg seg_theil_hw
keep FIPS seg_* 
lab var seg_theil_hw "Hispanic-white Theil Segregation Index"

merge 1:1 FIPS using  "data/intermediate/seg-age-all-theil.dta"
drop _merge
replace Hseg = 0 if Hseg<0 & Hseg !=.
ren Hseg seg_age_all_theil
keep FIPS seg_* 
lab var seg_age_all_theil "Age segregation (Theil)"

merge 1:1 FIPS using "data/intermediate/seg-income-all-theil.dta"
drop _merge
replace Hseg = 0 if Hseg<0 & Hseg !=.
ren *seg seg_inc_all_theil
keep FIPS seg_* 
lab var seg_inc_all_theil "Income segregation (Theil)"

save "data/output/segregation.dta",replace
