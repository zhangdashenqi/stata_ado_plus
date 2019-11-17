program define pbalchk, rclass

*! $Revision: 1.8 $
*! Author:  Mark Lunt
*! Date:    March 29, 2012 @ 10:44:20

version 8.2

	syntax varlist [if] [in] [,STRATA(varlist min=1 max=1)    ///
			Wt(varlist min=1 max=1)        ///
			f p mahal                      ///
			metric(namelist min=1 max=1)   ///
			beta(namelist min=1 max=1)     ///
			diag sqrt                      ///
			XIPrefix(namelist min=1 max=1) ///
			graph eform noSTandardize      ///  
			]

	// TODO
	// parametric vs non-parametric: difficult for weighted data
	// Use "correct" covariance matrix for standardised differences
	// Modularize to enable bits to be cut out
	// Order option for table: store results in a file
	//                         sort file
  //                         print results
	
	noi di

	// Handle parameters
	tokenize `varlist'
	local treat `1'
	macro shift
	local vars  `*'

  // Check that the command was valid, bail if it wasn't
  qui tab `treat'
  local levels = r(r)
  if `levels' > 2 {
    di as error "The first variable in the varlist must be a dichotomous exposure variable"
    exit  
  }

  if "`f'`p'" == "fp" {
    di as error "You cannot give both f and p as options, only one."
    exit
  }

	if "`xiprefix'" == "" {
		local xiprefix _I
	}
	local xiplen = length("`xiprefix'")

  if "`beta'" != "" {
    capture confirm matrix `beta'
    if _rc != 0 {
      noi di as error "Unable to find matrix `beta'"
      exit
    }
    local bnames : colnames `beta'
    local bnnames
    foreach var in `bnames' {
      if regexm("`var'", "^`xiprefix'") {
        di "Found one"
        local var = regexr("`var'", "^`xiprefix'", "_C")
      }
      local bnnames `bnnames' `var'
    }
    matrix colnames `beta' = `bnnames'
  }
  else {
    if "`eform'" != "" {
      noi di as error "The option eform makes no sense unless the option beta is also used."
      exit
    }
  }
	// Handle options

	// sqrt implies mahal

	if "`sqrt'" != "" & "`mahal'" == "" {
		local mahal mahal
	}

	if "`wt'" != "" {
		local pwtexp [pw=`wt']
		local iwtexp [iw=`wt']
	}

	if "`strata'" ~= "" {
		quietly xi i.`strata', prefix(_S)
		local istrata _S`strata'_*
	}

	unab nvars : `vars'
	local nvars : list uniq nvars
	local k : word count `nvars'

	foreach var of varlist `nvars' {
		if substr("`var'",1,2) == ("`xiprefix'") {
			local cvars `cvars' `var'
			local croot : subinstr local var "`xiprefix'" ""
			local croot = regexr("`croot'", "_[0-9]+$", "")
			local croots `croots' `croot'
		}
	}

	local croots : list uniq croots
	if "`cvars'" ~= "" {
		foreach var of varlist `cvars' {
			local nvars : subinstr local nvars "`var'" "", word
		}

		foreach r in `croots' {
			local icroots `icroots' i.`r'
		}
		xi `icroots', prefix(_C) noomit
		unab cvars : _C*

		foreach var in `vars' {
			if substr("`var'", 1, `xiplen') == "`xiprefix'" {
				local nvar = substr("`var'", 3, .)
				local var _C`nvar'
			}
			local tvars `tvars' `var'
		}
		local vars `tvars'
	}
  
	marksample touse

	// Check and tabulate balancing
	quietly {
		// Get mean and covariance matrices in treated
		tempname meantreat meanuntreat meandiff tempmat var covar 
		tempname umeantreat umeanuntreat umeandiff ucovar umetric wmetric
		tempname wbeta scovar ssd ussd smeandiff usmeandiff ssmeandiff ussmeandiff
    tempname fmat pmat bmat tmeandiff ucovart ucovaru
		
		covwt `vars' if `touse' & `treat' == 1
		matrix `umeantreat' = r(mean)
		matrix `ucovart' = r(covar)
		
		covwt `vars' if `touse' & `treat' == 1 `pwtexp'
		matrix `meantreat' = r(mean)
		matrix `covar' = r(covar)
    
		covwt `vars' if `touse' & `treat' == 0
		matrix `umeanuntreat' = r(mean)
		matrix `ucovaru' = r(covar)
    matrix `ucovar' = 0.5*(`ucovaru' + `ucovart')
    
		covwt `vars' if `touse' & `treat' == 0 `pwtexp'
		matrix `meanuntreat' = r(mean)

		matrix `meandiff' = `meantreat' - `meanuntreat'
		matrix `umeandiff' = `umeantreat' - `umeanuntreat'

		matrix `wmetric' = syminv(`covar')
		matrix `umetric' = syminv(`ucovar')
		
		if "`diag'" != "" {
			tempname inv
			matrix `inv' = syminv(`wmetric')
			foreach i of numlist 1 / `k' {
				foreach j of numlist 1 / `k' {
					if `i' != `j' {
						matrix `inv'[`i',`j'] = 0
					}
				}
			}
			matrix `wmetric' = syminv(`inv')
			matrix `inv' = syminv(`umetric')
			foreach i of numlist 1 / `k' {
				foreach j of numlist 1 / `k' {
					if `i' != `j' {
						matrix `inv'[`i',`j'] = 0
					}
				}
			}
			matrix `umetric' = syminv(`inv')
		}

		noi di as text _col(16) "Mean in treated   Mean in Untreated   " _cont
		if "`f'" == "f" {
			noi di as text "F-stat. for diff."
      matrix `fmat' = `meandiff'
		}
		else if "`p'" == "p" {
			noi di as text "p-value for diff."
      matrix `pmat' = `meandiff'
		}
		else if "`beta'" != "" {
			noi di as text "    Expected bias"
      matrix `bmat' = `meandiff' \ `meandiff'
    }
    else if "`standardize'" == "nostandardize" {
      noi di as text "  Mean Difference"
    }
		else {
			noi di as text "Standardised diff."
		}
		
		noi di as text "{hline 13}{c TT}{hline 56}"

		local diff_vars
		if ltrim(rtrim("`nvars'")) ~= "" {
			foreach var of varlist `nvars' {
        local var_col = colnumb(`meandiff', "`var'")
				tempname mc
				matrix `mc' = `meantreat'[1,"`var'"]
				local mean_case = el("`mc'",1,1)
				regress `var' `treat' `istrata' `pwtexp' if `touse'
				testparm `treat'
				local fstat = `r(F)'
				local diff = _b[`treat']
				local z = _b[`treat']/_se[`treat']
				local p_value = 2*(1-normal(abs(`z')))
				if "`strata'" ~= "" {
					local mean_control = `mean_case' - _b[`treat']
					matrix `meandiff'[1,`var_col'] = _b[`treat']
					matrix `meanuntreat'[1,`var_col'] =  ///
                 `meantreat'[1,`var_col'] - _b[`treat']
				}
				else {
					matrix `mc' = `meanuntreat'[1,"`var'"]
					local mean_control = el("`mc'",1,1)
				}
				noi di as text %12s abbrev("`var'", 12) " {c |}"   ///
						as result %16.2f `mean_case'                ///
						as result %19.2f `mean_control' _cont
				if "`f'" == "f" {
					noi di as result %21.1f `fstat'
          matrix `fmat'[1,`var_col'] = `fstat'
				}
				else if "`p'" == "p" {
					noi di as result %21.3f `p_value'
          matrix `pmat'[1,`var_col'] = `p_value'
				}
        else if "`beta'" != "" {
          local bdiff = `beta'[1,colnumb("`beta'", "`var'")]*`meandiff'[1,`var_col']
          if "`eform'" == "eform" {
            local ebdiff = exp(`bdiff') - 1
            noi di as result %16.1f 100*`ebdiff' as text " %"
          }
          else {
            noi di as result %16.3f `bdiff'
          }
          matrix `bmat'[1,colnumb("`beta'", "`var'")] = `bdiff'
          local bdiff = `beta'[1,colnumb("`beta'", "`var'")]*`umeandiff'[1,`var_col']
          matrix `bmat'[2,colnumb("`beta'", "`var'")] = `bdiff'
        }
        else if "`standardize'" == "nostandardize" {
					noi di as result %21.3f `diff'      
        }
        else {
					matrix `var' = `ucovar'["`var'", "`var'"]
					local vsd   = sqrt(el("`var'",1,1))
					local sdiff = `diff' / `vsd'
					noi di as result %21.3f `sdiff'      
				}
				if `p_value' < 0.05 {
					local diff_vars `diff_vars' `var'
				}
			}
		}
		if "`cvars'" ~= "" {
			noi di as text "{hline 13}{c +}{hline 56}"
//			if "`f'" == "" & "`p'" == "" {
//				noi di as text "{space 13}{c |}{space 50}%diff."
//			}
			tempname matfreq freqt frequ
			foreach root in `croots' {
				local cvargp         
				foreach var of varlist `cvars' {
          local var_col = colnumb(`meandiff', "`var'")
					if regexm("`var'", "_C`root'_") {
						local cvargp `cvargp' `var'		  
						// variable has been xi'd
						regress `var' `pwtexp' if `treat' == 1 & `touse' 
						local mean_case    = 100*_b[_cons]
						regress `var' `pwtexp' if `treat' == 0 & `touse'
						local mean_control = 100*_b[_cons]
						if "`strata'" ~= "" {
							regress `var' `treat' `istrata' `pwtexp' if `touse'
							local mean_control = `mean_case' - 100*_b[`treat']
							if (index("`vars'", "`var'") ~= 0) {
								matrix `meandiff'[1,`var_col'] = _b[`treat']
								matrix `meanuntreat'[1,colnumb(`meanuntreat', "`var'")]  ///
										= `meantreat'[1,colnumb(`meantreat', "`var'")] - _b[`treat']
							}
						}
						capture logit `var' `treat' `istrata' `pwtexp' if `touse'
						if _rc == 0 {
							local z = _b[`treat']/_se[`treat']
							local fstat = (`z')^2
							local p_value = 2*(1-normal(abs(`z')))
							noi di as text %12s abbrev("`var'", 12) " {c |}"   ///
									as result %15.1f `mean_case' as text " %"            ///
									as result %17.1f `mean_control' as text " %" _cont   
							if "`f'" == "f" {
								noi di as result %20.1f `fstat'
							}
							else if "`p'" == "p" {
								noi di as result %20.3f `p_value'
							}
							else if "`beta'" != "" {
                local bdiff = `beta'[1,colnumb("`beta'", "`var'")]*`meandiff'[1,`var_col']
                if "`eform'" == "eform" {
                  local bdiff = exp(`bdiff') - 1
                  noi di as result %15.1f 100*`bdiff' as text " %"
                }
                else {
                  noi di as result %15.3f `bdiff' 
                }
                if colnumb("`beta'", "`var'") < . {
                  matrix `bmat'[1,colnumb("`beta'", "`var'")] = `bdiff'
                  local bdiff = `beta'[1,colnumb("`beta'", "`var'")]*`umeandiff'[1,`var_col']
                  matrix `bmat'[2,colnumb("`beta'", "`var'")] = `bdiff'
                }

              }
              else if "`standardize'" == "nostandardize" {
                noi di as result %19.1f `mean_case'-`mean_control' as text " %"
              }
              else {
								local sd = sqrt(0.5*(`mean_case'*(100 - `mean_case') ///
                    +`mean_control'*(100 - `mean_control')))
								local sdiff = (`mean_case'-`mean_control')/`sd'
								//							local sdiff = `mean_control'-`mean_case' 
								noi di as result %20.3f `sdiff'
							}
						}
					}
				}
				if "`f'" == "f" | "`p'" == "p" {
					mlogit `root' `treat' `istrata' `pwtexp' if `touse'
					testparm `treat'
					local fstat = `r(chi2)'
					local p_value = `r(p)'
					noi di as text "             {c |}"   _cont
					if "`f'" == "f" {
						noi di as text "  Overall chi2-statistic for " _cont
						noi di as result %-12s abbrev("`root'",12) _cont
						noi di as result %11.1f `fstat'
					}
					else if "`p'" == "p" {
						noi di as text "  Overall p-value for " _cont
						noi di as result %-12s abbrev("`root'",12) _cont
						noi di as result %18.3f `p_value'
					}
				}
				else {
					noi di as text "{space 13}{c |}{space 56}"      
				}
				if `p_value' < 0.05 {
					local diff_vars `diff_vars' `root'
				}
			}
		}
		noi di as text "{hline 13}{c BT}{hline 56}" _n
		if "`mahal'" ~= "" {
			matrix `tempmat'  = `meandiff' * `umetric' * `meandiff''
			local D = el("`tempmat'",1,1)
			noi di as text "Mahalonobis Distance between mean vectors: " _n
			noi di as text "(original covariance in treated): " _cont
			noi di as result %6.3f `D'
			return scalar mahal = `D'
			if "`sqrt'" != "" {
				local D = sqrt(`D')
				noi di as text "(square root):                    " _cont
				noi di as result %6.3f `D'
				return scalar mahalsq = `D'
			}      
			matrix `tempmat'  = `meandiff' * `wmetric' * `meandiff''
			local D = el("`tempmat'",1,1)
			noi di as text "(Weighted covariance in treated): " _cont
			noi di as result %6.3f `D'
			return scalar wmahal = `D'
			if "`sqrt'" != ""  {
				local D = sqrt(`D')
				noi di as text "(square root):                    " _cont
				noi di as result %6.3f `D'
				return scalar wmahalsq = `D'
			}      
			return matrix umetric = `umetric'
			return matrix wmetric = `wmetric'
			noi di
		}
		
		if "`metric'" != "" {
			capture confirm matrix `metric'
			if _rc != 0 {
				noi di as error "Unable to find matrix `metric'"
			}
			else {
				matrix `tempmat'  = `meandiff' * `metric' * `meandiff''
				local D = el("`tempmat'",1,1)
				noi di as text "Distance between mean vectors: " _n
				noi di as text   "Using given metric: " _cont
				noi di as result %6.3f `D'
				return scalar dist = `D'
				if "`sqrt'" != "" {
					local D = sqrt(`D')
					noi di as text "(square root):      " _cont
					noi di as result %6.3f `D'
					return scalar distsq = `D'
				}
				noi di
			}
		}
		if "`beta'" != "" {
      matrix `tmeandiff' = `meandiff'
      matrix `tempmat'  = `beta' * `meandiff''
      local D = el("`tempmat'",1,1)
      noi di as text "Expected bias in outcome : " _n
      noi di as text "Using given betas: " _cont
      if "`eform'" == "" {
        noi di as result %6.3f `D'
      }
      else {
        noi di as result %6.1f 100*(exp(`D') - 1) " %"
      }
      return scalar Ebias = `D'
      local size = colsof(`beta')
      matrix `wbeta' = `beta'
      foreach i of numlist 1/`size' {
        local this = el(`wbeta', 1, `i')
        if `this' < 0 {
          matrix `wbeta'[1, `i'] = -1*`this'
        }
        local this = el(`meandiff', 1, `i')
        if `this' < 0 {
          matrix `tmeandiff'[1, `i'] = -1*`this'
        }
      }
      matrix `tempmat'  = `wbeta' * `tmeandiff''
      local D = el("`tempmat'",1,1)
      noi di as text "Absolute values:   " _cont
      if "`eform'" == "" {
        noi di as result %6.3f `D'
      }
      else {
        noi di as result %6.1f 100*(exp(`D') - 1) " %"
      }
      return scalar aEbias = `D'
      
      return matrix abeta = `wbeta'
      noi di
    }
  }
  
  if "`diff_vars'" ~= "" {
    di as error _n "Warning: " _cont
    di as text "Significant imbalance exists in " _cont
    di as text "the following variables:"
    di as result  "`diff_vars'"
    return local diff_vars "`diff_vars'"
  }
  else {
    return local diff_vars " "
  }
	
	matrix `smeandiff' = `meandiff'
	matrix `usmeandiff' = `meandiff'
	matrix `ssmeandiff'  = `meandiff'
	matrix `ussmeandiff' = `meandiff'
	matrix `ssd'       = vecdiag(`covar')
	matrix `ussd'      = vecdiag(`ucovar')
	local size = colsof(`ssd')
	local names : colnames `smeandiff'
	foreach num of numlist 1/`size' {
		matrix `ssd'[1,`num']      = sqrt(el(`ussd', 1, `num'))
		local var : word `num' of `names'
		if regexm("`cvars'", "`var'") {
			matrix `ssd'[1,`num']     = 0.5
		}
		matrix `ussd'[1,`num']      = sqrt(el(`ussd', 1, `num'))
		matrix `smeandiff'[1,`num'] = el(`meandiff', 1, `num') / el(`ussd', 1, `num')
		matrix `usmeandiff'[1,`num'] = el(`umeandiff', 1, `num') / el(`ussd', 1, `num')
		matrix `ssmeandiff'[1,`num']  = el(`meandiff', 1, `num') / el(`ssd', 1, `num')
		matrix `ussmeandiff'[1,`num'] = el(`umeandiff', 1, `num') / el(`ssd', 1, `num')
	}
	
	return matrix meandiff `meandiff'
	return matrix umeandiff `umeandiff'
	return matrix meantreat `meantreat'
	return matrix umeantreat `umeantreat'
	return matrix meanuntreat `meanuntreat'
	return matrix umeanuntreat `umeanuntreat'
	return matrix covar `covar'
	return matrix ucovar `ucovar'
  if "`f'" == "f" {
    return matrix fmat `fmat'
  }
  if "`p'" == "p" {
    return matrix pmat `pmat'
  }

	capture drop _S*
	capture drop _C*

  if "`graph'" != "" {
		quietly {
      preserve
      drop *
      local names : colnames `smeandiff'
      local size : word count `names'
      set obs `size'
      gen unadj = .
      gen adj = .
      gen id = _n
      if "`beta'" != "" {
        if "`eform'" == "eform" {
          foreach num of numlist 1/`size' {
            replace unadj = 100*(exp(el("`bmat'", 2, `num')) - 1) if _n == `num'
            replace adj   = 100*(exp(el("`bmat'", 1, `num')) - 1) if _n == `num'
          }
        }
        else {
          foreach num of numlist 1/`size' {
            replace unadj = el("`bmat'", 2, `num') if _n == `num'
            replace adj   = el("`bmat'", 1, `num') if _n == `num'
          }
        }
      }
      else {
        foreach num of numlist 1/`size' {
          replace unadj = el("`usmeandiff'", 1, `num') if _n == `num'
          replace adj   = el("`smeandiff'", 1, `num') if _n == `num'
        }
      }
      egen rank = rank(abs(unadj))
      //      noi list
      foreach num of numlist 1/`size' {
        local thisname: word `num' of `names'
        local thisval = rank[`num']
        label define rank `thisval' "`thisname'", add
        // noi di in red "`thisval' `thisname'"
      }
      sort rank
      label values rank rank
    }
    local xline xline(-0.1) xline(0.1) xline(0)
    local xtitle xtitle("Standardardised difference")
    if "`beta'" != "" {
      if "`eform'" == "eform" {
        local xtitle xtitle("Expected percentage bias in relative effect of `treat'")
        local xline xline(-5) xline(5) xline(0)
      }
      else {
        local xtitle xtitle("Expected bias in coefficient for `treat'")
        local xline xline(0)
      }
    }
      
    graph twoway scatter rank unadj || sc rank adj, `xline' ytitle("") `xtitle'          ///
        legend(label(1 "Before Adjustment")     ///
				label(2 "After Adjustment")) ylab(1(1)`size', val angle(0)) 
		restore
	}
  
	return matrix smeandiff `smeandiff'
	return matrix usmeandiff `usmeandiff'
	return matrix ssmeandiff `ssmeandiff'
	return matrix ussmeandiff `ussmeandiff'
  return matrix ussd `ussd'
	return matrix ssd `ssd'
  if "`beta'" != "" {
    return matrix bmat `bmat'
  }

end


