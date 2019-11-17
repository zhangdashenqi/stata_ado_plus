program define loghockey, eclass byable(recall)

  local scalarlist df_m df_r mss mms msr rmse F r2 r2_a dev converge N rss
  local scalarlist `scalarlist' df_t tss cj gm_2 k log_t lnlsq ic
  local macrolist title f_args version function params 

  version 8.2
  syntax varlist [if] [in] [, OR Right0 Left0]

if "`right0'" != "" & "`left0'" != "" {
	 noi di as error "You cannot specify both right0 and left0"
    exit 1
  }

tokenize `varlist'
  local dep `1'
  macro shift
  local indep `*'
  local main_indep : word 1 of `indep'
  marksample touse

  display
  //  set weights = 1
  quietly {
	 tempvar wt xb p Y ll llsum
	 gen `wt' = 1 if `touse'
	 //  use non-linear regression to get parameters
	 nl hockey `dep' `indep' `if' `in', `right0' `left0'
	 //  get rss
	 local rss = e(rss)
	 local old_rss 0
	 //  recalculate weights
	 predict `xb' if `touse'
	 generate `p' = exp(`xb') / (1 + exp(`xb')) if `touse'
	 replace `wt' = `p' * (1 - `p') if `touse'
	 gen `Y' = `xb' + (`dep' - `p')/(`p' * (1 - `p')) if `touse'
	 gen `ll' = ln(1-`p') + `dep'*ln(`p'/(1-`p'))
	 egen `llsum' = sum(`ll')
    local thisll = `llsum'[1]
	 //  refit model until rss stops changing
    local iter 0
	 while (abs(`rss' - `old_rss') > 0.00001) {
		noi di as text "Iteration `iter': log likelihood = " ///
        		 as result %10.4f `thisll'
		drop `xb'
		local old_rss = `rss'
		nl hockey `Y' `indep' [aw=`wt'] `if' `in', `right0' `left0'
		local rss = e(rss)
		predict `xb' if `touse'
		replace `p' = exp(`xb') / (1 + exp(`xb')) if `touse'
		replace `wt' = `p' * (1 - `p') if `touse'
		replace `ll' = ln(1-`p') + `dep'*ln(`p'/(1-`p'))
		drop `llsum'
      egen `llsum' = sum(`ll')
		local thisll = `llsum'[1]
      local iter = `iter' + 1
	 }
  foreach i in `scalarlist' {
	 local `i' = e(`i')
  }
  foreach i in `macrolist' {
	 local `i' = e(`i')
  }
  matrix b = e(b)
  matrix V = e(V)
  matrix b2 = b
  matrix V2 = V
  local colnames `main_indep' `main_indep' others
  if "`right0'" == "" & "`left0'" == "" {
	 local colnames `main_indep' `colnames'
  }
  matrix coleq b2 = `colnames'
  matrix coleq V2 = `colnames' 
  matrix roweq V2 = `colnames'
  
///    set trace on
	 logit `dep' if `touse'
	 local ll0 = e(ll)
	 tempvar ll llsum
	 gen `ll' = ln(1-`p') + `dep'*ln(`p'/(1-`p'))
    egen `llsum' = sum(`ll')
  }


  ereturn post b2 V2 

  local test = `llsum'[1]

  display
  display as text `""Hockey Stick" Logistic regression"' ///
          _col(50) "Number of obs   ="                   ///
          as result %11.0g  `N' 
  display as text _col(50) "LR chi2("                    ///
          as result `k' - 1                              ///
          as text  ")      ="                            ///
          as result %11.2f 2*(`llsum' - `ll0')
  display as text _col(50) "Prob > chi2     ="           ///
          as result %11.4f (1 - chi2(`k'-1, 2*(`llsum' - `ll0')))
  display as text "Log likelihood = "                    ///
          as result %11.4f `llsum'                       ///
          as text _col(50) "Pseudo-R2       ="           ///
          as result %11.4f 1-`llsum'/`ll0'
  display

  if "`or'" == "" {
	 ereturn display
  }
  else {
  local mult = invnorm(0.5 + $S_level/200)
  display as text "{hline 13}{c TT}{hline 64}"
    display as text %12s abbrev("`dep'", 12) " {c |}" ///
           	as text "     Param.   Std. Err.      z    P>|z|" ///
	         as text "     [$S_level% Conf. Interval]"
	 display as text "{hline 13}{c +}{hline 64}"
	 display as result %12s abbrev("`main_indep'", 12) as text " {c |}"
    
  local parmno 1
  local est = b[1,`parmno']
  local se  = sqrt(el(V,`parmno',`parmno'))
  display as text %12s "breakpoint" " {c |}" ///
	         as result _col(16) %9.0g `est' ///
	         as result _col(28) %9.0g `se'         ///
            as result _col(41) %5.2f `est'/`se'     ///
            as result _col(49) %5.3f 2*(1 - norm(abs(`est'/`se'))) ///
          	as result _col(59) %9.0g `est' - `mult'*`se' ///
           	as result _col(70) %9.0g `est' + `mult'*`se'

  local parmno = `parmno' + 1
  
  if "`left0'" == "" {
	 local est = b[1,`parmno']
	 local se  = sqrt(el(V,`parmno',`parmno'))
	 local este = exp(`est')
	 local see  = exp(`est') * `se'
	 display as text %12s "OR (left)" " {c |}"                      ///
	 as result _col(16) %9.0g `este'                        ///
	 as result _col(28) %9.0g `see'                         ///
	 as result _col(41) %5.2f `est'/`se'                    ///
	 as result _col(49) %5.3f 2*(1 - norm(abs(`est'/`se'))) ///
	 as result _col(59) %9.0g exp(`est' - `mult'*`se')    ///
	 as result _col(70) %9.0g exp(`est' + `mult'*`se')
	 local parmno = `parmno' + 1
  }
  if "`right0'" == "" {
	 local est = b[1,`parmno']
	 local se  = sqrt(el(V,`parmno',`parmno'))
	 local este = exp(`est')
	 local see  = exp(`est') * `se'
	 display as text %12s "OR (right)" " {c |}"                      ///
	 as result _col(16) %9.0g `este'                        ///
	 as result _col(28) %9.0g `see'                         ///
	 as result _col(41) %5.2f `est'/`se'                    ///
	 as result _col(49) %5.3f 2*(1 - norm(abs(`est'/`se'))) ///
	 as result _col(59) %9.0g exp(`est' - `mult'*`se')    ///
	 as result _col(70) %9.0g exp(`est' + `mult'*`se')
	 local parmno = `parmno' + 1
  }
    
  if `k' > `parmno' {
	 display as text "{hline 13}{c +}{hline 64}"
	 display as result %12s "Other ORs" as text " {c |}"
    if "`left0'" == "" & "`right0" == "" {
		local names  dummy dummy `indep'
	 }
	 else {
		local names  dummy `indep'
	 }
	 local counter = `parmno'
	 while `counter' < `k' {
		  local est = b[1,`counter']
		  local se  = sqrt(el(V,`counter',`counter'))
		  local este = exp(`est')
		  local see  = exp(`est') * `se'
		  local thisname : word `counter' of `names'
		  display as text %12s abbrev("`thisname'",12) " {c |}"          ///
		          as result _col(16) %9.0g `este'                        ///
	             as result _col(28) %9.0g `see'                         ///
                as result _col(41) %5.2f `est'/`se'                    ///
                as result _col(49) %5.3f 2*(1 - norm(abs(`est'/`se'))) ///
                as result _col(59) %9.0g exp(`est' - `mult'*`se')    ///
		          as result _col(70) %9.0g exp(`est' + `mult'*`se')
		  local counter = `counter' + 1
		}
	 }
  display as text "{hline 13}{c BT}{hline 64}"  
}

  set trace off
  ereturn post b V, esample(`touse')
  
  foreach i in `scalarlist' {
    ereturn scalar `i' = ``i''
  }
  foreach i in `macrolist' {
    ereturn local `i' = "``i''"
  }

  ereturn scalar ll   = `llsum'
  ereturn scalar ll_0 = `ll0'
  ereturn scalar r2_p = 1 - `llsum'/`ll0'
  ereturn local cmd "loghock"
  ereturn local predict "loghockey_p"
  ereturn local depvar "`dep'"
  set trace off
             
  
    
end
  
