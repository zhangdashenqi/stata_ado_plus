*! varwiker 1.00 IHSU 14/05/99; last revised 05/10/99           (SJ3-2: st0036)
* Adapted from adgakern 1.00 20/05/93   STB-16: snp6 by
* Isaias H. Salgado-Ugarte, Makoto Shimizu and Toru Taniuchi.
* Revised and updated version by Isaias H. Salgado-Ugarte
* Following suggestions by Nick Cox
*This program is an updated version of adgakern.ado which 
*calculates a variable bandwidth kernel density estimator of a  
*series of values according to the gaussian weight function and the
*procedure described in Fox, (1990) and Silverman(1986)

program define varwiker
   version 6.0


   #delimit ;
   syntax varlist(min=1 max=1) [if] [in]
   , Bwidth(real) [Gen(str) noGraph T1title(str) 
   Symbol(str) Connect(str) * ] ;
   #delimit cr

   quietly {
   local hv `bwidth'

   tokenize `varlist'
   *args xvar

   if "`gen'"~="" {
   tempfile _data
   save `_data'
   }

   marksample touse
   qui count if `touse'
   if r(N) == 0 {error 2000}
   *l `xvar' `touse'

  tempvar xvar
  gen `xvar'=`1' `if' `in'

   tempvar fkx xo z kz sums

      preserve
      drop if `touse' ==0 

      summarize `xvar' /* if `touse' */, meanonly 
      local nuobs = r(N)
      gen `fkx'=0
      local count=1
      gen `xo'=0
      gen `sums'=0
      gen `z'=0 
      gen `kz'=0      

    *set more 1
    while `count'<= _N {        
    *noi di "Calculating fk(x) number = " `count'
    replace `xo'=`xvar'[`count']
    replace `z'=(`xo'-`xvar')/`hv'
    replace `kz'=(1/(sqrt(2*_pi)))*exp(-.5*`z'^2) if abs(`z')<2.5 /* & `touse' */
    replace `sums'= sum(`kz')
    replace `fkx'=(1/(`nuobs'*`hv'))*`sums'[_N] if _n==`count'
    replace `kz'=0
    local count=`count'+1
  }

  *Calculating local weights
  tempvar lnfkx lnfg fg winfac
  gen `lnfkx'=log(`fkx')
  summ `lnfkx', meanonly
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
  *noi di "CALCULATING ADAPTIVE VALUES. DON'T DESPAIR"

  while `count2'<=_N {   
    *noi di "Working with adaptive value number = " `count2'
    replace `xo2'=`xvar'[`count2']
    replace `z2'=(`xo2'-`xvar')/(`winfac'*`hv')
    replace `kz2'=(1/(sqrt(2*_pi)))*exp(-.5*`z2'^2) if abs(`z2')<2.5 /* & `touse' */
    replace `sums2'=sum(`kz2'/`winfac')
    replace `fkx2'=(1/(`nuobs'*`hv'))*`sums2'[_N] if _n==`count2'
    replace `kz2'=0
    local count2=`count2'+1
 }

_crcslbl `xvar' `1'

    if "`graph'" ~= "nograph"  {

       if "`t1title'" =="" {
              local t1title "Variable bandwidth density"
              local t1title "`t1title', bw(Gmean) = `hv'"
          }
         
       if "`symbol'" == "" { local symbol "." }
       if "`connect'" == "" { local connect "l" }

    label variable `fkx2' "Density"

    graph `fkx2' `xvar' if `touse', sort `options' /*
       */ t1("`t1title'") s(`symbol') c(`connect')
    }


    if "`gen'" ~= "" {
       restore, not
       merge using `_data'
       drop _merge  
       tokenize `gen'
       gen `1' = `fkx2'
    }
  }
end
