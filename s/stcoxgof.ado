*! version 1.3.0  31january2000
program define stcoxgof, rclass
*! Goodness of Fit test and plot after proportional hazards model
*! Syntax: . [, GRoup(integer 4-10) Gen(string) POIdis  
*!              PLOT(integer 2-10) SEParate graph-options ]
*  Enzo Coviello (coviello@mythnet.it)

version 6
        syntax [, GRoup(numlist max=1 integer) Gen(string) POIdis PLOT(integer 0) /*
              */ SEParate Connect(string) Symbol(string) YScale(string) /*
              */ SAving(string) * ]
        st_is 2 analysis
        if "`e(cmd2)'" != "stcox" & "`e(cmd)'" != "ereg" & /*
               */ "`e(cmd)'" != "weibull" & "`e(cmd)'" != "gompertz"{
                        error 301
        }
        if "`e(cmd2)'" == "stcox" & "`e(mgale)'" == ""  {
            		noi di in red  /*
        */ "stcox did not save martingale residuals." _n /*
        */ "mgale(newvars) option must have been specified on the stcox" /*
        */ " command" _n "prior to using this command"
                  exit 198
        }
        local id : char _dta[st_id]
        if "`id'"!="" {
                    sort `id'
                    tempvar j
                    qui {
                        by `id': gen `j' = _N
                        sum `j'
                    }
                    if r(max)>1 {
                        noi di in red /*
        */ "Multiple records on the same subject aren't currently supported"
                exit 198
                    }
        }
        if "`group'" != "" & `plot' != 0 {
                 di in red "plot() and group() cannot be specified."
			exit 198
        }
        if `plot' == 0 & "`group'" == ""{
                 local group = 10
        }
        if "`gen'"!="" {
                confirm new variable `gen'
                local nvar : word count `gen'
		if `nvar' > 1 {
                        di in red "only one variable allowed in gen()"
			exit 198
                }
        }
        if "`gen'"!= "" & `plot' != 0 | "`poidis'"=="poidis" & `plot'!=0 {
                 di in red "plot() and gen() or plot() and poidis" /*
                 */ " cannot be specified."
			exit 198
        }
        global dis "`poidis'"
        tempvar H def xb
        qui {
             predict `H',csn
             gen `def' = _d
             predict `xb',xb
        }
        if `plot'==0 {
                if `group' < 4 | `group' > 10 {
                        di in re "group() invalid"
                        exit 198
                }
                mayhos `H' `def' `xb' `group' `gen'
                exit
         }
         if `plot'<2 | `plot'>10 {
                di in red "plot() invalid"
                    exit 198
         }
         preserve
         qui keep if e(sample)
         tempvar quant H_qu def_qu up_sc
         xtile `quant' = `xb',nq(`plot')
         sort `quant' `xb'
         qui {
              by `quant': gen double `H_qu' = sum(`H')
              by `quant': gen `def_qu' = sum(`def')
              keep if `def'==1
              by `quant': replace `H_qu' = round(`H_qu',.1) if _n==_N
              inspect `quant'
         }
         if r(N_unique) < `plot'{
                     di in red _n "Because of ties, there aren't " /*
                    */ `plot' " quantiles of risk."
                      exit
         }
         label var `def_qu' "Observed Counts"
         local symbol = cond("`symbol'"=="", "ii", "`symbol'")
         local connect = cond("`connect'"=="", "ll", "`connect'")
         local yscale = cond("`yscale'"=="", "0,.", "`yscale'")
         if "`saving'" ~= "" {
                local j = index("`saving'",",")
                if `j' {
                       local filnam = substr("`saving'",1,`j'-1)
                       local rest = substr("`saving'",`j',8)
                }
                else {
                       local filnam `saving'
                       local rest = ""
                }
         }
         if "`separate'" ~= "" {
                local i = 1
                while `i' <= `plot' {
                        if "`saving'" ~= "" {
                                local sav saving(`filnam'`i'`rest')
                        }
                        graph `H_qu' `def_qu' `def_qu' if `quant'==`i',  /*
                        */ l2("Expected Counts") t1("`i' Quantile of Risk") /*
                        */ c(`connect') s(`symbol') ys(`yscale') `sav' /*
                        */ `options'
                        more
                        local i = `i' + 1
                }
                if "`saving'" ~= "" {
                        di _n in bl "Plots have been saved as " /*
                        */ "`filnam'1 - `filnam'`plot' .gph files"
                }
         }
         else {
                if "`saving'" ~= "" {
                        local sav saving(`saving')
                        local sav1 saving(`filnam'1`rest')
                        local sav2 saving(`filnam'2`rest')
                }
                if `plot'< 7 {
                        qui forgraph 1-`plot', lt(num) ts(150) ti("Arjas" /*
                        */ " Plots for Goodness of Fit") /*
                        */ mar(10) `sav': graph `H_qu' `def_qu' `def_qu' /*
                        */ if `quant'==@,  /*
                        */ l2("Expected Counts") t1("@ Quantile of Risk") /*
                        */ c(`connect') s(`symbol') ys(`yscale')  `options'
                }
                else {
                      qui forgraph 1-4, lt(num) ts(150) ti("Arjas" /*
                      */ " Plots for Goodness of Fit") /*
                      */ mar(10) `sav1': graph `H_qu' `def_qu' `def_qu' /*
                      */ if `quant'==@,  /*
                        */ l2("Expected Counts") t1("@ Quantile of Risk") /*
                        */ c(`connect') s(`symbol') ys(`yscale') `options' 
                      more
                      qui forgraph 5-`plot', lt(num) ts(150) ti("Arjas" /*
                      */ " Plots for Goodness of Fit") /*
                      */ mar(10) `sav2': graph `H_qu' `def_qu' `def_qu' /*
                      */ if `quant'==@,  /*
                        */ l2("Expected Counts") t1("@ Quantile of Risk") /*
                        */ c(`connect') s(`symbol') ys(`yscale') `options'
                                if "`saving'" ~= "" {
                                di in bl "Plots have been saved as " /*
                                */ "`filnam'1 and `filnam'2 .gph files"
                                }
                }
         }
end

program define mayhos

           args H def xb group gen 
           tempvar dec z p num pp
           xtile `dec' = `xb',nq(`group')
           if "`gen'"!="" {
                qui gen float `gen' = `dec'
                label var `gen' "Quantiles of risk"
           }
           preserve
           qui {
               keep if e(sample)
               collapse (sum) `H' `def' (count) `num'=`def', by(`dec')
               gen `z' = (`def' - `H')/sqrt(`H')
               gen `p' = (1 - normprob(abs(`z')))*2
               if "$dis"=="poidis"{
                   ppois `H' `def' `pp'
               }
               tot `def' `H' `num'
               replace `H'=round(`H',.001)
               count
           }
           di in gr _n /*
                */ `"(Table collapsed on quantiles of linear predictor)"'
               if r(N) < `group' + 1 {
                        di in blu _n "Note: Because of ties, there " /*
                        */ "are only " `r(N)'-1 " distinct quantiles."
                        local group = `r(N)' - 1
               }
           label var `dec' "Quantile of Risk"
           label var `def' "Observed"
           label var `H' "Expected"
           label var `z' "z"
           label var `p' " p-Norm"
           label var `num' "Observations"
           if "$dis"=="poidis"{
               label var `pp' "p-Poisson"
               qui{
                   replace `p'=round(`p',.001)
                   replace `pp'=round(`pp',.001)
                }
               tabdisp `dec',cell(`def' `H' `p' `pp' `num') total /*
                */ format(%9.0g) center
           }
           else {
                qui {
                   replace `p'=round(`p',.001)
                   replace `z'=round(`z',.001)
                }
                tabdisp `dec',cell(`def' `H' `z' `p' `num') total /*
                */ format(%9.0g) center
           }
           if `group' < 5 {
                di _n in blu "Groups should not be less than 5."
           }
end



program define tot
                tempvar tot
                gen `tot' = 0
                local nm = _N + 1
                set obs `nm'
                while "`1'"!=""{
                        replace `tot'=sum(`1')
                        sum `tot'
                        replace `1' = r(max) if _n==_N
                        macro shift
                }
end


program define ppois
         args H_dec defdec pp
         gen double `pp' = 0
         local obs = _N
         local b = 1
         while `b'<=`obs'{
                local i = 0
                tempname pl H_b
                sca `pl' = `defdec'[`b']
                sca `H_b' = `H_dec'[`b']
                while `i' <= scalar(`pl') {
                          local facti = lnfact(`i')
                          local a = exp(`i'*ln(`H_b') - `facti' - /*
                          */ `H_b') 
                          replace `pp' = `pp' + `a' in `b'
                          local i = `i' + 1
                          }
                local b = `b' + 1
         }
         tempvar centr 
         gen `centr' = exp(`defdec'*ln(`H_dec') -`H_dec'- lnfact(`defdec'))
         replace `pp' = 2*`pp'- `centr' if `defdec'<`H_dec'
         replace `pp' = 2*(1-`pp') + `centr' if `defdec'>=`H_dec'

end
exit



. stcoxgof

(Table collapsed on quantiles of linear predictor)

----------+-----------------------------------------------------------------
Decile of |
Risk      |   Observed     Expected         z          p-Norm   Observations
----------+-----------------------------------------------------------------
        1 |         34      33.9565        .0075         .994           58  
        2 |         43      36.3499        1.103          .27           57  
        3 |         37       44.879      -1.1761        .2395           58  
        4 |         45      46.3605       -.1998        .8416           58  
        5 |         45      52.2301      -1.0004        .3171           57  
        6 |         51      38.7275       1.9721        .0486           57  
        7 |         50      49.6555        .0489         .961           58  
        8 |         52      52.3542        -.049         .961           57  
        9 |         53      53.3656         -.05        .9601           58  
       10 |         54      56.1213       -.2832        .7771           57  
          | 
    Total |        464          464                                    575  
----------+-----------------------------------------------------------------



. stcoxgof,poidis

(Table collapsed on quantiles of linear predictor)

----------+-----------------------------------------------------------------
Decile of |
Risk      |   Observed     Expected       p-Norm     p-Poisson  Observations
----------+-----------------------------------------------------------------
        1 |         34      33.9565         .994        .9714           58  
        2 |         43      36.3499          .27        .2735           57  
        3 |         37       44.879        .2395        .2364           58  
        4 |         45      46.3605        .8416        .8605           58  
        5 |         45      52.2301        .3171        .3179           57  
        6 |         51      38.7275        .0486        .0574           57  
        7 |         50      49.6555         .961        .9424           58  
        8 |         52      52.3542         .961        .9793           57  
        9 |         53      53.3656        .9601        .9783           58  
       10 |         54      56.1213        .7771        .7933           57  
          | 
    Total |        464          464                                    575  
----------+-----------------------------------------------------------------
