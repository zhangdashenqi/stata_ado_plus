*! version 1.00 28/02/97       STB-38 snp13
program define silvtest
  version 4.0
*First written 28/02/79; Last revision 25/03/97 
*Author: Salgado-Ugarte
*This program calculates the pvalue of the multimodality test of
*Silverman by using a Gaussian kernel density estimator on a series
*of bootstrapped samples generated with the bstrap bootsam ado-files
*combination for a given number of modes.
*To estimate the KDE it uses the WARPing procedure based on the
*algorithms described in Haerdle (1991) and Scott (1992)

local varlist "req ex min(2) max(2)"
local if "opt"
local in "opt"
#delimit ;

local options 
 "CRitbw(real 0) Mval(integer 0) NURIni(integer 1) NURFin(integer 0) 
  CNModes(integer 0) noGraph T1title(string) Symbol(string)
  Connect(string) *";

#delimit cr
parse "`*'"
parse "`varlist'", parse(" ")
quietly {

preserve

tempvar xvar countr
gen `xvar'=. if `2'==1

if `critbw'==0 {
     di in red "you must provide the critical bandwidth"
     exit}

if `mval'==0 {
     di in red "you must provide the number of shifted histograms"
     exit}

scalar nri=`nurini'
scalar nrf=`nurfin'

if nrf==0 {
     di in red "you must provide the final repetition number"
     exit} 

if `cnmodes'==0 {
     di in red "you must provide the critical number of modes"
     exit}

gen `countr'=nri

tempvar difvar mode sumo
gen `difvar'=0
gen `mode'=0
gen `sumo'=0

tempvar cm wm wm2 count
gen `cm'=0
gen `wm'=0
gen `wm2'=0
gen `count'=0

tempvar fh fh1 fh2 lfh
gen `fh'=0
gen `fh1'=0
gen `fh2'=0
gen `lfh'=0

tempvar midval index index2 
gen `midval'=0
gen `index'=0
*gen `index2'=0

tempfile _data
save `_data'

tempvar numera
gen `numera'=0

set more off
while `countr'<=nrf {

  replace `xvar'=`1' if `2'==`countr'
  drop if `xvar'==.
  gen `index2'=0 

  summ `xvar'
  local hv=`critbw'
  local mv=`mval'
  local cnm=`cnmodes'
  scalar nuobs=_result(1)
  scalar maxval=_result(6)
  scalar minval=_result(5)


  replace `index'=0
  replace `index2'=0

  scalar hval=`hv'*4
  scalar mval=`mv'
  scalar cnmv=`cnm'
  scalar delta=hval/mval
  local numbin=int((maxval-minval)/delta)+2*(mval+1+round((mval/10)+0.5),1)
  if `numbin'>_N {
      set obs `numbin'
      }
  scalar start=(minval-hval)-delta*.1
  if start<0 {
     scalar origin=(round(((start/delta)-0.5),1)-0.5)*delta
     }
  else {
     scalar origin=(int(start/delta)-0.5)*delta
     }

  replace `index'=int((`xvar'-origin)/delta)
  replace `index2'=`index'
  tempvar freq

  egen `freq'=count(`xvar'), by(`index2')
  replace `freq'=. if `index2'[_n-1]==`index2'[_n]
  replace `index'=. if `index2'[_n-1]==`index2'[_n]
  tempfile resu1 resu2
  save `resu1'
  keep `index' `freq'
  drop if `freq'==.
  tempvar freqc indexc
  rename `index' `indexc'
  rename `freq' `freqc'
  save `resu2'
  use `resu1', clear
  merge using `resu2'
  drop `index' `freq' _merge `index2'
  rename `indexc' `index'
  rename `freqc' `freq'

  replace `cm'=0.3989*4/(nuobs*hval)
  replace `wm'=`cm'*exp(-8*((_n-1)/mval)^2)

  replace `wm'=0 if _n>mval
  replace `wm2'=`wm'[_n-(mval-1)]                                                        
  replace `wm2'=`wm'[(mval+1)-_n] if _n<mval

  summ `freq'
  scalar binum=_result(1)
  replace `fh'=0
  replace `fh1'=0
  replace `fh2'=0
  replace `count'=1
  while `count' <= binum {
    replace `fh1'=`wm2'*`freq'[`count'] if _n<mval*2
    replace `fh2'=`fh1'[_n-(`index'[`count']-mval)]
    replace `fh2'=0 if `fh2'==.
    replace `fh'=`fh'+`fh2'
    replace `fh2'=0
    replace `fh1'=0
    replace `count'=`count'+1
    }
  replace `midval'=((0.5+(_n-1))*delta)+origin
  if `numbin'<_N {
    replace `fh'=. if _n>`numbin'
    replace `midval'=. if _n>`numbin'
    }
  replace `lfh'=`fh'[_n-(`index'[1]-mval)]
  replace `lfh'=0 if `lfh'==.
*replace `midval'=(`midval'[_N-1]-`midval'[_N-2])+`midval'[_N-1] if _n==_N
  if `numbin'<_N {
      replace `lfh'=. if _n>`numbin'
      }


if "`graph'" ~= "nograph"  {
   if "`t1title'" ==""{
      
         local t1title "WARPing density"
         local t1title "`t1title', bw = `hv', M = `mv', Gaussian kernel"
         }
   if "`symbol'"=="" { local symbol "." }
   if "`connect'"=="" { 

      local connect "l" 
   }
   
      label variable `lfh' "Density"
      label variable `midval' "Midpoints"
      graph `lfh' `midval', `options' /*
				*/ t1("`t1title'") /*
				*/ s(`symbol') c(`connect') 

}

   replace `difvar'=`lfh'[_n+1] - `lfh'[_n]
   replace `mode' = 0
   replace `mode'=1 if `difvar'[_n]>=0 & `difvar'[_n+1] < 0
   replace `sumo' = sum(`mode')
   local nomo= `sumo'[_N]
   
   noi display "bs sample " _col(15)`countr' _col(30)"Number of modes = " `nomo'
   replace `countr'=`countr'+1
   
   replace `numera'= `numera'+1 if `nomo'>cnmv

   keep `countr' `numera'
   merge using `_data'
   drop _merge
   replace `countr'=`countr'[1]
   replace `numera'=`numera'[1]
} *while

} *quietly

di _newline "Critical number of modes = " _col(15)%6.0f cnmv
di _newline "Pvalue = " _col(15)%6.0f `numera'[1] " / " nrf-nri+1 " = " _col(30)%8.4f `numera'[1]/(nrf-nri+1)


set more on
end
