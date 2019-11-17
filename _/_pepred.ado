*! version 1.6.9 2013-08-05 increase maxcnt to 40
* version 1.6.8 2008-07-10
*   - make stdp global

* _pepred takes as input the matrix PE_in; each row is an observation and
* the columns are values for the independent variables in the regression
* model.  _pepred temporarily adds these observations to the dataset and
* generates predicted values.  _pepred puts the predicted values in
* return matrices that can then be used by the calling program.

capture program drop _pepred
program define _pepred, rclass
    version 6
    tempvar added stdp stdf xb xb_hi xb_lo p p1 p1_hi p1_lo p0 p0_hi p0_lo mucount mu
    tempvar mu_hi mu_lo tempvar p1_inf p0_inf always0
    tempname b alpha ai gai b_inf xb_inf infby replval zwidth
    syntax [, level(integer $S_level) maxcnt(integer 9) choices(varlist)]
    *handle 'level' option
    if `level' < 10 | `level' > 99 {
        di in r "level() invalid"
        error 198
    }
    local level = `level'/100
    *`zwidth' = SD width of confidence interval for `level'% ci
    sca `zwidth' = invnorm(`level'+((1-`level')/2))

    *check if `maxcnt' specified to acceptable value
    local max_i = `maxcnt'  /* how should this be set */
    if `max_i' < 0 | `max_i' > 41 {
        di in r "maxcnt() value not allowed"
        exit 198
    }

    *preserve needed because data altered
    preserve

    *add observations to end of dataset
    qui gen `added' = 0
    local newobs = rowsof(PE_in)
    local oldn = _N
    local newn = `oldn'+`newobs'
    qui set obs `newn'
    *`added'==1 for observations created by _pepred
    qui replace `added' = 1 if `added' == .

    *use _perhs to get information about rhs variables
    _perhs
    local nrhs `r(nrhs)'
    local nrhs2 `r(nrhs2)'
    local rhsnms `r(rhsnms)'
    local rhsnms2 `r(rhsnms2)'

    *fill in added observations with rows of PE_in
    *cycle through all rhs variables
    local i = 1
    while `i' <= `nrhs' {
        local varname : word `i' of `rhsnms'
        *for each rhs variable, cycle through all added observations
        local i2 = 1
        while `i2' <= `newobs' {
            *to_rep is the row number of the observation to insert PE_in values
            local to_rep = `oldn' + `i2'
            *`replval' value to move from PE_in to dataset
            sca `replval' = PE_in[`i2',`i']
            qui replace `varname' = `replval' in `to_rep'
            local i2 = `i2' + 1
        }
        local i = `i' + 1
    }

    *fill in values for variables in second equation of ZIP/ZINB model
    if "`nrhs2'"!="" {
        local i = 1
        while `i' <= `nrhs2' {
            local varname : word `i' of `rhsnms2'
            local i2 = 1
            while `i2' <= `newobs' {
                local to_rep = `oldn' + `i2'
                sca `replval' = PE_in2[`i2',`i']
                qui replace `varname' = `replval' in `to_rep'
                local i2 = `i2' + 1
            }
            local i = `i' + 1
        }
    } /* if "`nrhs2'"!="" */

    *list `rhsnms' in -`newobs'/-1
    *if "`nrhs2'"!="" { list `rhsnms2' in -`newobs'/-1 }

    *specify routine below that estimation command should call

    if "`e(cmd)'"=="slogit"  { local routine "slogit" } // 26Mar2005
    if "`e(cmd)'"=="mprobit" { local routine "mprobit" } // 28Feb2005
    if "`e(cmd)'"=="ztp"     { local routine "zt" } // 050218
    if "`e(cmd)'"=="ztnb"    { local routine "zt" }
    if "`e(cmd)'"=="clogit"  { local routine "clogit" }
    if "`e(cmd)'"=="cloglog" { local routine "binary" }
    if "`e(cmd)'"=="cnreg"   { local routine "tobit" }
    if "`e(cmd)'"=="fit"     { local routine "regress" }
    if "`e(cmd)'"=="gologit" { local routine "gologit" }
    if "`e(cmd)'"=="intreg"  { local routine "tobit" }
    if "`e(cmd)'"=="logistic" { local routine "binary" }
    if "`e(cmd)'"=="logit"   { local routine "binary" }
    if "`e(cmd)'"=="mlogit"  { local routine "mlogit" }
    if "`e(cmd)'"=="nbreg"   { local routine "count" }
    if "`e(cmd)'"=="ologit"  { local routine "ordered" }
    if "`e(cmd)'"=="oprobit" { local routine "ordered" }
    if "`e(cmd)'"=="poisson" { local routine "count" }
    if "`e(cmd)'"=="probit"  { local routine "binary" }
    if "`e(cmd)'"=="regress" { local routine "regress" }
    if "`e(cmd)'"=="tobit"   { local routine "tobit" }
    if "`e(cmd)'"=="zinb"    { local routine "zeroinf" }
    if "`e(cmd)'"=="zip"     { local routine "zeroinf" }

*Note: these routines define a local macro `newvars', which is a list of
* all matrices that _pepred will return to the calling program.

*NB!?: predictions are done for all observations because you can't use temporary
*variables as an if condition after predict (if `added' == 1)

*BINARY ROUTINE

    if "`routine'" == "binary" {
        local newvars "xb stdp p1 p0 xb_hi p1_hi p0_hi xb_lo p1_lo p0_lo"

        quietly {

            *use predict to get xb and std err of prediction
            predict `xb', xb
            predict `stdp', stdp
            *2008-07-09
            global stdp = `stdp'[1]

            *calculate upper and lower ci for xb
            gen `xb_hi' = `xb' + (`zwidth'*`stdp')
            gen `xb_lo' = `xb' - (`zwidth'*`stdp')

            *convert ci bounds into probabilities
            if "`e(cmd)'"=="logit" | "`e(cmd)'"=="logistic" {
                gen `p1' = exp(`xb')/(1+exp(`xb'))
                gen `p1_hi' = exp(`xb_hi')/(1+exp(`xb_hi'))
                gen `p1_lo' = exp(`xb_lo')/(1+exp(`xb_lo'))
            }
            if "`e(cmd)'"=="probit" {
                gen `p1' = normprob(`xb')
                gen `p1_hi' = normprob(`xb_hi')
                gen `p1_lo' = normprob(`xb_lo')
            }
            if "`e(cmd)'"=="cloglog" {
                gen `p1' = 1 - exp(-exp(`xb'))
                gen `p1_hi' = 1 - exp(-exp(`xb_hi'))
                gen `p1_lo' = 1 - exp(-exp(`xb_lo'))
            }

            *use prob(1) values to calculate corresponding prob(0) values
            gen `p0' = 1 - `p1'
            gen `p0_hi' = 1 - `p1_hi'
            gen `p0_lo' = 1 - `p1_lo'

        } /* quietly */
    }

* ORDERED ROUTINE

    if "`routine'" == "ordered" {
        quietly {

            *get information about categories of dependent variables
            _pecats
            local ncats = r(numcats)
            local catvals "`r(catvals)'"

            *use predict to get probabilities for each outcome
            *cycle through each category
            local i = 1
            while `i' <= `ncats' {
                tempvar p`i'
                local newvars "`newvars'p`i' "
                local catval : word `i' of `catvals'
                *_PEtemp has to be used because temporary variable causes error
                capture drop _PEtemp
                predict _PEtemp, p outcome(`catval')
                gen `p`i'' = _PEtemp
                local i = `i' + 1
            }

            *use predict to get probability of xb and std err of prediction
            local newvars "`newvars'xb stdp xb_hi xb_lo"
            capture drop _PEtemp
            predict _PEtemp, xb
            qui gen `xb' = _PEtemp
            capture drop _PEtemp
            predict _PEtemp, stdp
            qui gen `stdp' = _PEtemp
            *2008-07-09
            global stdp = `stdp'[1]

            *calculate upper and lower ci's for xb
            gen `xb_hi' = `xb' + (`zwidth'*`stdp')
            gen `xb_lo' = `xb' - (`zwidth'*`stdp')

        } /* quietly { */
    } /* if "`routine'" == "ordered" */

* MLOGIT ROUTINE

    if "`routine'" == "mlogit" {

        *get information on categories of dependent variable
        _pecats
        local ncats = r(numcats)
        local catvals "`r(catvals)'"
        local refval "`r(refval)'"

        local i = 1
        quietly {
            while `i' <= `ncats' {
                tempvar p`i' xb`i' stdp`i' sdp`i' xb_hi`i' xb_lo`i'
                local newvars "`newvars'p`i' "

                *use predict to get probabilities for each outcome
                local catval : word `i' of `catvals'
                capture drop _PEtemp
                predict _PEtemp, p outcome(`catval')
                gen `p`i'' = _PEtemp

                *if `i' != `ncats', then outcome is not base category
                if `i' != `ncats' {
                    local newvars "`newvars'xb`i' stdp`i' sdp`i' "
                    capture drop _PEtemp
                    *use predict to get standard error of prediction
                    predict _PEtemp, stdp outcome(`catval')
                    qui gen `stdp`i'' = _PEtemp
                    capture drop _PEtemp
                    *use predict to get standard error of difference in prediction
                    predict _PEtemp, stddp outcome(`catval', `refval')
                    qui gen `sdp`i'' = _PEtemp
                    capture drop _PEtemp
                    *use predict to get xb
                    predict _PEtemp, xb outcome(`catval')
                    qui gen `xb`i'' = _PEtemp
                    *calculate upper and lower bounds of ci
                    qui gen `xb_hi`i'' = `xb`i'' + (`zwidth'*`stdp`i'')
                    qui gen `xb_lo`i'' = `xb`i'' - (`zwidth'*`stdp`i'')
                }
                local i = `i' + 1
            } /* while `i' <= `ncats' */
        }
    }

* MPROBIT 28Feb2005

    if "`routine'" == "mprobit" {

        *get information on categories of dependent variable
        _pecats
        local ncats = r(numcats)
        local catvals "`r(catvals)'"
        local refval "`r(refval)'"

        local i = 1
        quietly {
            while `i' <= `ncats' {
                tempvar p`i' xb`i' /*stdp`i' sdp`i' xb_hi`i' xb_lo`i'*/
                local newvars "`newvars'p`i' "
                *use predict to get probabilities for each outcome
                local catval : word `i' of `catvals'
                capture drop _PEtemp
                predict _PEtemp, p outcome(`catval')
                gen `p`i'' = _PEtemp

                *if `i' != `ncats', then outcome is not base category
                if `i' != `ncats' {
                    local newvars "`newvars'xb`i' " /*stdp`i' sdp`i' "*/
                    capture drop _PEtemp
                    *use predict to get standard error of prediction
                    capture drop _PEtemp
                    *use predict to get standard error of difference in prediction
                    capture drop _PEtemp
                    *use predict to get xb
                    predict _PEtemp, xb outcome(`catval')
                    qui gen `xb`i'' = _PEtemp
                }
                local i = `i' + 1
            } /* while `i' <= `ncats' */
        }
    }


* SLOGIT 26Mar2005

    if "`routine'" == "slogit" {
        *get information on categories of dependent variable
        _pecats
        local ncats = r(numcats)
        local catvals "`r(catvals)'"
        local refval "`r(refval)'"

        local i = 1
        quietly {
            while `i' <= `ncats' {
                tempvar p`i' xb`i' /*stdp`i' sdp`i' xb_hi`i' xb_lo`i'*/
                local newvars "`newvars'p`i' "
                *use predict to get probabilities for each outcome
                local catval : word `i' of `catvals'
                capture drop _PEtemp
                predict _PEtemp, p outcome(`catval')
                gen `p`i'' = _PEtemp
                local i = `i' + 1
            } /* while `i' <= `ncats' */
        } /* quietly */
    } /* if "`routine'" == "slogit" */

    if "`routine'" == "gologit" {

        *get information about number of categories
        _pecats
        local ncats = r(numcats)
        local catvals "`r(catvals)'"
        local numeqs = `ncats'-1 /* number of equations */
        quietly {

            *cycle through each equation
            local i = 1
            while `i' <= `numeqs' {
                tempvar xb`i' pcut`i'
                *use predict to get xb for each equation
                predict `xb`i'', eq(mleq`i')
                local newvars "`newvars'xb`i' "
                *convert xb into prob(y<=`i')
                gen `pcut`i'' = exp(`xb`i'')/(1+exp(`xb`i''))
                local i = `i' + 1
            }

            *setting variables to indicate that prob(y<=0)=0 and prob(y<=`ncats)=1
            tempvar pcut`ncats' pcut0
            gen `pcut`ncats''=0
            gen `pcut0'=1

            *cycle through categories
            local i = 1
            while `i' <= `ncats' {
                tempvar p`i'
                local newvars "`newvars'p`i' "
                local j = `i' - 1
                *calculate prob(y=i) as prob(y<=i) - prob(y<=[i-1])
                gen `p`i'' = `pcut`j''-`pcut`i''
                local i = `i' + 1
            } /* while `i' <= `ncats' */
        }  /* quietly */
    } /* if "`routine'" == "gologit" */

* COUNT MODEL ROUTINE

    if "`routine'"=="count" | "`routine'" == "zt" { // 050218
        quietly {

            *get alpha if nbreg
            *zt 18Feb2005
            if "`e(cmd)'"=="nbreg" | "`e(cmd)'"=="ztnb" {
                sca `alpha' = e(alpha)
                sca  `ai' = 1/`alpha'
                *`gai' used to calculate probabilities
                sca  `gai' = exp(lngamma(`ai'))
                if `gai'==. {
                    di in r "problem with alpha from nbreg prohibits " /*
                    */ "estimation of predicted probabilities"
                    exit 198
                }
            }

            *use predict to get mu, xb, and std err of prediction
            *zt add Cmu for conditional mu 050218
            tempname Cmu
            local newvars "mu xb stdp "
            capture drop _PEtemp
            predict double _PEtemp, ir  /* does not handle offset or exposure */
            gen `mu' = _PEtemp
            capture drop _PEtemp
            predict double _PEtemp, xb
            gen `xb' = _PEtemp
            capture drop _PEtemp
            predict double _PEtemp, stdp
            gen `stdp' = _PEtemp
            *zt Cmu 18Feb2005
            * compute conditional rate
            if "`e(cmd)'"=="ztnb" | "`e(cmd)'"=="ztp" {
                capture drop _PEtemp
                predict double _PEtemp, cm
                gen `Cmu' = _PEtemp
                local newvars "mu xb stdp Cmu "
            }

            *ci's for poisson (doesn't work for nbreg because of alpha)
            *zt and compute upper and lower 18Feb2005
            if "`e(cmd)'"=="poisson" | "`e(cmd)'"=="ztp" {
                local newvars "`newvars'xb_hi xb_lo mu_hi mu_lo "
                gen `xb_hi' = `xb' + (`zwidth'*`stdp')
                gen `xb_lo' = `xb' - (`zwidth'*`stdp')
                gen `mu_hi' = exp(`xb_hi')
                gen `mu_lo' = exp(`xb_lo')
            }

            *calculate prob of observing a given count [Prob(y=1)]
            *cycle from 0 to maximum count wanted
            local i = 0
            while `i' <= `max_i' {
                tempvar p`i'
                local newvars "`newvars'p`i' "
                *predicting a particular count from mu
                *zt 18Feb2005
                if "`e(cmd)'"=="poisson" | "`e(cmd)'"=="ztp"  {
                    * usual poisson formula
                    qui gen double `p`i'' = ((exp(-`mu'))*(`mu'^`i')) / /*
                        */ (round(exp(lnfact(`i'))), 1)
                    tempname p_hi`i' p_lo`i'
                    local newvars "`newvars'p_hi`i' p_lo`i' "
                    qui gen double `p_hi`i'' = /*
                        */ ((exp(-`mu_hi'))*(`mu_hi'^`i')) / /*
                        */ (round(exp(lnfact(`i'))), 1)
                    qui gen double `p_lo`i'' /*
                        */ = ((exp(-`mu_lo'))*(`mu_lo'^`i')) /*
                        */ / (round(exp(lnfact(`i'))), 1)
                }

                *zt 18Feb2005
                if "`e(cmd)'"=="nbreg" | "`e(cmd)'"=="ztnb"  {
                    capture drop _PEtemp
                    qui gen double _PEtemp = (  exp(lngamma(`i'+`ai')) /*
                    */ / ( round(exp(lnfact(`i')),1) * exp(lngamma(`ai')) ) ) /*
                    */ * ((`ai'/(`ai'+`mu'))^`ai') * ((`mu'/(`ai'+`mu'))^`i')
                    qui gen double `p`i'' = _PEtemp
                }
                local i = `i' + 1
            }
            return scalar maxcount = `max_i'
        } /* quietly */

*-> GENERATE CONDITIONAL PREDICTED PROBABILITIES
    *zt compute conditional predictions 18Feb2005
    if "`e(cmd)'"=="ztp" | "`e(cmd)'"=="ztnb" {
        local i 1
        while `i' <= `max_i' {
            tempvar Cp`i' // C for Conditional
            local newvars "`newvars'Cp`i' "
            * divide by prob not equal to 0
            quietly gen `Cp`i'' = `p`i''/(1-`p0')
            label variable `Cp`i'' "Pr(y=`i'|y>0) `modelis'"
            local i = `i' + 1
        }
    } // zt

    } /* if "`routine'" == "count" */


* ZERO-INFLATED COUNT MODEL ROUTINE

    if "`routine'"=="zeroinf" {
        quietly {
            * mucount == mu from count portion of model - 15Apr2005
            * mu == expected y
            local newvars "mu mucount xb stdp p "
            capture drop _PEtemp
            * E(y)
            predict double _PEtemp, n  /* does not handle offset or exposure */
            gen double `mu' = _PEtemp
            capture drop _PEtemp
            predict double _PEtemp, xb
            * xb from the count portion of the model
            gen double `xb' = _PEtemp
            capture drop _PEtemp
            predict double _PEtemp, stdp
            gen `stdp' = _PEtemp
            capture drop _PEtemp
            predict double _PEtemp, p
            gen `p' = _PEtemp
            * E(y | not always 0) - 15Apr2005
            quietly gen double `mucount' = `mu'/(1-`p')
            mat `b' = e(b)
            if "`e(cmd)'"=="zinb" {
                local temp = colsof(`b')
                sca `alpha' = `b'[1, `temp']
                sca `alpha' = exp(`alpha')
                sca `ai' = 1/`alpha'
                sca `gai' = exp(lngamma(`ai'))
                if `gai'==. {
                    di in r "problem with alpha from zinb prohibits " /*
                    */ "estimation of predicted probabilities"
                    exit 198
                }
                *take alpha off beta matrix
                local temp = `temp' - 1
                mat `b' = `b'[1, 1..`temp']
            }

            *make beta matrix for inflate equation
            local temp = `nrhs' + 2
            local temp2 = colsof(`b')
            mat `b_inf' = `b'[1,`temp'..`temp2']

            *calculate xb of the inflate model
            local newvars "`newvars'xb_inf "
            gen double `xb_inf' = 0 if `added' == 1
            local i = 1
            while `i' <= `nrhs2' {
                local infvar : word `i' of `rhsnms2'
                sca `infby' = `b_inf'[1,`i']
                replace `xb_inf' = `xb_inf' + (`infby'*`infvar')
                local i = `i' + 1
            }
            *add constant
            replace `xb_inf' = `xb_inf' + `b_inf'[1, `i']

            *calculate prob(inflate==1)
            if "`e(inflate)'"=="logit" {
                gen `p1_inf' = exp(`xb_inf')/(1+exp(`xb_inf'))
            }
            if "`e(inflate)'"=="probit" {
                gen `p1_inf' = normprob(`xb_inf')
            }

            *calculate prob(inflate==0)
            gen `p0_inf' = 1 - `p1_inf'

            *return prob(inflate==1) as `always0'
            local newvars "`newvars'always0 "
            gen `always0' = `p1_inf'

            *predicting a particular count from mucount
            local i = 0
            while `i' <= `max_i' {
                tempvar p`i'
                local newvars "`newvars'p`i' "
                * use mucount not mu! 15Apr2005
                if "`e(cmd)'"=="zip" {
                    qui gen double `p`i'' = /*
                    */ ((exp(-`mucount'))*(`mucount'^`i'))/(round(exp(lnfact(`i'))), 1)
                }
                * use mucount not mu! 15Apr2005
                if "`e(cmd)'"=="zinb" {
                    capture drop _PEtemp
                    qui gen double _PEtemp = (  exp(lngamma(`i'+`ai')) /*
                    */ / (round(exp(lnfact(`i')),1) * exp(lngamma(`ai')))) /*
                    */ * ((`ai'/(`ai'+`mucount'))^`ai') * ((`mucount'/(`ai'+`mucount'))^`i')
                    qui gen double `p`i'' = _PEtemp
                }

                *adjust counts for always zeros
                qui replace `p`i'' = `p`i''*`p0_inf'

               local i = `i' + 1
            }
            *adjust prob(y=0) for always zeros
            replace `p0' = `p0' + `always0'
            return scalar maxcount = `max_i'

        }  /* quietly */
    }    /* if "`routine'" == "zeroinf" */

* TOBIT ROUTINE

    if "`routine'" == "tobit" {
* remove stdf 6/23/2006
*        local newvars "`newvars'xb xb_hi xb_lo stdp stdf "
        local newvars "`newvars'xb xb_hi xb_lo stdp "
        quietly {
            predict `xb', xb
            predict `stdp', stdp
            *2008-07-09
            global stdp = `stdp'[1]

            * remove stdf 6/23/2006
            * predict `stdf', stdf
            gen `xb_hi' = `xb' + (`zwidth'*`stdp')
            gen `xb_lo' = `xb' - (`zwidth'*`stdp')
        }
    }

* REGRESS ROUTINE

    if "`routine'" == "regress" {
        * remove stdf 6/23/2006
        * local newvars "`newvars'xb xb_hi xb_lo stdp stdf "
        local newvars "`newvars'xb xb_hi xb_lo stdp "
        quietly {
            predict `xb', xb
            predict `stdp', stdp
            *2008-07-09
            global stdp = `stdp'[1]

            * remove stdf 6/23/2006
            * predict `stdf', stdf
            gen `xb_hi' = `xb' + (`zwidth'*`stdp')
            gen `xb_lo' = `xb' - (`zwidth'*`stdp')
        }
    }

** MAKE RETURN MATRICES

    *return level
    return local level `level'
    tokenize "`newvars'"

    *cycle through all the new variables created by routine above
    local i = 1
    while "``i''" != "" {

        *make matrix tmatnam with all observations for a given new variable
        local tmatnam = "_``i''"
        if length("`tmatnam'") > 7 {
            local tmatnam = substr("`tmatnam'", 1, 7)
        }
        tempname `tmatnam'
        mat ``tmatnam'' = J(`newobs', 1, 0)
        local i2 = 1
        while `i2' <= `newobs' {
            local outob = `oldn' + `i2'
            mat ``tmatnam''[`i2',1] = ```i'''[`outob']
            local i2 = `i2' + 1
        }
        *return matrix so available to calling program
        return matrix ``i'' ``tmatnam''
        local i = `i' + 1
    }

end


exit

15Apr2005 - correct error for zip and zinb (see changes in _pepred, _pecollect, _peciboot

    E(y) was used incorrectly rather than E(y|~always0).

    _pepred[3|5|7, 2] used to be mu defined as rate in count portion of model E(y|not always 0)

    _pepred[3|5|7, 2] now is the overall rate E(y); listed as simply mu.

    _pepred[3|5|7, 3] rate in count portion of model E(y|not always 0); listed as mucount.

To simplify changes in _peciboot, E(y) is referred to as mu; E(y|~always0) is mucount.

* version 1.6.7 2008-07-09
*   - save se of ystar predictions
* version 1.6.6 23Jun2006 fix stdf bug for regress and tobit
* version 1.6.5 15Apr2005 fix rate used for zip/zinb (see notes at end)
* version 1.6.4 13Apr2005
* version 1.6.3 27Mar2005 slogit
* version 1.6.2 28Feb2005 mprobit
* version 1.6.1 18Feb2005 zt models
* version 1.6.0 3/29/01
