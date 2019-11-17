*! version 1.1.0  10jan2002
program define gengamma
	version 7
	syntax newvarname [if] [in] [, alpha(string) beta(string) /*
	*/ gamma(string)]

/*  Function to generate random deviates from the gamma distribution.
    Parameterization is such that E(X) = alpha*beta, Var(X) = alpha*beta^2 
    When gamma specified, transforms to random deviates of the generalized
    gamma distribution */

	local x `varlist'

	if "`alpha'" == "" {
		local alpha = 1.0
	}
	else {
		capture confirm number `alpha'
		if _rc {
			confirm numeric variable `alpha'
		}
	}
	if "`beta'" == "" {
		local beta = 1.0
	}
	else {
		capture confirm number `beta'
		if _rc {
			confirm numeric variable `beta'
		}
	}

	if "`gamma'" == "" {
		local gamma = 1.0
	}
	else {
		capture confirm number `gamma'
		if _rc {
			confirm numeric variable `gamma'
		}
	}

	qui generate `typlist' `x' = invgammap(`alpha',uniform()) `if' `in'
 	qui replace `x' = `x'*`beta' `if' `in'
	qui replace `x' = `beta'*(`x'/`beta')^(1/`gamma') `if' `in'
	qui count if missing(`x')
	local cn = r(N)
	if `cn'>0 {
		di as txt "(`cn' missing values generated)"
	}
end
