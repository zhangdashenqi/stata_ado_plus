*! v 1.0.2 PR 12jan2009
program define pmbeval
version 8
syntax [if] [in], Xvar(str) [ CLEAR Rawdata(string) Freq(numlist) INClusions Values(numlist) ///
 SAVing(string) STandardize * ]
if "`inclusions'"!="" & `"`saving'"'=="" {
	di as err "option inclusions requires using <filename>"
	exit 198
}
if `"`saving'"' == "" & "`clear'" == "" {
	di as err "option clear or saving() required"
	exit 198
}
// Check if options for pmbextract are valid
pmbextract, `options'
if "`rawdata'"!="" { // `rawdata' is a dta-file holding raw data
	if substr("`rawdata'", -4, .)!=".dta" {
		local rawdata `rawdata'.dta
	}
	if "`values'`freq'"!="" {
		di as err "invalid `values' `freq', using file `rawdata'"
		exit 198
	}
	preserve
	use `"`rawdata'"', replace
	pmbload `xvar'
	local values `r(values)'
	local freq `r(freq)'
	restore
}
else {
	if "`values'"=="" {
		di as err "values() or rawdata() required"
		exit 198
	}
}
/*
	Check for requisite variables (powers and betas).
*/
local done 0
local np 0
while !`done' {
	local i=`np'+1
	cap confirm var `xvar'p`i'
	if _rc!=0 {
		local done 1
	}
	else {
		local np `i'
		local pwrs `pwrs' `xvar'p`np'
		local coef `coef' `xvar'b`np'
		if `i'==1 {
			local shift: char `xvar'p1[shift]
			if "`shift'"=="" {
				local shift 0
			}
			local scale: char `xvar'p1[scale]
			if "`scale'"=="" {
				local scale 1
			}
			local adjust:char `xvar'p1[adjust]
		}
	}
}
if `np'==0 {
	di as err "no powers or coefficients found for `xvar'"
	exit 2001
}
local stuff `pwrs' `coef'
cap confirm var b0
if _rc==0 {
	local b0 b0
	local stuff `stuff' `b0'
}
if "`inclusions'"!="" {
	* create inclusion indicators
	local includ
	local vl: char _dta[pmb_vl]
	tokenize `vl'
	while "`1'"!="" {
		qui gen byte `1'i=(`1'p1!=.)
		lab var `1'i "`1': 1=in, 0=out"
		local includ `includ' `1'i
		mac shift
	}
}
/*
	Check integrity of values and freq
*/
local nv: word count `values'
if "`freq'"!="" {
	local nf: word count `freq'
	if `nf'!=`nv' {
		di as err "number of values() and freq() differ"
		exit 198
	}
}
marksample touse
preserve
quietly {
	keep if `touse'
	keep `stuff' `includ'
	if "`standardize'"!="" {
		tempvar wsum		/* weighted sum of fitted values */
		tempname fsum
		gen double `wsum'=0
		scalar `fsum'=0
	}
	forvalues i = 1 / `nv' {
		local v: word `i' of `values'
		if "`freq'" != "" {
			local f: word `i' of `freq'
		}
		else local f 1
		gen double `xvar'`i' = `v'
		fraceval var `xvar'`i' "`pwrs'" "`coef'" "`b0'" "`adjust'" "`shift'" "`scale'"
		local fp `r(fpvar)'
		if "`standardize'" != "" {
			replace `wsum' = `wsum' + `f'*`fp'
			scalar `fsum' = `fsum' + `f'
		}
		replace `xvar'`i' = `fp'
	}
	if "`standardize'" != "" {
		replace `wsum' = `wsum' / `fsum'
		forvalues i = 1 / `nv' {
			replace `xvar'`i' = `xvar'`i' - `wsum'
		}
		drop `wsum'
	}
	drop `stuff' `fp'
	char _dta[pmb_fn] `rawdata'
	char _dta[pmb_v] `values'
	char _dta[pmb_f] `freq'
	char _dta[pmb_x] `xvar'
}
if `"`saving'"'=="" {
	* extract data for plotting and other purposes
	pmbextract, clear `options'
	restore, not
}
else {
	save `"`saving'"', replace
	qui count
	di _n as res `nv' as text " variables and " as res r(N) ///
	 as text " observations based on " as res "`xvar'" ///
	 as text " saved to file " as res "`saving'" as text "."
}
end
