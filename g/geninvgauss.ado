*! version 1.0.0  05sep2001
program define geninvgauss
	version 7
	syntax newvarname [if] [in] [, mu(string) lambda(string)]

/*  Function to generate random deviates from the IG distribution.
    Parameterization is such that E(X) = mu, Var(X) = mu^3/lambda */

	local x `varlist'

	if "`mu'" == "" {
		local mu = 1.0
	}
	else {
		capture confirm number `mu'
		if _rc {
			confirm numeric variable `mu'
		}
	}
	if "`lambda'" == "" {
		local lambda = 1.0
	}
	else {
		capture confirm number `lambda'
		if _rc {
			confirm numeric variable `lambda'
		}
	}
	
	qui generate `typlist' `x' = invchi2(1,uniform()) `if' `in'
	qui replace `x' = `mu'/(2*`lambda') * (2*`lambda' + /*
		*/ `mu'*`x' - sqrt(4*`lambda'*`mu'*`x' + /*
		*/ `mu'^2*`x'^2)) `if' `in'
	qui replace `x' = cond(uniform()<`mu'/(`mu'+`x'), `x', `mu'^2/`x') /*
		*/ `if' `in'
	qui count if missing(`x')
	local cn = r(N)
	if `cn'>0 {
		di as txt "(`cn' missing values generated)"
	}
end

