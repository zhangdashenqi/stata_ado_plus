*!version 2011-Feb-17, Qunyong Wang
program hacreg, eclass byable(recall) sortpreserve
version 11.0
if !replay() {
	syntax varlist(ts fv) [if] [in] [, noConstant Level(real 95) * ] 

	marksample touse
	// extract names of independent
	gettoken yname xnamea: varlist
	fvrevar `yname' if `touse'
	local y "`r(varlist)'"
	fvexpand `xnamea' if `touse'
	local vnames "`r(varlist)'"
	fvrevar `xnamea' if `touse'
	local vs "`r(varlist)'"
	qui _rmcoll `vs' , `constant' expand
	local vs2 "`r(varlist)'"
	local i=1
	foreach v of local vs2 {
		if !strmatch("`v'","*o.*") {
			local pos "`pos' 0"
			local vn: word `i' of `vnames'
			local xnames "`xnames' `vn'"
			local vx: word `i' of `vs'
			local xs "`xs' `vx'"
		}
		else {
			local pos "`pos' 1"
		}
		local i=`i'+1
	}
 	local k: word count `xs' // not include constant
	tempname b lrcov xx xinv hac b0 Fstat hac0
	qui reg `y' `xs' if `touse', `constant'
	*qui est store `ols'
	matrix `b'=e(b)
	if "`constant'"!="" local c=colsof(`b')
	else local c=colsof(`b')-1
	matrix `b0'=`b'[1,1..`c']
	tempvar res
	qui predict `res' if e(sample), residual 
	// extract all scalars in e()
	local scas: e(scalars)
	foreach s of local scas {
		local `s'=e(`s')
	}
	
	if "`constant'"!="" {  // no constant in reg & lrcov
		local df_m = `N'-`df_r'
		qui lrcov `xs' if `touse', nocenter wvar(`res') dof(`df_m') `options'
	}
	else {  // constant in model & lrcov
		local df_m = `N'-`df_r'-1
		qui lrcov `xs' if `touse', nocenter constant wvar(`res') dof(`=`df_m'+1') `options'
	}
	matrix `lrcov'=r(Omega)
	qui matrix accum `xx'=`xs' if `touse', `constant'
	matrix `xinv'=inv(`xx')
	matrix `hac'=`N'*`xinv'*`lrcov'*`xinv'
	mksym `hac'
	matrix `hac0'=`b0'*invsym(`hac'[1..`c', 1..`c'])*`b0''/`k'
	scalar `Fstat' = el(`hac0',1,1)

	// save results
	if "`constant'"=="" {
		local xnames "`xnames' _cons"
	}
	*qui est restore `ols'
	matrix rownames `b'=`yname'
	matrix colnames `b'=`xnames'
	matrix rownames `hac'=`xnames'
	matrix colnames `hac'=`xnames'
	ereturn post `b' `hac' , esample(`touse') dep(`yname') 
	// store all scalars into e()
	foreach s of local scas {
		ereturn scalar `s' = ``s''
	}
	ereturn scalar F = `Fstat'
	ereturn local title "Regression with HAC standard errors"
	ereturn local vcetype "HAC"
	ereturn local predict "regres_p"
	ereturn local cmdline `"hacreg `0'"'
	ereturn local cmd "hacreg"

}
else {
	if "`e(cmd)'"!="hacreg" error 301
	syntax [, Level(real 95) ]
}
dis ""
dis in gr %12s "Source" _col(14) "{c |}" _col(20) "SS" _col(30) "df" _col(40) "MS" /// 
	in gr _col(49) in gr "Number of obs" _col(67) "=" ///
		_col(70) in ye %9.0f e(N)
dis in gr _dup(13) "{c -}" _col(14) "{c +}" _dup(30) "{c -}" ///
	_col(49) in gr "F(" in ye e(df_m) in gr ", " in ye e(df_r) in gr ")" ///
	_col(67) "=" _col(70) in ye %9.0g e(F) 
dis in gr %12s "Model" _col(14) "{c |}" in ye %12.0g e(mss) %6.0g e(df_m)  %12.4f `=`e(mss)'/`e(df_m)'' ///
	_col(49) in gr "Prob > F" _col(67) "=" ///
	_col(73) in ye %6.4f `=Ftail(e(df_m), e(df_r),e(F))' 
dis in gr %12s "Residual" _col(14) "{c |}" in ye %12.0g e(rss) %6.0g e(df_r) %12.4f `=e(rss)/e(df_r)' ///
	_col(49) in gr "R-square" _col(67) "=" ///
	_col(70) in ye %9.0g e(r2)  
dis in gr _dup(13) "{c -}" "{c +}" _dup(30) "{c -}" ///
	_col(49) in gr "Adjusted R2" _col(67) "=" ///
	_col(70) in ye %9.0g e(r2_a) 
dis in gr %12s "Total" _col(14) "{c |}" %12.0g in ye `=e(rss)+e(mss)' %6.0g `=e(N)-1' %12.0g `=(e(rss)+e(mss))/(e(N)-1)' ///
	_col(49) in gr "Standard error" _col(67) "=" ///
	_col(70) in ye %9.0g e(rmse) _n
_coef_table, level(`level')
end

program mksym
syntax namelist
	tempname b
	foreach mat of local namelist {
		mata: `b'=st_matrix("`mat'")
		mata: _makesymmetric(`b')
		mata: st_matrix("`mat'", `b')
	}
end
