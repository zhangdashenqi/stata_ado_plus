*! version 1.00 94/9/27      STB-38 snp13
program define bcvwarpw
  version 4.0
*First written for Windows 95/02/01; Last revised 95/03/04
*This program calculates biased crossvalidation for warping
*density estimation using a TurboPascal program which utilizes
*modified algorithms from Haerdle (1991) "Smoothing Techniques with
*Implementations in S", Springer-Verlag Series in Statistics,
*New York 
*The kernel implemented are
*1 Quartic (Biweight)
*2 Triweight
local varlist "req ex min(1) max(1)"
local if "opt"
local in "opt"
#delimit ;
local options "Delta(real 0) Kercod(integer 0) MStart(integer 1)
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
  local kco=`kercod'
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
summ `xvar'
sort `xvar'
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
if `kc'<1 | `kc'>2 {
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

*added to call DOS program
winexec dosprmpt.pif /c bcvwarpw
capture confirm file signfile
while _rc ~=0 {
          capture confirm file signfile
}
erase signfile

erase _data2.raw
erase _inpval.raw 
tempvar mval bcv hval
infile `mval' `bcv' `hval' using resfile.
label variable `mval' "M-value"
label variable `bcv' "BCV-value"
label variable `hval' "Bandwidth"

if "`graph'" ~= "nograph"  {
   if "`t1title'" ==""{
         local t1title "Biased Cross Validation (WARP)"
         local t1title "`t1title', delta = `deltav', Kernel = `kco'"
   }
   if "`symbol'"=="" { local symbol "." }
   if "`connect'"=="" { local connect "l" }
   graph `bcv' `mval', `options' t1("`t1title'") /*
                          */ s(`symbol') c(`connect')
}

sort `bcv'
local i = 1
noi di _newline _dup(75) "-"
local title "Biased Cross-validation for WARPing density estimation"
if `kco'==1 {
   local kerlab "Quartic kernel"
   }
else {
   local kerlab "Triweight kernel"
   }
local title "`title', `kerlab'"
noi di "`title'"
noi di _dup(75) "-"
while `i'<6 {
noi di "Biased Cv-value = " %10.8f `bcv'[`i'] _column(32) "M-value = " %5.0g `mval'[`i'] _column(50) "Bandwidth = " %8.4f `hval'[`i']
      local i = `i'+1
   }
erase resfile
if "`gen'"~="" {
   restore, not
   merge using `_data'
   drop _merge
   parse "`gen'", parse(" ")  
   gen `1'=`bcv'
   gen `2'=`mval'
   gen `3'= `hval'
   }
}
end
