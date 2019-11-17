program define mpbalchk, rclass

*! $Revision: 1.1 $
*! Author:  Mark Lunt
*! Date:    April 18, 2012 @ 10:51:13

version 9

  syntax varlist [if] [in] [,STRATA(passthru) ///
			Wt(passthru) noSTandardize              ///
			f p mahal           ///
			metric(passthru)    ///
			beta(passthru)      ///
			eform diag sqrt     ///
			XIPrefix(passthru)  ///
			graph SHOWall       ///  
			]
  
  qui isvar _mj
  if "`r(varlist)'" != "_mj" {
    noi di as error "This is not multiply-imputed data: running pbalchk."
    pbalchk `varlist' `if' `in' ,`strata' `wt' `f' `p' `mahal' `metric' ///
        `beta' `eform' `diag' `sqrt' `xiprefix'	`graph' `standardize'
  }
  else {
		tempname meantreat meanuntreat meandiff tempmat var covar 
		tempname umeantreat umeanuntreat umeandiff ucovar umetric wmetric
		tempname wbeta mscovar ssd ussd smeandiff usmeandiff ssmeandiff ussmeandiff
    tempname fmat pmat bmat tmeandiff

    if "`if'" == "" {
      local mif if _mj > 0 & _mj < .
      local pif if _mj == \`i\'
    }
    else {
      local mif `if' & _mj > 0 & _mj < .
      local pif `if' & _mj == \`i\'
    }
    qui levelsof _mj `mif'
    local imps = r(levels)
    if regexm("`imps'", "^0 ") {
      local imps : subinstr("`imps'", "^0 ", "")
    }
    local nimps : word count `imps'
    if `nimps' < 1 {
      noi di in red "No imputations selected"
      exit
    }
    local first = 1
    local diff_vars
    local counter 1
    di
    foreach i in `imps' {
      di as text "Processing imputation " as result `i'
      if "`showall'" == "" {
        capture pbalchk `varlist' `pif' `in' ,`strata' `wt' `mahal'  ///
            `metric' `beta' `diag' `sqrt' `xiprefix' `f' `p' `eform'  ///
            `standardize'
      }
      else {
        pbalchk `varlist' `pif' `in' ,`strata' `wt' `mahal'  ///
            `metric' `beta' `diag' `sqrt' `xiprefix' `f' `p' `eform' ///
            `standardize'
      }
      if `first' {
        if "`mahal'" != "" {
          local D  = r(mahal)
          local wD = r(wmahal)
          if "`sqrt'" != "" {
            local sD  = r(mahalsq)
            local wsD = r(wmahalsq)
          }
          matrix `umetric' = r(umetric)
          matrix `wmetric' = r(wmetric)
        }
        if "`metric'" != "" {
          local mD = r(dist)
          if "`sqrt'" != "" {
            local msD = r(distsq)
          }
        }
        if "`beta'" != "" {
          local bD = r(Ebias)
          local abD = r(aEbias)
          matrix `wbeta' = r(abeta)
        }
        foreach mat in meandiff umeandiff meantreat umeantreat meanuntreat  ///
            umeanuntreat covar ucovar smeandiff usmeandiff ssmeandiff  ///
            ussmeandiff ussd ssd {
          matrix ``mat'' == r(`mat')
        }
        if "`f'" == "f" {
          matrix `fmat' == r(fmat)
        }
        if "`p'" == "p" {
          matrix `pmat' == r(pmat)
        }
        if "`beta'" != "" {
          matrix `bmat' == r(bmat)
        }
        local diff_vars = r(diff_vars)
      }
      else {
        if "`mahal'" != "" {
          local D  = `D'  + r(mahal)
          local wD = `wD' + r(wmahal)
          if "`sqrt'" != "" {
            local sD  = `sD'  + r(mahalsq)
            local wsD = `wsD' + r(wmahalsq)
          }
          matrix `umetric' = r(umetric) + `umetric'
          matrix `wmetric' = r(wmetric) + `wmetric'
        }
        if "`metric'" != "" {
          local mD = r(dist) + `mD'
          if "`sqrt'" != "" {
            local msD = r(distsq) + `msD'
          }
        }
        if "`beta'" != "" {
          local bD  = r(Ebias)  + `bD'
          local abD = r(aEbias) + `abD'
          matrix `wbeta' = r(abeta) + `wbeta'
        }
        foreach mat in meandiff umeandiff meantreat umeantreat meanuntreat  ///
            umeanuntreat covar ucovar smeandiff usmeandiff ssmeandiff  ///
            ussmeandiff ussd ssd {
          matrix ``mat'' == r(`mat') + ``mat''
        }
        if "`f'" == "f" {
          matrix `fmat' == r(fmat) + `fmat'
        }
        if "`p'" == "p" {
          matrix `pmat' == r(pmat) + `pmat'
        }
        if "`beta'" != "" {
          matrix `bmat' == r(bmat) + `bmat'
        }
      
      }
      if "`graph'" != "" {
        tempname smeandiff_`i' usmeandiff_`i'
        matrix `smeandiff_`i''  = r(smeandiff)
        matrix `usmeandiff_`i'' = r(usmeandiff)
        if "`beta'" != "" {
          tempname bmat_`i'
          matrix `bmat_`i'' = r(bmat)
        }
      }
      local this_vars = r(diff_vars)
      local diff_vars : list diff_vars | this_vars
      local first = 0
      local counter = `counter' + 1
    }
    di
    if "`mahal'" != "" {
      local D = `D' / `nimps'
      if "`sqrt'" != "" {
        local sD = `sD' / `nimps'
        matrix `umetric' = `umetric' / `nimps'
        matrix `wmetric' = `wmetric' / `nimps'
      }
    }
    if "`metric'" != "" {
      local mD = `mD' / `nimps'
      if "`sqrt'" != "" {
        local msD = `msD' / `nimps'
      }
    }
    if "`beta'" != "" {
      matrix `wbeta' = `wbeta' / `nimps'
      if regexm("`beta'", "beta\((.*)\)") == 1 {
        local beta = regexs(1)
      }

    }
    foreach mat in meandiff umeandiff meantreat umeantreat meanuntreat  ///
        umeanuntreat covar ucovar smeandiff usmeandiff ssmeandiff  ///
        ussmeandiff ussd ssd {
      matrix ``mat'' = ``mat'' / `nimps'
    }    
    if "`f'" == "f" {
      matrix `fmat' == `fmat' / `nimps'
    }
    if "`p'" == "p" {
      matrix `pmat' == `pmat' / `nimps'
    }
    if "`beta'" != "" {
      matrix `bmat' == `bmat' / `nimps'
    }
    noi di as text _col(16) "Mean in treated   Mean in Untreated   " _cont
    if "`f'" == "f" {
      noi di as text "F-stat. for diff."	
    }
    else if "`p'" == "p" {
      noi di as text "p-value for diff."	
    }
    else if "`beta'" != "" {
      noi di as text "Expected bias"	
    }
    else if "`standardize'" == "nostandardize" {
      noi di as text "Mean Difference"	
    }
    else {
      noi di as text "Standardised diff."	
    }
		
		noi di as text "{hline 13}{c TT}{hline 56}"

    local names : colnames `meandiff'
    local nnum  : word count `names'
    foreach num of numlist 1/`nnum' {
      local var : word `num' of `names'
      noi di as text %12s abbrev("`var'", 12) " {c |}"   ///
          as result %16.2f el(`meantreat',   1, `num')       ///
          as result %19.2f el(`meanuntreat', 1, `num') _cont
      if "`f'" == "f" {
        noi di as result %21.3f el(`fmat', 1, `num')
      }
      else if "`p'" == "p" {
        noi di as result %21.3f el(`pmat', 1, `num')
      }
      else if "`beta'" != "" {
        if "`eform'" == "eform" {
          local bdiff = el(`bmat', 1, `num')
          noi di as result %16.1f 100*(exp(`bdiff') - 1) as text " %" 
        }
        else {
          noi di as result %21.3f el(`bmat', 1, `num')
        }
      }
      else if "`standardize'" == "nostandardize" {
        if substr("`var'", 1, 2) == "_C" {
          noi di as result %20.1f 100*el(`meandiff', 1, `num') as text " %"
        }
        else {
          noi di as result %21.3f el(`meandiff', 1, `num')
        }
      }
      else {
        noi di as result %21.3f el(`smeandiff', 1, `num')
      }
    }
    
		noi di as text "{hline 13}{c BT}{hline 56}" _n
		if "`mahal'" ~= "" {
			matrix `tempmat'  = `meandiff' * `umetric' * `meandiff''
			local D = el("`tempmat'",1,1)
			noi di as text "Mean Mahalonobis Distance between mean vectors: " _n
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
				noi di as text "Mean distance between mean vectors: " _n
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
			capture confirm matrix `beta'
			if _rc != 0 {
				noi di as error "Unable to find matrix `beta'"
			}
			else {
        matrix `tmeandiff' = `meandiff'
				matrix `tempmat'  = `beta' * `meandiff''
				local D = el("`tempmat'",1,1)
				noi di as text "Mean expected bias in outcome : " _n
				noi di as text "Using given betas: " _cont
        if "`eform'" == "eform" {
          noi di as result %6.1f 100*(exp(`D') - 1) " %"
        }
        else {
          noi di as result %6.3f `D'
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
        if "`eform'" == "eform" {
          noi di as result %6.1f 100*(exp(`D') - 1) " %"
        }
        else {
          noi di as result %6.3f `D'
        }
				return scalar aEbias = `D'
				
				return matrix abeta = `wbeta'
        return matrix bmat  = `bmat'
				noi di
			}
		}
	}	

  if "`diff_vars'" ~= "" {
    di as error _n "Warning: " _cont
    di as text "Significant imbalance exists in the following variables " 
    di as text "in at least one imputation:"
    di as result  "`diff_vars'"
    return local diff_vars "`diff_vars'"
  }
  if "`graph'" != "" {
    quietly {
      preserve
      drop *
      set obs `nnum'
      gen str32 stem = ""
      gen category   = .
      foreach i in `imps' {
        gen unadj_`i'  = .
        gen adj_`i'    = .
      }
      gen id = _n
      local names : colnames `smeandiff'
      foreach num of numlist 1/`nnum' {
        local name : word `num' of `names'
        if regexm("`name'", "^_C(.+)_([0-9]+)") {
          local name = regexs(1)
          replace category = real(regexs(2)) if _n == `num'
        }
        replace stem = "`name'" if _n == `num'
        foreach i in `imps' {
          if "`beta'" != "" {
            if "`eform'" == "eform" {
              replace unadj_`i' = 100*(exp(el("`bmat_`i''", 2, `num')) - 1) if _n == `num'
              replace adj_`i'   = 100*(exp(el("`bmat_`i''", 1, `num')) - 1) if _n == `num'
            }
            else {
              replace unadj_`i' = el("`bmat_`i''", 2, `num') if _n == `num'
              replace adj_`i'   = el("`bmat_`i''", 1, `num') if _n == `num'
            }
          }
          else {
            replace unadj_`i' = el("`usmeandiff_`i''", 1, `num') if _n == `num'
            replace adj_`i'   = el("`smeandiff_`i''", 1, `num') if _n == `num'
          }
        }
      }

      egen ua = rowmean(unadj_*)
      bys stem: egen uam = mean(ua)
			
      egen rank1 = rank(abs(uam))
			gen add    = cond(category == ., 0, -1*category/100)
			egen rank  = rank(rank1 + add)
			sort id
      foreach num of numlist 1/`nnum' {
        local thisname: word `num' of `names'
        local thisval = rank[`num']
        label define rank `thisval' "`thisname'", add
      }
      label values rank rank
      sort rank category
      reshape long adj_ unadj_, i(id) j(mj)
      local xline xline(-0.1) xline(0.1) xline(0)
      local xtitle xtitle("Standardardised difference")
      if "`beta'" != "" {
    	// Handle parameters
        tokenize `varlist'
        local treat `1'
        
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
          label(2 "After Adjustment")) ylab(1(1)`nnum', val angle(0)) 
      restore
    }
  }
  foreach mat in meandiff umeandiff meantreat umeantreat meanuntreat  ///
      umeanuntreat covar ucovar smeandiff usmeandiff ssmeandiff  ///
      ussmeandiff ussd ssd {
    return matrix `mat' ``mat''
  }    
  
end
