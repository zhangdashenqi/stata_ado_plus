*! v 2.1.0 PR 14apr2008.
program define fraceval, rclass
	version 10.0
	args t X pwrs betas beta0 adjust sh sc	/* t=var | num */
	if "`9'"!="" {
		mac shift 6
		di as err "invalid `*'"
		exit 198
	}
	* Form of command: 1=FP stuff stored by fracpoly in e(), 0=get FP info from user input
	local stored=("`pwrs'"=="")
	if `stored' {
		if "`e(cmd)'" == "" | "`e(fp_cmd2)'" != "fracpoly" error 301
		if "`betas'`beta0'`adjust'`sh'`sc'"!="" {
			di as err "invalid first form of command"
			exit 198
		}
	}
	else {
		if "`adjust'"!="" 	confirm num `adjust'
		if "`sh'"!="" 		confirm num `sh'
		if "`sc'"!=""		confirm num `sc'
	}
	if "`t'"!="var" & "`t'"!="num" {
		di as err "invalid `t'"
		exit 198
	}
	if "`t'"=="var" {
		confirm var `X'
		tempvar x
		qui gen double `x'=`X'
		local gen qui gen double
		local replace qui replace
		local temp tempvar
	}
	else {
		tempname x
		cap scalar `x'=`X'
		if _rc {
			di as err "invalid " `X'
			exit 198
		}
		local gen scalar
		local replace scalar
		local temp tempname
	}
	tempname shift scale expx
	scalar `expx'=.
	if `stored' {
/*
	Get stored FP quantities. Calculate mean of X.
*/
		local np: word count `e(fp_xp)'
		tempname b0
		cap scalar `b0'=_b[_cons]
		if _rc scalar `b0'=0
		scalar `shift'=e(fp_shft)
		scalar `scale'=e(fp_sfac)
		if "`e(fp_xpx)'"!="" scalar `expx'=`e(fp_xpx)'
		// Check for adjust() option in cmdline
		local 0 `"`e(cmdline)'"'
		syntax [anything] [if] [in] [fweight  aweight  pweight  iweight] [, ADjust(string) *]
		if "`adjust'"=="no" local adjust ""
		else if "`adjust'"=="mean" | "`adjust'"=="" {
			// compute mean of original x in estimation sample
			qui sum `e(fp_x1)' if e(sample)
			local adjust = r(mean)
		}
	}
	else {
/*
	Quantities are in `pwrs', `beta0' and `betas'
*/
		local np: word count `pwrs'
		local nb: word count `betas'
		if `np'!=`nb' {
			di as err "numbers of powers and betas differ"
			exit 198
		}
		if "`beta0'"!="" {
			cap confirm num `beta0'
			if _rc==0 | (_rc>0 & "`beta0'"==".") {
				tempname b0
				scalar `b0'=`beta0'
			}
			else {
				confirm var `beta0'
				local b0 `beta0'
			}
		}
		else {
			tempname b0
			scalar `b0'=0
		}
		if "`sh'"=="" scalar `shift'=0
		else scalar `shift'=`sh'
		if "`sc'"=="" scalar `scale'=1
		else scalar `scale'=`sc'
	}
	forvalues i=1/`np' {
		if `stored' {
			tempname p`i' b`i'
			local w: word `i' of `e(fp_k1)'
			scalar `p`i''=`w'
			local w: word `i' of `e(fp_xp)'
			scalar `b`i''=_b[`w']
		}
		else {
			local w: word `i' of `pwrs'
			cap confirm num `w'
			if _rc==0 | (_rc>0 & "`w'"==".") {
				tempname p`i'
				scalar `p`i''=`w'
			}
			else {
				confirm var `w'
				if "`t'"!="var" {
					di as err "`w' invalid---" /*
					 */ "`w' is a var, `X' is a number"
					exit 198
				}
				local p`i' `w'
			}
			local w: word `i' of `betas'
			cap confirm num `w'
			if _rc==0 | (_rc>0 & "`w'"==".") {
				tempname b`i'
				scalar `b`i''=`w'
			}
			else {
				confirm var `w'
				if "`t'"!="var" {
					di as err "`w' invalid---" /*
					 */ "`w' is a var, `X' is a number"
					exit 198
				}
				local b`i' `w'
			}
		}
	}
/*
	Compute FP function.
*/
	tempname small
	`temp' fp h hlast lnx plast
	scalar `small'=1e-6
	`replace' `x'=(`x'+`shift')/`scale'
	if `expx'!=. `replace' `x'=exp(`expx'*`x')
	`gen' `lnx'=log(`x')
	`gen' `h'=.
	`gen' `hlast'=1
	`gen' `plast'=0
	if "`adjust'"!="" {
		tempname adj
		scalar `adj'=(`adjust'+`shift')/`scale'
		if `expx'!=. scalar `adj'=exp(`expx'*`adj')
		`temp' a alast lna
		`gen' `lna'=log(`adj')
		`gen' `a'=.
		`gen' `alast'=1
	}
	else {
		tempname a
		scalar `a'=0
	}
	forvalues j=1/`np' {
		if "`replace'"=="replace" local ifpj if `p`j''!=.
		`replace' `h'=cond(abs(`p`j''-`plast')<`small',`lnx'*`hlast', /*
		 */     cond(abs(`p`j'')<`small', `lnx', /*
		 */     cond(abs(`p`j''-1)<`small', `x', /*
		 */     cond(`x'==0, 0, `x'^`p`j'') ))) `ifpj'
		if "`adjust'"!="" {
			`replace' `a'=cond(abs(`p`j''-`plast')<`small', /*
			 */ `lna'*`alast', /*
			 */ cond(abs(`p`j'')<`small', `lna', /*
			 */ cond(abs(`p`j''-1)<`small', `adj', /*
			 */ cond(`adj'<=0, 0, `adj'^`p`j'') ))) `ifpj'
			`replace' `alast'=`a'
		}
		* If appropriate, extract adjustment
		if `stored' {
			if !missing(e(fp_a`j')) scalar `a'=e(fp_a`j')
		}
		if `j'==1 `gen' `fp'=`b0'+`b`j''*(`h'-`a')
		else `replace' `fp'=cond(`h'!=. & `b`j''!=., /*
			*/ `fp'+`b`j''*(`h'-`a'), `fp')
		`replace' `hlast'=`h'
		`replace' `plast'=`p`j''
	}
	return local fpvar _fp
	if "`t'"=="num" {
		di as txt "FP(" as res `X' as txt ") = " /*
		 */ as res %9.0g `fp'
		return scalar fp=`fp'
	}
	else {
		cap drop _fp
		rename `fp' _fp
		di as txt "_fp created from `X'."
		return scalar fp=_fp[1]
	}
end
