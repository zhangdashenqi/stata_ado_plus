*! version 2.00 97/01/15        STB-38 snp13
program define warpdenm
  version 5.0
*First written 94/11/09 ; Last revised 97/04/09
*Authors: Salgado-Ugarte I.H., M. Shimizu and T. Taniuchi.
*This program calculates kernel density estimator of a series of 
*values using the WARPing procedure with weight functions coded
*as follows:
* 1 = Uniform
* 2 = Triangle 
* 3 = Epanechnikov
* 4 = Quartic (Biweight)
* 5 = Triweight
* 6 = Gaussian
*Based on the procedures described in Haerdle (1991) and Scott (1992)
*This new version includes two new options: 'numodes' that gives the
*number of modes and 'modes' that list their estimated values; 'npoints'
*gives the number of points used for the density estimation

local varlist "req ex min(1) max(1)"
local if "opt"
local in "opt"
#delimit ;
local options "Bwidth(real 0) Mval(integer 0) Kercode(integer 0) STep NUMOdes
 MOdes NPoints Gen(string) noGraph T1title(string) Symbol(string) Connect(string) *";
#delimit cr
parse "`*'"
parse "`varlist'", parse(" ")
quietly {
preserve
if "`gen'"~="" {
   tempfile _data
   save `_data'
   }

tempvar xvar
gen `xvar'=`1' `if' `in'
drop if `xvar'==.
if `xvar'[1]==. {
   di in red "no observations"
   exit}
keep `xvar'
local hv=`bwidth'
local mv=`mval'
local kc=`kercode'

if `hv'==0 {
     di in red "you must provide the bandwidth"
     exit}
if `mv'==0 {
     di in red "you must provide the number of shifted histograms"
     exit}
if `kc'==0 {
     di in red "you must provide the kernel code"
     exit}
if `kc'>6 {
     di in red "invalid choice of kernel"
     exit} 

if "`modes'"~="" & "`numodes'"=="" {
     di in red "you must include the 'numodes' option"
     exit}

  tempvar midval index freq
  summ `xvar'
  scalar nuobs=_result(1)
  scalar maxval=_result(6)
  scalar minval=_result(5)
  tempvar index2
  if `kc'==6 {
      scalar hval=`hv'*4
      }
  else {
      scalar hval=`hv'
      }
  scalar mval=`mv'
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

 gen `index'=int((`xvar'-origin)/delta)
 gen `index2'=`index'
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
 tempvar cm wm wm2 count
 if `kc'==1 {
    gen `cm'=mval/((2*mval-1)*(nuobs*hval))
    gen `wm'=`cm'
    }
 else if `kc'==2 {
    gen `cm'=1/(nuobs*hval)
    gen `wm'=`cm'*(1-(_n-1)/mval)
    }
 else if `kc'==3 {
    gen `cm'=3*mval^2/((4*mval^2-1)*(nuobs*hval))
    gen `wm'=`cm'*(1-((_n-1)/mval)^2)
    }
 else if `kc'==4 {
    gen `cm'=0.9375/((1-0.0625/mval^4)*(nuobs*hval))
    gen `wm'=`cm'*(1-((_n-1)/mval)^2)^2
    }
 else if `kc'==5 {
    tempvar part1 part2
    gen `part1'= 1+0.14583333/mval^4
    gen `part2'= 0.05208333/mval^6
    gen `cm'=1.09375/((`part1'-`part2')*(nuobs*hval))
    gen `wm'=`cm'*(1-((_n-1)/mval)^2)^3
    }
else {
    gen `cm'=0.3989*4/(nuobs*hval)
    gen `wm'=`cm'*exp(-8*((_n-1)/mval)^2)
    }
replace `wm'=0 if _n>mval
gen `wm2'=`wm'[_n-(mval-1)]                                                        
replace `wm2'=`wm'[(mval+1)-_n] if _n<mval
tempvar fh fh1 fh2 lfh
summ `freq'
scalar binum=_result(1)
gen `fh'=0
gen `fh1'=0
gen `fh2'=0
gen `count'=1
while `count' <= binum {
    replace `fh1'=`wm2'*`freq'[`count'] if _n<mval*2
    replace `fh2'=`fh1'[_n-(`index'[`count']-mval)]
    replace `fh2'=0 if `fh2'==.
    replace `fh'=`fh'+`fh2'
    replace `fh2'=0
    replace `fh1'=0
    replace `count'=`count'+1
    }
gen `midval'=((0.5+(_n-1))*delta)+origin
if `numbin'<_N {
    replace `fh'=. if _n>`numbin'
    replace `midval'=. if _n>`numbin'
    }
gen `lfh'=`fh'[_n-(`index'[1]-mval)]
replace `lfh'=0 if `lfh'==.
*replace `midval'=(`midval'[_N-1]-`midval'[_N-2])+`midval'[_N-1] if _n==_N
if `numbin'<_N {
    replace `lfh'=. if _n>`numbin'
    }
tempvar inter lowcut
if "`graph'" ~= "nograph"  {
   if "`t1title'" ==""{
      if "`step'"~="" {
         local t1title "WARPing density (step version)"
         local t1title "`t1title', bw = `hv', M = `mv', Ker = `kc'"
      }
      else {
         local t1title "WARPing density (polygon version)"
         local t1title "`t1title', bw = `hv', M = `mv', Ker = `kc'"
      }           
   }
   if "`symbol'"=="" { local symbol "." }
   if "`connect'"=="" { 
      if "`step'"~="" {local connect "J" }
      else {local connect "l" }
   }
   if "`step'"~="" {
     gen `inter'=`midval'[2]-`midval'[1]
     gen `lowcut'=`midval'-(`inter'/2)
     label variable `lfh' "Density"
     label variable `lowcut' "Lower cutoff"
     graph `lfh' `lowcut',  `options' /*
				*/ t1("`t1title'") /*
				*/ s(`symbol') c(`connect') 
   }
   else {
      label variable `lfh' "Density"
      label variable `midval' "Midpoints"
      graph `lfh' `midval', `options' /*
				*/ t1("`t1title'") /*
				*/ s(`symbol') c(`connect') 
   }
}

if "`numodes'"~="" {
   tempvar difvar inmo sumo
   gen `difvar'=`lfh'[_n+1] - `lfh'[_n]
   gen `inmo' = 0
   replace `inmo'=1 if `difvar'[_n]>=0 & `difvar'[_n+1] < 0
   gen `sumo' = sum(`inmo')
   local numo= `sumo'[_N]
   noi di _newline " Number of modes = " `numo'
   }

if "`modes'"~="" {
   tempvar modes
   gen `modes'=.
   replace `modes'=`midval' if `inmo'[_n-1]==1 
   sort `modes'
   local i = 1
   noi di _newline _dup(75) "_"
   local title " Modes in WARPing density estimation"
   noi di "`title', bw = `hv', M = `mv', Ker = `kc'"
   noi di _dup(75) "-"
   while `i'<`numo'+1 {
      noi di " Mode ( " %4.0f `i' " ) = " %12.4f `modes'[`i']
      local i = `i'+1
      }
   noi di _dup(75) "_"
   sort `midval'
   }

if "`npoints'"~="" {
   summ `midval'
   local np = _result(1)
   noi di _newline " Number of estimated points = " `np'
   }
if "`gen'"~="" {
   restore, not
   merge using `_data'
   drop _merge
   parse "`gen'", parse(" ")  
   gen `1'=`lfh'
   gen `2'=`midval'
   }

}

end
