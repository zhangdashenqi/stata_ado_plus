*! version 3.0.0  09sep2003
program define genpoisson
	version 7
	syntax newvarname [if] [in] [, mu(string) xbeta(varname numeric) /*
			*/ ADOonly ]

/*  Function to generate random deviates from the poisson distribution, 
    or a poisson regression.
    Parameterization is such that E(X) = Var(X) = mu = exp(xbeta)*/

	local x `varlist'
	marksample touse, novarlist

	if "`mu'"!="" & "`xbeta'"!="" { 
		di as err "You may only specify one of mu() or xbeta()
		exit 198
	}

	tempvar mucons
	if "`mu'" == "" {
		if "`xbeta'"!="" {
			markout `touse' `xbeta'
			qui gen double `mucons' = exp(`xbeta') if `touse'
		}
		else {
			qui gen double `mucons' = 1.0 if `touse'
		}
	}
	else {
		capture confirm number `mu'
		if _rc {
			confirm numeric variable `mu'
			markout `touse' `mu'
		}
		qui gen double `mucons' = `mu' if `touse'
	}
	tempvar xp u 
	qui {
		gen double `u' = uniform() if `touse'
		gen double `xp' = 0 if `touse'
		if "`adoonly'" != "" {
			Randpois `xp' `mucons' `u' `touse'
		}
		else {
			capture plugin call _randpois /* 
				*/ `xp' `mucons' `u' if `touse'
			if _rc==199 {
				di as err "plugin not found: use adoonly option"
				exit 198
			}
		}
	}
	gen `typlist' `x' = `xp' if `touse'
end

capture program _randpois, plugin using("genpoisson.plugin")

program define Randpois          
	version 7
	args xp xm u touse   /* xp set to zero, u=uniform() */

        tempvar ds d1
	quietly {
		local i 0
        	gen double `d1' = exp(-`xm') if `touse'

		gen byte `ds' = (`u'>`d1') & `touse'
		count if `ds'

        	while r(N) > 0 {
                	replace `xp' = `xp' + 1 if `ds'
			local i = `i' + 1
			replace `d1' = `d1' + /*
			*/ exp(-`xm' + `i'*log(`xm') - lngamma(`i'+1)) if `ds'
			replace `ds' = (`u'>`d1') & `touse'
          		count if `ds'
        	}
	}
end

