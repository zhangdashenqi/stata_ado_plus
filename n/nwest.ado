*! version 1.0.0  07jan1997  STB-39 sg72
program define nwest
	version 5.0

	if "`1'" == "," | "`1'" == "" {
		if "$S_E_cmd2" != "nwest" {
			local options "Level(integer 95) OR IRR"
			parse "`*'"   
			if "`irr'"!="" & "`or'"!="" {
			di in red "only one of irr and or may be specified"
				exit 198
			}
			DispCmd
			DispRes `level' 
			exit
		}
		else {
			error 301  
		}
	}
	local cmd "`1'"
	CheckCmd `cmd'
	mac shift
	local varlist	"req"
	local if	"opt"
	local in	"opt"
	local options	"LAG(integer 0) T(string) Level(integer 95)"
	local options	"`options' OR IRR FORCE *"
	parse "`*'"
	
	if `lag' < 0 {
		di in red "lag() must be nonnegative"
		exit 198
	}
	if "`t'" != "" {
		local targ "t(`t')"
	}
	if "`irr'"!="" & "`or'"!="" {
		di in red "only one of irr and or may be specified"
		exit 198
	}
	quietly {
		global X_lag = `lag'
		tempvar touse
		mark `touse' `if' `in'
		markout `touse' `varlist'
		if "$X_cmd" == "glm" {
			glm `varlist' if `touse', fam(binom) link(log)
		}
		else {
			$X_cmd `varlist' if `touse', `options'
		}
		tempvar xb grad wgt
		predict double `xb', index
		tempname beta vce
		mat `beta' = get(_b)
		mat `vce' = get(VCE)
		
		global X_vl : colnames(`beta')
		local n : word count $X_vl
		parse "$X_vl", parse(" ")
		if "``n''"=="_cons" {
			local `n' 
		}
		global X_tvl "`*'"
		GetFact `grad' `wgt' `xb'
		_newey `grad' `wgt' `touse', `targ' lag(`lag') `force'
		if "`or'" != "" {
			local earg "Odds Ratio"
		}
		if "`irr'" != "" {
			local earg "IRR"
		}
		noi DispRes `level' `earg'
	}
end

program define DispRes
	local level "`1'"
	local earg "`2'"

	noi DispCmd
	if "`earg'" != "" {
		local earg "eform(`earg')"
	}
	
	if "`level'" == "" {
		local level = $S_level
	}
	else {
		if `level' < 5 | `level' > 99 {
			local level 95
		}
	}
	mat mlout, level(`level') `earg'
end


program define CheckCmd
	local cmd = lower(trim("`1'"))
	local l = length("`cmd'")
	if "`1'" == substr("regress", 1, max(`l',3)) {
		global X_cmd "regress"
		exit
	}
	if "`1'" == substr("probit", 1, max(`l',3)) {
		global X_cmd "probit"
		exit
	}
	if "`1'" == substr("logit", 1, max(`l',3)) {
		global X_cmd "logit"
		exit
	}
	if "`1'" == substr("poisson", 1, max(`l',3)) {
		global X_cmd "poisson"
		exit
	}
	if "`1'" == substr("glm", 1, max(`l',3)) {
		global X_cmd "glm"
		exit
	}
	noi di in red "`cmd' is not supported"
	exit 198
end


program define DispCmd
	if "$X_cmd" == "regress" {
		global X_nobs = _result(1)
		qui test $X_tvl, min
		global X_mdf  = _result(3)
		global X_tdf  = _result(5)
		global X_F    = _result(6)
		#delimit ;
		di _n in gr
		"Regression with Newey-West standard errors"
		_col(53)
                "Number of obs  =" in yel %10.0f $X_nobs _n
                in gr "maximum lag : " in ye $X_lag
                _col(53)
                in gr
                "F(" in gr %3.0f $X_mdf in gr "," in gr %6.0f $X_tdf
                in gr ")" _col(68) "=" in ye %10.2f $X_F _n
                /* in gr "coefficients: " in ye "$S_E_type least squares" */
                _col(53) in gr "Prob > F       =    "
                in ye %6.4f fprob($X_mdf,$X_tdf,$X_F) _n ;
		#delimit cr
	}
	else {
		if "$X_cmd" == "logit" {
			local cmdarg "Logit"
		}
		if "$X_cmd" == "probit" {
			local cmdarg "Probit"
		}
		if "$X_cmd" == "poisson" {
			local cmdarg "Poisson"
		}
		if "$X_cmd" == "glm" {
			local cmdarg "GLM binomial-identity"
		}
		
		global X_nobs = _result(1)
		qui test $X_tvl, min
		global X_mdf  = _result(3)
		global X_F    = _result(6)
		#delimit ;
		di _n in gr
		"`cmdarg' with Newey-West standard errors"
		_col(53)
                "Number of obs  =" in yel %10.0f $X_nobs _n
                in gr "maximum lag : " in ye $X_lag
                _col(53)
                in gr
                "chi2(" in gr %3.0f $X_mdf 
                in gr ")" _col(68) "=" in ye %10.2f $X_F _n
                /* in gr "coefficients: " in ye "$S_E_type least squares" */
                _col(53) in gr "Prob > chi2    =    "
                in ye %6.4f chiprob($X_mdf,$X_F) _n ;
		#delimit cr
	}
end

program define GetFact
	local g  "`1'"
	local w  "`2'"
	local xb "`3'"

	if "$X_cmd" == "regress" {
		gen double `g' = 1
		gen double `w' = 1
	}

	if "$X_cmd" == "probit" {
		gen double `g' = normd(`xb')
		gen double `w' = normprob(`xb')*(1 - normprob(`xb'))
	}

	if "$X_cmd" == "logit" {
		gen double `g' = exp(`xb')/( (1+exp(`xb'))^2 )
		gen double `w' = `g'
	}

	if "$X_cmd" == "poisson" {
		if "$S_E_off" != "" {
			local arg "+ln($S_E_off)"
		}
		gen double `g' = exp(`xb'`arg')
		gen double `w' = exp(`xb'`arg')
	}

	if "$X_cmd" == "glm" {
		*gen double `g' = exp(`xb')*(1-exp(`xb'))
		*gen double `w' = exp(`xb')
		gen double `g' = 1
		gen double `w' = 1
	}
	
end
		
