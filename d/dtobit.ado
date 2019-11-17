*! version 1.0.3  04feb2011
program define dtobit, eclass
	version 6.0
	if "`e(cmd)'" != "tobit" {
		noi di in red "results of tobit not found"
		exit 301
	}
	syntax [, AT(string) Censor Brief LEVel(int $S_level) noDiscrete ]

	tempname ll ul 
	scalar `ll' = e(llopt)
	scalar `ul' = e(ulopt)
	local flag cond(`ul'==., 1,2)		/* flag=1 left */
	if `flag' == 2 {			/* flag=2 right */ 
		local flag cond(`ll'==., 2, 3)	/* flag=3 in-between */
	}
	if "`at'" != "" & "`censor'" != "" {
		di in red "at and censor cannot be specified the same time"
		exit 198
	}

					/* `at' matrix	*/
	if `flag' == 3 & "`censor'" != "" {
		di in red "censor option not available for in-between " /*
			*/ "censoring"
		exit 198
	}
	
	local weight
	if "`e(wexp)'" != "" {
		local weight "[`e(wtype)'`e(wexp)']"
	}
	
	tempname B tmp uncond cond prob z za zb fz xmat sigma Fz
	mat `B'=e(b)
	mat `B'= `B'[1, 1..colsof(`B')-1] 
	mat `xmat'= `B'	
	local dep "`e(depvar)'"
	scalar `sigma' = _b[_se]
	local cnum =  colsof(`B')
	local cnames : colnames `B'
	if `"`at'"' == "" & "`censor'" == "" {
		local i = 1
		while `i' <= `cnum' {
			local name : word `i' of `cnames'
			if "`name'" != "_cons" {
				qui sum `name' `weight' if e(sample)
				mat `xmat'[1,`i'] = r(mean)
			}
			else mat `xmat'[1,`i'] = 1
			local i  = `i' + 1
		}
		local ismean  true
	}
	else { 
		if `"`at'"' == "" {
			if `flag' == 1 {
				qui count if `dep' > `ll' & e(sample)
			}
			else {
				qui count if `dep' < `ul' & e(sample)
			}
			scalar `Fz' = r(N)/e(N)
		}
		else {
			mat `xmat' = `B'
			cap _mkvec `xmat', from(`at') update
			if _rc == 111 {
				_mkvec `xmat', from(`at', copy) update /*
					*/ error("at(matname)")
			}
			else _mkvec `xmat', from(`at') update 		/*
			*/	error("at(matname)")
			local name : word `cnum' of `cnames'
			if "`name'" == "_cons" {
				mat `xmat'[1,`cnum'] = 1
			}
		}
	}
					/* calculation */

	if `flag' !=3 { 
		if "`censor'" == "" {
			mat `tmp' = `xmat'*`B''
			if `flag' == 1 {
				scalar `z' = (`tmp'[1,1]-`ll')/`sigma'
			}
			else scalar `z' = (`ul'-`tmp'[1,1])/`sigma'
			scalar `Fz' = normprob(`z')
		}
		else scalar `z' = invnorm(`Fz')	
		if `Fz' == 1 {
			scalar `prob' = .
			scalar `cond' = 1
			scalar `uncond' = 1
		}
		else {
			scalar `fz' = normd(`z')
			scalar `uncond' = `Fz'
		scalar `cond' = 1 - `z'*`fz'/`Fz' - `fz'*`fz'/(`Fz'*`Fz')
			scalar `prob' = `fz'/`sigma'
		}
	}	
	else {
		mat `tmp' = `xmat'*`B''
		scalar `za' = (`ll' - `tmp'[1,1])/`sigma'
		scalar `zb' = (`ul' - `tmp'[1,1])/`sigma'
		scalar `uncond' = (normprob(`zb') - normprob(`za'))
		scalar `prob' = (normd(`zb')-normd(`za'))/`sigma'
		scalar `cond' = 1 - (`za'*normd(`za') - `zb'*normd(`zb')) /*
			*/ /(normprob(`za')-normprob(`zb')) - 		/*
			*/ (normd(`za') - normd(`zb'))^2 / 		/*
			*/ (normprob(`za') - normprob(`zb'))^2 
	}

	tempname V dfdx_u dfdx_c dfdx_p V_u V_c V_p
	mat `dfdx_u' = `uncond'*`B'
	mat `dfdx_c' = `cond'*`B'
	mat `dfdx_p' = `prob'*`B'
	mat `V'=e(V)
	mat `V'=vecdiag(`V')
	mat `V'=`V'[1, 1..colsof(`V')-1]
	mat `V_u' = `uncond'*`uncond'*`V'
	mat `V_c' = `cond'*`cond'*`V'
	mat `V_p' = `prob'*`prob'*`V'

					/* mark dummies */

	local j : word count  `cnames' 
	local cnames : subinstr local cnames "_cons" ""
	tokenize `cnames'
	est local dummy
	while `"`1'"' != "" {
		cap assert `1' ==0 | `1' == 1 if e(sample)
		if _rc==0 { est local dummy `"`e(dummy)' 1"' }
		else	  { est local dummy `"`e(dummy)' 0"' }
		mac shift
	}
	est local dummy `"`e(dummy)' 0"'

					/* process dummy variable */

	if "`discret'" == "" & "`censor'" == "" {
		tempname u v 
		local i 1
		local anydum 
		while `i' <= `j' {
			local isdum : word `i' of `e(dummy)'
			if `isdum' {
				local anydum true
				Dummy "`i'" "`xmat'" "`B'" "`flag'"
				mat `dfdx_u'[1,`i'] = `s(dfdx_u)'
				mat `dfdx_c'[1,`i'] = `s(dfdx_c)'
				mat `dfdx_p'[1,`i'] = `s(dfdx_p)'
			}
			local i=`i'+1	
		}
	}

					/* output */
	if "`censor'" == "" {
		est mat at `xmat'
	}
	else est scalar rate=`Fz'

	tempname B V
	mat `B' = e(b)
	mat `B' = `B'[1, 1..colsof(`B')-1]
	mat `V' = e(V)
	mat `V' = vecdiag(`V')
	if "`brief'" != "" {
		Display0 "`B'" "`dfdx_u'" "`dfdx_c'" "`dfdx_p'" "`censor'" /*
			*/ "`discret'" "`ismean'"
	} 
	else {
		local title "Latent Variable"
		Display1  `B' `V' "`title'" "`level'" 
		local title "Unconditional Expected Value"
		Display1 `dfdx_u' `V_u'  "`title'" "`level'" "`censor'" /*
			*/ "`discret'"  
		local title "Conditional on being Uncensored"
		Display1 `dfdx_c' `V_c'  "`title'" "`level'" "`censor'" /*
			*/ "`discret'" 
		local title "Probability Uncensored"
		Display1 `dfdx_p' `V_p'  "`title'" "`level'" "`censor'" /*
			*/ "`discret'" 
		if `"`anydum'"'==`"true"' {
                	di in gr /*
                	*/ `"(*) dF/dx"' /*
                */ `" is for discrete change of dummy variable from 0 to 1"'
        	}
	}

					/* post results */
	tempname se_u se_c se_p se_b
	local I colsof(`dfdx_u')
	mat `se_u' = `V_u'
	mat `se_c' = `V_c'
	mat `se_p' = `V_p'
	local i 1
	while `i' <= `I' {
		mat `se_u'[1,`i'] == sqrt(`V_u'[1,`i'])
		mat `se_c'[1,`i'] == sqrt(`V_c'[1,`i'])
		mat `se_p'[1,`i'] == sqrt(`V_p'[1,`i'])
		local i = `i' + 1
	}
	local I colsof(`B')
	mat `se_b' = `B' 
	local i 1
	while `i' <=`I' {
		mat `se_b'[1,`i'] == sqrt(`V'[1,`i'])
		local i = `i' + 1
	}
	est mat dfdx_u `dfdx_u'
	est mat dfdx_c `dfdx_c'
	est mat dfdx_p `dfdx_p'
	est mat se_b `se_b'
	est mat se_u `se_u'
	est mat se_c `se_c'
	est mat se_p `se_p'
end

program define Dummy, sclass
	args i xmat B flag
	local ll= e(llopt)
	local ul= e(ulopt)
	tempname X x0 x1 E_u0 E_u1 E_c0 E_c1 E_p0 E_p1 se
        tempname dfdx_u dfdx_c dfdx_p 
	scalar `se' = _b[_se]
	mat `X'=`xmat'*`B''
	scalar `x0' = `X'[1,1] - `xmat'[1,`i']*`B'[1,`i']
	scalar `x1' = `X'[1,1] + (1-`xmat'[1,`i'])*`B'[1, `i']
	if `flag' == 1 {
		scalar `E_c0' = `x0' + `se'*normd((`ll'-`x0')/`se')  /*
		*/ / (1-normprob((`ll'-`x0')/`se'))
		scalar `E_u0' = `ll'*normprob((`ll'-`x0')/`se') + /*
		*/ normprob((`x0' - `ll')/`se')*`E_c0' 
		scalar `E_c1' = `x1' + `se'*normd((`ll'-`x1')/`se')  /*
		*/ / (1-normprob((`ll'-`x1')/`se'))
		scalar `E_u1' = `ll'*normprob((`ll'-`x1')/`se') + /*
		*/ normprob((`x1' - `ll')/`se')*`E_c1' 
		scalar `E_p0' = normprob((`x0' - `ll')/`se')
		scalar `E_p1' = normprob((`x1' - `ll')/`se')
	}
	if `flag' == 2 {
		scalar `E_c0' = `x0' - `se'*normd((`ul'-`x0')/`se')  /*
		*/ / normprob((`ul'-`x0')/`se')
		scalar `E_u0' = `ul'*normprob((`x0'-`ul')/`se') + /*
		*/ normprob((`ul' - `x0')/`se')*`E_c0' 
		scalar `E_c1' = `x1' - `se'*normd((`ul'-`x1')/`se')  /*
		*/ / normprob((`u1'-`x1')/`se')
		scalar `E_u1' = `ul'*normprob((`x1'-`ul')/`se') + /*
		*/ normprob((`ul' - `x1')/`se')*`E_c1' 
		scalar `E_p0' = normprob((`ul' - `x0')/`se')
		scalar `E_p1' = normprob((`ul' - `x1')/`se')
	}
	if `flag'==3 {
		scalar `E_c0' = `x0' + `se'*(normd((`ll'-`x0')/`se')  /*
		*/ - normd((`ul' - `x0')/`se'))/			/*
		*/ (normprob((`ul'-`x0')/`se') - normprob((`ll'-`x0')/`se'))
		scalar `E_u0' = `ll'*normprob((`ll'-`x0')/`se') /*
		*/ + `ul'*normprob((`x0'-`ul')/`se') +   	/*
		*/ (normprob((`ul'-`x0')/`se') - normprob((`ll'-`x0')/`se')) /*
		*/ *`E_c0'	
		scalar `E_c1' = `x1' + `se'*(normd((`ll'-`x1')/`se')  /*
		*/ - normd((`ul' - `x1')/`se'))/			/*
		*/ (normprob((`ul'-`x1')/`se') - normprob((`ll'-`x1')/`se'))
		scalar `E_u1' = `ll'*normprob((`ll'-`x1')/`se') /*
		*/ + `ul'*normprob((`x1'-`ul')/`se') +   	/*
		*/ (normprob((`ul'-`x1')/`se') - normprob((`ll'-`x1')/`se')) /*
		*/ *`E_c1'
		scalar `E_p0' = normprob((`ul'-`x0')/`se') -	/*
		*/ normprob((`ll'-`x0')/`se')
		scalar `E_p1' = normprob((`ul'-`x1')/`se') -	/*
		*/ normprob((`ll'-`x1')/`se')
		
	}
	scalar `dfdx_u' = `E_u1' - `E_u0'
	scalar `dfdx_c' = `E_c1' - `E_c0'
	scalar `dfdx_p' = `E_p1' - `E_p0'
	sreturn local dfdx_u = `dfdx_u'
	sreturn local dfdx_c = `dfdx_c'
	sreturn local dfdx_p = `dfdx_p'
end

program define Display0 
	args	B dfdx_u dfdx_c dfdx_p censor discret ismean

		local vnam : colnames(`dfdx_u')
		local nnam : word count `vnam'
		if `nnam' >= 1 {
			noi di 
			noi di in gr /*
				*/ "------------------------------------------------------------------------------"
			if "`ismean'" != "" {
			noi di in gr /*
				*/ "         | Marginal Effects at Means" 
			}
			else if "`censor'"=="" {
				noi di in gr /*
				*/ "         | Marginal Effects at e(at)" 
			}
			else noi di in gr /*
				*/ "	     | Marginal Effects at Observed" /*
				*/ " Censoring Rate"
			
			noi di in gr /*
				*/ "         |--------------------------------------------------------------------" 
			noi di in gr /*
				*/ "         |   Latent      Unconditional " /*
*/"    Conditional on      Probability"
			noi di in gr /*
				*/ "  Name   |  Variable     Expected Value "/*
*/"   being Uncensored    Uncensored"
			noi di in gr /*
				*/ "---------+--------------------------------------------------------------------"

			local i 1
			local anydum 
			while `i' <= `nnam' {
				local isdum : word `i' of `e(dummy)'
				if `isdum' & "`discret'" == "" {
					local star "*"
					local anydum true
				}
				else local star " "
				local v : word `i' of `vnam'
				local l = length("`v'")
				local skip = 9 - `l'
				local t0 = `B'[1,`i']
				local t1 = `dfdx_u'[1,`i']     
				local t2 = `dfdx_c'[1,`i'] 
				local t3 = `dfdx_p'[1,`i'] 
			noi di in gr _col(`skip') "`v'`star'" _col(10) "|" /*
					*/ _col(12) in ye %10.0g `t0' /*
					*/ _col(28) in ye %10.0g `t1' /*
					*/ _col(46) in ye %10.0g `t2' /*
					*/ _col(64) in ye %10.0g `t3'
				local i = `i'+1
			}
			noi di in gr /*
				*/ "---------+--------------------------------------------------------------------"
		}
	if `"`anydum'"'==`"true"' {
                di in gr /*
                */ `"(*) dF/dx"' /*
                */ `" is for discrete change of dummy variable from 0 to 1"'
        }
	
end

program define Display1
	args bm vm title level censor discret 
	local c colsof(`bm')
	if `level'<10 | `level'>99 {
		local level 95
	}
	tempname Z xmat rate
	if "`censor'" == "" {
		mat `xmat' = e(at) 
	}
	else scalar `rate' = e(rate) 
	scalar `Z' = invnorm(1-(1-`level'/100)/2)
	di 
	di in gr "Marginal Effects: " "`title'"
	di in gr _dup(78) `"-"'
        local 1 "variable"
	local skip = 8-length(`"`1'"')
	if "`censor'" == "" {
	di in gr /*
		*/ _skip(`skip') `"`1' |"' _col(17) `"dF/dx"' _col(25) /*
		*/ `"Std. Err."' _col(40) `"z"' _col(45) `"P>|z|"' /*
		*/ _col(55) `"X_at"'/*
		*/ _col(62) `"[    `level'% C.I.   ]"' _n /*
		*/ _dup(9) `"-"' `"+"' _dup(68) `"-"'
	}
	else {
	di in gr /*
		*/ _skip(`skip') `"`1' |"' _col(17) `"dF/dx"' _col(25) /*
		*/ `"Std. Err."' _col(40) `"z"' _col(45) `"P>|z|"' /*
		*/ _col(55) `"Rate"'/*
		*/ _col(62) `"[    `level'% C.I.   ]"' _n /*
		*/ _dup(9) `"-"' `"+"' _dup(68) `"-"'
	}

        local varlist: colnames(`bm')
	tokenize `varlist'
	local i 1
	while `i' <= `c' {
		local isdum : word `i' of `e(dummy)'
		if `isdum' & ("`discret'" == "") {
			local star "*"
		}
		else local star " "
		local C = `bm'[1, `i']    
		local v = `vm'[1,`i']
		local s = sqrt(`v')
		local ll = `C'-`Z'*`s'
		local ul = `C'+`Z'*`s'
		local z = `C'/`s' 
		if "`censor'" == "" {
			local x = `xmat'[1,`i']
		}
		else local x=`rate'

		local skip=8-length(`"``i''"')
		if `isdum' & ("`discret'" == "") {
			di in gr _skip(`skip') `"``i''`star'|  "' in ye /*
			*/ %9.0g `C' `"  "' /*
			*/ %9.0g `s' `" "' /*
			*/ %8.2f `z'  `"  "' /*
			*/ %6.3f 2*normprob(-abs(`z')) `"  "' /* 
			*/ " 0 --> 1  " /*
			*/ %8.0g `ll' `" "' /*
			*/ %8.0g `ul'
		}
		else {
			di in gr _skip(`skip') `"``i''`star'|  "' in ye /*
			*/ %9.0g `C' `"  "' /*
			*/ %9.0g `s' `" "' /*
			*/ %8.2f `z'  `"  "' /*
			*/ %6.3f 2*normprob(-abs(`z')) `"  "' /* 
			*/ %8.6g `x' `"  "' /*
			*/ %8.0g `ll' `" "' /*
			*/ %8.0g `ul'
		}
		local i=`i'+1
	}
	di in gr _dup(78) `"-"'

end



