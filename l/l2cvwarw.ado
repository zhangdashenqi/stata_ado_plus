*! version 1.01 94/9/26  STB-38 snp13
program define l2cvwarw
  version 4.0
*First written for Windows 95/02/01; Last revised 95/03/07
*This program calculates least squares crossvalidation for warping
*density estimation using a TurboPascal program which utilizes
*modified algorithms from Haerdle (1991) "Smoothing Techniques with
*Implementations in S", Springer-Verlag Series in Statistics,
*New York 
*Kernel codes:
*1 Uniform
*2 Triangle
*3 Epanechnikov
*4 Quartic (Biweight)
*5 Triweight
*6 Gaussian
local varlist "req ex min(1) max(1)"
local if "opt"
local in "opt"
#delimit ;
local options "Delta(real 0) Kercode(integer 0) MStart(integer 1)
     MEnd(integer 0) Gen(string) noGraph T1title(string) Symbol(string)
     Connect(string) *";
#delimit cr
parse "`*'"
parse "`varlist'", parse(" ")
quietly {
preserve
  if "`gen'"~="" {
     tempfile _data
     save `_data'
     }
  local deltav=`delta'
  local kco=`kercode'
  summ `1'
  sort `1' 
  if "`mstart'"~="" {
    local ms=`mstart'
  }
  if "`mend'"~="" {
    local me=`mend'
  }

tempvar xvar
gen `xvar'=`1' `if' `in'
drop if `xvar'==.
if `xvar'[1]==. {
   di in red "no observations"
   exit}
outfile `xvar' using _data2, replace
tempvar dval kc msv mev
gen `dval'=`deltav'
if `dval'==0 {
   di in red "you must provide the delta value"
   exit}
gen `kc'=`kco'
if `kc'==0 {
     di in red "you must provide the kernel code"
     exit}

if `kc'<1 | `kc'>6 {
   di in red "invalid kernel code"
   exit}
gen `msv'=`ms'
if `msv'<1 {
   di in red "you must use a Mstart > 0"
   exit}
gen `mev'=`me'
replace `mev'=int(0.33*((_result(6)-_result(5))/`delta')) if `me'==0
keep `dval' `kc' `msv' `mev'
drop if _n>1
set obs 1
outfile using _inpval, replace
drop _all

*added for call DOS program
winexec dosprmpt.pif /c l2cvwarw
capture confirm file signfile
while _rc ~=0 {
          capture confirm file signfile
}
erase signfile

erase _data2.raw
erase _inpval.raw 
tempvar mval cv hval
infile `mval' `cv' `hval' using resfile.
label variable `mval' "M-value"
label variable `cv' "CV-value"
label variable `hval' "Bandwidth"

if "`graph'" ~= "nograph"  {
   if "`t1title'" ==""{
         local t1title "L2 Cross Validation (WARP)"
         local t1title "`t1title', delta = `deltav', Kernel = `kco'"
   }
   if "`symbol'"=="" { local symbol "." }
   if "`connect'"=="" { local connect "l" }
   graph `cv' `mval', `options' t1("`t1title'") /*
                          */ s(`symbol') c(`connect')
}

sort `cv'
local i = 1
noi di _newline _dup(79) "-"

local title "Least Squares Cross-validation for WARPing density estimation"
if `kco'==1 {
   local kerlab "Uniform kernel"
   }
else if `kco'==2 {
   local kerlab "Triangle kernel"
   }
else if `kco'==3 {
   local kerlab "Epanech. kernel"
   }
else if `kco'==4 {
   local kerlab "Quartic kernel"
   }
else if `kco'==5 {
   local kerlab "Triweight kernel"
   }
else {
   local kerlab "Gaussian kernel"
   }
local title "`title', `kerlab'"
noi di "`title'"

noi di _dup(79) "-"
while `i'<6 {
noi di "CV-value = " %10.8f `cv'[`i'] _column(30) "M-value = " %5.0g `mval'[`i'] _column(50) "Bandwidth = " %8.4f `hval'[`i']
      local i = `i'+1
   }
erase resfile
if "`gen'"~="" {
   restore, not
   merge using `_data'
   drop _merge
   parse "`gen'", parse(" ")  
   gen `1'=`cv'
   gen `2'=`mval'
   gen `3'= `hval'
   }
}
end
