*! version 2.5.0 2009-10-28 jsl
*  - stata 11 update for returns from -mlogit-

capture program drop mlogplot
capture program drop lp_plt
capture program drop getprob

program define mlogplot
    version 6.0
    tempname tmp b sd bstd sdrhs 01rhs sdi ch0 chu chs _lpstdt _lpplt isdum
    * if 1, then auto exit of mlogview
    global PE_mlerr = 0

/*  06Apr2006 - trap 0 category
    mat `tmp' = e(cat)
    local ncat = e(k_cat)
    local i = 1
    while `i' <= `ncat' {
        local v = `tmp'[`i',1]
        if `v' <= 0 {
            di in r "outcome categories cannot be 0 or negative."
            di in r "recode outcome variable to begin at 1."
            exit
        }
        local i = `i' + 1
    }
*/
    * 18Nov2005
    local maxvar = 7
    syntax [varlist(default=none)], [/*
    */ ORatio DChange Prob(real 1) packed labels /*
    */ min(real -99999) max(real 99999) /*
    */ matrix Std(string) Vars(string) /*
    */ dcadd(real 0) dcbase(real .1) NTics(real 7) /*
    */ Basecategory(real -1) Note(string) VALues] /*
    */ [saving(string)] [sign]

    * create saving option
    local gphopen "gph open"
    if "`saving'"~="" { local gphopen "gph open, saving(`saving')" }

    local varis `varlist'
    if "`varis'"=="" & "`matrix'"~="matrix" {
        _perhs
        local varis "`r(rhsnms)'"
    }
    if `min'>=`max' {
        di in r "the minimum is larger than the maximum"
        exit
    }
    * dcplot=1 if dc plot
    local dcplot = 0
    if "`dchange'"=="dchange" & "`oratio'"~="oratio" {
        local dcplot = 1
        local packed packed
    }
    * mavar depends on whether there is packing
    if "`packed'" == "packed" {
        local maxvar = 11 /* max # to plot in packed graph */
    }

*=> matrix input

    if "`matrix'" == "matrix" {
        if `prob'~=1 {
            di in r "with matrix input the prob " /*
                    */ "option does not work."
            local prob = 1
        }
        if "`dchange'" == "dchange" {
            if "`oratio'" ~= "oratio" {
                di in r "dchange plots are not " /*
                    */ "possible with matrix input."
                exit
            }
            di in r "dchange option does not work " /*
                    */ "with matrix output. option was ignored."
            local dchange ""
        }

        local depvar "$mnldepnm"
        * names of variables to plot
        local varis `vars'
        * in b, cols are variables, rows are contrasts
        mat `b' = mnlbeta
        mat `sdrhs' = mnlsd
        local nvarp1 = colsof(`b') + 1 /* with constant */
        *todo: check if # of bvarnm is same as cols of b
        * variables associated with rows of betas
        local bvarnm "$mnlname"
        *todo: if doesn't exist, make it all 1's
        * columns correspond to columns in betas
        mat `sd' = mnlsd
        * check size of beta and sd's
        local n1 = colsof(`b')
        local n2 = colsof(`sd')
        if `n1'~=`n2' {
            di in r "# of columns in mnlbeta and mnlsd must be equal"
            exit
        }
    } /* if matrix */

*=> get information from mlogit

    else {
        if "`e(cmd)'"!="mlogit" {
            di in r "mlogplot must be run after mlogit or with matrix input"
            exit
        }
        local depvar = e(depvar)
        version 5
        mat `b' = get(_b)
        version 6
        * 2009-10-28
        tempname eV
        _get_mlogit_bv `b' `eV'
*mat list `b'
*mat list `eV'        
        local bvarnm : colnames(`b')
        parse "`bvarnm'", parse (" ")
        quietly _pesum, dummy
        mat `sdrhs' = r(Ssd)
        mat `sdrhs' = `sdrhs'[1,2...]
        mat `01rhs' = r(Sdummy)
        mat `01rhs' = `01rhs'[1,2...]

        * 16Nov2005 1.6.8 - get range
        tempname rngrhs
        mat `rngrhs' = r(Smax) - r(Smin)
        mat `rngrhs' = `rngrhs'[1,2...]
        *<
        local nvarp1 = colsof(`b') /* with constant */
    }
    local nvar = `nvarp1' - 1 /* excludes constant */
    local ncat = rowsof(`b') + 1
    local maxnvar = 3*`nvar' /* allows each var plotted 3 times */
                             /* 0->1, +-1, +-sd */
    if `basecategory' > `ncat' {
        di in r "specified base category exceeds number of categories"
        exit
    }

*=> get discrete change coefficints
*
*   Note: PE_dc - each variable has 5 rows
*   row 1: 0->1 (16Nov2005 1.6.8 not min->max)
*   row 2: min->max (16Nov2005 1.6.8 which can be 0->1)
*   row 3: -/+ 1
*   row 4: -/+ sd
*   row 5: not used
*   row label is void if coefficient not computed

    * 16Nov2005 1.6.8 - discrete change over range
    tempname chr
    mat `chr' = J(`nvar',`ncat',0)

    mat `ch0' = J(`nvar',`ncat',0)
    mat `chu' = J(`nvar',`ncat',0)
    mat `chs' = J(`nvar',`ncat',0)
    if "`dchange'" == "dchange" {

        capture local ncol = colsof(PE_dc)
        capture local nrow = rowsof(PE_dc)
       
        if "`ncol'"=="" {
            di in r "you must run prchange before " /*
                */ "plotting discrete changes"
            global PE_mlerr = 1
            exit
        }
        local nr = `nvar'*5

/* TEST: 
    di "nvar:   `nvar'"
    di "nvarp1: `nvarp1'"
    di "ncat:   `ncat'"
    di "maxnvar:`maxnvar'"
    di "ncol:   `ncol'"
    di "nrow:   `nrow'"
    di "nr:     `nr'"
END TEST */    

        * size of PE_dc is wrong; probably old PE_dc hanging around
        * 26Nov2006 - or prchange run on only some of the rhs variables
        if `ncol'~=`ncat' | `nrow'~=`nr' {
            di in r "There is a problem with the discrete change " ///
                "coefficients. Rerun " in w "prchange" in r "."
            di in r "Note that " in w "prchange" in r " must include " ///
                "all variables. For example, for the model "
            di in w "mlogit occ white ed exper" in r ", run " ///
                in w "prchange" in r ", not " in w "prchange white ed" ///
                in r "."
            global PE_mlerr = 1
            exit
        }
        local ivar = 1
        local r = 1
        while `ivar' <= `nvar' {
            local c = 1
            * loop over outcome categories
            while `c' <= `ncat' {
                * 16Nov2005 1.6.8 - retrieve dc over range
                scalar `tmp' = PE_dc[`r'+1,`c']
                mat `chr'[`ivar',`c'] = `tmp'
                * 16Nov2005 1.6.8 retrieve dc from 0 to 1 (same as dc over range)
                scalar `tmp' = PE_dc[`r',`c']
                *scalar `tmp' = PE_dc[`r'+1,`c']
                mat `ch0'[`ivar',`c'] = `tmp'
                * -/+ 1
                scalar `tmp' = PE_dc[`r'+2,`c']
                mat `chu'[`ivar',`c'] = `tmp'
                * -/+ sd
                scalar `tmp' = PE_dc[`r'+3,`c']
                mat `chs'[`ivar',`c'] = `tmp'
                local c = `c' + 1
            }
            local ivar = `ivar' + 1
            local r = `r' + 5
        }
    } /* if dchange */

*=> parse variables to plot and check if dummy variable
    mat `_lpplt' = J(`maxnvar',1,0)  /* 1 if plot this coef */
    mat `isdum' = J(`maxnvar',1,0)   /* 1 if dummy variable */
    parse "`varis'",parse(" ")  /* varis==variables to be plot */
    local ntoplot = 0
    while "`1'"~="" {
        if `ntoplot' >= `maxvar' {
            di in r "only `maxvar' variables can be " /*
                */ "plotted in one graph"
            exit
        }
        * check selected name is in beta matrix
        local i 1
        local okvarn = 0
        while `i' <= `nvar' {
            * bvarnm contains names from beta matrix
            local vnm : word `i' of `bvarnm'
            if "`1'"=="`vnm'" { local okvarn = `i' }
            local i = `i' + 1
        }
        if `okvarn'==0 {
            di in red "`1' was not a variable in mlogit"
            exit
        }
        local ntoplot = `ntoplot' + 1
        if "`matrix'" ~= "matrix" {
            mat `isdum'[`ntoplot',1] = `01rhs'[1,`okvarn']
        }
        * plot variables in this order
        mat `_lpplt'[`ntoplot',1] = `okvarn'
        macro shift
    }

*=> parse standardization type for each variable

    mat `_lpstdt' = J(`maxnvar',1,0) /* Plot: 1=unstd; 3=std; 2=0/1 */
    local i 1
    local nstd = length("`std'")
    while `i' <= `nstd' {
        local stdi = substr("`std'",`i',1)

        * 16Nov2005 1.6.8 - allow r as an option for how to plot variable
        if "`stdi'"~="r" & "`stdi'"~="s" & "`stdi'"~="u" & "`stdi'"~="0" {
            di in r "std() options must be s, r, u or 0"
            *        if "`stdi'"~="s" & "`stdi'"~="u" & "`stdi'"~="0" {
            *            di in r "std() options must be s, u or 0"
            exit
        }
        mat `_lpstdt'[`i',1] = 1 /* unstd */
        if "`stdi'" == "s" {
            mat `_lpstdt'[`i',1] = 3 /* std */
        }

        * 16Nov2005 1.6.8 - if range, type 4 coefficients
        if "`stdi'" == "r" {
            mat `_lpstdt'[`i',1] = 4 /* min max */
        }

        if "`stdi'" == "0" {
             mat `_lpstdt'[`i',1] = 2 /* dummy */
             if `isdum'[`i',1]~=1 {
                di in r "variable specified as std(0) " /*
                    */ "is not a binary variable"
                exit
             }
        }
        * warning if isdum and not 0
        if `isdum'[`i',1]==1 & `_lpstdt'[`i',1]~=2 {
            local tmp = `_lpplt'[`i',1]
            local vnm : word `tmp' of `bvarnm'
            di in r "warning: variable `vnm'" /*
                */ " is binary, but std(0) was not used"
        }
        local i = `i' + 1
    }
    if `ntoplot'~=`nstd' {
        di in r "# of variables does not match # of " /*
            */ "std() values specified"
        exit
    }

*=> set up matrices with plot data

    tempname _lpbplt _lpbvar _lpbcat _lpboff _lpbtyp _lpbchk _lpbchp
    local tmp = `ntoplot' * `ncat'     /* # coefs to plot */
    matrix `_lpbplt'  = J(`tmp',1,0)   /* coef to plot */
    matrix `_lpbchp'  = `_lpbplt'      /* values of discrete change */
    matrix `_lpboff'  = `_lpbplt'      /* vertical offset */
    matrix `_lpbvar'  = `_lpbplt'      /* variable number */
    matrix `_lpbcat'  = `_lpbplt'      /* category */
    matrix `_lpbtyp'  = `_lpbplt'      /* type of standardization */

    * compute standardized betas
    mat `bstd' = `b'
    local ivar = 1
    while `ivar' < `nvarp1' {
        scalar `sdi' = `sdrhs'[1,`ivar']
        * loop over categories and fill in border
        local icat = 1
        while `icat' < `ncat' {
            mat `bstd'[`icat',`ivar'] = `b'[`icat',`ivar'] * `sdi'
            local icat = `icat' + 1
        }
        local ivar = `ivar' + 1
    }

    * 2007-06-29
    if "`matrix'" != "matrix" {
        * 16Nov2005 1.6.8 - compute beta*range
        tempname brng
        mat `brng' = `b'
        local ivar = 1
        while `ivar' < `nvarp1' {
            scalar `sdi' = `rngrhs'[1,`ivar']
            * loop over categories and fill in border
            local icat = 1
            while `icat' < `ncat' {
                mat `brng'[`icat',`ivar'] = `b'[`icat',`ivar'] * `sdi'
                local icat = `icat' + 1
            }
            local ivar = `ivar' + 1
        }
    }
    else {
        // make range missing since it is not used
        tempname brng
        mat `brng' = `bstd' * .
    } // 2007-06-29

    * determine basecategory
    if "`matrix'"~="matrix" {
        _pecats `e(depvar)'
        local catnm  "`r(catnms)'"
        * 30Mar2005 1.6.6
        if "`values'"=="values" {
            local catnm  "`r(catvals)'"
        }

        * refnum is value of the reference category for the estiamted betas
        * 2007-06-29 stata 10
        if c(stata_version) < 10 {
            local refnum = e(basecat)
        }
        else {
            local refnum = e(baseout)
        }

        * 1.7.0 08Apr2006 - fix when refnum is 0
        if `refnum'==0 {
            local refnum = 1
        }

        * names of outcome categories in order of matrix
        * all but the last correspond to the rows in b
    }

    if "`matrix'"=="matrix" {
        local catnm  "$mnlcatnm"
        local refnum "`ncat'"
    }

*=> stack b coefficients to plot into _lpbplt vector

    * determine offset for plot
    * baserow has the row in b with beta's for new base category
    local baserow = 0
    * `basecategory' has the # of the specified base
    if `basecategory'~=`refnum' & `basecategory'~=-1 {
        local baserow = `basecategory'
        if `basecategory' > `refnum' { local baserow = `baserow' - 1 }
    }
    * loop through variables, decide on std and unstd to plot
    local iloc = 1
    local ivar = 1
    while `ivar' <= `ntoplot' {
        local icat = 1
        local varnum = `_lpplt'[`ivar',1]
        * find b values for changing basecategory
        local bbase = 0
        local bbstd = 0
        * 16Nov2005 1.6.8
        local bbrng = 0

        if `baserow' ~= 0 {
            local bbase = `b'[`baserow',`varnum']
            local bbstd = `bstd'[`baserow',`varnum']
            * 16Nov2005 1.6.8
            local bbrng = `brng'[`baserow',`varnum']
        }
        * compute _lpbplt
        while `icat' <= `ncat' {
            if `icat' < `ncat' {
                matrix `_lpbplt'[`iloc',1] = `b'[`icat',`varnum'] - `bbase'
            }
            else {
                matrix `_lpbplt'[`iloc',1] = 0  - `bbase'/* ref category */
            }
            matrix `_lpbtyp'[`iloc',1] = 1
            matrix `_lpbchp'[`iloc',1] = `chu'[`varnum',`icat']
            if `_lpstdt'[`ivar',1] == 2 {
                matrix `_lpbtyp'[`iloc',1] = 2
                matrix `_lpbchp'[`iloc',1] = `ch0'[`varnum',`icat']
            }
            if `_lpstdt'[`ivar',1] == 3 {
                if `icat' < `ncat' {
                    matrix `_lpbplt'[`iloc',1] = /*
                        */ `bstd'[`icat',`varnum'] - `bbstd'
                }
                else {
                    matrix `_lpbplt'[`iloc',1] = /*
                        */ 0 - `bbstd' /* reference category */
                }
                matrix `_lpbtyp'[`iloc',1] = 3
                matrix `_lpbchp'[`iloc',1] = `chs'[`varnum',`icat']
            }

            * 16Nov2005 1.6.8 - coefficients when change over range
            if `_lpstdt'[`ivar',1] == 4 {
                if `icat' < `ncat' {
                    matrix `_lpbplt'[`iloc',1] = /*
                        */ `brng'[`icat',`varnum'] - `bbrng'
                }
                else {
                    matrix `_lpbplt'[`iloc',1] = /*
                        */ 0 - `bbrng' /* reference category */
                }
                matrix `_lpbtyp'[`iloc',1] = 4
                matrix `_lpbchp'[`iloc',1] = `chr'[`varnum',`icat']
            }

            * _lpbplt now has coefficients to be plotted
            matrix `_lpbvar'[`iloc',1] = `ivar' /* var# for given coef */
            matrix `_lpbcat'[`iloc',1] = `icat' /* cat# for tiven coef */
            local iloc = `iloc' + 1
            local icat = `icat' + 1
            }
        local ivar = `ivar' + 1
    }

    if `dcplot' == 1 { /* dcplot , so plot _lpbchp */
        matrix `_lpbplt' = `_lpbchp'
    }

*=> determine offsets for letters

*   algorithm is use offsets of 0,1,2,0,1,2 as coefficients are ordered
*   from smallest to largerst.  The code is messy, but works...

    * if packed, use 0's already in _lpboff
    if "`packed'" ~= "packed" {
        local iloc = 1
        local ivar = 1
        while `ivar' <= `ntoplot' {
            local varnum = `_lpplt'[`ivar',1]
            * grab coefficients for given variable in _lpbplt
            local istrt = ((`ivar'-1)*`ncat') + 1
            local iend = `istrt' + `ncat' - 1
            matrix `_lpbchk' = `_lpbplt'[`istrt'..`iend',1]
            local icat = 1
            while `icat' <= `ncat' {
                local icat2 = 1
                local minn = 99999999
                * find smallest coef that hasn't been used
                while `icat2' <= `ncat' {
                    if `_lpbchk'[`icat2',1] < `minn' {
                        local minn = `_lpbchk'[`icat2',1]
                        local minloc = `icat2'
                    }
                    local icat2 = `icat2' + 1
                }
                * this is current smallest
                local updown = mod(`icat'+2,3)
                * change to big values so won't select again
                mat `_lpbchk'[`minloc',1] = 99999999
                local minn = 99999999
                * this is the location in the stored variables
                local ichng = `istrt' + `minloc' - 1
                mat `_lpboff'[`ichng',1] = `updown'
                local iloc = `iloc' + 1
                local icat = `icat' + 1
            }
            local ivar = `ivar' + 1
        }
    }

*=> create variables from the matrices

    mat colnames `_lpbplt' = _lpbplt
    mat colnames `_lpbvar' = _lpbvar
    mat colnames `_lpbcat' = _lpbcat
    mat colnames `_lpboff' = _lpboff
    mat colnames `_lpbtyp' = _lpbtyp
    mat colnames `_lpbchp' = _lpbchp
    mat colnames `_lpplt' = _lpplt
    mat colnames `_lpstdt' = _lpstdt

    svmat `_lpbplt', names(col)
    svmat `_lpbvar', names(col)
    svmat `_lpbcat', names(col)
    svmat `_lpboff', names(col)
    svmat `_lpbtyp', names(col)
    svmat `_lpbchp', names(col)
    svmat `_lpplt', names(col)
    svmat `_lpstdt', names(col)

*=> generate variable with first letter of category names

    if "`matrix'"~="matrix" {
        local ltr : word `refnum' of `catnm'
        local ltr = upper(substr("`ltr'",1,1))
        quietly generate str1 _lpbltr = "`ltr'"
        local icat = 1
        while `icat' <= `ncat' {
            if `icat'==`refnum' {
                local refnm: word `ncat' of `catnm'
                if `baserow'~=0 {
                    local refnm: word `baserow' of `catnm'
                }
            }
            if `icat'!=`refnum' {
                local nm: word `icat' of `catnm'
                local ltr = upper(substr("`nm'",1,1))
                quietly replace _lpbltr = "`ltr'" if _lpbcat == `icat'
            }
            local icat = `icat' + 1
        }
    }

    if "`matrix'"=="matrix" {
        * this is the reference category in the betas
        local ltr : word `ncat' of `catnm'
        local ltr = upper(substr("`ltr'",1,1))
        quietly generate str1 _lpbltr = "`ltr'"
        * get letter for reference category
        local baserow = `basecategory'
        if `baserow' == -1 { local baserow = `ncat' }
        local refnm : word `baserow' of `catnm'
        * place correct letters to plot
        local icat = 1
        while `icat' <= `ncat' {
            if `icat'!=`refnum' {
                local nm: word `icat' of `catnm'
                local ltr = upper(substr("`nm'",1,1))
                quietly replace _lpbltr = "`ltr'" if _lpbcat == `icat'
            }
            local icat = `icat' + 1
        }
    }

*=> data to pass to plot program

    global S_1 = `dcplot'
    global S_2 = `min'
    global S_3 = `max'
    global S_4 "`packed'"
    global S_5 = `ntoplot'
    global S_6 = `dcadd'
    global S_7 = `dcbase'
    global S_8 = `ncat'
    global S_9 "`labels'"
    global S_10 "`dchange'"
    global S_11 "`bvarnm'"
    global S_12 = `prob'
    global S_13 "`refnm'"
    global S_14 = `ntics'
    global S_15 "`note'"
    global S_16 "`depvar'"
    global S_17 "`gphopen'"
    * 16Nov2005 sign
    global S_18 = 0
    if "`sign'"=="sign" {
        global S_18 = 1
    }
    lp_plt
    capture drop _lpbplt-_lprowb
end

program define lp_plt
    * decode information from calling program
    local dcplot = $S_1
    local min = $S_2
    local max = $S_3
    local packed "$S_4"
    local ntoplot = $S_5
    local dcadd = $S_6
    local dcbase = $S_7
    local ncat = $S_8
    local labels "$S_9"
    local dchange "$S_10"
    local bvarnm "$S_11"
    local prob = $S_12
    local refnm "$S_13"
    local ntics = $S_14
    local note "$S_15"
    local depvar "$S_16"
    local gphopen "$S_17"
    * 16Nov2005 sign
    local addsign = $S_18

    * coordinate used:
    *
    *   (0,0)       (0,cstrt)                   (0,cend)
    *
    *               (rhead,cstrt)      data     (rhead,cend)
    *
    *               (rhead+rvar,cstrt)          (rhead+rvar,cend)
    *
    local cstrt  = 10000            /* first column in plot space */
    local cborder = 1000            /* border at ends of plot space */
    local cend   = 31500            /* right most column of plot space */
    local crange = `cend' - `cstrt' - (2*`cborder')
    local cname  = `cstrt' - 700    /* name of variable ends here */
    *local rhead  = 2000             /* header space for factor change scale */
    local rhead  = 1800             /* header space for factor change scale */
    if `dcplot'==1 { local rhead = 1000 }
    if "`note'"~="" {
        local rhead = `rhead' + 1000
    }

    * rows per variable in plot space
    * local rvar   = 3600 /* maxvar = 5 */
    * local rvar   = 3200 /* maxvar = 6 */
    local rvar   = 2800 /* maxvar = 7 */

    if "`packed'" == "packed" { local rvar = 1700 }

    local rnmoff = 1000 - `rvar'    /* vert offset for listing name */

    * vert offset within horizontal lines (larger adds vertical compression
    local rltoff = 800

    * rescale to metric used in columns of plot and find 0 location
    quietly sum _lpbplt /* get min and max of coefficients being plotted */
    local minb = _result(5)
    if `min'~=-99999 & `min'<`minb' { local minb = `min' }
    local maxb = _result(6)
    if `max'~=99999 & `max'>`maxb' { local maxb = `max' }
    local rng = `maxb' - `minb'
    * change range to [0-1]
    quietly generate _lpcolb = (_lpbplt - `minb')/`rng'
    local c0 = (0 - `minb')/`rng'
    * min and max column for plotting area
    local minn = `cstrt' + `cborder'
    local maxx = `cend' - `cborder'
    local rng = `maxx' - `minn'
    quietly replace _lpcolb = (_lpcolb * `rng') + `minn'
    local c0 = (`c0' * `rng') + `minn'

    * rescale metric for rows in plot
    * # of rows to contain letters
    local rltr = `rvar' - `rltoff' - `rltoff'
    if "`packed'" ~= "packed" {
        quietly sum _lpboff
        local minn = _result(5)
        local maxx = _result(6)
        local rng = `maxx' - `minn'
        * change to range of 0--1
        quietly generate _lprowb = (_lpboff - `minn')/`rng'
        * expand to range of rltr
        quietly replace _lprowb = _lprowb * `rltr' /* offsets as # of rows */
        * determine row position
        #delimit ;
        quietly replace _lprowb = _lprowb
            + `rhead'               /* skip over header */
            + ((_lpbvar-1)*`rvar')  /* space over prior variables */
            + `rltoff'              /* space before letters begin */
            ;
        #delimit cr
        quietly sum _lprowb
    }
    else if "`packed'" == "packed" {
        local rltoff = 925       /* vert offset top & bot for letters */
        * determine row position
        #delimit ;
        quietly generate _lprowb = `rhead'  /* skip over header */
            + ((_lpbvar-1)*`rvar')          /* space over prior variables */
            + `rltoff'                      /* space before letters begin */
            ;
        #delimit cr
    }

    `gphopen'
    gph font 600 300
    if "`note'"~="" {
        local tmp = `cstrt' - 400
        gph text 480 `tmp' 0 -1 `note'
    }
    local rloc = `rhead' - 200
    * axis at top of graph
    gph line `rloc' `cstrt' `rloc' `cend'
    * add labels at top and bottom
    gph font 500 250
    local rloc = `rhead' - 1400
    if `dcplot' == 0 {
        local ltr "`refnm'"
        * move top label down a smidge
        local rloctmp = `rloc' + 250
        gph text `rloctmp' `cstrt' 0 -1 /*
            */ Factor Change Scale Relative to Category `ltr'
        local rloc = `rhead' + (`ntoplot'*`rvar') + 1200
        local tmp ""
        * if "`depvar'" ~= "" { local tmp " of `depvar'" }
        local ltr "`refnm' `tmp'"
        gph text `rloc' `cstrt' 0 -1 /*
            */ Logit Coefficient Scale Relative to Category `ltr'
    }
    if `dcplot' == 1 {
        local rloc = `rhead' + (`ntoplot'*`rvar') + 1200
        *! version 1.6.5 2/24/2003 - correct typo in graph
        local tmp "Change in Predicted Probability for $S_16"
        gph text `rloc' `cstrt' 0 -1 `tmp'
    }
    * add tic marks
    local nper = (`maxb' - `minb')/(`ntics' - 1)
    local itic = 1
    local minn = `cstrt' + `cborder'
    local maxx = `cend' - `cborder'
    local cper = (`maxx' - `minn')/(`ntics' - 1)
    while `itic' <= `ntics' {
        local ticval : display round(exp(`minb' + ((`itic'-1)*`nper')),.01)
        local cval = `minn' + ((`itic'-1)*`cper')
        local rloc = `rhead' - 600
        * write tic value at top
        local rloctmp = `rloc' + 200 /* move it down a smidge */
        if `dcplot' ==0 { gph text `rloctmp' `cval' 0 0 `ticval' }
        * add tic marks
        local rlst = `rhead' - 200
        local rlend = `rlst' + 150
        gph line `rlst' `cval' `rlend' `cval'
        local rlst = `rhead' + (`ntoplot'*`rvar') - 200
        local rlend = `rlst' - 150
        gph line `rlst' `cval' `rlend' `cval'
        local ticval : display round(`minb' + ((`itic'-1)*`nper'),.01)
        local itic = `itic' + 1
        local rloc = `rhead' + (`ntoplot'*`rvar') + 400
        gph text `rloc' `cval' 0 0 `ticval'
    }
    local rloc = `rhead' + (`ntoplot'*`rvar') - 200
    gph line `rloc' `cstrt' `rloc' `cend'
    if `dcplot' == 1 {
        local rt = `rhead' - 200
        gph line `rt' `c0' `rloc' `c0'
    }

    * plot letters
    local i 0
    local ivar 1
    local dcbase = sqrt(`dcbase')
    while `ivar' <= `ntoplot'  {      /* loop over variables */
        local icat 1
        while `icat' <= `ncat' {      /* loop over categories within vars */
            local i = `i' + 1
            * get point to plot
            local r = _lprowb[`i']
            local c = _lpcolb[`i']
            local l = _lpbltr[`i']
            local siz 1
            if "`dchange'" == "dchange" & `dcplot' == 0 {
                local siz = sqrt(`dcadd'+abs(_lpbchp[`i']))/`dcbase'
            }
            local fr = `siz'*700
            local fc = `siz'*350
            gph font `fr' `fc'

            * 16Nov2005 option sign
            if _lpbchp[`i']<0 & `addsign'==1 {
                gph text `r' `c' 0 0 _
                *    local l "-`l'"
            }

            gph text `r' `c' 0 0 `l'
            local icat = `icat' + 1
        }
        local ivar = `ivar' + 1
    }

    * add names and dividing lines
    local ivar = 1
    while `ivar' <= `ntoplot' {
        * name of variable
        local varnum = _lpplt[`ivar']
        if `dcplot' == 0 & `prob'~= 1 {
        * get prob values
            global S_1 = `varnum' /* variable number */
            global S_2 = `ncat'
            getprob
            local cat1 2
            while `cat1' <= `ncat' {
            * location in data set of coordinates for this coef
                local loc1 = ((`ivar'-1)*`ncat')+`cat1'
                local r1 = _lprowb[`loc1']
                local c1 = _lpcolb[`loc1']
                local cat2 1
                while `cat2' < `cat1' {
                    local loc2 = ((`ivar'-1)*`ncat')+`cat2'
                    local r2 = _lprowb[`loc2']
                    local c2 = _lpcolb[`loc2']
                    local p = mlplt_p[`cat1',`cat2']
                    if `p' > `prob' { gph line `r1' `c1' `r2' `c2' }
                    local cat2 = `cat2' + 1
                } /* `cat2' < `cat1' */
            local cat1 = `cat1' + 1
            } /* `cat1' < `ncat' */
        } /* if get prob */
        local vname: word `varnum' of `bvarnm'
        if "`labels'" == "labels" & "`matrix'"~="matrix" {
            local vname2 : variable label `vname'
            if "`vname2'"!="" { local vname "`vname2'"}
        }
        local rloc = `rhead' + `rnmoff' + (`ivar'*`rvar')
        gph font 700 350
        local _lpstdt = _lpstdt[`ivar']
        if "`packed'" == "packed" {
            if `_lpstdt' == 3 {
                gph text `rloc' `cname' 0 1 `vname'-std
            }
            else if `_lpstdt' == 2 {
                gph text `rloc' `cname' 0 1 `vname'-0/1
            }
            else if `_lpstdt' == 1 {
                gph text `rloc' `cname' 0 1 `vname'
           }
            * 16Nov2005 1.6.8 - label for dc over range
            else if `_lpstdt' == 4 {
                gph text `rloc' `cname' 0 1 `vname'-range
            }
        }
        if "`packed'" ~= "packed" {
            gph text `rloc' `cname' 0 1 `vname'
            gph font 400 200
            local rloc = `rhead' + `rnmoff' + (`ivar'*`rvar') + 900
            if `_lpstdt' == 1 {
                gph text `rloc' `cname' 0 1 UnStd Coef
            }
            if `_lpstdt' == 2 {
                gph text `rloc' `cname' 0 1 0/1
            }
            if `_lpstdt' == 3 {
                gph text `rloc' `cname' 0 1 Std Coef
            }
            * 16Nov2005 1.6.8 - label for or over range
            else if `_lpstdt' == 4 {
                gph text `rloc' `cname' 0 1 Range Coef
            }
        }
        * dividing line
        if `ivar' != 1 {
            local rloc = `rhead' + ((`ivar'-1)*`rvar') - 200
            gph line `rloc' `cstrt' `rloc' `cend'
        }
        local ivar = `ivar' + 1
    }
    gph close
end

program define getprob
    * get the prob values for all contrasts
    version 5.0
    tempname b v b1 b2 b12 se z p
    local ivar = $S_1
    local ncat = $S_2
    matrix `b' = get(_b)
    local nvars = colsof(`b')
    mat `v' = get(VCE)
    * 2009-10-28 - fix for stata 11 returns
    nobreak {
        _get_mlogit_bv `b' `v'
        local nvars = colsof(`b')
    }
/* TEST
    di "nvars: `nvars'"
    di "ncat: `ncat'"
    di "v with fix"   
    mat list `v'
    di "b with fix"
    mat list `b' 
END TEST */    
    matrix mlplt_p = J(`ncat',`ncat',1)
    * loop through all pairs of categories
    local cat1 1
    local cat2 1
    while `cat1' <= `ncat' {
        while `cat2' <= `cat1' {
            if `cat1'!=`cat2' {
                * 1st element of contrast is not ref cat
                if `cat1'!=`ncat' {
                    if `cat2'==`ncat' { scalar `b2' = 0 }
                    else { scalar `b2' = `b'[`cat2',`ivar'] }
                    scalar `b1' = `b'[`cat1',`ivar']
                    scalar `b12' = `b1'-`b2'
                    local loc2 = ((`cat2'-1)*`nvars')+`ivar'
                    if `cat2'==`ncat' {
                        scalar `se' = sqrt(`v'[`loc1',`loc1'])
                    }
                    else {
                        local loc1 = ((`cat1'-1)*`nvars')+`ivar'
                        scalar `se' = sqrt(`v'[`loc1',`loc1'] + /*
                        */ `v'[`loc2',`loc2'] - 2*`v'[`loc1',`loc2'])
                    }
                } /* `cat1'!=`ncat' */
                * first element of contrast is reference category
                if `cat1'==`ncat' {
                    if `cat2'==`ncat' { scalar `b2' = 0 }
                    else { scalar `b2' = `b'[`cat2',`ivar'] }
                    scalar `b1' = 0 /*`b'[`cat1',`ivar']*/
                    scalar `b12' = `b1'-`b2'
                    local loc2 = ((`cat2'-1)*`nvars')+`ivar'
                    scalar `se' = sqrt(`v'[`loc2',`loc2'])
                }
                scalar `se' = 1/`se'
                scalar `z' = `se'*`b12'
                scalar `p' = 2*normprob(-abs(`z'))
                matrix mlplt_p[`cat1',`cat2'] = `p'
                matrix mlplt_p[`cat2',`cat1'] = `p'
            } /* if `cat1'!=`cat2' */
        local cat2 = `cat2' + 1
        } /* while `cat2' <= `ncat' */
    local cat2 1
    local cat1 = `cat1' + 1
    } /* cat1 */

end
exit

* version 1.6.4 3/22/2001
* version 1.6.5 2/24/2003 - correct typo in graph
* version 1.6.6 30Mar2005 - add values option
* version 1.6.7 13Apr2005
* version 1.6.8 allow plots for change over range 16Nov2005
*       add: option sign: underline negative discrete change
*            option r   : for range
* version 1.6.9 error if outcome cat <= 0
* version 1.7.0 08Apr2006 fixed when basecategory is 0!
* version 1.7.1 26Nov2006
*       improve error message when prchange is a problem.
* version 1.7.2 29Jun2007 // fix range problem if data is a matrix
* version 1.7.3 29Jun2007 // stata 10 revisions
