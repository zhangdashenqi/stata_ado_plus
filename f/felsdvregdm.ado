* 1.1.0 KM June 2009
* Author: Kata Mihaly, The RAND Corporation
* based on felsdvreg.ado, written by Thomas Cornelissen, University of Hannover, Germany
* Incorporates the grouping algorithm of Robert Creecy (original author), Lars Vilhuber (current author), Amine Ouazad (Stata port)
program define felsdvregdm, eclass
version 9.2

syntax varlist(min=1) [if] [in], Ivar(varname) Jvar(varname) Feff(name) Peff(name) Reff(name) xb(name) res(name) Mover(name) mnum(name) pobs(name) Group(name) [robust CLuster(varname) noadji noadjj onelevel NORMalize NOIsily CHOLsolve mem NOCOMPress hat(varlist) orig(varlist) feffse(name) grouponly]
set more off

timer clear
tempvar itemp jtemp jtemp2 miss sample n firmnum feffgbar f p pf gmax jmin moverp firm mnumcat cltemp refftemp constemp
tempvar indid unitid groupcheck largestgrp numdiffgrp groupkeep moversample mingrp maxgrp /*Grouping*/
tempvar minreff maxreff diffreff diffreff2
tempfile tempgroupfile tempdatafile /*Grouping*/

marksample touse
set varabbrev off

if "`grouponly'"=="grouponly" {
	di in yellow "Note: You specified 'grouponly'. Only the group variable was modified and saved."
	di "      No estimates were produced."	
	if wordcount("`varlist'")==1 {
		qui gen `constemp' = 1
		local varlist `varlist' `constemp'		
	}

	qui egen `miss'=rowmiss(`varlist' `ivar' `jvar')
	qui gen `sample'=0
	qui replace `sample'=1 if `touse' & `miss'==0

	tokenize "`varlist'"
	local depvar "`1'"
	qui _rmdcoll `varlist' if `sample'==1
	local varlist `depvar' `r(varlist)'
	tokenize "`varlist'"
	local depvar "`1'"
	mac shift
	local indepvar "`*'"

	capture drop `group'
	qui gen `group'=.
	qui gen `n'=_n if `sample'==1
	
	preserve
	qui keep if `sample'==1
	qui keep `ivar' `jvar' `varlist' `orig' `sample' `n' `group' `cluster'

	qui egen `itemp'=group(`ivar') if `sample'==1
	qui egen `jtemp2'=group(`jvar') if `sample'==1
	sort `itemp' `jtemp2'

	qui by `itemp': gen byte `p'=1 if _n==1
	qui by `itemp': gen `pobs'=_N
	qui by `itemp' `jtemp2': gen `pf'=1 if _n==1
	qui sum `pf'
	qui by `itemp': egen `firmnum'=sum(`pf')
	qui gen `mover'=(`firmnum'>1)
	qui bysort `jtemp2': egen `mnum'=sum(`mover')
	qui bysort `jtemp2': gen `f'=1 if _n==1

	if r(mean)==0 {
		di in red "There are no movers in the sample. No firm effects can be identified."
		exit(2000)
	}
	
	qui replace `jtemp2'=0 if `mnum'==0
	qui egen `jtemp'=group(`jtemp2') if `sample'==1
	qui drop `jtemp2'

	qui drop `group'
	*---------------------------GROUPING START
	global ORIGAUTHOR     = "Robert Creecy"
	global CURRENTAUTHOR  = "Lars Vilhuber, STATA port by Amine Ouazad"
	global VERSION	    = "0.1"

	quietly {

	save "`tempdatafile'", replace

	keep if `mnum'>0
	keep `itemp' `jtemp'

	egen `indid'  = group(`itemp')
	egen `unitid' = group(`jtemp')

	keep `itemp' `jtemp'  `indid' `unitid' 

	***** Keeps only cells : we are working with cells, not observations
	duplicates drop  `indid' `unitid', force

	mata: groups( "`indid'","`unitid'","`group'")

	*** Drop new school and pupil indexes
	keep `itemp' `jtemp' `group'
	sort `itemp' `jtemp'
	save "`tempgroupfile'", replace

	*** Merge group information with main input data file

	use "`tempdatafile'"

	sort `itemp' `jtemp'
	merge `itemp' `jtemp' using "`tempgroupfile'"
	drop _merge
	}

	/* --------------------------------------------------------------------------- */

	qui replace `group'=0 if `mnum'==0	
	qui sum `group'

	sort `group'
	qui gen `moverp'=`mover' if `p'==1
	sort `jtemp'
	qui by `jtemp': gen `firm'=1 if _n==1
	local last=0
	qui sum `firm'
	local firms=r(N)

	di _newline "Groups of firms connected by worker mobility:"
	di  _newline "             Person-years       Persons          Movers         Firms"
	table `group', c(N `itemp' N `p' sum `moverp' N `f') row

	qui sum `group'
	if r(min)==0 {
		di _newline "Note: Group 0 in the table regroups firms without movers."
		}

	mata: save1("`group'")

}	
*---------------------------GROUPING END

else {

timer on 23

if "`noisily'"=="noisily" {
	disp in yellow "Step 0 - Basic data checks"
}

cap qui sum `group'
if _rc ==0 {
	di in yellow "The group variable (called `group') that exists in the dataset will be replaced!"
}

if "`reff'"=="`group'" {
	di in red "Reference collection and group variables must have different names"
	exit(197)
}	

* KM: for now this is disabled
if "`robust'"=="robust" {
	di in red "Robust option is disabled. Please see later versions of the command."
	exit(197)
}	
if "`cluster'"!="" {
	di in red "Cluster option is disabled. Please see later versions of the command."
	exit(197)
}	

if "`hat'"!="" | "`orig'"!="" {
	di in red "Hat and Orig options are disabled. Please see later versions of the command."
	exit(197)
}

if "`noisily'"=="noisily" {
	display in yellow "Step 1 - Selecting sample and covariate collinearity check "
}
timer on 1
qui egen `miss'=rowmiss(`varlist' `ivar' `jvar')
qui gen `sample'=0
qui replace `sample'=1 if `touse' & `miss'==0

capture drop `feff'
capture drop `feffse'
capture drop `peff'
capture drop `xb'
capture drop `res'
capture drop `mover'
capture drop `mnum'
capture drop `pobs'
capture drop `group'
cap scalar drop maxtokens

* KM: first check explicit regressor collinearity 
tokenize "`varlist'"
local depvar "`1'"
if "`onelevel'"=="onelevel" {
	_rmdcoll `varlist' if `sample'==1, nocons
}
else {
	_rmdcoll `varlist' if `sample'==1
}
local varlist `depvar' `r(varlist)'
tokenize "`varlist'"
local depvar "`1'"
mac shift
local indepvar "`*'"

qui gen `group'=.
qui gen `mover'=.
qui gen `n'=_n if `sample'==1
qui gen `refftemp' = .
timer off 1

if "`nocompress'"!="nocompress" {
if "`noisily'"=="noisily" {
	disp in yellow "Step 2 - Preserve dataset and compress"
}
timer on 2
preserve
qui keep if `sample'==1
qui keep `ivar' `jvar' `varlist' `orig' `sample' `n' `group' `cluster' `reff' `refftemp' `touse'
*Compressing data set. Use option 'nocompress' to avoid compressing
qui compress
timer off 2
}
else {
if "`noisily'"=="noisily" {
	disp in yellow "Step 2 - Preserve dataset"
}
timer on 2
preserve
qui keep if `sample'==1
qui keep `ivar' `jvar' `varlist' `orig' `sample' `n' `group' `cluster' `reff' `refftemp' `touse'
timer off 2
}

if "`noisily'"=="noisily" {
	disp in yellow "Step 3 - Generate smooth person, firm and reference collection ids"
}
timer on 3

qui egen `itemp'=group(`ivar') if `sample'==1
qui egen `jtemp2'=group(`jvar') if `sample'==1
qui drop `refftemp'
qui egen `refftemp' = group(`reff') if `sample'==1

* KM: check if jvar is unique to reference collection
bysort `jtemp2': egen `minreff' = min(`refftemp')
bysort `jtemp2': egen `maxreff' = max(`refftemp')
qui count if `maxreff' != `minreff'
if r(N)>0 {
	di in red "The jvar variable (called `jvar') is not exclusive to the reference collection"
	di in red "Sum-to-zero effects cannot be calculated if jvar crosses reference collections"
	di in red "Redefine jvar, so that each value of the jvar is unique to a reference collection"
	di in red "perhaps using egen group() command"
	exit(197)
	}	

timer off 3

if "`noisily'"=="noisily" {
	disp in yellow "Step 4 - Sort dataset"
}
timer on 4
sort `itemp' `jtemp2'
timer off 4

if "`noisily'"=="noisily" {
	disp in yellow "Step 5 - Determine stayers and movers for grouping algorithm"
}
* this is before check for multiple group, so no output
timer on 5
qui by `itemp': gen byte `p'=1 if _n==1
qui by `itemp': gen `pobs'=_N
qui by `itemp' `jtemp2': gen `pf'=1 if _n==1
qui sum `pf'
qui by `itemp': egen `firmnum'=sum(`pf')
qui gen `mover'=(`firmnum'>1)
label variable `mover' "Mover"
label variable `pobs' "Obs. per person"
qui bysort `jtemp2': egen `mnum'=sum(`mover')
qui bysort `jtemp2': gen `f'=1 if _n==1
timer off 5

if "`noisily'"=="noisily" {
	disp in yellow "Step 6 - Group firms without movers under artificial firm IDs"
}
timer on 6
qui replace `jtemp2'=0 if `mnum'==0
qui egen `jtemp'=group(`jtemp2') if `sample'==1
qui drop `jtemp2'
timer off 6

timer on 7

if "`noisily'"=="noisily" {
	disp in yellow "Step 7 - Get strata amd compare to reference collections"
	disp in yellow "         for two level fixed effect models"
}

qui drop `group'
*---------------------------GROUPING START
global ORIGAUTHOR     = "Robert Creecy"
global CURRENTAUTHOR  = "Lars Vilhuber, STATA port by Amine Ouazad"
global VERSION	    = "0.1"

quietly {
	save "`tempdatafile'", replace
	keep if `mnum'>0
	keep `itemp' `jtemp'

	egen `indid'  = group(`itemp')
	egen `unitid' = group(`jtemp')

	keep `itemp' `jtemp'  `indid' `unitid' 

	***** Keeps only cells : we are working with cells, not observations
	duplicates drop  `indid' `unitid', force

	mata: groups( "`indid'","`unitid'","`group'")

	*** Drop new school and pupil indexes
	keep `itemp' `jtemp' `group'
	sort `itemp' `jtemp'
	save "`tempgroupfile'", replace

	*** Merge group information with main input data file

	use "`tempdatafile'"
	
	sort `itemp' `jtemp'
	merge `itemp' `jtemp' using "`tempgroupfile'"
	drop _merge
}

	/* --------------------------------------------------------------------------- */

if "`onelevel'"!="onelevel" {
	* KM: check to make sure reference collections do not cross groups (strata)
	bysort `refftemp': egen `mingrp' = min(`group')
	bysort `refftemp': egen `maxgrp' = max(`group')
	qui count if `maxgrp' != `mingrp'
	if r(N)>0 {
		di in red "The refference collection variable (called `reff') is not exclusive to groups"
		di in red "Sum-to-zero effects cannot be calculated if reference collections are in multiple groups"
		di in red "Redefine refference collection, so that each value of the reff is unique to a group"
		di in red "perhaps using egen group() command"
		exit(197)
		}	

	

	*---------------------------GROUPING END
}

timer off 7

if "`noisily'"=="noisily" {
	disp in yellow "Step 8 - Determine stayers and movers after grouping, for descriptive tables"
}
timer on 8
qui drop `itemp' `jtemp' `p' `pobs' `pf' `firmnum' `mnum' `f'
qui egen `itemp'=group(`ivar') if `sample'==1
qui egen `jtemp2'=group(`jvar') if `sample'==1
qui sort `itemp' `jtemp2'
qui by `itemp': gen byte `p'=1 if _n==1 & `sample'==1
qui by `itemp': gen `pobs'=_N if `sample'==1
qui by `itemp' `jtemp2': gen `pf'=1 if _n==1 & `sample'==1
qui sum `pf' if `sample'==1
if "`noisily'"=="noisily" {
	di in yellow _newline "Unique worker-firm combinations: " r(N)  _newline 
	}
qui by `itemp': egen `firmnum'=sum(`pf') if `sample'==1
if "`noisily'"=="noisily" {
	 di "Number of firms workers are employed in:"
	label variable `firmnum' "Number of firms"
	tab `firmnum' if `p'==1 & `sample'==1
	}
qui replace `mover'=(`firmnum'>1) if `sample'==1
qui label variable `mover' "Mover"
qui label variable `pobs' "Obs. per person"
if "`noisily'"=="noisily" {
	di  _newline "Number of movers (0=Stayer, 1=Mover):"
	tab `mover' if `p'==1 & `sample'==1
	di  _newline "Number of observations per person:"
	tab `pobs' if `p'==1 & `sample'==1
	}
qui bysort `jtemp2': egen `mnum'=sum(`mover') if `sample'==1
qui bysort `jtemp2': gen `f'=1 if _n==1 & `sample'==1
if "`noisily'"=="noisily" {
	di _newline "Number of movers per firm:"
	qui gen `mnumcat'=0 if `mnum'==0 & `sample'==1
	qui replace `mnumcat'=1 if `mnum'>0 & `mnum'<=5 & `sample'==1
	qui replace `mnumcat'=2 if `mnum'>5 & `mnum'<=10 & `sample'==1
	qui replace `mnumcat'=3 if `mnum'>10 & `mnum'<=20 & `sample'==1
	qui replace `mnumcat'=4 if `mnum'>20 & `mnum'<=30 & `sample'==1
	qui replace `mnumcat'=5 if `mnum'>30 & `mnum'<=50 & `sample'==1
	qui replace `mnumcat'=6 if `mnum'>50 & `mnum'<=100 & `sample'==1
	qui replace `mnumcat'=7 if `mnum'>100 & `sample'==1
	qui label define `mnumcat' 0 "      0" 1 " 1-  5" 2 " 6- 10" 3 "11- 20" 4 "21- 30" 5 "31- 50" 6 "51- 100" 7 ">100"
	qui label values `mnumcat' `mnumcat'
	qui label variable `mnumcat' "Movers per firm"
	tab `mnumcat' if `f'==1 & `sample'==1
	}
qui sum `mnum' if `sample'==1
if r(mean)==0 {
	di in red "There are no movers in the sample. No firm effects can be identified."
	exit(2000)
	}
local minmnum = r(min)

*KM: replace temporary reff variable if firm only has nonmovers, redefine jvar
qui replace `refftemp' = 0 if `mnum'==0
qui gen `moversample'  = (`sample'==1)
qui replace `moversample' = 0 if `mnum'==0

qui replace `jtemp2'=0 if `mnum'==0 & `sample'==1
qui egen `jtemp'=group(`jtemp2') if `sample'==1
qui drop `jtemp2'
timer off 8


*KM: make sure that have unique firm ids within each reference group
timer on 9
qui egen `jtemp2'=group(`refftemp' `jtemp') if `sample'==1
qui drop `jtemp'
qui rename `jtemp2' `jtemp'

local origvarlist ""
if "`onelevel'"=="onelevel" {
	if "`noisily'"=="noisily" {
		disp in yellow "Step 9 - One level model - no within transformation"
	}
	tokenize "`varlist'"
	while "`1'" != "" {
		qui gen orig`1' = `1' if `sample'==1
		macro shift
	}
}
else {
	if "`noisily'"=="noisily" {
		disp in yellow "Step 9 - Two level model - perform within transformation"
	}
	foreach y of any `varlist'{
		qui bysort `itemp': egen `y'm=mean(`y') if `sample'==1
		qui gen orig`y' = `y' if `sample'==1
		quietly replace `y'=`y'-`y'm if `sample'==1
		drop `y'm
	}
}
timer off 9

if "`noisily'"=="noisily" {
	disp in yellow "Step 10 - Check for reference collection fixed effects and "
	disp in yellow "	whether they are collinear with the covariates"

}
timer on 10

qui xi i.`refftemp', noomit prefix(D)
if `minmnum'==0{
	qui drop D`refftemp'_0
}
qui sum `refftemp' if `sample'==1
local numreff = r(max) 
local numreffstart = r(min)
if `minmnum'==0{
	local numreffstart = 1
}
forval k = `numreffstart'/`numreff' {
	 qui cap drop origD`refftemp'_`k'
	 qui gen origD`refftemp'_`k' = D`refftemp'_`k' if `sample'==1
	 if "`onelevel'"!="onelevel" {
		 qui bysort `ivar': egen D`refftemp'_`k'm=mean(D`refftemp'_`k') if `sample'==1
		 qui replace D`refftemp'_`k'=D`refftemp'_`k'-D`refftemp'_`k'm if `sample'==1
	 	 qui drop D`refftemp'_`k'm
	 }
	qui replace D`refftemp'_`k' = . if `sample'==0
	rename D`refftemp'_`k' D`reff'_`k'
	cap rename origD`refftemp'_`k' origD`reff'_`k'
	if _rc {
		di in red "Please rename reference collection indicator variables in indepvars"
		di in red "The name you entered is in use by the command"
		exit(197)
	}
}

tokenize "`varlist'"
local depvar "`1'"
mac shift
local indepvar "`*'"
local addedvars " "
if "`indepvar'"!=""{
	qui _rmcollright (`indepvar') (D`reff'*) if `sample'==1, nocons
	qui return list
	scalar maxtokens = 1
	if "`r(varlist)'"~="`indepvar'" {
		display ""
		display "Some variables were added or dropped from the independent variables"
		display "Reference collection fixed effects may not be sufficiently defined,"
		display "Variables could be collinear due to multiple groups in the dataset,"
		display "Or some variables may be collinear with the second level of fixed effects"
		display "The following variable(s) were added to the explanatory variables"
		display " `r(block2)'"
		display "The following variable(s) were ignored or dropped from the explanatory variables"
		display " `r(dropped)'"
		display ""
		local addedvarstemp `r(block2)'
		local varlist `depvar' `r(block1)' `r(block2)'
		tokenize "`varlist'"
		local depvar "`1'"
		mac shift
		local indepvarin "`*'"
		* KM: start with maxtokens=1 on purpose, when use this need addedvars+1 - see step 14
		* KM: also, need to read in both regular and demeaned version, so maxtokens bumped by 2 each time
		tokenize "`addedvarstemp'"
		while "`1'" != "" {
			scalar maxtokens = maxtokens + 2
			local addedvars `addedvars' orig`1'
			macro shift 
		}
	}
	else {
		local indepvarin `indepvar'	
	}
}
else {
	if `numreff'!=1 {
		qui _rmcollright D`reff'* if `sample'==1, nocons
		qui return list
		display "Reference collection fixed effects were not included in explanatory variables,"
		display "The following variable(s) were added to the explanatory variables"
		display " `r(varlist)'"
		display "(The number represents consecutive values of the reference collection variable)"
		display ""
		local addedvarstemp `r(varlist)'
		local varlist `depvar' `r(varlist)'
		scalar maxtokens = 1
		tokenize "`varlist'"
		local depvar "`1'"
		mac shift
		local indepvarin "`*'"
	}
	else {
		local addedvarstemp D`reff'_1
		local varlist `depvar' D`reff'_1
		scalar maxtokens = 1
		tokenize "`varlist'"
		local depvar "`1'"
		mac shift
		local indepvarin "`*'"
		display "Reference collection fixed effects were not included in explanatory variables,"
		display "The following variable(s) were added to the explanatory variables"
		display " `indepvarin'"
		display "(The number represents consecutive values of the reference collection variable)"
		display ""
	}
	* KM: start with maxtokens=1 on purpose, when use this need addedvars+1 - see step 14
	* KM: also, need to read in both regular and demeaned version, so maxtokens bumped by 2 each time
	tokenize "`addedvarstemp'"
	while "`1'" != "" {
		scalar maxtokens = maxtokens + 2
		local addedvars `addedvars' orig`1'
		macro shift 
	}
}

* KM: need this for F tests
tokenize "`depvar'"
local origvarlist orig`1'
tokenize "`indepvarin'"
while "`1'" != "" {
	local origvarlist `origvarlist' orig`1'
	macro shift
}

if "`noisily'"=="noisily" {
	sort `sample' `refftemp' 
	qui gen `moverp'=`mover' if `p'==1 & `sample'==1
	sort `sample' `jtemp'
	qui by `sample' `jtemp': gen `firm'=1 if _n==_N 
	local last=0
	qui sum `firm'  if `sample'==1
	local firms=r(N)

if "`noisily'"=="noisily" {

	di _newline "Reference collection in firms connected by worker mobility:"
	di  _newline "             Person-years       Persons          Movers         Firms"
	table `refftemp', c(N `itemp' N `p' sum `moverp' N `f') row
	}

qui sum `f'  if `sample'==1
local firms=r(N)
qui sum `f' if `refftemp'==0  & `sample'==1
local nomov=r(N)
qui sum `refftemp'  if `sample'==1
if "`noisily'"=="noisily" {
	if r(min)==0 {
		di _newline "Note: Reference Collection 0 in the table regroups firms without movers."
		di _newline "No firm effects are identified for these firms."
		di _newline "These firms can be identified by the mnum variable (called `mnum') = 0"
		di `firms' "-" `nomov' "-" `r(max)' " = " `firms'-`nomov'-`r(max)' " firm effects are identified."
		di "(number of firms - number of firms without movers - number of firms with only nonmovers)"  _newline
		}
	else {
		di _newline "Note: Each firm has at least 1 mover."
		di `firms' "-" `r(max)' " = " `firms'-`r(max)' " firm effects are identified."
		di "Computed as: number of firms - number of reference collections" _newline
		}
	}
}
timer off 10

if "`noisily'"=="noisily" {
	disp in yellow "Step 11 - Fit restricted models for F-tests"
}
timer on 11
* KM: needed to move this so have correct explanatory vars
* Without firm effects, only student effects
if "`onelevel'"!="onelevel" {
	qui xtreg `origvarlist' if `sample'==1, i(`ivar') fe
	local rss_restf=`e(rss)'
	local numb_restf=`e(df_m)'+1
}
else {
	local numb_restf = .
	local rss_restf = .
}

* Without both effects, base model
* degrees of freedom rss
if "`onelevel'"=="onelevel" {
	qui reg `origvarlist' if `sample'==1, nocons
	local numb_rest=`e(df_m)'  
	local rss_rest=`e(rss)'
}
else {
	qui reg `origvarlist' if `sample'==1
	local numb_rest=`e(df_m)'+1  
	local rss_rest=`e(rss)'
}
qui reg `origvarlist' if `sample'==1
mat b=e(b)
mat V=e(V)
local obs=e(N)
ereturn clear
mat b=b[1,1..colsof(b)-1]
mat V=V[1..rowsof(V)-1,1..colsof(V)-1]
ereturn post b V, obs(`obs')
timer off 11

sort `itemp' `jtemp'

if "`noisily'"=="noisily" {
	display in green "Start Mata environment"
}
mata: decompreg("`depvar'","`indepvarin'","`itemp'","`jtemp'","`feff'","`peff'","`res'","`xb'","`normalize'","`mem'","`robust'","`cluster'","`cholsolve'","`hat'","`orig'","`addedvars'","`addedvarstemp'")

*Restricted model without person effects
* KM: replace demeaned version of added variable with original before run xtreg
if maxtokens>1 {
	qui tokenize "`addedvarstemp'"
	while "`1'" != "" {
		qui replace `1' = orig`1'
		macro shift 
	} 
}

_estimates hold felsdvregdm, copy
qui drop `jtemp' 
qui egen `jtemp'=group(`jvar') if `sample'==1
qui replace `jtemp'=0 if `feff'==0

* Without student effects, just firm effects (they are not centered here)
if "`onelevel'"!="onelevel" {
	qui xtreg `varlist', i(`jtemp') fe
	local rss_restp=`e(rss)'
	local numb_restp=`e(df_m)'+1
}
else {
	local rss_restp=.
	local numb_restp=.
}

_estimates unhold felsdvregdm
ereturn scalar rss_rest=`rss_rest'
ereturn scalar dof_rest=`numb_rest'
ereturn scalar rss_restp=`rss_restp'
ereturn scalar dof_restp=`numb_restp'
ereturn scalar rss_restf=`rss_restf'
ereturn scalar dof_restf=`numb_restf'

ereturn local cmd "felsdvregdm"

ereturn scalar F_f =((`e(rss_rest)'-`e(rss)')/`e(rss)')* (`e(df_r)'/(`e(df_m)'-`e(dof_rest)')) /* For F-test that all u_i equal zero*/

if "`onelevel'"!="onelevel" {
	ereturn scalar F_fp =((`e(rss_restp)'-`e(rss)')/`e(rss)')* (`e(df_r)'/(`e(df_m)'-`e(dof_restp)')) /* For F-test that all person effects equal zero*/
	ereturn scalar F_ff =((`e(rss_restf)'-`e(rss)')/`e(rss)')* (`e(df_r)'/(`e(df_m)'-`e(dof_restf)')) /* For F-test that all firm effects zero*/
}

di in green _newline "N=" e(N)

ereturn display

if "`hat'"!=""{
	di "RSS and standard errors are adjusted for 2SLS 2nd stage regression."
	local to=wordcount("`hat'")
	foreach i of numlist 1/`to'{
	di in yellow word("`hat'",`i') in green " is a 1st stage prediction from regression of " in yellow word("`orig'",`i') in green " on instruments."
	}
}

local Ftestdf_base = `e(df_m)'-`e(dof_rest)'
if "`hat'"==""{
	if "`onelevel'"=="onelevel" {
		di _newline "F-test that firm effects are equal to zero:   F(`Ftestdf_base',`e(df_r)')=" round(`e(F_f)',.001) " Prob > F = " round(Ftail(`e(dof_rest)',`e(df_r)',`e(F_f)'),.0001)	
	}
	else {
	local Ftestdf_p = `e(df_m)'-`e(dof_restp)'
	local Ftestdf_f = `e(df_m)'-`e(dof_restf)'
		di _newline "F-test that person and firm effects are zero: F(`Ftestdf_base',`e(df_r)')=" round(`e(F_f)',.001) " Prob > F = " round(Ftail(`e(dof_rest)',`e(df_r)',`e(F_f)'),.0001)
		di          "F-test that person effects are equal to zero: F(`Ftestdf_p',`e(df_r)')=" round(`e(F_fp)',.001) " Prob > F = " round(Ftail(`e(dof_restp)',`e(df_r)',`e(F_fp)'),.0001)
		di          "F-test that firm effects are equal to zero:   F(`Ftestdf_f',`e(df_r)')=" round(`e(F_ff)',.001) " Prob > F = " round(Ftail(`e(dof_restf)',`e(df_r)',`e(F_ff)'),.0001)
	}
}

if `e(df_r)'<0 {
	di _newline "Degrees of freedom are negative, you do not have sufficient observations!"
	di _newline "#firm effects + #person effects + #regressors exceeds sample size !!"
	}


qui correlate `depvar' `xb', covariance
local vary=r(Var_1)
local covxb=r(cov_12)
qui correlate `depvar' `peff', covariance
local covp=r(cov_12)
qui correlate `depvar' `feff', covariance
local covf=r(cov_12)
qui correlate `depvar' `res', covariance
local covr=r(cov_12)

if "`noisily'"=="noisily" {	
	di _newline "If the covariances are positive, the following may indicate the importance in explaining "
	di "the variance of `depvar':"
	di _newline "Cov(`depvar', `xb') / Var(`depvar'): " _column(50) `covxb'/`vary'
	di        "Cov(`depvar', `peff') / Var(`depvar'): " _column(50) `covp'/`vary'
	di        "Cov(`depvar', `feff') / Var(`depvar'): " _column(50) `covf'/`vary'
	di         "Cov(`depvar', `res') / Var(`depvar'): " _column(50) `covr'/`vary'
	}

* KM: drop demeaned version of variable, rename before close of program
if maxtokens>1 {
	qui tokenize "`addedvarstemp'"
	while "`1'" != "" {
		qui drop `1'
		qui rename orig`1' `1'
		macro shift 
	} 
}

* teacher effects set to missing in two level model if teacher only has nonmovers, they are not defined
if "`onelevel'"!="onelevel" {
	qui replace `feff' = . if `mnum'==0
	cap qui replace `feffse' = . if `mnum'==0
}


timer off 23
if "`noisily'"=="noisily" {
	display in yellow "Program is finished"
}
} /* End of grouponly else*/
end

/* -------------------------------- MATA CODE  -----------------------------------------------------  */
mata:
void decompreg(string scalar depvar, string scalar indepvar, string scalar ivar, string scalar jvar, string scalar feffn, string scalar peffn,  string scalar resn,  string scalar xbn, string scalar normalize, string scalar mem, string scalar rob, string scalar clust, string scalar chol,string scalar hat,string scalar orig,string scalar addedvars,string scalar addedvarstemp)
{

/* ------------------------------  Konstante generieren ------------------------------------------------------------*/


xindex=st_varindex(tokens(indepvar))
yindex=st_varindex(depvar)
iindex=st_varindex(ivar)
jindex=st_varindex(jvar)

if (clust!="") {
clindex=st_varindex(clust)
}



/* ---------------------------  Generate system of normal equations  ----------------------------------------*/

y=X=id=jd=jd2=.                                  /*Ist notwendig, sonst error "X2 not found".*/
						/* KM: added j2 */
st_view(y,.,yindex,st_macroexpand("`"+"sample"+"'"))
st_view(X,.,xindex,st_macroexpand("`"+"sample"+"'"))
st_view(jd,.,jindex,st_macroexpand("`"+"sample"+"'"))
numj=colmax(jd)

/*Step 12 - Compute Total sum of squares */
stata("timer on 12")
ybar = mean(y)
yy=cross(y:-ybar,y:-ybar)
st_numscalar("e(tss)",yy)

stata("timer off 12")

display("Memory requirement for moment matrices in GB:")
((cols(X)+numj)^2+cols(X)+numj)*8/1000000000

stata("timer on 13")

A=(quadcross(X,X),J(cols(X),numj,0) \ J(numj,cols(X),0),J(numj,numj,0))
B=(quadcross(X,y)\ J(numj,1,0))
if (clust!="" | rob=="robust") { /* Create matrix for clustered or robust standard errors already here to see if enough memory*/
display(" ")
display("Memory requirement for robust/clustered standard errors in GB:")
(sizeof(A))/1000000000
C=(J(cols(X),cols(X),0),J(cols(X),numj,0) \ J(numj,cols(X),0),J(numj,numj,0))
}
display (" ")

st_updata(1) /*Flag setzen dass Datensatz geändert wurde.*/
st_view(y,.,yindex,st_macroexpand("`"+"moversample"+"'"))
st_view(X,.,xindex,st_macroexpand("`"+"moversample"+"'"))
st_view(id,.,iindex,st_macroexpand("`"+"moversample"+"'"))
st_view(jd,.,jindex,st_macroexpand("`"+"moversample"+"'"))
numj=colmax(jd)

PI=panelsetup(id,1)

group=groupmover=havenonmover=.				/* KM: added groupmover and indicator for having group 0 teachers  - this is now reff*/
group=st_data(.,(st_varindex(st_macroexpand("`"+"refftemp"+"'")),jindex),st_macroexpand("`"+"sample"+"'"))
st_view(jd2,.,jindex)						/* KM: now use jd2 because use jd below */
group=sort(group,(1,2))

groupmover=st_data(.,(st_varindex(st_macroexpand("`"+"refftemp"+"'")),jindex),st_macroexpand("`"+"moversample"+"'"))
									/* KM: groupmover is same as group but only for movers, no sort */
havenonmover = (rows(group)!=rows(groupmover))

GI=panelsetup(group,1)

for (j=rows(GI); j>=1;j--) {
	GI[j,1]=group[GI[j,1],2]
	}

GI=sort(GI,(1))

numj=colmax(jd2)
GI[rows(GI),2]=numj

for (j=rows(GI)-1; j>=1;j--) {
	GI[j,2]=GI[j+1,1]-1
	}

jtest=uniqrows(jd2)
numcolsGI = GI[.,2] - GI[.,1]:+1          /*KM: counts number of teachers in each group */

stata("timer off 13")

/* 14. Filling in elements for movers */
							/* KM: used to be step 13, now 14*/
stata("timer on 14")
for (i=1; i<=rows(PI);i++) {

xi=panelsubmatrix(X,i,PI)
yi=panelsubmatrix(y,i,PI)
ji=panelsubmatrix(jd,i,PI)
PJ=panelsetup(ji,1)
groupi = panelsubmatrix(groupmover[.,1],i,PI)  /* KM: added groupi which i's group */
groupi = groupi:+havenonmover

repmat=.							/* KM: delete old ji variable - don't need uniquerows */ 
refteach = J(0,1,.)
for (a=1;a<=rows(groupi);a++) {
	refteach = refteach\(GI[groupi[a,1],1]:==ji[a,1])
}								/* KM: check if have ref teacher for each group, note that first group (group0) skipped if don't have stayers */

numref = sum(refteach)

fi=J(PJ[1,2]-PJ[1,1]+1,1,1)				/* KM: create fi the same as original felsdvreg code */
for (j=2; j<=rows(PJ);j++) {
	fi=fi \ J(PJ[j,2]-PJ[j,1]+1,1,j)
}
fi = designmatrix(fi)
ji = uniqrows(ji)						/* KM: indicator for teachers of student i */

if (numref!=0) {						/* KM: if have any reference teacher */
	refgroupall = refteach:*groupi
	refgroup = uniqrows(refgroupall)			/* KM: tag unique, nonzero reference group */
	if (refgroup[1,1] == 0) {
		refgroup = refgroup[2..rows(refgroup)]
	}

	check = 0						/* KM: check if have all teachers in ref group already */
	for (a=1;a<=rows(refgroup);a++) {
		temp1 = numcolsGI[refgroup[a]]
		temp2 = sum(refgroup[a]==refgroupall)
		temp = (temp1!=temp2)
		check = check+temp
	}
	
	jigroup = J(rows(ji),1,.) 
	for (k=1;k<=rows(ji);k++) {
		check1 = ji[k,1]:>=GI[.,1]
		check2 = ji[k,1]:<=GI[.,2]
		temp = uniqrows(((check1+check2):==2):*(range(1,rows(GI),1)))
		if (rows(temp)==1) {
			jigroup[k,1] = temp
		}
		else {
			jigroup[k,1] = temp[2,1]
		}
	}

	if (check>0) {					/* KM: if don't have all teachers, need to fill them in */
		fitemp = fi		
		jitemp = ji	
		jigrouptemp = jigroup
		fi = J(rows(fitemp),0,.)
		ji = J(0,1,.)
		jigroup = J(0,1,.)
		appended = J(0,1,.)
		track = J(1,1,0)		
		for (g = 1;g<=rows(refgroup);g++) {
			nficols = GI[refgroup[g],2]-GI[refgroup[g],1]+1
			fi = fi,J(rows(fitemp),nficols,0)
			ji = ji\(runningsum(J(nficols,1,1)) :+ (GI[refgroup[g],1]-1))	
			jigroup = jigroup\J(nficols,1,refgroup[g])
			appended = appended\J(nficols,1,0) 
			track = track\J(nficols,1,(max(track)+1))
		}
		jicols = runningsum(J(rows(ji),1,1)) 
		for (j = 1; j<=rows(jitemp); j++) {
			if (sum(jigrouptemp[j,1]:==refgroup)>0) {
				fi[.,max((ji:==jitemp[j,1]):*jicols)] = fitemp[.,j]
			}
			else {
				appended = appended\1
				track = track\(max(track)+1)				
				fi = fi,fitemp[.,j]
				ji = ji\jitemp[j,1]
				jigroup = jigroup\jigrouptemp[j,1]
				jicols = jicols\(max(jicols)+1)
			}
		}	
		track = track[2..rows(track)]		
	}
	
	repmat = J(rows(fi),cols(fi),0)				/* KM: for each group, replace with -1 if have ref teach */
	for (g = 1;g<=rows(refteach);g++) {
		if (refteach[g,1]>0) {
			repmat[g,.] = -1:*(jigroup :== groupi[g])'
		}
	}
	fi = fi+repmat						/* KM: recode fixed effect matrix */

}

if (st_macroexpand("`"+"onelevel"+"'")!="onelevel") {
	fi=fi:-mean(fi,1)
}

ff=quadcross(fi,fi)
xf=quadcross(xi,fi)
fy=quadcross(fi,yi)

if (numref==0) {
	for (j=1; j<=cols(ff);j++) {
	for (k=1; k<=rows(ff);k++) {
		A[cols(X)+ji[j],cols(X)+ji[k]]=A[cols(X)+ji[j],cols(X)+ji[k]]+ff[j,k]
		}
		}

	for (j=1; j<=rows(ji);j++) {
	A[1..rows(xf),ji[j]+cols(X)]=A[1..rows(xf),ji[j]+cols(X)]+xf[.,j]
	A[ji[j]+cols(X),1..rows(xf)]=A[ji[j]+cols(X),1..rows(xf)]+xf[.,j]'
	}

	fy=quadcross(fi,yi)
	for (j=1; j<=rows(ji);j++) {
	B[ji[j]+cols(X),1]=B[ji[j]+cols(X),1]+fy[j]
	}
}

else {
	RI = panelsetup(track,1)
	for (g1 = 1;g1<=rows(RI);g1++) {
		for (g2 = 1;g2<=rows(RI);g2++) {
			f1start = RI[g1,1]
			f1end = RI[g1,2]
			f2start = RI[g2,1]
			f2end = RI[g2,2]
			if (sum(panelsubmatrix(appended,g1,RI)) == 0) {			
				xx1start = cols(X)+GI[jigroup[RI[g1,1]],1]
				xx1end = cols(X)+GI[jigroup[RI[g1,1]],2]
			}
			else {
				xx1start = cols(X)+ji[RI[g1,1]]
				xx1end = cols(X)+ji[RI[g1,1]]
			}
			if (sum(panelsubmatrix(appended,g2,RI))==0) {
				xx2start = cols(X)+GI[jigroup[RI[g2,1]],1]
				xx2end = cols(X)+GI[jigroup[RI[g2,1]],2]
			}
			else {
				xx2start = cols(X)+ji[RI[g2,1]]
				xx2end = cols(X)+ji[RI[g2,1]]
			}
			A[|xx1start,xx2start\xx1end,xx2end|]=A[|xx1start,xx2start\xx1end,xx2end|]+ff[|f1start,f2start\f1end,f2end|]
		}
		A[|1,xx1start\rows(xf),xx1end|]=A[|1,xx1start\rows(xf),xx1end|]+xf[|1,f1start\rows(xf),f1end|]
		A[|xx1start,1\xx1end,rows(xf)|]=A[|xx1start,1\xx1end,rows(xf)|]+xf[|1,f1start\rows(xf),f1end|]'
		B[|xx1start,1\xx1end,.|]=B[|xx1start,1\xx1end,.|]+fy[|f1start,1\f1end,.|]
	}
}
}


stata("timer off 14")

/* -----------------------  Determine unidentified firm effects  ---------------------------------------*/

/* 15. Take out unidentified firm effects */

							/* KM: this used to be step 12, moved before step 15 */
stata("timer on 15")

jtest=uniqrows(jd2)
for (j=1; j<=rows(GI);j++) {
      for (i=cols(X)+GI[j,1]; i<=cols(X)+GI[j,2]-1;i++) {
	B[i-j+1]=B[i+1]
	A[.,i-j+1]=	A[.,i+1]
	A[i-j+1,.]=	A[i+1,.]
	}
}
numrowsdeleted = j-1

A=A[1..rows(A)-rows(GI),1..cols(A)-rows(GI)]

B=B[1..rows(B)-rows(GI)]

jd2=jd2[1..rows(jd2)-rows(GI)]

stata("timer off 15")


/* ------------------------ Solve -----------------------------------------------------------------------*/

if (mem=="mem") {
sizeof(A)
sizeof(B)
}

ranktol = .
tol = solve_tol(A,ranktol)
if (rank(A,tol)!=rank(quadcross(X,X))+numj-numrowsdeleted) {
	_error("Firm effects are collinear with explanatory variables - cannot proceed")
	}

if (chol!="") {
	printf("Solving for beta, dimension: %f\n", rows(A))
	display("  Start: "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))
	stata("timer on 16")
	beta=cholsolve(A,B)
	dropped=0
	stata("timer off 16")
	display("  End:   "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))
}
else{
	printf("Computing generalized inverse, dimension: %f\n", rows(A))
	display("  Start: "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))
	stata("timer on 16")
	o=cols(X)+1
	if (cols(A)>cols(X)+1) {
		for (j=cols(X)+2; j<=rows(A);j++) {
		o=o , j 
		}
	}
	_invsym(A,o)
	dropped=diag0cnt(A)
	beta=A*B
	stata("timer off 16")
	/*printf("  Collinear regressors dropped: %f\n", dropped)*/
	display("  End:   "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))
}

stata("timer on 17")

								/* KM: this stores all teacher FE, including reference teacher effect in each group */
betatemp=(beta[1..cols(X)])

if (havenonmover==1) {
	betatemp = betatemp \ 0
}

for (j=1+havenonmover; j<=rows(GI);j++) {
	if (numcolsGI[j,1]==1) {
		refteachFE = 0
	}
	else {
		refteachFE = sum(beta[cols(X)+GI[j,1]-j+1..cols(X)+GI[j,2]-j])
	}

	betatemp = betatemp\-refteachFE

	if (numcolsGI[j,1]!=1) {
		betatemp = betatemp\beta[cols(X)+GI[j,1]-j+1..cols(X)+GI[j,2]-j]
	}
}

for (j=1; j<=rows(GI);j++) {
	if (cols(X)+GI[j,1]<=rows(beta)){
		 beta=(beta[1..cols(X)+GI[j,1]-1] \ 0 \ beta[cols(X)+GI[j,1]..rows(beta)])
		 }
	else {
		beta=(beta[1..cols(X)+GI[j,1]-1] \ 0)
	}
}

st_matrix("b",beta[1..cols(X)]')		
st_matrixcolstripe("b",(J(cols(X),1," "),(st_varname(xindex)')))
st_view(jd,.,st_macroexpand("`"+"jvar"+"'"),st_macroexpand("`"+"sample"+"'"))

/* Copy variables mover, group, mnum and pobs for joining to the data after restore */
/* KM: first change sample macro if there were multiple groups and largest one used */

stata( "sort "+"`"+"ivar"+"'"+" "+"`"+"jvar"+"'")

n_mov_group_index=st_varindex((st_macroexpand("`"+"n"+"'"),st_macroexpand("`"+"mover"+"'"),st_macroexpand("`"+"group"+"'"),st_macroexpand("`"+"refftemp"+"'"),st_macroexpand("`"+"mnum"+"'"),st_macroexpand("`"+"pobs"+"'"),st_macroexpand("`"+"itemp"+"'"),st_macroexpand("`"+"jtemp"+"'")))
n_mov_group=st_data(.,n_mov_group_index,st_macroexpand("`"+"sample"+"'"))

/* KM: also copy added variables */
if (st_numscalar("maxtokens")>1) {
	addedvarsvec = (range(2,st_numscalar("maxtokens"),1))'
	addedvars_index = (st_varindex(st_macroexpand("`"+"n"+"'")),st_varindex(tokens(addedvars)),st_varindex(tokens(addedvarstemp)))
	addedvarsdata=st_data(.,addedvars_index,st_macroexpand("`"+"sample"+"'"))
}

/*17. Restore dataset */

stata("restore")
stata("timer off 17")

/*18. Generate smooth firm and person IDs again */
stata("timer on 18")
stata( "sort "+"`"+"n"+"'")	
stata( "qui gen "+"`"+"itemp"+"'"+"=.")
stata( "qui gen "+"`"+"jtemp"+"'"+"=.")
stata( "qui gen "+"`"+"mnum"+"'"+"=.")
stata( "qui gen "+"`"+"pobs"+"'"+"=.")

/*Join Mover and Group to data */
n_mov_group=sort(n_mov_group,1)
st_store(.,(st_macroexpand("`"+"mover"+"'"),st_macroexpand("`"+"group"+"'"),st_macroexpand("`"+"refftemp"+"'"),st_macroexpand("`"+"mnum"+"'"),st_macroexpand("`"+"pobs"+"'"),st_macroexpand("`"+"itemp"+"'"),st_macroexpand("`"+"jtemp"+"'")),st_macroexpand("`"+"sample"+"'"),n_mov_group[.,(2,3,4,5,6,7,8)])


if (st_numscalar("maxtokens")>1) {
	addedvarnames = tokens(addedvars)
	for (i=1;i<=(st_numscalar("maxtokens")-1)/2;i++) {
		stata( "qui cap gen "+addedvarnames[1,i]+"=.")
	}
	addedvarnamesdm = tokens(addedvarstemp)
	for (i=1;i<=(st_numscalar("maxtokens")-1)/2;i++) {
		stata( "qui cap gen "+addedvarnamesdm[1,i]+"=.")
	}
	addedvarsdata = sort(addedvarsdata,1)
	st_store(.,(tokens(addedvars),tokens(addedvarstemp)),st_macroexpand("`"+"sample"+"'"),addedvarsdata[.,addedvarsvec])	
}

stata("timer off 18")


/*Predicting x'b and assigning firm effects */			/* KM: note that firm effect we pass out different from what used in calculations  */
stata("timer on 19")

xindex=st_varindex(tokens(indepvar))
hatindex=st_varindex(tokens(hat))
origindex=st_varindex(tokens(orig))
xoindex=xindex

for (i=1; i<=cols(hatindex);i++) {
	_editvalue(xoindex,hatindex[i],origindex[i])
	}

yindex=st_varindex(depvar)
iindex=st_varindex(ivar)
jindex=st_varindex(jvar)
gindex=st_varindex(st_macroexpand("`"+"group"+"'"))

stata( "sort "+"`"+"itemp"+"'")
st_view(y,.,yindex,st_macroexpand("`"+"sample"+"'"))
st_view(X,.,xindex,st_macroexpand("`"+"sample"+"'"))
st_view(Xo,.,xoindex,st_macroexpand("`"+"sample"+"'"))
st_view(id,.,iindex,st_macroexpand("`"+"sample"+"'"))
st_view(jd,.,jindex,st_macroexpand("`"+"sample"+"'"))
numj=colmax(jd)

xb=feff=fefftemp=peff=res=J(rows(X),1,0)			/* KM: added fefftemp to store teacher FE, including reference teacher */

for (i=1; i<=rows(X);i++) {
xb[i]=X[i,.]*beta[1..cols(X)]
feff[i]=beta[cols(X)+jd[i]]
fefftemp[i]=betatemp[cols(X)+jd[i]]
}
if (hat!=""){
	xbo=reso=J(rows(X),1,0)
	for (i=1; i<=rows(X);i++) {
	xbo[i]=Xo[i,.]*beta[1..cols(X)]
	}
}

st_store(.,st_addvar("float",(feffn)),st_macroexpand("`"+"sample"+"'"),(fefftemp))

/*Firmeneffekte normlisieren*/		/* KM: this is no longer be valid, already normalized */

if (normalize=="normalize") {
	feffindex=st_varindex(feffn)
	stata("qui egen "+"`"+"feffgbar"+"'"+" = mean("+"`"+"feff"+"'"+"), by("+"`"+"group"+"'"+")")
	stata("qui replace "+"`"+"feff"+"'"+" = "+"`"+"feff"+"'"+"-"+"`"+"feffgbar"+"'")
	feff=st_data(.,feffindex,st_macroexpand("`"+"sample"+"'"))
	}
stata("timer off 19")


/*20. Computing residuals and person effects */			/* KM: for residuals, use original feff */
stata("timer on 20")
PI=panelsetup(id,1)

for (i=1; i<=rows(X);i++) {
res[i]=y[i]-xb[i]-fefftemp[i]
}


if (hat!=""){
for (i=1; i<=rows(X);i++) {
reso[i]=y[i]-xbo[i]-fefftemp[i]
}
}


for (i=1; i<=rows(PI);i++) {
	if (st_macroexpand("`"+"onelevel"+"'")!="onelevel") {
		peff[PI[i,1]..PI[i,2],1]=J(PI[i,2]-PI[i,1]+1,1,mean(panelsubmatrix(res,i,PI),1))
	}
	else {
		peff[PI[i,1]..PI[i,2],1]=J(PI[i,2]-PI[i,1]+1,1,0)
	}
}
res=res-peff


uu=cross(res,res)
st_numscalar("e(rss)",uu)
st_numscalar("e(r2)",1-uu/yy)

if (hat!=""){
	if (st_macroexpand("`"+"onelevel"+"'")!="onelevel") {
		reso=reso-peff
	}
	uu=cross(reso,reso)
	st_numscalar("e(rss)",uu)
}

k=cols(X)

if (st_macroexpand("`"+"onelevel"+"'")=="onelevel") {
	dof=cols(A)
}
else {
	dof=cols(A)+rows(PI)
}

/* correction for one reff collection, no covariates, two level model*/
if (cols(X)==1 & dropped==1 & (st_macroexpand("`"+"numreff"+"'")=="1") & (st_macroexpand("`"+"onelevel"+"'")!="onelevel")) {
	dof = dof-1
}

dofr = rows(X) - dof

covars=cols(X)

/*With cluster option, if panels i and j are considered going off to infinity, DoF is different*/
if (clust!="") {
if (st_macroexpand("`"+"adji"+"'")=="noadji") {
	dof=dof+(rows(PI)-1)
	}
if (st_macroexpand("`"+"adjj"+"'")=="noadjj") {
	dof=dof+(cols(A)-cols(X))
	}
}

st_numscalar("e(df_r)",dofr)
st_numscalar("e(df_m)",dof)
st_numscalar("e(numb_covars)",covars)

sigmau=sqrt(uu/dofr)
st_numscalar("e(rmse)",sigmau)
stata("timer off 20")

if (chol!="") {
	display("")
	display("Solving for covariance matrix")
	display("  Start: "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))
	stata("timer on 21")
	_cholinv(A)
	stata("timer off 21")
	display("  End:   "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))
}

st_store(.,st_addvar("float",(peffn,xbn,resn)),st_macroexpand("`"+"sample"+"'"),(peff,xb,res))

/* +++++++++++++++++    START CLUSTERED STANDARD ERRORS +++++++++++++++++++++++++++ */
if (clust!="") {
display("")
stata("timer on 25")
stata( "sort "+"`"+"cluster"+"'")
stata( "qui egen "+"`"+"cltemp"+"'"+"=group("+"`"+"cluster"+"'"+") if "+st_macroexpand("`"+"sample"+"'")+"==1")

xindex=st_varindex(tokens(indepvar))
yindex=st_varindex(depvar)
iindex=st_varindex(ivar)
jindex=st_varindex(jvar)
resindex=st_varindex(st_macroexpand("`"+"res"+"'"))
movindex=st_varindex(st_macroexpand("`"+"mover"+"'"))
clindex=st_varindex(st_macroexpand("`"+"cltemp"+"'"))

/*C=(J(cols(X),cols(X),0),J(cols(X),numj,0) \ J(numj,cols(X),0),J(numj,numj,0))*/

st_view(X,.,xindex,st_macroexpand("`"+"sample"+"'"))
st_view(res,.,resindex,st_macroexpand("`"+"sample"+"'"))
st_view(id,.,iindex,st_macroexpand("`"+"sample"+"'"))
st_view(jd,.,jindex,st_macroexpand("`"+"sample"+"'"))
st_view(cl,.,clindex,st_macroexpand("`"+"sample"+"'"))
st_view(mover,.,movindex,st_macroexpand("`"+"sample"+"'"))

obs=rows(X)
PC=panelsetup(cl,1)
nocl=rows(PC)

printf("Computing clustered standard errors, clusters:  %f\n", nocl)
display("  Start: "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))

for (c=1; c<=rows(PC);c++) {      /*Start loop over Clusters*/
	if (c==1){
	stata("timer on 30")
	}
	if (c==2){
	stata("timer off 30")
	}

	idc=uniqrows(id[PC[c,1]..PC[c,2]])  /* Sorted vector of all person IDs in cluster */
	xic=J(1,cols(X),0)
	mc=0
	for (i=1; i<=rows(idc);i++) {    /*Start loop over Persons*/
		ident=id:==idc[i]
		xi=select(X,ident)
		xi=xi:-mean(xi,1)
		mi=select(mover,ident)
		resi=select(res,ident)
		cli=select(cl,ident)
		cident=cli:==c         /* Identification vector for all observations for peson i with respect to cluster c*/
	
		if (rows(xi)>1){ 
			xi=select(xi,cident)	
			}
		if (rows(resi)>1){
			resi=select(resi,cident)
			}

		xi=xi:*resi
		xic=xic+colsum(xi)

		mc=mc+mi[1,1]
		if (mi[1,1]==1) { /*Begin if mover*/
		ji=select(jd,ident)
		jiu=uniqrows(ji)
		fi=ji:==jiu[1]

		if (rows(jiu)>1){
		 for (j=2; j<=rows(jiu);j++) {
		  	 fi=fi,ji:==jiu[j]
			 }
		  }

		fi=fi:-mean(fi,1)

		if (rows(fi)>1){
			fi=select(fi,cident)
			}
		fi=fi:*resi
		fi=colsum(fi)
		jiu=jiu'

		if (mc==1){      					      /* If first mover in the cluster, create jdc and fic new */
			jdc=jiu
			fic=fi
			}   
		else {                                                 /* Otherwise .... */
			for (j=1; j<=cols(jiu);j++) {	 /* For all firms person was employed*/			
 			      ind=jdc:==jiu[j]
 	 		      if (sum(ind)>0) {                         /* add value of fi to fic if firm already in jdc/fic.... */
				ind=jdc:<=jiu[j]
				fic[sum(ind)]=fic[sum(ind)]+fi[j]
				}
			   else {                                      /* if firm not already there either append in the end....*/
					if (jiu[j]>jdc[cols(jdc)]) {
						jdc=jdc,jiu[j]
						fic=fic,fi[j]
						                     }
					else {					/* or insert it....*/
						ind=sum(jdc:<jiu[j])
						if (ind>0) {
							jdc=jdc[1..ind],jiu[j],jdc[ind+1..cols(jdc)]  /*...in the middle*/
							fic=fic[1..ind],fi[j],fic[ind+1..cols(fic)]
							}
						else {
							jdc=jiu[j],jdc[ind+1..cols(jdc)] /* ...or in the first place*/
							fic=fi[j],fic[ind+1..cols(fic)]
							}
						}				   
				   }  /* if firm not already there */
			   }  /* End for all firms person was employed*/			


			}
		

		} /*End if mover*/
		}  /*End loop over Persons*/

xx=quadcross(xic,xic)
C[1..cols(X),1..cols(X)]=C[1..cols(X),1..cols(X)]+xx

if (mc>0) { /* If there were movers in the cluster */
ff=quadcross(fic,fic)
xf=quadcross(xic,fic)

for (l=1; l<=cols(ff);l++) {
for (k=1; k<=rows(ff);k++) {
	C[cols(X)+jdc[l],cols(X)+jdc[k]]=C[cols(X)+jdc[l],cols(X)+jdc[k]]+ff[l,k]
	}
	}

for (l=1; l<=cols(jdc);l++) {
C[1..rows(xf),jdc[l]+cols(X)]=C[1..rows(xf),jdc[l]+cols(X)]+xf[.,l]
C[jdc[l]+cols(X),1..rows(xf)]=C[jdc[l]+cols(X),1..rows(xf)]+xf[.,l]'
}
} /*End if there were movers in cluster */

	}  /*End loop over Clusters*/
display("  End:   "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))
} /*End if cluster option*/



/* +++++++++++++++++     END CLUSTERED STANDARD ERRORS +++++++++++++++++++++++++++ */
/* +++++++++++++++++    START ROBUST   STANDARD ERRORS +++++++++++++++++++++++++++ */
if (clust=="" & rob=="robust") {
display("")
display("Computing robust standard errors")
display("  Start: "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))
stata("timer on 25")
stata( "sort "+"`"+"itemp"+"' "+"`"+"jtemp"+"' ")

xindex=st_varindex(tokens(indepvar))
yindex=st_varindex(depvar)
iindex=st_varindex(ivar)
jindex=st_varindex(jvar)
resindex=st_varindex(st_macroexpand("`"+"res"+"'"))
movindex=st_varindex(st_macroexpand("`"+"mover"+"'"))

/*C=(J(cols(X),cols(X),0),J(cols(X),numj,0) \ J(numj,cols(X),0),J(numj,numj,0))*/

st_view(y,.,yindex,st_macroexpand("`"+"sample"+"'"))
st_view(X,.,xindex,st_macroexpand("`"+"sample"+"'"))
st_view(res,.,resindex,st_macroexpand("`"+"sample"+"'"))
st_view(id,.,iindex,st_macroexpand("`"+"sample"+"'"))
st_view(jd,.,jindex,st_macroexpand("`"+"sample"+"'"))
PI=panelsetup(id,1)
obs=rows(X)
for (i=1; i<=rows(PI);i++) {      
xi=panelsubmatrix(X,i,PI)
ji=panelsubmatrix(jd,i,PI)
PJ=panelsetup(ji,1)
ji=uniqrows(ji)

xi=xi:-mean(xi,1)
for (p=1; p<=rows(PJ);p++) {    /* p which firm of the firms person i is observed in this refers to  */
for (j=PJ[p,1]; j<=PJ[p,2];j++) {   /* j counts at which observation of person i we are */
	C[1..cols(X),1..cols(X)]=C[1..cols(X),1..cols(X)]+quadcross(xi[j,.],xi[j,.])*res[PI[i,1]+j-1,1]^2
	}
	}
}

stata( "qui replace "+"`"+"mover"+"' =0 if "+"`"+"sample"+"' ==0")
movindex=st_varindex(st_macroexpand("`"+"mover"+"'"))
st_view(y,.,yindex,st_macroexpand("`"+"mover"+"'"))
st_view(X,.,xindex,st_macroexpand("`"+"mover"+"'"))
st_view(id,.,iindex,st_macroexpand("`"+"mover"+"'"))
st_view(jd,.,jindex,st_macroexpand("`"+"mover"+"'"))
st_view(mover,.,movindex,st_macroexpand("`"+"sample"+"'"))
resm=select(res,mover)
stata( "qui replace "+"`"+"mover"+"' =. if "+"`"+"sample"+"' ==0")
PI=panelsetup(id,1)
for (i=1; i<=rows(PI);i++) {
xi=panelsubmatrix(X,i,PI)
ji=panelsubmatrix(jd,i,PI)
PJ=panelsetup(ji,1)
ji=uniqrows(ji)
fi=J(PJ[1,2]-PJ[1,1]+1,1,1)
for (j=2; j<=rows(PJ);j++) {
	fi=fi \ J(PJ[j,2]-PJ[j,1]+1,1,j)
	}
fi=designmatrix(fi)
fi=fi:-mean(fi,1)
xi=xi:-mean(xi,1)

for (p=1; p<=rows(PJ);p++) {    /* p which firm of the firms person i is observed in this refers to  */
for (j=PJ[p,1]; j<=PJ[p,2];j++) {   /* j counts at which observation of person i we are */
	ff=quadcross(fi[j,.],fi[j,.])*resm[PI[i,1]+j-1,1]^2
	for (l=1; l<=cols(ff);l++) {
	for (k=1; k<=rows(ff);k++) {
		C[cols(X)+ji[l],cols(X)+ji[k]]=C[cols(X)+ji[l],cols(X)+ji[k]]+ff[l,k]
		}
		}
	xf=quadcross(xi[j,.],fi[j,.])*resm[PI[i,1]+j-1,1]^2
	for (l=1; l<=rows(ji);l++) {
	C[1..rows(xf),ji[l]+cols(X)]=C[1..rows(xf),ji[l]+cols(X)]+xf[.,l]
	C[ji[l]+cols(X),1..rows(xf)]=C[ji[l]+cols(X),1..rows(xf)]+xf[.,l]'
		}
	}
	}
}
display("  End:   "+st_macroexpand("`"+"c(current_date)"+"'")+" "+st_macroexpand("`"+"c(current_time)"+"'"))
} /* End if robust option*/
/* +++++++++++++++++    END ROBUST   STANDARD ERRORS +++++++++++++++++++++++++++ */

/* -------  Take out unidentified firm effects  of C for cluster and robust standard errors  ---------------------*/
if (clust!="" | rob=="robust") {
group=.
group=st_data(.,(st_varindex(st_macroexpand("`"+"group"+"'")),jindex),st_macroexpand("`"+"sample"+"'"))
st_view(jd,.,jindex,st_macroexpand("`"+"sample"+"'"))
group=sort(group,(1,2))
GI=panelsetup(group,1)

for (j=rows(GI); j>=1;j--) {
	GI[j,1]=group[GI[j,1],2]
	}

GI=sort(GI,(1))

numj=colmax(jd)
GI[rows(GI),2]=numj

for (j=rows(GI)-1; j>=1;j--) {
	GI[j,2]=GI[j+1,1]-1
	}


for (j=1; j<=rows(GI);j++) {
      for (i=cols(X)+GI[j,1]; i<=cols(X)+GI[j,2]-1;i++) {
	C[.,i-j+1]=	C[.,i+1]
	C[i-j+1,.]=	C[i+1,.]
	}
}

C=C[1..rows(C)-rows(GI),1..cols(C)-rows(GI)]    
								
S=quadcross(A,C)
R=quadcross(S',A)

stata("timer off 25")

if (clust=="" & rob=="robust") {  /* ROBUST */
R=(obs/dof)*R
st_global("e(vcetype)","Robust")
};
if (clust!="") {  /* CLUSTER */
R=(obs-1)/dof*nocl/(nocl-1)*R
st_global("e(vcetype)","Robust")
st_global("e(clustvar)",st_macroexpand("`"+"cluster"+"'"))
if (st_macroexpand("`"+"adji"+"'")=="noadji") {
	display("    Number of effects of panels i not counted into degrees of freedom adjustment")
	display("    of the clustered covariance matrix.")

	}
if (st_macroexpand("`"+"adjj"+"'")=="noadjj") {
	display("    Number of effects of panels j not counted into degrees of freedom adjustment.")
	display("    of the clustered covariance matrix.")
	}
if (st_macroexpand("`"+"adji"+"'")!="noadji" & st_macroexpand("`"+"adjj"+"'")!="noadjj" ) {
	display("  Full degrees of freedom adjustment (equal to xtreg option -dfadj-)")
	}
}
st_matrix("V",R[1..cols(X),1..cols(X)])
if (st_macroexpand("`"+"feffse"+"'")!="") {
sefeff=sqrt(diagonal(R[cols(X)+1..cols(R),cols(X)+1..cols(R)]))
}


} /* End Cluster or Robust */
/* +++++++++++++++++    END CLUSTERED AND ROBUST   STANDARD ERRORS +++++++++++++++++++++++++++ */
/*-------------------------------------------------------------------------------------------------*/
else
{
stata("timer on 22")

A=sigmau^2*A
st_matrix("V",A[1..cols(X),1..cols(X)]')

if (st_macroexpand("`"+"feffse"+"'")!="") {
	sefeff=sqrt(diagonal(A[cols(X)+1..cols(A),cols(X)+1..cols(A)]))
	}
}
								/* KM: fill in reference teacher effects, pass out all effects*/

if (st_macroexpand("`"+"feffse"+"'")!="") {
group=uniqrows(st_data(.,(st_varindex(st_macroexpand("`"+"refftemp"+"'")),st_varindex(st_macroexpand("`"+"jtemp"+"'"))),st_macroexpand("`"+"sample"+"'")))
GG=panelsetup(group,1)
numcolsGG = GG[.,2] - GG[.,1]:+1
feffse = betatemp[cols(X)+1..rows(betatemp)]
for (j=1+havenonmover; j<=rows(GG);j++) {
	if (numcolsGG[j,1]==1) {
		refse = 0
		}
	else {
		refse = sqrt(sum(A[cols(X)+GG[j,1]-j+1..cols(X)+GG[j,2]-j,cols(X)+GG[j,1]-j+1..cols(X)+GG[j,2]-j]))
	}
	feffse[GG[j,1]] = refse
	if (numcolsGG[j,1]!=1) {
		feffse[GG[j,1]+1..GG[j,2]] = sefeff[GG[j,1]-j+1..GG[j,2]-j]
		}
	}

st_view(jd,.,(st_varindex(st_macroexpand("`"+"jtemp"+"'"))),st_macroexpand("`"+"sample"+"'"))
jdd=jd
for (j=1; j<=rows(jd);j++) {
	jdd[j]=feffse[jd[j]]
	}
st_store(.,st_addvar("float",st_macroexpand("`"+"feffse"+"'")),st_macroexpand("`"+"sample"+"'"),jdd)
}

st_matrixrowstripe("V",(J(cols(X),1," "),(st_varname(xindex)')))
st_matrixcolstripe("V",(J(cols(X),1," "),(st_varname(xindex)')))

stata("ereturn repost b=b V=V, rename")
stata("timer off 22")

}

void groups(string scalar individualid, string scalar unitid, string scalar groupvar) {

		real scalar ncells, npers, nfirm; 	/* Data size : number of distinct observations number of pupils number of schools */
		real matrix byp, byf; 			/* Dataset sorted by pupil/by school */
		real vector pg, fg, pindex, findex, ptraced, ftraced, ponstack, fonstack;
	
		/***** Stack for tracing elements */
		real vector m;				/* Stack of pupils/schools */
		real scalar mpoint;			/* Number of elements on the stack */
	
		real scalar nptraced, nftraced;	// Number of traced elements
		real scalar lasttenp, lasttenf;
		real scalar nextfirm;

		real vector mtype; 	/* Type of the element on top of the stack */
					 	/* Convention : 					 */
					 	/* 1 for a pupil					 */
					 	/* 2 for a school					 */
	
		real scalar g;	/* Current group */
	
		real scalar j;
	
		real matrix data;		/* A data view used to add group information after the algorithm completed */
	
		printf("Grouping algorithm for CG\n");
	
		/****** Core data : cells sorted by person/by firm */

		byp = st_data(., (individualid, unitid));
		printf("Sorting data by pupil id\n");
		byp = sort(byp,1);
	
		byf = st_data(., (individualid, unitid));
		printf("Sorting data by school id\n");
		byf = sort(byf,2);
		
		/****** Data size */
	
		ncells = rows(byf);		/* Number of distinct observations (duplicates drop has to be done beforehand) */
		npers  = byp[ncells,1];		/* Number of pupils										 */
		nfirm  = byf[ncells,2];		/* Number of schools										 */

		printf("Data size : %9.0g cells, %9.0g pupils, %9.0g firms\n", ncells, npers, nfirm);
	
		/****** Initializing the stack and p/ftraced */

		printf("Initializing the stack\n");
	
		ptraced  = J(npers, 1, 0);	// No pupil has been traced yet
		ftraced  = J(nfirm, 1, 0);	// No school has been traced yet

		ponstack = J(npers, 1, 0);	// No pupil has been on the stack yet
		fonstack = J(nfirm, 1, 0);	// No school has been on the stack yet
	
		m 	= J(npers+nfirm, 1, 0); // Empty stack
		mtype = J(npers+nfirm, 1, 0);	// Unknown type of the element on top of the stack
	
		printf("Initializing pg,fg\n");
	
		pg	= J(npers, 1, 0);
		fg	= J(nfirm, 1, 0);
	
		/****** Initializing pindex, findex */
	
		printf("Initializing the index arrays\n");
	
		pindex = J(npers, 1, 0);
		findex = J(nfirm, 1, 0);
	
		for ( j = 1 ; j <= ncells ; j++) {
			pindex[byp[j,1]] = j;
			findex[byf[j,2]] = j;
		}
	
		g = 1;   	// The first group is group 1
		
		check_data(byp, byf, ncells);
	
		/***** Puts the first firm in the stack */
	
		printf("Putting first school on the stack\n");
		nextfirm = 1;
		mpoint = 1;
		m[mpoint] = 1;
		mtype[mpoint] = 2;
		fonstack[1] = 1;
	
		printf("Starting to trace the stack\n");
		
		nptraced = 0;
		nftraced = 0;
		lasttenp = 0;
		lasttenf = 0;

		while (mpoint > 0) {
	
			if (trunc((nptraced/npers)*100.0) > lasttenp || trunc((nftraced/nfirm)*100.0) > lasttenf) {
				lasttenp = trunc((nptraced/npers)*100.0);
				lasttenf = trunc((nftraced/nfirm)*100.0);
	
				printf("Progress : %9.0g pct pupils traced, %9.0g pct firms traced\n",lasttenp,lasttenf);
			}
	
			if (g > 1) {
				printf("%9.0g\t", g);
			}
			trace_stack( byp, byf, pg, fg, m, mpoint, mtype, ponstack, fonstack, ptraced, ftraced, pindex,  findex,g, nptraced, nftraced);
			if (mpoint == 0) {
				g = g + 1;
				while (nextfirm < nfirm && fg[nextfirm] != 0) {
					nextfirm = nextfirm + 1;
				}
				if (fg[nextfirm] == 0) {
					mpoint = 1;
					m[mpoint] = nextfirm;
					mtype[mpoint] = 2;
					fonstack[nextfirm] = 1;
				}
			}
		}
	
		printf("Finished processing, adding group data\n");
	
		st_addvar("long", groupvar);
	
		st_view(data, . ,(individualid, unitid,groupvar));
	
		for (j = 1 ; j<=ncells; j++ ) {
			data[j,3] = pg[data[j,1]];
			if (pg[data[j,1]] != fg[data[j,2]]) {
				printf("Error in the output data.\n");
				printf("Observation %9.0g, Pupil %9.0g, School %9.0g, Group of pupil %9.0g, Group of school %j\n",
						j, data[j,1], data[j,2], pg[data[j,1]], fg[data[j,2]]);
				exit(1);
			}
		}
	
		printf("Finished adding groups.\n");
	
	}

	/*

	Name:			check_data()
	
	Purpose:	This function checks whether data is correctly sequenced.
	
	 */
	
	function check_data(real matrix byp, real matrix byf, real scalar ncells) {
		
		real scalar thispers, thisfirm;
	
		real scalar i;
	
		thispers = 1;
		thisfirm = 1;
	
		for ( i=1 ; i <= ncells ; i++ ) {
			if ( byp[i,1] != thispers ) {
				if ( byp[i,1] != thispers+1 ) {
					printf("Error : by pupil file not correctly sorted or missing sequence number\n");
					printf("Previous person : %9.0g , This person : %9.0g , Index in file %9.0g\n", thispers, byp[i,1], i);
					exit(1);
				}
				thispers = thispers + 1 ;
			}
	

			if ( byf[i,2] != thisfirm ) {
				if ( byf[i,2] != thisfirm + 1 ) {
					printf("Error : by school file not correctly sorted or missing sequence number\n");
					printf("Previous school : %9.0g , This school : %9.0g , Index in file %9.0g\n", thisfirm, byf[i,2], i);
					exit(1);
				}
				thisfirm = thisfirm + 1;
			}
		
		}
	
		printf("Data checked - By pupil and by school files correctly sorted and sequenced\n");
	}

	/*
	
	Name: 	trace_stack()
	
	Purpose:	Builds the connex component of the graph of the elements on the stack

	 */

	void trace_stack( real matrix byp, real matrix byf, real vector pg,  real vector fg, 
				real vector m, real scalar mpoint, real vector mtype,
				real vector ponstack, real vector fonstack,
				real vector ptraced,  real vector ftraced,
				real vector pindex,   real vector findex,
				real scalar g, real scalar nptraced, real scalar nftraced) {
	
		real scalar thispers, thisfirm, person, afirm, lower, upper;
	
		if (mtype[mpoint] == 2) { // the element on top of the stack is a firm
			thisfirm = m[mpoint];
			mpoint = mpoint - 1;
			fg[thisfirm] = g;
			ftraced[thisfirm] = 1;
			fonstack[thisfirm] = 0;
			if (thisfirm == 1) {
				lower = 1;
			} else {
				lower =  findex[thisfirm - 1] + 1;
			}
			upper = findex[thisfirm];
			for (person = lower ; person <= upper ; person ++) {
				thispers = byf[person, 1];
				pg[thispers] = g;
				if (ptraced[thispers] == 0 && ponstack[thispers] == 0) {
					nptraced = nptraced + 1;
					mpoint = mpoint + 1;
					m[mpoint] = thispers;
					mtype[mpoint] = 1;
					ponstack[thispers] = 1;
				}
			}
		} else if (mtype[mpoint] == 1) { // the element on top of the stack is a person
			//printf("A person\t");
			thispers = m[mpoint];
			mpoint = mpoint - 1;
			pg[thispers] = g;
			ptraced[thispers] = 1;
			ponstack[thispers] = 0;
			if (thispers == 1) {
				lower = 1;
			} else {
				lower = pindex[thispers - 1] +1;
			}
			upper = pindex[thispers];
			for (afirm = lower; afirm <= upper; afirm++) {
				thisfirm = byp[afirm, 2];
				fg[thisfirm] = g;
				if (ftraced[thisfirm] == 0 && fonstack[thisfirm] == 0) {
					nftraced = nftraced + 1;
					mpoint = mpoint + 1;
					m[mpoint] = thisfirm;
					mtype[mpoint] = 2;
					fonstack[thisfirm] = 1;
				}
			}
		} else {
			printf("Incorrect type, element number %9.0g of the stack, type %9.0g\n",mpoint,mtype[mpoint]);
		}
	
	}

void save1(string scalar var)
{
stata("sort "+"`"+"n"+"'")
M=st_data(.,var)
stata("restore")
st_store(.,var,st_varindex(st_macroexpand("`"+"sample"+"'")),M)
}

end
