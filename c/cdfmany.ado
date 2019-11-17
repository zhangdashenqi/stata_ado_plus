*! Multiple cdf plot; (c) Stas Kolenikov
program define cdfmany
  version 6
  syntax varlist(numeric) [if] [in] [fw aw], [LOG SOrt DEBUG UP(real 1) LOW(real 0) RIght(real 1e12) LEft(real -1e12) *]
  tokenize `varlist'
  preserve
  qui {
    marksample touse
    keep if `touse'
    local cond
    if "`if'"~="" | "`in'"~="" { local cond `"Cond."' }
    local stacker  /* this would be the stack of the variables */
    local into "a" /* "a" would be the name of the horizontal axis var */
    tempvar mv
    g byte `mv'=.  /* a fake variable to be inserted into stack */
    local k=1
    while "``k''"~="" {
       tempvar y`k' cdf`k'
       if "`log'"~="" { g double `y`k''=log(``k'') }
       else { g double `y`k''=``k'' }
       cumul `y`k'' [`weight'`exp'], gen(`cdf`k'')
       replace `cdf`k''=. if `cdf`k''<`low' | `cdf`k''>`up' | `y`k''<`left' | `y`k''>`right'
       local stacker "`stacker' `y`k''"
       local j=1
       while "``j''"~="" {
          if `k'==`j' { local stacker "`stacker' `cdf`k''" }
          else        { local stacker "`stacker' `mv'"   }
          local j=`j'+1
       }
       local into "`into' b`k'"
       if "`debug'"~="" {
          noi di in gre _n "Step no: " in yel `k'
*          noi di in gre "Stack  : " in yel `"`stacker'"'
          noi di in gre "Into   : " in yel `"`into'"'
          noi sum `y`k'' `cdf`k''
          noi sum `y`k'' `cdf`k'' if `y`k''==0
          noi sum `y`k'' `cdf`k'' if `y`k''>0
          set more on
          more
          set more off
       }
       local k=`k'+1
    }
    stack `stacker', into(`into') clear
    local grvar
    local sym
    local conn
    local k=1
    while "``k''"~="" {
       lab var b`k' "`cond' cdf of `log' ``k''"
       local grvar "`grvar' b`k'"
       local sym "`sym'."
       local conn "`conn'l"
       local k=`k'+1
    }
    sort a `grvar'
    graph `grvar' a, s(`sym') c(`conn') `options' ys(`low',`up')
  }
end
