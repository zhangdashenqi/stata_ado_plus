capture program drop shapley2
*!version 1.1 23aug2013 -  F. Wendelspiess Chavez Juarez
program define shapley2 , eclass 
version 9.2
syntax [anything] , stat(str) [Command(str) Indepvars(str) Depvars(str) GRoup(str) MEMory FORCE Noisily]
qui{
tempfile orgdb
save `orgdb'
keep if e(sample)
tempfile usedb
save `usedb'
est store myreg
local full=e(`stat')


//tokenize `cmd'


if("`command'"==""){
	local command=e(cmd)
	}
if("`depvar'"==""){
	local depvar=e(depvar)
	}
if("`indepvars'"==""){
	local indepvarstemp:colnames e(b)		// load indepvars
	
	// control if all is ok (this eliminates some additional columns like _cons
	local indepvars=""
	foreach var of local indepvarstemp{
		capture confirm variable `var'
			if(_rc==0){
				local indepvars="`indepvars' `var'"	
			}
		}
	}
if("`group'"!=""){ // this is the algorithm for the group specific shapley value
	gl stop=0
	local g=1
	tokenize "`group'", parse(",")
	while($stop==0){
		local group`g'=trim("`1'")
		macro shift
		if("`1'"==","){ // ANOTHER "," more groups are expected
			local g=`g'+1
			macro shift
		} //end if
		else{
			gl stop=1
		} // end else
	} // end while
	
	if(`g'<=12 & c(version)<12){ // for stata version <12, adapt matsize 
		local newmatsize=max(2^`g'+200,c(matsize))
		capture set matsize `newmatsize'
		}
	if(`g'>12){
		local runs=2^`K'
		noisily di as error "Too many groups defined (`runs' needed)"
		noisily di as error "A maximum of 12 groups is allowed"
		exit
	}
	
	preserve
			drop _all
			set obs 2
			forvalues j=1/`g'{
				gen _group`j'=1 in 1/1
				replace _group`j'=0 in 2/2
				}
			fillin _group*
			
			local allvars=""
			forvalues j=1/`g'{
				foreach var of local group`j'{
					gen `var'=_group`j'
					local allvars="`allvars' `var'"
				}
			}
			
			drop _fillin
			gen result=.
			mkmat * , matrix(combinations) 
			matrix list combinations
			restore
	

		local numcomb=rowsof(combinations)
		local numcols=colsof(combinations)

		
		matrix combinations[1,`numcols']=0
			
		forvalues i=2/`numcomb'{
		local thisvars=""
			foreach var of local allvars{
				
				matrix mymat=combinations[`i',"`var'"]
				local test=mymat[1,1]
				
				if(`test'==1){
					
					local thisvars="`thisvars' `var'"
					
					}
				}
			//di "`thisvars'"
			
			
			`noisily' `command' `depvar' `thisvars'
			matrix combinations[`i',`numcols']=e(`stat')
			
		}
		matrix list combinations
		preserve
		drop _all
		matrix list combinations
		svmat combinations,names(col) 


}
else{ // no group variable, hence use all indepvars individually
local K=wordcount("`indepvars'")

if(`K'>20 & "`force'"==""){
	local runs=2^`K'
	noisily di as error "Too many independent variables (`runs' needed)"
	noisily di as error "If you really want to proceed, use the option 'force'"
	exit
	}
if(`K'<=12 & c(version)<12){
	local newmatsize=max(2^`K'+200,c(matsize))
	capture set matsize `newmatsize'
	
}

if(2^`K'<=c(matsize)){

		preserve
			drop _all
			set obs 2

			foreach var of local indepvars {
				gen `var'=1 in 1/1
				replace `var'=0 in 2/2
				}
				
			fillin `indepvars'
			drop _fillin
			gen result=.
			mkmat `indepvars' result , matrix(combinations) 
			matrix list combinations
		restore

		local numcomb=rowsof(combinations)
		local numcols=colsof(combinations)

		//di as error "I have to perform `numcomb' regressions"
		matrix combinations[1,`numcols']=0
		forvalues i=2/`numcomb'{
		local thisvars=""
			foreach var of local indepvars{
				matrix mymat=combinations[`i',"`var'"]
				local test=mymat[1,1]
				
				if(`test'==1){
					local thisvars="`thisvars' `var'"
					}
				}
			//di "`thisvars'"
			`noisily' `command' `depvar' `thisvars'
			matrix combinations[`i',`numcols']=e(`stat')
			
		}
		preserve
		drop _all
		matrix list combinations
		svmat combinations,names(col) 
}
else{ // if the matsize is to big

	if("`mem'"=="mem"){
		clear
		capture set mem 5000m
		while(_rc!=0){
		capture set mem `i'm
		local i=round((`i')*0.9)
		}
		use `usedb'
		}


	di as error "Slow algorithm chosen. Try to increase matsize to enable the faster algorithm"
	drop _all
	set obs 2

	foreach var of local indepvars {
		gen `var'=1 in 1/1
		replace `var'=0 in 2/2
		}
	compress	
	fillin `indepvars'
	drop _fillin
	gen result=.
	
	
	
	local numcomb=_N
	
	di "`numcomb' combinations!"
	qui:replace result=0 in 1/1
	forvalues i=2/`numcomb'{
		local thisvars=""
			foreach var of local indepvars{
				local test=`var' in `i'/`i'
					if(`test'==1){
						local thisvars="`thisvars' `var'"
					}
		}
	
	//di "`thisvars'"
	preserve
	use `usedb', clear
	di "`command' `depvar' `thisvars'"
	qui: `command' `depvar' `thisvars'
	restore
	
	qui: replace result=e(`stat') in `i'/`i'
	
}


}
}

/* Start computing the shapley value*/
if("`group'"!=""){
	reg result _group*
	matrix shapley=e(b)
	matrix shapley=shapley[1,1..`g']
	matrix shapley_rel=shapley/`full'
} // end if group
else{
reg result `indepvars'
	matrix shapley=e(b)
	matrix shapley=shapley[1,1..`K']
	matrix shapley_rel=shapley/`full'
}
//matrix result=(shapley\shapley_rel)'

// GENERATE THE NORMALIZED VERSION

local cols=colsof(shapley)

local sum=0
forvalues i=1/`cols'{
	local sum=`sum'+shapley[1,`i']
	}
	local residual=`full'-`sum'
matrix define shapley_norm=(`full'/`sum')*shapley
matrix define shapley_rel_norm=(`full'/`sum')*shapley_rel

matrix result=(shapley\shapley_rel\shapley_norm\shapley_rel_norm)







restore
use `orgdb', clear
est restore myreg
est drop myreg
ereturn matrix shapley shapley

ereturn matrix shapley_rel shapley_rel

ereturn matrix shapley_norm shapley_norm
ereturn matrix shapley_rel_norm shapley_rel_norm
} // end quietly



// START OUTPUT
//di as text  "---------1---------2---------3---------4---------5---------6---------7---------8---------9---------10--------+"
di as text "Factor" _col(12) "{c |}" " Shapley value " _col(23) "{c |}  Per cent " _col(40) "{c |} Shapley value" _col(45) "{c |}   Per cent  "
di as text  _col(12) "{c |}" "  (estimate)   " _col(23) "{c |} (estimate)" _col(40) "{c |} (normalized) " _col(45) "{c |} (normalized)"
di as text "{hline 11}{c +}{hline 15}{c +}{hline 11}{c +}{hline 14}{c +}{hline 13}"
local i=0
if("`group'"!=""){
	forvalues j=1/`g'{
	local i=`i'+1
	local varname="Group `j'" //abbrev("`group`j''",10)
	di as text "`varname'" _col(12) "{c |}" as result %6.5f _col(15) el(result,1,`i') as text _col(28) "{c |}" _col(31) as result %6.2f 100*el(result,2,`i') as text " %" ///
	_col(40) "{c |}" as result %6.5f _col(42) el(result,3,`i') as text _col(55) "{c |}" _col(57) as result %6.2f 100*el(result,4,`i') as text " %"
	}
}
else{
	foreach var of local indepvars{
		local i=`i'+1
		local varname=abbrev("`var'",10)
		di as text "`varname'" _col(12) "{c |}" as result %6.5f _col(15) el(result,1,`i') as text _col(28) "{c |}" _col(31) as result %6.2f 100*el(result,2,`i') as text " %" ///
		_col(40) "{c |}" as result %6.5f _col(42) el(result,3,`i') as text _col(55) "{c |}" _col(57) as result %6.2f 100*el(result,4,`i') as text " %"
	}
	}
di as text "{hline 11}{c +}{hline 15}{c +}{hline 11}{c +}{hline 14}{c +}{hline 13}"
di as text "Residual" _col(12) "{c |}" as result %6.5f _col(15) `full'-`sum' as text _col(28) "{c |}" _col(31) as result %6.2f 100*(1-`sum'/`full') as text " %" _col(40) "{c |}" _col(55) "{c |}"
di as text "{hline 11}{c +}{hline 15}{c +}{hline 11}{c +}{hline 14}{c +}{hline 13}"
di as text "TOTAL" _col(12) "{c |}" as result %6.5f _col(15) `full' as text _col(28) "{c |}" _col(31) as result %6.2f 100 as text " %" ///
				   _col(40) "{c |}" as result %6.5f _col(42) `full' as text _col(55) "{c |}" _col(57) as result %6.2f 100 as text " %"
di as text "{hline 11}{c +}{hline 15}{c +}{hline 11}{c +}{hline 14}{c +}{hline 13}"
if("`group'"!=""){ //display the groups
di as text "Groups are:"
forvalues j=1/`g'{
	di as text "Group `j':" _col(10) as result "`group`j''"
}
}

end

********************
*!
*!--------------------- VERSION HISTORY -------------------
*! Version 1.1: Bugfix to ensure no changes are made to the current database. 
*! Version 1.0: First release on 06nov2012


