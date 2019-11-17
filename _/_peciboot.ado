*! version 1.0.0 2009-10-28 jsl
*   - stata 11 fix

//  bootstrap for prvalue
capture program drop _peciboot
program define _peciboot, rclass

    version 8.0
    syntax [if] [in] [, x(passthru) rest(passthru) all ///
                     save diff ///
                     Reps(int 1000)  SIze(int -9) dots ///
                     ITERate(passthru) match SAving(string)]

    tempname post_name lastest p_obsmat pdif_obsmat pci_mat pdifci_mat ///
            probs1 probs2 probsdif ///
            tempbase tempbase2
    tempname mu_obs mudif_obs mu mudif ///
            all0_obs all0dif_obs all0 all0dif
    tempname p_obs p_avg p_std p_normlo p_normup ///
            pdif_obs pdif_avg pdif_std pdif_normlo pdif_normup ///
            p_pctlo p_pctup pdif_pctlo pdif_pctup z t tdf ///
            totobs zpr zdc p_bcup p_bclo pdif_bcup pdif_bclo
    tempname orig_pred orig_info orig_type orig_base orig_base2 ///
            orig_upper orig_lower orig_upnorm orig_lonorm ///
            orig_upbias orig_lobias
    tempvar touse
    tempfile original post_file

    * store information to restore when bootstrapping is done
    mat `orig_pred' = pepred
    mat `orig_info' = peinfo
    mat `orig_base' = pebase
    mat `orig_upper' = peupper
    mat `orig_lower' = pelower

    * get information on model that has been estimated
    local io $petype
    local maxcnt = peinfo[1,11] // get max # of counts compute
    if "`maxcnt'"=="." {
        local maxcnt = 9
    }
    local cmd : word 1 of $petype // specific model command
    local input : word 2 of $petype // typical or twoeq
    local output : word 3 of $petype // output type
    local depvar "`e(depvar)'" // dep var
    local numcats = peinfo[1,2]
    forval i = 1/`numcats' { // construct string with outcome categories
        local curval = pepred[1, `i']
        local catvals "`catvals'`cutval' "
    }
    local rhsnms : colnames(pebase)
    if "`input'"=="twoeq" {
        local rhsnms2 : colnames(pebase2)
    }
    local wtype "`e(wtype)'" // weight type
    local wexp "`e(wexp)'" // weight expression
    local nocon = "" // constant in model
    if peinfo[1,6]==1 {
        local nocon "nocon"
    }
    local inout "`input' `output'"
    if "`input'"=="twoeq" {
        mat `orig_base2' = pebase2
    }
    local nobs = e(N) // observations in original estimation sample
    local level = peinfo[1,3]
    scalar `z' = peinfo[1,4]

    * trap improper use of match option
    if ("`output'"!="binary" & "`output'"!="ordered" ///
            & "`output'"!="mlogit") & "`match'"!="" {
        di as error ///
        "Error: match works only with binary, ordered, and mlogit routines."
        exit
    }

    * create touse indicating cases in the original estimatin sample
    mark `touse' if e(sample)
    if "`size'"=="-9" | "`size'"=="" { // -9 is default for size
        local size = e(N)
    }
    if "`size'"!="" & `size'>e(N) {
        di as error ///
            "Error: resample size is larger than the number of observations"
        exit
    }

    * create list of variables and expressions used by post commands
    forval i = 1/`numcats' {
        tempname  p`i'
        local post_var "`post_var'`p`i'' "
        local post_exp "`post_exp'(`p`i'') "
        if "`diff'"!="" {
            tempname p`i'dif
            local post_var "`post_var'`p`i'dif' "
            local post_exp "`post_exp'(`p`i'dif') "
        }
    }

    * count # of statistics to bootstrap
    local nstats = `numcats' // # of statistics being bootstrapped
    if  "`output'"=="count" {
        local nstats = `nstats' + 1 // add mu
        local post_exp "`post_exp'(`mu') "
        local post_var "`post_var'`mu' "
        if "`diff'"!="" {
            local post_exp "`post_exp'(`mudif') "
            local post_var "`post_var'`mudif' "
        }
    }
    if  "`input'"=="twoeq"  {
        local nstats = `nstats' + 1 // add pr always 0
        local post_exp "`post_exp'(`all0') "
        local post_var "`post_var'`all0' "
        if "`diff'"!="" {
            local post_exp "`post_exp'(`all0dif') "
            local post_var "`post_var'`all0dif' "
        }
    }

     local dots = cond("`dots'"=="", "*", "noisily")

//  STORE OBSERVED ESTIMATES

    * get predictions for prob and discrete change
    mat `p_obsmat' = (pepred[2, 1...])'
    if "`diff'"!="" {
        mat `pdif_obsmat' = (pepred[6,1...])'
    }

    * get rate and pr always 0
    if  "`output'"=="count" {
        scalar `mu_obs' = pepred[3,2]
        if "`diff'"!="" {
            scalar `mudif_obs' = pepred[7,2]
        }
    }
    if  "`input'"=="twoeq" {
        scalar `all0_obs' = pepred[3,4]
        if "`diff'"!="" {
            scalar `all0dif_obs' = pepred[7,4]
        }
    }

    * hold non-bootstrap estimation results; restore later
    _estimates hold `lastest', restore

    if "`match'"!="" {
        preserve // #1
        quietly keep if `touse'
        quietly save `original'
        restore // #1
    }

    postfile `post_name' `post_var' using `post_file'

//  BEGIN SIMULATIONS

    quietly {

        * # of replications missed due to nonconvergence
        local nmissed = 0

        forval i = 1/`reps' {

            `dots' dodot `reps' `i'
            preserve // #2

            * if match, resample within outcome categories
            if "`match'"!="" {
                tempname samppct catsize
                scalar `samppct' = `size' / `nobs'

                forval i = 1/`numcats' {
                    tempfile cat`i'file
                    use `original', clear
                    local cur_val: word `i' of `catvals'
                    local depval`i' "`cur_depval'"
                    keep if `depvar'==`cur_val'
                    count
                    scalar `catsize' = `samppct'*r(N)
                    local resamp = round(`catsize',1)
                    if `catsize'==0 {
                        local resamp = 1
                    }
                    bsample `resamp'
                    save `cat`i'file'
                }

                * stack data from all categories
                use `cat1file', clear
                forval i = 2/`numcats' {
                    append using `cat`i'file'
                }
            } // matched

            * if match option not specified
            else {

                keep if `touse'
                bsample `size'

                * check if boot sample has all outcome categories
                if "`output'"!="count" {
                    _pecats `depvar'
                    local catschk = r(numcats)
                    * if category missed, count it, and take another sample
                    if `catschk' != `numcats' {
                        local ++nmissed // count missed replication
                        local errlog "`errlog'`i', "
                        restore
                        continue
                    }
                }
            } // no matched

//  ESTIMATE MODEL WITH BOOTSTRAP SAMPLE

            capture { // trap errors in estimation

                if "`input'" == "typical" {
                    `cmd' `depvar' `rhsnms' ///
                            if `touse' [`wtype'`wexp'], `iterate' `nocon'
                }
                else if "`input'" == "twoeq" {
                    `cmd' `depvar' `rhsnms' ///
                            if `touse' [`wtype'`wexp'], ///
                            inflate(`rhsnms2') `iterate' `nocon'
                }

                * get base values for bootstrap sample
                _pebase `if' `in', `x' `rest' `all'
                mat `tempbase' = r(pebase)
                mat PE_in = `tempbase'
                if "`input'"=="twoeq" {
                    mat `tempbase2' = r(pebase2)
                    mat PE_in2 = `tempbase2'
                }

                * get predictions
                _pepred, level(`level') maxcnt(`maxcnt')
                local tmp2 = r(maxcount)
                local tmp = r(level)
                capture _return drop pepred
                _return hold pepred
                _return restore pepred, hold
                * put results from bootstrap estimate into global matrices
                _pecollect, inout(`inout') level(`tmp') ///
                        maxcount(`tmp2') `diff'

            } // capture

            * if error in estimation, count it as missed
            if _rc!=0 {
                local ++nmissed
                local errlog "`errlog'`i', "
                restore
                continue
            }

            * get predicted probabilities
            mat `probs1'= (pepred[2, 1...])'
            * get mu and pr(always 0) from count models
            if  "`output'"=="count" {
                scalar `mu' = pepred[3,2]
            }
            if  "`input'"=="twoeq"  {
                scalar `all0' = pepred[3,4]
            }

//  DISCRETE CHANGES

            if "`diff'"!="" {

                capture {

                    * $pexsetup hold x() rest() all from prior prvalue
                    _pebase `if' `in', $pexsetup
                    mat `tempbase' = r(pebase)
                    mat `tempbase2' = r(pebase2)
                    mat PE_in = `tempbase'
                    if "`input'"=="twoeq" {
                        mat PE_in2 = `tempbase2'
                    }
                    _pepred, level(`level') maxcnt(`maxcnt')
                    local tmp2 = r(maxcount)
                    local tmp = r(level)
                    _return drop _all
                    _return hold pepred
                    _return restore pepred, hold
                    _pecollect, inout(`inout') level(`tmp') ///
                            maxcount(`tmp2') `diff'

                } // end of capture

                if _rc !=0 { // if error in estimation
                    local ++nmissed // count missed replication
                    local errlog "`errlog'`i', "
                    restore
                    continue
                }

                mat `probs2' = (pepred[2, 1...])'
                mat `probsdif' = `probs1' - `probs2'

                * get results from count models
                if  "`output'"=="count" {
                    scalar `mudif' = -1 * pepred[7,2]
                }
                if  "`input'"=="twoeq"  {
                    scalar `all0dif' = -1 * pepred[7,4]
                }

            } // end of diff loop

//  POST RESULTS

            * move probs from matrices to scalars for posting
            forval j = 1/`numcats' {
                scalar `p`j'' = `probs1'[`j', 1]
                if "`diff'"!="" {
                    scalar `p`j'dif' = `probsdif'[`j', 1]
                }
            }
            post `post_name' `post_exp'

            restore // #2

        } // end of replications loop

        postclose `post_name' // close postfile

//  CONSTRUCT CI

        preserve // #3

        use `post_file', clear
        qui count
        scalar `totobs' = r(N)
        scalar `tdf' = `totobs' -1
        scalar `t' = invttail(`tdf',((1-(`level')/100)/2))

        * rename mu and all0 so loop for p_i can be used later
        local inew = `numcats'
        if  "`output'"=="count" {
            local inew = `inew' + 1
            tempname p`inew'
            rename `mu' `p`inew''
            matrix `p_obsmat' = `p_obsmat' \ `mu_obs'
            if "`diff'"!="" {
                tempname p`inew'dif
               rename `mudif' `p`inew'dif'
               matrix `pdif_obsmat' = `pdif_obsmat' \ `mudif_obs'
            }
        }
        if  "`input'"=="twoeq" {
            local inew = `inew' + 1
            tempname p`inew'
            rename `all0' `p`inew''
            matrix `p_obsmat' = `p_obsmat' \ `all0_obs'
            if "`diff'"!="" {
                tempname p`inew'dif
                rename `all0dif' `p`inew'dif'
                matrix `pdif_obsmat' = `pdif_obsmat' \ `all0dif_obs'
            }
        } // twoeq

        * loop through each statistics
        forval i = 1/`nstats' {

            sum `p`i'', d
            scalar `p_obs' = `p_obsmat'[`i',1]
            scalar `p_avg' = r(mean)
            scalar `p_std' = r(sd)

            * bias correction method
            qui count if `p`i''<=`p_obs'
            * zpr will be missing if r(N)=0
            scalar `zpr' = invnorm(r(N)/`totobs')

            * use t for normal
            scalar `p_normup' = `p_obs' + `t'*`p_std'
            scalar `p_normlo' = `p_obs' - `t'*`p_std'

            * percentile method
            qui _pctile `p`i'', nq(1000)
            local upperpctile = 500 - 5*-`level'
            local lowerpctile = 1000 - `upperpctile'
            scalar `p_pctup' = r(r`upperpctile')
            scalar `p_pctlo' = r(r`lowerpctile')

            * percentile for the bias-correction.
            local upnum = round((norm(2*`zpr' + `z')) * 1000, 1)
            local lonum = round((norm(2*`zpr' - `z')) * 1000, 1)
            if `zpr'==. { // if missing, upper & lower limits are missing
                scalar `p_bcup' = .
                scalar `p_bclo' = .
            }
            else {
                scalar `p_bcup' = r(r`upnum')
                scalar `p_bclo' = r(r`lonum')
            }

            * stack results from 3 methods
            mat `pci_mat' = nullmat(`pci_mat') \ ///
                `p_pctlo', `p_pctup', ///
                `p_normlo', `p_normup', ///
                `p_bclo', `p_bcup'

 // CI FOR DISCRETE CHANGE

            if "`diff'"!="" {

                sum `p`i'dif', d
                scalar `pdif_obs' = `pdif_obsmat'[`i',1]
                scalar `pdif_avg' = r(mean)
                scalar `pdif_std' = r(sd)

                * bias corrected method
                qui count if `p`i'dif'<=`pdif_obs'
                scalar `zdc' = invnorm(r(N)/`totobs')
                local upnum = round((norm(2*`zdc' + `z'))*1000, 1)
                local lonum = round((norm(2*`zdc' - `z'))*1000, 1)

                * use t for normal
                scalar `pdif_normup' = `pdif_obs' + `t'*`pdif_std'
                scalar `pdif_normlo' = `pdif_obs' - `t'*`pdif_std'

                * percentile method
                _pctile `p`i'dif', nq(1000)
                scalar `pdif_pctup' = r(r`upperpctile')
                scalar `pdif_pctlo' = r(r`lowerpctile')

                * percentile for bias corrected
                if `zdc'==. {
                    scalar `pdif_bcup' = .
                    scalar `pdif_bclo' = .
                }
                else {
                    scalar `pdif_bcup' = r(r`upnum')
                    scalar `pdif_bclo' = r(r`lonum')
                }

                * stack results from 3 methods
                mat `pdifci_mat' = nullmat(`pdifci_mat') \ ///
                    `pdif_pctlo', `pdif_pctup', ///
                    `pdif_normlo', `pdif_normup', ///
                    `pdif_bclo', `pdif_bcup'
            }
        }

    } // end of quietly

    * grab the mu and all0 ci's
    tempname muci mudifci all0ci all0difci
    local inew = `numcats'
    if  "`output'"=="count" {
        local inew = `inew' + 1
        matrix `muci' = `pci_mat'[`inew',1...]
        if "`diff'"!="" {
            matrix `mudifci' = `pdifci_mat'[`inew',1...]
        }
    }
    if "`input'"=="twoeq" {
        local inew = `inew' + 1
        matrix `all0ci' = `pci_mat'[`inew',1...]
        if "`diff'"!="" {
            matrix `all0difci' = `pci_mat'[`inew',1...]
        }
    }
    * get rid of mu and all 0 info leaving only probabilities
    mat `pci_mat' = `pci_mat'[1..`numcats',1...]
    if "`diff'"!="" {
        mat `pdifci_mat' = `pdifci_mat'[1..`numcats',1...]
    }

//  RESTORE DATA FROM ORIGINAL ESTIMATION

    mat pepred = `orig_pred'
    mat peinfo = `orig_info'
    mat pebase = `orig_base'
    if "`input'"=="twoeq" {
        mat pebase2 = `orig_base2'
    }
    mat peupper = `orig_upper'
    mat pelower = `orig_lower'
    mat peupnorm = peupper
    mat pelonorm = pelower
    mat peupbias = peupper
    mat pelobias = pelower
    mat peuppct = peupper
    mat pelopct = pelower

    global petype "`io'"

//  ADD CIs TO GLOBAL

    * get list of rownames to use in return matrices
    forval i = 1/`numcats' {
        local curval = pepred[1, `i'] // current val
        local plist "`plist' p`curval' " // predicted probabilities
        local dlist "`dlist' pdif`curval' " // discrete changes
    }

    * save x() rest() all setup to be used for prvalue, dif
    if "`save'"!="" {
        global pexsetup "`x' `rest' `all'"
    }

    if "`diff'"!="" { // if discrete change
        mat colnames `pdifci_mat' = pctlo pctup nrmlo nrmup bclo bcup
        mat rownames `pdifci_mat' = `dlist'
        mat pelower[6,1] = (`pdifci_mat'[1...,1])'
        mat peupper[6,1] = (`pdifci_mat'[1...,2])'
        mat pelonorm[6,1] = (`pdifci_mat'[1...,3])'
        mat peupnorm[6,1] = (`pdifci_mat'[1...,4])'
        mat pelobias[6,1] = (`pdifci_mat'[1...,5])'
        mat peupbias[6,1] = (`pdifci_mat'[1...,6])'
        return mat bootcidifp = `pdifci_mat'
    } // difference

    mat colnames `pci_mat' = pctlo pctup nrmlo nrmup bclo bcup
    mat rownames `pci_mat' = `plist'
    mat pelower[2,1] = (`pci_mat'[1..., 1])'
    mat peupper[2,1] = (`pci_mat'[1..., 2])'
    mat pelonorm[2,1] = (`pci_mat'[1..., 3])'
    mat peupnorm[2,1] = (`pci_mat'[1..., 4])'
    mat pelobias[2,1] = (`pci_mat'[1..., 5])'
    mat peupbias[2,1] = (`pci_mat'[1..., 6])'
    return mat bootcip = `pci_mat'
    local repsnomis = `reps' - `nmissed'
    return scalar Nrepsnomis = `repsnomis'

    if "`output'"=="count" {
        mat pelower[3,2] = `muci'[1,1]
        mat peupper[3,2] = `muci'[1,2]
        mat pelonorm[3,2] = `muci'[1,3]
        mat peupnorm[3,2] = `muci'[1,4]
        mat pelobias[3,2] = `muci'[1,5]
        mat peupbias[3,2] = `muci'[1,6]
        if "`diff'"!="" {
            mat pelower[7,2] = `mudifci'[1,1]
            mat peupper[7,2] = `mudifci'[1,2]
            mat pelonorm[7,2] = `mudifci'[1,3]
            mat peupnorm[7,2] = `mudifci'[1,4]
            mat pelobias[7,2] = `mudifci'[1,5]
            mat peupbias[7,2] = `mudifci'[1,6]
        }
    }
    if "`input'"=="twoeq" {
        mat pelower[3,4] = `all0ci'[1,1]
        mat peupper[3,4] = `all0ci'[1,2]
        mat pelonorm[3,4] = `all0ci'[1,3]
        mat peupnorm[3,4] = `all0ci'[1,4]
        mat pelobias[3,4] = `all0ci'[1,5]
        mat peupbias[3,4] = `all0ci'[1,6]
        if "`diff'"!="" {
            mat pelower[7,4] = `all0difci'[1,1]
            mat peupper[7,4] = `all0difci'[1,2]
            mat pelonorm[7,4] = `all0difci'[1,3]
            mat peupnorm[7,4] = `all0difci'[1,4]
            mat pelobias[7,4] = `all0difci'[1,5]
            mat peupbias[7,4] = `all0difci'[1,6]
        }
    }

    if "`saving'"!="" {
        forval i = 1/`numcats' {
            local varnm: word `i' of `plist'
            rename `p`i'' b_`varnm'
            if "`diff'"!="" {
                local varnm: word `i' of `dlist'
                rename `p`i'dif' b_`varnm'
            }
        }
        if  "`output'"=="count" {
            local iadd = `numcats'+1
            rename `p`iadd'' b_mu
            if "`diff'"!="" {
                rename `p`iadd'dif' b_mudif
            }
        }
        if  "`input'"=="twoeq" {
            local iadd = `iadd' + 1
            rename `p`iadd'' b_alw0
            if "`diff'"!="" {
                rename `p`iadd'dif' b_alw0dif
            }
        }
        save `saving'
    }

    restore // #3

//  RESTORE ERETURNS

    mat peuppct = peupper // just duplicate the default method
    mat pelopct = pelower // just duplicate the default method
    _estimates unhold `lastest'

end // _peciboot

* produce dots
capture program drop dodot
program define dodot
    version 8
    args N n
    local dot "."
    * don't bother with %'s if few than 20 reps
    if `N'>19 {
        scalar s = `N'/10
        forvalues c = 0/10 {
            local c`c' = floor(`c'*s)
            if `n'==`c`c'' {
                local pct = `c'*10
                di in g `pct' "%" _c
                local dot ""
                * new line when iterations are done
                if `pct'==100 {
                    di
                }
            }
        } //forvalues
    } // if > 19
    di in g as txt "`dot'" _c
end
exit
* version 0.2.0 2005-02-03 (13Apr2005)
* version 0.2.1 13Apr2005
