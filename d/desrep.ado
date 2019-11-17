*! version 2.41, 9Mar2001, J.Hendrickx@mailbox.kun.nl (STB-61: dm73.3)
/*
Direct comments to: 

John Hendrickx <J.Hendrickx@mailbox.kun.nl>
Nijmegen Business School
University of Nijmegen
P.O. Box 9108
6500 HK Nijmegen
The Netherlands 

Desmat is available at 
http://baserv.uci.kun.nl/~johnh/desmat/stata/

Version 2.41, March 9, 2001
Added "except(xtgee)" for "e(disp)". Won't convert to string when "using"
is used because it's a macro rather than a scalar
Added "version 6" wherever this had been omitted
Version 2.4, January 3, 2001
Order of subroutines changed, desrep program first in file, for compatiblity
with Stata version 7 (by Alan McDowell at StataCorp)
Version 2.3, October 26, 2000
s.e. weren't being printed when "all" option was used
Version 2.2, September 21, 2000
Fixed bug that occurred if equation names contained spaces, e.g. in the
value labels of the dependent variable in -mlogit-. Equation names are
written as well when the "using" option is used.
Added summary information for -svy- models
Version 2.1, Septebmer 12, 2000
Added "using" option, write output to a tab delimited file
Calculates confidence intervals, can print all coefficient statistics now,
most model information.
Version 2.0, June 30 2000
Used t-test rather than Z for prob for regression models (if there is an 
F-statistic for the model to be precise).
Added options for field width, number of decimals, cutpoints and symbols
for level of significance, space between estimate and symbol. Options to
display z(or t) or prob, to suppress printing of significance symbols
or prob.
Version 1.06, April 18 2000
Numbered parameters
Version 1.05, March 30 2000
Display weight and chi-square type
Version 1.04, Nov 8 1999
Reports and uses equation names for compatiblity with mlogit,
cleaned up code somewhat, reports summary model information
Version 1.03, Nov 1 1999
Switched from e(b) and e(V) to _b and _se
Version 1.02, Oct. 7 1999
Added an option for displaying multiplicative parameters
Version 1.01, Sept. 30 1999
Cosmetic changes to display a 'direct' variables name in an interaction but
not in a main effect
*/


program define desrep
  version 6

  if "`0'" == "exp" {
    * multiplicative parameters if argument is "exp"
    * for compatibility with version 1.06 and earlier
    local exp "exp"
  }
  else {
    * numlist kludge to make option argument optional
    #delimit ;
    syntax [using] [,fw(numlist >0 integer max=1)
             ndec(numlist > 0 integer max=1)
             sigcut(numlist)
             sigsym(string)
             sigsep(numlist >=0 integer max=1)
             nrwd(numlist >= 0 integer max=1)
             EXP noSIG noSE ZVAL PROB CI ALL
             noTRUNC noMODINFO OUTRAW REPLACE];
    #delimit cr
  }

  * global macros define fieldwidth, number of decimals, significance
  * cutpoints, significance symbols, width of siginficance column
  if "`fw'" == "" {
    if "$D_FW" ~= "" {local fw $D_FW }
    else {local fw 10 }
  }
  if "`ndec'"=="" {
    if "$D_NDEC" ~= "" {local ndec $D_NDEC }
    else {local ndec 3 }
  }
  if "`sigcut'" == "" {
    if "$D_SIGCUT" ~= "" {local sigcut $D_SIGCUT }
    else {local sigcut ".05 .01" }
  }
  if "`sigsym'" == "" {
    if "$D_SIGSYM" ~= "" {local sigsym $D_SIGSYM }
    else {local sigsym "* **" }
  }
  if "`sigsep'" == "" {
    if "$D_SIGSEP" ~= "" {local sigsep $D_SIGSEP }
    else {local sigsep 0}
  }
  if "`nrwd'" == "" {
    if "$D_NRWD" ~= "" {local nrwd $D_NRWD }
    else {local nrwd 3}
  }
  * global variables to display results such as z-values and probabilities
  * used only if option not specified in argument string
  * add trailing space for checking
  local zero "`0' "
  if "$D_SIG"   ~= "" & index(lower("`zero'"),"sig ") == 0 {
    local sig "$D_SIG"
  }
  if "$D_SE"    ~= "" & index(lower("`zero'"),"se ") == 0 {
    local se "$D_SE"
  }
  if "$D_ZVAL"  ~= "" & index(lower("`zero'"),"zval ") == 0 {
    local zval"$D_ZVAL"
  }
  if "$D_PROB"  ~= "" & index(lower("`zero'"),"prob ") == 0 {
    local prob "$D_PROB"
  }
  if "$D_CI"  ~= "" & index(lower("`zero'"),"ci ") == 0 {
    local ci "$D_CI"
  }
  if "$D_ALL"  ~= "" & index(lower("`zero'"),"full ") == 0 {
    local all "$D_ALL"
  }
  if "$D_TRUNC" ~= "" & index(lower("`zero'"),"trunc ") == 0 {
    local trunc "$D_TRUNC"
  }
  if "$D_RAW" ~= "" & index(lower("`zero'"),"outraw ") == 0 {
    local outraw "$D_RAW"
  }
  if "$D_REPL" ~= "" & index(lower("`zero'"),"replace ") == 0 {
    local replace "$D_REPL"
  }

  if "`all'" ~= "" {
    local zval "zval"
    local prob "prob"
    local ci "ci"
  }

  if "`using'" ~= "" {
    preserve
    if `nrwd' > 0 {
      quietly gen str80 __O__0=""
    }
    * labels, estimates
    quietly gen str80 __O__10=""
    quietly gen str12 __O__12=""
    quietly gen str12 __O__14=""
    quietly gen str80 __O__2=""
    * find out how many columns are used for printing header information
    local lstcol 2
    if "`sig'" == "" & (`sigsep' > 0 | "`outraw'"~="") {
      local lstcol=`lstcol'+1
      quietly gen str80 __O__`lstcol'=""
    }
    if "`se'" == "" {
      local lstcol=`lstcol'+1
      quietly gen str80 __O__`lstcol'=""
    }
    if "`zval'" ~= "" {
      local lstcol=`lstcol'+1
      quietly gen str80 __O__`lstcol'=""
    }
    if "`prob'" ~= "" {
      local lstcol=`lstcol'+1
      quietly gen str80 __O__`lstcol'=""
    }
    if "`ci'" ~= "" {
      local lstcol=`lstcol'+1
      quietly gen str80 __O__`lstcol'=""
      local lstcol=`lstcol'+1
      quietly gen str80 __O__`lstcol'=""
    }
    global D__WRT 1
    global D__LST `lstcol'
    if "`outraw'" == "" {
      global D__FMT `", "%12.`ndec'f""'
    }
  }

  * indent for effect numbering
  global D__INDT=`nrwd'+1
  global D__NDEC=`ndec'

  * model summary information
  if "`modinfo'" == "" {
    display _dup(79) "-"
    display _col($D__INDT) e(cmd)
    if "`using'" ~= "" {
      quietly replace __O__10 = "`e(cmd)'" if _n==$D__WRT
      global D__WRT=$D__WRT+2
    }
    display _dup(79) "-"
    cdisstr  ,rslt(e(depvar))   lab("Dependent variable")
    if "`e(title_fl)'" ~= "" {
      tokenize "`e(title_fl)'", parse(",")
      local fam "`1'"
      local link "`3'"
      clocstr ,rslt("`fam'") lab("Distribution family:")
      clocstr ,rslt("`link'") lab("Link function:")
    }
    cdisstr  ,rslt(e(offset))   lab("Offset variable:")
    cdisint  ,rslt(e(N))        lab("Number of observations:")
    cdisint  ,rslt(e(N_psu))    lab("Number of PSUs:")
    cdisreal ,rslt(e(N_pop))    lab("Population size:")
    cdisreal ,rslt(e(N_subpop)) lab("Subpopulation size:")
    if "`e(wexp)'" ~= "" {
      * extra trouble to get rid of "=" sign in e(wexp)
      local wexp=e(wexp)
      local wexp: subinstr local wexp "=" " ", all
      clocstr ,rslt("`wexp'") lab("`e(wtype)':")
    }
    cdisstr  ,rslt(e(strata))   lab("Strata variable:")
    cdisint  ,rslt(e(N_strata)) lab("Number of strata:")
    cdisstr  ,rslt(e(clustvar)) lab("Cluster variable:")
    cdisint  ,rslt(e(N_clust))  lab("Number of clusters:")
    cdisstr  ,rslt(e(psu))      lab("PSU variable:")
    cdisstr  ,rslt(e(fpc))      lab("FPC variable:")
    cdisstr  ,rslt(e(vcetype))  lab("Type of standard error")
    cdisreal ,rslt(e(deviance)) lab("Deviance:")
    cdisreal ,rslt(e(dispers))  lab("Deviance dispersion:")
    cdisreal ,rslt(e(disp))     lab("Deviance scale factor:") except(xtgee)
    cdisint  ,rslt(e(df_pear))  lab("df")
    cdisreal ,rslt(e(ll_0))     lab("Initial log likelihood:") except("regress")
    cdisreal ,rslt(e(ll))       lab("Log likelihood:") except("regress")
    cdisreal ,rslt(e(chi2))     lab("`e(chi2type)' chi square:") except("glm")
    cdisreal ,rslt(e(F))        lab("F statistic:")
    cdisint  ,rslt(e(df_m))     lab("Model degrees of freedom:")
    cdisint  ,rslt(e(df_r))     lab("Residual degrees of freedom:") except("glm")
    cdisint  ,rslt(e(k_cat))    lab("Number of categories of the dependent variable:")
    * category number, usualy the same as category value
    *cdisint  ,rslt(e(ibasecat)) lab("Baseline category number:")
    cdisint  ,rslt(e(basecat))  lab("Baseline category:")
    cdisreal ,rslt(e(r2_p))     lab("Pseudo R-squared:")
    cdisreal ,rslt(e(r2))       lab("R-squared:")
    cdisreal ,rslt(e(r2_a))     lab("Adjusted R-squared:")
    cdisreal ,rslt(e(rmse))     lab("Root MSE")

    * display probability
    if "`e(deviance)'" ~= "" {
      local mprob=chiprob(`e(df_pear)',`e(deviance)')
    }
    else if "`e(chi2)'" ~= "" {
      local mprob=chiprob(`e(df_m)',`e(chi2)')
    }
    else if "`e(F)'" ~= "" {
      local mprob=fprob(`e(df_m)',`e(df_r)',`e(F)')
    }
    if "`mprob'" ~= "" {
      display _col($D__INDT) "Prob:" _col(68) %12.`ndec'f  `mprob'
      if "`using'" ~= "" {
        quietly replace __O__10 = "Prob:" if _n==$D__WRT
        quietly replace __O__`lstcol'= string(`mprob'$D__FMT) if _n==$D__WRT
        incrmnt
      }
    }

    if "`using'" ~= "" {
      incrmnt
    }
  } /* end of summary information */

  * find the length of the longest significance symbol
  tokenize "`sigsym'"
  local sigwd=length("`1'")
  while "`1'" ~= "" {
    local sigwd=max(`sigwd',length("`1'"))
    macro shift
  }

  * field reserved for label informatie
  local div=80-`fw' /* estimate */
  if "`sig'" == "" {
    local div=`div'-`sigwd'-`sigsep'
  }
  if "`se'" == "" {
    local div=`div'-`fw'
  }
  if "`zval'" ~= "" {
    local div=`div'-`fw'
  }
  if "`prob'" ~= "" {
    local div=`div'-`fw'
  }
  if "`ci'" ~= "" {
    local div=`div'-2*`fw'
  }

  * header for the estimates section
  display _dup(79) "-"
  if `nrwd' > 0 {
    display "nr" _col(`nrwd') _skip(1) "Effect" _col(`div') _continue
    if "`using'" ~= "" {
      quietly replace __O__0="nr" if _n==$D__WRT
      quietly replace __O__10 = "Effect" if _n==$D__WRT
    }
  }
  else {
    display "Effect" _col(`div') _continue
    if "`using'" ~= "" {
      quietly replace __O__10="Effect" if _n==$D__WRT
    }
  }
  display %`fw's "Coeff" _continue
    if "`using'" ~= "" {
      quietly replace __O__2="Coeff" if _n==$D__WRT
      local curcol 2
    }
  if "`sig'" == "" {
    display _skip(`sigwd') _skip(`sigsep') _continue
    if "`using'" ~= "" & (`sigsep' > 0 | "`outraw'" ~= "") {
      local curcol=`curcol'+1
    }
  }
  if "`se'" == "" {
    display %`fw's "s.e." _continue
    if "`using'" ~= "" {
      local curcol=`curcol'+1
      quietly replace __O__`curcol'="s.e." if _n==$D__WRT
    }
  }
  if "`zval'" ~= "" {
    if "`e(F)'" ~= "" {
      display %`fw's "t  " _continue
      if "`using'" ~= "" {
        local curcol=`curcol'+1
        quietly replace __O__`curcol'="t" if _n==$D__WRT
      }
    }
    else {
      display %`fw's "z  " _continue
      if "`using'" ~= "" {
        local curcol=`curcol'+1
        quietly replace __O__`curcol'="z" if _n==$D__WRT
      }
    }
  }
  if "`prob'" ~= "" {
    display %`fw's "prob" _continue
    if "`using'" ~= "" {
      local curcol=`curcol'+1
      quietly replace __O__`curcol'="prob" if _n==$D__WRT
    }
  }
  if "`ci'" ~= "" {
    display %`fw's "lo $S_level%" %`fw's "hi $S_level%"  _continue
    if "`using'" ~= "" {
      local curcol=`curcol'+1
      quietly replace __O__`curcol'="lo $S_level%" if _n==$D__WRT
      local curcol=`curcol'+1
      quietly replace __O__`curcol'="hi $S_level%" if _n==$D__WRT
    }
  }
  display
  if "`using'" ~= "" {
    incrmnt
  }

  if "`exp'" ~= "" {
    display "(exponential parameters)"
    if "`using'" ~= "" {
      quietly replace __O__10="(exponential parameters)" if _n==$D__WRT
      incrmnt
    }
  }
  display _dup(79) "-"
  if "`using'" ~= "" {
    incrmnt
  }

  tempname paras 
  matrix `paras'=e(b)
  local nms: colnames `paras'
  local fnms: colfullnames `paras'
  local i 1
  * check for colons --> equation names (e.q. -mlogit-)
  local pnt=index("`fnms'",":")
  tokenize "`nms'"
  while "`1'" ~= "" {
    local indt=`nrwd'+1
    * check for an equation name. If so, report it and indent two spaces
    *if `pnt' ~= 0 {
    if "`nms'" ~= "`fnms'" {
      gettoken eqnm fnms : fnms, parse(":")
      gettoken null fnms : fnms, parse(":") /* get the colon */
      gettoken null fnms : fnms             /* get the variable */

      if "`eqnm'" ~= "`eqnm1'" {
        display _col(`indt') "`eqnm'"
        if "`using'" ~= "" {
          quietly replace __O__10="`eqnm'" if _n == $D__WRT
          incrmnt
        }
      }
      local eqnm1="`eqnm'"
      local b_=["`eqnm'"]_b[`1']
      local se_=["`eqnm'"]_se[`1']
      local indt=`indt'+2
    }
    else {
      local b_=_b[`1']
      local se_=_se[`1']
    }

    * cf example in [R] logit
    if `se_' == 0 { local se_ = . }

    local zt_=`b_'/`se_'
    if "`e(F)'" ~= "" {
      local prob_=tprob(`e(N)'-2,`zt_')
    }
    else {
      local prob_=2*(1-normprob(abs(`zt_')))
    }

    * determine significance level
    local sig_=""
    gettoken cut sigct: sigcut
    gettoken sym sigsm: sigsym
    while "`cut'" ~= "" {
      if `prob_' < `cut' {
        local sig_="`sym'"
      }
      gettoken cut sigct: sigct
      gettoken sym sigsm: sigsm
    }

    * option to report exponential parameters
    if "`exp'" ~= "" {
      * save linear versions for calculating c.i.
      local linb `b_'
      local linse `se_'
      local b_=exp(`b_')
      local se_=`b_'*`se_'
    }

    * get variable names
    local varn="``1'[varn]'"
    local pzat="``1'[pzat]'"
    if "`varn'" ~= "`varn1'" & "`varn'" ~= "" & "`pzat'" ~= "direct" {
      * display the effect name on a separate line for categorical effects
        display _col(`indt') "`varn'"
        if "`using'" ~= "" {
          local whch=`indt'-`nrwd'-1
          quietly replace __O__1`whch'="`varn'" if _n == $D__WRT
          incrmnt
        }
    }
    local varn1="`varn'"

    * get value labels
    local valn="``1'[valn]'"
    if "`valn'" == "" | "`pzat'" == "direct" {
      * continuous variables or effects not generated by desmat:
      * use the variable label if available, otherwise the varname
      capture local valn: variable label `1'
      if "`valn'" == "" {
        local valn `1'
      }
    }
    else {
      * categorical variable, indent two spaces
      local indt=`indt'+2
    }

    * write full label `valw' to text file even if `valn' truncated
    local valw "`valn'"
    if "`trunc'" == "" {
      local valn=substr("`valn'",-`div'+`indt'+1,.)
    }

    * display the results
    if `nrwd' > 0 {
      display %-`nrwd's "`i'" _col(`indt') "`valn'" _col(`div')  _continue
      if "`using'" ~= "" {
        local whch=`indt'-`nrwd'-1
        quietly replace __O__0=string(`i') if _n == $D__WRT
        quietly replace __O__1`whch'="`valw'" if _n == $D__WRT
      }
    }
    else {
      display                 _col(`indt') "`valn'" _col(`div')  _continue
      if "`using'" ~= "" {
        local whch=`indt'-`nrwd'-1
        quietly replace __O__1`whch'="`valw'" if _n == $D__WRT
      }
    }
    if "`trunc'" ~= "" & length("`valn'") > `div' - `indt' {
      display
      display _col(`div') _continue
    }
    display %`fw'.`ndec'f `b_' _continue
    if "`using'" ~= "" {
      quietly replace __O__2=string(`b_'$D__FMT) if _n == $D__WRT
      local curcol 2
    }
    if "`sig'" == "" {
      display _skip(`sigsep') %-`sigwd's "`sig_'" _continue
      if "`using'" ~= "" {
        if `sigsep' > 0 | "`outraw'" ~= "" {
          local curcol=`curcol'+1
          quietly replace __O__`curcol'="`sig_'" if _n == $D__WRT
        }
        else {
          quietly replace __O__`curcol'=string(`b_'$D__FMT)+"`sig_'" if _n == $D__WRT
        }
      }
    }
    if "`se'" == "" {
      display %`fw'.`ndec'f `se_' _continue
      if "`using'" ~= "" {
        local curcol=`curcol'+1
        quietly replace __O__`curcol'=string(`se_'$D__FMT) if _n == $D__WRT
      }
    }
    if "`zval'" ~= "" {
      display %`fw'.`ndec'f `zt_' _continue
      if "`using'" ~= "" {
        local curcol=`curcol'+1
        quietly replace __O__`curcol'=string(`zt_'$D__FMT) if _n == $D__WRT
      }
    }
    if "`prob'" ~= "" {
      display %`fw'.`ndec'f `prob_' _continue
      if "`using'" ~= "" {
        local curcol=`curcol'+1
        quietly replace __O__`curcol'=string(`prob_'$D__FMT) if _n == $D__WRT
      }
    }
    if "`ci'" ~= "" {
      if "`e(F)'" ~= "" {
        local ci1_=`b_'-invt(`e(df_r)',$S_level/100)*`se_'
        local ci2_=`b_'+invt(`e(df_r)',$S_level/100)*`se_'
      }
      else {
        if "`exp'" == "" {
          local ci1_=`b_'-invnorm($S_level/200+.5)*`se_'
          local ci2_=`b_'+invnorm($S_level/200+.5)*`se_'
        }
        else {
          local ci1_=exp(`linb'-invnorm($S_level/200+.5)*`linse')
          local ci2_=exp(`linb'+invnorm($S_level/200+.5)*`linse')
        }
      }
      display %`fw'.`ndec'f `ci1_' %`fw'.`ndec'f `ci2_' _continue
      if "`using'" ~= "" {
        local curcol=`curcol'+1
        quietly replace __O__`curcol'=string(`ci1_'$D__FMT) if _n == $D__WRT
        local curcol=`curcol'+1
        quietly replace __O__`curcol'=string(`ci2_'$D__FMT) if _n == $D__WRT
      }
    }
    display
    if "`using'" ~= "" {
      incrmnt
    }

    macro shift
    local i=`i'+1
  }
  display _dup(79) "-"
  if "`using'" ~= "" { incrmnt }

  * legend for significance symbols
  gettoken cut sigct: sigcut
  gettoken sym sigsm: sigsym
  while "`cut'" ~= "" {
    display %-`sigwd's "`sym'" " p < `cut'"
    if "`using'" ~= "" {
      quietly replace __O__10 = "`sym' p < `cut'" if _n == $D__WRT
      incrmnt
    }
    gettoken cut sigct: sigct
    gettoken sym sigsm: sigsm
  }

  if "`using'" ~= "" {
    global D__WRT=$D__WRT-1
    local vlist "__O__10"
    if `nrwd' > 0 { local vlist "__O__0 `vlist'" }
    tempvar a
    quietly gen `a'=sum(~missing(__O__12))
    if `a'[$D__WRT] ~= 0 { local vlist "`vlist' __O__12" }
    quietly replace `a'=sum(~missing(__O__14))
    if `a'[$D__WRT] ~= 0 { local vlist "`vlist' __O__14" }
    local vlist "`vlist' __O__2-__O__`lstcol'"
    outshee2 `vlist' `using' in 1/$D__WRT, nonames noquote `replace'
    restore
  }
  macro drop D__*
end
program define incrmnt
  version 6
    if $D__WRT >= _N {
      local n=_N+10
      quietly set obs `n'
    }
    global D__WRT=$D__WRT+1
end

program define cdisstr
  version 6
  * display string "e()" if defined.
  syntax [,rslt(string) lab(string) except(string)]
  if "``rslt''" == "" { exit }
  tokenize "`except'"
  while "`1'" ~= "" {
    if "`e(cmd)'" == "`1'" {
      exit
    }
    macro shift
  }
  local colpos=80-length(`rslt')

  display _col($D__INDT) "`lab'" _col(`colpos')       `rslt'
  
  if "$D__WRT" ~= "" {
    * "using" option is in effect
    quietly replace __O__10 = "`lab'" if _n==$D__WRT
    quietly replace __O__$D__LST="``rslt''" if _n==$D__WRT
    incrmnt
  }
end

program define cdisint
  version 6
  * display integer value "e()" if defined.
  syntax [,rslt(string) lab(string) except(string)]
  if "``rslt''" == "" { exit }
  tokenize "`except'"
  while "`1'" ~= "" {
    if "`e(cmd)'" == "`1'" {
      exit
    }
    macro shift
  }

  display _col($D__INDT) "`lab'" _col(68) %12.0f `rslt'
  
  if "$D__WRT" ~= "" {
    * "using" option is in effect
    quietly replace __O__10 = "`lab'" if _n==$D__WRT
    quietly replace __O__$D__LST=string(`rslt') if _n==$D__WRT
    incrmnt
  }
end

program define cdisreal
  version 6
  * display real number "e()" if defined.
  syntax [,rslt(string) lab(string) except(string)]
  if "``rslt''" == "" { exit }
  tokenize "`except'"
  while "`1'" ~= "" {
    if "`e(cmd)'" == "`1'" {
      exit
    }
    macro shift
  }

  display _col($D__INDT) "`lab'" %12.${D__NDEC}f _col(68) ``rslt''
  
  if "$D__WRT" ~= "" {
    * "using" option is in effect
    quietly replace __O__10 = "`lab'" if _n==$D__WRT
    quietly replace __O__$D__LST=string(`rslt'$D__FMT) if _n==$D__WRT
    incrmnt
  }
end

program define clocstr
  version 6
  * display local string macro, portion of e() result
  syntax [,rslt(string) lab(string) except(string)]

  local colpos=80-length("`rslt'")

  display _col($D__INDT) "`lab'" _col(`colpos')       "`rslt'"
  
  if "$D__WRT" ~= "" {
    * "using" option is in effect
    quietly replace __O__10 = "`lab'" if _n==$D__WRT
    quietly replace __O__$D__LST="`rslt'" if _n==$D__WRT
    incrmnt
  }
end

