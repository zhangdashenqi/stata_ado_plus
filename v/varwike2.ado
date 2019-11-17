*! varwike2 1.00 IHSU 14/05/99; last revision 23/03/2001        (SJ3-2: st0036)
* Adapted from adgaker2 2.00 13/08/94
* Isaias H. Salgado-Ugarte, Makoto Shimizu and Toru Taniuchi.
* Revised and updated version of adgaker2 by Isaias H. Salgado-Ugarte
* Following suggestions by Nick Cox
*This program is an updated version that calculates a variable
*bandwidth kernel density estimator of a  
*series of values according to the gaussian weight function and the
*adaptive procedure described in Fox, (1990) and Silverman(1986)
*For simplicity, this version only takes as a default 50 equally
*space points as suggested by Chambers, et al. (1983), but the 
*user may chose another number of estimation points if desired.

program define varwike2
   version 6.0

   #delimit ;
   syntax varlist(min=1 max=1) [if] [in]
   , Bwidth(real) [NPoint(int 50) Gen(str) NUMOdes MOdes noGraph  
   T1title(str) Symbol(str) Connect(str) * ] ;
   #delimit cr

  quietly {
   local hv `bwidth'
   local np `npoint'

   if "`npoint'"~="" {
        local np = `npoint'
   }


   tokenize `varlist'
   *args xvar 

   preserve   

   if "`gen'"~="" {
   tempfile _data
   save `_data'
   }

  
   marksample touse
   qui count if `touse'
   if r(N) == 0 {error 2000}

  tempvar xvar
  gen `xvar'=`1' `if' `in'

  tempvar fkx xo z kz sums

     if `np' >_N { 
 
	set obs `np' 
     }
  
  if "`modes'"~="" & "`numodes'"=="" {
     di in red "you must include the 'numodes' option"
     exit}

  sum `xvar' if `touse', meanonly
  local nuobs =r(N)
  gen `fkx'=0
  local count=1
  gen `xo'=0
  gen `sums'=0
  gen `z'=0
  gen `kz'=0
  *set more 1
*noi di "WORKING WITH EACH VALUE. PLEASE BE PATIENT"
  while `count'<=_N {        
    *noi di "Calculating fk(x) number = " `count'
    replace `xo'=`xvar'[`count']
    replace `z'=(`xo'-`xvar')/`hv'
    replace `kz'=(1/(sqrt(2*_pi)))*exp(-.5*`z'^2) if abs(`z')<2.5
    replace `sums'= sum(`kz')
    replace `fkx'=(1/(`nuobs'*`hv'))*`sums'[_N] if _n==`count'
    replace `kz'=0
    local count=`count'+1
  }

  *Calculating local weights
  tempvar lnfkx lnfg fg winfac
  gen `lnfkx'=log(`fkx')
  summ `lnfkx'
  gen `lnfg'=r(mean)
  gen `fg'=exp(`lnfg')
  gen `winfac'=sqrt(`fg'/`fkx')
  tempvar xo2 z2 kz2 sums2 fkx2 
  local count2=1
  gen `xo2'=0
  gen `z2'=0
  gen `kz2'=0
  gen `sums2'=0
  gen `fkx2'=0

  *Preparing 50 equally spaced points
  tempvar maxval minval range inter midval
  summ `xvar'
  local maxval=r(max)+`hv'+((r(max)-r(min))*0.1)
  local minval=r(min)-`hv'-((r(max)-r(min))*0.1)
  local range=`maxval'-`minval'
  gen `inter'=`range'/`np'
  gen `midval'=sum(`inter')+`minval'+`inter'/2
  *noi di "CALCULATING ADAPTIVE VALUES. DON'T DESPAIR"
  while `count2'<=`np' { 
    *noi di "Working with adaptive value number = " `count2'
    replace `xo2'=`midval'[`count2']
    replace `z2'=(`xo2'-`xvar')/(`winfac'*`hv')
    replace `kz2'=(1/(sqrt(2*_pi)))*exp(-.5*`z2'^2) if abs(`z2')<2.5
    replace `sums2'=sum(`kz2'/`winfac')
    replace `fkx2'=(1/(`nuobs'*`hv'))*`sums2'[_N] if _n==`count2'
    replace `kz2'=0
    local count2=`count2'+1
  }  
  if `np' < _N {
    replace `fkx2'=. if _n> `np'
    replace `midval'=. if _n>`np'
  }

   * _crcslbl `xvar' `1'

    if "`graph'" ~= "nograph"  {

       if "`t1title'" =="" { 
              local t1title "Variable bandwidth density"
              local t1title "`t1title', bw(Gmean) = `hv', np = `np'"
       }

       if "`symbol'" == "" { local symbol "." }
       if "`connect'" == "" { local connect "l" }

    label variable `fkx2' "Density"
    label variable `midval' "Midpoints"

    graph `fkx2' `midval', `options' /*
       */ t1("`t1title'") s(`symbol') c(`connect')
    }

if "`numodes'"~="" {
   tempvar difvar inmo sumo
   gen `difvar'=`fkx2'[_n+1] - `fkx2'[_n]
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
   local title " Modes in variable bandwidth KDE"
   noi di "`title', bw (Gmean) = `hv', npoints = `np'
   noi di _dup(75) "-"
   while `i'<`numo'+1 {
      noi di " Mode ( " %4.0f `i' " ) = " %12.4f `modes'[`i']
      local i = `i'+1
      }
   noi di _dup(75) "_"
   sort `midval'
   }

    if "`gen'" ~= "" {
       restore, not
       merge using `_data'
       drop _merge 
       tokenize `gen'
       gen `1' = `fkx2'
       gen `2' = `midval'
    }

}
end
