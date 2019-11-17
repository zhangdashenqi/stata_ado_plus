*! version 1.6.0 3/29/01

capture program drop brant
program define brant, rclass
version 6
    tempvar touse
    tempname bout d pvals ivchi ivout step1 step2 ologit
    tempname XpWmmX iXpWmmX XpWmlX XpWllX iXpWllX DB DBp iDvBDp
    syntax [, detail]

    if "`e(cmd)'"!="ologit" {
        di in r "brant can only be used after ologit"
        exit
    }

    *to make output stata 6 or stata 7 compatible
    cap version 7
        if _rc!=0 {
            local vers7 "no"
            local smcl ""
            local dash "-"
            local vline "|"
            local plussgn "+"
            local topt "-"
            local bottomt "-"
        }
        else { local vers7 "yes"
            local smcl "in smcl "
            local dash "{c -}"
            local vline "{c |}"
            local plussgn "{c +}"
            local topt "{c TT}"
            local bottomt "{c BT}"
        }
    version 6.0

    local ocmd "`e(cmd)'"
    if "`ocmd'"=="ologit"  { local bcmd "logit" }
    local depvar "`e(depvar)'"
    gen `touse' = e(sample)
    local wtis ""
    if "`e(wtype)'"!="" {
        di in r "-brant- does not work with ologit models with weights"
        error 999
    }
    _perhs
    local rhsnms "`r(rhsnms)'"
    local nrhs "`r(nrhs)'"
    _pecats
    local numcats = `r(numcats)'
    local catvals "`r(catvals)'"
    local catnms "`r(catnms)'"
    local catnms8 "`r(catnms8)'"
    estimates hold `ologit'

*** estimate series of binary logits
    local i = 1
    while `i' <= `numcats'-1 {
        local splitat : word `i' of `catvals'
        tempvar dummy
        quietly gen `dummy' = 0 if `depvar' <= `splitat' & `touse'==1
        quietly replace `dummy' = 1 if `depvar' > `splitat' & `touse'==1
        quietly `bcmd' `dummy' `rhsnms' `wtis' if `touse' == 1
        _perhs
        local binnrhs = "`r(nrhs)'"
        if `nrhs' != `binnrhs' {
            di in r "not all independent variables can be retained in all binary logits"
            di in r "brant test cannot be computed"
            exit 999
        }
        tempvar prob`i'
        quietly predict `prob`i''
        tempname b`i' V`i' bc`i'
        mat `b`i'' = e(b)
        mat `b`i'' = `b`i''[1, 1..`nrhs']
        mat `V`i'' = e(V)
        mat `V`i'' = `V`i''[1..`nrhs', 1..`nrhs']
        mat `bc`i'' = e(b) /* with constant--for detail output only */
        mat `bc`i'' = `bc`i'''
        local outname "y>`splitat'"
        local outname = substr("`outname'", 1, 8)
        mat colnames `bc`i'' = "`outname'"
        mat `bout' = nullmat(`bout'), `bc`i''
        local i = `i' + 1
    }

*** make variables for W(ml) matrices
    local i = 1
    while `i' <= `numcats'-1 {
        local i2 = `i'
        while `i2' <= `numcats'- 1 {
            tempvar w`i'_`i2'
            quietly gen `w`i'_`i2'' = `prob`i2'' - (`prob`i''*`prob`i2'')
            local i2 = `i2' + 1
       }
        local i = `i' + 1
    }

*** calculate variance Bm, Bl
    local i = 1
    while `i' <= `numcats'-1 {
        local i2 = `i'
        while `i2' <= `numcats'- 1 {
            quietly {
                * inverse(X'W(mm)X)
                matrix accum `XpWmmX' = `rhsnms' [iw=`w`i'_`i''] if `touse'==1
                matrix `iXpWmmX' = inv(`XpWmmX')
                * X'W(ml)X
                matrix accum `XpWmlX' = `rhsnms' [iw=`w`i'_`i2''] if `touse'==1
                * inverse(X'W(ll)X)
                matrix accum `XpWllX' = `rhsnms' [iw=`w`i2'_`i2''] if `touse'==1
                matrix `iXpWllX' = inv(`XpWllX')
                * product of three matrices
                matrix `step1' = `iXpWmmX' * `XpWmlX'
                tempname vb`i'_`i2'
                matrix `vb`i'_`i2'' = `step1' * `iXpWllX'
            }
            mat `vb`i'_`i2''= `vb`i'_`i2''[1..`nrhs',1..`nrhs']
            local i2 = `i2' + 1
       }
        local i = `i' + 1
    }

    * define var(B) matrix
    local i = 1
    while `i' <= `numcats'-1 {
        tempname row`i'
        local i2 = 1
        while `i2' <= `numcats'- 1 {
            quietly {
                if `i'==`i2' { mat `row`i'' = nullmat(`row`i''), `V`i'' }
                if `i'<`i2' { mat `row`i'' = nullmat(`row`i'') , `vb`i'_`i2'' }
                if `i'>`i2' { mat `row`i'' = nullmat(`row`i'') , `vb`i2'_`i''' }
            }
            local i2 = `i2' + 1
       }
        local i = `i' + 1
    }

    * combine matrices
    tempname varb
    local i = 1
    while `i' <= `numcats'-1 {
        mat `varb' = nullmat(`varb') \ `row`i''
        local i = `i' + 1
    }
    * make beta vector
    tempname bstar
    local i = 1
    while `i' <= `numcats'-1 {
        mat `bstar' = nullmat(`bstar') , `b`i''
        local i = `i' + 1
    }
    mat `bstar' = `bstar''

    * create design matrix for wald test; make I, -I, and 0 matrices
    tempname id negid zero
    local dim = `nrhs'
    mat `id' = I(`dim')
    mat rownames `id' = `rhsnms'
    mat colnames `id' = `rhsnms'
    mat `negid' = -1*`id'
    mat rownames `negid' = `rhsnms'
    mat colnames `negid' = `rhsnms'
    mat `zero' = J(`dim', `dim', 0)
    mat rownames `zero' = `rhsnms'
    mat colnames `zero' = `rhsnms'
    * dummy matrix
    local i = 1
    while `i' <= `numcats'-2 {
        tempname drow`i'
        local i2 = 1
        while `i2' <= `numcats'- 1 {
            quietly {
                tempname feed
                if `i2'==1 { mat `feed' = `id' }
                else if `i2'-`i'==1 { mat `feed' = `negid' }
                else { mat `feed' = `zero' }
                mat `drow`i'' = nullmat(`drow`i'') , `feed'
            }
            local i2 = `i2' + 1
       }
        local i = `i' + 1
    }

    * combine matrices
    local i = 1
    while `i' <= `numcats'-2 {
        mat `d' = nullmat(`d') \ `drow`i''
        local i = `i' + 1
    }

    * terms of wald test
    mat `DB' = `d' * `bstar'
    mat `DBp' = `DB''
    mat `step1' = `d'*`varb'
    mat `step2' = `step1' * (`d'')
    mat `iDvBDp' = inv(`step2')

*** calculate wald stat
    tempname step1 wald waldout pout dfout
    mat `step1' = `DBp' * `iDvBDp'
    mat `wald' = `step1' * `DB'
    sca `waldout' = `wald'[1,1]
    sca `dfout' = `nrhs'*(`numcats'-2)
    sca `pout' = chiprob(`dfout', `waldout')
    tempname dtemp vbtemp bstemp
    local i = 1
    while `i' <= `nrhs' {
        tempname d`i' vb`i' bstar`i'
        local i2 = 1
            while `i2' <= `numcats'-1 {
                local row = ((`nrhs')*(`i2'-1)) + (`i')
                tempname drow vbrow
                local i3 = 1
                while `i3' <= `numcats'-1 {
                    local column = ((`nrhs')*(`i3'-1)) + (`i')
                    if (`i2'<`numcats'-1) {
                        mat `dtemp' = `d'[`row',`column']
                        mat `drow' = nullmat(`drow') , `dtemp'
                    }
                    mat `vbtemp' = `varb'[`row',`column']
                    mat `vbrow' = nullmat(`vbrow') , `vbtemp'
                local i3 = `i3' + 1
            }
            if (`i2'<`numcats'-1) { mat `d`i'' = nullmat(`d`i'') \ `drow' }
            mat `vb`i'' = nullmat(`vb`i'') \ `vbrow'
            mat `bstemp' = `bstar'[`row', 1]
            mat `bstar`i'' = nullmat(`bstar`i'') \ `bstemp'
            local i2 = `i2' + 1
        }
        local i = `i' + 1
    }

*** wald test for each independent variable
    tempname waldiv
    local i = 1
    while `i' <= `nrhs' {
        tempname DB DBp iDvBDp step1 step2
        mat `DB' = `d`i'' * `bstar`i''
        mat `DBp' = `DB''
        mat `step1' = `d`i''*`vb`i''
        mat `step2' = `step1' * (`d`i''')
        mat `iDvBDp' = inv(`step2')
        tempname step1 wald`i'
        mat `step1' = `DBp' * `iDvBDp'
        mat `wald`i'' = `step1' * `DB'
        mat `waldiv' = nullmat(`waldiv') \ `wald`i''
        local i = `i' + 1
    }

    if "`detail'"!="" {
        di _n in gr "Estimated coefficients from j-1 binary regressions"
        mat list `bout', noheader
    }

    di _n in g "Brant Test of Parallel Regression Assumption"
    di _n `smcl' in g "    Variable `vline'      chi2   p>chi2    df"
    di  `smcl' _dup(13) in g "`dash'" "`plussgn'" _dup(26) in g "`dash'"
    di  `smcl' in g "         All `vline'" in y /*
    */ %10.2f `waldout' %9.3f `pout' %6.0f `dfout'
    di  `smcl' _dup(13) in g "`dash'" "`plussgn'" _dup(26) in g "`dash'"
    * calculate p for individual wald tests
    mat `pvals' = J(`nrhs', 1, 0)
    local i = 1
    local df = `numcats'-2
    while `i' <= `nrhs' {
        sca `ivchi' = `waldiv'[`i',1]
        if `ivchi' >= 0 {
            mat `pvals'[`i',1] = chiprob(`df',`ivchi')
        }
        if `ivchi' < 0 {
            mat `pvals'[`i',1] = -999
        }
        local vnm : word `i' of `rhsnms'

        *added for stata 7 compatibility
        local printnm "`vnm'"
        if "`vers7'"=="yes" { local printnm = abbrev("`printnm'", 12) }

        di `smcl' in g %12s "`printnm'" _col(14) "`vline'" in y /*
        */ %10.2f `ivchi' %9.3f `pvals'[`i',1] %6.0f `df'
        local i = `i' + 1
    }
    di  `smcl' _dup(13) in g "`dash'" "`bottomt'" _dup(26) in g "`dash'"
    di _n in g /*
        */ "A significant test statistic provides evidence that the parallel"
    di in g "regression assumption has been violated."
    mat `ivout' = `waldiv', `pvals'
    mat rownames `ivout' = `rhsnms'
    mat colnames `ivout' = chi2 p>chi2
    estimates unhold `ologit'
    return scalar chi2 = `waldout'
    return scalar p = `pout'
    return scalar df = `dfout'
    return matrix ivtests `ivout'
end
