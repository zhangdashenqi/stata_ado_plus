*! version 1.7.6 jsl 2009-10-18
* - stata 11 minor revisions

capture program drop mlogtest
program define mlogtest, rclass
    version 9
    tempname numrhs sample numcats omit chisq df pval
    tempname matiia matsuiia matlr matwald matcomb matlrc nxtrow testn newbase
    tempvar tmp count

    local n = e(N)
    local n "(N=`n')"
    local vers7 "yes"
    local smcl "in smcl "
    local dash "{c -}"
    local vline "{c |}"
    local plussgn "{c +}"
    local topt "{c TT}"
    local bottomt "{c BT}"

    * version 6 
    * 13Feb2005
    syntax [varlist(default=none)][, Detail Iia ///
        Hausman Lr Wald Combine LRComb SMhsiao ///
        SUest Set(string) All Base]

    if "`e(cmd)'" != "mlogit" {
        di _newline in y "mlogtest" in r " only works after " in y "mlogit."
        exit
    }

    * store estimation results from original mlogit as _X
    qui estimates store _X

*-> set defaults
    local dolr = "no"
    if "`lr'"!="" { 
        local dolr = "yes" 
    }
    local doiia = "no"
    if "`hausman'"!="" | "`iia'"!="" { 
        local doiia = "yes" 
    }
    local doshiia = "no"
    if "`smhsiao'"!="" | "`iia'"!="" { 
        local doshiia = "yes" 
    }
    local dosuiia = "no"
    if "`suest'"!="" | "`iia'"!="" { 
        local dosuiia = "yes" 
    }
    local dowald = "no"
    if "`wald'"!="" { 
        local dowald = "yes" 
    }
    local docomb = "no"
    if "`combine'"!="" { 
        local docomb = "yes" 
    }
    local dolrcom = "no"
    if "`lrcomb'"!="" { 
        local dolrcom = "yes" 
    }
    if "`all'"!="" {
        local dolr = "yes"
        local doiia = "yes"
        local doshiia = "yes"
*       local dosuiia = "yes"
        local dowald = "yes"
        local docomb = "yes"
        local dolrcom = "yes"
    }

*-> get weight info from last mlogit
    local wtis ""
    if "`e(wtype)'"!="" {
        local wtis "[`e(wtype)'`e(wexp)']"
    }

*-> check that estimation sample matches n from regression
    qui gen `sample' = e(sample)
    if "`e(wtype)'"=="" | "`e(wtype)'"=="aweight" | "`e(wtype)'"=="pweight" {
        qui count if `sample' == 1
        scalar `testn' = r(N)
    }
    if "`e(wtype)'"=="fweight" | "`e(wtype)'"=="iweight" {
        local wtexp = substr("`e(wexp)'", 3, .)
        gen `tmp' = (`wtexp')*`sample'
        qui su `tmp', meanonly
        scalar `testn' = round(r(sum),1)
    }
    if e(N) ~= `testn' {
        di  _newline in r "Data has been altered since " /*
        */ in y "mlogit" in r " was estimated."
        exit
    }

*-> get information about the mlogit
    local depvar = "`e(depvar)'"

    local printdv = abbrev("`printdv'", 8) 

    _perhs
    local rhsnam "`r(rhsnms)'"
    scalar `numrhs' = `r(nrhs)'
    _pecats
    local catnms8 "`r(catnms8)'"
    local catvals "`r(catvals)'"
    local catnms "`r(catnms)'"
    scalar `numcats' = r(numcats)

		* 2007-06-29 stata 10    
		if c(stata_version) < 10 {    
    		local basecat = e(basecat) /* or r(refval) */
		}
		else {
    		local basecat = e(baseout) /* or r(refval) */
		}    
    local refnm "`r(refnm)'"
    local check : word count `catvals'
    if `numcats' ~= real("`check'") {
        di  _newline in r "Problem determining number of categories."
    }

*-> parse out sets if set option on
    local numset = 0
    if "`set'" ~= "" {
        tokenize "`set'", parse("\")
        local count = 1
        while "``count''"!="" {
            if "``count''"=="\" { 
                macro shift 
            }
            else {
                local set`count' "``count''"
                capture  unab set`count': /*
                    */ `set`count'', min(2) name(defining sets)
                local setl`count': word count `set`count''
                * check if all variables in set are rhs variables
                local count2 = 1
                while `count2' <= `setl`count'' {
                    local count3 = 1
                    local inrhs "no"
                    local setvar : word `count2' of `set`count''
                    while `count3' <= `numrhs' {
                        local ivar : word `count3' of `rhsnam'
                        if "`setvar'"=="`ivar'" { 
                            local inrhs "yes" 
                        }
                        local count3 = `count3' + 1
                    }
                    if "`inrhs'" == "no" {
                        di _newline in r "variable " in y "`setvar'" in r /*
                        */ " specified in set() but is not in model."
                        exit
                    }
                    local count2 = `count2' + 1
                } /* while count2 <= `setl`count' */
                return local set_`count' "`set`count''"
                local count = `count' + 1
            } /* else */
        } /*  while "``count''"!="" */
        local numset = `count' - 1
    } /* if "`set'" ~= "" */

*-> LR test of independent variables

		version 7
    if "`dolr'"=="yes" & `numrhs' == 0 {
        di _n in r "LR test cannot be computed on intercept-only model."
    }
    else if "`dolr'"=="yes" {
        di _newline in g /*
        */ "**** Likelihood-ratio tests for independent variables `n'"
        di _newline in g /*
        */  " Ho: All coefficients associated with given variable(s) are 0."
        di `smcl' _newline in g  %12s "`printdv'" _col(14) "`vline'" /*
        */ _col(22) "chi2" _col(29) "df" _col(34) "P>chi2"
        di `smcl' in g _dup(13) "`dash'" "`plussgn'" _dup(25) "`dash'"

        lrtest, saving(0)

        * 13Feb2005 - allow tests of specified # of variables
        if "`varlist'"!="" { // if var list
            local nvlist : word count `varlist'
            local ntests = `nvlist' // use this as the # of rhsvars
            local testnms "`varlist'"
        }
        else {
            local testnms "`rhsnam'"
            local ntests = `numrhs'
        }
        tokenize "`rhsnam'" // tokenize list, rather than rhs vars

        * 13Feb2005 replace numrhs with ntests below
        * loop over all rhs + specified sets
        local count = 1
        while `count' <= `ntests'+`numset' {
            local testvar : word `count' of `testnms'
            * for individual independent variables
            if `count' <= `ntests' {
                local var`count' : word `count' of `testnms'
                * create varlist with all vars but count variable
                local count2 = 1
                local lrrhs = ""
                while `count2' <= `numrhs' { // loop through all variables
                    if "`testvar'"!="``count2''" {
                        local lrrhs "`lrrhs' ``count2''"
                    }
                local count2 = `count2' + 1
                }
            } /* if `count' <= `ntests' */

            * for sets of independent variables
            if `count' > `ntests' {
                local thisset = `count'-`ntests'
                * for matrix & output rowname
                local var`count' "set_`thisset'"
                * for count3 loop
                local countto : word count `set`thisset''
                local count2 = 1
                local lrrhs = ""
                while `count2' <= `ntests' {
                    local count3 = 1
                    local inset "no"
                    while `count3' <= `countto' {
                        local setvar : word `count3' of `set`thisset''
                        if "``count2''"=="`setvar'" { 
                            local inset "yes" 
                        }
                        local count3 = `count3' + 1
                    }
                    if "`inset'" == "no" { 
                        local lrrhs "`lrrhs' ``count2''" 
                    }
                    local count2 = `count2' + 1
                }
            } /* if `count' > `ntests' */

            qui mlogit `depvar' `lrrhs' `wtis' /*
            */ if `sample' == 1, b(`basecat')
            * quietly lrtest, using(0)
            qui lrtest, using(0)
            * put results in matrix
            scalar `chisq' = r(chi2)
            scalar `df' = r(df)
            scalar `pval' = r(p)
            if `pval' == . { 
                scalar `pval' = -9999 
            }
            mat `nxtrow' = `chisq', `df', `pval'
            mat rownames `nxtrow' = "`var`count''"
            mat `matlr' = nullmat(`matlr') \ `nxtrow'
            local count = `count' + 1
        } /* while `count' <= `ntests' */

        mat colnames `matlr' = chi2 df p
        * cycle through row by row of output matrix and print
        local countto = rowsof(`matlr')
        local count = 1
        while `count' <= `countto' {
            scalar `chisq' = `matlr'[`count', 1]
            scalar `df' = `matlr'[`count', 2]
            scalar `pval' = `matlr'[`count', 3]
            if `pval' == -9999 { 
                scalar `pval' = . 
            }
            * tests of individual variables
            if `count' <= `ntests' {
                * name to print
                local printnm "`var`count''"
                local printnm = abbrev("`printnm'", 12) 
                di `smcl' in y %12s "`printnm'" _col(14) in g "`vline'" /*
                */ _col(17) %9.3f in y `chisq' /*
                */ _col(26) %5.0f `df' /*
                */ _col(35) %4.3f `pval'
            }
            * tests of sets
            if `count' > `ntests' {
                local thisset = `count' - `ntests'
                di `smcl' in g _dup(13) "`dash'" "`plussgn'" _dup(25) "`dash'"
                * name to print
                local printnm "`var`count''"
                local printnm = abbrev("`printnm'", 12) 
                di `smcl' in g %12s "`printnm':" _col(14) in g "`vline'" /*
                */ _col(17) %9.3f in y `chisq' /*
                */ _col(26) %5.0f `df' /*
                */ _col(35) %4.3f `pval'
                local count2 = 1
                local countt2 : word count `set`thisset''
                while `count2' <= `countt2' {
                    local setvar : word `count2' of `set`thisset''
                    * name to print
                    local printnm "`setvar'"
                    if "`vers7'"=="yes" { local printnm = abbrev("`printnm'", 12) }
                    di `smcl' %12s in y "`printnm'" _col(14) in g "`vline'"
                    local count2 = `count2' + 1
                }
            }
            local count = `count' + 1
        } /* while `count' <= `countto' */
        di `smcl' in g _dup(13) "`dash'" "`bottomt'" _dup(25) "`dash'"

        qui version 9: estimates restore _X
        return matrix lrtest `matlr'

    } /* if "`dolr'"=="yes" */

*-> WALD test of independent variables

		version 7
    * 13Feb2005 - allow tests of specified # of variables
    if "`varlist'"!="" { // if var list
        local nvlist : word count `varlist'
        local testnms "`varlist'"
        local ntests = `nvlist' // use this as the # of rhsvars
    }
    else {
        local ntests = `numrhs'
        local testnms "`rhsnam'"
    }

    if "`dowald'"=="yes" & `ntests' == 0 {
        di _n in r "Wald test cannot be computed on intercept-only model."
    }
    else if "`dowald'"=="yes" {
        * 13Feb2005 replace numrhs with ntests below
        tokenize "`testnms'"
        di _newline in g /*
        */ "**** Wald tests for independent variables `n'"
        di _newline in g /*
        */  " Ho: All coefficients associated with given variable(s) are 0."
        di `smcl' _newline in g  %12s "`printdv'" _col(14) "`vline'" /*
        */ _col(22) "chi2" _col(29) "df" _col(34) "P>chi2"
        di `smcl' in g _dup(13) "`dash'" "`plussgn'" _dup(25) "`dash'"

        * loop over all rhs + specified sets
        local count = 1
        while `count' <= `ntests'+`numset' {
            * for individual independent variables
            if `count' <= `ntests' {
                * 13Feb2005
                local var`count' : word `count' of `testnms'
                qui test `var`count''
            }
            * tests of sets
            if `count' > `ntests' {
                local thisset = `count'-`ntests'
                *get set name/number for matrix&output
                local var`count' "set_`thisset'"
                qui test `set`thisset''
            }
            scalar `chisq' = r(chi2)
            scalar `df' = r(df)
            scalar `pval' = r(p)
            if `pval' == . { scalar `pval' = -9999 }
            mat `nxtrow' = `chisq', `df', `pval'
            mat rownames `nxtrow' = "`var`count''"
            mat `matwald' = nullmat(`matwald') \ `nxtrow'
            local count = `count' + 1
        } /* while `count' <= `ntests' */

        mat colnames `matwald' = chi2 df p
        local countto = rowsof(`matwald')
        local count = 1
        while `count' <= `countto' {
            scalar `chisq' = `matwald'[`count', 1]
            scalar `df' = `matwald'[`count', 2]
            scalar `pval' = `matwald'[`count', 3]
            if `pval' == -9999 { scalar `pval' = . }
            if `count' <= `ntests' {
                *added for stata 7 compatibility
                local printnm "`var`count''"
                local printnm = abbrev("`printnm'", 12)
                di `smcl' in y %12s "`printnm'" _col(14) in g "`vline'" /*
                */ _col(17) %9.3f in y `chisq' /*
                */ _col(26) %5.0f `df' /*
                */ _col(35) %4.3f `pval'
            }
            if `count' > `ntests' {
                local thisset = `count' - `ntests'
                di `smcl' in g _dup(13) "`dash'" "`plussgn'" _dup(25) "`dash'"
                *added for stata 7 compatibility
                local printnm "`var`count''"
                local printnm = abbrev("`printnm'", 12)
                di `smcl' in g %12s "`printnm':" _col(14) in g "`vline'" /*
                */ _col(17) %9.3f in y `chisq' /*
                */ _col(26) %5.0f `df' /*
                */ _col(35) %4.3f `pval'
                local count2 = 1
                local countt2 : word count `set`thisset''
                while `count2' <= `countt2' {
                    local setvar : word `count2' of `set`thisset''
                    *added for stata 7 compatibility
                    local printnm "`setvar'"
                    if "`vers7'"=="yes" {
                        local printnm = abbrev("`printnm'", 12)
                    }
                    di `smcl' %12s in y "`printnm'" _col(14) in g "`vline'"
                    local count2 = `count2' + 1
                }
            }
            local count = `count' + 1
        } /* while `count' <= `countto' */
        di `smcl' in g _dup(13) "`dash'" "`bottomt'" _dup(25) "`dash'"
        return matrix wald `matwald'
    } /* if "`dowald'"=="yes" */

*-> HAUSMAN IIA Test

		version 9
    * can't do if only two categories
    if "`doiia'"=="yes" & `numcats' == 2 {
        di _n in r /*
        */ "Hausman IIA test requires at least 3 dependent categories."
    }
    else if "`doiia'"=="yes" {
        di _newline in g /*
        */ "**** Hausman tests of IIA assumption `n'"
        di _newline in g /*
        */ " Ho: Odds(Outcome-J vs Outcome-K) are independent of "/*
        */ "other alternatives."

        * cycle through all alternatives
        tokenize "`catvals'"
        local count = 1
        while real("`count'") <= `numcats' {
            local lab`count' : word `count' of `catnms'
            local slab`count' : word `count' of `catnms8'
            scalar `omit' = real("``count''")
            if "`detail'" == "detail" {
                if "`lab`count''"!="``count''" {
                    di _newline in g/*
                    */ "Hausman test when omitted alternative is " in y `omit' /*
                    */ in g " (" in y "`lab`count''" in g ")"
/*                    di _newline in g/*
                    */ "Hausman test when omitted outcome is " in y `omit' /*
                    */ in g " (" in y "`lab`count''" in g ")"
*/
                }
                else {
                    di in g _newline /*
                    */ "Hausman test when omitted alternative is " in y `omit'
                }
            } /* if "`detail'" == "detail" */
            if `omit'==real("`basecat'") & "`base'" != "" {
                * IIA for basecategory requires estimating mlogit with
                * new basecategory. Make new basecat the largest category
                * of the dependent variable that is not the original basecat
                local maxcnt = 0
                local count2 = 1
                while `count2' <= `numcats' {
                    if real("``count2''") != `omit' {
                        qui count if `depvar'==``count2'' & `sample'==1
                        if r(N)>`maxcnt' {
                            local newbase = ``count2''
                            local maxcnt = r(N)
                            local tmplab : word `count2' of `catnms'
                        }
                    }
                    local count2 = `count2' + 1
                } /* while count2 <= `numcats' */
                
                * estimates of old logit are held in _X
                qui mlogit `depvar' `rhsnam' `wtis' /*
                */ if `sample' == 1, b(`newbase')
                qui estimates store _Xnb
                
                qui mlogit `depvar' `rhsnam' `wtis' /*
                */ if `sample'==1 & `depvar'!=`omit', b(`newbase')
                if "`detail'"=="detail" {
                    if "`lab`count''"!="``count''" {
                        di in g "(Using category " in g "`newbase' " /*
                        */ in g "(" in g "`tmplab'" in g /*
                        */ ") as comparison group)"
                    }
                    else {
                        di in g "(Using category " in g "`newbase' " /*
                        */ in g "as comparison group)"
                    }
                    hausman . _Xnb, alleq constant
                }
                else { 
                    qui hausman . _Xnb, alleq constant 
                }
                scalar `chisq' = r(chi2)
                scalar `df' = r(df)
                scalar `pval' = r(p)
                if `pval' == . | `chisq' < 0 { 
                    scalar `pval' = -9999 
                }

                *put things back and then hold them again
                qui estimates restore _X
                mat `nxtrow' = `omit', `chisq', `df', `pval'
                mat rownames `nxtrow' = "`slab`count''"
                mat `matiia' = nullmat(`matiia') \ `nxtrow'
            } /* if `omit'==real("`basecat'") */
            else if `omit'!=real("`basecat'") {
                quietly mlogit `depvar' `rhsnam' `wtis' /*
                */ if `sample' == 1 & `depvar' != `omit', b(`basecat')
                if "`detail'"=="detail" { 
                    hausman . _X, alleq constant
                }
                else { 
                    qui hausman . _X, alleq constant 
                }
                scalar `chisq' = r(chi2)
                scalar `df' = r(df)
                scalar `pval' = r(p)
                if `pval' == . | `chisq' < 0 { 
                    scalar `pval' = -9999 
                }
                mat `nxtrow' = `omit', `chisq', `df', `pval'
                mat rownames `nxtrow' = "`slab`count''"
                mat `matiia' = nullmat(`matiia') \ `nxtrow'
            }  /* else if `omit'!=real("`basecat'") */
            local count = `count' + 1
        } /* while real("`count'") <= `numcats' */

        mat colnames `matiia' = omitted chi2 df p
        if "`detail'" == "detail" {
            di in g _newline "*** Summary of results"
        }
        
        * only print explainer if negative chi2 observed
        local anyneg = "no"
        local countto = rowsof(`matiia')
        local count = 1

        di _newline `smcl' in g " Omitted" _col(10) "`vline'" /*
        */ _col(17) "chi2" _col(24) "df" _col(29) "P>chi2" _col(38) "evidence"
        di `smcl' in g _dup(9) "`dash'" "`plussgn'" _dup(36) "`dash'"

        *cycle through row by row of output matrix and print
        while `count' <= `countto' {
            scalar `chisq' = `matiia'[`count', 2]
            scalar `df' = `matiia'[`count', 3]
            scalar `pval' = `matiia'[`count', 4]
            if `pval' == -9999 {
                local anyneg "yes"
                local implies "---"

                *added for stata 7 compatibility
                local printnm "`slab`count''"
                local printnm = abbrev("`printnm'", 8)

                di `smcl' in y %8s "`printnm'" _col(10) in g "`vline'" /*
                */ _col(13) %8.3f in y `chisq' /*
                */ _col(21) %5.0f `df' /*
                */ _col(30) " ---" /*
                */ _col(38) %-10s "`implies'"
            }
            else {
                local implies  "for Ho"
                if `pval' < .05 {
                    local implies "against Ho"
                }
                *added for stata 7 compatibility
                local printnm "`slab`count''"
                local printnm = abbrev("`printnm'", 12)

                di `smcl' %8s in y "`printnm'" _col(10) in g "`vline'" /*
                */ _col(13) %8.3f in y `chisq' /*
                */ _col(21) %5.0f `df' /*
                */ _col(30) %4.3f `pval' /*
                */ _col(38) %-10s "`implies'"
            }
            local count = `count' + 1
        } /* while `count' <= `countto' */
        di `smcl' in g _dup(9) "`dash'" "`bottomt'" _dup(36) "`dash'"

        if "`anyneg'" == "yes" {
            di in g " Note: If chi2<0, the estimated model does not"
            di in g " meet asymptotic assumptions of the test."
        }

        qui estimates restore _X
        return matrix hausman `matiia'

    }  /* if "`doiia'"=="no" */

*-> suest-based HAUSMAN IIA Test

		version 9
		* see if cluster has been used and, if so, this can be incorporated in suest
		local clustvar = e(clustvar)
    * can't do if only two categories
    if "`dosuiia'"=="yes" & `numcats' == 2 {
        di _n in r ///
            "suest-based Hausman IIA test requires at least 3 dependent categories."
    }
    else if ("`clustvar'" != "." & "`clustvar'" != "") {
        di _n as err ///
            "suest-based Hausman IIA test must be estimated differently when cluster()"
        di as err "is specified, see [R] suest"
    }
    else if "`dosuiia'"=="yes" {
        di _newline in g /*
        */ "**** suest-based Hausman tests of IIA assumption `n'"
        di _newline in g /*
        */ " Ho: Odds(Outcome-J vs Outcome-K) are independent of "/*
        */ "other alternatives."

        * cycle through all alternatives
        tokenize "`catvals'"
        local count = 1
        while real("`count'") <= `numcats' {
            local lab`count' : word `count' of `catnms'
            local slab`count' : word `count' of `catnms8'
            scalar `omit' = real("``count''")
            if `omit'==real("`basecat'") & "`base'" != "" {
                * IIA for basecategory requires estimating mlogit with
                * new basecategory. Make new basecat the largest category
                * of the dependent variable that is not the original basecat
                local maxcnt = 0
                local count2 = 1
                while `count2' <= `numcats' {
                    if real("``count2''") != `omit' {
                        qui count if `depvar'==``count2'' & `sample'==1
                        if r(N)>`maxcnt' {
                            local newbase = ``count2''
                            local maxcnt = r(N)
                            local tmplab : word `count2' of `catnms'
                        }
                    }
                    local count2 = `count2' + 1
                } /* while count2 <= `numcats' */

                * estimates of old logit are held in _X
                qui mlogit `depvar' `rhsnam' `wtis' /*
                */ if `sample' == 1, b(`newbase') 
                qui estimates store _Xnb
    
                qui mlogit `depvar' `rhsnam' `wtis' /*
                */ if `sample'==1 & `depvar'!=`omit', b(`newbase')
                qui estimates store _Y
                local eqnames = e(eqnames)
                qui estimates store _Y
                qui suest _Y _Xnb
                qui estimates store _suest

                foreach name in `eqnames' {
                * di `"`eqnames'"'
                    qui test [_Xnb_`name' = _Y_`name'], cons accum
                }
                if "`detail'"=="detail" {
                    suest
                    test
                }

                scalar `chisq' = r(chi2)
                scalar `df' = r(df)
                scalar `pval' = r(p)
                if `pval' == . | `chisq' < 0 { 
                    scalar `pval' = -9999 
                }

                *put things back and then hold them again
                qui estimates restore _X
                mat `nxtrow' = `omit', `chisq', `df', `pval'
                mat rownames `nxtrow' = "`slab`count''"
                mat `matsuiia' = nullmat(`matsuiia') \ `nxtrow'
                
            } /* if `omit'==real("`basecat'") */
            else if `omit'!=real("`basecat'") {
                quietly mlogit `depvar' `rhsnam' `wtis' /*
                */ if `sample' == 1 & `depvar' != `omit', b(`basecat') 
                local eqnames = e(eqnames)
                qui estimates store _Y
                qui suest _Y _X
                qui estimates store _suest

                ** execute tests
                foreach name in `eqnames' {
                * di `"`eqnames'"'
                   qui test [_X_`name' = _Y_`name'], cons accum
                }
                if "`detail'"=="detail" {
                    suest
                    test
                }
                scalar `chisq' = r(chi2)
                scalar `df' = r(df)
                scalar `pval' = r(p)
                if `pval' == . | `chisq' < 0 { 
                    scalar `pval' = -9999 
                }
                qui estimates restore _X
                mat `nxtrow' = `omit', `chisq', `df', `pval'
                mat rownames `nxtrow' = "`slab`count''"
                mat `matsuiia' = nullmat(`matsuiia') \ `nxtrow'
            }  /* else if `omit'!=real("`basecat'") */
            local count = `count' + 1
        } /* while real("`count'") <= `numcats' */

        mat colnames `matsuiia' = omitted chi2 df p
        local anyneg = "no"
        local countto = rowsof(`matsuiia')
        local count = 1

        di _newline `smcl' in g " Omitted" _col(10) "`vline'" /*
        */ _col(17) "chi2" _col(24) "df" _col(29) "P>chi2" _col(38) "evidence"
        di `smcl' in g _dup(9) "`dash'" "`plussgn'" _dup(36) "`dash'"

        *cycle through row by row of output matrix and print
        while `count' <= `countto' {
            scalar `chisq' = `matsuiia'[`count', 2]
            scalar `df' = `matsuiia'[`count', 3]
            scalar `pval' = `matsuiia'[`count', 4]
            if `pval' == -9999 {
                local anyneg "yes"
                local implies "---"
                *added for stata 7 compatibility
                local printnm "`slab`count''"
                local printnm = abbrev("`printnm'", 8)

                di `smcl' in y %8s "`printnm'" _col(10) in g "`vline'" /*
                */ _col(13) %8.3f in y `chisq' /*
                */ _col(21) %5.0f `df' /*
                */ _col(30) " ---" /*
                */ _col(38) %-10s "`implies'"
            }
            else {
                local implies  "for Ho"
                if `pval' < .05 {
                    local implies "against Ho"
                }
                *added for stata 7 compatibility
                local printnm "`slab`count''"
                local printnm = abbrev("`printnm'", 12) 

                di `smcl' %8s in y "`printnm'" _col(10) in g "`vline'" /*
                */ _col(13) %8.3f in y `chisq' /*
                */ _col(21) %5.0f `df' /*
                */ _col(30) %4.3f `pval' /*
                */ _col(38) %-10s "`implies'"
            }
            local count = `count' + 1
        } /* while `count' <= `countto' */
        di `smcl' in g _dup(9) "`dash'" "`bottomt'" _dup(36) "`dash'"

        qui estimates restore _X
        return matrix suest `matsuiia'
    }  /* if "`doiia'"=="no" */

*-> Small-Hsiao test of iia

		version 7
    * NOTE: THE CODE FOR COMPUTING THE SMALL-HSIAO TEST IS ADAPTED
    * FROM CODE WRITTEN BY NICK WINTER (IN HIS -SMHSIAO- COMMAND)

    * 050219 fix error in df for sh test

    *can't do if only two categories
    if "`doshiia'"=="yes" & `numcats' == 2 {
        di _n in r "Small-Hsiao IIA test requires at least 3 dependent categories."
    }
    else if "`doshiia'"=="yes" {
        tempname rowres matsh touse
        di _newline in g /*
        */ "**** Small-Hsiao tests of IIA assumption `n'"
        di _newline in g /*
        */ " Ho: Odds(Outcome-J vs Outcome-K) are independent of other alternatives."
        qui gen `touse' = e(sample)

        tempvar samp
        qui gen `samp'=round(uniform(),1)+1 if `touse'
        local y `e(depvar)'
        tempvar tempy
        qui gen `tempy' = `depvar'
        local varlist "`tempy' `rhsnam'"	
				*local dof = `numrhs' + 1
        qui ta `tempy' if `touse' & `samp'==1
        local cat1 `r(r)'
        qui ta `tempy' if `touse' & `samp'==2
        local cat2 `r(r)'
        if `cat1'!=`numcats' | `cat2'!=`numcats' {
            di in r /*
            */ "Random draw yielded empty cells for some categories of `y' in"
            di in r /*
            */ "one of the half-samples. Could not estimate Small-Hsiao test."
            error 148
        }

        local count = 1
        local countto = `numcats' - 1
        if "`base'"!="" { 
            local countto = `numcats' 
        }
        while `count' <= `countto' {
            local bcat "b(`basecat')"
            if `count'==`numcats' { 
                local bcat "" 
            }
            local elim : word `count' of `catvals'
            local ielim `elim'
            tempname Vals
            qui tab `tempy' if `touse', matrow(`Vals')
            local nEvals = `numcats'-1
            local Yvals = ""
            local EYvals = ""
            local EYeqs = ""
            local i = 1
            while `i' <= `numcats' {
                local Yval`i' = `Vals'[`i',1]
                local Yvals "`Yvals' `Yval`i''"
                    if `Yval`i'' != `elim' {
                        local EYvals "`EYvals' `Yval`i''"
                        local EYeqs "`EYeqs' `i'"
                        local Ylab`i' `Yval`i''
                    }
                local i = `i' + 1
            }

            tempvar lnL denom
            tempname b0a b0b b0ab b1b

            qui mlogit `varlist' /*
            */ if (`touse' & `samp'==2 & `tempy'!=`elim') `wtis',  `bcat'
            *spost9 df for SH 19Feb2005
            tempname v
            mat `v' = e(V)
            local dof = rowsof(`v')
            local lnL_1 = e(ll)
            if `count'==`numcats' {
                local tmpbcat "`e(basecat)'"
                local bcat "b(`tmpbcat')"
            }
            *ESTIMATE MODELS FOR EACH HALF SAMPLE
            qui mlogit `varlist' if `touse' & `samp'==1 `wtis', `bcat'
            mat `b0a' = e(b)
            qui mlogit `varlist' if `touse' & `samp'==2 `wtis', `bcat'
            mat `b0b' = e(b)
            * Zhang & Hoffman eq. 9
            mat `b0ab' = (0.70710678)*(`b0a') + (0.29289322)*(`b0b')

            * get LnL for amalgamated coefficients
            *get XBs & assemble denominator
            qui gen double `denom' = 0 if `touse'
            local i 1
            * cycle through values (w/o eliminated one)
            while `i' <= (`numcats'-1) {
                local cury : word `i' of `EYvals'
                local cureq : word `i' of `EYeqs'
                tempvar xb`cureq'
                if `cury' != `basecat' & "`cury'" != "`tmpbcat'" {
                    matrix score double `xb`cureq'' = `b0ab' /*
                    */ if `touse', eq(`Ylab`cureq'')
                }
                else {
                    qui gen double `xb`cureq''=0  /* because (exp(0)=1) */
                }
                qui replace `denom'=`denom' + exp(`xb`cureq'') if `touse'
                local i=`i'+1
            }

        		* create Log likelihood using amalgamated coeff.
            qui gen double `lnL' = . if `touse'
            local i 1
            while `i'<=`nEvals' {
                local cureq : word `i' of `EYeqs'
                local cury : word `i' of `EYvals'
                qui replace `lnL' = ln(exp(`xb`cureq'')/(`denom')) /*
                */ if `tempy'==`cury' & `touse'
                local i=`i'+1
            }

        * GET LnL, only for observations in the 2d sample
        * and without eliminated observations:
            sum `lnL' if `touse' & `samp'==2 & `tempy'!=`elim', meanonly
            local lnL_0 = r(sum)
            local SH = -2 * (`lnL_0' - `lnL_1')
            local p = chiprob(`dof',`SH')
            mat `rowres' = `elim' , `lnL_0' , `lnL_1' , `SH' , `dof' , `p'
            mat rownames `rowres' = "test `count'"
            mat colnames `rowres' = elim_cat lnL_0 lnL_1 chi2 df p
            mat `matsh' = nullmat(`matsh') \ `rowres'
            local count = `count' + 1
        }

        di _newline `smcl' in g " Omitted" _col(10) "`vline'" /*
        */ _col(13) "lnL(full)" _col(24) "lnL(omit)" /*
        */ _col(37) "chi2" _col(44) "df" _col(49) "P>chi2" _col(58) "evidence"
        di `smcl' in g _dup(9) "`dash'" "`plussgn'" _dup(57) "`dash'"
        local count = 1
        local countto = rowsof(`matsh')
        while `count' <= `countto' {
            local elim = `matsh'[`count', 1]
            local elimnm8 : word `count' of `catnms8'
            local lnL_0 = `matsh'[`count', 2]
            local lnL_1 = `matsh'[`count', 3]
            local SH = `matsh'[`count', 4]
            scalar `df' = `matsh'[`count', 5]
            scalar `pval' = `matsh'[`count', 6]
            local count = `count' + 1
            local implies  "for Ho"
            if `pval' < .05 {
                local implies "against Ho"
            }
            di `smcl' in y %8s "`elimnm8'" _col(10) in g "`vline'" /*
            */ _col(13) %9.3f in y `lnL_0' /*
            */ _col(24) %9.3f `lnL_1' /*
            */ _col(33) %8.3f `SH' /*
            */ _col(41) %5.0f `df' /*
            */ _col(50) %4.3f `pval' /*
            */ _col(58) %-10s "`implies'"
        }
        di `smcl' in g _dup(9) "`dash'" "`bottomt'" _dup(57) "`dash'"

        qui mat list `matsh'
        qui version 9: estimates restore _X
        return matrix smhsiao `matsh'
    }  /* if "`doshiia'"=="no" */

*-> Wald tests for combining categories

    if "`docomb'"=="yes" & `numcats' == 2 {
        di in r "Test requires at least 3 dependent categories."
    }
    else if "`docomb'"=="yes" {
        di _newline in g /*
        */ "**** Wald tests for combining alternatives `n'"
        di _newline in g /*
        */  " Ho: All coefficients except intercepts associated " /*
        */ "with a given pair"
        di in g /*
        */  "     of alternatives are 0 (i.e., alternatives can be combined)."
        di `smcl' _newline in g %17s "Alternatives tested" _col(20) "`vline'" /*
        */ _col(26) "chi2" _col(33) "df" _col(38) "P>chi2"
        di `smcl' in g _dup(19) "`dash'" "`plussgn'" _dup(24) "`dash'"

        tokenize "`catvals'"
        qui version 9: estimates restore _X

        * cycle through all pairs of outcomes
        local count1 = 1
        while `count1' <= (`numcats'-1) {
            local count2 = `count1' + 1
            while `count2' <= `numcats' {
                    if "``count1''"=="`basecat'" {
                        quietly test [``count2'']
                    }
                    else if "``count2''"=="`basecat'" {
                        quietly test [``count1'']
                    }
                    else {
                        quietly test [``count2''=``count1'']
                    }
                    scalar `chisq' = r(chi2)
                    scalar `df' = r(df)
                    scalar `pval' = r(p)
                    local numrow = `numrow' + 1
                    local s1`numrow' : word `count1' of `catnms8'
                    local s2`numrow' : word `count2' of `catnms8'
                    if `pval' == . { scalar `pval' = -9999 }
                    mat `nxtrow' = ``count1'', ``count2'', /*
                    */ `chisq', `df', `pval'
                    mat roweq `nxtrow' = "`s1`numrow''"
                    mat rownames `nxtrow' = "`s2`numrow''"
                    mat `matcomb' = nullmat(`matcomb') \ `nxtrow'
                local count2 = `count2' + 1
            }
            local count1 = `count1' + 1
        } /* while `count1' <= `numcats' */

        mat colnames `matcomb' = cat1 cat2 chi2 df p
        local countto = rowsof(`matcomb')
        local count = 1
        while `count' <= `countto' {
            scalar `chisq' = `matcomb'[`count', 3]
            scalar `df' = `matcomb'[`count', 4]
            scalar `pval' = `matcomb'[`count', 5]
            if `pval' == -9999 { scalar `pval' = . }
            di `smcl' in y %8s "`s1`count''" _col(9) "-" %8s "`s2`count''" /*
            */ _col(20) in g "`vline'" /*
            */ _col(21) %9.3f in y `chisq' /*
            */ _col(30) %5.0f `df' /*
            */ _col(39) %4.3f `pval'
            local count = `count' + 1
        }
        di `smcl' in g _dup(19) "`dash'" "`bottomt'" _dup(24) "`dash'"
        qui version 9: estimates restore _X
        return matrix combine `matcomb'
    } /* if "`docomb'"=="yes" */

*-> LR tests for combining categories

    if "`dolrcom'"=="yes" & `numcats' == 2 {
        di in r "Test requires at least 3 dependent categories."
    }
    else if "`dolrcom'"=="yes" {
        di _newline in g /*
        */ "**** LR tests for combining alternatives `n'"
        di _newline in g /*
        */  " Ho: All coefficients except intercepts associated" /*
        */ " with a given pair"
        di in g /*
        */  "     of alternatives are 0 (i.e., alternatives can be collapsed)."
        di `smcl' _newline in g %17s "Alternatives tested" _col(20) "`vline'" /*
        */ _col(26) "chi2" _col(33) "df" _col(38) "P>chi2"
        di `smcl' in g _dup(19) "`dash'" "`plussgn'" _dup(24) "`dash'"

        lrtest, saving(lrc)
        tokenize "`catvals'"

        * cycle through all pairs of outcomes
        local count1 = 1
        while `count1' <= (`numcats'-1) {
            local count2 = `count1'+1
            while `count2' <= `numcats' {
                constraint define 999 [``count1'']
                qui mlogit `depvar' `rhsnam' `wtis' /*
                */ if `sample' == 1, base(``count2'') constr(999)
                qui lrtest, using(lrc)
                scalar `chisq' = r(chi2)
                scalar `df' = r(df)
                scalar `pval' = r(p)
                local numrow = `numrow' + 1
                local s1`numrow' : word `count1' of `catnms8'
                local s2`numrow' : word `count2' of `catnms8'
                if `pval' == . { scalar `pval' = -9999 }
                mat `nxtrow' = ``count1'', ``count2'', `chisq', `df', `pval'
                mat roweq `nxtrow' = "`s1`numrow''"
                mat rownames `nxtrow' = "`s2`numrow''"
                mat `matlrc' = nullmat(`matlrc') \ `nxtrow'
                local count2 = `count2' + 1
            }
            local count1 = `count1' + 1
        } /* while `count1' <= `numcats' */

        mat colnames `matlrc' = cat1 cat2 chi2 df p
        local countto = rowsof(`matlrc')
        local count = 1
        while `count' <= `countto' {
            scalar `chisq' = `matlrc'[`count', 3]
            scalar `df' = `matlrc'[`count', 4]
            scalar `pval' = `matlrc'[`count', 5]
            if `pval' == -9999 { scalar `pval' = . }
            di `smcl' in y %8s "`s1`count''" _col(9) "-" %8s "`s2`count''" /*
            */ _col(20) in g "`vline'" /*
            */ _col(21) %9.3f in y `chisq' /*
            */ _col(30) %5.0f `df' /*
            */ _col(39) %4.3f `pval'
            local count = `count' + 1
        }
        di `smcl' in g _dup(19) "`dash'" "`bottomt'" _dup(24) "`dash'"

        qui version 9: estimates restore _X
        return matrix lrcomb `matlrc'
    } /* if "`dolrcom'"=="yes" */

		qui version 9: estimates restore _X
		* drop estimates stored in program
		capture estimates drop _X
		capture estimates drop _Xnb
		capture estimates drop _Y
		capture estimates drop _suest

end
exit
* version 1.6.9 09Aug2005 - change terminology for alternatives
* version 1.7.0 22Jun2006 - fix warning for hausman; use estimates restore; add suest (undocumented)
* version 1.7.1 29Jun2006 - add suest as documented
* version 1.7.2 18Aug2006 - fix mlogit program name bug
* version 1.7.4  8Dec2006 - suest bug fix
* version 1.7.5 2007-06-29 stata 10 fixes
