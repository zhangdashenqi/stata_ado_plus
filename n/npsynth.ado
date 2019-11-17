********************************************************************************
* NON-PARAMETRIC SYNTHETIC CONTROL METHOD ("npsynth")
*! npsynth v4 - GCerulli 30/08/2017
********************************************************************************
program npsynth, eclass
version 15
#delimit ;     
syntax varlist ,
t0(numlist max=1)
bandw(numlist max=1)
panel_var(varlist max=1)
time_var(varlist max=1)
trunit(numlist max=1)
kern(string)
[
save_res(string)
gr1
gr2
gr3
w_median
gr_y_name(string)
save_gr1(string)
save_gr2(string)
save_gr3(string)
gr_tick(numlist max=1)
]
;
#delimit cr
********************************************************************************
marksample touse
tokenize `varlist'
local y `1'
macro shift
local xvars `*'
********************************************************************************
* Non parametric Synthetic Control Method (Weights by year)
********************************************************************************
* SETTING:
*  Pre-reatment time: [1,2,3,...,t0-1]
*  Treatment time:    [t0,t0+1,...,t]
*  t0=first year of treatment (time-shock)
********************************************************************************
********************************************************************************
qui{
if "`gr_tick'"==""{
local gr_tick=3 
}
********************************************************************************
if "`gr_y_name'"==""{
local gr_y_name="`y'" 
}
********************************************************************************
* Exstract the name of the treated unit
********************************************************************************
preserve
tsset `panel_var' `time_var'
local t_first=r(tmin)
local t_end=r(tmax)
keep `panel_var'
tempvar panel_var2
decode `panel_var' , generate(`panel_var2')
duplicates drop  `panel_var2' , force
keep if `panel_var'==`trunit'
local unit=`panel_var2'[1]
restore
********************************************************************************
local m=`t0'-`t_first'+1
qui tsset `panel_var' `time_var'
local k=r(imax)-1  // number of donors
local s=`t_end'-`t0'
preserve
* Define a temporary copy of the current dataset called "smoking_temp"
tempfile smoking_temp
* Save "smoking_temp"
save `smoking_temp' , replace
* Loop over years
forvalues i=`t_first'/`t0'{  // start looping over years
	*Open the dataset
	use `smoking_temp' , clear 
	*Decode the panel var
	cap drop `panel_var'_string
	decode `panel_var' , gen(`panel_var'_string) 
	*Collapse the data to median of xvars and get a cross-section for each year i
	collapse (median) `xvars' if `time_var'==`i', by(`panel_var')
	*Save the dataset
	tempfile data_mean_`i'
	save `data_mean_`i'' , replace 
	*For each year i, generate the distance between the treated unit j  
	*and the rest of the units, and call this distance "dist"
	tempvar dist_`i'
	mahascore `xvars'  , gen(`dist_`i'') refobs(`trunit') compute_invcovarmat
	*Standardize the distance to vary in [0-1]
	qui sum `dist_`i'' , d
	tempvar dist_`i'_n
	gen `dist_`i'_n'=(`dist_`i''-r(min))/(r(max)-r(min))
	qui sum `dist_`i'_n'
	*Sort the dataset over the standardized distance
	sort  `dist_`i'_n'
	*Delete the treated unit j
	drop if `panel_var'==`trunit'
	*Generate the kernel weights "_weight_`i'" based on the std. distance 
	ereturn scalar bandh = `bandw'
	_Kernel_ `dist_`i'_n'  , bwidth(`bandw') kernel(`kern') 
	rename _weight _weight_`i'
	*Decode the panel var
	cap drop `panel_var'_string
	decode `panel_var' , gen(`panel_var'_string)
	*Keep only the panel var and the weights
	keep `panel_var' _weight_`i'
	drop if _weight_`i'==.
	*Save the year new dataset 
	tempfile data_weight_`i'
	save `data_weight_`i'' , replace
} // end looping over year
restore
********************************************************************************
* Build the Matrix B (i.e., the matrix of weights)
********************************************************************************
preserve
	keep `panel_var'
	duplicates drop `panel_var' , force
	drop if `panel_var'==`trunit'
	forvalues i=`t_first'/`t0'{
	qui merge 1:1 `panel_var' using `data_weight_`i''
	replace _weight_`i'=0 if _weight_`i'==.
	drop _merge
	}
	tempfile data_weights
	save `data_weights' , replace
	tempname B
********************************************************************************	
* Matrix B contains the same "average weight"
********************************************************************************
	tempvar _weight_mean
	if "`w_median'"==""{
	cap drop `_weight_mean'
	egen `_weight_mean' = rowmean(_weight_*)  // take the mean of the pre-treatment weights
	}
	else if "`w_median'"!=""{
	egen `_weight_mean' = rowmedian(_weight_*)  // take the mean of the pre-treatment weights
	}
********************************************************************************	
	forvalues i=`t_first'/`t0'{
	replace _weight_`i' = `_weight_mean'
	}
	mkmat _weight_* , matrix(`B')
	mat list `B'
restore
********************************************************************************
* Build the Matrix A (i.e. pre-treatment time series for each unit
* excluded the treated unit j)
********************************************************************************
preserve
	levelsof `panel_var' , local(slist)
	local N: word count `slist'
	di `N'
	sort `panel_var' `time_var'
	drop if `panel_var'==`trunit'
	keep `panel_var' `time_var' `y'
restore
********************************************************************************
foreach v of local slist{
preserve
	keep if `panel_var'==`v'
	rename `y' `y'_`v'
	keep `time_var' `y'_`v'
	tempfile data_`y'_`v'
	save `data_`y'_`v'' , replace
restore
}
********************************************************************************
* Merging of the datasets of pre-treatment series of each unit
********************************************************************************
preserve
	drop if `panel_var'==`trunit'
	keep `time_var'
	duplicates drop `time_var' , force
	tempfile data_`time_var'
	save `data_`time_var'' , replace
	foreach v of local slist{
	qui merge 1:1 `time_var' using `data_`y'_`v''
	cap drop _merge
	} 
	drop `y'_`trunit'
	tempfile data_`y'
	save `data_`y'' , replace
	tempname Atot
	mkmat `y'_* , matrix(`Atot')	
********************************************************************************
* Build the Matrix C (where the diagonal of matrix C contains the pre-treatment
* "synthetic" treated unit j) --> The synthetic pre-treatment treated is Y0 
********************************************************************************
    tempname A
	mat `A'=`Atot'[1..`m',1..`k']
	*mat list `A'
	tempname C
	mat `C'=`A'*`B'
	*mat list `C'
	tempname Y0a
	mat `Y0a'=vecdiag(`C')
	*mat list Y0a
	tempname Y0
	mat `Y0'=`Y0a''
	*mat list `Y0'
	svmat `Y0'
	sum `Y0'1
	keep `time_var' `Y0'1
	tempfile counter
	save `counter' , replace
restore
********************************************************************************
* build Y1 (pre-treatment)
********************************************************************************
preserve
	sort `panel_var' `time_var'
	keep if `panel_var'==`trunit'
	keep `time_var' `y'
	tempvar Y1
	rename `y' `Y1'
	qui merge 1:1 `time_var' using `counter'
	keep if `time_var'<=`t0'
	tempvar DIF DIF_sqr
	gen `DIF'=`Y1'-`Y0'
	gen `DIF_sqr'=(`DIF')^2
	qui sum `DIF_sqr'
	local myRMSPE=r(mean)
	ereturn scalar RMSPE = sqrt(`myRMSPE')
	local myRMSPE=round(sqrt(`myRMSPE'), 0.001)
********************************************************************************
    if "`gr1'"!=""{
	tw (line `Y1' `time_var')  ///
	(line `Y0' `time_var' , lpattern(dash)) , ///
	xline(`t0') title("Pre-treatment balancing and parallel trend") ///
	legend(label(1 "Actual") label(2 "Synthetic")) scheme(s1mono) ///
	xlabel(`t_first'(`gr_tick')`t0') xtitle("") ///
	note("Dependent variable = `gr_y_name'" "Bandwidth = `bandw'" "Kernel = `kern'" "RMPSE = `myRMSPE'" "Treated = `unit'") ///
	name(`save_gr1' , replace)
	if "`save_gr1'"!=""{
	graph save `save_gr1' , replace
	}
	}
********************************************************************************	
	keep `time_var' `DIF'
	rename `DIF' `DIF'_pre
	tempfile `DIF'_pre
	save ``DIF'_pre' , replace
********************************************************************************
*
********************************************************************************
* POST-TREATMENT ANALYSIS
********************************************************************************
* Build the Matrix "Btot"
********************************************************************************
set more off
use `data_weights' , clear
tempvar _weight_mean
if "`w_median'"==""{
cap drop `_weight_mean'
egen `_weight_mean' = rowmean(_weight_*)  // take the mean of the pre-treatment weights
}
else if "`w_median'"!=""{
cap drop `_weight_mean'
egen `_weight_mean' = rowmedian(_weight_*)  // take the median of the pre-treatment weights
}
********************************************************************************
tempvar pan_var_2
decode `panel_var' , gen(`pan_var_2')
tempname W
mkmat `_weight_mean' , matrix(`W') nomissing rownames(`pan_var_2')
matrix colnames `W' = "WEIGHT"
********************************************************************************
forvalues i=1/`s'{
cap drop _weight_mean`i'
gen _weight_mean`i'=`_weight_mean'
}
* Same weights
forvalues i=`t_first'/`t0'{
replace _weight_`i' = `_weight_mean'
}
* This matrix contains the same "average" weight
tempname Btot
mkmat _weight_* , mat(`Btot')
mat list `Btot'
********************************************************************************
restore
********************************************************************************
preserve
* Build matrix Ctot
tempname Ctot
*mat list `Atot'
mat `Ctot'=`Atot'*`Btot'
*mat list `Ctot'
tempname Y0tot
	mat `Y0tot'=vecdiag(`Ctot')
	*mat list Y0tot
	mat `Y0tot'=`Y0tot''
	*mat list Y0tot
	svmat `Y0tot'
	sum `Y0tot'1
	keep `time_var' `Y0tot'1
	duplicates drop `time_var', force
	tempfile counter2
	save `counter2' , replace
	*sum `Y0tot'
restore
********************************************************************************
* Build Y1tot (pre and post treatment)
********************************************************************************
preserve
	sort `panel_var' `time_var'
	keep if `panel_var'==`trunit'
	keep `time_var' `y'
	tempvar Y1tot
	rename `y' `Y1tot'
	qui merge 1:1 `time_var' using `counter2'
	gen ATEtot=`Y1tot'-`Y0tot'
********************************************************************************
	if "`save_res'"!=""{
	gen _Y1_=`Y1tot'
	gen _Y0_=`Y0tot'
	save `save_res' , replace
    }
********************************************************************************
	if "`gr2'"!=""{
	tw (line `Y1tot' `time_var')  ///
	(line `Y0tot' `time_var' , lpattern(dash)) , ///
	xline(`t0') ytitle("") ///
	title("Non-parametric Synthetic Control Method", size(medium)) ///
	legend(label(1 "Actual") label(2 "Synthetic")) scheme(s1mono) ///
	xlabel(`t_first'(`gr_tick')`t_end') xtitle("") name(`save_gr2', replace) ///
	note("Dependent variable = `gr_y_name'" "Bandwidth = `bandw'" "Kernel = `kern'" "Treated = `unit'")
	if "`save_gr2'"!=""{
	graph save `save_gr2' , replace
	}
	}
********************************************************************************
	if "`gr3'"!=""{
	line ATEtot `time_var' ,  ///
	yline(0) xline(`t0') ytitle("") scheme(s1mono) ///
	title("Non-parametric Synthetic Control Method", size(medium)) ///
	xlabel(`t_first'(`gr_tick')`t_end') xtitle("") ylabel() name(`save_gr3', replace) ///
	note("Dependent variable = `gr_y_name'" "Bandwidth = `bandw'" "Kernel = `kern'" "Treated = `unit'")
	if "`save_gr3'"!=""{
	graph save `save_gr3' , replace
	}
	}
********************************************************************************
	keep `time_var' ATEtot
	tempfile ATE_tot
	save `ATE_tot' , replace
********************************************************************************
restore
********************************************************************************
}  // end of the quietly
********************************************************************************
* Outcome results
********************************************************************************
di _newline(2)
di as result "*******************************************"
di as result "Root Mean Squared Prediction Error (RMSPE) "
di as result "*******************************************"
di as txt "{hline 43}"
di as result "RMSPE = `myRMSPE'"
di as txt "{hline 43}"
********************************************************************************
di _newline(1)
di as result "*******************************************"
di as result "AVERAGE UNIT WEIGHTS                       "
di as result "*******************************************"
matlist `W' , tw(30) rowtitle("UNIT") border(rows)
ereturn matrix W=`W'
********************************************************************************
if "`save_res'"!=""{
preserve
use `save_res' , clear
keep `time_var' _Y1_ _Y0_
save `save_res' , replace
restore
}
end

********************************************************************************
* PROGRAM FOR VARIOUS KERNELS GENERATION: "_Kernel_"
********************************************************************************
capture program drop _Kernel_
program _Kernel_, rclass
version 13
#delimit;     
syntax varlist(min=1 max=1 numeric) [if] [in] [fweight iweight pweight] ,
bwidth(numlist max=1)
kernel(string)
[cvfile(string)
graph];
#delimit cr
********************************************************************************
marksample touse
tokenize `varlist'
local dif `1'  
********************************************************************************
tempvar weight
if ("`kernel'"=="epan") {
	qui g double `weight' = 1 - (`dif'/`bwidth')^2 if abs(`dif')<=`bwidth' & `touse'
	}
else if ("`kernel'"=="normal") {
		qui g double `weight' = normalden(`dif'/`bwidth')  if  `touse'
	}
else if ("`kernel'"=="biweight") {
		qui g double `weight' = (1 - (`dif'/`bwidth')^2)^2 if abs(`dif')<=`bwidth' & `touse'
	}
else if ("`kernel'"=="uniform") {
		qui g double `weight' = 1 if abs(`dif')<=`bwidth' &  `touse'
	}
else if ("`kernel'"=="triangular") {
		qui g double `weight' = (1-abs(`dif'/`bwidth')) if abs(`dif')<=`bwidth' & `touse'
	}	
else if ("`kernel'"=="tricube") {
		qui g double `weight' = (1-abs(`dif'/`bwidth')^3)^3 if abs(`dif')<=`bwidth' & `touse'
	}
	// normalize sum of weights to 1
qui sum `weight'  if  `touse' , mean
replace `weight' = `weight'/r(sum)  if  `touse'
cap drop _weight
gen _weight=`weight' if  `touse'
end
********************************************************************************
* End of npsynth
********************************************************************************
