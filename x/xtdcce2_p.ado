capture program drop xtdcce2_p
program define xtdcce2_p 
	syntax newvarname(max=1 generate) [in] [if] , [RESiduals xb COEFFicient stdp se partial]
	
	*marksample for in if of predict command
	marksample touse, novarlist
	
	if "`e(cmd)'" != "xtdcce2" {
		display as error "Only after xtdcce2, last command is `e(cmd)'"
		exit
	}
	qui xtdcce2 , version
	if `e(version)' < 1.2 {
		display as error "predict requires version 1.2 or higher"
		display as error "To update, from within Stata type " _c
		display as smcl	"{stata ssc install xtdcce2, replace :ssc install xtdcce2, replace}"
		exit
	}
	
	local nopts : word count `residuals' `xb' `coefficient' `stdp' `se' `partial'
    if `nopts' >1 {
        display "{err}only one statistic may be specified"
        exit 498
    }
	else if `nopts' == 0 {
		display in gr "(option xb assumed; fitted values)"
		local xb "xb"
	}
	qui{
		tsset
		*if "`r(balanced)'" != "strongly balanced" {
		*	tsfill, full
		*}
		local newvar `varlist'
		
		tempvar tvar idvar  
		
			
		if "`e(p_if)'" != "" {
			local p_if "& `e(p_if)'"
		}
		if "`e(p_in)'" != "" {
			local p_in "in `e(p_in)'"
		}		
		tsset
		local d_idvar `r(panelvar)'
		local d_tvar `r(timevar)'
		sort `d_idvar' `d_tvar' 
		egen `idvar' = group(`d_idvar')
		egen `tvar' = group(`d_tvar')
		tsset `idvar' `tvar'
		
		local lhs `e(depvar)'
		local mg_vars  `e(p_mg_vars)'
		local mg_vars : list uniq mg_vars
		local pooled_vars `e(p_pooled_vars)'
		local cr_vars `e(p_cr_vars)'
		
		local o_lhs `lhs'
		local o_mg_vars `mg_vars'
		local o_pooled_vars `pooled_vars'
		
		
		
		local cr_lags = e(cr_lags)
		**create ec variable if necessary
		if "`e(lr)'" != "" {
			local lr_vars `e(lr)'			
			
			local pooled_vars = subinword("`pooled_vars'","ec","`e(p_lr_1)'",.)
			local mg_vars = subinword("`mg_vars'","ec","`e(p_lr_1)'",.)
			local cr_vars = subinword("`cr_vars'","ec","`e(p_lr_1)'",.)		
			local lr_vars = subinword("`lr_vars'","ec","`e(p_lr_1)'",.)
			
			local o_mg_vars = subinword("`o_mg_vars'","ec","`e(p_lr_1)'",.)
			local o_pooled_vars = subinword("`o_pooled_vars'","ec","`e(p_lr_1)'",.)

		}		
		
		
		
		**create constant and trend
		if strmatch("`pooled_vars' `mg_vars' `cr_vars'","*_cons*") == 1 {
			tempvar constant
			gen double `constant' = 1
			local pooled_vars = subinword("`pooled_vars'","_cons","`constant'",.)
			local mg_vars = subinword("`mg_vars'","_cons","`constant'",.)
			local cr_vars = subinword("`cr_vars'","_cons","`constant'",.)
		}
		if strmatch("`pooled_vars' `mg_vars' `cr_vars'","*trend*") == 1 {
			tempvar trend
			gen double `trend' = `tvar'
			local pooled_vars = subinword("`pooled_vars'","trend","`trend'",.)
			local mg_vars = subinword("`mg_vars'","trend","`trend'",.)
			local cr_vars = subinword("`cr_vars'","trend","`trend'",.)
		}
		
		markout `touse' `lhs' `mg_vars' `pooled_vars'
		
		*replace `touse' = 1 if `touse' `p_if' `p_in'
		
		local unique_vars `pooled_vars' `mg_vars' `cr_vars' `lhs'
		local unique_vars : list uniq unique_vars
		
		***check for ts vars. tsrevar creates tempvars, then loop over remaining vars to create tempvars
	
		fvrevar `unique_vars' 
		local no_temp_vars `r(varlist)'
		local temp_vars : list unique_vars - no_temp_vars
		local no_temp_vars : list unique_vars & no_temp_vars
				
		*loop over ts vars and create temp var 
		* as over variables, subinword can be used
		foreach var in `temp_vars' {
			fvrevar `var'
			foreach liste in pooled_vars mg_vars cr_vars lhs {
					local `liste' = subinword("``liste''","`var'","`r(varlist)'",.)
			}
		}
		
		*loop over non ts vars and create tempvat
		foreach var in `no_temp_vars' {
			tempvar `var'
			gen double ``var'' = `var' if `touse'
			foreach liste in pooled_vars mg_vars cr_vars lhs {
					local `liste' = subinword("``liste''","`var'","``var''",.)
			}
		}

		if "`e(bias_correction)'" == "recursive mean correction" {
			tempvar s_mean
			gen `s_mean' = 0
			local r_varlist `lhs' `mg_vars' `cr_vars' `pooled_vars' 
			local r_varlist: list uniq r_varlist
			local r_varlist: list r_varlist - `constant'

			foreach var in `r_varlist' {
				by `idvar' (`tvar'), sort: replace `s_mean' = sum(`var'[_n-1]) / (`tvar'-1) if `touse'
				replace `s_mean' = 0 if `s_mean' == . 
				replace `var' = `var' - `s_mean'  
			}
			replace `s_mean' = 0
			sort `idvar' `tvar'
		}
		sum `idvar' if `touse' , meanonly
		local N_g = r(max)
		*get country list
		forvalues i = 1(1)`N_g' {
			local ctry_list `ctry_list' `i'
		}
		**partial out variables
		*create CR Lags
		if "`cr_vars'" != "" {
			tempvar cr_mean
			foreach var in `cr_vars' { 				
				by `tvar' , sort: egen double `cr_mean' = mean(`var') if `touse'
				forvalues lag=0(1)`cr_lags' {
					sort `idvar' `tvar'
					tempvar L`lag'_m_`var'
					gen double `L`lag'_m_`var'' = L`lag'.`cr_mean' if `touse'  
					local clist1  `clist1'  `L`lag'_m_`var'' 
				}
				drop `cr_mean' 
			}
			*noi disp "vars:`touse' `lhs' `pooled_vars' `mg_vars'"
			markout `touse' `lhs' `pooled_vars' `mg_vars'
			tempvar touse_ctry
			tempname mrk
			local mata_drop `mata_drop' `mrk'
			gen `touse_ctry' = 0
			sort `idvar' `tvar'	
			foreach ctry in `ctry_list' {
				qui replace `touse_ctry' =  1 if `touse'  & `ctry' == `idvar'
				*noi disp "country: `ctry': `lhs' `pooled_vars' mg: `mg_vars' - `clist1'"
				mata xtdcce_m_partialout("`lhs' `pooled_vars' `mg_vars'","`clist1'","`touse_ctry'",`mrk'=.)
				qui replace `touse_ctry' =  0
				
			}
			
		}
		*Markout again to drop missings from partialout. put e(sample) in place (not needed for mean group)
		markout `touse' `lhs' `pooled_vars' `mg_vars'		
		replace `touse' = `touse' * e(sample)

		**calculate coefficients
		tempname coeff xbc
		matrix `coeff' = e(bi)
		if "`se'" == "se" {
			matrix `coeff' = e(Vi)
			mata st_matrix("`coeff'",sqrt(diagonal(st_matrix("`coeff'")))')
			local coln : colnames e(Vi)
			matrix colnames `coeff' = `coln'
		}
		gen double `xbc' = 0 if `touse'
		local i = 1
		foreach var in `pooled_vars' {
			tempvar c_`var'
			local o_var = word("`o_pooled_vars'",`i')
			gen double `c_`var'' = `coeff'[1,colnumb(`coeff',"`o_var'")]
			local i = `i' + 1	
		}
		local i = 1
		foreach var in `mg_vars' {
			tempvar c_`var'
			gen double `c_`var'' = .
			local o_var = word("`o_mg_vars'",`i')
			foreach ctry in `ctry_list' {
				replace `c_`var'' = `coeff'[1,colnumb(`coeff',"`o_var'_`ctry'")] if `idvar' == `ctry' & `touse'
				*sum `c_`var''
			}
			local i = `i' + 1
		}
		local o_full `o_mg_vars' `o_pooled_vars'
		
		if "`e(lr)'" != "" {
			local cmd `e(cmdline)'
			gettoken 0 options: cmd , parse(",")
			
			
			**correct lr_vars list
			foreach var in `lr_vars' {
				local pos : list posof `"`var'"' in o_full
				local tmp = word("`mg_vars' `pooled_vars'",`pos')
				local lr_vars =  subinword("`lr_vars'","`var'","`tmp'",.)
			}
			
			if strmatch("`options'","*nodivide*") == 0 {
				gettoken first rest : lr_vars
				foreach var in `rest' {
					replace `c_`var'' = - `c_`var'' * `c_`first'' if `touse'
				}		
			}

		}		
	
		foreach var in `mg_vars' `pooled_vars' {
			replace `xbc' = `xbc' + `c_`var'' * `var'  if `touse'
		}
		
		if "`xb'" == "xb" | "`stdp'" == "stdp" {
			replace `newvar' = `xbc'   if `touse'
		}
		if "`residuals'" == "residuals" {
			replace `newvar' = `lhs' - `xbc' if `touse'
		}
		if "`coefficient'" == "coefficient" | "`se'" == "se" {
			drop `newvar'
			local i = 1
			foreach var in `pooled_vars' {
				local o_var = word("`o_pooled_vars'",`i')
				local o_var = strtoname("`o_var'")
				gen double `newvar'_`o_var' = `c_`var'' if `touse'
				local i = `i' + 1
			}
			local i = 1
			foreach var in `mg_vars' {
				local o_var = word("`o_mg_vars'",`i')
				local o_var = strtoname("`o_var'")
				gen double `newvar'_`o_var' = `c_`var'' if `touse'
				local i = `i' + 1
			}
		}
		if "`stdp'" == "stdp" {
			local v_order: colnames e(Vi)
			foreach var in `o_mg_vars' {
				foreach i in `ctry_list' { 
					local o_mg_vars_id `o_mg_vars_id' `var'`i'
				}			
			}
			local o_full_id `o_mg_vars_id' `o_pooled_vars'
			tempvar idt
			gen `idt' = _n
			preserve  
				foreach var in `mg_vars' {
					qui separate `var' if `touse' , by(`idvar')
					local mg_vars_id `mg_vars_id' `r(varlist)'
					recode `r(varlist)' (missing = 0) if `touse'	
				}
				foreach var in `v_order' {
					local pos : list posof `"`var'"' in o_full_id
					local tmp = word("`mg_vars_id' `pooled_vars'",`pos')
					local v_order_n `v_order_n' `tmp'
				}			
				
				tempname m_V m_x m_h
				putmata `m_x' = (`v_order_n') `idt' if `touse' , replace
				mata `m_V' = st_matrix("e(Vi)")
				mata `newvar' = `m_x'*`m_V'*`m_x''
				mata `newvar'  = sqrt(diagonal(`newvar'))
			restore
			drop `newvar'
			getmata `newvar' , id(`idt'=`idt')
			mata mata drop `m_V' `m_x' `newvar' `idt'
			
		}
		if "`partial'" == "partial" {
			drop `newvar'
			local o_list  `o_lhs' `o_pooled_vars' `o_mg_vars' 
			*noi disp "`o_list'"
			*noi disp "`lhs' `pooled_vars' `mg_vars' "
			local i = 1
			foreach var in `lhs' `pooled_vars' `mg_vars' {
				*Get current temp varname
				local tmp = word("`o_list'",`i')
				local tmp = subinstr("`tmp'",".","_",.)
				*noi disp "`tmp'"
				gen double `newvar'_`tmp' = `var'
				local i = `i' + 1
			}
		}
		capture drop ec
		capture rename `ec_save' ec
		tsset `d_idvar' `d_tvar'
	}
end

*** Partial Out Program
** quadcross automatically removes missing values and therefore only uses (and updates) entries without missing values
capture mata mata drop xtdcce_m_partialout()
mata:
	function xtdcce_m_partialout (  string scalar X2_n,
									string scalar X1_n, 
									string scalar touse,
									| real matrix rk)
	{
		real matrix X1
		real matrix X2
		real matrix to
		st_view(X2,.,tokens(X2_n),touse)
		st_view(X1,.,tokens(X1_n),touse)
		X1X1 = quadcross(X1,X1)
		X1X2 = quadcross(X1,X2)
		//Get Rank
		s = qrinv(X1X1,rk=.)		
		rk = (rk=rows(X1X1))
		rk = (rk,rows(X1X1))
		X2[.,.] = (X2 - X1*cholqrsolve(X1X1,X1X2))
	};
end

// Mata utility for sequential use of solvers
// Default is cholesky;
// if that fails, use QR;
// if overridden, use QR.
// By Mark Schaffer 2015
capture mata mata drop cholqrsolve()
mata:
	function cholqrsolve (  numeric matrix A,
							numeric matrix B,
						  | real scalar useqr)
	{
			if (args()==2) useqr = 0
			
			real matrix C

			if (!useqr) {
					C = cholsolve(A, B)
					if (C[1,1]==.) {
							C = qrsolve(A, B)
					}
			}
			else {
					C = qrsolve(A, B)
			}
			return(C)

	};
end


capture mata mata drop cholqrinv()
mata:
	function cholqrinv (  numeric matrix A,
						  | real scalar useqr)
	{
			if (args()==2) useqr = 0
			
			real matrix C

			if (!useqr) {
					C = cholinv(A)
					if (C[1,1]==.) {
							C = qrinv(A)
					}
			}
			else {
					C = qrinv(A)
			}
			return(C)

	};
end
