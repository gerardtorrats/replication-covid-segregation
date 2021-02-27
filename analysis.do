**********************************************************************************************************************
**********************************************************************************************************************
***** Replication code for "Using Machine Learning to Estimate the Effect of Racial Segregation on COVID-19 Mortality in the United States" (PNAS, 2021)
***** This file does: Analysis (outputs all tables and figures in the main article and the SI Appendix) 
***** Author: Gerard Torrats-Espinosa
***** Date: Dec 24, 2020 
**********************************************************************************************************************
**********************************************************************************************************************
set more off
estimates clear
use "merged-for-analysis.dta",clear

*******************************************************
***** Keep relevant variables
*******************************************************
*** Create macros with variable categories
local Segregation  seg_theil_all seg_theil_bw seg_theil_hw seg_reldiv_all seg_reldiv_bw seg_reldiv_hw 
local Population  dem_totpop   dem_popdens
local Age dem_25under dem_65over seg_age_all
local Race   dem_asian dem_black dem_hispanic dem_white
local SES dem_lesshs dem_college_more dem_med_hhinc dem_pov seg_inc_all 
local Interaction  dem_log_popdens dem_comm_avg_time dem_publictrans dem_comm_wfh dem_unemployed dem_hu_vacant dem_hhold_6more   dem_hu_50more  dem_gchild air_dom air_int 
local Capital  cbp_est_civic cbp_est_relig cbp_est_sport
local Health_Risk rwj_life_expec  rwj_prem_mort   rwj_diabetes_rate rwj_hiv_rate rwj_obese rwj_smoking  rwj_drinking rwj_phys_inact rwj_insuf_sleep     
local Health_Capacity rwj_physicians_r rwj_other_pcp_rate  hos_beds dem_insured  rwj_flu_vaccine
local Pollution rwj_air_pollution
local Essential_Business  cbp_foodstores cbp_hospitals cbp_nurshomes cbp_pharmacies dem_pub_sect dem_construction
local Politics pol_dem2016 cli_happening  cli_regulate
local race_diffs dem_pov_wb dem_pov_wa dem_pov_wh dem_med_hhinc_wb dem_med_hhinc_wa dem_med_hhinc_wh dem_unemployed_wb dem_unemployed_wa dem_unemployed_wh rwj_life_expec_wb rwj_life_expec_wh

local predictors  `SES'  `Age'  `Interaction'  `Capital'  `Health_Risk'  `Health_Capacity'  `Pollution' `Essential_Business' `Politics'

local varskeep region* `Population' `Segregation' `Race'  `predictors'  `race_diffs'

*** Keep variables for analysis
keeporder FIPS county_name_state state_ab state_name   c_* d_*  `varskeep' 

*** Create state dummies
levelsof state_ab,local(states_abs)
foreach s of local states_abs {
	gen st_`s' =(state_ab =="`s'")
	lab var st_`s' "`s'"
}

local states  st_AL st_AR st_AZ st_CA st_CO st_CT st_DE st_FL st_GA st_IA st_ID st_IL st_IN st_KS st_KY st_LA st_MA st_MD st_ME st_MI st_MN st_MO st_MS st_MT st_NC st_ND st_NE st_NH st_NJ st_NM st_NV st_NY st_OH st_OK st_OR st_PA st_RI st_SC st_TN st_TX st_UT st_VA st_VT st_WA st_WI st_WV st_WY

*******************************************************
***** Standarize and residualize variables
*******************************************************
*** Standarize variables
foreach v of varlist d_* c_*  `Population' `Segregation' `Race'  `predictors'  `race_diffs'  {
	egen s_`v' = std(`v')
	local lbl : variable label `v' 
    label var  s_`v' "`lbl'"
}

local std_preds
foreach v of local predictors { 
             local std_preds `std_preds' s_`v'
}

local std_race
foreach v of local Race { 
             local std_race `std_race' s_`v'
}

*** Combine standarized predictors and racial composition variables in one macro
local std_race_preds `std_race'  `std_preds' 

*** Residualize COVID outcomes and segregation from state fixed effects and standarize them
encode state_ab,gen(state_id)
foreach v of varlist d_r_log_usaf  c_r_log_usaf seg_reldiv* seg_theil*  {
	reg `v' i.state_id 
	predict r_`v',residuals
	egen sr_`v' = std(r_`v')
	local lbl : variable label `v' 
    label var  sr_`v' "`lbl'"
	drop r_`v'
}

*** Simplify names of ouctome and segregation variables
ren d_r_log_usaf deaths_r
ren c_r_log_usaf cases_r

ren s_d_r_log_usaf s_deaths_r
ren s_c_r_log_usaf s_cases_r

ren sr_d_r_log_usaf sr_deaths_r
ren sr_c_r_log_usaf sr_cases_r

foreach s in s sr {
	ren  `s'_seg_reldiv_all `s'_rd_all
	ren  `s'_seg_reldiv_bw `s'_rd_bw
	ren  `s'_seg_reldiv_hw `s'_rd_hw
	ren  `s'_seg_theil_all `s'_th_all
	ren  `s'_seg_theil_bw `s'_th_bw
	ren  `s'_seg_theil_hw `s'_th_hw
	
}

*******************************************************
***** Figure 2: Bivariate scatterplots (net of state fixed effects)
*******************************************************
foreach i in rd th {
	scatter sr_deaths_r sr_`i'_all [aw=dem_totpop]  , msymbol(circle_hollow)  mcolor(gray%90) msize(.8) mlwidth(.2) || ///
	lfit sr_deaths_r sr_`i'_all [aw=dem_totpop], lcolor(black) lwidth(.2) ///
	scheme(s1mono)  plotregion(lcolor(none))  ///
	xlabel(-4 (2) 6 , labsize(vlarge) format(%6.0fc) ) ///
	ylabel(-4 (2) 6 ,labsize(vlarge) format(%6.0fc)) ///
	yscale(range(-4 6.5)) ///
	xtitle("Residualized racial segregation", size(huge)) ///
	ytitle("Residualized log death rate", size(huge)) ///
	legend(off )
	graph export analysis-output/scatter-death-rate-`i'.pdf,replace

	scatter sr_cases_r sr_`i'_all [aw=dem_totpop]  , msymbol(circle_hollow)  mcolor(gray%90) msize(.8) mlwidth(.2) || ///
	lfit sr_cases_r sr_`i'_all [aw=dem_totpop], lcolor(black) lwidth(.2) ///
	scheme(s1mono)  plotregion(lcolor(none))  ///
	xlabel(-4 (2) 6 , labsize(vlarge) format(%6.0fc) ) ///
	ylabel(-4 (2) 6 ,labsize(vlarge) format(%6.0fc)) ///
	yscale(range(-4 6.5)) ///
	xtitle("Residualized racial segregation", size(huge)) ///
	ytitle("Residualized log case rate", size(huge)) ///
	legend(off )
	graph export analysis-output/scatter-case-rate-`i'.pdf,replace

}

*******************************************************
***** Figure S2: Bivaraite scatterplot Theil and Realtive Diveristy
*******************************************************
reg seg_theil_all seg_reldiv_all [aw=dem_totpop] 
local r2: display %6.2f `e(r2)'
scatter seg_theil_all seg_reldiv_all [aw=dem_totpop]  , msymbol(circle_hollow)  mcolor(gray%90) msize(.8) mlwidth(.2) || ///
	lfit seg_theil_all seg_reldiv_all [aw=dem_totpop], lcolor(black) lwidth(.2) ///
	scheme(s1mono)  plotregion(lcolor(none))  ///
	xlabel(0 (.2) .6 , labsize(large) format(%6.1fc) ) ///
	ylabel(0 (.2) .6 ,labsize(large) format(%6.1fc)) ///
	yscale(range()) ///
	ytitle("Multi-group Theil Index", size(large)) ///
	xtitle("Multi-group Relative Diversity Index", size(large)) ///
	legend(off ) ///
	text(.4 .55 "R{superscript:2} =  `r2'",size(medlarge))
	graph export analysis-output/scatter-theil-reldiv.pdf,replace
	
*******************************************************
***** Figures 1, S1, and S3: Coefficient plots plots of regression of controls predicting COVID ouctomes and segregation
*******************************************************
ren s_rd_all s_reldiv
ren s_th_all s_theil

foreach y in deaths_r reldiv theil {
	foreach p of local predictors {
		areg s_`y' s_`p' [aw=dem_totpop],a(state_ab) cluster(state_ab)
		estimates store `y'_`p'
		}
		
	foreach p of local Race {
		areg s_`y' s_`p' [aw=dem_totpop], a(state_ab) cluster(state_ab)
		estimates store `y'_`p'
		}
}

foreach o in deaths_r {
	coefplot (`o'_dem_25under `o'_dem_65over `o'_seg_age_all `o'_dem_asian `o'_dem_black `o'_dem_hispanic `o'_dem_white `o'_dem_lesshs `o'_dem_college_more `o'_dem_med_hhinc `o'_dem_pov   `o'_seg_inc_all  `o'_dem_log_popdens `o'_dem_comm_avg_time `o'_dem_publictrans `o'_dem_comm_wfh `o'_dem_unemployed `o'_dem_hu_vacant `o'_dem_hhold_6more `o'_dem_hu_50more  `o'_dem_gchild   `o'_air_dom `o'_air_int `o'_cbp_est_civic `o'_cbp_est_relig `o'_cbp_est_sport `o'_rwj_life_expec `o'_rwj_prem_mort `o'_rwj_diabetes_rate `o'_rwj_obese `o'_rwj_hiv_rate `o'_rwj_smoking `o'_rwj_drinking  `o'_rwj_insuf_sleep `o'_rwj_phys_inact  `o'_rwj_physicians_r `o'_rwj_other_pcp_rate `o'_hos_beds `o'_dem_insured  `o'_rwj_flu_vaccine `o'_rwj_air_pollution `o'_cbp_foodstores `o'_cbp_hospitals `o'_cbp_nurshomes `o'_cbp_pharmacies `o'_dem_pub_sect `o'_dem_construction `o'_pol_dem2016 `o'_cli_happening  `o'_cli_regulate), bylabel("{bf: `o'}" "{bf:rate}")   subtitle(, size(small)) ///
	 drop(_cons) ///
	ysize(8) ///
	  nooffsets    ///
	xline(0,lwidth(.2) lpattern(solid) lcolor(red)) ///
	byopts(cols(3) legend(off)) ///
	levels(95) ///
	lpatt(solid) mcol(black)   msym(o) msize(.7) lwidth(.1)  ciopts( recast(rcap) lpatt(solid) lcol(black) lwidth(.15)) ///
	scheme(s1mono)  plotregion(lcolor(none))  ///
	grid(glpattern(dot) glwidth(vthin) glcolor(gray) )  ///
	xlabel(-.5(.25).5 , labsize(vsmall) ) ///
	ylabel(,labsize(vsmall)) ///
	headings(s_dem_25under = "{bf:Demographics}" ///
	s_dem_log_popdens  = "{bf: Density and public interaction}" /// 
	s_cbp_est_civic  = "{bf:Social capital}" ///
	s_rwj_life_expec  = "{bf:Health risk factors}" ///
	s_rwj_physicians_r = "{bf:Health system capacity}" ///
	s_rwj_air_pollution  = "{bf:Air pollution}" ///
	s_cbp_foodstores  = "{bf:Essential businesses}" ///  
	s_pol_dem2016  = "{bf:Political views}", labsize(vsmall))

	graph export analysis-output/coefplot-bivariate-`o'-predictors.pdf,replace

}

foreach o in reldiv theil {
	coefplot (`o'_dem_25under `o'_dem_65over `o'_seg_age_all `o'_dem_asian `o'_dem_black `o'_dem_hispanic `o'_dem_white `o'_dem_lesshs `o'_dem_college_more `o'_dem_med_hhinc `o'_dem_pov   `o'_seg_inc_all  `o'_dem_log_popdens `o'_dem_comm_avg_time `o'_dem_publictrans `o'_dem_comm_wfh `o'_dem_unemployed `o'_dem_hu_vacant `o'_dem_hhold_6more `o'_dem_hu_50more  `o'_dem_gchild   `o'_air_dom `o'_air_int `o'_cbp_est_civic `o'_cbp_est_relig `o'_cbp_est_sport `o'_rwj_life_expec `o'_rwj_prem_mort `o'_rwj_diabetes_rate `o'_rwj_obese `o'_rwj_hiv_rate `o'_rwj_smoking `o'_rwj_drinking  `o'_rwj_insuf_sleep `o'_rwj_phys_inact  `o'_rwj_physicians_r `o'_rwj_other_pcp_rate `o'_hos_beds `o'_dem_insured  `o'_rwj_flu_vaccine `o'_rwj_air_pollution `o'_cbp_foodstores `o'_cbp_hospitals `o'_cbp_nurshomes `o'_cbp_pharmacies `o'_dem_pub_sect `o'_dem_construction `o'_pol_dem2016 `o'_cli_happening  `o'_cli_regulate), bylabel("{bf: `o'}" "{bf:rate}")   subtitle(, size(small)) ///
	 drop(_cons) ///
	ysize(8) ///
	  nooffsets    ///
	xline(0,lwidth(.2) lpattern(solid) lcolor(red)) ///
	byopts(cols(3) legend(off)) ///
	levels(95) ///
	lpatt(solid) mcol(black)   msym(o) msize(.7) lwidth(.1)  ciopts( recast(rcap) lpatt(solid) lcol(black) lwidth(.15)) ///
	scheme(s1mono)  plotregion(lcolor(none))  ///
	grid(glpattern(dot) glwidth(vthin) glcolor(gray) )  ///
	xlabel(-1(.5)1 , labsize(vsmall) ) ///
	ylabel(,labsize(vsmall)) ///
	headings(s_dem_25under = "{bf:Demographics}" ///
	s_dem_log_popdens  = "{bf: Density and public interaction}" /// 
	s_cbp_est_civic  = "{bf:Social capital}" ///
	s_rwj_life_expec  = "{bf:Health risk factors}" ///
	s_rwj_physicians_r = "{bf:Health system capacity}" ///
	s_rwj_air_pollution  = "{bf:Air pollution}" ///
	s_cbp_foodstores  = "{bf:Essential businesses}" ///  
	s_pol_dem2016  = "{bf:Political views}", labsize(vsmall))

	graph export analysis-output/coefplot-bivariate-`o'-predictors.pdf,replace

}

ren s_reldiv s_rd_all  
ren s_theil s_th_all  

*******************************************************
***** Table S1: Descriptive statistics
*******************************************************
lab var d_r_usaf "\hspace{0.4cm} Deaths per 100,000"
lab var deaths_r "\hspace{0.4cm} Log deaths per 100,000"
lab var c_r_usaf  "\hspace{0.4cm} Cases per 100,000"
lab var cases_r  "\hspace{0.4cm} Log cases per 100,000"

lab var seg_reldiv_all "\hspace{0.4cm} Multi-group Relative Diversity Index"
lab var seg_reldiv_bw "\hspace{0.4cm} Black-white Relative Diversity Index"
lab var seg_reldiv_hw "\hspace{0.4cm} Hispanic-white Relative Diversity Index"
lab var seg_theil_all "\hspace{0.4cm} Multi-group Theil Segregation Index"
lab var seg_theil_bw "\hspace{0.4cm} Black-white Theil Segregation Index"
lab var seg_theil_hw "\hspace{0.4cm} Hispanic-white Theil Segregation Index"

lab var dem_totpop "\hspace{0.4cm} Population"
lab var dem_25under "\hspace{0.4cm} \% younger than 25"
lab var dem_65over "\hspace{0.4cm} \% older 65"
lab var dem_white "\hspace{0.4cm} \% white"
lab var dem_black "\hspace{0.4cm} \% black"
lab var dem_asian "\hspace{0.4cm} \% Asian"
lab var dem_hispanic "\hspace{0.4cm} \% Hispanic"
lab var dem_lesshs "\hspace{0.4cm} \% no high school"
lab var dem_college_more "\hspace{0.4cm} \% college or more"
lab var dem_med_hhinc "\hspace{0.4cm} Median income (in 1,000s)"
lab var dem_pov "\hspace{0.4cm} \% in poverty"
lab var seg_age_all "\hspace{0.4cm} Age segregation (Theil Index)"
lab var seg_inc_all "\hspace{0.4cm} Income segregation (Theil Index)"
lab var dem_popdens "\hspace{0.4cm} Population density"
lab var dem_log_popdens "\hspace{0.4cm} Population density (log)"
lab var dem_publictrans "\hspace{0.4cm} \% public transit"
lab var dem_comm_wfh "\hspace{0.4cm} \% working from home"
lab var dem_comm_avg_time "\hspace{0.4cm} Average commute (in minutes)"
lab var dem_unemployed "\hspace{0.4cm} \% unemployed"
lab var dem_pub_sect "\hspace{0.4cm} Public sector"
lab var dem_construction "\hspace{0.4cm} Construction"
lab var dem_hu_vacant "\hspace{0.4cm} \% vacant units"
lab var dem_hhold_6more "\hspace{0.4cm} \% households with 6+ occupants"
lab var dem_gchild "\hspace{0.4cm} \% families with grandchildren present"
lab var dem_hu_50more "\hspace{0.4cm} \% units in 50+ unit buildings"
lab var air_dom "\hspace{0.4cm} Domestic airport passengers per 1,000 (log)"
lab var air_int "\hspace{0.4cm} International airport passengers per 1,000 (log)"
lab var cbp_est_civic "\hspace{0.4cm} Civic organizations"
lab var cbp_est_relig "\hspace{0.4cm} Religious organizations"
lab var cbp_est_sport  "\hspace{0.4cm} Sports and bowling centers"
lab var rwj_life_expec "\hspace{0.4cm} Life expectancy"
lab var rwj_life_expec_wb "\hspace{0.4cm} White-black life expectancy gap"
lab var rwj_life_expec_wh "\hspace{0.4cm} White-Hispanic life expectancy gap"
lab var rwj_prem_mort "\hspace{0.4cm} \% premature deaths"
lab var rwj_diabetes_rate "\hspace{0.4cm} \% diabetic"
lab var rwj_hiv_rate "\hspace{0.4cm} \% HIV positive"
lab var rwj_insuf_sleep "\hspace{0.4cm} \% sleep less 7h"
lab var rwj_smoking "\hspace{0.4cm} \% smokers"
lab var rwj_obese "\hspace{0.4cm} \% obese"
lab var rwj_phys_inact "\hspace{0.4cm} \% physically inactive"
lab var rwj_drinking "\hspace{0.4cm} \% excessive drinking"
lab var rwj_physicians_r "\hspace{0.4cm} Primary care physicians per 100,000"
lab var rwj_other_pcp_rate "\hspace{0.4cm} Primary care providers per 100,000"
lab var hos_beds "\hspace{0.4cm} Hospital beds per 1,000"
lab var dem_insured "\hspace{0.4cm} \% insured"
lab var rwj_flu_vaccine "\hspace{0.4cm} \%  flu vaccine"
lab var rwj_air_pollution "\hspace{0.4cm} PM2.5 daily average"
lab var cbp_foodstores "\hspace{0.4cm} Food stores"
lab var cbp_hospitals "\hspace{0.4cm} Hospitals"
lab var cbp_nurshomes "\hspace{0.4cm} Nursing homes"
lab var cbp_pharmacies "\hspace{0.4cm} Pharmacies"
lab var pol_dem2016 "\hspace{0.4cm} \% voted democrat in 2016"
lab var cli_happening "\hspace{0.4cm} \% thinks global warming is happening"
lab var cli_regulate "\hspace{0.4cm} \% supports CO2 regulation"

lab var dem_unemployed_wb "\hspace{0.4cm} White-black unemployment rate gap"
lab var dem_unemployed_wa "\hspace{0.4cm} White-Asian unemployment rate gap"
lab var dem_unemployed_wh "\hspace{0.4cm} White-Hispanic unemployment rate gap"
lab var dem_med_hhinc_wb "\hspace{0.4cm} White-black median household income gap"
lab var dem_med_hhinc_wa "\hspace{0.4cm} White-Asian median household income gap"
lab var dem_med_hhinc_wh "\hspace{0.4cm} White-Hispanic median household income gap"
lab var dem_pov_wb "\hspace{0.4cm} White-black poverty rate gap"
lab var dem_pov_wa "\hspace{0.4cm} White-Asian poverty rate gap"
lab var dem_pov_wh "\hspace{0.4cm} White-Hispanic poverty rate gap"

* Paste labels to standarized variables
foreach v of varlist dem_* rwj_*  air_* cbp_* hos_* pol_* cli_*  {
	local lbl : variable label `v' 
    label var  s_`v' "\hspace{-0.4cm} `lbl'"
}

* Label segregation variables
lab var s_rd_all "\hspace{0.4cm} Relative Diversity Index"
lab var s_rd_bw "\hspace{0.4cm} Black-White RDI"
lab var s_rd_hw "\hspace{0.4cm} Hispanic-White RDI"
lab var s_th_all "\hspace{0.4cm} Theil Segregation Index"
lab var s_th_bw "\hspace{0.4cm} Black-White Theil"
lab var s_th_hw "\hspace{0.4cm} Hispanic-White Theil"

* Rescale income to 1000s
replace dem_med_hhinc = dem_med_hhinc/1000

* Rescale prevalences in per 100,000 to %
foreach v in rwj_hiv_rate rwj_prem_mort cbp_foodstores cbp_hospitals cbp_nurshomes cbp_pharmacies {
	replace `v' = `v'/1000
}

estpost  tabstat d_r_usaf deaths_r   c_r_usaf cases_r  seg_reldiv_all seg_reldiv_bw seg_reldiv_hw seg_theil_all seg_theil_bw   seg_theil_hw  `Race' `predictors', s(mean sd min  p50   max) columns(statistics) 
esttab using "analysis-output/descriptives.tex",  fragment ///
	refcat(d_r_usaf "\cmidrule(lr){2-6} \emph{COVID-19 Outcomes}" /// 
	seg_reldiv_all "\emph{Racial segregation}"  ///
	dem_asian "\emph{Demographics}" ///
	dem_log_popdens  "\emph{Density and public interaction}" ///  
	cbp_est_civic  "\emph{Social capital (per 100,000)}" ///
	rwj_life_expec  "\emph{Health risk factors}" ///
	rwj_physicians_r "\emph{Health system capacity}" ///
	rwj_air_pollution  "\emph{Air pollution}" ///
	cbp_foodstores  "\emph{Employment in essential businesses (in \%)}" ///  
	pol_dem2016  "\emph{Political views}", nolabel) /// 		
	cells("mean(fmt(%9.2fc)) sd(fmt(%9.2fc))  min(fmt(%9.2fc)) p50(fmt(%9.2fc)) max(fmt(%9.2fc))") ///
	replace nonum noobs label  nolines ///
	collabels("Mean" "SD" "Min" "Median" "Max") 

*******************************************************
***** Run models of overall mortality and infection
*******************************************************
ren s_rd_all s_seg_reldiv_all
ren s_rd_bw s_seg_reldiv_bw
ren s_rd_hw s_seg_reldiv_hw
ren s_th_all s_seg_theil_all
ren s_th_bw s_seg_theil_bw
ren s_th_hw s_seg_theil_hw

foreach g in   reldiv reldiv_bw reldiv_hw  theil theil_bw theil_hw   {
		gen REG_`g'_ols_bi = .
		gen REG_`g'_ols_fe = .
		gen REG_`g'_lasso = .
			
		lab var REG_`g'_ols_bi "OLS"
		lab var REG_`g'_ols_fe "OLS FE"
		lab var REG_`g'_lasso "Double-Lasso"
}

*** Run double-lasso for coavariate selection forcing state dummies to be selected
foreach g in reldiv theil { 	
	foreach y in deaths_r  cases_r {

		replace REG_`g'_lasso = s_seg_`g'_all
				
		quietly dsregress  `y'  REG_`g'_lasso,  controls((`states'  ) `std_preds'  `std_race' )  rseed(12345) 
		local ctrl_`y'_`g'_lasso `e(controls_sel)'
	}
	
	* Create macro with variables selected across deaths and cases lasso models
	local controls_lasso_`g': list ctrl_deaths_r_`g'_lasso | ctrl_cases_r_`g'_lasso
}

* Create macro with variables selected across reldiv and Theil lasso models
local controls_lasso: list controls_lasso_reldiv |  controls_lasso_theil

*** Run OLS and lasso models with selected covariates
foreach y in cases_r  deaths_r {
	foreach g in  reldiv theil  {

	* OLS bivariate
		replace REG_`g'_ols_bi = s_seg_`g'_all
		reg  `y'  REG_`g'_ols_bi  [aw=dem_totpop] , cluster(state_ab)
		estimates store `y'_`g'_ols_bi

	* OLS with fixed effects
		replace REG_`g'_ols_fe = s_seg_`g'_all
		areg  `y'  REG_`g'_ols_fe  [aw=dem_totpop] ,a(state_ab) cluster(state_ab)
		estimates store `y'_`g'_ols_fe

	* Double-lasso
		replace  REG_`g'_lasso  = s_seg_`g'_all
		reg  `y'  REG_`g'_lasso `controls_lasso'   [aw=dem_totpop], cluster(state_ab)
		estimates store `y'_`g'_lasso
}
}

*******************************************************
***** Run models of racial gaps
*******************************************************
** Flag consistent sample
foreach y in  bw hw  {
	reg  d_log_r_`y'_cov  REG_reldiv_ols_bi 
	predict res_`y' , residuals
}
gen sample_gaps = (res_bw!=. & res_hw!=.  )	
gen sample_bw = (res_bw!=.  )	
gen sample_hw = (res_hw!=.  )	

*** Run OLS and lasso models with selected covariates
foreach y in  bw hw  {
	foreach g in theil reldiv {
		
	* OLS bivariate
		replace REG_`g'_ols_bi = s_seg_`g'_`y'
		reg  d_log_r_`y'_cov  REG_`g'_ols_bi  [aw=dem_totpop]  if sample_gaps ==1, robust
		estimates store `y'_`g'_ols_bi

		reg  d_log_r_`y'_cov  REG_`g'_ols_bi  [aw=dem_totpop]  , robust
		estimates store `y'_`g'_ols_bi_diff
		
	* OLS with fixed effects
		replace REG_`g'_ols_fe = s_seg_`g'_`y'
		areg  d_log_r_`y'_cov  REG_`g'_ols_fe  [aw=dem_totpop] if sample_gaps ==1, robust a(state_ab)
		estimates store `y'_`g'_ols_fe

		replace REG_`g'_ols_fe = s_seg_`g'_`y'
		areg  d_log_r_`y'_cov  REG_`g'_ols_fe  [aw=dem_totpop]   , robust a(state_ab)
		estimates store `y'_`g'_ols_fe_diff
		
	* Double-lasso
		replace  REG_`g'_lasso  = s_seg_`g'_`y'
		areg  d_log_r_`y'_cov  REG_`g'_lasso `controls_lasso' [aw=dem_totpop] if sample_gaps ==1, robust a(state_ab)
		estimates store `y'_`g'_lasso		
	
		replace  REG_`g'_lasso  = s_seg_`g'_`y'
		areg  d_log_r_`y'_cov  REG_`g'_lasso `controls_lasso' [aw=dem_totpop]  , robust a(state_ab)
		estimates store `y'_`g'_lasso_diff			
	}
}

*******************************************************
***** Figures 3, 4, S5, and S6: Coefficient plots with OLS and double-lasso estimates
*******************************************************
*** Figures 3 and S5: OLS and double-lasso estimates for overall mortality and infection
foreach s in reldiv theil {
	coefplot ///
	( deaths_r_`s'_ols_bi deaths_r_`s'_ols_fe  deaths_r_`s'_lasso), bylabel("{bf:Log death rate}")   subtitle(, size(huge))   ///
	|| ///
	( cases_r_`s'_ols_bi cases_r_`s'_ols_fe  cases_r_`s'_lasso), bylabel("{bf:Log infection rate}")   subtitle(, bcolor(white) size(vhuge)) ///
	||, ///
	keep(REG_*) ///
	ysize(2) ///
	xline(0,lwidth(.1) lpattern(solid) lcolor(red)) ///
	byopts(cols(2) legend(off)) ///
	levels(95) ///
	lpatt(solid) lcol(black) msym(o) msize(3) mcol(black) ciopts( recast(rcap) lpatt(solid) lcol(black) lwidth(.7)) ///
	scheme(s1mono)  plotregion(lcolor(none))  ///
	grid(glpattern(dot) glwidth(vthin) glcolor(gray) )  ///
	mlabel  mlabposition(12) format(%9.2fc) mlabsize(9) mlabgap(*.5) ///
	xlabel(0(.25).5 , format(%9.2g) labsize(vhuge) ) ///
	ylabel(,labsize(vhuge)) ///
	xscale(range(-.10 .55)) 
	graph export analysis-output/coefplot-ols-lasso-death-case-`s'.pdf,replace

}

*** Figures 4 and S6: OLS and double-lasso estimates for mortality gaps
foreach s in reldiv theil {
	coefplot ///
	( bw_`s'_ols_bi_diff bw_`s'_ols_fe_diff  bw_`s'_lasso_diff ///
	) , bylabel("{bf:Black-white}" "{bf:death rate gap}") ///
	|| ///
	( hw_`s'_ols_bi_diff hw_`s'_ols_fe_diff  hw_`s'_lasso_diff ///
	)  ///
	, bylabel("{bf:Hispanic-white}" "{bf:death rate gap}")   subtitle(, bcolor(white) size(vhuge)) ///
	||, ///
	keep(REG_*) ///
	ysize(2) ///
	xline(0,lwidth(.1) lpattern(solid) lcolor(red)) ///
	byopts(cols(2) legend(off)) ///
	levels(95) ///
	lpatt(solid) lcol(black) msym(o) msize(3) mcol(black) ciopts( recast(rcap) lpatt(solid) lcol(black) lwidth(.7)) ///
	scheme(s1mono)  plotregion(lcolor(none))  ///
	grid(glpattern(dot) glwidth(vthin) glcolor(gray) )  ///
	mlabel  mlabposition(12) format(%9.2fc) mlabsize(9) mlabgap(*.5) ///
	xlabel(-.1(.1).2 , format(%9.2g) labsize(vhuge) ) ///
	ylabel(,labsize(vhuge)) ///
	xscale(range(-.12 .22)) 
	graph export analysis-output/coefplot-ols-lasso-death-race-gaps-`s'-diff-samples.pdf,replace
}

*** Figures S9 and S10: OLS and double-lasso estimates for mortality gaps with consitent sample
foreach s in reldiv theil {
	coefplot ///
	( bw_`s'_ols_bi bw_`s'_ols_fe  bw_`s'_lasso ///
	) , bylabel("{bf:Black-white}" "{bf:death rate gap}") ///
	|| ///
	( hw_`s'_ols_bi hw_`s'_ols_fe  hw_`s'_lasso ///
	)  ///
	, bylabel("{bf:Hispanic-white}" "{bf:death rate gap}")   subtitle(, bcolor(white) size(vhuge)) ///
	||, ///
	keep(REG_*) ///
	ysize(2) ///
	xline(0,lwidth(.1) lpattern(solid) lcolor(red)) ///
	byopts(cols(2) legend(off)) ///
	levels(95) ///
	lpatt(solid) lcol(black) msym(o) msize(3) mcol(black) ciopts( recast(rcap) lpatt(solid) lcol(black) lwidth(.7)) ///
	scheme(s1mono)  plotregion(lcolor(none))  ///
	grid(glpattern(dot) glwidth(vthin) glcolor(gray) )  ///
	mlabel  mlabposition(12) format(%9.2fc) mlabsize(9) mlabgap(*.5) ///
	xlabel(-.1(.1).2 , format(%9.2g) labsize(vhuge) ) ///
	ylabel(,labsize(vhuge)) ///
	xscale(range(-.12 .22)) 
	graph export analysis-output/coefplot-ols-lasso-death-race-gaps-`s'.pdf,replace
}

*******************************************************
***** Tables S3 and S4: Full regression output
*******************************************************
lab var s_seg_theil_all "\hspace{-0.4cm} \hspace{0.4cm} Multi-Group Theil Segrgeation Index"
lab var s_seg_reldiv_all "\hspace{-0.4cm}  \hspace{0.4cm} Multi-Group Relative Diversity Index"
lab var s_seg_theil_bw "\hspace{-0.4cm} \hspace{0.4cm} Black-White Theil Segrgeation Index"
lab var s_seg_reldiv_bw "\hspace{-0.4cm}  \hspace{0.4cm} Black-White Relative Diversity Index"
lab var s_seg_theil_hw "\hspace{-0.4cm} \hspace{0.4cm} Hispanic-White Theil Segrgeation Index"
lab var s_seg_reldiv_hw "\hspace{-0.4cm}  \hspace{0.4cm} Hispanic-White Relative Diversity Index"

lab var s_seg_inc "\hspace{-0.4cm}  \hspace{0.4cm} Income Segregation"
lab var s_seg_age "\hspace{-0.4cm}  \hspace{0.4cm} Age Segregation"

foreach v of varlist dem_* rwj_*  air_* cbp_* hos_* pol_* cli_*  {
	local lbl : variable label `v' 
    label var  s_`v' "\hspace{-0.4cm} `lbl'"
}

*** Create macro with racial composition variables not selected by the lasso
local race_prop s_dem_asian s_dem_black  

*** Create macro with racial gaps in poverty, household income, unemployment, and life expectancy 
local dem_gaps s_dem_pov_wb  s_dem_pov_wh s_dem_med_hhinc_wb  s_dem_med_hhinc_wh s_dem_unemployed_wb  s_dem_unemployed_wh s_rwj_life_expec_wb s_rwj_life_expec_wh

foreach g in theil reldiv {

	*** Main lasso models
	reg  deaths_r  s_seg_`g'_all `controls_lasso' [aw=dem_totpop], cluster(state_ab)
	estimates store output_deaths_r_`g'

	reg  cases_r  s_seg_`g'_all `controls_lasso' [aw=dem_totpop], cluster(state_ab)
	estimates store output_cases_r_`g'

	areg  d_log_r_bw_cov  s_seg_`g'_bw `controls_lasso'[aw=dem_totpop] if sample_bw ==1,r a(state_ab)
	estimates store output_bw_r_`g'

	areg  d_log_r_hw_cov  s_seg_`g'_hw `controls_lasso' [aw=dem_totpop] if sample_hw ==1,r a(state_ab)
	estimates store output_hw_r_`g'

	*** Adding racial composition variables not selected by the lasso
	reg  deaths_r  s_seg_`g'_all `race_prop' `controls_lasso'  [aw=dem_totpop], cluster(state_ab)
	estimates store output_deaths_r_`g'_race

	reg  cases_r  s_seg_`g'_all `race_prop' `controls_lasso'   [aw=dem_totpop], cluster(state_ab)
	estimates store output_cases_r_`g'_race

	areg  d_log_r_bw_cov  s_seg_`g'_bw `race_prop'  `controls_lasso'   [aw=dem_totpop]  if sample_bw ==1,r a(state_ab)
	estimates store output_bw_r_`g'_race

	areg  d_log_r_hw_cov  s_seg_`g'_hw `race_prop' `controls_lasso'   [aw=dem_totpop] if sample_hw ==1,r a(state_ab)
	estimates store output_hw_r_`g'_race

	*** Adding racial/ethnic gaps in poverty, household income, unemployment, and life expectancy
	reg  deaths_r  s_seg_`g'_all `controls_lasso' `race_prop'  `dem_gaps'  [aw=dem_totpop], cluster(state_ab)
	estimates store output_deaths_r_`g'_dg

	reg  cases_r  s_seg_`g'_all `controls_lasso' `race_prop'  `dem_gaps' [aw=dem_totpop], cluster(state_ab)
	estimates store output_cases_r_`g'_dg

	areg  d_log_r_bw_cov  s_seg_`g'_bw `controls_lasso' `race_prop'  `dem_gaps'  [aw=dem_totpop]  if sample_bw ==1,r a(state_ab)
	estimates store output_bw_r_`g'_dg

	areg  d_log_r_hw_cov  s_seg_`g'_hw `controls_lasso' `race_prop'  `dem_gaps'  [aw=dem_totpop] if sample_hw ==1,r a(state_ab)
	estimates store output_hw_r_`g'_dg

}

foreach g in theil reldiv {		
	esttab output_deaths_r_`g' output_deaths_r_`g'_race output_deaths_r_`g'_dg  output_cases_r_`g' output_cases_r_`g'_race output_cases_r_`g'_dg  ///
	using  "analysis-output/lasso-output-controls-overall-`g'.tex", replace fragment ///
		 mgroups( "Log death rate"   "Log case rate"    , pattern(1 0  0 1 0  0) prefix(\multicolumn{@span}{c}{) suffix(})   span erepeat(\cmidrule(lr){@span}))  ///
		refcat(s_seg_`g'_all  "\cmidrule(lr){2-7}    \\ [-2em]", nolabel) ///
		mtitles("Fig. 3"    ""    ""    "Fig. 3"  "" "") ///
		drop(st_* _cons) ///
		order(s_seg_`g'_all s_dem_asian s_dem_black s_dem_hispanic s_dem_white   `controls_lasso'  `dem_gaps') ///
		label  eqlabels(none)  ///
		b(3) p(3)  ///
		alignment(S S)  ///
		star(* 0.10 ** 0.05 *** 0.01) ///
		nolines ///
		nonotes ///
		collabels(none) ///
		cells("b(fmt(3)star)" "se(fmt(3)par)") ///
		stats( N  r2_a  r2, fmt(%9.0fc %9.3fc  )   labels(`"\noalign{\smallskip} \noalign{\smallskip} Counties"'  `"Adj. \(R^{2}\)"' `"\(R^{2}\)"'   ))

}

foreach g in theil reldiv {	
	esttab output_bw_r_`g' output_bw_r_`g'_race output_bw_r_`g'_dg  output_hw_r_`g' output_hw_r_`g'_race output_hw_r_`g'_dg  ///
	using  "analysis-output/lasso-output-controls-gaps-`g'.tex", replace fragment ///
		 mgroups( "Black-white gap"   "Hispanic-white gap"    , pattern(1 0  0 1 0  0) prefix(\multicolumn{@span}{c}{) suffix(})   span erepeat(\cmidrule(lr){@span}))  ///
		refcat(s_seg_`g'_bw  "\cmidrule(lr){2-7}    \\ [-2em]", nolabel) ///
		mtitles("Fig. 4"    ""    ""    "Fig. 4"  "" "") ///
		drop(st_* _cons) ///
		order(s_seg_`g'_bw s_seg_`g'_hw s_dem_asian s_dem_black s_dem_hispanic s_dem_white   `controls_lasso'  `dem_gaps') ///
		label  eqlabels(none)  ///
		b(3) p(3)  ///
		alignment(S S)  ///
		star(* 0.10 ** 0.05 *** 0.01) ///
		nolines ///
		nonotes ///
		collabels(none) ///
		cells("b(fmt(3)star)" "se(fmt(3)par)") ///
		stats( N  r2_a  r2, fmt(%9.0fc %9.3fc  )   labels(`"\noalign{\smallskip} \noalign{\smallskip} Counties"'  `"Adj. \(R^{2}\)"' `"\(R^{2}\)"'   ))

}

*******************************************************
***** Figure S7: Frank's sensitivity test to invalidate inference for black-white mortality gap 
*******************************************************
*** Parameters for K formula
* Parameters from edtimated model
reg	d_log_r_bw_cov s_seg_reldiv_bw `controls_lasso' [aw=dem_totpop] if sample_bw ==1,r 
matrix beta = e(b)
matrix se = e(V)
scalar N = `e(N)'
scalar q = `e(rank)' - 2
scalar t = beta[1,1] / sqrt(se[1,1])
scalar d = (t^2)+(N-q-1)

* r2xz (R2 of regression of X on all controls)
reg	d_log_r_bw_cov `controls_lasso'  if sample_bw ==1,r 
scalar r2xz = `e(r2)'

* r2xz (R2 of regression of Y on all controls)
reg	   s_seg_reldiv_bw `controls_lasso'  if sample_bw ==1,r 
scalar r2yz = `e(r2)'

*ryxz (partial correlation between Y and X, controling for all other covariates)
pcorr	d_log_r_bw_cov s_seg_reldiv_bw  `controls_lasso'    if sample_bw ==1
matrix matpcorr = r(p_corr)
scalar ryxz = abs(matpcorr[1,1])

*** Compute K
scalar k = abs(     (sqrt((1-r2xz)*(1-r2yz)))*(   ((t^2 +(t*sqrt(d)))/(-(N-q-1)))  +  (((-d-(t*sqrt(d))) / -(N-q-1) )*   ryxz))      )
di k
* Compute correlation between Y and confounding variable
scalar rycv = sqrt(k*sqrt((1-r2yz)/(1-r2xz)))
di rycv
* Compute correlation between X and confounding variable
scalar rxcv = sqrt(k*sqrt((1-r2xz)/(1-r2yz)))
di rxcv

di rxcv/sqrt((1-r2xz))

*** Plot of correlations 
gen bw_varname = ""
gen bw_corr_bw = .
gen bw_corr_seg = .

gen bw_counter = _n
replace bw_varname = "Omitted variable" if bw_counter == 1
replace bw_corr_bw =  rycv if bw_counter == 1 
replace bw_corr_seg =  rxcv if bw_counter == 1 

local i = 1
foreach var of local std_race_preds {
	local i=`i'+1
	local lbl : variable label `var' 
	replace bw_varname = "`lbl'"  if bw_counter == `i'
	
	pcorr d_log_r_bw_cov `var' `controls_lasso'  if sample_bw ==1
	matrix matpcorr = r(p_corr)
	replace bw_corr_bw = matpcorr[1,1] if bw_counter == `i'

	pcorr s_seg_reldiv_bw `var' `controls_lasso'  if sample_bw ==1
	matrix matpcorr = r(p_corr)
	replace bw_corr_seg = matpcorr[1,1] if bw_counter  == `i'
}

gen bw_varname_lab = ""
replace bw_varname_lab = bw_varname if bw_counter == 1

twoway (function y=k/x,range(.2 .8) lcolor(black) lwidth(.3)) (function y=k/x,range(-.2 -.8) lcolor(black) lwidth(.3))  (scatter bw_corr_bw bw_corr_seg if bw_counter==1,mfcolor(black) mlcolor(black)  msymbol(d) msize(2) mlabel(bw_varname_lab) mlabsize(4) mlabposition(3) mlabcolor(black)) (scatter bw_corr_bw bw_corr_seg if bw_counter>1 ,mfcolor(white) mlcolor(gray) msymbol(o) msize(2)  mlabel(bw_varname_lab) mlabsize(4) mlabposition(3) mlabcolor(gray)), ///
scheme(s1mono)  plotregion(lcolor(none))  ///
title("", size(large)) ///
xtitle("Correlation with black-white Relative Diversity Index" ,   size(medlarge)) ///
xscale(titlegap(*7)) ///
ytitle("Correlation with black-white mortality gap", size(medlarge)) ///
ylabel(-.3(.1).3, labsize(medlarge) format(%9.1g)) ///
xlabel(-.8(.2).8, labsize(medlarge) format(%9.1g)) ///
xline(0,lwidth(thin) lpattern(dash) lcolor(red)) ///
yline(0,lwidth(thin) lpattern(dash) lcolor(red)) ///
legend(off)
graph export analysis-output/sensitivity-frank-black-white-gap-reldiv.pdf,replace	

*******************************************************
***** Figure S8: Oster's sensitivity test for point estimate is zero 
*******************************************************
gen double n_bw = _n/100
gen double r2_bw = .
gen double delta_beta_zero_bw = .

areg  d_log_r_bw_cov   s_seg_reldiv_bw  `controls_lasso' [aw=dem_totpop]   if sample_bw ==1 ,r a(state_ab)
scalar r2_reg_bw= `e(r2)'

foreach  r in .7 .71 .72 .73 .74 .75 .76 .77 .78 .79 .8 .81 .82 .83 .84 .85 .86 .87 .88 .89 .90 .91 .92 .93 .94 .95 .94 .95 .96 .97 .98 .99 1  {
	psacalc delta s_seg_reldiv_bw , beta(0) rmax(`r')
	replace delta_beta_zero_bw = abs(`r(delta)') if n_bw == `r'
	replace r2_bw = `r(rmax)' if n_bw == `r'
}

line delta_beta_zero_bw  r2_bw if  r2_bw>=.70,lpattern(solid) lcolor(black) ///
scheme(s1mono)  plotregion(lcolor(none))  ///
yline(1,lwidth(thin) lpattern(solid) lcolor(red)) ///
title("Black-white mortality gap model", size(large)) ///
xtitle("R{superscript:2} with unobservables" ,   size(large)) ///
xscale(titlegap(*7)) ///
ytitle("Ratio selection on unobservables" "to selection on observables", size(large)) ///
ylabel(0(2)10, labsize(large) format(%9.0f)) ///
yscale(range(0 10.5)) ///
xlabel(0.70(.05)1, labsize(large) format(%9.2f)) ///
legend(off)
graph export analysis-output/sensitivity-black-white-gap-reldiv.pdf,replace	
