*! version 2.1 : May1997 : Joseph Hilbe  STB-38 smv3.2
*  Dichotomous Discriminate Anaylsis
*  Based on ver 1 - Hilbe: STB-5 (Jan1992), ver 2.0 STB-34 (Nov1996)

program define discrim
  version 5.0
    local varlist "req ex"
    local options "Detail Graph Anova Predict Keep"
    local in "opt"
    local if "opt"
    parse "`*'"
    parse "`varlist'",parse(" ")
    qui summ `1'

    if (_result(6)<0 | _result(6)>1)  {
       noi di in red "Error: Group variable must be 0/1"
       exit
    }
    if "`keep'"=="" {
      preserve
    }
    qui {
    dropmiss `varlist'
    tempvar prob0 prob1 dummy D nvar obs obs1 obs0 c0 c1 prop D cntall
     gen `cntall'=_n
     local group `1'
     local y "`1'"
     mac shift
     qui count
     gen `obs' = _result(1)
     count if `group'==0
     gen `obs0'= _result(1)
     count if `group'==1
     gen `obs1'= _result(1)
     tempvar c0
     gen `c0' =`obs1'/`obs'
     gen `c1' = -(`obs0'/`obs')
     gen `prob0' = `obs1'/`obs'
     gen `dummy' = `c0' if `group'==0
     replace `dummy' = `c1' if `group'==1
     reg `dummy' `*', noheader
     global nvar = _result(3)
     cap drop `dummy' `c0' `c1'
     global rsquare = _result(7)
     global mahala=($rsquare/(1-$rsquare))*((`obs'*(`obs'-2))/(`obs0'*`obs1'))
     gen `prop' = $rsquare/$mahala
     gen `D' = sqrt($mahala)

*  Calc discriminant scores
     local i = 1
     while "``i''"!= ""  {
        tempvar cof`i' dis`i'
        gen `cof`i'' = _b[``i'']
        gen `dis`i'' = `cof`i''/`prop'
        local i = `i'+1
     }

*   Calc main values */
    local j = 1
    local i = 1
    tempvar konst usdfk dscorep dscore dsFp dfun
    gen `usdfk'=0
    gen `konst' = 0
    gen `dscorep'=0
    gen `dscore'=0
    gen `dsFp'=0
    gen `dfun'=0
    while "``i''"!="" {
       tempvar mean`j' mn0`j' mn1`j' mndff`j' usdf`j'
       summ ``i''
       gen `mean`j'' = _result(3)
       summ ``i'' if `group'==0
       gen `mn0`j'' = _result(3)
       summ ``i'' if `group'==1
       gen `mn1`j'' = _result(3)
       gen `mndff`j'' = `mn0`j'' + `mn1`j''
       replace `konst' = `dis`i''*`mndff`j''+`konst'
       gen `usdf`i''=`dis`i''/-`D'
       replace `usdfk'=`usdf`j'' * `mean`j'' + `usdfk'
       replace `dscorep'=`usdf`i''*``i''
       replace `dscore'=`dscore'+`dscorep'
       replace `dsFp'=`dis`i''*``i''
       replace `dfun'=`dfun'+`dsFp'
       local i = `i'+1
       local j = `j'+1
    }
    replace `usdfk'=`usdfk'* -1
    replace `dscore'=`dscore'+`usdfk'
    replace `konst'=`konst'*-.5
    replace `dfun' = `dfun'+`konst'
    local tsquare = $mahala*((`obs0'*`obs1')/`obs')
    local F = `tsquare'*(`obs'-$nvar)/(($nvar-1)*(`obs'-2))
    global cnt0 = -`D'*(`obs1'/`obs')
    global cnt1 = `D'*(`obs0'/`obs')
    noi di _n
    noi di in gr _col(20) "Dichotomous Discriminant Analysis"
    noi di "                                                 "
    #delimit ;
    noi di in gr "Observations    = " in ye `obs'
       in gr _col(50) "Obs Group 0 = " in ye %9.0g `obs0';
    noi di in gr "Indep variables = " in ye $nvar
       in gr _col(50) "Obs Group 1 = " in ye %9.0g  `obs1';
    noi di "                                                  ";
    noi di in gr "Centroid 0  = " in ye %9.4f $cnt0
       in gr _col(50) "R-square    = " in ye %9.4f $rsquare;
    noi di in gr "Centroid 1  = " in ye %9.4f $cnt1
       in gr _col(50) "Mahalanobis = " in ye %9.4f $mahala;
    noi di in gr "Grand Cntd  = " in ye %9.4f
       ((`obs1'*$cnt0)+(`obs0'*$cnt1))/`obs';
    noi di "                                                  ";
    #delimit cr
    oneway `dscore' `group'
    global eigen  = _result(2)/_result(4)
    global ccor   = sqrt(_result(2)/(_result(2)+_result(4)))
    global lambda = _result(4)/(_result(2)+_result(4))
    global chisq  = log($lambda)* -((`obs'-($nvar+2)/2)-1)
    #delimit ;
    noi di in gr "Eigenvalue   = " in ye %9.4f $eigen
       in gr _col(50) "Wilk's Lambda = " in ye %7.4f $lambda;
    noi di in gr "Canon. Corr. = " in ye %9.4f $ccor
       in gr _col(50) "Chi-square    = " in ye %7.4f $chisq;
    noi di in gr "Eta Squared  = " in ye %9.4f $ccor^2
       in gr _col(50) "Sign Chi2     = " in ye %7.4f chiprob($nvar,$chisq);
    #delimit cr

* DISPLAY COEFFICIENTS
     noi di _n(1)
     noi di in gr _col(26) "Discrim Function" _col(46) "Unstandardized"
     noi di in gr _col(11) /*
       */ "Variable" _col(28) "Coefficients" _col(48) "Coefficients"
     noi di in gr _col(11) _dup(49) "-"
     local i=1
     while "``i''"!=""  {
     noi di in gr _col(11) "``i''" in ye _col(28) %9.4f `dis`i'' /*
       */ _col(51) %9.4f `usdf`i''
     local i = `i'+1
     }
     noi di in gr _col(11) "constant" in ye _col(28) %9.4f `konst' /*
       */ _col(51) %9.4f `usdfk'

     tempvar lprob grpred cell
     gen `lprob'    = 1/(1+exp(`dfun'))
     gen `grpred'     = 1 if `lprob'>=0.5
     replace `grpred' = 0 if `lprob'<0.5
     gen `cell' = 1
     summ `cell' if `group'==0 & `lprob'<0.5
     local aa=_result(2)
     summ `cell' if `group'==0 & `lprob'>=0.5
     local bb=_result(2)
     summ `cell' if `group'==1 & `lprob'<0.5
     local cc=_result(2)
     summ `cell' if `group'==1 & `lprob'>=0.5
     local dd=_result(2)
     local tot = `aa'+`bb'+`cc'+`dd'

* CONFUSION MATRIX AND RELATED STATS OPTION
if "`predict'" !=""  {
    noi di _n "                                                     "
    noi di in gr _col(25) "----- Predicted -----"
    noi di in gr _col(13) "Actual   |  Group 0         Group 1 |   Total    Pr(G
    noi di in gr _col(13) "---------+" _dup(26) "-" "+--------"
    noi di in gr _col(13) "Group 0  |" in ye _col(26) %6.0g `aa' /*
     */ _col(40) %6.0g `bb' in gr _col(49) "|" in ye _col(52) %6.0g /*
     */ `aa'+`bb'  _col(62) %6.2f (`aa'+`bb')/`tot'
    noi di in gr _col(13) "Group 1  |" in ye _col(26) %6.0g `cc' /*
     */ _col(40) %6.0g `dd' in gr _col(49) "|" in ye _col(52) %6.0g /*
     */ `cc'+`dd'  _col(62) %6.2f (`cc'+`dd')/`tot'
    noi di in gr _col(13) "---------+" _dup(26) "-" "+--------"
    noi di in gr _col(13) "Total    |" in ye _col(26) %6.0g `aa'+`cc' /*
      */ _col(40) %6.0g `bb'+`dd' in gr _col(49) "|" in ye _col(52) /*
      */ %6.0g `tot'
    noi di in gr _col(13) "---------+" _dup(26) "-" "+--------"
    noi di "                                                  "
    noi di in gr _col(21) "Correctly predicted = " in ye /*
      */ %6.2f ((`aa'+`dd')/`tot')*100 " %"
    noi di in gr _col(21) "Model sensitivity   = " in ye /*
      */ %6.2f (`aa'/(`aa'+`bb'))*100 " %"
    noi di in gr _col(21) "Model specificity   = " in ye /*
      */ %6.2f (`dd'/(`cc'+`dd'))*100 " %"
    noi di in gr _col(21) "False positive      = " in ye /*
      */ %6.2f (`cc'/(`dd'+`cc'))*100 " %"
    noi di in gr _col(21) "False negative      = " in ye /*
      */ %6.2f (`bb'/(`bb'+`aa'))*100 " %"
    noi di in gr _col(21) "-------------------------------"
    noi di in gr _col(21) "Positive pred value = " in ye /*
      */ %6.2f (`aa'/(`aa'+`cc'))*100 " %"
    noi di in gr _col(21) "Negative pred value = " in ye /*
      */ %6.2f (`dd'/(`bb'+`dd'))*100 " %"
    noi di in gr _col(21) "-------------------------------"
    noi di in gr _col(21) "Kendall's tau-b     = " in ye /*
     */ %6.2f ( (`aa'+`dd')-((((`aa'+`bb')/`tot')*(`aa'+`bb')) /*
     */ + (((`cc'+`dd')/`tot') * (`cc'+`dd')))) /*
     */ / (`tot'-((((`aa'+`bb')/`tot')*(`aa'+`bb')) /*
     */ + (((`cc'+`dd')/`tot') * (`cc'+`dd')))) * 100 " %"
    noi di in gr _col(21) "Cohen's kappa       = " in ye /*
     */ %6.2f (((`aa'+`dd')/`tot')-((((`aa'+`bb')*(`aa'+`cc'))/`tot') /*
     */ + (((`cc'+`dd')*(`bb'+`dd'))/`tot')) / `tot') / (1-((((`aa'+`bb') /*
     */ * (`aa'+`cc'))/`tot') + (((`cc'+`dd')*(`bb'+`dd'))/`tot'))/`tot') /*
     */ *100 " %"


}

* ANOVA OPTION
  if "`anova'"!="" {
    noi di _n(1)
    noi di in gr _col(18) "Discriminant Scores v Group Variable"
    noi oneway `dscore' `group'
  }

* GRAPH OPTION
  if "`graph'"!="" {
    tempvar lnp lnm
    gen `lnp'=`lprob' if (`lprob'>=0.5 & `group'==1) | /*
      */ (`lprob'<0.5 & `group'==0)
    gen `lnm'=`lprob' if `lnp'==.
    lab var `lnp' "Classified"
    lab var `lnm' "Misclassified"
    lab var `dfun' "Discriminant Index"
    noi gr `lnp' `lnm' `dfun', s(.p) xlab ylab(.1,.3,.4,.5,.6,.7,.9) /*
      */ border yline(.5) ti("      Probability of Classification")
    cap drop `lnp' `lnm'
  }

* INDIVIDUAL CLASSIFICATION STATISTICS OPTION: SAVES WITH SAVE OPTION
   if "`detail'"!="" {
   cap drop PRED DscScore DscIndex LnProb1 Group DIFF
   sort `cntall'
   noi di _n(2)
   gen PRED=`grpred'
   gen DscScore  = `dscore'
   gen DscIndex  = `dfun'
   gen LnProb1   = `lprob'
   gen Group     = `group'
   compress Group PRED
   gen str2 DIFF = " *" if `group'!=PRED
   format DIFF %2s
   format DscIndex DscScore LnProb1 %9.4f
 noi di in gr " PRED    = Predicted Group       DIFF     = Misclassification"
 noi di in gr " LnProb1 = Probability Gr 1      DscScore = Discriminant Score"
 noi di in gr "                                 DscIndex = Discriminant Index"
   noi di in gr _dup(63) "-"
   di "                                           "
   noi l `y' PRED DIFF LnProb1 DscIndex DscScore, nol
 }

global S_E_var $nvar
global S_E_obs `obs'
global S_E_ob0 `obs0'
global S_E_ob1 `obs1'
global S_E_cn0 $cnt0
global S_E_cn1 $cnt1
global S_E_cng  ((`obs1'*$cnt0)+(`obs0'*$cnt1))/`obs'
global S_E_r2  $rsquare
global S_E_mah $mahala
global S_E_eig $eigen
global S_E_lam $lamda
global S_E_cc  $ccor
global S_E_chi $chisq
global S_E_e2  $ccor^2
global S_E_cmd "discrim"

}

if "`keep'"!="" {
  noi di _n in bl " Caution: data changed in memory"
  }
if "`keep'"=="" {
  restore
}

end



* DROP MISSING VALUES
  capture program drop dropmiss
  program define dropmiss
  local varlist "req ex"
  parse "`*'"
  parse "`varlist'", parse(" ")
  local i= 1
  while "``i''"!=""  {
    drop if ``i''==.
    local i=`i'+1
  }
end

