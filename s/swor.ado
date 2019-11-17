*! 1.1.0 NJC 21 Dec 2004       (SJ 5-1: dm86_1)                    
*! 1.0.0 NJC 3 Nov 2000          (STB-59: dm86)
program swor, sort 
	version 8 
	local 0 `"=`0'"'
	syntax =/exp [if] [in] [, BY(varlist) Keep Generate(str) ]

	tempvar nobs random 
	marksample touse 
	qui count if `touse'
	local N = r(N)
	if `N' == 0 { 
		di as err "no observations to sample"
		exit 2000 
	} 	

	local exp = trim("`exp'")
	confirm integer number `exp'
	if `exp' < 0 { 
		di as err "# in sample must be at least 1" 
		exit 198 
	}
	else if `exp' > `N' { 
		di as err "`exp' exceeds number of pertinent observations `N'" 
		exit 198 
	} 	

	if "`keep'" != "" & "`generate'" == "" { 
		di as err "generate() required with keep" 
		exit 198 
	} 
	
	if "`generate'" != "" confirm new variable `generate'
	else tempvar generate  

	if "`by'" != "" { 
		if "`in'" != "" {
			di as err "in may not be combined with by"
			exit 190
		}
		sort `touse' `by', stable 
		qui by `touse' `by' : gen long `nobs' = _N if `touse' 
		su `nobs', meanonly 
		if `exp' > `r(min)' { 
			di as err "`exp' exceeds smallest group size `r(min)'"
			exit 198 
		} 	
	}
	
	if _caller() < 4.0 {
		gen float `random' = uniform0()
	}
	else	gen float `random' = uniform()
	
	sort `touse' `by' `random', stable 
	qui by `touse' `by' : gen byte `generate' = (_n <= `exp') * `touse' 

	if "`keep'" == "" drop if `generate' == 0 & `touse' 
end
