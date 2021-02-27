**********************************************************************************************************************
**********************************************************************************************************************
***** Replication code for "Using Machine Learning to Estimate the Effect of Racial Segregation on COVID-19 Mortality in the United States" (PNAS, 2021)
***** This file does: Data Preparation, Demographics
***** Author: Gerard Torrats-Espinosa
***** Date: Dec 24, 2020 

**** Input Data: Social Explorer, ACS 2014-2018, County-level (https://www.socialexplorer.com/)
**********************************************************************************************************************
**********************************************************************************************************************
set more off
set maxvar 10000

infile using "data/input/demographics/acs-2018-county-v2.dct", using("data/input/demographics/acs-2018-county-v2.txt") clear

ren A00001_001 dem_totpop
ren A00002_002 dem_popdens 
gen dem_log_popdens = ln(dem_popdens)

ren PCT_A01001A_006 dem_25under
ren PCT_A01001B_010 dem_65over

ren PCT_A04001_003 dem_white 
ren PCT_A04001_004 dem_black 
ren PCT_A04001_006 dem_asian 
ren PCT_A04001_010 dem_hispanic 

ren PCT_A10024_007 dem_hhold_6_person  
ren PCT_A10024_008 dem_hhold_7more_person 
gen dem_hhold_6more = dem_hhold_6_person + dem_hhold_7more_person
ren PCT_A10007_007 dem_gchild 

ren PCT_B12001_002 dem_lesshs 
ren PCT_B12001_003 dem_hs 
ren PCT_B12001_004 dem_college_more 

ren PCT_A17002_006 dem_unemployed 
ren  PCT_A17006B_003 dem_unemployed_black
ren  PCT_A17006D_003 dem_unemployed_asian
ren  PCT_A17006H_003 dem_unemployed_hispanic
ren  PCT_A17006I_003 dem_unemployed_white
gen dem_unemployed_wb = dem_unemployed_white - dem_unemployed_black
gen dem_unemployed_wa = dem_unemployed_white - dem_unemployed_asian
gen dem_unemployed_wh = dem_unemployed_white - dem_unemployed_hispanic
lab var dem_unemployed_wb "White-black unemployment rate gap"
lab var dem_unemployed_wa "White-Asian unemployment rate gap"
lab var dem_unemployed_wh "White-Hispanic unemployment rate gap"

ren PCT_A17009_003 dem_pub_sect
ren PCT_A17004_003 dem_construction

ren A14006_001 dem_med_hhinc 
ren A14007_003 dem_med_hhinc_black
ren A14007_005 dem_med_hhinc_asian
ren A14007_009 dem_med_hhinc_hispanic
ren A14007_010 dem_med_hhinc_white
gen dem_med_hhinc_wb = dem_med_hhinc_white - dem_med_hhinc_black
gen dem_med_hhinc_wa = dem_med_hhinc_white - dem_med_hhinc_asian
gen dem_med_hhinc_wh = dem_med_hhinc_white - dem_med_hhinc_hispanic
lab var dem_med_hhinc_wb "White-black median household income gap"
lab var dem_med_hhinc_wa "White-Asian median household income gap"
lab var dem_med_hhinc_wh "White-Hispanic median household income gap"

ren PCT_A10044_003 dem_hu_vacant 
ren PCT_A10032_010 dem_hu_50more 

gen dem_pov = ((A13003A_002 + A13003B_002 + A13003C_002) / (A13003A_001 + A13003B_001 + A13003C_001))*100
lab var dem_pov "% Below Poverty Line"
ren PCT_A13005B_002 dem_pov_black
ren PCT_A13005D_002 dem_pov_asian
ren PCT_A13005H_002 dem_pov_hispanic
ren PCT_A13005I_002 dem_pov_white
gen dem_pov_wb = dem_pov_white - dem_pov_black
gen dem_pov_wa = dem_pov_white - dem_pov_asian
gen dem_pov_wh = dem_pov_white - dem_pov_hispanic
lab var dem_pov_wb "White-black poverty rate gap"
lab var dem_pov_wa "White-Asian poverty rate gap"
lab var dem_pov_wh "White-Hispanic poverty rate gap"

ren PCT_A09005_003 dem_publictrans 
ren PCT_A09005_008 dem_comm_wfh 
ren A09003_001 dem_comm_avg_time 

ren PCT_A20001_003 dem_insured 

keep FIPS dem_*  

save "data/output/county-demographics.dta", replace
