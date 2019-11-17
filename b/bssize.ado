*! version 0.0.1 20040304

/*
bssize initial , [ tau(real 0.05) pdb(real 5) pctt(real -1) ]

bssize refine using/  

bssize analyze using/ , [ tau(real 0) pdb(real 0) pctt(real -1)<-Not impl.
	APPend(string asis) ]

bssize cleanup
*/


program bssize

	gettoken key 0 : 0, parse(" ,")

	if `"`key'"' == "initial" {
		Initial `0'
	}
	else if `"`key'"' == "refine" {
		Refine `0'
	}
	else if `"`key'"' == "analyze" {
		Analyze `0'
	}
	else if `"`key'"' == "cleanup" {
		Cleanup `0'
	}
	else {
		di as error "bssize: `key' not a valid suboption"
		exit 198
	}
	
end



program Initial, rclass

	syntax [, Tau(real 0.05) Pdb(real 5) pctt(real -1) ]
	
	if `tau' <= 0 | `tau' >= 1 | `pdb' <= 0 | `pdb' >= 100 {
di as error "tau must be between 0 and 1, and pdb must be between 1 and 100"
		exit 198
	}
	
	local se
	if `pctt' < 0 {
		local se "se"
	}
	else if `pctt' < 1 | `pctt' > 99.999 {
		di as error "pctt must be between 1 and 99.999"
		exit 198
	}
	else {
		local alpha = (100 - `pctt') / 200	// (1-2alpha) CI
		// We do this so we can write alpha = a1/a2 easily:
		local alpha = int(`alpha'*1000) / 1000
	}
	
	bssize cleanup
	
	tempname zsq 
	scalar `zsq' = invnorm(1 - `tau'/2)^2
	if "`se'" != "" {
		local b = int(10000*`zsq'*0.5 / `pdb'^2)
	}
	else {
		tempname za phisq w h
		GetA1A2 `alpha'
		local a1 `r(a1)'
		local a2 `r(a2)'
		scalar `za' = invnorm(1 - `alpha')
		scalar `phisq' = normden(`za')^2
		scalar `w' = ( `alpha'*(1-`alpha') ) / (`za'^2 * `phisq')
		scalar `h' = int( (10000*`zsq'*`w') / (`pdb'^2*`a2') )
		local b = `a2'*`h' - 1
	}
	
	di
	if "`se'" != "" {
di as text "Initial estimate of bootstrap size needed for standard errors"
	}
	else {
di as text "Initial estimate of bootstrap size needed for percentile-t CI's"
	}
	di as text "{hline 63}"
	if "`se'" == "" {
		di as text "Confidence interval size  " ///
			_col(58) as result %6.3f (100*(1 - 2*`alpha'))
	}
	di as text "Percent deviation from Binfinity (pdb)    " ///
		_col(58) as result %6.3f `pdb'
	di as text "Probability (1 - tau)   " ///
		_col(58) as result %6.3f (1 - `tau')
	di as text "{hline 63}"
	di as text "Required size (B1)  " _col(58) ///
		as result %6.0f `b'
	
	global BSS_pdb = `pdb'
	global BSS_tau = `tau'
	if "`se'" != "" {
		global BSS_type "se"
	}
	else {
		global BSS_type "pctt"
		global BSS_alpha = `alpha'
		global BSS_a1 = `a1'
		global BSS_a2 = `a2'
		global BSS_pctt = 100*(1 - 2*`alpha')
	}
	global BSS_B1 = `b'
	global BSS_set = "yes"
	
	return scalar B1 = `b'
	
end



program define Refine, rclass

	syntax using/  

	if "$BSS_set" != "yes" {
			di as error ///
				"you must first use " as text "bssize initial"
			exit 198
	}

	preserve
	capture use `"`using'"' , clear
	if _rc != 0 {
		di as error "could not open bootstrap data file"
		exit _rc
	}
	qui count
	loc cursize = r(N)
	
	// Does the dataset have any b_* or t_* vars?
	cap ds b_*
	if _rc != 0 {
		cap ds t_*
		if _rc != 0 {
			di as error "no valid variables found"
			exit 498
		}
	}
	
	local maket
	if "$BSS_type" == "pctt" {
		cap ds t_*
		if _rc == 0 {
			local maket "no"
			qui ds t_*
			local stats `r(varlist)'
			local stats : subinstr local stats "t_" "", all
			foreach i of local stats {
				cap confirm numeric variable t_`i'
				if _rc != 0 {
					di as error ///
					"nonnumeric t_ variable for `i'"
					exit 498
				}
			}
		}
		else {
			local maket "yes"
			qui ds b_*
			local stats `r(varlist)'
			local stats : subinstr local stats "b_" "", all
			foreach i of local stats {
				cap confirm numeric variable b_`i' se_`i'
				if _rc != 0 {
					di as error ///
					"nonnumeric b_ or se_ variable for `i'"
					exit 498
				}
			}	
		}
	}
	else {
		qui ds b_*
		local stats `r(varlist)'
		local stats : subinstr local stats "b_" "", all
		foreach i of local stats {
			cap confirm numeric variable b_`i'
			if _rc != 0 {
				di as error ///
					"nonnumeric b_ variable for `i'"
				exit 498
			}
		}
	}
	
	local tau = $BSS_tau
	local pdb = $BSS_pdb

	di
	if "$BSS_type" == "pctt" {
	        di as text ///
	"Refined estimate of bootstrap size needed for percentile-t CI's"
	}
	else {
		di as text ///
		"Refined estimate of bootstrap size needed for standard errors"
	}
        di as text "{hline 63}"
	if "$BSS_type" == "pctt" {
		di as text "Confidence interval size  " ///
			_col(58) as result %6.3f (100*(1 - 2*$BSS_alpha))
	}
        di as text "Percent deviation from Binfinity (pdb) " ///
                _col(58) as result %6.3f `pdb'
        di as text "Probability (1 - tau)   " ///
                _col(58) as result %6.3f (1 - `tau')
	di as text "{hline 13}{c TT}{hline 49}"
	di as text "   Parameter {c |}" _col(18) "Initial Size" ///
		_col(35) "Current Size" ///
		_col(52) "Revised Size"
        di as text "{hline 13}{c +}{hline 49}"
	
	tempname zsq b gamma omega maxb 
	tempvar t
	if "`maket'" == "yes" {
		qui gen double `t' = .
	}
	scalar `maxb' = 0
	scalar `zsq' = invnorm(1 - `tau'/2)^2
	foreach var of local stats {
		if "$BSS_type" == "se" {
			qui summ b_`var', d
			scalar `gamma' = r(kurtosis)*r(N)/(r(N)-1) - 3
			scalar `omega' = (2 + `gamma') / 4 
			scalar `b' = int(10000*`zsq'*`omega' / `pdb'^2)
		}
		else {
			if "`maket'" == "yes" {
				local x  : char b_`var'[observed]
				if ( real("`x'") >= . ) {
					di as error ///
				"obesrved characteristic for b_`var' not found"
					exit 498
				}
				qui replace `t' = (b_`var'-`x') / se_`var'
				GetBpctt `t'
			}
			else {
				GetBpctt t_`var'
			}
			scalar `b' = r(b)
			
		}
		if `b' > `maxb' {
			scalar `maxb' = `b'
		}
		local abname = abbrev("`var'", 12)
		di as text "{ralign 12:`abname'} {c |}" ///
			as res _col(23) %7.0f $BSS_B1 ///
			as res _col(40) %7.0f `cursize' ///
			as res _col(57) %7.0f `b'
	}
	di as text "{hline 13}{c BT}{hline 49}"
	di as text "Maximum revised size" as res _col(57) %7.0f `maxb'
	di as text "Additional replications needed " ///
		as res _col(57) %7.0f max(0,(`maxb' - `cursize'))
		
	
end



program define Analyze

	syntax using/ , [ tau(real 0) pdb(real 0) pctt(real -1) ///
		APPend(string asis) ]
	
	if `tau' != 0 & `pdb' != 0 {
		di as error "cannot specify both tau() and pdb()"
		exit 198
	}
	
	local se
	if `pctt' < 0 {
		local se "se"
	}
	else {
		di as text "bssize analyze" as error ///
			" not implemented for percentile-t confidence intervals"
	}
	
        if `tau' == 0 & (`pdb' <= 0 | `pdb' >= 100) {
	        di as error "pdb must be between 1 and 100"
		exit 198
	}
	if `pdb' == 0 & (`tau' <= 0 | `tau' >= 1) {
		di as error "tau must be between 0 and 1"
		exit 198
	}
	
	preserve
	capture use `"`using'"', clear
	if _rc != 0 {
		di as error "could not open bootstrap data file"
		exit _rc
	}
	if `"`append'"' != "" {
		capture append using `"`append'"'
		if _rc != 0 {
di as error "could not append second bootstrap data file"
			exit _rc
		}
	}
	
	
	
	// Does the dataset have any b_* vars?
	cap ds b_*
	if _rc != 0 {
		di as error "no valid variables found"
		exit 498
	}
	
	if `tau' != 0 & "`se'" == "se" {
		AnaltauSE `tau' `"`stats'"'
		exit
	}
	
	if `pdb' != 0 & "`se'" == "se" {
		AnalpdbSE `pdb' `"`stats'"'
		exit
	}
	if `pdb' == 0 & `tau' == 0 & "`se'" == "se" {
		di as error "you must specify either tau() or pdb()"
		exit 198
	}

end


program define AnaltauSE

	args tau stats
	tempname B omega pdb z maxpdb gamma
	qui count
	scalar `B' = r(N)
	di
	di as text "Analysis of bootstrap results for standard errors"
	di as text "{hline 63}"
	di as text "Probability (1 - tau)" ///
		_col(58) as result %5.3f (1 - `tau')
	di as text "{hline 13}{c TT}{hline 49}"
	di as text "   Parameter {c |}" _col(28) "Final Size" ///
		_col(44) "Pct. Deviation (pdb)"
	di as text "{hline 13}{c +}{hline 49}"
	scalar `maxpdb' = 0
	foreach var of varlist b_* {
		qui summ `var', d
		scalar `gamma' = r(kurtosis)*r(N)/(r(N)-1) - 3
		scalar `omega' = (2 + `gamma') / 4                      
		scalar `z' = invnorm(1 - `tau'/2)
		scalar `pdb' = 100 * `z' * sqrt( `omega' / `B')
		if `pdb' > `maxpdb' {
			scalar `maxpdb' = `pdb'
		}
		local abname = abbrev("`var'", 12)
		di as text "{ralign 12:`abname'} {c |}" ///
			_col(31) as result %7.0f `B' ///
			_col(58) as result %6.3f `pdb'
	}
	di as text "{hline 13}{c BT}{hline 49}"
	di as text "Maximum percent deviation (pdb) " ///
			_col(58) as result %6.3f `maxpdb'
	
end



program define AnalpdbSE

	args pdb stats
	tempname B omega tau maxtau max1mtau gamma
	qui count
	scalar `B' = r(N)
	scalar `maxtau' = 0
	scalar `max1mtau' = 0
	di
	di as text "Analysis of bootstrap results for standard errors"
	di as text "{hline 63}"
	di as text "Percent deviation (pdb) " ///
		_col(58) as result %6.3f `pdb'
	di as text "{hline 13}{c TT}{hline 49}"
	di as text "   Parameter {c |}" _col(19) "Final Size" ///
		_col(44) "tau" _col(57) "1 - tau"
	di as text "{hline 13}{c +}{hline 49}"
	foreach var of varlist b_* {
		qui summ `var', d
		scalar `gamma' = r(kurtosis)*r(N)/(r(N)-1) - 3
		scalar `omega' = (2 + `gamma') / 4                      	
		scalar `tau' = 2*(1 - norm(`pdb'*sqrt(`B'/`omega')/100))
		if `tau' > `maxtau' {
			scalar `maxtau' = `tau'
		}
		if (1-`tau') > `max1mtau' {
			scalar `max1mtau' = (1 - `tau')
		}
		local abname = abbrev("`var'", 12)
		di as text "{ralign 12:`abname'} {c |}" ///
			_col(22) as result %7.0f `B' ///
			_col(41) as result %6.3f `tau' ///
			_col(58) as result %6.3f (1-`tau')
	}
	di as text "{hline 13}{c BT}{hline 49}"
	di as text "Maximum" _col(42) as result %5.3f `maxtau' ///
		_col(58) as result %6.3f `max1mtau'	
	
end



program define GetA1A2, rclass

	args alpha
	
	scalar a1 = `alpha'*1000
	scalar a2 = 1000
	forv j = `=a1'(-1)2 {
		if (mod(a1, `j') == 0 & mod(a2, `j') == 0) {
			scalar a1 = a1 / `j'
			scalar a2 = a2 / `j'
		}
	}
	
	return scalar a1 = a1
	return scalar a2 = a2
	
end



program define GetBpctt, rclass sortpreserve

	args t
	
	qui count if `t' < .
	local B = r(N)
	sort `t'
	
	tempname calpha gbi teta tetamm tetapm omega1ma omegaa zsq zsq1ma2 z1ma
	// 1-alpha centile
	scalar `z1ma' = invnorm(1 - $BSS_alpha)
	scalar `zsq1ma2' = (invnorm(1 - $BSS_alpha/2))^2
	scalar `calpha' = ( (1.5*`zsq1ma2'*(normden(`z1ma'))^2) / ///
			    (2*`zsq1ma2' + 1) ) ^ (1/3)
	local eta = (`B'+1)*(1 - $BSS_alpha)
	local mb = int(`calpha'*`B'^(2/3))
	scalar `teta' = `t'[`eta']
	scalar `tetamm' = `t'[(`eta'-`mb')]
	scalar `tetapm' = `t'[(`eta'+`mb')]
	scalar `gbi' = `B' / (2*`mb') * (`tetapm' - `tetamm')
	scalar `omega1ma' = ( $BSS_alpha * (1 - $BSS_alpha) * `gbi'^2 ) / ///
				`teta'^2
	scalar `zsq' = invnorm(1 - $BSS_tau/2)^2
	local h = int( (10000*`zsq'*`omega1ma') / ///
			(($BSS_pdb)^2 * $BSS_a2) )
	local b1 = $BSS_a2*`h' - 1


	// alpha centile
	local eta = (`B'+1)*($BSS_alpha)
	scalar `teta' = `t'[`eta']
	scalar `tetamm' = `t'[(`eta'-`mb')]
	scalar `tetapm' = `t'[(`eta'+`mb')]
	scalar `gbi' = `B' / (2*`mb') * (`tetapm' - `tetamm')
	scalar `omegaa' = ( $BSS_alpha * (1 - $BSS_alpha) * `gbi'^2 ) / ///
				`teta'^2
	local h = int( (10000*`zsq'*`omegaa') / ///
			(($BSS_pdb)^2 * $BSS_a2) )
	local b2 = $BSS_a2*`h' - 1

	local b = `b1'
	if `b2' > `b1' {
		local b = `b2'
	}
	
	return scalar b = `b'

	
end


program define Cleanup

	cap macro drop BSS_pdb
	cap macro drop BSS_tau
	cap macro drop BSS_type
	cap macro drop BSS_type
	cap macro drop BSS_alpha
	cap macro drop BSS_a1
	cap macro drop BSS_a2
	cap macro drop BSS_pctt
	cap macro drop BSS_B1
	cap macro drop BSS_set
	
end

