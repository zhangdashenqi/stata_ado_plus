*! _gxtile version 1.2 UK 08 Mai 2006
* categorizes exp by its quantiles - byable

* 1.2: Bug: Opt percentiles were treated incorrectely after implement. of option nq
*	   Allows By-Variables that are strings
* 1.1: Bug: weights are treated incorectelly in version 1.0. -> fixed
*     New option nquantiles() implemented	         
* 1.0: initial version
program _gxtile, byable(onecall) sortpreserve
	version 8.2
        gettoken type 0 : 0
        gettoken h    0 : 0 
        gettoken eqs  0 : 0

	syntax varname(numeric) [if] [in] [, ///
	  Percentiles(string) ///
	  Nquantiles(string) ///
	  Weights(string) ALTdef by(varlist) ]

	marksample touse 
	
	// Error Checks

	if "`altdef'" ~= "" & "`weights'" ~= "" {
		di as error "weights are not allowed with altdef"
		exit 111
	}
	
	if "`percentiles'" != "" & "`nquantiles'" != "" {
		di as error "do not specify percentiles and nquantiles"
		exit 198
	}

	// Default Settings etc.

	if "`weights'" ~= "" {
		local weight "[aw = `weights']"
	}

	if "`percentiles'" != "" {
		local percnum "`percentiles'"
	}
	else if "`nquantiles'" != "" {
		local perc = 100/`nquantiles'
		local first = `perc'
		local step = `perc'
		local last = 100-`perc'
		local percnum "`first'(`step')`last'"
	}

	if "`nquantiles'" == "" & "`percentiles'" == "" {
		local percnum 50
	}

	quietly {
	
		gen `type' `h' = .

		// Without by

		if "`by'"=="" {
			local i 1
			_pctile `varlist' `weight' if `touse', percentiles(`percnum') `altdef'
			foreach p of numlist `percnum' {
				if `i' == 1 {
					replace `h' = `i' if `varlist' <= r(r`i') & `touse'
				}
				replace `h' = `++i' if `varlist' > r(r`--i')  & `touse'
				local i = `i' + 1
			}
			exit
		}

		// With by
		tempvar byvar
		by `touse' `by', sort: gen `byvar' = 1 if _n==1 & `touse'
		by `touse' (`by'): replace `byvar' = sum(`byvar')
		
		levels `byvar', local(K)
		foreach k of local K {
			local i 1
			_pctile `varlist' `weight' if `byvar' == `k' & `touse' , percentiles(`percnum') `altdef'
			foreach p of numlist `percnum' {
				if `i' == 1 {
					replace `h' = `i' if `varlist' <= r(r`i') & `byvar' == `k' & `touse'
				}
				replace `h' = `++i' if `varlist' > r(r`--i')  & `byvar' == `k' & `touse'
				local i = `i' + 1
			}
		}
	}
	end
	exit
	
