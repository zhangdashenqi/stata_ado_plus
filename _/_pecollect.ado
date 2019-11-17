*! version 2.0.1 2008-07-09 jsl
*   - peinfo[3,8] to missing since it isn't the sd of the difference

//  Utility to collect information from the current model and
//  saves it to global matrices for use by other programs (e.g.,
//  for simulations or constructing plots unavailable with prgen).
//  For details on these matrices, -help prvalue_collect-

capture program drop _pecollect
program define _pecollect, rclass
    version 8
    tempname temp values mu xb prall0 nrhs2 muC ey mucount
    tempname dif difp difm r1 r2 r3

    syntax , level(real) inout(string) maxcount(string) [Diff reps(int 1000)]

// get information about current model

    * is it zero truncated?
    local iszt = 0
    if ("`e(cmd)'"=="ztp" | "`e(cmd)'"=="ztnb") local iszt = 1

    * type of model
    global petype "`e(cmd)' `inout'"
    local input : word 2 of $petype // is it a typical or twoeq model?
    local output : word 3 of $petype // what is the output type?

    local level = r(level) // CI level for current model

    * nrhs: # of rhs variables
    local colnms: colnames(PE_in)
    local nrhs: word count `colnms'
    local nrhs = `nrhs' // no _cons included

    * ncat: number of outcome categories
    if "`output'"=="count" {
        local ncat = `maxcount'+1
    }
    else if "`output'"=="regress" | "`output'"=="tobit" {
        local ncat = 1
    }
    else {
        _pecats
        local catvals = r(catvals)
        local ncat = r(numcats)
        _return restore pepred, hold // restore returns from _pepred
    }

    * nrhs2: # of rhs if zip or zinb
    local nrhs2 = .
    if "`input'"=="twoeq" {
        local colnms2: colnames(PE_in2)
        local nrhs2: word count `colnms2'
        local nrhs2 = `nrhs2' // no _cons included
    }

    * basecat: mlogit base category
    local basecat = .
    * if "`e(cmd)'"=="mlogit" { local basecat = e(basecat) }
    if "`e(cmd)'"=="mlogit" {
        local basecat = e(i_base)
    }

// peinfo - global matrix with numeric information about:
//
//      Row 1: the current model
//      Row 2: the saved model used to compute the difference
//      Row 3: Row 1 - Row 2

    mat def peinfo = J(3,12,.)
    matrix peinfo[1,1] = `nrhs' // nrhs - columns for pebase
    matrix peinfo[1,2] = `ncat' // numcats from _pecats
    matrix peinfo[1,3] = `level'*100 // ci level as 95 not .95
    matrix peinfo[1,4] = -invnorm((1-`level')/2) // z @ level for ci
    matrix peinfo[1,5] = `nrhs2' // nrhs2
    matrix peinfo[1,6] = . // nocon
    matrix peinfo[1,7] = `basecat' // base category for mlogit
    matrix peinfo[1,8] = . // stdp for binary model
    matrix peinfo[1,9] = `reps' // requested # of replications for bootstrap
    matrix peinfo[1,10] = . // completed # of replications for bootstrap
                            // this will be added after _peciboot is called
    matrix peinfo[1,11] = `maxcount'

    * if diff, add saved and compute current-saved
    if "`diff'" == "diff" {

        mat `r1' = peinfo[1,1...] // current
        mat `r2' = PRVinfo // saved
        mat `dif' = `r1' - `r2'
        mat peinfo = `r1' \ `r2' \ `dif'

* 2008-07-09
mat peinfo[3,8] = . // since this is not a valid stdp

    } // "`diff'" == "diff"

//  pebase and pebase2 - global matrices with base values

    * start with current base and two blank rows
    mat pebase = PE_in \ J(1,`nrhs',.) \ J(1,`nrhs',.)
    if "`input'" == "twoeq" {
        mat pebase2 = PE_in2 \ J(1,`nrhs2',.) \ J(1,`nrhs2',.)
        matrix rownames pebase2 = Current Saved Cur-Saved
    }

    * if diff, get previous base values
    if "`diff'" == "diff" {
        mat `dif' = pebase[1,1...] - PRVbase
        mat pebase = PE_in \ PRVbase \ `dif'
        if "`input'" == "twoeq" {
            mat `dif' = pebase2[1,1...] - PRVbase2
            mat pebase2 = PE_in2 \ PRVbase2 \ `dif'
            matrix rownames pebase2 = Current Saved Cur-Saved
        }
    }

//  gather information about current model

    * missing by default
    scalar `xb' = .
    scalar `mu' = . // rate in count; e(y) in zip/zinb
    scalar `mucount' = . // mu in count portion of zip/zinb
    scalar `prall0' = .

    * info on mu for count models
    if "`output'"=="count" {
        mat `temp' = r(mu)
        scalar `mu' = `temp'[1,1]
    }
    if "`e(cmd)'"=="zip"  | "`e(cmd)'"=="zinb" {
        mat `temp' = r(mucount) // grab rate from count portion of model
        scalar `mucount' = `temp'[1,1]
    }
    if  `iszt' {
        mat `temp' = r(xb)
        scalar `xb' = `temp'[1,1]
        mat `temp' = r(muC) // E(y|y<0)
        scalar `muC' = `temp'[1,1]
    }
    if  "`e(cmd)'"=="poisson" ///
        | "`e(cmd)'"=="nbreg" {
        mat `temp' = r(xb)
        scalar `xb' = `temp'[1,1]
    }
    if "`input'"=="twoeq" { // zip and zinb
        scalar `xb' = log(`mu')
        mat `temp' = r(always0)
        scalar `prall0' = `temp'[1,1]
    }

    if "`output'"=="binary" ///
        | "`output'"=="regress" ///
        | "`output'"=="tobit" ///
        | "`output'"=="ordered" {
        mat `temp' = r(xb)
        scalar `xb' = `temp'[1,1]
    }

//  start with empty pepred & peCpred matrices

    mat def pepred = J(7,`ncat',.)
    matrix rownames pepred = ///
        1values 2prob 3misc 4sav_prob 5sav_misc 6dif_prob 7dif_misc
    mat def peupper = pepred // holds upper ci
    mat def pelower = pepred // holds lower ci
    local method = word("$pecimethod",1)
    if "`method'"=="bootstrap" { // bootstrap computes 3 types of CIs
        mat def peupnorm = pepred // holds upper by normal appox
        mat def pelonorm = pepred // holds lower by normal appox
        mat def peupbias = pepred // holds upper with bias adjustment
        mat def pelobias = pepred // holds lower with bias adjustment
    }
    if  `iszt' {
        mat def peCpred = pepred // for conditional results
    }

//  pepred & peinfo: add info about current model

    if "`output'"=="binary" {

        mat pepred[1,1] = 0 // outcome values
        mat pepred[1,2] = 1
        mat `temp' = r(p0) // predictions
        mat pepred[2,1] = `temp'[1,1]
        mat `temp' = r(p1)
        mat pepred[2,2] = `temp'[1,1]
        mat pepred[3,1] = `xb'
        mat `temp' = r(stdp)
        mat peinfo[1,8] = `temp'[1,1]
        mat `temp' = r(p0_lo) // upper and lower limits
        * due to error in _pepred, r(p0_lo) is really upper limit
        mat peupper[2,1] = `temp'[1,1]
        mat `temp' = r(p0_hi)
        mat pelower[2,1] = `temp'[1,1]
        mat `temp' = r(p1_hi)
        mat peupper[2,2] = `temp'[1,1]
        mat `temp' = r(p1_lo)
        mat pelower[2,2] = `temp'[1,1]
        mat `temp' = r(xb_hi)
        mat peupper[3,1] = `temp'[1,1]
        mat `temp' = r(xb_lo)
        mat pelower[3,1] = `temp'[1,1]
    }

    if "`output'"=="tobit" ///
        | "`output'"=="regress" {

        mat pepred[1,1] = . // value
        mat pepred[2,1] = . // predicted probability
        mat pepred[3,1] = `xb'
        mat `temp' = r(xb_lo)
        mat pelower[3,1] = `temp'[1,1]
        mat `temp' = r(xb_hi)
        mat peupper[3,1] = `temp'[1,1]
        mat `temp' = r(stdp)
        mat peinfo[1,8] = `temp'[1,1]
    }

    if "`output'"=="ordered"  { // also works for mlogit

        mat `temp' = r(stdp)
        mat peinfo[1,8] = `temp'[1,1]
        mat `temp' = r(xb_hi)
        mat peupper[3,1] = `temp'[1,1]
        mat `temp' = r(xb_lo)
        mat pelower[3,1] = `temp'[1,1]
        forval i=1/`ncat' {
            local v : word `i' of `catvals'
            mat pepred[1,`i'] = `v'
            mat `temp' = r(p`i')
            mat pepred[2,`i'] = `temp'[1,1]
        }
        mat pepred[3,1] = `xb'
    }

    if "`e(cmd)'"=="gologit" | "`e(cmd)'"=="mlogit" ///
        | "`e(cmd)'"=="mprobit" | "`e(cmd)'"== "slogit" {
        forval i=1/`ncat' {
            local v : word `i' of `catvals'
            mat pepred[1,`i'] = `v'
            mat `temp' = r(p`i')
            mat pepred[2,`i'] = `temp'[1,1]
            mat pepred[2,`i'] = `temp'[1,1]
            if `i' != `ncat' {
                mat `temp' = r(xb`i')
                mat pepred[3,`i'] = `temp'[1,1]
            }
        }
    }

    if "`e(cmd)'"=="poisson" | "`e(cmd)'"=="nbreg" ///
        | "`e(cmd)'"=="zip"  | "`e(cmd)'"=="zinb" ///
        | `iszt' {
        forval i=1/`ncat' { // add labels to headers
            local im1 = `i' - 1
            mat pepred[1,`i'] = `im1' // numbers 0 to ncat-1
            mat `temp'=r(p`im1')
            mat pepred[2,`i'] = `temp'[1,1]
            if  `iszt' { // if zt model, get pr(y|y>0)
                mat peCpred[1,`i'] = `im1' // numbers 0 to ncat-1
                mat `temp'=r(Cp`im1')
                mat peCpred[2,`i'] = `temp'[1,1]
            }
        }
        mat pepred[3,1] = `xb'
        mat pepred[3,2] = `mu' // overall rate E(y)
        mat pepred[3,3] = `mucount' // mu for count model E(y|~always0)
        mat `temp' = r(stdp)
        mat peinfo[1,8] = `temp'[1,1]
        mat `temp' = r(mu_hi)
        mat peupper[3,1] = `temp'[1,1]
        mat `temp' = r(mu_lo)
        mat pelower[3,1] = `temp'[1,1]
        if "`input'"=="twoeq" {
            mat pepred[3,4] = `prall0'
        }
        if `iszt' { // zt models
            mat `temp' = r(Cmu) // conditional mu
            mat peCpred[3,2] = `temp'[1,1]
        }

    }

    * Information on current model is now located in pepred, peCpred,
    * peinfo, peupper, pelower.

//  if -diff-, add saved and difference to output matrix

    if "`diff'" == "diff" {

        * peinfo
        mat `dif' = peinfo[1,1...] - PRVinfo
        mat peinfo = peinfo[1,1...] \ PRVinfo \ `dif'

        * pepred: row 1-values; 2-prob; 3-misc
        mat `difp' = pepred[2,1...] - PRVprob // dif in prob
        mat `difm' = pepred[3,1...] - PRVmisc // dif in other stats
        *               Current             SavedMode           Difference
        mat pepred = pepred[1..3,1...] \ PRVprob \ PRVmisc \ `difp' \ `difm'

        if  `iszt' { // if zero trucated, also fix conditional matrix
            mat `difp' = pepred[2,1...] - PRVCprob
            mat `difm' = pepred[3,1...] - PRVCmisc
            mat peCpred = ///
                pepred[1..3,1...] \ PRVCprob \ PRVCmisc \ `difp' \ `difm'
        }

    } // end if diff


//  ADD CATEGORY NUMBERS TO FIRST ROW; ADD ROW & COL NAMES

    mat `r1' = pepred[1,1...]
    mat `r2' = peupper[2...,1...]
    mat `r3' = pelower[2...,1...]
    mat peupper = `r1' \ `r2'
    mat pelower = `r1' \ `r3'
    matrix rownames peupper = ///
        1values 2up_pr 3up_misc 4up_sav_pr ///
        5up_sav_misc 6up_dif_pr 7up_dif_misc
    matrix rownames pelower = ///
        1values 2lo_pr 3lo_misc 4lo_sav_pr ///
        5lo_sav_misc 6lo_dif_pr 7lo_dif_misc
    matrix rownames peinfo = Current Saved Cur-Saved
    matrix colnames peinfo = 1nrhs 2numcats 3level 4z_level ///
        5nrhs2 6nocon 7basecat 8stdp 9reps 10repsdone 11maxcount ///
        12blank
    matrix rownames pebase = Current Saved Cur-Saved

//  INFORMATION ON WHETHER CONSTANT IS IN MODEL

    _penocon
    local temp = r(nocon)
    matrix peinfo[1,6] = `temp'

end

exit

version 1.0.0 15Apr2005 fix rate used for zip/zinb (see notes at end)

    15Apr2005 - correct error for zip and zinb (see changes in _pepred, _pecollect, _peciboot
      E(y) was used incorrectly rather than E(y|~always0).
      _pepred[3|5|7, 2] used to be mu defined as rate in count portion of model E(y|not always 0)
      _pepred[3|5|7, 2] now is the overall rate E(y); listed as simply mu.
      _pepred[3|5|7, 3] rate in count portion of model E(y|not always 0); listed as mucount.
    To simplify changes in _peciboot, E(y) is referred to as mu; E(y|~always0) is mucount.

version 2.0.0 2007-03-04 jsl - revised for prvalue repeated dif calls
