*! version 2.5.0 2009-10-28 jsl
*  - stata 11 update for returns from -mlogit-

*   compute marginal effects

capture program drop _pemarg
program define _pemarg, rclass

    * 11Apr2005; 13Jun2005
    if c(stata_version) >= 9 {
        tempname tmpb
        mat `tmpb' = e(b)
        local tmpcut : colnames `tmpb'
        if index("`tmpcut'", "_cut1") != 0 {
            local cut "_"
        }
        else {
            local cut "/"
        }
    }
    else {
        local cut "_"
    }
    
    syntax [, caller(real 5.0)] // 1.7.0 stata version

    version 6.0
    tempname b x xb sxb prob marg tmp bxb bxbm1 difpdf tmp2
    tempname b x o xo xb sxb prob marg tmp bxb bxbm1 difpdf tmp2 bi alpha
    tempname sumxb sp PredVal PredPr sump
    tempname pdiag sumpb o

    if "`e(cmd)'"=="cloglog"  { local hasmarg = "not yet" }
    if "`e(cmd)'"=="cnreg"    { local hasmarg = "not applicable" }
    if "`e(cmd)'"=="fit"      { local hasmarg = "not applicable" }
    if "`e(cmd)'"=="gologit"  { local hasmarg = "not yet" }
    if "`e(cmd)'"=="intreg"   { local hasmarg = "not applicable" }
    if "`e(cmd)'"=="logistic" { local hasmarg = "yes" }
    if "`e(cmd)'"=="logit"    { local hasmarg = "yes" }
    if "`e(cmd)'"=="mlogit"   { local hasmarg = "yes" }
    if "`e(cmd)'"=="nbreg"    { local hasmarg = "yes" }
    if "`e(cmd)'"=="ologit"   { local hasmarg = "yes" }
    if "`e(cmd)'"=="oprobit"  { local hasmarg = "yes" }
    if "`e(cmd)'"=="poisson"  { local hasmarg = "yes" }
    if "`e(cmd)'"=="probit"   { local hasmarg = "yes" }
    if "`e(cmd)'"=="regress"  { local hasmarg = "not applicable" }
    if "`e(cmd)'"=="tobit"    { local hasmarg = "not applicable" }
    if "`e(cmd)'"=="zinb"     { local hasmarg = "not yet" }
    if "`e(cmd)'"=="zip"      { local hasmarg = "not yet" }
    return local hasmarg `hasmarg'
    if "`hasmarg'"!="yes" { exit }

    /* 1.6.4
        matrix `b' = e(b)
        if "`e(cmd)'"=="mlogit" {
            version 5.0
            matrix `b' = get(_b)
            version 6.0
        }
    */
    
    tempname eV
    * 0.2.5 - get b and v for all estimation commands
    mat `b' = e(b)
    * drop local nbeta = colsof(`b')
    if "`e(cmd)'"=="mlogit" {
        version 5.0
        matrix `b' = get(_b)
        version 6.0
    }
    mat `eV' = e(V)
    * 2009-10-28 get b and V under Stata 11
    if "`e(cmd)'"=="mlogit" { // if mlogit, special treatment
         nobreak {
            _get_mlogit_bv `b' `eV'
         }
     }
         
    if "`e(cmd)'"=="nbreg" {
        local nb = colsof(`b') - 1 /* -1 for alpha */
        matrix `b' = `b'[1,1..`nb']
    }
    matrix `x' = PE_base

    if "`e(cmd)'"=="logit"  | "`e(cmd)'"=="probit" | /*
    */ "`e(cmd)'"=="logistic" | /*
    */"`e(cmd)'"=="poisson" | "`e(cmd)'"=="nbreg"  {
        matrix `x' = `x',J(1,1,1)
        matrix `xb' = `x' * `b''
        local nb = colsof(`b') - 1
        matrix `b' = `b'[1,1..`nb'] /* get rid of _con */
        scalar `sxb' = `xb'[1,1]
        if "`e(cmd)'"=="logit" | "`e(cmd)'"=="logistic" {
            scalar `prob' = exp(`sxb')/(1+exp(`sxb'))
            scalar `tmp' = `prob'*(1-`prob')
            matrix `marg' = `tmp'*`b'
        }
        else if "`e(cmd)'"=="probit" {
            scalar `prob' = normprob(`sxb')
            scalar `tmp'  = exp(-`sxb'*`sxb'/2)/sqrt(2*_pi)
            matrix `marg' = `tmp'*`b'
        }
        else if "`e(cmd)'"=="poisson" | "`e(cmd)'"=="nbreg" {
            scalar `prob' = exp(`sxb')
            matrix `marg' = `prob'*`b'
            scalar `prob' = -exp(`sxb') /* to undo change below */
        }
        matrix `prob' = -1 * `marg'
        matrix `marg' = `prob' \ `marg'
    }

    if "`e(cmd)'"=="oprobit" | "`e(cmd)'"=="ologit" {
        local ncats = e(k_cat)
        * xb without intercept
        local nb = colsof(`b') - `ncats' + 1
        matrix `b' = `b'[1,1..`nb'] /* get rid of _con's */
        matrix `xb' = `x' * `b''
        scalar `sxb' = `xb'[1,1]
        matrix `difpdf' = J(1,`ncats',1)
        matrix `marg' = J(`nb',`ncats',1)
        * compute probabilities
        if "`e(cmd)'"=="oprobit" {
            matrix `prob' = J(1,`ncats',1)
            scalar `bxb' = _b[`cut'cut1]-`sxb'
            matrix `prob'[1,1] = normprob(`bxb') /* prob for cat 1 */
            matrix `difpdf'[1,1] = exp(-`bxb'*`bxb'/2)/sqrt(2*_pi)
            local i 2
            while `i'<`ncats' {
                local im1 = `i' - 1
                scalar `bxb' = _b[`cut'cut`i'] - `sxb'
                scalar `bxbm1' = _b[`cut'cut`im1'] - `sxb'
                matrix `prob'[1,`i'] = normprob(`bxb') - normprob(`bxbm1')
                matrix `difpdf'[1,`i'] = exp(-`bxb'*`bxb'/2)/sqrt(2*_pi) /*
                */ - exp(-`bxbm1'*`bxbm1'/2)/sqrt(2*_pi)
                local i = `i' + 1
            }
            local im1 = `i' - 1
            scalar `bxb' = `sxb'-_b[`cut'cut`im1']
            matrix `prob'[1,`ncats'] = normprob(`bxb')
            * 12/6/00
            matrix `difpdf'[1,`ncats'] = -1*exp(-`bxb'*`bxb'/2)/sqrt(2*_pi)
        }
        if "`e(cmd)'"=="ologit" {
            matrix `prob' = J(1,`ncats',1)
            scalar `tmp' = 1/(1+exp(`sxb'-_b[`cut'cut1]))
            matrix `prob'[1,1] = `tmp'
            matrix `difpdf'[1,1] = `tmp'*(1-`tmp')
            local i 2
            while `i'<`ncats' {
                local im1=`i'-1
                scalar `tmp' = 1/(1+exp(`sxb'-_b[`cut'cut`i']))
                scalar `tmp2' = 1/(1+exp(`sxb'-_b[`cut'cut`im1']))
                matrix `prob'[1,`i'] = `tmp' - `tmp2'
                matrix `difpdf'[1,`i'] = (`tmp'*(1-`tmp')) - (`tmp2'*(1-`tmp2'))
                local i=`i'+1
            }
            local im1 = `i'-1
            scalar `tmp' = 1/(1+exp(`sxb'-_b[`cut'cut`im1']))
            matrix `prob'[1,`ncats'] = 1-`tmp'
            matrix `difpdf'[1,`i'] = - (`tmp'*(1-`tmp'))
        }
        local i 1
        while `i'<=`nb' {
            local j 1
            while `j'<=`ncats' {
                matrix `marg'[`i',`j'] = -1 * `difpdf'[1,`j'] * `b'[1,`i']
                local j = `j' + 1
            }
            local i = `i' + 1
        }
    }

    if "`e(cmd)'"=="mlogit" {
        matrix `x'  = PE_base
        matrix `xo' = `x',J(1,1,1)
        matrix `PredVal'  = J(1,1,1)
        matrix colnames `PredVal' = xb
        /* 1.6.4 - does not work with Stat 11
        version 5.0
        matrix `b' = get(_b)
        version 6.0
        */
        * 2007-06-29 stata 10
        if c(stata_version) < 10 {
            local ncats = e(k_cat)
        }
        else {
            local ncats = e(k_out)
        }
        matrix `prob' = J(1,`ncats',-1)
        matrix `xb' = `b'*`xo'' /* one row for each set of b's */
        matrix `PredVal' = `xb'
        scalar `sumxb' = 1
        local i = 1
        while `i' < `ncats' {
            scalar `sxb' = exp(`xb'[`i',1])
            scalar `sumxb' = `sumxb' + `sxb' /* sum of exp(xb) */
            matrix `prob'[1,`i'] = `sxb'
            local i = `i' + 1
        }
        scalar `sumxb' = 1/`sumxb'
        matrix `prob'[1,`ncats'] = 1
        matrix `prob' = `sumxb'*`prob'
        matrix `PredPr' = `prob'
        matrix `pdiag' = `PredPr'
        matrix `pdiag' = diag(`pdiag')
        * 2007-06-29 stata 10
        if c(stata_version) < 10 {
            local ncats = e(k_cat)
        }
        else {
            local ncats = e(k_out)
        }
        local nb = colsof(`b')
        matrix `b' = `b' \ J(1,`nb',0) /* add 0's for last outcome */
        matrix `marg' = `pdiag' * (`b' - (J(`ncats',`ncats',1)*`pdiag'*`b'))
        local nb = colsof(`b') - 1
        matrix `marg' = `marg'[.,1..`nb']
        matrix `marg' = `marg''
    }
    return matrix marginal `marg'

end
exit

* version 1.6.0 3/29/01
* version 1.6.1 11Apr2005 fix _cut for stata 9
* version 1.6.2 13Apr2005
* version 1.6.3 13Jun2005 - fix ologit version 8/9 bug with _cut
* version 1.6.4 2007-06-29 stata 10
* version 1.7.0 2009-09-19 jsl
*   - fix for e(b) for mlogit in stata 11
