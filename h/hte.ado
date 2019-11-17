*! version 1.0.8  23feb2010  Ben Jann, Jennie E. Brand, Yu Xie

program hte, rclass
    version 9.2
    syntax [anything(equalok)] [if] [in] [fw iw pw] [, * ]
    if replay() {
        hte_tabulate `0'
        exit
    }
    gettoken first second : anything
    local flen = strlen(`"`first'"')
    if `"`first'"'==substr("graph",1,max(2,`flen')) & `"`second'"'=="" {
        hte_graph `if' `in' [`weight'`exp'], `options'
        exit
    }
    hte_compute `anything' `if' `in' [`weight'`exp'], `options'
end

program hte_graph
    syntax [, Level(cilevel) Outcomes(numlist integer min=1) noCI * ]
    local z = invnorm((100+`level')/200)

    if `"`e(cmd)'"'!="hte" {
        di as err "hte results not found"
        exit 301
    }

    _get_gropts , graphopts(`options') getallowed(LINEOPts CIOPts plot addplot)
    local options `"`s(graphopts)'"'
    local lineopts `"`s(lineopts)'"'
    local ciopts `"`s(ciopts)'"'
    _check4gropts lineopts, opt(`lineopts')
    _check4gropts ciopts, opt(`ciopts')
    local plot `"`s(plot)'"'
    local addplot `"`s(addplot)'"'

    tempname b se block lfit coefs tmp
    mat `b'     = e(b)
    mat `se'    = e(se)
    mat `block' = e(block)
    mat `lfit'  = e(lfit)
    local neq   = e(neq)
    if "`outcomes'"=="" {
        if `neq'==1 local outcomes "_"
        else {
            numlist "1/`neq'"
            local outcomes "`r(numlist)'"
        }
    }
    else if `neq'==1 {
        local outcomes: subinstr local outcomes "1" "_", word all
    }
    foreach eq of local outcomes {
        mat `tmp' = `b'[1...,`"`eq':"']', `se'[1...,`"`eq':"']' // => error if outcome not found
        mat `tmp' = `tmp'[1..rowsof(`tmp')-2,1...], ///
            `block'[1...,`"`eq':"']', `lfit'[1...,`"`eq':"']'
        mat `coefs' = nullmat(`coefs') \ `tmp'
    }
    tempname B SE ID FIT touse
    mat coln `coefs' = `B' `SE' `ID' `FIT'
    svmat `coefs', names(col)
    qui gen byte `touse' = `ID'<.

    local depvar `"`e(depvar)'"'
    local ndepvar : list sizeof depvar
    local hasby = (`"`e(byvar)'"'!="")
    if `:list sizeof outcomes'==1 {
        local Bvars   `B'
        local FITvars `FIT'
        lab var `B'     "TE within strata"
        lab var `FIT'   "linear trend"
        if "`ci'"==""   {
            tempname LB UB
            qui gen `LB' = `B' - `z'*`SE'
            qui gen `UB' = `B' + `z'*`SE'
            local CIgraph (rcap `LB' `UB' `ID' if `touse', `ciopts')
            local legend legend(label(1 "`level'% CI"))
        }
        local title
        if `neq'>1 {
            if `ndepvar'>1 {
                local title `"`e(depvar`outcomes')'"'
                if `hasby' {
                    local title `"`title': "'
                }
            }
            if `hasby' {
                local title `"`title'`e(byvar)' = `e(by`outcomes')'"'
            }
            local title `"title(`title')"'
            local trend subtitle(`"`e(trend`outcomes')'"')
        }
        else {
            local trend subtitle(`"`e(trend)'"')
        }
    }
    else {
        local eqlist: roweq `coefs'
        local k = rowsof(`coefs')
        tempname by
        qui gen byte `by' = .
        forv i = 1/`k' {
            gettoken eq eqlist : eqlist
            qui replace `by' = `eq' in `i'
        }
        local i 0
        foreach eq of local outcomes {
            local ++i
            tempname B_`i' FIT_`i' LB_`i' UB_`i'
            qui gen `B_`i''   = `B'     if `by'==`eq'
            qui gen `FIT_`i'' = `FIT'   if `by'==`eq'
            local eqlab
            if `ndepvar'>1 {
                local eqlab `"`e(depvar`eq')'"'
                if `hasby' {
                    local eqlab `"`eqlab': "'
                }
            }
            if `hasby' {
                local eqlab `"`eqlab'`e(byvar)' = `e(by`eq')'"'
            }
            lab var `B_`i''   `"`eqlab'"'
            lab var `FIT_`i'' `"`eqlab'"'
            local Bvars   `Bvars' `B_`i''
            local FITvars `FITvars' `FIT_`i''
            local pstyles `pstyles' p`i'
            local legend `legend' `=`neqs'+`i''
        }
        local pstyles pstyle(`pstyles')
        local legend legend(order(`legend'))
    }
    su `ID', mean
    local xlabel "xlabel(1(1)`r(max)')"
    if r(max)==1 local xlabel // fix stata graph bug

    local Lgraph (line `FITvars' `ID' if `touse', `pstyles' `lineopts')
    graph twoway                                    ///
        `CIgraph'                                   ///
        (scatter `Bvars' `ID' if `touse',           ///
            `pstyles'                               ///
            `xlabel'                                ///
            xvarlabel("Propensity Score Strata")    ///
            ytitle("Treatment Effect")              ///
            `legend' `title' `trend'                ///
            `options'                               ///
        )                                           ///
        `Lgraph'                                    ///
        || `plot' || `addplot'                      ///
        // blank
end

program hte_tabulate
    capt syntax [, Level(cilevel) ]
    if `"`e(cmd)'"'!="hte" {
        di as err "hte results not found"
        exit 301
    }
    local z = invnorm((100+`level')/200)
    tempname b se
    mat `b' = e(b)
*    capt confirm matrix e(V)
*    if _rc | e(vce)=="bootstrap" {
        mat `se' = e(se)
*    }
*    else { // needed for jackknife, but not for bootstrap
*        mat `se' = vecdiag(e(V))
*        forv i=1/`=colsof(`se')' {
*            mat `se'[1,`i'] = sqrt(`se'[1,`i'])
*        }
*    }
    local namelist : colname `b'
    local eqlist : coleq `b'
    local k = colsof(`b')
    local depvar `"`e(depvar)'"'
    local hasby = (`"`e(byvar)'"'!="")
    di as txt _n _col(56) "Number of obs =" as res %8.0g  e(N)
    local topline as txt "{hline 13}{c TT}{hline 64}"
    local headline as txt %12s abbrev(`"\`depv'"',12) " {c |}" %11s "Coef." ///
        %12s "Std. Err." %8s "z " %8s "P>|z|" %25s "[`level'% Conf. Interval]"
    local sepline as txt "{hline 13}{c +}{hline 64}"
    local botline as txt "{hline 13}{c BT}{hline 64}"
    local legend as txt "TE = treatment effect"
    local eqlabstrata as res %-12s "TE by strata" as txt " {c |}" %64s ""
    local eqlabtrend as res %-12s "Linear trend" as txt " {c |}" %64s ""
    local eq0
    forv i = 1/`k' {
        gettoken name namelist : namelist
        gettoken eq eqlist : eqlist
        if "`eq'"!="`eq0'" {
            local eq0 "`eq'"
            if `i'>1 {
                di `botline'
                di ""
            }
            if "`eq'"=="_"  local depv `"`depvar'"'
            else            local depv `"`e(depvar`eq')'"'
            if `hasby' {
                di as res `"-> `e(byvar)' = `e(by`eq')'"'
            }
            di `topline'
            di `headline'
            di `sepline'
            di `eqlabstrata'
        }
        if `"`name'"'=="_slope" {
            di `sepline'
            di `eqlabtrend'
        }
        local t = `b'[1,`i']/`se'[1,`i']
        di as txt %12s abbrev(`"`name'"',12) " {c |}" ///
            "  "   as res %9.0g `b'[1,`i'] ///
            "  "   as res %9.0g `se'[1,`i'] ///
            "  "   as res %7.2f `t' ///
            "   "  as res %5.3f 2*norm(-abs(`t')) ///
            "    " as res %9.0g `b'[1,`i']-`se'[1,`i']*`z' ///
            "   "  as res %9.0g `b'[1,`i']+`se'[1,`i']*`z'
    }
    di `botline'
    di `legend'
end

program hte_compute
    local stdopts ///
        by(passthru) SEParate NOIsily Level(passthru) CASEwise LISTwise Replace ///
        join(passthru) AUTOjoin AUTOjoin2(passthru) _blockid(passthru) /// _blockid() undocumented
        ALpha(passthru) pscore(passthru) blockid(passthru) logit comsup numblo(passthru) DETail  /// pscore opts
        CONtrols(passthru) ESTcom(passthru) ESTOPts(passthru)  /// regress options
        // blank
    syntax anything(equalok id="varlist") [if] [in] [fw iw pw] [, `stdopts' noGRaph * ]
    if "`graph'"!="" {
        syntax anything(equalok id="varlist") [fw iw pw] [if] [in] [, `stdopts' noGRaph ]
    }
    if "`detail'"!="" local noisily noisily

    gettoken depvar varlist : anything, parse("=")  // Parse "y1 [ y2 y3 ... = ] x1 x2 ..."
    if `"`depvar'"'=="=" {
        di as err "depvar required"
        exit 198
    }
    else if `"`varlist'"'!="" {
        gettoken junk varlist : varlist, parse("=") // get rid of "="
    }
    else {
        gettoken depvar varlist : anything          // just one depvar
    }

    capt which pscore
    if _rc {
        di as err "-pscore- is required. To install, type: " ///
            `"{stata "net install st0026_2, from(http://www.stata-journal.com/software/sj5-3)"}"'
        exit _rc
    }

    _hte_compute `varlist' `if' `in' [`weight'`exp'], depvar(`depvar')          ///
        `by' `separate' `noisily' `casewise' `listwise' `replace'               ///
        `join' `autojoin' `autojoin2' `_blockid'                                ///
        `alpha' `pscore' `blockid' `logit' `comsup' `numblo' `detail'           ///
        `controls' `estcom' `estopts'

    hte_tabulate , `level'

    if "`graph'"=="" {
        hte_graph , `level' `options'
    }
end

program _hte_compute, eclass
    syntax varlist(numeric) [if] [in] [fw iw pw] , depvar(varlist numeric) [ ///
        by(varname) SEParate NOIsily CASEwise LISTwise Replace ///
        join(str) AUTOjoin AUTOjoin2(passthru) _blockid(varname) /// _blockid() undocumented
        ALpha(passthru) pscore(name) blockid(name) logit comsup numblo(passthru) DETail /// pscore opts
        CONtrols(str) ESTcom(str) ESTOPts(passthru) /// regress options
        ]
    if "`autojoin2'"!="" local autojoin autojoin
    foreach opt in alpha join autojoin {
        if "`_blockid'"!="" & `"``opt''"'!="" {
            di as err "`opt'() not allowed with _blockid()"
            exit 198
        }
    }
    if "`_blockid'"!="" & `"`pscore'`blockid'`logit'`comsup'`numblo'"'!="" {
        di as err "{it:pscore_options} not allowed with _blockid()"
        exit 198
    }
    if `"`estcom'"'=="" local estcom regress
    ParseJoin `join' // returns local join
    if `"`controls'"'!="" {
        ParseControls `controls'
    }
    if "`listwise'"!="" local casewise casewise
    if "`replace'"=="" {
        foreach var in `pscore' `blockid' {
            confirm new var `var'
        }
    }

    // mark obs
    gettoken treatvar indepvars : varlist
    marksample touse
    if "`casewise'"!="" {
        markout `touse' `depvar' `controlvars'
    }
    if "`by'"!="" {
        markout `touse' `by', strok
    }
    if "`_blockid'"!="" {
         markout `touse' `_blockid', strok
    }
    tab `treatvar' if `touse', nofreq
    if r(N)==0 error 2000
    if r(r)!=2 {
        if r(r)>2 di as err "more than 2 groups found in treatvar, only 2 allowed"
        else      di as err "less than 2 groups found in treatvar, 2 required"
        exit 420
    }

    // compute treatment effects
    local ndepvar : list sizeof depvar
    if "`by'"!="" {
        qui levelsof `by' if `touse', local(bygrps)
        local byvar `by'
        local nby: list sizeof bygrps
    }
    else {
        local byvar  1
        local bygrps 1
        local nby    1
    }
    local neq = `ndepvar' * `nby'
    if "`_blockid'"!="" {
        local idvar `_blockid'
    }
    else {
        tempvar psvar idvar
        qui gen      `psvar' = .
        qui gen byte `idvar' = .
    }
    if `"`separate'"'=="" & "`_blockid'"=="" {
        _hte_compute_pstrata `varlist' if `touse' [`weight'`exp'], ///
            pscore(`psvar') blockid(`idvar') ///
            `noisily' `join' `autojoin' `autojoin2' ///
            `alpha' `logit' `comsup' `numblo' `detail'
    }
    tempname b se obs block lfit tmp
    local j 0
    local i 0
    foreach depv of local depvar {
        local ++j
        if `ndepvar'>1 {
            qui `noisily' di as res _n `"-> Outcome variable is: `depv'"'
        }
        gettoken byi rest : bygrps, quotes
        while (`"`byi'"'!="") {
            local ++i
            if "`by'"!="" {
                qui `noisily' di as res _n `"-> Results for `by' == `byi':"'
            }
            if `"`separate'"'!="" & "`_blockid'"=="" & `j'==1 {
                _hte_compute_pstrata `varlist' if `touse' & `byvar'==`byi' [`weight'`exp'], ///
                    pscore(`psvar') blockid(`idvar') ///
                    `noisily' `join' `autojoin' `autojoin2' ///
                    `alpha' `logit' `comsup' `numblo' `detail'
            }
            __hte_compute `varlist' if `touse' & `byvar'==`byi' [`weight'`exp'], ///
                depvar(`depv') estcom(`estcom') blockid(`idvar') ///
                `noisily' `controls' `estopts'
            foreach m in b se obs block lfit {
                mat `tmp' = r(`m')
                if `neq'>1 {
                    mat coleq `tmp' = "`i'"
                }
                mat ``m'' = nullmat(``m'') , `tmp'
            }
            gettoken byi rest : rest, quotes
        }
    }

    // returns
    local wtype = cond("`weight'"=="pweight", "aweight", "`weight'")
    su `touse' if `touse' [`wtype'`exp'], mean
    local nobs = r(N)
    ereturn post `b', obs(`nobs') esample(`touse')
    ereturn scalar neq = `neq'
    ereturn local wexp "`exp'"
    ereturn local wtype "`weight'"
    if "`by'"!="" {
        capt confirm str var `by'
        local bynotstr = _rc
        ereturn local byvar `by'
    }
    if `ndepvar'>1 | "`by'"!="" {
        local i 0
        foreach depv of local depvar {
            gettoken byi rest : bygrps, quotes
            while (`"`byi'"'!="") {
                local ++i
                ereturn local depvar`i' `depv'
                if "`by'"!="" {
                    if `bynotstr' {
                        local byi: label (`by') `byi'
                        local byi `"`"`byi'"'"'
                    }
                    ereturn local by`i' `byi'
                }
                local slope: di %5.3f [`i']_b[_slope]
                local slope_se: di %5.3f `se'[1, colnumb(`se', `"`j':_slope"')]
                ereturn local trend`i' `"slope of linear trend (s.e.) = `slope' (`slope_se')"'
                gettoken byi rest : rest, quotes
            }
        }
        assert (`neq'==`i') // must be equal
    }
    else {
        local slope: di %5.3f _b[_slope]
        local slope_se: di %5.3f `se'[1, colnumb(`se', "_slope")]
        ereturn local trend `"slope of linear trend (s.e.) = `slope' (`slope_se')"'
    }
    ereturn local controls  `controls'
    ereturn local indepvars `indepvars'
    ereturn local treatvar  `treatvar'
    ereturn local depvar    `depvar'
    ereturn local estcom    `estcom'
    ereturn local cmd "hte"
    foreach mat in lfit block obs se {
        ereturn matrix `mat' = ``mat''
    }
    if "`pscore'"!="" {
        Vreturn `psvar' `pscore' `replace'
    }
    if "`blockid'"!="" {
        Vreturn `idvar' `blockid' `replace'
    }
    // total N vs. N_comsup (or return N_outofsup)
end

program Vreturn
    args oldname newname replace
    if "`replace'"!="" {
        capt confirm var `newname', exact
        if !_rc drop `newname'
    }
    rename `oldname' `newname'
end

program ParseJoin
    gettoken nlist rest : 0, parse(",")
    while (`"`nlist'"'!="") {
        capt numlist `"`nlist'"', integer range(>0) min(2) sort
        if _rc {
            di as err `"join(): numlist invalid"'
            exit 198
        }
        local nlist `"`r(numlist)'"'
        gettoken last nlist0 : nlist
        foreach num of local nlist0 {
            if `num'!=`last'+1 {
                di as err "join(): numlist not consecutive"
                exit 198
            }
            local last `num'
        }
        local dis: list fulllist & nlist
        if `"`dis'"'!="" {
            di as err "join(): numlists not disjunctive"
            exit 198
        }
        local fulllist : list fulllist | nlist
        local join "`join'`comma'`nlist'"
        local comma ", "
        gettoken nlist rest : rest, parse(",") // get rid of the comma
        gettoken nlist rest : rest, parse(",")
    }
    if `"`join'"'!="" {
        local join join(`join')
    }
    c_local join `join'
end

program ParseControls
    local S 0       // number of set
    local vtmp      // hold varlist
    local stmp      // hold strata numbers
    local 0: subinstr local 0 "," " ", all // allow comma separated list
    gettoken chunk rest : 0, parse(" :")
    local colonok 0
    local vlistok 1
    local nlistok 1
    while `"`chunk'"'!="" {
        gettoken dash : rest, parse("-")
        if `"`dash'"'=="-" {   // bind x - y
            gettoken dash rest : rest, parse("-")
            gettoken dash rest : rest, parse(" :")
            local chunk `"`chunk'-`dash'"'
        }
        if `"`chunk'"'==":" {
            if `colonok'==0 {
                di as err "invalid controls()"
                exit 198
            }
            local colonok 0
            local vlistok 1
            local nlistok 0
            gettoken chunk rest : rest, parse(" :")
            local ++S  // next set
            continue
        }
        capt unab v : `chunk'
        if _rc==0 | _rc==111 {
            if `vlistok'==0 {
                di as err "invalid controls()"
                exit 198
            }
            if _rc==111 {
                di as err "invalid controls(): " _c
                unab v : `chunk', name(controls())
                exit _rc // not needed
            }
            local vtmp `vtmp' `v'
            if `"`stmp'"'!="" {
                local s`S' : list uniq stmp
                local stmp
            }
            local colonok 0
            local nlistok 1
            gettoken chunk rest : rest, parse(" :")
            continue
        }
        capt numlist `"`chunk'"', integer range(>0) sort
        if _rc==0 {
            if `nlistok'==0 {
                di as err "invalid controls()"
                exit 198
            }
            local stmp `stmp' `r(numlist)'
            if `"`vtmp'"'!="" {
                local v`S' : list uniq vtmp
                local vtmp
            }
            local colonok 1
            local vlistok 0
            gettoken chunk rest : rest, parse(" :")
            continue
        }
        di as err "invalid controls()"
        exit 198
    }
    if `"`vtmp'"'!="" { // get last varlist
        local v`S' `vtmp'
        local vtmp
    }
    local ncontrols `v0'  // common controls
    local allv `v0'
    forv i=1/`S' {
        foreach s of local s`i' {
            local sv`s' `sv`s'' `v`i''
        }
        local alls : list alls | s`i'
        local allv : list allv | v`i'
    }
    if `"`alls'"'!="" {
        numlist `"`alls'"', sort
        local alls `r(numlist)'
        foreach s of local alls {
            local sv`s' : list uniq sv`s'
            local ncontrols `"`ncontrols',`s':`sv`s''"'
        }
    }
    c_local controls controls(`ncontrols') // layout is: [varlist][,#:varlist[,#:varlist[...]]]
    c_local controlvars `allv'
end

program ParseControls2
    gettoken chunk rest : 0, parse(",")
    if `"`chunk'"'!="," {
        local allv `chunk'
        c_local commoncontrols `chunk'
        gettoken chunk rest : rest, parse(",")
    }
    local i 0
    gettoken chunk rest : rest, parse(",")
    while (`"`chunk'"'!="") {
        gettoken s chunk : chunk, parse(":")  // get #
        gettoken chunk v : chunk, parse(":")  // remove :
        local allv : list allv | v
        c_local controls_`s' `v'
        gettoken chunk rest : rest, parse(",") // remove ,
        gettoken chunk rest : rest, parse(",")
    }
    c_local allcontrols `allv'
end

prog _hte_compute_pstrata
    syntax varlist(numeric) [if] [in] [fw iw pw], pscore(varname) blockid(varname) [ ///
        NOIsily join(str) AUTOjoin AUTOjoin2(integer 0) ALpha(str asis) ///
        logit comsup numblo(passthru) DETail /// pscore opts
        ]
    if `"`join'"'!="" & ("`autojoin'"!="" | `autojoin2'!=0) {
        di as err "only one of join() and autojoin() allowed"
        exit 198
    }
    if "`autojoin'"!="" & `autojoin2'==0 local autojoin2 10
    if `"`alpha'"'!="" {
        local level level(`alpha')
    }
    marksample touse
    gettoken treatvar indepvars : varlist

    tempname psvar idvar
    capt confirm variable comsup, exact
    if _rc==0 {     // pscore will overwite variable comsup
        tempname comsupbak
        rename comsup `comsupbak'
    }
    if "`noisily'"=="" local noiqui noisily quietly // make sure that errors and warnings appear
    else               local noiqui noisily
    capture `noiqui' pscore `treatvar' `indepvars' if `touse' [`weight'`exp'], ///
        pscore(`psvar') blockid(`idvar') `logit' `comsup' `level' `numblo' `detail'
    local rc = _rc
    capt confirm variable comsup, exact
    if _rc==0 drop comsup
    if "`comsupbak'"!="" {
        rename `comsupbak' comsup
    }
    if `rc' {
        exit `rc'
    }
    if `autojoin2'>0 {
        local join
        tempname C R
        qui tab `idvar' `treatvar' if `touse', matcell(`C') matrow(`R')
        local N1 0
        local N2 0
        local joinl
        local i 0
        while (`i'<r(r)) {
            local ++i
            local num: di `R'[`i',1]
            local joinl `joinl' `num'
            local N1 = `N1' + `C'[`i',1]
            local N2 = `N2' + `C'[`i',2]
            if (`N1'>= `autojoin2') & (`N2'>=`autojoin2') continue, break
        }
        if `:list sizeof joinl'>1 {
            local join `joinl'
        }
        local N1 0
        local N2 0
        local joinr
        local i = r(r)+1
        while (`i'>1) {
            local --i
            local num: di `R'[`i',1]
            local joinr `num' `joinr'
            local N1 = `N1' + `C'[`i',1]
            local N2 = `N2' + `C'[`i',2]
            if (`N1'>= `autojoin2') & (`N2'>=`autojoin2') continue, break
        }
        if `:list sizeof joinr'>1 {
            if "`join'"!="" {
                if "`:list join & joinr'"!="" {
                    di as err "autojoin(): results in single stratum"
                    exit 499
                }
                local join "`join', `joinr'"
            }
            else local join `joinr'
        }
    }
    if `"`join'"'!="" {
        di as txt "(merged strata: " _c
        gettoken nlist rest : join, parse(",")
        local comma ""
        while (`"`nlist'"'!="") {
            di as txt `"`comma'`nlist'"' _c
            local comma ", "
            gettoken first nlist : nlist
            foreach num of local nlist {
                qui replace `idvar' = `first' if `idvar'==`num' & `touse'
            }
            gettoken nlist rest : rest, parse(",") // get rid of the comma
            gettoken nlist rest : rest, parse(",")
        }
        tempvar idvar2
        qui egen `idvar2' = group(`idvar')  // renumber strata
        drop `idvar'
        rename `idvar2' `idvar'
        di as txt "; strata renumbered)"
    }
    qui replace `pscore' = `psvar' if `touse'
    qui replace `blockid' = `idvar' if `touse'
end

prog __hte_compute, rclass
    syntax varlist(numeric) [if] [in] [fw iw pw] , ///
        blockid(varname) depvar(varname) ESTcom(str) [ ///
        NOIsily COMBine(str) ///
        CONtrols(str) ESTOPts(str) /// regress options
        ]
    ParseControls2 `controls' // returns locals allcontrols, commoncontrols, controls_#

    marksample touse
    markout `touse' `blockid'     /// restrict to common support
        `depvar' `allcontrols'    //  estimation sample
    gettoken treatvar indepvars : varlist

    qui levelsof `blockid' if `touse', local(blocks)
    tempname coefs
    local k 0
    foreach l of local blocks {
        local ++k
        local controls_`k' : list commoncontrols | controls_`k'
        qui `noisily' di _n as txt "Treatment Effect within Propensity Score Stratum " `l' ":"
        qui `noisily' `estcom' `depvar' `treatvar' `controls_`k'' ///
            if `touse' & `blockid'==`l' [`weight'`exp'], `estopts'
        capt di _b[`treatvar']   // check whether treatvar has been dropped from model
        local rc = _rc
        if `rc'==0 {
            if _b[`treatvar']==0 & _se[`treatvar']==0 local rc 111  // "omitted" coef
        }
        if `rc'==111 {
            di as err "error in model for stratum `l': treatvar dropped due to collinearity"
            exit `rc'
        }
        mat `coefs' = nullmat(`coefs') \ (`l', e(N), _b[`treatvar'], _se[`treatvar'])
        local blocklbls `blocklbls' `l'
    }

    tempname IDvar Nvar Bvar SEvar
    mat coln `coefs' = `IDvar' `Nvar' `Bvar' `SEvar'
    mat rown `coefs' = `blocklbls'
    svmat `coefs', names(col)
    qui `noisily' di _n as txt "Linear Fit of Treatment Effect on Propensity Score Rank:"
    *qui `noisily' regress `Bvar' `IDvar', depname("TreatEfct")
    if `k'>1 {
        qui `noisily' vwls `Bvar' `IDvar', sd(`SEvar')
        tempvar lfit
        qui predict `lfit' if e(sample), xb
    }
    else if `k'==1 {
        local singleton_b = _b[`treatvar']
        local singleton_se = _se[`treatvar']
        tempvar lfit
        qui gen `lfit' = `singleton_b' in 1
    }
    else { // should never happen
        di as err "somethings wrong; no propensity score strata were generated by -pscore-"
        exit 499
    }
    mkmat `lfit' in 1/`k'
    drop `lfit'
    mat `coefs' = `coefs', `lfit'
    mat coln `coefs' = id N b se lfit

    tempname b se obs block
    if `k'>1 {
        mat `b'   = `coefs'[1...,3]', _b[`IDvar'] , _b[_cons]
        mat `se'  = `coefs'[1...,4]', _se[`IDvar'] , _se[_cons]
    }
    else {
        mat `b'   = `coefs'[1...,3]', 0, `singleton_b'
        mat `se'  = `coefs'[1...,4]', 0, `singleton_se'
    }
    mat coln `b'  = `blocklbls' _slope _cons
    mat coln `se' = `blocklbls' _slope _cons
    mat `obs'     = `coefs'[1...,2]'
    mat `block'   = `coefs'[1...,1]'
    mat `lfit'    = `coefs'[1...,5]'
    foreach mat in b se obs block lfit {
        return mat `mat' = ``mat''
    }
end
