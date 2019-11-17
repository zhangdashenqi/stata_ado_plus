*! 2.1.0 11 Oct 2004 Dan Blanchette 
*! 2.0.0 12Aug2004 by Dan Blanchette  -- svymlogit allowed
*! 1.0.1 03/25/93  by Bill Rogers              sqv10: STB-23
program mcross
	version 8  

	// anything to use? 
	if !index("`e(cmd)'","mlogit") error 301 

	// syntax processing 
	syntax [, Level(integer `c(level)') Rrr ] 
	if `level' < 10 local level 10
	if `level' > 99 local level 99 
	local lc = invnorm(.50 + `level'/200)
	
	local coef "Coef."
	if "`rrr'" != "" {
		local rrr "eform(rrr)"
		local coef "  RRR"
	}
	
	// pick up results 
	tempname b v vv1 vv2 vvx b1 b2 bg vg 
	mat `b' = e(b)
	mat `v' = e(V)
	local dv = abbrev("`e(depvar)'",12) 
	local namelist "`e(eqnames)'" 
	local numeq : word count `namelist' 
	local names : coleq(`v')
	tokenize "`: colnames(`b')'" 
	
	// header 
	di _n as txt "{hline 13}{c TT}{hline 64}"
	local l = 12 - length("`dv'")
	di as txt "{space `l'}`dv' {c |}     `coef'  " ///
	"Std. Err.        z    P>|z|     [`level'% Conf. Interval]"

	// loop over pairs of equations 
	capture forval i = 1/`=`numeq' -1' {
		// first in pair 
		local name1 : word `i' of `namelist'
		mat `b1' = `b'[1,"`name1':"] 
		mat `vv1' = `v'["`name1':","`name1':"]
		
		forval j = `=`i' + 1'/`numeq' {
			// second in pair 
			local name2 : word `j' of `namelist'
			mat `b2' = `b'[1,"`name2':"]
			mat `vv2' = `v'["`name2':","`name2':"]
			
			// variance of contrast 
			mat `vvx' = `v'["`name1':","`name2':"]
			mat `bg' = `b2' - `b1'
			mat `vv2' = `vv2' - `vvx'
			mat `vg' = `vv2' + `vv1' - (`vvx')' 

			// show which pair 
			noi di as txt "{hline 13}{c +}{hline 64}"
			local ncomp = substr("`name2'-`name1'",1,12)
			local l = 12 - length("`ncomp'") 
			noi di as res "`ncomp'{space `l'} " as txt "{c |}"

			// show results for each predictor 
			noi forval k = 1/`= colsof(`bg')' {
				local nnn = abbrev("``k''", 14)
				local l = 12 - length("`nnn'")

				local c = `bg'[1,`k']
				local s = sqrt(`vg'[`k',`k'])
				
				if "`rrr'" == "" {
					di "{space `l'}" as txt "`nnn' {c |} " ///
					as res %9.0g `c' "  " ///
					as res %9.0g `s'      ///
					as res %10.2f `c'/`s' ///
					as res %8.3f 2 * normprob(-abs(`c'/`s')) /// 
					as res "      " %8.0g `c' - `lc' * `s' ///
					as res "   " %8.0g `c' + `lc' * `s'
				}
				else if "`nnn'" != "_cons" {
					di "{space `l'}" as txt "`nnn' {c |} " ///
					as res %9.0g exp(`c') "  " /// 
					as res %9.0g exp(`c') * `s' ///
					as res %10.2f `c'/`s' ///
					as res %8.3f 2 * normprob(-abs(`c'/`s')) ///
					as res "      " %8.0g exp(`c' - `lc' * `s') ///
					as res "   " %8.0g exp(`c' + `lc' * `s')
				}
			} // loop k 
		} // loop j 
	} // loop i  

	/// show final line if OK 
	local rc = _rc
	if !`rc' di as txt "{hline 13}{c BT}{hline 64}"
	error `rc'
end

/*

var (b1 - b2) = E(b1-b2)(b1-b2)' = E b1 b1' - b1 b2' - b2 b1' + b2 b2'

*/
