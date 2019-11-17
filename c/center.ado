*! version 1.08, Ben Jann, 01sep2013
*! - option inplace added
*! version 1.07, Ben Jann, 22feb2006
program define center, byable(onecall) sortpreserve
version 7.0
syntax varlist(numeric) [if] [in] [aw fw/] [, PREfix(string) noLabel Addtolabel(string) /*
 */ Replace Double Standardize MEANsave MEANsave2(string) SDsave SDsave2(string) /*
 */ Casewise THeta(string) Generate(string) Inplace ]

if "`inplace'"!="" {
 if `"`prefix'"'!="" {
  di as error "prefix() not allowed with inplace"
  exit 198
 }
 if `"`generate'"'!="" {
  di as error "generate() not allowed with inplace"
  exit 198
 }
 local prefix
}
else if `"`generate'"'!="" {
 if `"`prefix'"'!="" {
  di as error "prefix() not allowed if generate() is specified"
  exit 198
 }
 local nvars: word count `varlist'
 if `nvars'>1 {
  di as error "too many variables specified"
  exit 103
 }
 confirm name `generate'
 local prefix `"`generate'"'
}
else if `"`prefix'"'!="" {
 confirm name `prefix'
}
else {
 local prefix "c_"
}
if `"`theta'"'!="" {
 capture confirm number `theta'
 if _rc {
  capture confirm numeric variable `theta'
  if _rc {
   di as error "invalid specification of theta()"
   exit 198
  }
 }
}
else {
 local theta 1
}
if "`meansave'"!="" {
 local meansave "m_`generate'"
}
if "`meansave2'"!="" {
 local meansave "`meansave2'"
}
if "`meansave'"!="" {
 confirm name `meansave'
}
if "`sdsave'"!="" {
 local sdsave "sd_`generate'"
}
if "`sdsave2'"!="" {
 local sdsave "`sdsave2'"
}
if "`sdsave'"!="" {
 if "`standardize'"=="" {
  di as error "sdsave not allowed unless standardize is specified"
  exit 198
 }
 confirm name `sdsave'
}
if "`inplace'"=="" {
 foreach name of local varlist {
  if "`generate'"=="" {
   local nname `name'
  }
  local mpre=cond("`meansave'"!="","meansave","")
  local sdpre=cond("`sdsave'"!="","sdsave","")
  foreach pre in prefix `mpre' `sdpre' {
   capture confirm new variable ``pre''`nname'
   if _rc {
    if "`replace'"!=""{
     drop ``pre''`nname'
    }
    else {
     di as error "``pre''`nname' already defined or invalid name"
     exit 110
    }
   }
  }
 }
}
if "`label'"=="" {
 if `"`addtolabel'"'=="" {
  if "`standardize'"!="" {
   local addtolabel " (standardized)"
  }
  else {
   local addtolabel " (centered)"
  }
 }
 local llength=80-length(`"`addtolabel'"')
}

if "`casewise'"=="" {
 marksample touse, novarlist
}
else {
 marksample touse
}

if "`exp'"=="" {
 local exp "\`name'!=."
}
if "`standardize'"!="" {
 if "`weight'"=="fweight" {
  local exp2 "`exp'"
 }
 else {
  local exp2 "\`name'!=."
 }
}
else {
 local sd 1
}

sort `touse' `_byvars'
foreach name of local varlist {
 if "`generate'"=="" {
  local nname `name'
 }
 quietly {
   tempvar mean
   by `touse' `_byvars': gen `double' `mean' = /*
           */ sum((`exp')*`name')/sum((`exp')*(`name'!=.)) if `touse'
   by `touse' `_byvars': replace `mean' = `mean'[_N]
   if "`standardize'"!="" {
    tempvar sd
    by `touse' `_byvars': gen `double' `sd' = /*
           */ sum((`exp')*(`name'!=.))-sum((`exp')*(`name'!=.))/sum((`exp2')*(`name'!=.)) if `touse'
    by `touse' `_byvars': replace `sd' = /*
           */ sum((`exp')*(`name'-`mean')^2) / `sd' if `touse'
    by `touse' `_byvars': replace `sd' = sqrt(`sd'[_N])
   }
   if "`inplace'"!="" {
     replace `name' = (`name' - `theta'*`mean') / `sd'  if `touse'
   }
   else {
     gen `double' `prefix'`nname' = (`name' - `theta'*`mean') / `sd'  if `touse'
   }
 }
 if "`meansave'"!="" {
  qui replace `mean'=. if `name'==.
  rename `mean' `meansave'`nname'
 }
 if "`sdsave'"!="" {
  qui replace `sd'=. if `name'==.
  rename `sd' `sdsave'`nname'
 }
 if "`label'"=="" {
  local lab: var l `name'
  if `"`lab'"'=="" {
   local lab `name'
  }
  local lab=substr(`"`lab'"',1,`llength')
  lab var `prefix'`nname' `"`lab'`addtolabel'"'
  if "`meansave'"!="" {
   lab var `meansave'`nname' `"mean(s) of `name'"'
  }
  if "`sdsave'"!="" {
   lab var `sdsave'`nname' `"std. deviation(s) of `name'"'
  }
 }
}
end
