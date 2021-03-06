*!version 3.0.4  Ben Jann  18nov2008

program define oaxaca, byable(recall) properties(svyj svyb)
    version 9.2
    capt syntax [, Level(passthru) eform xb noLEgend ]
    if _rc==0 {
        Display `0'
        exit
    }
    syntax [anything] [if] [in] [fw aw pw iw] [ , ///
        SVY SVY2(str asis) vce(str) cluster(passthru) noSE * ]

    marksample touse, novarlist zeroweight

    if `"`svy2'"'!="" {
        _parsesvyopt `svy2'
        local svy svy
    }
    if "`svy'"!="" {
        if _by() {
            di as err "svy may not be combined with by"
            exit 190
        }
        local i 0
        foreach opt in vce cluster weight {
            local optnm: word `++i' of "vce()" "cluster()" "weights"
            if `"``opt''"'!="" {
                di as err "`optnm' not allowed with svy"
                exit 198
            }
        }
        if `"`svy_type'"'=="" {
            qui svyset
            local svy_type "`r(vce)'"
        }
        if inlist(`"`svy_type'"',"brr","jackknife") {
            local se "nose"
            svy `svy_type', `svy_opts': ///
                oaxaca `anything' if `touse', `se' `options'
            exit
        }
    }
    if `"`vce'"'!="" {
        _parsevceopt `vce'
        if inlist(`"`vce_type'"',"bootstrap","jackknife") {
            local se "nose"
            `vce_type', `vce_opts': ///
                oaxaca `anything' if `touse' [`weight'`exp'], `se' `options'
            exit
        }
    }
    __oaxaca `anything' if `touse' [`weight'`exp'], ///
        `svy' svy2(`svy2') vce(`vce') `cluster' `se' `options'
end

program _parsesvyopt
    syntax [anything] [, * ]
    local len = strlen(`"`anything'"')
    if `"`anything'"'==substr("jackknife",1,max(4,`len')) local anything "jackknife"
    c_local svy_type `"`anything'"'
    c_local svy_opts `"`options'"'
end

program _parsevceopt
    syntax [anything] [, * ]
    local len = strlen(`"`anything'"')
    if `"`anything'"'==substr("jackknife",1,max(4,`len'))      local anything "jackknife"
    else if `"`anything'"'==substr("bootstrap",1,max(4,`len')) local anything "bootstrap"
    c_local vce_type `"`anything'"'
    c_local vce_opts `"`options'"'
end

prog Display, eclass
    syntax [, level(passthru) eform xb noLEgend ]
    if e(cmd)!="oaxaca" {
        error 301
    }
    if "`eform'"!="" {
        local eform "eform(exp(b))"
        tempname b
        mat `b' = e(b)
        local coln: colnames `b'
        local newcoln: subinstr local coln "_cons" "__cons", word count(local cons)
        if `cons' {
            mat coln `b' = `newcoln'
            ereturn repost b = `b', rename
        }
    }

    _coef_table_header
    di _n   as txt _col(12) "1: `e(by)' = " as res e(group_1)
    di      as txt  _col(12) "2: `e(by)' = " as res e(group_2)
    di ""

    eret display, `level' `eform'
    if "`eform'"!="" {
        if `cons' {
            mat `b' = e(b)
            mat coln `b' = `coln'
            ereturn repost b = `b', rename
        }
    }
    if "`legend'"=="" {
        Display_legend
    }
    if `"`xb'"'!="" {
        Display_b0, `level'
    }
end

prog Display_legend
    if `"`e(legend)'"'=="" exit
    foreach line in `e(legend)' {
        local i 0
        local piece: piece `++i' 78 of `"`line'"'
        di as txt `"`piece'"'
        while (1) {
            local piece: piece `++i' 76 of `"`line'"'
            if `"`piece'"'=="" continue, break
            di as txt `"  `piece'"'
        }
    }
end

prog Display_b0
    syntax [, Level(passthru)]
    tempname hcurrent b V
    mat `b' = e(b0)
    mat `V' = e(V0)
    _est hold `hcurrent', restore estsystem
    di _n "Coefficients (b) and means (x)"
    eret post `b' `V'
    eret display, `level'
end


program define __oaxaca
    version 9.2
    syntax varlist(min=1 numeric) [if] [in] [aw fw iw pw] , ///
        By(varname) [                                       ///
        swap                                                ///
        THREEfold THREEfold2(passthru) Weights(passthru)    ///
        Pooled Pooled2(str asis)                            ///
        Omega  Omega2(str asis)                             ///
        Reference(passthru)                                 ///
        noSE                                                ///
        SVY SVY2(str asis)                                  ///
        vce(str) CLuster(passthru)                          ///
        NOSUEST SUEST                                       ///
        MODEL1(str asis)                                    ///
        MODEL2(str asis)                                    ///
        eform                                               ///
        Level(passthru)                                     ///
        xb                                                  ///
        noLEgend                                            ///
        NOIsily                                             ///
        Noisily2 /// undocumented: display results from -suest- and -mean-
        * ]

    if `"`pooled2'"'!="" local pooled pooled
    if `"`omega2'"'!=""  local omega omega
    if `"`threefold2'"'!="" local threefold threefold
    if  ("`threefold'"!="") + (`"`weights'"'!="") + (`"`pooled'"'!="") ///
        + (`"`omega'"'!="") + (`"`reference'"'!="") >1 {
        di as err "only one of threefold, weight(), pooled, omega, and reference() allowed"
        exit 198
    }
    if "`nosuest'"!="" & "`suest'"!="" {
        di as err "suest and nosuest not both allowed"
        exit 198
    }
    if "`noisily'"=="" local qui quietly
    local noisily = cond("`noisily2'"!="","noisily","")

    if "`pooled'"!="" {
        local model3 `"`pooled2'"'
    }
    else if "`omega'"!="" {
        local model3 `"`omega2'"'
    }
    local nmodels = 2 + (`"`pooled'`omega'"'!="")
    forv i=1/`nmodels' {
        __parsemodelopt cmd`i' `model`i''
    }

// use suest?
    if `"`vce'"'==substr("robust",1,max(1,strlen(`"`vce'"'))) {
        local regvce "vce(robust)"
        local vce
    }
    if `"`pooled'`omega'`svy'`cluster'"'!="" {
        local suest "suest"
    }
    if `"`vce'"'!="" {
        __vce_iscluster `vce'
        if `vce_iscluster' local suest "suest"
        local vce `"vce(`vce')"'
    }
    if "`se'"!="" | "`nosuest'"!="" {
        local suest
    }
    local regweight "`weight'"
    if "`weight'"=="pweight" & "`suest'"!="" {
        local regweight "iweight"
    }
    if "`suest'"!="" {
        local regvce  // disable robust option
    }
    if "`svy'"!="" {
        capt __parsesvyopt `svy2'
        if _rc {
            di as err "invalid svy() option"
            exit 198
        }
        capt __parsesvysubpop `svy_subpop'
        if _rc {
            di as err "invalid subpop() option"
            exit 198
        }
        //=> svy `svy_vcetype', subpop(`svy_subpop') `svy_opts': ...
    }

    marksample touse, zeroweight novarlist
    if "`svy'"!="" {
        svymarkout `touse'
    }
    qui levelsof `by' if `touse', local(groups)
    if `: list sizeof groups'>2 {
        di as err "more than 2 groups found, only 2 groups allowed"
        exit 420
    }
    if "`swap'"=="" {
        gettoken group1 group2: groups, quotes
        gettoken group2: group2, quotes
    }
    else {
        gettoken group2 group1: groups, quotes
        gettoken group1: group1, quotes
    }

    tempname est1 est2 est3
    forv i=1/2 {
        `qui' di as txt _n "Model for group `i'"
        if "`svy'"!="" {
            `qui' svy `svy_vcetype', subpop(`svy_subpop' & `by'==`group`i'') `svy_opts': ///
             `cmd`i'' `varlist' `cmd`i'rhs' if `touse', `cmd`i'opts'
        }
        else {
            `qui' `cmd`i'' `varlist' `cmd`i'rhs' if `touse' & `by'==`group`i'' ///
                [`regweight'`exp'], `regvce' `cmd`i'opts'
        }
        est sto `est`i''
    }

    if `"`pooled'`omega'"'!="" {
        `qui' di as txt _n "Pooled model"
        if `"`pooled'"'!="" local includeby `"`by'"'
        if "`svy'"!="" {
            `qui' svy `svy_vcetype', subpop(`svy_subpop') `svy_opts': ///
             `cmd3' `varlist' `cmd3rhs' `includeby' if `touse', `cmd3opts'
        }
        else {
            `qui' `cmd3' `varlist' `cmd3rhs' `includeby' if `touse' ///
                [`regweight'`exp'], `regvce' `cmd3opts'
        }
        est sto `est3'
        local reference "reference(`est3')"
    }
    gettoken depvar: varlist
    _oaxaca `est1' `est2' if `touse' [`weight'`exp'], nodisplay depname(`depvar') ///
        `noisily' `se' `svy' svy2(`svy2') `vce' `cluster' `nosuest' `suest' ///
        `threefold' `threefold2' `weights' `reference' `options'

    PostResults, by(`by') group1(`group1') group2(`group2')

    Display, `level' `eform' `xb' `legend'
end

program __parsemodelopt
    syntax anything [, ADDrhs(str asis) * ]
    gettoken name estcom : anything
    if `"`estcom'"'=="" local estcom "regress"
    c_local `name'     `"`estcom'"'
    c_local `name'rhs  `"`addrhs'"'
    c_local `name'opts `"`options'"'
end

program __parsesvyopt
    syntax [anything] [, SUBpop(str asis) * ]
    c_local svy_type    `"`anything'"'
    c_local svy_opts    `"`options'"'
    c_local svy_subpop  `"`subpop'"'
end

program __parsesvysubpop
    syntax [varname(default=none)] [if/]
    if `"`if'"'!="" {
        local iff `"(`if') & "'
    }
    c_local svy_subpop `"`varlist' if `iff'1"'
end

program __vce_iscluster
    syntax [anything] [, * ]
    local vce_type: word 1 of `anything'
    local iscluster 0
    if `"`vce_type'"'==substr("cluster",1,max(2,strlen(`"`vce_type'"'))) local iscluster 1
    c_local vce_iscluster `iscluster'
end

program PostResults, eclass
    syntax, by(str) group1(str asis) group2(str asis)
    eret local group_2 `"`group2'"'
    eret local group_1 `"`group1'"'
    eret local by `"`by'"'
    eret local cmd "oaxaca"
end
