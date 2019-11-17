*!version 1.4.1    01 September 1993   RG       sg31: STB-23
program define rspread
    version 3.0
    local varlist "req ex min(1)"
    local if "opt"
    local in "opt"
    mac def _options "GRaph"
    parse "`*'"
    parse "`varlist'", parse(" ")
    local sFN $S_FN
    tempfile USER
    if "`if'"=="" & "`in'"=="" {
         qui keep _all
    }
    else qui keep `if' `in'
    qui save `USER', replace
    di "Measures of Absolute and Relative Dispersion (or Inequality):"
    di ""
    di _col(9) "| Mean Dev. about                                                Max."
    di "variable|" _col(13) " Mean  Median  MeanDif      CV       CD     Gini  SEMean    % Dev."
    di in red _dup(8) "-" in ye "|" in re _dup(69) "-"
    while ("`1'"!="") {
    egen mdmean=mdmean(`1')
    qui su mdmean
    local mdmeana=_result(3)
    egen mdmed=mdmed(`1')
    qui su mdmed
    local mdmeda=_result(3)
    qui save, replace
    qui sort `1'
    qui gen FDIST=_n/_N
    qui gen TOTAL=sum(`1')
    qui gen FPOP=`1'/TOTAL[_N]
    qui gen FPOP2=sum(FPOP)
    if "`graph'"!="" {
    local gcount=`gcount'+1
         local NUMB=_N
         local OBS=`NUMB'+1
         qui set obs `OBS'
         qui replace FPOP2=0 if FPOP2==.
         qui replace FDIST=0 if FDIST==.
         sort FDIST
    #del ;
     qui gr FPOP2 FDIST FDIST, c(ll) s(Oi) ti("Lorenz Curve--`1'") xlab ylab
         l1("Cumulative Fraction of `1'") b2("Cumulative Fraction of base")
         sav(lorenz`gcount', replace) ;
    #del cr
    }
    qui drop if FDIST==0
*    qui integ FDIST FDIST, gen(EQUAL)
*    qui integ FPOP2 FDIST, gen(GINI)
** If using discrete data use 2nd line (put * at beginning of next line)
*    local gini=1-(GINI[_N]/EQUAL[_N])
**   local gini=2*(EQUAL[_N]-GINI[_N])
qui egen RR=rank(`1')
qui corr `1' RR, cov
local COV0=_result(4)/_result(1)
    qui su `1', d
local gini=2*(`COV0'/_result(3))
    local maxp=max(abs(((_result(5)-_result(3))/_result(3))),((_result(6)-_result(3))/_result(3)))
#del ;
di "`1'" _col(9) "| " in gr %7.1g `mdmeana' _skip(1) %7.1g `mdmeda' _skip(2)
 %7.1g 2*_result(3)*`gini' _skip(1) %7.4f sqrt(_result(4))/_result(3) _skip(1)
 %8.4f mdmed[_N]/_result(10) _skip(1) %8.4f `gini' _skip(1)
 %7.1g sqrt(_result(4))/sqrt(_result(1)) _skip(1) %7.2f 100*`maxp' "%" ;
#del cr
*   qui drop mdmed mdmean FDIST TOTAL FPOP FPOP2 EQUAL GINI
    qui drop mdmed mdmean FDIST TOTAL FPOP FPOP2 RR
    mac shift
}
qui use `sFN', replace
qui erase `USER'
end
