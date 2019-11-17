*! A driver for fsreg to produce nice graphs. v.1.1, 22.11.2000 Stas Kolenikov
program define fsregrph
    version 6

    syntax [in] [if], [Residual BEtas(str) TStats(str) Level(int $S_level) LAst(int 0) SCore B T XTic XLab Symbol(str) * ]

    if "`symbol'" == "" { local symbol .................... }

    marksample touse

****di in whi ("`betas'"~="") + ("`residua'"~="") + ("`b'"~="") + ("`tstats'"~="") + ("`score'"~="") + ("`t'"~="")

    if ("`betas'"~="") + ("`residua'"~="") + ("`b'"~="") + ("`tstats'"~="") + ("`score'"~="") + ("`t'"~="") ~=1 {
      di in red "one and only one option should be specified"
      exit 198
    }

    local charfs : char _dta[fsreg]
    if "`charfs'"=="" {
      di in red "The data do not seem to be produced by fsreg"
      exit 301
    } 
    local ci=round(invnorm( 1-(100-`level')/200),1e-5)

    local total=_nobs[_N]
    if `last'==0 {
      local start=int(_nobs[_N-15]/10)*10
**    sum _nobs if `touse'
**    local minno=r(min)
**    local begin=int((`minno'+9)/10)*10
      local begin=int((_nobs[1]+9)/10)*10
      local step=10^(int( log10(`total'-`begin')-0.2 ) )
      local ticks xtick(`start'(1)`total') xlab(`begin'(`step')`total')
**    set graphics off
**    cap noi gr _sig _nobs, `ticks'
**    if _rc~=0 {
**      local step=10
**      local ticks xtick(`start'(`step')`total')
**    }
**    set graphics on
**
**    di in whi "ticks: `ticks'"
    }
    * end of if not last
    else {
      if `last'>20 | `last'<1 {
         di in red "too many observations in last"
         exit 198
      }
      local start=_nobs[_N-`last'+1]
      local ticks xtick(`start'(1)`total') 
      qui replace `touse'=(_n>=_N-`last'+1)
    }

    if "`residua'"~="" {
***** confirm integer number `residua'
      local restype: char _dta[res]
      if "`restype'"=="" {
         di in red "No info on residuals found"
         exit 190
      }
      gr _r* _nobs if `touse' , yline(0 `ci') `ticks' ti("Largest `restype' residuals") ylab s(...................) c(llllllllllllllll) `options'
    } 

    if "`betas'"~="" | "`b'"~="" {
       if "`betas'"~="" {
         tokenize `betas'
         while "``k''"~="" {
           confirm var ``k''
           local k=`k'+1
         }
       }
       if "`b'"~="" { local blist : char _dta[fsregl] }
****** di in whi `"gr `betas'`blist' _nobs , ti("Regression coefficients") ylab s(...................) c(llllllllllllllll)"'
       gr `betas'`blist' _nobs if `touse' , ti("Regression coefficients") `ticks' ylab s(...................) c(llllllllllllllll) `options'
    }

    if "`tstats'"~="" | "`t'"~="" {
       * unab tlist: _added - _cons
       * gettoken foobar tlist : tlist
       local tlist : char _dta[fsregl] 
       local nvars : word count `tlist'
       * tokenize `tstats'
       * local k=1
       * while "``k''"~="" {
         * everything was wrong!
         * confirm var _t`k'
         * local tlist `tlist' _t`k'
       if "`tstats'"~="" {
         unab tstats : `tstats'
         poslist `tlist' \ `tstats'
         tokenize `r(list)'
***      di as inp "Source: `tlist'; search: `tstats'; result: `r(list)'"
         local tlist
         while "`1'"~="" {
           if `1'!=0 { 
             local tlist `tlist' _t`1' 
           }
           mac shift
         }
***      di as inp "Output: `tlist'"
       }
       else { local tlist _t1-_t`nvars' }
**** di in whi `"     gr `tlist' _nobs , yline(-`ci' 0 `ci') ti("t-statistics") ylab s(...............) c(llllllllllllll) "'
       gr `tlist' _nobs if `touse', yline(-`ci' 0 `ci') ti("t-statistics") `ticks' ylab s(`symbol') c(llllllllllllll) `options'
    }

    if "`score'"~="" {
       local dv : char _dta[depvar]
       gr _sco* _nobs if `touse' , yline(-`ci' 0 `ci') l1("Box-cox lambda scores") ti("Transformation score test: `dv'") `ticks' ylab s([_labm2][_labm1][_labm05][_lab0][_lab05][_lab1][_lab2]) c(lllllll) `options'
    }

end
