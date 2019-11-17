*! 2:01 PM 6/26/2006 by raa (raalfaro@hotmail.com)
program gthacker, eclass
	version 8
	syntax varlist(ts) [if] [in] [, NOFE Level(integer `c(level)') LAG(integer -1)]
	tokenize `varlist'
	local lhs `1'
	mac shift 
	local rhs `*'

	tsrevar `varlist'
	local varlist "`r(varlist)'"

	if `level'<10 | `level'>99 {
		di as err "level() must be between 10 and 99 inclusive"
		exit 198
	}

	qui {

		local ivar: char _dta[iis]
		local tvar: char _dta[tis]

		tempvar touse x c
		tempname vadj b V

		mark `touse' `if' `in'
		markout `touse' `varlist' `ivar' `tvar'

		preserve
		keep if `touse'
		keep `varlist' `ivar' `tvar'

		tab `ivar'
		local dfa=r(r)
		local dfm : word count `varlist'
		local w 1
		
		if "`nofe'"=="" {
			foreach i of varlist `varlist' {
				summ `i'
				by `ivar': gen double `x'=sum(`w'*`i')/sum(`w')
				by `ivar': replace `x'=`i'-`x'[_N]+r(mean)
				drop `i'
				gen double `i'=`x'
				drop `x'
			}
		}

		regress `varlist'
		local rsq=e(r2)
		local mss=e(mss)
		local rss=e(rss)
		local nobs=e(N)
		local F=e(F)
		local p=fprob(e(df_m),e(df_r),e(F))
		mat `b'=e(b)

		if "`nofe'"=="" {
			local dfe=`nobs'-e(df_m)-`dfa'	
			local tit "Gerring-Thacker linear regression: FE"
			sca `vadj'=e(df_r)/`dfe'
			local typ "within"
			local F=e(F)/`vadj'
			local p=fprob(e(df_m),`dfe',`F')			
		}		
		else {
			local dfe=`nobs'-e(df_m)-1
			local tit "Gerring-Thacker linear regression"
			sca `vadj'=1
			local typ "normal"
		}

		if `lag'>=0 {
			newey `varlist', lag(`lag') force
			local vce="Newey-West"
			local tit = "`tit' + NW(`lag')"
			local F=e(F)/`vadj'
			local p=fprob(e(df_m),`dfe',`F')
		}

		mat `V'=e(V)
		mat `V'=`vadj'*`V'
		sum `tvar' if e(sample) 
		local tmin=r(min)
		local tmax=r(max)
		restore
		mat colnames `b' = `rhs' _cons
		mat rownames `V' = `rhs' _cons
		mat colnames `V' = `rhs' _cons

		eret post `b' `V', dep(`lhs') obs(`nobs') dof(`dfe') esample(`touse')
		eret local vcetype	"`vce'"
		eret local depvar 	"`lhs'"
		eret local title	"`tit'"
		eret local typer2	"`typ'"
		eret local cmd		"gthacker"
		eret local predict	"gthacker_p"
		eret scalar r2 		=`rsq'
		eret scalar N_g 	=`dfa'
		eret scalar T_l		=`tmin'
		eret scalar T_u		=`tmax'
		eret scalar df_m	=`dfm'-1
		eret scalar F		= `F'
		eret scalar prob	=`p'
	}

	#delimit ;
	di _n in gr "`e(title)'"; di " ";
	di in gr `"Number of groups  ="' in ye %8.0f e(N_g) 
		in gr _col(56) `"Number of obs ="' in ye %8.0f e(N);
	di in gr `"Sample min period ="' in ye %8.0f e(T_l) 
		in gr _col(56) `"F("' in gr %3.0f e(df_m) in gr `","' 
		in gr %6.0f e(df_r) in gr `") ="' in ye %8.2f e(F);
	di in gr `"       max period ="' in ye %8.0f e(T_u) 
		in gr _col(56) `"Prob > F      ="' in ye %8.4f e(prob);
	di in gr `"Type of R-squared =  "' in ye "`e(typer2)'" 
		in gr _col(56) `"R-squared     ="' in ye %8.4f e(r2);
	di " ";
	#delimit cr

	eret display, level(`level')	
end
