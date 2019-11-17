*! version 1.0.0  07jan2010
program mibeta, eclass
	version 11
	syntax [anything(everything name=rhs)] [aw fw iw pw]	  ///
				[, 	FISHERZ		 	  ///
					NOCOEF 	  		  ///
					MIOPTS(string asis)	  ///
					*			  /// <regopts>
				]
	if ("`weight'"!="") {
		local rhs `rhs' [`weight'`exp']
	}
	if ("`fisherz'"=="") {
		local original original
	}
	if ("`nocoef'"!="") {
		local nocoef qui
	}
	// check if -saving()- is already specified
	_chk_saving, `miopts'
	local fname    `"`s(filename)'"'
	if (`"`fname'"')=="" {
		tempfile miestfile
		local saving saving(`miestfile')
	}
	else {
		local miestfile `"`fname'"'
	}
	//obtain MI estimates and save indiv. estimation results
	cap `nocoef' noi mi est, `saving' `miopts': regress `rhs', `options'
	if _rc {
		exit _rc
	}
	tempname esthold
	_estimates hold `esthold', copy

	// save completed-data beta and R2 estimates as variables
	local M = e(M_mi)
	mata: st_local("p",strofreal(cols(st_matrix("e(b_mi)"))))
	local cols : colnames e(b_mi)
	local pos : list posof "_cons" in cols
	if `pos'>0 {
		local p = `p'-1
	}
	tempname Beta r2
	mat `Beta' = J(`M',`p',0)
	mat `r2' = J(`M',2,.)
	forvalues i=1/`M' {
		qui estimates use `miestfile', number(`i')
		mat `r2'[`i',1] = e(r2)
		mat `r2'[`i',2] = e(r2_a)
		forvalues j=1/`p' {
			qui _ms_display, el(`j')
			mat `Beta'[`i',`j'] = r(beta)
		}
	}
	preserve
	qui {
		clear
		svmat double `r2', n(r2_)
		svmat double `Beta', n(beta)
	}
	_estimates unhold `esthold'
	// compute and display descriptive stats over imputations
	di
	di as txt "Standardized coefficients and R-squared"
	di as txt "Summary statistics over `M' imputations"
	di
	if ("`original'"=="") {
		local star *
	}
	di as txt _col(14) "{c |}" _col(22) "mean`star'" 	///
				   _col(33) "min"	///
				   _col(44) "p25"	///
				   _col(52) "median"	///
				   _col(66) "p75"	///
				   _col(76) "max"
	di as txt "{hline 13}{c +}{hline 64}"
	forvalues j=1/`p' {
		_ms_element_info, el(`j') matrix(e(b_mi))
		if ("`r(type)'"!="variable" & r(first)) {
			local first first
		}
		if (`"`r(note)'"'=="(base)") {
			continue
		}
		if (`"`r(note)'"'!="") {
			_ms_display, el(`j') matrix(e(b_mi)) `first'
			di as res `"`r(note)'"'
			local first
		}
		else {
			_ms_display, el(`j') matrix(e(b_mi)) `first'
			_di_stats beta`j', `original'
			local first
		}
	}
	di as txt "{hline 13}{c +}{hline 64}"
	di as txt _col(5) "R-square {c |}" _c
	_di_stats r2_1, `original' sqrt
	di as txt _col(1) "Adj R-square {c |}" _c
	_di_stats r2_2, `original' sqrt
	di as txt "{hline 13}{c BT}{hline 64}"
	if ("`original'"=="") {
		di as txt "* based on Fisher's z transformation"
	}
	restore
end

program _chk_saving
	syntax [, SAVing(string asis) * ]
	if (`"`saving'"'!="") {
		// return filename in s(filename)
		_prefix_saving `saving'
	}
end

program _di_stats
	syntax varname(numeric) [, original SQRT ]
	local var `varlist'

	tempname m
	if ("`original'"!="") {
		qui summ `var', meanonly
		scalar `m' = r(mean)
	}
	else { //compute mean on Fisher's z scale and transform back
		tempvar x
		if ("`sqrt'"!="") {
			qui gen double `x'=atanh(sqrt(`var'))
			qui summ `x', meanonly
			scalar `m' = (tanh(r(mean)))^2
		}
		else {
			qui gen double `x'=atanh(`var')
			qui summ `x', meanonly
			scalar `m' = tanh(r(mean))
		}
	}
	di as res _col(17) %9.0g `m' _c
	qui summ `var', detail
	di as res "  " %8.3g r(min)	///
		  "  " %9.0g r(p25)	///
		  "  " %9.0g r(p50)	///
		  "  " %9.0g r(p75)	///
		  "  " %8.3g r(max)
end
