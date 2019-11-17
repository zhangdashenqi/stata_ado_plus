*! version 2.5.0 2009-10-28 jsl
*  - stata 11 update for returns from -mlogit-

//  delta method for prvalue

capture program drop _pecidelta
program define _pecidelta, rclass

    version 8
    * _G==gradient matrix; _V=var/cov matrix; _up=upper bound; _lo=lower
    tempname x_base x_base1 x_baseneg xb b b_j b_nocuts designmat cur_eq_sav
    tempname pdf z G V temp yval eV v
    tempname mu mu_G mu_V mudif mudif_V
    tempname pr_cur pr_G pr_V pr_se pr_lo pr_up pr_sav
    tempname prdif prdif_se prdif_lo prdif_up prdif_V

    /* Matrix definitions:

        pr_cur   : predicted probabilities
        pr_lo    : lower bound for pred prob
        pr_up    : upper bound for pred prob
        pr_G     : gradient matrix for pred prob
                 :   [dp/db'*e(V)*dp/db]
        pr_V     : variance (only) matrix for pred prob
        pr_se    : standards error for pred prob

        prdif    : discrete change for pred prob
        prdif_lo : lower bound for discrete change
        prdif_up : upper bound for discrete change
        prdif_V  : covariance matrix for discrete change
                 : [d(p2-p1)/db'*e(V)*d(p2-p1)/db]
        prdif_se : standards error for discrete change

        yval     : y values

        G   = [dF(XB)/dB]'
            = [dF(XB)/dXB]*[dXB/dB]' = f(XB)*X
        V   = Var(F(XB))
            = [dF(XB)/dB]' V(B) [dF(XB)/dB]
    */

//  DECODE SYNTAX

    * syntax [, Save Diff] // 0.2.3
    * 0.2.5 - caller indicates version of stata calling _pecidelta;
    * needed since other commands change versions.

    syntax [, Save Diff caller(real 5.0)]

// GET INFORMATION STORED IN GLOBALS

    loc io $petype
    loc cmd : word 1 of $petype  // model command
    loc input : word 2 of $petype  // typical or twoeqn
    loc output : word 3 of $petype  // output type

    loc nrhs = peinfo[1,1]  // # of rhs
    loc nrhsp1 = peinfo[1,1] + 1  // adding 1 for constant
    scalar `z' = peinfo[1,4]
    loc numcats = peinfo[1,2]
    loc numcatsm1 = peinfo[1,2] - 1
    loc max_count = `numcats' - 1  // count model max counts

    * mat `b' = e(b) // 0.2.2
    * 0.2.5 get b and v for all estimation commands
    mat `b' = e(b)
    local nbeta = colsof(`b')
    mat `eV' = e(V)

    * 0.2.6 get_mlogit_bv to get b and V under Stata 11
    if "`e(cmd)'"=="mlogit" { // if mlogit, special treatment
         nobreak {
            _get_mlogit_bvecv `b' `eV'
         }
     }

    * base values
    mat `x_base'= pebase[1, 1...] // base values for predictions
    mat `x_base1' = `x_base', 1 // adding 1 to end for constant

// GET PREDICTED PROBABILITIES

    if "`output'"=="count" | "`output'"=="binary" {
        forval i = 0/`numcats' {
            tempname p`i'
            scalar `p`i'' = pepred[2,`i'+1]
        }
    }
    else {
        forval i = 1/`numcats' {
            tempname p`i'
            scalar `p`i'' = pepred[2,`i']
        }
    }
    mat `pr_cur'= pepred[2,1...]'

//  BINARY MODELS - predicted probability

    if "`output'"=="binary" {

        scalar `xb' = pepred[3,1]

        // dF(XB)/dXB = pdf
        if "`e(cmd)'"=="cloglog" {
            scalar `pdf' = (`p1'-1) * exp(`xb')
        }
        if "`e(cmd)'"=="logit" | "`e(cmd)'"=="logistic" {
            scalar `pdf' = `p1' * (1-`p1')
        }
        if "`e(cmd)'"=="probit"{
            scalar `pdf' = normden(`xb')
        }

        // dF(XB)/dB = f(XB)*X
        mat `G' = `pdf' * `x_base1'
        // noncon fix 2004-12-22
        mat `G' = `G'[1,1..`nbeta']
        mat `pr_G' = `G' \ `G'
        // Var(F(XB)) = dF(XB)/dB' V(B) dF(XB)/dB
        * 0.2.2 mat `V' = `G' * e(V) * `G''
        mat `V' = `G' * `eV' * `G'' // 0.2.5
        // Since V(p1)=V(p0):
        mat `pr_V' = `V'[1,1] \ `V'[1,1]
    }

//  ORDERED MODELS

    if "`output'"=="ordered" {

        * Ordered logit/probit involves computing:
        *
        *   Pr(y=m) = F(t_m - xb) - F(t_m-1 * xb)
        *
        * The e(b) matrix is a vector of b's associated with the
        * x's and then the tau's. To compute t_m - xb by vector
        * multiplicaton of e(b), we need to compute vectors like:
        *
        *   x_tau1 = -x1 -x2 -x3 1 0 0 0
        *   x_tau2 = -x1 -x2 -x3 0 1 0 0
        *   x_tau3 = -x1 -x2 -x3 0 0 1 0
        *   x_tau4 = -x1 -x2 -x3 0 0 0 1
        *
        * Then x_taum*e(b) = t_m - xb

        tempname I tau_xb tau_xbm1 pdf1 pdflast
        mat `I' = I(`numcatsm1')

        * loop through categories
        forval i = 1/`numcatsm1' {
            tempname x_tau`i'
            mat `x_tau`i'' = -(`x_base'), `I'[`i',1...]
        }

        * get b's with tau's at end
        mat `b' = e(b)
        * compute tau_m - xb
        mat `tau_xb' = `x_tau1'*`b''
        scalar `tau_xb' = `tau_xb'[1,1]
        * for category 1: d cdf/d xb = pdf
        if "`e(cmd)'"=="ologit" {
            lgtpdf 0 `tau_xb'
            scalar `pdf1' = r(pdf)
        }
        if "`e(cmd)'"=="oprobit" {
            scalar `pdf1' = normden(`tau_xb')
        }
        * for the first outcome
        mat `G' = `pdf1' * `x_tau1'
        mat `pr_G' = `G'
        * 0.2.2 mat `V' = `G' * e(V) * (`G')'
        mat `V' = `G' * `eV' * (`G')' // 0.2.5
        mat `pr_V' = `V'[1,1]

        * cateories 2 through next to last add to matrices for category 1
        forval i = 2/`numcatsm1' {

            local im1 = `i' - 1 // prior cutpoint
            tempname pdf`i'
            mat `tau_xb' = `x_tau`i''*`b''
            scalar `tau_xb' = `tau_xb'[1,1]
            mat `tau_xbm1' = `x_tau`im1''*`b''
            scalar `tau_xbm1' = `tau_xbm1'[1,1]
            if "`e(cmd)'"=="ologit" {
                * cutpoint i
                lgtpdf 0 `tau_xb'
                scalar `pdf`i'' = r(pdf)
                * cutpoint i-1
                lgtpdf 0 `tau_xbm1'
                scalar `pdf`im1'' = r(pdf)
            }
            if "`e(cmd)'"=="oprobit" {
                scalar `pdf`i'' = normden(`tau_xb')
                scalar `pdf`im1'' = normden(`tau_xb')
            }

            mat `G' = (`pdf`i'')*(`x_tau`i'') ///
                        - (`pdf`im1'') * (`x_tau`im1'')
            mat `pr_G' = `pr_G' \ `G'
            * 0.2.2     mat `V' = `G' * e(V) * (`G')'
            mat `V' = `G' * `eV' * (`G')' // 0.2.5
            mat `pr_V' = `pr_V' \ `V'[1,1]

        } // if given category

        * last category
        local im1 = `numcats' - 1
        mat `tau_xb' = `x_tau`im1''*`b''
        scalar `tau_xb' = `tau_xb'[1,1]
        if "`e(cmd)'"=="ologit" {
            lgtpdf 0 `tau_xb'
            scalar `pdflast' = - r(pdf)
        }
        if "`e(cmd)'"=="oprobit" {
            scalar `pdflast' = -normden(`tau_xb')
        }
        mat `G' = `pdflast' * (`x_tau`im1'')
        mat `pr_G' = `pr_G' \ `G'
        * 0.2.2 mat `V' = `G' * e(V) * (`G')'
        mat `V' = `G' * `eV' * (`G')' // 0.2.5
        mat `pr_V' = `pr_V' \ `V'[1,1]

    } // ordered

//  GOLOGIT

    if "`e(cmd)'"=="gologit" {

        tempname nextrow pdfmat fmxb_mx

        forval j = 1/`numcatsm1' {

            * select betas for outcome j
            local start = (`j'-1) * `nrhsp1' + 1
            local end = `start' + `nrhs' // including constant
            mat `b_j' = `b'[1...,`start'..`end']

            * pdf at -xb
            mat `xb' = `x_base1'*(`b_j')'
            lgtpdf 0 -`xb'[1,1]
            scalar `pdf' = r(pdf)

            * collect column vector with pdfs for each outcome
            mat `pdfmat' = nullmat(`pdfmat') \ `pdf'
        }

        * dF(-xb)/dB = dFxbdB contains vec of:
        *
        *  -x1*f(xb1) ... -x1*f(xbJ-1)
        *  :::
        *  -xK*f(xb1) ... -xK*f(xbJ-1)
        *  -1 *f(xb1) ... -1 *f(xbJ-1)

        mat `fmxb_mx' = vec((-1 * `pdfmat' * `x_base1')')

        * designmat: let J = (1 1 ... 1) for # rhs + 1
        *            let M = -J
        *            let 0 = 0 matrix of same size
        *
        * designmat = J 0 0 0 0 ... 0 0 ==> -xf(-xb_1)
        *             M J 0 0 0 ... 0 0 ==> xf(-xb_1)-xf(-xb_2)
        *             0 M J 0 0 ... 0 0
        *             : : : : :::::::::
        *             0 0 0 0 0 ... 0 M==> xf(-xb_ncats)-xf(-xb_2)

        tempname J M
        mat `J' = J(1,`nrhsp1',1)
        mat `M' = J(1,`nrhsp1',-1)

        * outcome 1
        mat `designmat' = J(1,`nrhsp1',1), J(1,`nbeta'-`nrhsp1',0)

        * outcomes 2 - J-1
        forval i = 2/`numcatsm1' {
            mat `nextrow' = J(1,`nbeta',0)
            local startneg = (`i'-2) * `nrhsp1' + 1 // start -1
            local startpos = (`i'-1) * `nrhsp1' + 1 // start 1
            mat `nextrow'[1,`startneg'] = `M'
            mat `nextrow'[1,`startpos'] = `J'
            mat `designmat' = nullmat(`designmat') \ `nextrow'
        }

        * outcome J
        mat `nextrow' = J(1,`nbeta'-`nrhsp1',0), J(1,`nrhsp1',-1)
        mat `designmat' = nullmat(`designmat') \ `nextrow'
        * compute gradient and variance
        mat `pr_G' = `designmat' * diag(`fmxb_mx')
        * 0.2.2 mat `pr_V' = ( vecdiag(`pr_G' * e(V) * (`pr_G')') )'
        mat `pr_V' = ( vecdiag(`pr_G' * `eV' * (`pr_G')') )' // 0.2.5
    }

//  NOMINAL

    if "`e(cmd)'"=="mlogit" {
        local nbeta = colsof(`b')
        local nrhspluscon = `nrhsp1' // if constant
        local iscon "1"
        if `nrhs'*`numcatsm1'==`nbeta' { // if true, noconstant
            local nrhspluscon = `nrhsp1' - 1 // if noconstant
            local iscon ""
        }

        tempname  pj_xk_mat pj_xk_vec
        forval i = 1/`numcats' {
            tempname p`i'fst p`i'snd Var`i'
        }

        * X = base values with 1 for contant
        * 0 = 0 row vector of same size.
        * Create:
        *           X 0 0 0 ...
        *           0 X 0 0 ...
        *           0 0 X 0 ...
        mat `designmat' = J(`numcatsm1',`nbeta',0)
        forval i = 1/`numcatsm1' {
            local st = (`i'-1) * `nrhspluscon'
            forval j = 1/`nrhspluscon' {
                local k = `st' + `j'
                mat `designmat'[`i',`k'] = `x_base`iscon''[1,`j']
            }
        }
        * vector p1x1 p1x2 p1x3...p2x1 p2x2 p2x3...p3x1 p3x2 p3x3...
        forval i = 1/`numcatsm1' {
            mat `pj_xk_vec' = nullmat(`pj_xk_vec'),(`x_base`iscon'' * `p`i'')
        }
        * compute the variances
        forval i = 1/`numcats' {
            if "`i'"<"`numcats'" {
                mat `G' = (`p`i'') * (`designmat'[`i',1..`nbeta']) ///
                        - (`p`i'') * (`pj_xk_vec')
                mat `pr_G' = nullmat(`pr_G') \ `G'
            }
            if "`i'"=="`numcats'" {
                mat `G' = -(`p`i'') * (`pj_xk_vec')
                mat `pr_G' = `pr_G' \ `G'
            }

            // noncon fix 2004-12-22
            mat `G' = `G'[1,1..`nbeta']
            * 0.2.2     mat `V' = `G' * e(V) * (`G')'
            mat `V' = `G' * `eV' * (`G')' // 0.2.5
            mat `pr_V' = nullmat(`pr_V') \ `V'[1,1]
        }
    }

//  NBREG AND POISSON

    if "`output'"=="count" & "`input'"=="typical" {

        // POISSON

        if "`e(cmd)'"=="poisson" {
            scalar `mu' = pepred[3,2]
            mat `mu_G' = `mu'*`x_base1' // d mu/dB
            mat `mu_G' = `mu_G'[1,1..`nbeta'] // noncon fix 2004-12-22
            forval i = 0/`max_count' {
                matrix `G' = `x_base1' * ///
                     ( `i' * `mu'^`i' - `mu'^(`i'+1) ) /  ///
                     ( exp(lngamma(`i'+1)) * exp(`mu') )
                mat `G' = `G'[1,1..`nbeta'] // noncon fix 2004-12-22
                mat `pr_G' = nullmat(`pr_G') \ `G'
                * 0.2.2         mat `V' = `G' * e(V) * (`G')'
                mat `V' = `G' * `eV' * (`G')' // 0.2.5
                mat `pr_V' = nullmat(`pr_V') \ `V'[1,1]
                * 0.2.2                mat `eV' = e(V)
            }
        }

        // NBREG

        if "`e(cmd)'"=="nbreg" {

            tempname alpha alphainv inv1alpmu
            tempname scorexb gradb scorelnalpha gradlnalpha
            scalar `mu' = pepred[3,2]
            mat `mu_G' = (`mu' * `x_base1'), 0

            // noncon fix 2005-01-08
            * strip off the alpha
            local nbeta = `nbeta' - 1 // drop alpha
            * strip off the alpha
            mat `mu_G' = `mu_G'[1,1..`nbeta']

            scalar `alpha' = e(alpha)
            scalar `inv1alpmu' = 1 / (1+`alpha'*`mu')
            scalar `alphainv' = 1 / `alpha'

            forval y = 0/`max_count' { // loop through counts

                scalar `scorexb' = `inv1alpmu' * (`y'-`mu')
                mat `gradb' = (`scorexb' * `x_base1') * `p`y''
                scalar `scorelnalpha' = `alphainv' * ///
                        (   digamma(`alphainv') ///
                          - digamma(`y' + `alphainv') ///
                          - ln(`inv1alpmu') ///
                        ) ///
                        + `inv1alpmu'*(`y'-`mu')
                scalar `gradlnalpha' = `scorelnalpha' * `p`y''
                mat `G' = `gradb', `gradlnalpha'
                mat `G' = `G'[1,1..`nbeta'] // noncon fix 2004-12-22
                mat `pr_G' = nullmat(`pr_G') \ `G'

                // noncon fix 2005-01-08
                *drop mat `V' = `G' * e(V) * (`G')'
                * 0.2.2                mat `eV' = e(V)
                mat `eV' = `eV'[1..`nbeta',1..`nbeta']
                mat `V' = `G' * `eV' * (`G')'
                mat `pr_V' = nullmat(`pr_V') \ `V'[1,1]

            } // loop through counts

        }

        // BOTH MODELS

        // noncon fix 2005-01-08
        mat `mu_V' = `mu_G' * `eV' * (`mu_G')' // variance for expected rate

     } // negbin and poisson

//  GET CATEGORY VALUES FOR PROBABILITIES - used to label matrices

    forval i = 1/`numcats' {
        local category = pepred[1,`i'] // value of category
        * used for column names later
        local catnames "`catnames' Cat=`category'"
    }

//  VARIANCE FOR DISCRETE CHANGE

    if "`diff'"=="diff" {

        /* 0.2.2
        if "`e(cmd)'"!="nbreg" {
            mat `eV' = e(V)
        } */

        mat def `pr_sav' = pepred[4,1...]'
        mat `prdif' = `pr_cur' - `pr_sav'

        * is there no change in x? 0 if no difference.
        scalar `cur_eq_sav' = mreldif(`pr_sav',`pr_cur')

        * variance for change in prob
        mat `prdif_V' = pegrad_pr * `eV' * pegrad_pr' ///
                + `pr_G' * `eV' * (`pr_G')' ///
                - pegrad_pr * `eV' * (`pr_G')' ///
                - `pr_G' * `eV' * pegrad_pr'
        mat `prdif_V' = (vecdiag(`prdif_V'))'

        if "`e(cmd)'"=="poisson" | "`e(cmd)'"=="nbreg" {
            mat `mudif' = `mu' - pepred[5,2] // minus save mu
            * variance for change in mu
            mat `mudif_V' = pegrad_mu * `eV' * pegrad_mu' ///
                    + `mu_G' * `eV' * (`mu_G')' ///
                    - pegrad_mu * `eV' * (`mu_G')' ///
                    - `mu_G' * `eV' * pegrad_mu'
        }
    }

//  COMPUTE UPPER AND LOWER BOUNDS

    mat rownames `pr_V' = `catnames'
    mat rownames `pr_G' = `catnames'

    * std errors = square root of variances
    mat `pr_se' = vecdiag(cholesky(diag(`pr_V')))'

    * 2008-07-09
    matrix pedifsep = `pr_se'

    if "`diff'"=="diff" {

        if `cur_eq_sav'==0 { // no change from x_dif==0
            * se's are 0
            mat `prdif_se' = J(rowsof(`prdif_V'),1,0)
        }
        else {
            mat `prdif_se' = vecdiag(cholesky(diag(`prdif_V')))'
        }

        * 2008-07-09
        matrix pedifsep = `prdif_se'

    }

    * construct bounds for pred prob
    mat `pr_lo' = `pr_cur' - `z'*`pr_se'
    mat `pr_up' = `pr_cur' + `z'*`pr_se'
    mat peupper[2,1] = (`pr_up')'
    mat pelower[2,1] = (`pr_lo')'

    if "`e(cmd)'"=="poisson" | "`e(cmd)'"=="nbreg" {
        * 2008-07-09
        global pesemu = sqrt(`mu_V'[1,1])
        mat peupper[3,2] = `mu' + `z'*sqrt(`mu_V'[1,1])
        mat pelower[3,2] = `mu' - `z'*sqrt(`mu_V'[1,1])
    }

// CREATE BOUNDS FOR DISCRETE CHANGE

    if "`diff'"=="diff" {
        mat `prdif_lo' = `prdif' - `z'*`prdif_se'
        mat `prdif_up' = `prdif' + `z'*`prdif_se'
        mat peupper[6,1] = (`prdif_up')'
        mat pelower[6,1] = (`prdif_lo')'
        if "`e(cmd)'"=="poisson" | "`e(cmd)'"=="nbreg" {
        * 2008-07-09
        global pedifsemu = sqrt(`mudif_V'[1,1])
            mat peupper[7,2] = (`mudif' + `z'*sqrt(`mudif_V'[1,1]))
            mat pelower[7,2] = (`mudif' - `z'*sqrt(`mudif_V'[1,1]))
        }
    }

// SAVE GRADIENTS TO COMPUTE CI FOR DCs

    if "`save'"=="save" {
        mat pegrad_pr = `pr_G'
        if "`e(cmd)'"=="poisson" | "`e(cmd)'"=="nbreg" {
            mat pegrad_mu = `mu_G'
        }
    }

end

capture program drop lgtpdf
// lgtpdf 0 0
//      scalar a = r(pdf) // pdf of logit
//      scalar b = r(cdf) // cdf of logit
// di "pdf: " r(pdf)
// di "cdf: " r(cdf)

program define lgtpdf, rclass
    version 8
    tempname expab pdf cdf
    args a bx
    scalar `expab' = exp(`a' + `bx')
    scalar `pdf' = `expab' / (1 + `expab')^2
    scalar `cdf' = `expab' / (1 + `expab')
    return scalar pdf = `pdf'
    return scalar cdf = `cdf'
end

exit

version 0.2.0 2005-02-03
version 0.2.1 13Apr2005
version 0.2.2 2008-07-09
    - return global pedifsep
version 0.2.5 2009-09-18
    - update for stata 11 - drop for _get_mlogit_bv.ado
version 0.2.6 2009-10-21
    - use _get_mlogit_bv.ado
