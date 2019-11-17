*! version 2.0.0  09sep2003
program define gennbreg
	version 7
	syntax newvarname [if] [in] [, mu(string) xbeta(varname numeric) /*
	*/	Dispersion(string) alpha(string) delta(string) ADOonly]

/*  Function to generate random response from a Neg. Binomial regression
    with linear predictor -xbeta- and parameter alpha if disp(mean) or 
    parameter delta if disp(CONStant) */

	local y `varlist'
	Dispers, `dispersion'
	local dispersion `s(dispersion)'

	if "`mu'"!="" & "`xbeta'"!="" { 
		di as err "You may only specify one of mu() or xbeta()
		exit 198
	}

	tempvar exb
	if "`mu'" == "" {
		if "`xbeta'"!="" {
			qui gen `exb' = exp(`xbeta') `if' `in'
		}
		else {
			qui gen `exb' = 1.0 `if' `in'
		}
	}
	else {
		capture confirm number `mu'
		if _rc {
			confirm numeric variable `mu'
		}
		qui gen `exb' = `mu' `if' `in'
	}

	if "`dispersion'"=="mean" {
		if "`delta'"!="" {
			di as err "delta() not allowed with dispersion(mean)"
			exit 198
		}
	}
	else {
		if "`alpha'"!="" {
			di as err "alpha() not allowed with " _c
			di as err "dispersion(constant)"
			exit 198
		}
	}

	tempvar a b g

 	if "`dispersion'"=="mean" {
		if "`alpha'"=="" {
			local alpha 1.0
		}
		else {
			confirm number `alpha'
		}
		
		local oalpha = 1/`alpha'
		qui gen `b' = `exb'*`alpha' `if' `in'
		qui gengamma `g' `if' `in', alpha(`oalpha') beta(`b')
		qui genpoisson `y' `if' `in', mu(`g') `adoonly'
	}

	else {  /* `dispersion' == "constant" */
		if "`delta'"=="" {
			local delta 1.0
		}
		else {
			confirm number `delta'
		}
		
		qui gen `a' = `exb'/`delta' `if' `in'
		qui gengamma `g' `if' `in', alpha(`a') beta(`delta')
		qui genpoisson `y' `if' `in', mu(`g') `adoonly'
	}
end

program define Dispers, sclass
	sret clear
	syntax [, Mean Constant]
	if "`constant'"=="" {
		sret local dispersion "mean"
		exit
	}
	if "`mean'"!="" {
di as err "must choose either mean or constant for dispersion()"
		exit 198
	}
	sret local dispersion "constant"
end

