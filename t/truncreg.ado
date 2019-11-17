*! version 1.0.2  22mar2000 
 program define truncreg, eclass
	 version 6.0

	 if replay() {
		 if "`e(cmd)'" != "truncreg" {
			 noi di in red "results of truncreg not found"
			 exit 301
                 }
		 Replay `0'
         }
	 else Estimate `0'
	 mac drop T_*
 end

 program define Estimate, eclass
	 version 6.0
	 syntax [varlist] [aweight fweight pweight] [if] [in]  /*
		 */ [, LL(string) UL(string) /*
		 */ NOConstant noLOg /*
		 */ Marginal   AT(string)/*
		 */  Robust CLuster(varname) Level(passthru) * ]
	 mlopts mlopts, `options'
         if "`cluster'"~="" {
		 local clopt "cluster(`cluster')"
         }
	 if ("`marginal'"=="") & (`"`at'"' ~= "") {
		 noi di in red "invalid syntax"
		 exit 198
         }			
                                 
	 tokenize `varlist'
	 local lhs "`1'"
	 mac shift
	 local rhs "`*'"
	 _rmcoll `rhs'
	 local rhs `r(varlist)'
					  /* define estimation sample */
	 quietly{
	        marksample touse	
		markout `touse' `lhs' `rhs' `cluster' `wvar', strok
		count if `touse'==1
		scalar N_b= r(N)
					/* case 1, left truncated */ 
		if "`ll'" ~= "" {
		        replace `touse' = 0 if `lhs' <= `ll'
			capture confirm number `ll'
			if  _rc != 0 {
				replace `touse' = 0 if `ll'==.
			}
			global T_a `ll'
			global T_flag 1
                }
					/* case -1, right truncated */
		if "`ul'" ~= "" {
			replace `touse' = 0 if `lhs' >= `ul'
			capture confirm number `ul'
			if _rc != 0 {
				replace `touse' = 0 if `ul'== .
			}
			global T_b `ul'
			global T_flag -1
                }
					/* case 0, between        */
		if ("`ul'" ~="") & ("`ll'"~="") {
			global T_flag 0
                }
					/* case 2, regression     */
		if ("`ul'"=="") & ("`ll'"=="") {
			global T_flag 2
		}
		count if `touse'==1
		scalar N_a=r(N)
	 } 
                                          /* handle weights          */
         if "`weight'"~= "" {
	        tempvar wvar
	        qui gen double `wvar' `exp' if `touse' 
	        local weight "[`weight'`exp']"
                } 
	 di
	 di in blue "Note: " %10.0g N_b - N_a " obs. are truncated"
                                 	/* get initial values       */
         if "`weight'" ~= "" {
         	qui reg `lhs' `rhs' `weight' if `touse', `noconstant'
         }
	 else {
		qui reg `lhs' `rhs' if `touse', `noconstant'
         }
	 tempname b0
	 mat `b0'=e(b), e(rmse)
					/* call ml model            */
	 ml model lf trunc_ll (`lhs'=`rhs', `noconstant') /sigma    /*
		 */ `weight' if `touse', max miss init(`b0', copy)    /*
		 */ search(off) nopreserve `mlopts' `log' /* 
		 */ `robust' `clopt' title("Truncated regression")
	 tempname b
	 mat `b' = get(_b)
	 est scalar N_bf=N_b
	 est scalar sigma =`b'[1,colsof(`b')]
         est local cmd "truncreg"
	 est local predict "truncr_p"
	 est local k
	 est local k_eq
	 est local k_dv
	 if $T_flag == 1 {
		est scalar llopt= $T_a
         }
	 if $T_flag == -1 {
		est scalar ulopt= $T_b
         }
	 if $T_flag == 0 {
		est scalar llopt= $T_a
		est scalar ulopt= $T_b
         }
					/* get mean matrix     */
	 if "`weight'" ~= "" {
		qui mat ac A= `rhs' `weight' if `touse',   /*
		  */ `noconstant' means(M)
	 }
	 else {
		qui mat ac A=`rhs' if `touse',                /*
		  */ `noconstant' means(M)
	 }
	 est mat means M
	 if `"`at'"' ~= "" {
		if "`noconstant'" ~="" {
	 		Replay, `level' `marginal' at(`at')
		}
		else {
			tempname at2
			mat `at2'= `at', 1
			Replay, `level' `marginal' at(`at2')
		}
	 }
	 else {
	 	Replay, `level' `marginal' 
	 }
end

program define Replay
	syntax [, Level(int $S_level) Marginal AT(string)]
	if ("`marginal'" =="") & (`"`at'"' ~= "") {
		noi di in red "invalid syntax"
		exit 198
	}
	local flag cond(e(ulopt)==., 1, -1) 
	if `flag'== -1 {
		local flag cond(e(llopt)==., -1,0)	
	}
	else local flag cond(e(llopt)==., 2, 1)
	local llopt e(llopt)
	local ulopt e(ulopt)

	if "`marginal'" =="" {
		di _n in gr `"Truncated regression"'   
		if `flag' == 1 {
	        	di in gr "Limit:   lower = " in ye %10.0g `llopt' /*
			*/ _col(57) `"Number of obs ="' /*
			*/ in ye %7.0f e(N)
			di in gr "         upper = " in ye "      +inf" /*
			*/ in gr _col(57) `"`e(chi2type)' chi2("' /*
			*/ in ye e(df_m) /*
			*/ in gr `")"' _col(71) /*
			*/ `"="' in ye %7.2f e(chi2)
        	}
		if `flag' == -1 {
			di in gr "Limit:   lower = " in ye "      -inf" /*
			*/ _col(57) `"Number of obs ="' /*
			*/ in ye %7.0f e(N)
			di in gr "         upper = " in ye %10.0g `ulopt' /*
			*/ in gr _col(57) `"`e(chi2type)' chi2("' /*
			*/ in ye e(df_m) /*
			*/ in gr `")"' _col(71) /*
			*/ `"="' in ye %7.2f e(chi2)
        	}
		if `flag' == 0 {
			di in gr "Limit:   lower = " in ye %10.0g `llopt' /*
			*/ _col(57) `"Number of obs ="' /*
			*/ in ye %7.0f e(N)
			di in gr "         upper = " in ye %10.0g `ulopt' /*
			*/ in gr _col(57) `"`e(chi2type)' chi2("' /*
			*/ in ye e(df_m) /*
			*/ in gr `")"' _col(71) /*
			*/ `"="' in ye %7.2f e(chi2)
        	}
		if `flag' == 2 {
			di in gr "Limit:   lower = " in ye "      -inf" /*
			*/ _col(57) `"Number of obs ="' /*
			*/ in ye %7.0f e(N)
			di in gr "         upper = " in ye "      +inf" /*
			*/ in gr _col(57) `"`e(chi2type)' chi2("' /*
			*/ in ye e(df_m) /*
			*/ in gr `")"' _col(71) /*
			*/ `"="' in ye %7.2f e(chi2)
        	}
		di in gr `"Log likelihood = "' in ye %10.0g e(ll) /*
	       		*/ _col(57) `"Prob > chi2   ="' in ye /*
			*/ %7.4f chiprob(e(df_m),e(chi2))
		di
		ml display, level(`level') noh
	}
	else {
		if `"`at'"' =="" {	
			Margin, level(`level') at(e(means))
		}
		else {
			Margin, level(`level') at(`at')
                }
	}
end


program define Margin, eclass
	syntax [,Level(int $S_level) AT(string)] 

	local flag cond(e(ulopt)==., 1, -1) 
	if `flag'== -1 {
		local flag cond(e(llopt)==., -1,0)	
	}
	else local flag cond(e(llopt)==., 2, 1)
	local llopt e(llopt)
	local ulopt e(ulopt)
					/* calculation		*/
	tempname bm vm b V a c xmat xb alpha alpha2 lamda  factor  Z z s u 
	mat `xmat' = `at'
	mat `b' = get(_b) 
	mat `V' = e(V) 
	scalar `a' =colsof(`b')
	local s =`b'[1,`a'] 
	scalar `c' = colsof(`xmat')
	mat `xb' = `xmat'*`b'[1,1..`c']'
        if `flag' == 1 {
        	scalar `alpha' = (`llopt' - `xb'[1,1])/`s'
		scalar `lamda' = normd(`alpha')/(normprob(-`alpha'))
		scalar `factor' = 1-`lamda'^2 + `alpha'*`lamda'
        }
	if `flag' == -1 {
        	scalar `alpha' = (`ulopt' - `xb'[1,1])/`s'
		scalar `lamda' = -normd(`alpha')/(normprob(`alpha'))
		scalar `factor' = 1-`lamda'^2 + `alpha'*`lamda'
	}
	if `flag' == 0 {
        	scalar `alpha' = (`llopt' - `xb'[1,1])/`s'
        	scalar `alpha2' = (`ulopt' - `xb'[1,1])/`s'
		scalar `lamda' = (normd(`alpha2') - normd(`alpha')) /*
		       */ /(normprob(`alpha2') - normprob(`alpha'))
		scalar `factor' = 1 - `lamda'^2 - `alpha2'*`lamda' /*
		       */ - (`ulopt' - `llopt')*normd(`alpha')           /*
		       */ /(`s'*(normprob(`alpha2') - normprob(`alpha')))
	}
	if `flag' == 2 {
		scalar `factor' = 1
	}
	mat `bm' = `factor'*`b'[1,1..`c'] 
	mat `vm' = (`factor'^2)*`V'[1..`c',1..`c']
					   /* display results        */
	scalar `Z' = invnorm(1-(1-`level'/100)/2)

	if `level'<10 | `level'>99 {
		local level 95
	}
		di _n in gr `"Marginal Effects"'   
		if `flag' == 1 {
	        	di in gr "Limit:   lower = " in ye %10.0g `llopt' /*
			*/ _col(57) `"Number of obs ="' /*
			*/ in ye %7.0f e(N)
			di in gr "         upper = " in ye "      +inf" /*
			*/ in gr _col(57) `"`e(chi2type)' chi2("' /*
			*/ in ye e(df_m) /*
			*/ in gr `")"' _col(71) /*
			*/ `"="' in ye %7.2f e(chi2)
        	}
		if `flag' == -1 {
			di in gr "Limit:   lower = " in ye "      -inf" /*
			*/ _col(57) `"Number of obs ="' /*
			*/ in ye %7.0f e(N)
			di in gr "         upper = " in ye %10.0g `ulopt' /*
			*/ in gr _col(57) `"`e(chi2type)' chi2("' /*
			*/ in ye e(df_m) /*
			*/ in gr `")"' _col(71) /*
			*/ `"="' in ye %7.2f e(chi2)
        	}
		if `flag' == 0 {
			di in gr "Limit:   lower = " in ye %10.0g `llopt' /*
			*/ _col(57) `"Number of obs ="' /*
			*/ in ye %7.0f e(N)
			di in gr "         upper = " in ye %10.0g `ulopt' /*
			*/ in gr _col(57) `"`e(chi2type)' chi2("' /* 
			*/ in ye e(df_m) /*
			*/ in gr `")"' _col(71) /*
			*/ `"="' in ye %7.2f e(chi2)
        	}
		di in gr `"Log likelihood = "' in ye %10.0g e(ll) /*
	       		*/ _col(57) `"Prob > chi2   ="' in ye /*
			*/ %7.4f chiprob(e(df_m),e(chi2))
	di
	if `"`e(clustvar)'"' != "" {
		local skip = 33-length(`"`e(clustvar)'"')
		di in gr _skip(`skip') /*
	      */ `"(standard errors adjusted for clustering on `e(clustvar)')"'
	}
	di in gr _dup(78) `"-"'
        local 1 "variable"
	local skip = 8-length(`"`1'"')
	di in gr /*
		*/ _skip(`skip') `"`1' |"' _col(17) `"dF/dx"' _col(25) /*
		*/ `"Std. Err."' _col(40) `"z"' _col(45) `"P>|z|"' /*
		*/ _col(55) `"X_at"'/*
		*/ _col(62) `"[    `level'% C.I.   ]"' _n /*
		*/ _dup(9) `"-"' `"+"' _dup(68) `"-"'
        local varlist: colnames(`bm')
	tokenize `varlist'
	local i 1
	while `i' <= `c' {
		local C = `bm'[1, `i']    
		local v = `vm'[`i',`i']
		local star `" "'
		local s = sqrt(`v')
		local ll = `C'-`Z'*`s'
		local ul = `C'+`Z'*`s'
		local z = `C'/`s' 
		local x = `xmat'[1,`i']

		local skip=8-length(`"``i''"')
		di in gr _skip(`skip') `"``i''`star'|  "' in ye /*
			*/ %9.0g `C' `"  "' /*
			*/ %9.0g `s' `" "' /*
			*/ %8.2f `z'  `"  "' /*
			*/ %6.3f 2*normprob(-abs(`z')) `"  "' /* 
			*/ %8.0g `x' `"  "' /*
			*/ %8.0g `ll' `" "' /*
			*/ %8.0g `ul'
		local i=`i'+1
	}
	di in gr _dup(78) `"-"'

					/* post results		*/
	est local at 
	est mat at `xmat'
	est local dfdx 
	est mat dfdx `bm'
	est local V_dfdx 
	est mat V_dfdx `vm'
end



