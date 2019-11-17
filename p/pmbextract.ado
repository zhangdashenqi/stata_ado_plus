*! v 1.0.2 PR 20jan2009
program define pmbextract, rclass
version 8
syntax [if] [in] , [CLEAR Centiles(numlist >0 <100) Mean Sd N MAd Dsq /*
 */ TRunc(real 0) Ref(int 1)]
* exit silently if clear not issued
if "`clear'"=="" {
	exit
}
local prog: char _dta[pmb_data]
local values: char _dta[pmb_v]
local nxval: word count `values'
local xvar: char _dta[pmb_x]
if "`values'"=="" | "`xvar'"=="" {
	di as err "data has invalid characteristics char[_dta]"
	exit 198
}
if `trunc'<0 | `trunc'>=0.5 {
	di as err "invalid trunc()"
	exit 198
}
local f: char _dta[pmb_f]
local sumstat=("`centiles'`mean'`sd'`n'"!="")
local stabil=("`mad'`dsq'"!="")
if (`sumstat'*`stabil')==1 {
	di as err "incompatible options chosen"
	exit 198
}
if `stabil' {
	if `ref'<1 | `ref'>_N {
		di as err "invalid ref(), must be between 1 and " _N
		exit 198
	}
}
quietly {
	preserve
	marksample touse
	if !`sumstat' & !`stabil' {	/* save fitted values only */
		drop if !`touse'
		drop `touse'
		// Determine number of rows (bootstrap samples + 1) in file
		count
		local nrows = r(N)
		xpose, clear
		* Check compatibility between values and #rows of file
		count
		if r(N)!=`nxval' {
			noi di as err "wrong number of observations" /*
			 */ "---expecting `nxval'"
			exit 198
		}
		// Rename variables to v0,...,vB if data are from mfpboot
		if "`prog'" == "mfpboot" {
			forvalues i = 1 / `nrows' {
				local im1 = `i' - 1
				rename v`i' v`im1'
			}
		}
		gen `xvar' = .
		cap drop _freq
		gen long _freq = .
		lab var _freq "Frequencies of `xvar'"
		forvalues i = 1 / `nxval' {
			local v: word `i' of `values'
			replace `xvar' = `v' in `i'
			local v: word `i' of `f'
			replace _freq = `v' in `i'
		}
	}
	else if `sumstat' {
		forvalues i = 1 / `nxval' {
			if "`mean'`sd'`n'" != "" {
				sum `xvar'`i'
				if "`mean'" != "" {
					local m`i' = r(mean)
				}
				if "`sd'" != "" {	/* sqrt of MLE of variance */
					local s`i' = sqrt(r(Var) * (1 - 1 / r(N)))
				}
			}
			if "`centiles'"!="" {
				centile `xvar'`i', cent(`centiles')
				local nc = r(n_cent)
				forvalues j = 1 / `nc' {
					local c`i'`j' = r(c_`j')
				}
			}
		}
		* Save summary stats
		drop _all
		set obs `nxval'
		gen `xvar' = .
		if "`mean'"!="" {
			gen _mean = .
			lab var _mean "Mean for `xvar'"
		}
		if "`sd'" != "" {
			gen _sd = .
			lab var _sd "SD for `xvar'"
		}
		if "`n'" != "" {
			gen long _freq = .
			lab var _freq "Frequencies of `xvar'"
		}
		if "`centiles'" != "" {
			forvalues j = 1 / `nc' {
				local cj: word `j' of `centiles'
				gen _c`j' = .
				lab var _c`j' "`cj' centile for `xvar'"
			}
		}
		forvalues i = 1 / `nxval' {
			local v: word `i' of `values'
			replace `xvar' = `v' in `i'
			if "`mean'" != "" {
				replace _mean = `m`i'' in `i'
			}
			if "`sd'"!="" {
				replace _sd = `s`i'' in `i'
			}
			if "`n'"!="" {
				local v: word `i' of `f'
				replace _freq = `v' in `i'
			}
			if "`centiles'"!="" {
				forvalues j = 1 / `nc' {
					replace _c`j' = `c`i'`j'' in `i'
				}
			}
		}
	}
	else if `stabil' {	/* code from pbxsum.ado */
		if "`mad'" != "" {
			cap drop _mad
			gen double _mad = 0
		}
		if "`dsq'" != "" {
			cap drop _dsq
			gen double _dsq = 0
		}
		tempname sumwt sumwt2 ntrunc n
		scalar `sumwt' = 0
		local f: char _dta[pmb_f]
		forvalues i = 1 / `nxval' {
			local fi: word `i' of `f'
			scalar `sumwt' = `sumwt' + `fi'
		}
		scalar `n' = `sumwt'
		scalar `ntrunc' = round(`n'*`trunc') // `ntrunc' could be 0
		scalar `sumwt' = 0
		scalar `sumwt2' = 0
		forvalues i = 1 / `nxval' {
			local fi: word `i' of `f'
			scalar `sumwt' = `sumwt' + `fi'
			if `sumwt' > `ntrunc' & `sumwt' <= (`n' - `ntrunc') {
				scalar `sumwt2' = `sumwt2' + `fi'
				replace `xvar'`i' = abs(`xvar'`i' - `xvar'`i'[`ref']) if (_n != `ref') & `touse'
				if "`mad'" != "" {
					replace _mad = _mad + `fi' * `xvar'`i' if (_n != `ref') & `touse'
				}
				if "`dsq'" != "" {
					replace _dsq = _dsq + `fi' * `xvar'`i'^2 if (_n != `ref') & `touse'
				}
			}
			else replace `xvar'`i' = . if (_n!=`ref') & `touse'
		}
		if "`mad'" != "" {
			replace _mad = _mad / `sumwt2'
			lab var _mad "Mean absolute deviation for `xvar' curve"
		}
		if "`dsq'" != "" {
			replace _dsq = _dsq / `sumwt2'
			lab var _dsq "Mean square deviation for `xvar' curve"
		}
		if "`mad'" != "" {
			local keep _mad
		}
		if "`dsq'" != "" {
			local keep `keep' _dsq
		}
		keep `keep'
	}
}
restore, not
di _n as text "Data now comprise " as res `nxval' ///
 as text " observations for " as res "`xvar'" as text "."
return local x `xvar'
end
