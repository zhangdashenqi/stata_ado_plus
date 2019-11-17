*!Sampsurv.ado 
*! Sample Size calculation for Survival endpoints
*! Inspired by sampsi.ado
* WvP 21/2/97
* Adapted slightly to include the non-inferiority design. 14/3/01

program define sampsurv
version 7.0
local dalpha = 1 - $S_level/100
if substr("`0'",1,1)~="," {local 0 ,`0' }
#delimit ;
syntax [,Alpha(real `dalpha') Power(real 0.90) N1(int 0) 
  N2(int 0) Hr(real 1)  Ratio(real 1) P1(string) P2(string)
  ONEside EQuiv AP(real 0.01) Fu(real 1) Strhr(string) PREV(string)
  NAmes(string) Tu(string) NRat(numlist asc >0)] ;
#delimit cr

if _N>0 {
 preserve
 clear 
}

if `alpha'<=0 | `alpha'>=1 { 
  di in red "alpha() out of range"
  exit 198
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
  parse "`p1'",parse(", ")
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

if `power'<=0 | `power'>=1 {
  di in red "power() out of range"
  exit 198
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

tempname diff n0 pbar r1 w w1 w2 za zb

scalar t=`ap'+`fu'     /* maximum fu time */
scalar tm=`fu'+`ap'/2  /* median  fu time */
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
while `t`i''<= tm { local i=`i'+1  }
local i_1 =`i'-1
local S1m=`p1`i_1''*exp(-`l`i''*(tm-`t`i_1''))  
local S2m=`S1b'^`hr'

local i=1
while `t`i''<= `fu' { local i=`i'+1 }
local i_1 =`i'-1
local S1a=`p1`i_1''*exp(-`l`i''*(`fu'-`t`i_1''))  
local S2a=`S1a'^`hr'
local rat0=0
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
      local ms1=`ms1'+`p1`j_1''^`hr`s''*(`t`j''-max(`fu',`t`j_1''))
      local ms2=`ms2'+`p2`j_1''^`hr`s''*(`t`j''-max(`fu',`t`j_1''))
    }
    local j=`j'+1
  }
  local j_1 =`j'-1
  if `l`j''>.0001  {
    local ms1=`ms1'+ (min(`S1a',`p1`j_1'')^`hr`s''-`S1b'^`hr`s'')/(`l`j''*`hr`s'')
    local ms2=`ms2'+ (min(`S2a',`p2`j_1'')^`hr`s''-`S2b'^`hr`s'')/(`l`j''*`hr'*`hr`s'')
  }
  else   {
    local ms1=`ms1'+`S1b'^`hr`s''*(t-max(`fu',`t`j_1''))
    local ms2=`ms2'+`S2b'^`hr`s''*(t-max(`fu',`t`j_1''))
  }

  local s1`s'=1-`ms1'/`ap'  /* Expected fraction of events in arm 1 
            given accrual period and follow up time in Stratum `s' */
  local s2`s'=1-`ms2'/`ap'  /* The same for arm 2 */
  }
  else { /* accrual period 0: simpler ! */
    local s1`s'=(1-`S1a'^`hr`s'') /* Expected fraction of events in arm 1 
            given accrual period and follow up time in Stratum `s'*/
    local s2`s'=(1-`S2a'^`hr`s'') /* The same for arm 2 */
  }

/* approximation of average log ratio between numbers at risk at the
   event times for each stratum. */
  local S1=`S1m'^`hr`s''
  local h `hr'
  local h2 =2*`hr'-1
  local rat`s'=(`h'-1)*(`S1'-1-`S1'*log(`S1'))
  local rat`s'=`rat`s''+(`h'-1)*(`S1'^`h'-1-`S1'^`h'*`h'*log(`S1'))/`h'
  local rat`s'=`rat`s''/(2-`S1'-`S1'^`h')
  local rat0=`rat0'+`prev`s''*(`s1`s''+`ratio'*`s2`s'')*`rat`s''
  local tot0=`tot0'+`prev`s''*(`s1`s''+`ratio'*`s2`s'')
  local s=`s'+1
}
local rat0=exp(`rat0'/`tot0')

if "`equiv'"~="" {local oneside oneside }

if "`oneside'"~="" { scalar `za' = invnorm(1 - `alpha') }
else               { scalar `za' = invnorm(1 - `alpha'/2)   }

if `n1' == 0 & `n2' == 0 {  /* compute sample size */
  scalar `zb' = invnorm(`power')
* local d=(((`hr'+1)/(`hr'-1))*(`za'+`zb'*(2*(`hr'^2+1))^.5/(`hr'+1)))^2

  local ratx=`ratio'
  local d2=((`za'+`zb')*(1+`ratx')/log(`hr'))^2/`ratx' /* Schoenfeld */
  local d3=((`za'+`zb')*(`hr'*`ratx'+1)/(`hr'-1))^2/`ratx' /* Number of events required
                by formula of Peto / Freedman */
  local d4=((`za'+`zb'*(`hr'^.5*(1+`ratx')/(1+`hr'*`ratx')))*(`hr'*`ratx'+1)/(`hr'-1))^2/`ratx' 
    /*  by formula of Peto / Freedman - modified */
  if "`equiv'"=="" {
    local d4=((`za'+`zb'*(`hr'^.5*(1+`ratx')/(1+`hr'*`ratx')))*(`hr'*`ratx'+1)/(`hr'-1))^2/`ratx' 
    /*  by formula of Peto / Freedman - modified */
  }
  else {
    local d4=((`zb'+`za'*(`hr'^.5*(1+`ratx')/(1+`hr'*`ratx')))*(`hr'*`ratx'+1)/(`hr'-1))^2/`ratx' 
    /*  by formula of Peto / Freedman - modified */
  }
    
*adjustment for variation in ratio between numbers ate risk due to
* difference in hazard rates 
  local ratx=`rat0'*`ratio'
  local d2x=((`za'+`zb')*(1+`ratx')/log(`hr'))^2/`ratx' /* Schoenfeld */
  local d3x=((`za'+`zb')*(`hr'*`ratx'+1)/(`hr'-1))^2/`ratx' /* Number of events required
                by formula of Peto / Freedman */
  if "`equiv'"=="" {
    local d4x=((`za'+`zb'*(`hr'^.5*(1+`ratx')/(1+`hr'*`ratx')))*(`hr'*`ratx'+1)/(`hr'-1))^2/`ratx' 
    /*  by formula of Peto / Freedman - modified */
  }
  else {
    local d4x=((`zb'+`za'*(`hr'^.5*(1+`ratx')/(1+`hr'*`ratx')))*(`hr'*`ratx'+1)/(`hr'-1))^2/`ratx' 
    /*  by formula of Peto / Freedman - modified */
  }

/* Literature
 Freedman, Stat in Med Vol 1, 121-129, 1982; formula 4 on page 127.
 The modified version is found by not using the approximation in the formulas after
 formula (2) with the phi[i] (ratio of number of patients at risk) assumed to be 
 constant but not equal to 1. Formulas (2) and (4) are according to Freedman an 
 approximation of what I call the modified version.
 Schoenfeld, Biometrics 39, 499-503.
*/  
  local sum=0
  local s=1
  local r2=`ratio'/(`ratio'+1)
  local r1=1/(`ratio'+1)
  while `s'<=`nstr' {
    local sum=`sum'+`s1`s''*`prev`s''*`r1'
    local sum=`sum'+`s2`s''*`prev`s''*`r2'
    local s=`s'+1
  }
  local N=`d3'/`sum'
  local N2=`r2'*`N'
  local N1=`r1'*`N'
  local n1=int(`N1'+.5)
  local D1=0
  local D2=0
  local s=1
  while `s'<=`nstr' {
    local N_`s'=`prev`s''*`N'
    local N1`s'=`r1'*`N_`s''
    local N2`s'=`r2'*`N_`s''
    local D1`s'=`s1`s''*`N1`s''
    local D2`s'=`s2`s''*`N2`s''
    local D_`s'=`D1`s''+`D2`s''
    local D1=`D1'+`D1`s''
    local D2=`D2'+`D2`s''
    local s=`s'+1
  }
  #delimit ;
  if "`equiv'"~="" { ;
    di _n in gr "Estimated sample size for two-sample comparison of survival curves" _n(2)
    "Non-inferiority study with " _n " S1 survival function in control group"
    _n " S2 Survival function in experimental group" _n 
    " Test Ho: S2<=S1 - D for some positive difference D, versus " _n 
    "      Ha: S2>=S1, S2 at least as good as S1." _n
    " The difference D is expressed as proportional hazard (>1) rate below." _n
    " The power is calculated for the alternative S2=S1." _n(2) 
    "Assumptions:" _n(1) 
    _col(10) in gr  "Proportional hazard rate" _col(35) "= " in ye %8.3f `hr' _n 
    _col(10) in gr  "   Accrual period [`tu']" _col(35) "= " in ye %8.1f `ap' _n 
    _col(10) in gr  "   Additional FU  [`tu']" _col(35) "= " in ye %8.1f `fu' _n 
    _col(10) in gr  "                   alpha" _col(35) "= " in ye %8.4f `alpha' _c ;
  } ;
  else { ;
    di _n in gr "Estimated sample size for two-sample comparison of survival curves" _n(2)
    "Test Ho: S1 = S2, where S1 is the Survival function in population 1" _n _col(21)
    "and S2 is the Survival function in population 2" _n(2) "Assumptions:" _n(1) 
    _col(10) in gr  " Proportional hazard rate" _col(35) "= " in ye %8.3f `hr' _n 
    _col(10) in gr  "    Accrual period [`tu']" _col(35) "= " in ye %8.1f `ap' _n 
    _col(10) in gr  "    Additional FU  [`tu']" _col(35) "= " in ye %8.1f `fu' _n 
    _col(10) in gr  "                    alpha" _col(35) "= " in ye %8.4f `alpha' _c ;
  } ;
  if "`oneside'"~="" { di in gr "  (one-sided)" } ;
  else                { di in gr "  (two-sided)" } ;
  di _col(10) in gr "                    power" _col(35) "= " in ye %8.4f `power' _n; 
  di in gr "Survival probabilities [%]:    Time    Arm 1    Arm 2    Total";

  #delimit cr
  if `nstr'>1 {  di in gr " `str1', Prevalence:" %4.2f `prev1'  }
  local i=1
  while `i'<=`nt' {
    scalar p1=`p1`i''*100
    scalar p2=`p2`i''*100
    di in gr _col(32) %4.0f `t`i'' _skip(4)  %5.1f p1  _skip(4) %5.1f p2 
    local i=`i'+1
  }
  local s=1
  while `s'<=`nstr' {
    if `s'>1 {di in gr " `str`s'', Prevalence: " %4.2f `prev`s''  _col(40) "RHR vs `str1': " %5.2f `hr`s''}
    scalar p1=`S1a'^`hr`s''*100
    scalar p2=`S2a'^`hr`s''*100
    di in gr "           Minimum FU [`tu']:" _col(32) %4.0f `fu' _skip(4)  %5.1f p1  _skip(4) %5.1f p2
    scalar p1=`S1b'^`hr`s''*100
    scalar p2=`S2b'^`hr`s''*100
    di in gr "           Maximum FU [`tu']:" _col(32) %4.0f t _skip(4)  %5.1f p1  _skip(4) %5.1f p2 _n
    local s=`s'+1
  }     
  local N1=int(`N1'+.99)  /* Round off upwards */
  local N2=int(`N2'+.99)
  local N=`N1'+`N2'

  di in ye "Freedman/Peto formula: "
  di in gr "Required number of subjects (N) :" in ye _col(40) %5.0f `N1' _skip(4) %5.0f `N2' _skip(4) %5.0f `N'
  di in gr "Required/exp number of events (E):" in ye _col(40) %5.1f `D1'  _skip(4) %5.1f `D2'  _skip(4) %5.1f `d3' 
  di _n
  di in gr              _col(44) "E"      _col(53)  "N"
  di in gr " by Freedman/Peto: "            in ye  _col(39)   %6.1f `d3'   _col(48)  %6.1f `d3'/`sum' 
  di in gr " by Freedman/Peto (modified): " in ye  _col(39)   %6.1f `d4'   _col(48)  %6.1f `d4'/`sum'  
  di in gr " by Schoenfeld : "              in ye  _col(39)   %6.1f `d2'   _col(48)  %6.1f `d2'/`sum' 


  di in gr _n "With adjustment for changing ratios of numbers at risk:"
  di in gr "  estimated average ratio = " in ye _col(49) %5.2f `ratx' 
  di in gr " by Freedman/Peto: "            in ye   _col(39)   %6.1f `d3x'    _col(48)  %6.1f `d3x'/`sum' 
  di in gr " by Freedman/Peto (modified): " in ye   _col(39)   %6.1f `d4x'    _col(48)  %6.1f `d4x'/`sum' 
  di in gr " by Schoenfeld: "               in ye   _col(39)   %6.1f `d2x'    _col(48)  %6.1f `d2x'/`sum' 

  *Om te vergelijken met sampsi2 berekeningen:
  global Ntot2=`d3'/`sum'
  global Ntot3=`d4'/`sum'
  global Ntot4=`d2'/`sum'
  global Ntot5=`d3x'/`sum'
  global Ntot6=`d4x'/`sum'
  global Ntot7=`d2x'/`sum'

  if `nstr'>1 {
    di in gr _n "Numbers per stratum"
    local s=1
    while `s'<=`nstr' {
      di in gr "`str`s''" _col(20) "Subjects:" in ye _col(40) %5.1f `N1`s'' _skip(4) %5.1f `N2`s'' _skip(4) %5.1f `N_`s''
      di in gr _col(20)            "Events  :" in ye _col(40) %5.1f `D1`s''  _skip(4) %5.1f `D2`s''  _skip(4) %5.1f `D_`s'' 
      local s=`s'+1
    }
  }
}

/* Compute power. */

else {
  if `n2' == 0 {  /* determine n2 from n1 and ratio */
*   local n2 = `n1'/`ratio'   /* error detected on 16/9/00 after mail by M Camus */
    local n2 = `n1'*`ratio'
    if `n2' ~= int(`n2') { local n2 = int(`n2' + 1) }
  }
  else if `n1' == 0 {  /* determine n1 from n2 and ratio */
*   local n1 = `n2'*`ratio'
    local n1 = `n2'/`ratio'
    if `n1' ~= int(`n1') { local n1 = int(`n1' + 1) }
  }
* local ratio=`n1'/`n2'
  local ratio=`n2'/`n1'
  local N1 `n1'
  local N2 `n2'
  local N=`N1'+`N2'
  local D1=0
  local D2=0
  local s=1
  while `s'<=`nstr' {
    local N1`s'=`prev`s''*`N1'
    local N2`s'=`prev`s''*`N2'
    local N_`s'=`N1`s''+`N2`s''
    local D1`s'=`s1`s''*`N1`s''
    local D2`s'=`s2`s''*`N2`s''
    local D_`s'=`D1`s''+`D2`s''
    local D1=`D1'+`D1`s''
    local D2=`D2'+`D2`s''
    local s=`s'+1
  }
  local D=`D1'+`D2'

  local zb= abs((`D'*`ratio')^.5*(`hr'-1)/(`hr'*`ratio'+1))-`za' /*Freedman Peto formula*/
  local power = normprob(`zb')
  #delimit ;
  if "`equiv'"~="" { ;
  	di _n in gr "Estimated power for two-sample comparison of survival curves" _n(2)
	  "Non-inferiority study with " _n " S1 survival function in control group"
	  _n " S2 Survival function in experimental group" _n 
	  " Test Ho: S2<=S1 - D for some positive difference D, versus " _n 
	  "      Ha: S2>=S1, S2 at least as good as S1." _n
	  " The difference D is expressed as proportional hazard (>1) rate below." _n(2)
	  "Assumptions:" _n(1) 
		_col(10) in gr  "Proportional hazard rate" _col(35) "= " in ye %8.3f `hr' _n 
		_col(10) in gr  "   Accrual period [`tu']" _col(35) "= " in ye %8.1f `ap' _n 
		_col(10) in gr  "   Additional FU  [`tu']" _col(35) "= " in ye %8.1f `fu' _n 
		_col(10) in gr  "                   alpha" _col(35) "= " in ye %8.4f `alpha' _c ;
	} ;
	else  { ;
    di _n in gr "Estimated power for two-sample comparison of survival curves" _n(2)
    "Test Ho: S1 = S2, where S1 is the Survival function in population 1" _n _col(21)
    "and S2 is the Survival function in population 2" _n(2) "Assumptions:" _n(1) 
    _col(10) in gr  "Proportional hazard rate" _col(35) "= " in ye %8.3f `hr' _n 
    _col(10) in gr  "   Accrual period [`tu']" _col(35) "= " in ye %8.1f `ap' _n 
    _col(10) in gr  "   Additional FU  [`tu']" _col(35) "= " in ye %8.1f `fu' _n 
    _col(10) in gr  "                   alpha" _col(35) "= " in ye %8.4f `alpha' _c ;
  } ;
  if "`oneside'"~="" { di in gr "  (one-sided)" _n } ;
  else                { di in gr "  (two-sided)" _n }  ;
  di in gr "Survival probabilities [%]:    Time    Arm 1    Arm 2    Total";

  #delimit cr
  if `nstr'>1 {  di in gr " `str1', Prevalence:" %4.2f `prev1'   }
  local i=1
  while `i'<=`nt' {
    scalar p1=`p1`i''*100
    scalar p2=`p2`i''*100
    di in gr _col(32) %4.0f `t`i'' _skip(4)  %5.1f p1  _skip(4) %5.1f p2 
    local i=`i'+1
  }
  local s=1
  while `s'<=`nstr' {
    if `s'>1 {di in gr " `str`s'', Prevalence: " %4.2f `prev`s''  _col(40) "RHR vs `str1': " %5.2f `hr`s''}
    scalar p1=`S1a'^`hr`s''*100
    scalar p2=`S2a'^`hr`s''*100
    di in gr "           Minimum FU [`tu']:" _col(32) %4.0f `fu' _skip(4)  %5.1f p1  _skip(4) %5.1f p2
    scalar p1=`S1b'^`hr`s''*100
    scalar p2=`S2b'^`hr`s''*100
    di in gr "           Maximum FU [`tu']:" _col(32) %4.0f t _skip(4)  %5.1f p1  _skip(4) %5.1f p2 _n
    local s=`s'+1
  }     
  di in gr "Number of subjects  :" in ye _col(40) %5.0f `N1' _skip(4) %5.0f `N2' _skip(4) %5.0f `N'
  di in gr "Expected number of events:" in ye _col(40) %5.1f `D1'  _skip(4) %5.1f `D2'  _skip(4) %5.1f `D' 
  if `nstr'>1 {
    di in gr _n "Numbers per stratum"
    local s=1
    while `s'<=`nstr' {
      di in gr "`str`s''" _col(20) "Subjects:" in ye _col(40) %5.1f `N1`s'' _skip(4) %5.1f `N2`s'' _skip(4) %5.1f `N_`s''
      di in gr _col(20)            "Events  :" in ye _col(40) %5.1f `D1`s''  _skip(4) %5.1f `D2`s''  _skip(4) %5.1f `D_`s'' 
      local s=`s'+1
    }
  }
  di _n in gr "Power according to Freedman/Peto formulas:"   _col(40) in ye %11.3f `power' _n 
}

if "`nrat'"!="" {
  if `nstr'>1 {
    local rest strhr(`strhr') prev(`prev') 
    if "`names'"~="" { local rest `rest' `names(`names') }
  }
  if "`n1'"=="" { local n1 `N1'}
  local m `n1'
  nois display `" n1(`m')"'
  nois display `" `rest'  n1(`m') "'
  nois display `"   nrat ,at(`nrat') p1(`p1') hr(`hr') ratio(`ratio') ap(`ap') tu(`tu') n1(`m') `rest'  "'

  nrat ,at(`nrat') p1(`p1') hr(`hr') ratio(`ratio') ap(`ap') tu(`tu')  n1(`m') `rest'
end


