*! version 2.5.2 2009-12-11 jsl
*  - deal with negative value in ologit for outcome option
*  version 2.5.1 2009-12-10 jsl
*  - deal with negative value in ologit

capture program drop prchange
program define prchange, rclass

    * 1.9.0
     local caller = _caller()

    version 6
    tempname delthlf delt
    tempname tobase tobase2 min max mean sd min2 max2 mean2 sd2 marg
    tempname margout marg2 margou2
    tempname sdx sdxhalf minx maxx lobase hibase x_base xb xb_lo xb_hi mu
    tempname p1 p_lo p_hi temp tmp tmp_lo tmp_hi vmarg vchange dchange basepr
    tempname baseval basezi // 2006-02-18 for estout
    mat def `baseval' = J(1,1,.)
    mat def `basezi' = J(1,1,.)
    tempname /*deltais*/ predis change      // changed 05nov2007 bj
    mat def `change' = J(1,1,.)
    mat def `predis' = J(1,1,.)
    tempname nomtemp

*=> classify each valid type of model

    *zt 18Feb2005
    local iszt = 0 //
    if ("`e(cmd)'"=="ztp" | "`e(cmd)'"=="ztnb") {
            local iszt = 1
    }
    if "`e(cmd)'"=="ztp"  { local io = "typical count"   }
    if "`e(cmd)'"=="ztnb"  {    local io = "typical count"     }

    if "`e(cmd)'"=="cloglog"  { local io = "typical binary" }
    if "`e(cmd)'"=="gologit"  { local io = "typical ordered" }
    if "`e(cmd)'"=="logistic" { local io = "typical binary" }
    if "`e(cmd)'"=="logit"    { local io = "typical binary" }
    if "`e(cmd)'"=="mlogit"   { local io = "typical nomord" }
    if "`e(cmd)'"=="mprobit"  { local io = "typical nomord" } // 16Feb2008 sl
    if "`e(cmd)'"=="nbreg"    { local io = "typical count" }
    if "`e(cmd)'"=="ologit"   { local io = "typical nomord" }
    if "`e(cmd)'"=="oprobit"  { local io = "typical nomord" }
    if "`e(cmd)'"=="slogit"   { local io = "typical nomord" }
    if "`e(cmd)'"=="poisson"  { local io = "typical count" }
    if "`e(cmd)'"=="probit"   { local io = "typical binary" }
    if "`e(cmd)'"=="zinb"     { local io = "twoeq count" }
    if "`e(cmd)'"=="zip"      { local io = "twoeq count" }
    if "`io'"=="" {
        di
        di in y "prchange" in r " does not work for last model estimated."
        exit
    }
    local input : word 1 of `io'   /* input routine to _pepred */
    local output : word 2 of `io'  /* output routine */

*=> get info about variables

    _perhs
    local nrhs = `r(nrhs)'
    local rhsnms "`r(rhsnms)'"
    if "`input'"=="twoeq" {
        local nrhs2 = `r(nrhs2)'
        local rhsnms2 "`r(rhsnms2)'"
    }
    if "`output'" != "regress" & "`output'" != "tobit" {
        _pecats
        local ncats = r(numcats)
        local catnms8 `r(catnms8)'
        local catvals `r(catvals)'
        local catnms `r(catnms)'
    }

*=> decode input

    syntax [varlist(default=none)] [if] [in] /*
    */ [, x(passthru) Rest(passthru) Level(passthru) Delta(real 1) /*
    */ UNCentered Fromto all Outcome(string) noBAse noLAbel Help Brief /*
    */ CONditional ]

    *zt 19Feb2005
    if `iszt'==1 & "`conditional'"=="conditional" ///
        & "`outcome'"=="0" {
        di _n in r "conditional probabilities for outcome 0 are undefined."
        exit
    }

    *convert delta() to scalars
    sca `delt' = `delta'
    sca `delthlf' = `delt'/2

    * _pebase handles input and sets base values
    _pebase `if' `in', `x' `rest' `choices' `all'
    mat `tobase' = r(pebase)
    if "`input'"=="twoeq" { mat `tobase2' = r(pebase2) }

    * _peife combines `if' with e(sample)==1 if needed
    _peife `if', `all'
    local if "`r(if)'"

    * summary statistics on rhs variables
    quietly _pesum `if' `in'
    mat `min' = r(Smin)
    mat `min' = `min'[1, 2...]
    mat `max' = r(Smax)
    mat `max' = `max'[1, 2...]
    mat `mean' = r(Smean)
    mat `mean' = `mean'[1, 2...]
    mat `sd' = r(Ssd)
    mat `sd' = `sd'[1, 2...]

    * 2006-02-18 - base values to be returned for estout
    mat `baseval' = `mean' \ `sd' \ `min' \ `max'
    mat rownames `baseval' = Mean SD Min "Max"

    if "`input'"=="twoeq" {
        quietly _pesum `if' `in', two
        mat `min2' = r(Smin)
        mat `min2' = `min2'[1, 2...]
        mat `max2' = r(Smax)
        mat `max2' = `max2'[1, 2...]
        mat `mean2' = r(Smean)
        mat `mean2' = `mean2'[1, 2...]
        mat `sd2' = r(Ssd)
        mat `sd2' = `sd2'[1, 2...]
        * 2006-02-18 - zip & zinb base values to be returned for estout
        mat `basezi' = `mean2' \ `sd2' \ `min2' \ `max2'
        mat rownames `basezi' = Mean SD Min Max
    }

    * set values of PE_in, to be modified before sent to _pepred
    capture mat drop PE_in
    mat PE_in = `tobase'
    if "`input'"=="twoeq" {
        capture mat drop PE_in2
        mat PE_in2 = `tobase2'
    }

    if "`varlist'" == "" { local varlist "`rhsnms'" }

*=> handle outcome() option

    if "`outcome'"!="" {
        if "`output'"=="binary" {
            di in r "outcome() not allowed for prchange after `e(cmd)'"
            exit 198
        }
        if "`output'"=="nomord" {
            local found "no"
            * cycle through outcome categories
            local i = 1
            while `i' <= `ncats' {
                local valchk : word `i' of `catvals'
                local nmchk : word `i' of `catnms'
                * outcome() value to category value
                if ("`outcome'"=="`valchk'") | ("`outcome'"=="`nmchk'") {
                    local found "yes"
                    local outcmv = "`valchk'"
* 2.5.2
local outcmvnm "`outcmv'"
if `outcome'<0 {
    local outcmvnm = abs(`outcmv')
    local outcmvnm "_`outcmvnm'"
}                    

                    if "`valchk'"!="`nmchk'" { local outcmnm " (`nmchk')" }
                    local outcome = `i'
                    local i = `ncats'
                }
                local i = `i' + 1
            }
            if "`found'"=="no" {
                di in r "`outcome' not category of `e(depvar)'"
                exit 198
            }
        } // output is nomord

        if "`output'"=="count" {
            confirm integer number `outcome'
            if `outcome' < 0 { exit 198 }
            local outcmv "`outcome'"
        }
    }

*=> compute marginal effects (_pemarg requires mat PE_base that was set by _pebase)

    * zt 19Feb2005 TO DO
    * 1.8.0 _pemarg
    _pemarg, caller(`caller') // 1.9.0
    local hasmarg = "`r(hasmarg)'"
    if "`hasmarg'"=="yes" {
        mat `marg' = r(marginal)
        if "`output'"=="count" | "`output'"=="binary" {
            mat `marg' = `marg'[2, 1...]
        }
    }

*=> header information

    if "`brief'"=="" {

        *zt 19Feb2005
        if `iszt'==1 {
            if "`conditional'"=="" {
                local type "Unconditional "
            }
            else {
                local type "Conditional "
            }
        }
        di _n in y "`e(cmd)'" _c
        if "`output'"=="count" & "`outcome'"=="" {
            di in g ": Changes in `type'Rate for " _c
        }
        else { di in g ": Changes in `type'Probabilities for " _c}
        di in y "`e(depvar)'"
        if "`outcome'"!="" {
            di in g _new "Outcome: " in y "`outcmv'" in y "`outcmnm'" // 2007-01-07
        }

        *print value of delta if specified
        if `delt'!=1 {
            if "`uncentered'"!="" {
                di _n in g "(Note: delta = " in y `delt' in g ")"
            }
            else {
                di _n in g "(Note: d = " in y `delt' in g ")"
            }
        }
    }

*=> cycle through all variables in varlist
*   varnum = matrix position of rhs variable; -1 if not in count equation
*   varnum2 =position in binary matrix of rhs var in ZIP/ZINB; -1 if absent

    local i = 1
    local i_to : word count `varlist'
    while `i' <= `i_to' {
        local var : word `i' of `varlist'
        local found "no"
        local varnum -1
        local i2 = 1
        local i2_to : word count `rhsnms'
        while `i2' <= `i2_to' {
            local varchk : word `i2' of `rhsnms'
            unab varchk : `varchk', max(1)
            if "`var'"=="`varchk'" {
                local found "yes"
                local varnum = `i2'
                local i2 = `i2_to'
            }
            local i2 = `i2' + 1
        } /* while `i2' < `i2_to' */

        if "`input'"=="twoeq" {
            local i3 = 1
            local i3_to : word count `rhsnms2'
            local varnum2 -1
            while `i3' <= `i3_to' {
                local varchk : word `i3' of `rhsnms2'
                unab varchk : `varchk', max(1)
                if "`var'"=="`varchk'" {
                    local found "yes"
                    local varnum2 = `i3'
                    local i3 = `i3_to'
                }
                local i3 = `i3' + 1
            }
        } /* if "`input'"=="twoeq" */

        if "`found'"=="no" {
            di in r "`var' not rhs variable"
            exit 198
        }

*=> arrange `marg' matrix for output

        if `varnum' != -1 & "`hasmarg'"=="yes" {
            if "`output'"=="nomord" | "`output'"=="mlogit" {
                mat `margout' = nullmat(`margout') \ `marg'[`varnum', 1...]
            }
            else {
                mat `margout' = nullmat(`margout') , `marg'[1, `varnum']
            }
        }

        *=> PE_in has values of start and end of change variable
        *   and levels of other variables for all changes considered
        if `varnum' != -1 {

            * create scalar values for discrete change calculations
            sca `sdx' = `sd'[1, `varnum']
            sca `sdxhalf' = `sdx' / 2
            sca `minx' = `min'[1, `varnum']
            sca `maxx' = `max'[1, `varnum']
            sca `x_base' = `tobase'[1, `varnum']

            * for min --> max
            mat `lobase' = `tobase'
            mat `lobase'[1, `varnum'] = `minx'
            mat PE_in = PE_in \ `lobase'
            mat `hibase' = `tobase'
            mat `hibase'[1, `varnum'] = `maxx'
            mat PE_in = PE_in \ `hibase'

            * low and high values for 0 --> 1
            mat `lobase' = `tobase'
            mat `lobase'[1, `varnum'] = 0
            mat PE_in = PE_in \ `lobase'
            mat `hibase' = `tobase'
            mat `hibase'[1, `varnum'] = 1
            mat PE_in = PE_in \ `hibase'

            * +/- delta
            if "`uncentered'"=="" {
                mat `lobase' = `tobase'
                mat `lobase'[1, `varnum'] = `x_base'-`delthlf'
                mat PE_in = PE_in \ `lobase'
                mat `hibase' = `tobase'
                mat `hibase'[1, `varnum'] = `x_base'+`delthlf'
                mat PE_in = PE_in \ `hibase'
            }
            else {
                mat `lobase' = `tobase'
                mat `lobase'[1, `varnum'] = `x_base'
                mat PE_in = PE_in \ `lobase'
                mat `hibase' = `tobase'
                mat `hibase'[1, `varnum'] = `x_base'+`delt'
                mat PE_in = PE_in \ `hibase'
            }

            * for +/- sdx
            if "`uncentered'"=="" {
                mat `lobase' = `tobase'
                mat `lobase'[1, `varnum'] = `x_base'-`sdxhalf'
                mat PE_in = PE_in \ `lobase'
                mat `hibase' = `tobase'
                mat `hibase'[1, `varnum'] = `x_base'+`sdxhalf'
                mat PE_in = PE_in \ `hibase'
            }
            else {
                mat `lobase' = `tobase'
                mat `lobase'[1, `varnum'] = `x_base'
                mat PE_in = PE_in \ `lobase'
                mat `hibase' = `tobase'
                mat `hibase'[1, `varnum'] = `x_base'+`sdx'
                mat PE_in = PE_in \ `hibase'
            }

        } /* if `varnum' != -1 */

        * if rhs variable not in equation, then all PE_in rows == tobase
        else {
            mat PE_in = nullmat(PE_in) \ `tobase'
            mat PE_in = PE_in \ `tobase'
            mat PE_in = PE_in \ `tobase'
            mat PE_in = PE_in \ `tobase'
            mat PE_in = PE_in \ `tobase'
            mat PE_in = PE_in \ `tobase'
            mat PE_in = PE_in \ `tobase'
            mat PE_in = PE_in \ `tobase'
        }

        * handle PE_in2 for second equation if zip/zinb
        if "`input'"=="twoeq" {
            if "`varnum2'" != "-1" {

                tempname sdx sdxhalf minx maxx
                sca `sdx' = `sd2'[1, `varnum2']
                sca `sdxhalf' = `sdx' / 2
                sca `minx' = `min2'[1, `varnum2']
                sca `maxx' = `max2'[1, `varnum2']
                tempname lobase hibase x_base
                sca `x_base' = `tobase2'[1, `varnum2']

                * min --> max
                mat `lobase' = `tobase2'
                mat `lobase'[1, `varnum2'] = `minx'
                mat PE_in2 = PE_in2 \ `lobase'
                mat `hibase' = `tobase2'
                mat `hibase'[1, `varnum2'] = `maxx'
                mat PE_in2 = PE_in2 \ `hibase'

                * 0 --> 1
                mat `lobase' = `tobase2'
                mat `lobase'[1, `varnum2'] = 0
                mat PE_in2 = PE_in2 \ `lobase'
                mat `hibase' = `tobase2'
                mat `hibase'[1, `varnum2'] = 1
                mat PE_in2 = PE_in2 \ `hibase'

                * +/- delta
                if "`uncentered'"=="" {
                    mat `lobase' = `tobase2'
                    mat `lobase'[1, `varnum2'] = `x_base'-`delthlf'
                    mat PE_in2 = PE_in2 \ `lobase'
                    mat `hibase' = `tobase2'
                    mat `hibase'[1, `varnum2'] = `x_base'+`delthlf'
                    mat PE_in2 = PE_in2 \ `hibase'
                }
                else {
                    mat `lobase' = `tobase2'
                    mat `lobase'[1, `varnum2'] = `x_base'
                    mat PE_in2 = PE_in2 \ `lobase'
                    mat `hibase' = `tobase2'
                    mat `hibase'[1, `varnum2'] = `x_base'+`delt'
                    mat PE_in2 = PE_in2 \ `hibase'
                }

                * +/- sdx
                if "`uncentered'"=="" {
                    mat `lobase' = `tobase2'
                    mat `lobase'[1, `varnum2'] = `x_base'-`sdxhalf'
                    mat PE_in2 = PE_in2 \ `lobase'
                    mat `hibase' = `tobase2'
                    mat `hibase'[1, `varnum2'] = `x_base'+`sdxhalf'
                    mat PE_in2 = PE_in2 \ `hibase'
                }
                else {
                    mat `lobase' = `tobase2'
                    mat `lobase'[1, `varnum2'] = `x_base'
                    mat PE_in2 = PE_in2 \ `lobase'
                    mat `hibase' = `tobase2'
                    mat `hibase'[1, `varnum2'] = `x_base'+`sdx'
                    mat PE_in2 = PE_in2 \ `hibase'
                }

            } /* if "`varnum2'" != "-1" */

            * if not in inflate equation, PE_in2==tobase2
            else {
                mat PE_in2 = nullmat(PE_in2) \ `tobase2'
                mat PE_in2 = PE_in2 \ `tobase2'
                mat PE_in2 = PE_in2 \ `tobase2'
                mat PE_in2 = PE_in2 \ `tobase2'
                mat PE_in2 = PE_in2 \ `tobase2'
                mat PE_in2 = PE_in2 \ `tobase2'
                mat PE_in2 = PE_in2 \ `tobase2'
                mat PE_in2 = PE_in2 \ `tobase2'
            } /* else */

        } /* if "`input'"=="twoeq" */

        local i = `i' + 1
    } /*  while `i' <= `i_to' */


*=> _pepred calculates probabilities based on PE_in

    _pepred, `level'
    local max_i = r(maxcount)

*=> BINARY MODELS

    if "`output'"=="binary" {
        * predicted probability for all rows of PE_in
        mat `p1' = r(p1)
        local i = 1
        local i_to : word count `varlist'
        mat `dchange' = J(`i_to', 4, 0)
        local dchcol 1
        if "`fromto'"=="fromto" {
            mat `dchange' = J(`i_to', 12, 0)
            local dchcol 3
        }
        * cycle though variables
        while `i' <= `i_to' {
            * calculate discrete change as difference and put in dchange matrix
            local anchor = (`i' * 8) - 6
            sca `p_lo' = `p1'[`anchor', 1]
            sca `p_hi' = `p1'[`anchor'+1, 1]
            if "`fromto'"=="fromto" {
                mat `dchange'[`i', 1] = `p_lo'
                mat `dchange'[`i', 2] = `p_hi'
            }
            mat `dchange'[`i', 1*`dchcol'] = `p_hi' - `p_lo'
            sca `p_lo' = `p1'[`anchor'+2, 1]
            sca `p_hi' = `p1'[`anchor'+3, 1]
            if "`fromto'"=="fromto" {
                mat `dchange'[`i', 4] = `p_lo'
                mat `dchange'[`i', 5] = `p_hi'
            }
            mat `dchange'[`i', 2*`dchcol'] = `p_hi' - `p_lo'
            sca `p_lo' = `p1'[`anchor'+4, 1]
            sca `p_hi' = `p1'[`anchor'+5, 1]
            if "`fromto'"=="fromto" {
                mat `dchange'[`i', 7] = `p_lo'
                mat `dchange'[`i', 8] = `p_hi'
            }
            mat `dchange'[`i', 3*`dchcol'] = `p_hi' - `p_lo'
            sca `p_lo' = `p1'[`anchor'+6, 1]
            sca `p_hi' = `p1'[`anchor'+7, 1]
            if "`fromto'"=="fromto" {
                mat `dchange'[`i', 10] = `p_lo'
                mat `dchange'[`i', 11] = `p_hi'
            }
            mat `dchange'[`i', 4*`dchcol'] = `p_hi' - `p_lo'
            local i = `i' + 1
        } /* while `i' <= `i_to' */

        mat rownames `dchange' = `varlist'
            *added to make matrix headings stata7 compatible
            mat _PEtemp = `dchange''
            _peabbv _PEtemp
            mat `dchange' = _PEtemp'

        *column names for centered change
        if "`uncentered'"=="" {
            if `delt' == 1 {
                mat colnames `dchange' = min->max 0->1 -+1/2 -+sd/2
                if "`fromto'"=="fromto" {
                    mat colnames `dchange' =  x=min x=max min->max /*
                    */  x=0 x=1 0->1 x-1/2 x+1/2 -+1/2 x-1/2sd x+1/2sd -+sd/2
                }
            }
            else {
                mat colnames `dchange' = min->max 0->1 -+d/2 -+sd/2
                if "`fromto'"=="fromto" {
                    mat colnames `dchange' =  x=min x=max min->max /*
                    */  x=0 x=1 0->1 x-d/2 x+d/2 -+d/2 x-1/2sd x+1/2sd -+sd/2
                }
            }
        }
        *column names for uncentered change
        else {
            if `delt' == 1 {
                mat colnames `dchange' = min->max 0->1 +1 +sd
                if "`fromto'"=="fromto" {
                    mat colnames `dchange' =  x=min x=max min->max /*
                    */  x=0 x=1 0->1 x x+1 +1 x x+sd +sd
                }
            }
            else {
                mat colnames `dchange' = min->max 0->1 +delta +sd
                if "`fromto'"=="fromto" {
                    mat colnames `dchange' =  x=min x=max min->max /*
                    */  x=0 x=1 0->1 x x+delta +delta x-sd x+sd +sd
                }
            }
        }

        if "`fromto'"=="fromto" {
            mat coleq `dchange' = from to dif from to dif /*
            */ from to dif from to dif
        }

        * add marginals to output if available
        if "`hasmarg'"=="yes" {
            mat rownames `margout' = MargEfct
            mat roweq `margout' = _
            mat `margout' = `margout''
            mat `dchange' = `dchange', `margout'
        }

        * output list discrete change matrix
        mat list `dchange', noheader f(%8.4f)
        mat `change' = `dchange'' // 2006-02-18 for estout

        * list probabilities at tobase if desired
        mat temp = r(p0)
        mat temp2 = r(p1)
        mat `basepr' = temp[1,1] , temp2[1,1]
        mat rownames `basepr' = "Pr(y|x)"
        if "`label'"=="nolabel" { mat colnames `basepr' = `catvals' }
        else { mat colnames `basepr' = `catnms8' }
        if "`brief'"=="" { mat list `basepr', noheader f(%8.4f) }
        mat `predis' = `basepr' // 2006-02-18 for estout

    } /*  if "`output'"=="binary" */

*=> COUNT MODELS, but not zt

    if "`output'"=="count" & `iszt'==0 {
        if "`outcome'"=="" { mat `tmp' = r(mu) }
        else { mat `tmp' = r(p`outcome') }
        local i = 1
        local i_to : word count `varlist'
        mat `dchange' = J(`i_to', 4, 0)
        local dchcol 1
        if "`fromto'"=="fromto" {
            mat `dchange' = J(`i_to', 12, 0)
            local dchcol 3
        }
        * cycle through all variables specified in varlist
        while `i' <= `i_to' {
            * calculate discrete change and put in dchange matrix
            local anchor = (`i' * 8) - 6
            sca `tmp_lo' = `tmp'[`anchor', 1]
            sca `tmp_hi' = `tmp'[`anchor'+1, 1]
            if "`fromto'"=="fromto" {
                mat `dchange'[`i', 1] = `tmp_lo'
                mat `dchange'[`i', 2] = `tmp_hi'
            }
            mat `dchange'[`i', `dchcol'*1] = `tmp_hi' - `tmp_lo'
            sca `tmp_lo' = `tmp'[`anchor'+2, 1]
            sca `tmp_hi' = `tmp'[`anchor'+3, 1]
            if "`fromto'"=="fromto" {
                mat `dchange'[`i', 4] = `tmp_lo'
                mat `dchange'[`i', 5] = `tmp_hi'
            }
            mat `dchange'[`i', `dchcol'*2] = `tmp_hi' - `tmp_lo'
            sca `tmp_lo' = `tmp'[`anchor'+4, 1]
            sca `tmp_hi' = `tmp'[`anchor'+5, 1]
            if "`fromto'"=="fromto" {
                mat `dchange'[`i', 7] = `tmp_lo'
                mat `dchange'[`i', 8] = `tmp_hi'
            }
            mat `dchange'[`i', `dchcol'*3] = `tmp_hi' - `tmp_lo'
            sca `tmp_lo' = `tmp'[`anchor'+6, 1]
            sca `tmp_hi' = `tmp'[`anchor'+7, 1]
            if "`fromto'"=="fromto" {
                mat `dchange'[`i', 10] = `tmp_lo'
                mat `dchange'[`i', 11] = `tmp_hi'
            }
            mat `dchange'[`i', `dchcol'*4] = `tmp_hi' - `tmp_lo'
            local i = `i' + 1
        }
        mat rownames `dchange' = `varlist'
            *added to make matrix headings stata7 compatible
            mat _PEtemp = `dchange''
            _peabbv _PEtemp
            mat `dchange' = _PEtemp'

        *column names for centered change
        if "`uncentered'" == "" {
            *unit change
            if `delt' == 1 {
                mat colnames `dchange' = min->max 0->1 -+1/2 -+sd/2
                if "`fromto'"=="fromto" {
                    mat colnames `dchange' =  x=min x=max min->max /*
                    */ x=0 x=1 0->1 x-1/2 x+1/2 -+1/2 x-1/2sd x+1/2sd -+sd/2
                }
            }
            *change specified by delta()
            else {
                mat colnames `dchange' = min->max 0->1 -+d/2 -+sd/2
                if "`fromto'"=="fromto" {
                    mat colnames `dchange' =  x=min x=max min->max /*
                    */ x=0 x=1 0->1 x-d/2 x+d/2 -+d/2 x-1/2sd x+1/2sd -+sd/2
                }
            }
        }
        *column names for uncentered change
        else {
            *unit change
            if `delt' == 1 {
                mat colnames `dchange' = min->max 0->1 +1 +sd
                if "`fromto'"=="fromto" {
                    mat colnames `dchange' =  x=min x=max min->max /*
                    */ x=0 x=1 0->1 x x+1 -+1 x x+sd +sd
                }
            }
            *change specified by delta
            else {
                mat colnames `dchange' = min->max 0->1 +delta +sd
                if "`fromto'"=="fromto" {
                    mat colnames `dchange' =  x=min x=max min->max /*
                    */ x=0 x=1 0->1 x x+delta +delta x x+sd +sd
                }
            }
        }
        if "`fromto'"=="fromto" {
            mat coleq `dchange' = from to dif from to dif from /*
            */ to dif from to dif
        }

        if "`hasmarg'"=="yes" & "`outcome'"=="" {
            mat rownames `margout' = MargEfct
            mat roweq `margout' = _
            mat `margout' = `margout''
            mat `dchange' = `dchange', `margout'
        }
        mat list `dchange', noheader f(%8.4f)
        if "`outcome'"=="" {
            local i = 0
            mat `temp' = r(mu)
            sca `mu' = `temp'[1,1]
            mat `predis' = `mu' // 2006-02-18 for estout
            mat rownames `predis' = exp(xb) // 2006-02-18 for estout
            if "`brief'"=="" { di _n in g "exp(xb): " in y %8.4f `mu' }
        }
        else {
            local i = 0
            while `i' <= `max_i' {
                mat `temp' = r(p`i')
                mat `basepr' = nullmat(`basepr') , `temp'[1, 1]
                local cntvals "`cntvals'`i' "
                local i = `i' + 1
            }
            mat rownames `basepr' = "Pr(y|x)"
            mat colnames `basepr' = `cntvals'
            if "`brief'"=="" { mat list `basepr', noheader f(%8.4f) }
            mat `predis' = `basepr' // 2006-02-18 for estout
            mat rownames `predis' = "Pr(y|x)" // 2006-02-18 for estout
        }
        mat `change' = `dchange'' // 2006-02-18 for estout
    }

*=> ZT COUNT MODELS 19Feb2005

    if `iszt'==1 {
        if "`conditional'"=="" {
            local type ""
        }
        else {
            local type "C"
        }

        * grab conditional or not based on type
        if "`outcome'"=="" { mat `tmp' = r(`type'mu) }
        else { mat `tmp' = r(`type'p`outcome') }
        local i = 1
        local i_to : word count `varlist'
        mat `dchange' = J(`i_to', 4, 0)
        local dchcol 1
        if "`fromto'"=="fromto" {
            mat `dchange' = J(`i_to', 12, 0)
            local dchcol 3
        }

        * cycle through all variables specified in varlist
        while `i' <= `i_to' {
            * calculate discrete change and put in dchange matrix
            local anchor = (`i' * 8) - 6
            sca `tmp_lo' = `tmp'[`anchor', 1]
            sca `tmp_hi' = `tmp'[`anchor'+1, 1]
            if "`fromto'"=="fromto" {
                mat `dchange'[`i', 1] = `tmp_lo'
                mat `dchange'[`i', 2] = `tmp_hi'
            }
            mat `dchange'[`i', `dchcol'*1] = `tmp_hi' - `tmp_lo'
            sca `tmp_lo' = `tmp'[`anchor'+2, 1]
            sca `tmp_hi' = `tmp'[`anchor'+3, 1]
            if "`fromto'"=="fromto" {
                mat `dchange'[`i', 4] = `tmp_lo'
                mat `dchange'[`i', 5] = `tmp_hi'
            }
            mat `dchange'[`i', `dchcol'*2] = `tmp_hi' - `tmp_lo'
            sca `tmp_lo' = `tmp'[`anchor'+4, 1]
            sca `tmp_hi' = `tmp'[`anchor'+5, 1]
            if "`fromto'"=="fromto" {
                mat `dchange'[`i', 7] = `tmp_lo'
                mat `dchange'[`i', 8] = `tmp_hi'
            }
            mat `dchange'[`i', `dchcol'*3] = `tmp_hi' - `tmp_lo'
            sca `tmp_lo' = `tmp'[`anchor'+6, 1]
            sca `tmp_hi' = `tmp'[`anchor'+7, 1]
            if "`fromto'"=="fromto" {
                mat `dchange'[`i', 10] = `tmp_lo'
                mat `dchange'[`i', 11] = `tmp_hi'
            }
            mat `dchange'[`i', `dchcol'*4] = `tmp_hi' - `tmp_lo'
            local i = `i' + 1
        }
        mat rownames `dchange' = `varlist'
            *added to make matrix headings stata7 compatible
            mat _PEtemp = `dchange''
            _peabbv _PEtemp
            mat `dchange' = _PEtemp'

        *column names for centered change
        if "`uncentered'" == "" {
            *unit change
            if `delt' == 1 {
                mat colnames `dchange' = min->max 0->1 -+1/2 -+sd/2
                if "`fromto'"=="fromto" {
                    mat colnames `dchange' =  x=min x=max min->max /*
                    */ x=0 x=1 0->1 x-1/2 x+1/2 -+1/2 x-1/2sd x+1/2sd -+sd/2
                }
            }
            *change specified by delta()
            else {
                mat colnames `dchange' = min->max 0->1 -+d/2 -+sd/2
                if "`fromto'"=="fromto" {
                    mat colnames `dchange' =  x=min x=max min->max /*
                    */ x=0 x=1 0->1 x-d/2 x+d/2 -+d/2 x-1/2sd x+1/2sd -+sd/2
                }
            }
        }
        *column names for uncentered change
        else {
            *unit change
            if `delt' == 1 {
                mat colnames `dchange' = min->max 0->1 +1 +sd
                if "`fromto'"=="fromto" {
                    mat colnames `dchange' =  x=min x=max min->max /*
                    */ x=0 x=1 0->1 x x+1 -+1 x x+sd +sd
                }
            }
            *change specified by delta
            else {
                mat colnames `dchange' = min->max 0->1 +delta +sd
                if "`fromto'"=="fromto" {
                    mat colnames `dchange' =  x=min x=max min->max /*
                    */ x=0 x=1 0->1 x x+delta +delta x x+sd +sd
                }
            }
        }
        if "`fromto'"=="fromto" {
            mat coleq `dchange' = from to dif from to dif from /*
            */ to dif from to dif
        }

        if "`hasmarg'"=="yes" & "`outcome'"=="" {
            mat rownames `margout' = MargEfct
            mat roweq `margout' = _
            mat `margout' = `margout''
            mat `dchange' = `dchange', `margout'
        }
        mat list `dchange', noheader f(%8.4f)
        mat `change' = `dchange'' // 2006-02-18 for estout

        if "`outcome'"=="" {
            local i = 0
            mat `temp' = r(mu)
            sca `mu' = `temp'[1,1]
            mat `predis' = `mu' // 2006-02-18 for estout
            mat rownames `predis' = exp(xb) // 2006-02-18 for estout

            if "`brief'"=="" { di _n in g "exp(xb): " in y %8.4f `mu' }
        }
        else {
            local i = 0
            while `i' <= `max_i' {
                mat `temp' = r(p`i')
                mat `basepr' = nullmat(`basepr') , `temp'[1, 1]
                local cntvals "`cntvals'`i' "
                local i = `i' + 1
            }
            mat rownames `basepr' = "Pr(y|x)"
            mat colnames `basepr' = `cntvals'
            if "`brief'"=="" { mat list `basepr', noheader f(%8.4f) }
            mat `predis' = `basepr' // 2006-02-18 for estout
            mat rownames `predis' = "Pr(y|x)" // 2006-02-18 for estout
        }
    }

*=> NOMINAL and ORDINAL

    * jsl 10/23/00 - add average absolute discrete change
    if "`output'"=="nomord" {
        local dchcol 1
        if "`fromto'"=="fromto" { local dchcol 3 }
        local i = 1
        local i_to : word count `varlist'
        * loop over variables
        tempname a01 a1 asd arange amarg    // changed 23oct2007 bj
        mat `amarg' = J(1,`i_to',0)         // added 23oct2007 bj
        while `i' <= `i_to' {
            scalar `a01' = 0
            scalar `a1' = 0
            scalar `asd' = 0
            scalar `arange' = 0
            local ncats1 = `ncats' + 1
            mat `vchange' = J(4, `ncats1', 0)
            if "`fromto'"=="fromto" { mat `vchange' = J(12, `ncats1', 0) }
            local anchor = (`i' * 8) - 6
            local i2 = 2
            local i2_to = `ncats1'
            * loop over categories
            while `i2' <= `i2_to' {
                local tmp = `i2' - 1
                mat `temp' = r(p`tmp')
                sca `p_lo' = `temp'[`anchor', 1]
                sca `p_hi' = `temp'[`anchor'+1, 1]
                if "`fromto'"=="fromto" {
                    mat `vchange'[1, `i2'] = `p_lo'
                    mat `vchange'[2, `i2'] = `p_hi'
                }
                * range
                mat `vchange'[`dchcol'*1, `i2'] = `p_hi' - `p_lo'
                scalar `arange' = `arange' + abs(`p_hi' - `p_lo')/`ncats'
                mat `vchange'[`dchcol'*1, 1] = `arange'
                sca `p_lo' = `temp'[`anchor'+2, 1]
                sca `p_hi' = `temp'[`anchor'+3, 1]
                if "`fromto'"=="fromto" {
                    mat `vchange'[4, `i2'] = `p_lo'
                    mat `vchange'[5, `i2'] = `p_hi'
                }
                * 0->1
                mat `vchange'[`dchcol'*2, `i2'] = `p_hi' - `p_lo'
                scalar `a01' = `a01' + abs(`p_hi' - `p_lo')/`ncats'
                mat `vchange'[`dchcol'*2, 1] = `a01'
                * -+1
                sca `p_lo' = `temp'[`anchor'+4, 1]
                sca `p_hi' = `temp'[`anchor'+5, 1]
                if "`fromto'"=="fromto" {
                    mat `vchange'[7, `i2'] = `p_lo'
                    mat `vchange'[8, `i2'] = `p_hi'
                }
                mat `vchange'[`dchcol'*3, `i2'] = `p_hi' - `p_lo'
                scalar `a1' = `a1' + abs(`p_hi' - `p_lo')/`ncats'
                mat `vchange'[`dchcol'*3, 1] = `a1'
                * -+sd
                sca `p_lo' = `temp'[`anchor'+6, 1]
                sca `p_hi' = `temp'[`anchor'+7, 1]
                if "`fromto'"=="fromto" {
                    mat `vchange'[10, `i2'] = `p_lo'
                    mat `vchange'[11, `i2'] = `p_hi'
                }
                mat `vchange'[`dchcol'*4, `i2'] = `p_hi' - `p_lo'
                scalar `asd' = `asd' + abs(`p_hi' - `p_lo')/`ncats'
                mat `vchange'[`dchcol'*4, 1] = `asd'
                local i2 = `i2' + 1

            } /* loop over categories */
            local var : word `i' of `varlist'

            * column names for centered change
            if "`uncentered'"=="" {
                if `delt'==1 {
                    mat rownames `vchange' = "Min->Max" "    0->1"  "   -+1/2" /*
                    */ "  -+sd/2"
                    if "`fromto'"=="fromto" {
                        mat rownames `vchange' = "   x=min" "   x=max" "min->max"  /*
                        */  "     x=0" "     x=1" "    0->1" "   x-1/2" "   x+1/2" /*
                        */ "   -+1/2" " x-1/2sd" " x+1/2sd" "  -+sd/2"
                    }
                }
                else {
                    mat rownames `vchange' = "Min->Max" "    0->1"  "   -+d/2" /*
                    */ "  -+sd/2"
                    if "`fromto'"=="fromto" {
                        mat rownames `vchange' = "   x=min" "   x=max" "min->max"  /*
                        */  "     x=0" "     x=1" "    0->1" "   x-d/2" "   x+d/2" /*
                        */ "   -+d/2" " x-1/2sd" " x+1/2sd" "  -+sd/2"
                    }
                }
            }
            * uncentered change
            else {
                if `delt'==1 {
                    mat rownames `vchange' = "Min->Max" "    0->1"  "      +1" /*
                    */ "     +sd"
                    if "`fromto'"=="fromto" {
                        mat rownames `vchange' = "   x=min" "   x=max" "min->max"  /*
                        */  "     x=0" "     x=1" "    0->1" "       x" "     x+1" /*
                        */ "      +1" "       x" "    x+sd" "     +sd"
                    }
                }
                else {
                    mat rownames `vchange' = "Min->Max" "    0->1"  "  +delta" /*
                    */ "     +sd"
                    if "`fromto'"=="fromto" {
                        mat rownames `vchange' = "   x=min" "   x=max" "min->max"  /*
                        */  "     x=0" "     x=1" "    0->1" "       x" " x+delta" /*
                        */ "  +delta" "       x" "    x+sd" "     +sd"
                    }
                }
            }
            if "`fromto'"=="fromto" {
                mat roweq `vchange' = from to dif from to dif from /*
                */ to dif from to dif
            }

*=> save PE_dc with discrete change values; used by mlogplot and mlogview

            tempname zeros tempmat
            * 1 row x ncats with 0's
            mat `zeros' = J(1, `ncats', 0)
            mat rownames `zeros' = "    void"
            * is it binary?
            capture assert `var' == 0 | `var' == 1 | `var' == . `if' `in'
            * if binary, only 0/1 in 2nd row
            if _rc == 0 {
            * DROP 16Nov2005 1.6.9
            * mat `tempmat' = `zeros' \ `vchange'[1,2...] \ `zeros' \ `zeros' \ `zeros'
                * 16Nov2005 1.6.9
                mat `tempmat' = `vchange'[2,2...] \ `vchange'[1,2...] \ `zeros' /*
                */ \ `zeros' \ `zeros'
            } /* else, 1: min/max 2:null 3:1 4:sd */
            else {

            /* DROP 16Nov2005 1.6.9
                * contains 0->1, zeros, -+1, -+sd
                mat `tempmat' = `vchange'[2,2...] \ /*
                */ `zeros' \ `vchange'[3..4,2...] \ `zeros'
            */
                * 16Nov2005 1.6.9
                * contains 0->1, min->max, -+1, -+sd
                mat `tempmat' = `vchange'[2,2...] \ /*
                */ `vchange'[1,2...] \ `vchange'[3..4,2...] \ `zeros'

            }
            mat roweq `tempmat' = `var'
            if "`i'"=="1" {
                mat PE_dc = `tempmat'
                if "`label'"=="nolabel" { mat colnames PE_dc = `catvals' }
                else { mat colnames PE_dc = `catnms8' }
            }
            if "`i'"!="1" {
                mat PE_dc = PE_dc \ `tempmat'
            }

            * grab all info on change
            mat `nomtemp' = nullmat(`nomtemp') \ `vchange' // 2006-02-18 for estout

*=> set up matrices for output

            if "`label'"=="nolabel" {
                mat colnames `vchange' = "Avg|Chg|" `catvals'
            }
            else {
                mat colnames `vchange' = "Avg|Chg|" `catnms8'
            }
            if "`outcome'"=="" {
                * is 0/1 variable
                capture assert `var' == 0 | `var' == 1 | `var' == . `if' `in'
                if "`fromto'"=="fromto" {
                    if _rc == 0 { mat `vchange' = `vchange'[4..6, 1...] }
                    else {
                        tempname vchang1 vchang2
                        mat `vchang1' = `vchange'[1..3, 1...]
                        mat `vchang2' = `vchange'[7..., 1...]
                        mat `vchange' =  `vchang1' \ `vchang2'
                    }
                }
                else {
                    if _rc == 0 { mat `vchange' = `vchange'[2, 1...] }
                    else {
                        tempname vchang1 vchang2
                        mat `vchang1' = `vchange'[1, 1...]
                        mat `vchang2' = `vchange'[3..., 1...]
                        mat `vchange' =  `vchang1' \ `vchang2'
                    }
                }
                if "`hasmarg'"=="yes" {
                    capture assert `var' == 0 | `var' == 1 /*
                    */ | `var' == . `if' `in'
                    if _rc != 0 {
                        mat `vmarg' = `margout'[`i', 1...]
                        * compute avg abs discrete change
                        local k = 1
                        * amarg changes made in 1.8.0 for estout returns
                        *tempname amarg                                 // removed 23oct2007 bj
                        *scalar `amarg' = 0                             // removed 23oct2007 bj
                        while `k' <= `ncats' {
                            mat `amarg'[1,`i'] = `amarg'[1,`i'] + abs(`vmarg'[1,`k'])    // changed 23oct2007 bj
                            local k = `k' + 1
                        }

                        * jf 5/20/03
                        mat `amarg'[1,`i'] = `amarg'[1,`i'] / `ncats'   // changed 23oct2007 bj
                        mat `vmarg' = (`amarg'[1,`i'],`vmarg')          // changed 23oct2007 bj
                        mat rownames `vmarg' = MargEfct
                        mat roweq `vmarg' = _
                        mat `vchange' = `vchange' \ `vmarg'
                    }
                }
                di _n in y "`var'" _c
                mat list `vchange', noheader
                mat roweq `vchange' = `var'
                mat `dchange' = nullmat(`dchange') \ `vchange'

            } /* "`outcome'"=="" */

            else {
                * mat `vchange' = `vchange'[1..., `outcome']
                * 1.7.1 06Jan2007
                * +1 since average in in first column
                mat `vchange' = `vchange'[1..., `outcome'+1]
                mat `vchange' = `vchange''
                mat rownames `vchange' = `var'
                mat `dchange' = nullmat(`dchange') \ `vchange'
            }
            local i = `i' + 1
        } /* while `i' <= `i_to' */

        if "`outcome'"!="" {
            if "`hasmarg'"=="yes" {
                mat `margout' = `margout'[1..., `outcome']
                mat colnames `margout' = MargEfct
                mat coleq `margout' = _
                mat `dchange' = `dchange' , `margout'
            }
            *added to make matrix headings stata7 compatible
            mat _PEtemp = `dchange''
* 2.5.2
local outcmvnm "`outcmv'"
return mat change`outcmvnm' = _PEtemp, copy
*            return mat change`outcmv' = _PEtemp, copy           // added 23oct2007 bj
            _peabbv _PEtemp
            mat `dchange' = _PEtemp'
            mat list `dchange', noheader
            mat `dchange' = `dchange''
        }
        local i = 1
        while `i' <= `ncats' {
            mat temp = r(p`i')
            mat `basepr' = nullmat(`basepr') , temp[1, 1]
            local i = `i' + 1
        }
        mat rownames `basepr' = "Pr(y|x)"
        if "`label'"=="nolabel" { mat colnames `basepr' = `catvals' }
        else { mat colnames `basepr' = `catnms8' }
        if "`brief'"=="" { mat list `basepr', noheader }

        // rearrange info to be returned 2006-02-18 for estout
        if "`outcome'"=="" {            // if-condition added 23oct2007 bj
            tempname tempmat mtemp      // changed 24oct2007 bj
            local i = 1
            while `i' <= (`ncats'+1) {
                * move col i into one column for each variable
                local v = 1
                while `v' <= `i_to' {
                    local nrowper = 4 + 8*("`fromto'"=="fromto") // rows of info per variable - changed 07nov2007 bj
                    local rst = 1+ ((`v'-1)*`nrowper')
                    local ren = `rst' + `nrowper' - 1
                    mat `tempmat' = nullmat(`tempmat') , `nomtemp'[`rst'..`ren'', `i']
                    local ++v
                }
                mat colnames `tempmat' = `varlist'
                if `i'==1 {
                    if "`hasmarg'"=="yes" {             // block added 23oct2007 bj
                        mat rowname `amarg' = MargEfct
                        mat `tempmat' = `tempmat' \ `amarg'
                    }
                    return mat changemn = `tempmat'
                }
                else {
                    local c = `i' - 1
                    local catnum : word `c' of `catvals'
                    * 2.5.1 if negative, replace - with _ 2009-12-10
                    if `catnum'<0 {
                        local catnum = abs(`catnum')
                        local catnum "_`catnum'"
                    }                    
                    tempname change`catnum'

                    * 1.7.1 add marg to return matrix
                    if "`hasmarg'"=="yes" {             // if-condition added 23oct2007 bj
                        mat `mtemp' = `margout'[1...,`c']'  // changed 23oct2007 bj
                        mat rowname `mtemp' = MargEfct
                        *mat def mtemp = `mtemp'        // removed 23oct2007 bj
                        *mat def tempmat = `tempmat'    // removed 23oct2007 bj
                        mat `tempmat' = `tempmat' \ `mtemp'
                    }
                    return mat change`catnum' = `tempmat'

                }
                local ++i
            }
        } /* if "`outcome'"=="" */
        mat `predis' = `basepr'

    } /* if "`output'"=="nomord" */

*=> print base values

    if "`brief'"=="" & "`base'"!="nobase" {
        if "`input'"=="twoeq" {
            di _n in g "base x values for count equation: "
        }
        mat `tobase' = `tobase' \ `sd'
        * 2009-07-10 1.8.1 for Stata 11
        mat rownames `tobase' = "x=" "sd_x="
        mat _PEtemp = `tobase'
        _peabbv _PEtemp
        mat list _PEtemp, noheader f(%8.0g)
        if "`input'"=="twoeq" {
            di _n in g "base x values for binary equation: "
            mat `tobase2' = `tobase2' \ `sd2'
            * 2009-07-10 1.8.1 for Stata 11
            mat rownames `tobase2' = "x=" "sd_x="
            mat _PEtemp = `tobase2'
            _peabbv _PEtemp
            mat list _PEtemp, noheader f(%8.0g)
        }
    }

*=> Help option

    if "`help'"=="help" {
        di
        di in g " Pr(y|x): probability of observing each y for "/*
        */ "specified x values"
        di in g "Avg|Chg|: average of absolute value of the change"/*
        */ " across categories"
        di in g "Min->Max: change in predicted probability as x"/*
        */ " changes from its minimum to"
        di in g "          its maximum"
        di in g "    0->1: change in predicted probability as x"/*
        */ " changes from 0 to 1"

        if "`uncentered'"=="" {
            if `delt'==1 {
                di in g "   -+1/2: change in predicted probability as x"/*
                */ " changes from 1/2 unit below"
                di in g "          base value to 1/2 unit above"
            }
            else {
                di in g "   -+d/2: change in predicted probability as x"/*
                */ " changes from " `delthlf' " units"
                di in g "          below base value to "`delthlf' " units"/*
                */ " above"
            }
        }
        else {
            if `delt'==1 {
                di in g "      +1: change in predicted probability as x"/*
                */ " increases by 1 unit"
            }
            else {
                di in g "  +delta: change in predicted probability as x"/*
                */ " increases by " `delt' " units"
            }
        }

        if "`uncentered'"=="" {
            di in g "  -+sd/2: change in predicted probability as x"/*
            */ " changes from 1/2 standard"
            di in g "          dev below base to 1/2 standard"/*
            */ " dev above"
        }
        else {
            di in g "     +sd: change in predicted probability as x"/*
            */ " increases by a standard dev"
        }

        di in g "MargEfct: the partial derivative of the predicted"/*
        */ " probability/rate with"
        di in g "          respect to a given independent variable"
    }

//  2006-02-18 returns for estout

    mat rown `tobase' = X                                    // 23oct2007 bj
    mat `baseval' = `tobase'[1,1...] \ `baseval'[2...,1...]  // 23oct2007 bj
    * combine base values and name equations if zip or zinb
    if "`input'"=="twoeq" {
        mat rown `tobase2' = X                                      // added 23oct2007 bj
        mat `basezi' = `tobase2'[1,1...] \ `basezi'[2...,1...]      // added 23oct2007 bj
        matrix colnames `basezi' = inflate:
        local eqnm "`e(depvar)':"
        matrix colnames `baseval' = `eqnm'
        matrix `baseval' = `baseval' , `basezi'
    }

    return matrix baseval = `baseval'
    if "`output'"!="nomord" { return matrix change = `change' }     // changed 23oct2007 bj
    return matrix predval = `predis'
    return scalar delta = `delt'                        // 05nov2007 bj
    return scalar centered = ("`uncentered'"=="")       // 05nov2007 bj
    if "`outcome'"!="" {                                // 23oct2007 bj
        return scalar outcome = `outcmv'
    }
    return local modeltype `"`io'"'         // 23oct2007 bj

    * return names and values of outcome categories
    tempname catn
    if "`catvals'"!="" {
        local i = 1
        while `i' <= `ncats' {
            local valchk : word `i' of `catvals'
            local nmchk : word `i' of `catnms'
            mat `catn' = nullmat(`catn') \ `valchk'
            local ++i
        }
    }
    else {
        matrix `catn' = J(1,1,.)
        local catnms = ""
    }
    matrix `catn' = `catn''
    matrix colnames `catn' = `catnms'
    matrix rownames `catn' = "`e(depvar)'"
    return matrix catval = `catn'
end
exit

*  version 1.6.8 13Apr2005
*  version 1.6.7c 27Mar2005 slogit
*  version 1.6.7b 19Feb2005 zt
*  version 1.6.6  20May2003
*  version 1.6.9 - 19May2006
*   - Add min->max change to PE_dc for mlogplot
*   - required for mlogplot v1.6.8 to plot changes over range
*  version 1.7.1 jsl 06Jan2007 for estout
*   - outcome() fixed for ord and nom
*  version 1.7.2 - 07nov2007 Ben Jann changes for estout
*  - -fromto- results were not returned correctly with nomord models - this is fixed
*  - brief option caused error - this is fixed
*  - returns r(outcome) if -outcome()- specified
*  - returns type of model in r(modeltype)
*  - returns marginal effects now also in r(changemn)
*  - no longer crashes on nomorg models without marginals (i.e. -slogit-)
*  - returns correct basevals now if x() is specified
*  - returns results now only for the specified outcome if -outcome()- is specified
*  - no longer returns r(change) for nomord models
* version 1.8.0 2008-02-16 sl
*   - revised to work with estout
*   - added mprobit
* version 1.8.1 2009-07-10
*   - sd(x) fix for Stata 11
* version 1.9.0 jsl 2009-09-19
*   - fix mlogit for e(b) in stata 11
* version 2.5.0 2009-10-28 jsl
*  - stata 11 update for returns from -mlogit-
