*!nrat.ado 
*! Companion program to sampsurv.ado
*! Calculates the expected nr of patients enrolled and nr of events in a  trial
* with assumed constant entry rate at specified time points.
* Useful for planning interim analyses. 
* WvP 28/1/2002
/* 
Options almost as in sampsurv. Not power() alpha() fu()
N1() is required 
At(timepoints) 

Uniform entry is assumed during period [0,ap]
*/ 
program define nrat
version 7.0
if substr("`0'",1,1)~="," {local 0 ,`0' }
#delimit ;
syntax  [, AT(numlist asc >0)  N1(integer 0) P1(string) N2(integer 0) Hr(real 1)  Ratio(real 1)  P2(string) 
   AP(real 0.01) Strhr(string) PREV(string)  NAmes(string) Tu(string) ]  ;
#delimit cr
if _N>0 {
 preserve
 clear 
}

if "`tu'"=="" {  local tu yrs }
else {  local tu =substr("`tu'",1,3) }
if "`p1'"=="" { 
  di in red "p1() not specified"
  exit 198
}
else {
  local t0=0
  local p10=1
  local p20=1
  parse "`p1'",parse(",")
  local i=1
  while "``i''"~="" {
    while "``i''"=="," {macro shift}
    local p1`i' ``i''
    local i=`i'+1
  }
  local nt=`i'-1    /* Number of timepoints with specified S1(t) in arm 1 */
  local i=1
  while `i'<=`nt' {
    local i_1=`i'-1
    parse  "`p1`i''",parse(" :")
    if "`3'"==""&`nt'>1 {
      di in red "p1() not valid"
      exit 198
    }
    else if "`3'"==""&`nt'==1 {
      local t1 5  /* If time not specified: default 5 [yr] */
      local p11 `1'
    }
    else if "`3'"~="" {
      local t`i' `1'
      local p1`i' `3'
    }
    if `p1`i''>`p1`i_1''|`p1`i''<=0|`t`i''<=`t`i_1'' { 
      di in red "p1() not valid"
      exit 198
    }
    /* exponential hazard rate in time interval: l`i'*/
    local l`i' =log(`p1`i_1''/`p1`i'')/(`t`i''-`t`i_1'')
    local i=`i'+1
  }
  local i_1=`i'-1
  local t`i' .        /* last interval till infinity */
  local l`i' `l`i_1''
}
if `hr'==1 {
  parse  "`p2'",parse(" :,")
  if ("`4'"~="") {
    di in red "p2() not valid"
    exit 198
  }
  else if "`3'"=="" {
    /* If time not specified for arm 2: default the first t1 */
    local p21 `1'
    if "`p21'"=="" {
      di in red "p2() not valid, hr() not specified"
      exit 198
    }
    local hr=log(`p21')/log(`p11')
  }
  else if "`3'"~="" {
    local time  `1'
    local p21 `3'
    local i=1
    while `i'<=`nt' {
      if `t`i''==`time' {
        local hr=log(`p21')/log(`p1`i'')
        local ok ok
        local i=`nt'+1
      }
      local i=`i'+1
    }
    if "`ok'"~="ok" {   
      di in red "p2() not valid"
      exit 198
    }
  }
}
if `hr'<=0 { 
  di in red "hr() out of range"
  exit 198
}
else if abs(`hr'-1)<.0001 { 
  di in red "p2() or hr() must be specified; hr<>1"
  exit 198
}
else  {
  local i=1
  while `i'<=`nt' {
    local p2`i'=`p1`i''^`hr'
    local i=`i'+1
  }
}

if `ratio'<=0 { 
  di in red "ratio() out of range"
  exit 198
}
if `n1'< 0 | `n2'< 0 { 
  di in red "n() out of range"
  exit 198
}

if "`prev'"=="" {
  local nstr=1   /* N Strata =1 */
  local hr1 1
  local prev1 1
}
else {
  local nstr: word count `prev'
  parse "`prev'",parse(" ")
  local sum 0
  local i=1
  while `i'<=`nstr' {
    if ``i''<=0 {
      di in red "prev() not valid; elts>0"
      exit 198
    }
    local prev`i' ``i''
    local sum=`sum'+ ``i''
    local i=`i'+1
  }
  local nhr : word count `strhr'
  if `nhr'!=`nstr'-1 {
    di in red "hr() not valid; # elts must be # strata-1"
    exit 198
  }
  parse "`strhr'",parse(" ")
  local prev1 = `prev1'/`sum'
  local hr1 1
  local i=1
  while `i'<=`nstr'-1 {
    if ``i''<=0 {
      di in red "hr() not valid; elts>0"
      exit 198
    }
    local a=``i''
    local i=`i'+1
    local hr`i' `a'
    local prev`i'=`prev`i''/`sum'
  }
  parse "`names'",parse(" ")
  local i=1
  while `i'<=`nstr' {
    if "``i''"!="" {  local str`i' ``i'' }
    else {      local str`i' Stratum `i' } 
    local i=`i'+1
  }
}

local r1=100/(`ratio'+1)


nois display in gr _n "Expected number of patients entered and number of events at different timepoints" _n
#delimit ;
nois display 
    "Assumptions:" _n(1) 
    _col(1) in gr  "Proportional hazard rate" _col(25) "= " in ye %8.3f `hr' _n 
    _col(1) in gr  "   Accrual period [`tu']" _col(25) "= " in ye %8.1f `ap' _n 
    _col(1) in gr  "   uniform accrual rate" _n
    _col(1) in gr  "   Perc. of pts in arm 1" _col(25) "= " in ye %8.0f `r1' "%" _n
;
  di in gr "Survival probabilities [%]:"_n _col(12) "Time    Arm 1    Arm 2";

  #delimit cr
  if `nstr'>1 {  di in gr " `str1'," _col(14) "Prevalence: " %4.2f `prev1'  }
  local i=1
  while `i'<=`nt' {
    scalar p1=`p1`i''*100
    scalar p2=`p2`i''*100
    di in gr _col(12) %4.0f `t`i'' _skip(4)  %5.1f p1  _skip(4) %5.1f p2 
    local i=`i'+1
  }
  local s=2
  while `s'<=`nstr' {
    if `s'==2 { di in gr  _col(29) "RHR vs `str1'" }
    di in gr " `str`s''," _col(14) "Prevalence: " %4.2f `prev`s''  _col(33) %5.2f `hr`s''
    local s=`s'+1
  }     

nois display _n in gr "  Time  Entered   -------Events------"
nois display    in gr "                  Total   Arm1   Arm2"        

foreach time of numlist `at' {
  scalar t=`time'     /* analysis time from entry first patient = max fu time */
  scalar minfu=max(0, t-`ap')  /* min fu duration */

 /* Calculate S1a and S1b : expected S1(t) at min fu and max fu time points
   in arm 1 and similarly in arm 2. In stratum 1.
   Also S1m and S2m at median fu time. Used for approximation of mean 
   ratio of numbers at risk at event times. 
 */

  local i=1
  while `t`i''<= t { local i=`i'+1  }
  local i_1 =`i'-1
  local S1b=`p1`i_1''*exp(-`l`i''*(t-`t`i_1'')) 
  local S2b=`S1b'^`hr'
  local i=1
  if minfu>0 {
    while `t`i''<= minfu { local i=`i'+1 }
    local i_1 =`i'-1
    local S1a=`p1`i_1''*exp(-`l`i''*(minfu-`t`i_1''))  
    local S2a=`S1a'^`hr'
  }
  else {
    local S1a=1
    local S2a=1
  }  
  local s=1
  while `s'<=`nstr' {
    if `ap'>0 {
        local ms1 0
        local ms2 0
        local j=`i'
        while `t`j''<=t {
          local j_1 =`j'-1
          if `l`j''>.0001  {
            local ms1=`ms1'+ (min(`S1a',`p1`j_1'')^`hr`s''-`p1`j''^`hr`s'')/(`l`j''*`hr`s'')
            local ms2=`ms2'+ (min(`S2a',`p2`j_1'')^`hr`s''-`p2`j''^`hr`s'')/(`l`j''*`hr'*`hr`s'')
          }
          else {
            local ms1=`ms1'+`p1`j_1''^`hr`s''*(`t`j''-max(minfu,`t`j_1''))
            local ms2=`ms2'+`p2`j_1''^`hr`s''*(`t`j''-max(minfu,`t`j_1''))
          }
          local j=`j'+1
        }
        local j_1 =`j'-1
        if `l`j''>.0001  {
          local ms1=`ms1'+ (min(`S1a',`p1`j_1'')^`hr`s''-`S1b'^`hr`s'')/(`l`j''*`hr`s'')
          local ms2=`ms2'+ (min(`S2a',`p2`j_1'')^`hr`s''-`S2b'^`hr`s'')/(`l`j''*`hr'*`hr`s'')
        }
        else   {
          local ms1=`ms1'+`S1b'^`hr`s''*(t-max(minfu,`t`j_1''))
          local ms2=`ms2'+`S2b'^`hr`s''*(t-max(minfu,`t`j_1''))
        }

        local s1`s'=1-`ms1'/min(`ap',t)  /* Expected fraction of events in arm 1 
            given accrual period and analysis time in Stratum `s' */
        local s2`s'=1-`ms2'/min(`ap',t)  /* The same for arm 2 */
    }
    else { /* accrual period 0: simpler ! */
        local s1`s'=(1-`S1a'^`hr`s'') /* Expected fraction of events in arm 1 
            given accrual period and analysis time in Stratum `s'*/
        local s2`s'=(1-`S2a'^`hr`s'') /* The same for arm 2 */
    }
    local s=`s'+1
  }


  local sum1=0
  local sum2=0
  local s=1
  local r2=`ratio'/(`ratio'+1)
  local r1=1/(`ratio'+1)
  while `s'<=`nstr' {
    local sum1=`sum1'+`s1`s''*`prev`s''
    local sum2=`sum2'+`s2`s''*`prev`s''
    local s=`s'+1
  }
  local sum=`sum1'*`r1'+`sum2'*`r2'
  local N1t=`n1'*min(t,`ap')/`ap'  /* # pts entered in arm 1 at analysis time t */
  local Nt=`N1t'/`r1'
  local Et=`sum'*`Nt'
  local E1t=`sum1'*`N1t' 
  local E2t=`sum2'*(`Nt'-`N1t') 
  nois display in gr  %6.0f t  in ye %9.0f `Nt' %8.1f `Et'  %7.1f `E1t' %7.1f `E2t' 
  
}

end


