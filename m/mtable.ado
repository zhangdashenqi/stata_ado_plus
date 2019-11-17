*! version 1.0.6 2014-08-14 | long freese | allow non-estimable
 * version 1.0.5 2014-08-11 | long freese | strip bug in 11.2
 * version 1.0.4 2014-06-16 | long freese | nose and ci
 * version 1.0.3 2014-05-30 | long freese | _caller()
 * version 1.0.2 2014-05-16 | long freese | trap no ecommand
 * version 1.0.1 2014-04-13 | long freese | adjust label printing
 * version 1.0.0 2014-02-18 | long freese | spost13 release

//  table of margins results

program define mtable, rclass

    version 11.2

    if _caller() >= 12 {
        local VERSION : display "version " string(_caller()) ":"
    }

    * naming convensions: M == margins; W == wide; L == long

    syntax [if] [in] , [ ///
        NOFVLABEL NOROWNUMbers ///
        brief NOATvars ATVars(string) ATRight /// at()
    /// stats: estimate ul ll z se p start end
        STATS(string) STATistics(string) ALLSTats CI PValue ///
        OUTcome(string) cpr(string) pr(string) /// predict(xxx(*))
    /// output
        below right CLEARstack /// stacking
        long wide NAMes(string) /// Rows Columns All None used by matlist
        ESTName(string asis) COLSTub(string) ROWSTub(string) ///
        ROWName(string) ROWEQnm(string) COLEQnm(string) ///
        NOLabels VALUELength(numlist >0 integer) ///
        title(string)DECimals(integer 3) WIDth(integer 8) TWidth(integer 0) ///
        NOBS DETAILs VERBose COMMANDs NOISily post MATrix(string) ///
        * ] // everything else will get passed along

    tempname atvec atorginal attable atL Mtable statcolmat outmat ivec vec
    tempname priormat currentmat margins outmatlong overN
    local maxestlength = 14 // if columns too wide, make this smaller
    local iserror = 0
    local icount = 0

    local maxcolwidth = 14 // if columns too wide, make this smaller
    if (`decimals'>=`width') local width = `decimals' + 1
    local mincolwidth = `width'
    if (`decimals'>=`mincolwidth') local mincolwidth = `decimals' + 1

    if "`e(cmd)'"=="margins" {
        display as error ///
        "margins estimates are in memory, not those from a regression model"
        exit
    }
    if "`e(cmd)'"=="" {
        display as error "no regression estimates are in memory"
        exit
    }
    if ("`post'"=="post") estimates store _mtable_model

//  atvars

    if ("`noatvars'"=="noatvars") local atvars "_none"
    if "`atvars'"=="_none" {
        local atvars ""
        local noatintable = 1 // string to number
    }
    else local noatintable = 0
    local isatintable = 1 - `noatintable'

//  stats

    if ("`stats'"!="" & "`statistics'"=="") local statistics "`stats'"
    local statistics : subinstr local statistics "ci" "estimate ll ul", all
    local statlist "estimate" // default statistics
    local tablecolnms "estimate se z pvalue ll ul" // for results matrix
    if "`allstats'"=="allstats" | "`statistics'"=="all" {
        local statlist "`tablecolnms'"
    }
    else if ("`ci'"=="ci") local statlist "estimate ll ul"
    else if ("`pvalue'"=="pvalue") local statlist "estimate pvalue"
    else if "`statistics'"!="" { // check if stat() options are valid
        local new ""
        foreach opt in `statistics' {
            _parse_stat, `opt'
            if "`s(isbad)'"=="1" {
                display as error "invalid statistic specified: `opt'"
                exit
            }
            local stat "`s(stat)'"
            local new "`new'`stat' "
        }
        local statlist "`new'"
    }
    if ("`s(isbad)'"=="1") exit

    local statlist : list uniq statlist
    local statsN = wordcount("`statlist'")
    local lbl_se "se" // labels for statistics
    local lbl_z "z"
    local lbl_pvalue "p"
    local lbl_ll "ll"
    local lbl_ul "ul"
    local lbl_estimate "estimate"

    * nose suppresses any test results
    local isnose = strpos("`options'","nose")
    if `isnose'>0 {
        local ok = 1
        foreach sestat in se z p ll ul {
            local pos = strpos("`statlist'","`sestat'")
            if `pos'>0 local ok = 0
        }
        if `ok'==0 {
            display as error ///
"requested statistics cannot be computed using -nose- option"
            exit
        }
    }

//  test if options are valid

    local isbad = 0
    if "`e(cmd)'"=="ztnb" | "`e(cmd)'"=="ztp" {
        display as error "use tpoisson or tnbreg instead of ztp or ztnb"
        local isbad = 1
    }
    if "`long'"=="long" & "`wide'"=="wide" {
        display as error "options wide and long cannot be used together"
        local isbad = 1
    }
    if "`below'"=="below" & "`right'"=="right" {
        display as error "options below and right cannot be used together"
        local isbad = 1
    }
    if "`clearstack'"=="clearstack" & "`right'"=="right" {
        local right "" // if right not needed, ignore it
    }
    if "`clearstack'"=="clearstack" & "`below'"=="below" {
        local below ""
    }
    if `isbad' exit

//  decode options

    local quicmd "quietly" // listing of command
    if ("`commands'"=="commands") local quicmd "noisily"
    if ("`verbose'"=="verbose") local details "details"
    local quimar "quietly"
    if "`details'" == "details" {
        local quimar "noisily"
        local quicmd "noisily"
    }

    if ("`below'"=="below") local isbelow = 1
    else local isbelow = 0
    if ("`right'"=="right") local isright = 1
    else local isright = 0
    local stackwithprior = (`isbelow' + `isright')>0

    * matlist names() options
    if "`norownumbers'"!="" { // turn off row labels
        if "`names'"!="" {
            display as error ///
            "optsions norownumbers and names() cannot be combined"
            exit
        }
        else local names "col"
    }

    if ("`names'"!="") local nonamesopt = 0
    else local nonamesopt = 1
    local isall = regexm(" `names'","[ ](a|al|all)")
    local isrow = regexm(" `names'","[ ](r|ro|row|rows)")
    local isnon = regexm(" `names'","[ ](n|no|non|none)")
    local iscol = regexm(" `names'","[ ](c|co|col|colu|column|columns)")
    if ("`names'"=="" | `iscol') local names "columns" // default
    else if (`isrow') local names "rows"
    else if (`isall') local names "all"
    else if (`isnon') local names "none"
    else {
        display as error "invalid names() option"
        exit
    }

//  decode model, margins, outcomes, predict options

    _rm_margins_modeltype // binary, discrete, count, other
    local modeltype "`s(modeltype)'"
    _rm_margins_parse_options, `options' `post'
    local Moptions "`s(marginsoptions)'"

    if ("`modeltype'"=="discrete" & "`outcome'"=="") local outcome "*"
    if "`outcome'"=="*" | "`outcome'"=="_all" {
        qui levelsof `e(depvar)' if e(sample)==1, local(outcome)
    }

    _rm_margins_parse_predict, `options' modeltype(`modeltype') ///
        outcome(`outcome') cpr(`cpr') pr(`pr')
    if `s( iserror)' exit
    local outcomes "`s(outcomes)'"
    local ismultiple = `s(ismultiple)'
    local issingle = 1 - `ismultiple'
    local predictform `"`s(predictform)'"'

//  information for printing, merging, and stacking

    * W=wide: stats in columns; L=long: in rows
    if "`wide'"=="" & "`long'"=="" {
        if (`ismultiple') local long "long"
        if (`issingle')   local wide "wide"
    }
    if "`wide'"=="wide" {
        local islong = 0
        local iswide = 1 - `islong'
        local LW "W"
    }
    else { // long
        local islong = 1
        local iswide = 1 - `islong'
        local LW "L"
    }

    if "`clearstack'"=="clearstack" {
        capture matrix drop _mtab_stack
        capture matrix drop _mtab_atstack
    }

//  margins for single outcome

    if `issingle' {

        local Mcmd "margins `if' `in', `Moptions'"
        _rm_margins_clean_cmd `Mcmd'
        local Mcmd `"`s(cmd)'"'
        `quicmd' display _new "Command: `Mcmd'"
        `quimar' `VERSION' `Mcmd'
        _rm_margins_names
        local Mtitle "`s(marginstitlenum)'" // if single, use # in nm
        if ("`estname'"=="") local estname `"`s(estlblnum)'"'
        local lbl_estimate "`estname'" // estname() options
        local dydxvarsN "`s(xvarsN)'"
        local isdydx `s(isdydx)'
        if `isdydx' & `dydxvarsN'>2 & r(k_at)>1 {
            display as error "only one dydx() variable allowed when using at()"
            exit
        }
        matrix `Mtable' = r(table)'
        _return hold `margins' // wipes out returns
        _return restore `margins', hold // bring r(error) back
        _rm_matrix_noomitted `Mtable' row
        _return restore `margins'
        local estimatesN = rowsof(`Mtable')

    } // single outcome

//  margins for multiple outcomes

    if `ismultiple' {

        local vallabnm : value label `e(depvar)'
        foreach outval of numlist `outcomes' {

            local outvalnoneg : subinstr local outval "-" "_", all // -1=>_1
            local outlbl "`outval'" // if labels not used, use value
            if "`vallabnm'"!="" & "`nolabels'"!="nolabels" {
                local outlbl : label `vallabnm' `outval' `valuelength'
            }
            local outlbl : subinstr local outlbl " " "_", all
            local predict : subinstr local predictform "XX" "`outval'"
            if "`modeltype'" == "binary" {
                if (`outval'==0) local predict = "1-`predictform'"
            }
            if ("`post'"=="post") qui estimates restore _mtable_model

            local Mcmd "margins `if' `in', `Moptions' expression(`predict')"
            _rm_margins_clean_cmd `Mcmd'
            local Mcmd `"`s(cmd)'"'
            `quicmd' display _new "Command: `Mcmd'"
            `quimar' `VERSION' `Mcmd'

            _rm_margins_names
            local Mtitle "`s(marginstitlenonum)'"
            if ("`estname'"=="") local estname `"`s(estlblnonum)'"'
            local lbl_estimate "`estname'" // estname() dominates
            local dydxvarsN "`s(xvarsN)'"

            local isdydx `s(isdydx)'
            if `isdydx' {
                capture confirm matrix r(at)
                if (_rc!=0) local atrowsN = 1
                else local atrowsN = rowsof(r(at))
                if `dydxvarsN'>2 & `atrowsN'>1 {
                    display as error ///
                    "only one dydx() variable allowed when using at()"
                    local iserror = 1
                    continue , break
                }
            }

            local colnms `"`lbl_estimate'_`outlbl' `lbl_se'_`outlbl'"'
            local colnms `"`colnms' `lbl_z'_`outlbl' `lbl_pvalue'_`outlbl'"'
            local colnms `"`colnms' `lbl_ll'_`outlbl' `lbl_ul'_`outlbl'"'
            mat `Mtable' = r(table)'
            _return hold `margins'
            _rm_matrix_noomitted `Mtable' row // drop omitted columns
            _return restore `margins'
            matrix Mtable_`outvalnoneg' = `Mtable'[1...,1..6]
            if _caller() <= 13 { // symbol not allowed in earlier versions of stata
                local colnms : subinstr local colnms "|" "\", all
            }
            matrix colnames Mtable_`outvalnoneg' = `colnms'
            local estimatesN = rowsof(Mtable_`outvalnoneg')
        } // over outcomes

        if (`iserror'==1) exit._at


    } // if multiple

//  get r(at) matrix: savevarying in table; saveconstant printed

    tempname atconstant atvarying
    qui capture mlistat, savevarying(`atvarying') saveconstant(`atconstant')
    local isatconstant = `s(isconstant)'
    local isatvarying = `s(isvarying)'
    tempname marginsat
    matrix `marginsat' = r(at)

    * expand catvar to 2.catvar 3.catvar etc; i.var to 1.var
    if "`atvars'"!="" {
        local atnms : colnames `marginsat'
        local expandedatvars ""
        foreach vnm in `atvars' {
            local found = 0
            foreach atnm in `atnms' { // in at()
                local ipos = strpos("`atnm'",".`vnm'")
                local bpos = strpos("`atnm'","b.")
                if `ipos'>0 & `bpos'==0 {
                    local expandedatvars `"`expandedatvars'`atnm' "'
                    local found = 1
                }
            }
            if (`found' == 0) local expandedatvars `"`expandedatvars'`vnm' "'
        }
        local atvars `expandedatvars'
    }

    * return string with at specification
    if `isatconstant'==1 {
        local atnms : colnames `marginsat'
        local atN = colsof(`marginsat')
        local atspec ""
        forvalues iatvar = 1/`atN' {
            local atnm : word `iatvar' of `atnms'
            local atval = el(`marginsat',1,`iatvar')
            if `atval'<. {
                local atval = string(`atval',"%11.8g")
                local atspec "`atspec'`atnm'=`atval' "
            }
        }
        return local atspec "`atspec'"
    }

    if `noatintable' matrix `attable' = J(1,1,.z)
    else if "`atvars'" == "" {
        if `isatvarying' {
            matrix `attable' = `atvarying'
        }
        else {
            local noatintable = 1
            local isatintable = 1 - `noatintable'
            matrix `attable' = J(1,1,.)
        }
    }
    else if "`atvars'" == "_all" {
        matrix `attable' = r(at)
        local at11 = `attable'[1,1]
        if (`at11'==.) {
            local noatintable = 1
            local isatintable = 1 - `noatintable'
        }
    }
    else { // atvars specified
        matrix `atorginal' = r(at)
        local atnms : colnames `atorginal'
        foreach atvarnm of local atvars {
            * expand name and return as 1.name
            fvunab atvarnm : `atvarnm'
            local found ///
                = regexm("`atvarnm'","(i)([0-9a-z]*)(\.)([0-9a-zA-Z_]*)")
            if `found' local atvarnm = regexs(2) + regexs(3) + regexs(4)
            local ipos : list posof "`atvarnm'" in atnms
            if `ipos'==0 {
                display as error "`atvarnm' is not in r(at)"
                local iserror = 1
                continue, break
            }
            matrix `atvec' = `atorginal'[1...,`ipos']
            matrix `attable' = nullmat(`attable') , `atvec'
        }
        if `iserror' exit
    }
    local colsatN = colsof(`attable')
    local atnms : rownames `attable'
    local atnms : subinstr local atnms "bn." ".", all
    local atnms : subinstr local atnms "._at" "", all
    matrix rownames `attable' = `atnms'

 //  WIDE matrix with current results

    capture matrix drop _mtab_W
    capture matrix drop _mtab_atW
    capture matrix drop _mtab_statW

    foreach stat of local statlist {

        local matnm `lbl_`stat''
        local statnm `lbl_`stat'' // used as column name
        if "`stat'" == "estimate" {
            local matnm "estimate"
            if ("`estname'"!="") local statnm `estname'
            if _caller() <= 13{ // symbol not allowed in earlier versions of stata
                local statnm : subinstr local statnm "|" "\", all
            }
        }
        local statcol : list posof "`stat'" in tablecolnms

        if `ismultiple' {
            local colnms ""
            foreach outval of numlist `outcomes' {
                local outlbl "`outval'"
                local outvalnoneg : subinstr local outval "-" "_", all
                if "`vallabnm'"!="" & "`nolabels'"!="nolabels" {
                    local outlbl : label `vallabnm' `outval' `valuelength'
                }
                local outlbl : subinstr local outlbl " " "_", all
                local statcolnm "`statnm'"
                if ("`statnm'"=="pvalue") local statcolnm "p"
                if `iswide' {
                   local colnms `"`colnms' `statcolnm'_`colstub'`outlbl'"'
                }
                else { // long do not add stat name to column names
                    local colnms `"`colnms' `colstub'`outlbl'"'
                }
                matrix `ivec' = Mtable_`outvalnoneg'[1...,`statcol']
                matrix _mtab_`matnm' = nullmat(_mtab_`matnm') , `ivec'
            }
            matrix colnames _mtab_`matnm' = `colnms'
        }

        if `issingle' {
            local colnm "`lbl_`stat''"
            local singlecolnms "`statcolnms' `colnm'"
            matrix `ivec' = `Mtable'[1...,`statcol']
            matrix _mtab_`matnm' = nullmat(_mtab_`matnm') , `ivec'
            matrix colnames _mtab_`matnm' = `"`colstub'`statnm'"'
        }

        local rownms : rownames _mtab_`matnm'
        local rownms : subinstr local rownms "._at" "", all
        local rownms : subinstr local rownms "bn" "", all
        if ("`rownms'"=="_cons") local rownms "estimate"

        * label catvars if dydx
        if `isdydx' {
            local oldnms `rownms'
            local rownms ""
            if "`nofvlabel'"=="nofvlabel" {
                * use #.varname
                foreach rnm in `oldnms' {
                    * local rownms `"`rownms' `""d_`rnm'""' "'
                    local rownms `"`rownms' `""`rnm'""' "'
                }
            }
            else {
                local underscore underscore
                tempname rb
                matrix `rb' = r(b) // get dydx
                _rm_matrix_noomitted `rb' col // remove o.
                local rbN = colsof(`rb')
                forvalues i = 1/`rbN' {
                    qui _ms_display, el(`i') first matrix(`rb') width(20)
                    local vnm "`r(term)'"
                    if "`r(note)'"!="(base)" { // no base level
                        * local addnm `""`r(level1)'""'
                        local addnm `""`r(level)'""'
                        local addnm : subinstr local addnm " " "_", all
                        local rownms `"`rownms' `"`addnm'"' "'
                    }
                }
            }
        }
        matrix rownames _mtab_`matnm' = `rownms'
        matrix roweq _mtab_`matnm' = `vnm'
        if ("`coleqnm'"!="") matrix coleq _mtab_`matnm' = "`coleqnm'"
        * current with matrix of statistics
        matrix _mtab_statW = nullmat(_mtab_statW) , _mtab_`matnm'
    } // over stats

    * add at values
    local rownmsW `"`rownms'"'
    local colsstatWN = colsof(_mtab_statW)
    if (`noatintable') matrix _mtab_W = _mtab_statW
    else if "`atright'"=="atright" {
        matrix _mtab_W = _mtab_statW, `attable'
        matrix _mtab_atW = `attable'
    }
    else { // atvars on left
        matrix _mtab_W = `attable', _mtab_statW
        matrix _mtab_atW = `attable'
    }

//  LONG matrix with current results

    capture matrix drop _mtab_L
    capture matrix drop _mtab_statL
    capture matrix drop _mtab_atL

    local rownms ""
    capture matrix drop `outmat'
    forvalues irow = 1/`estimatesN' {
        if `isatintable' matrix `atvec' = `attable'[`irow',1...]
        foreach stat of local statlist {
            local matstatnm `lbl_`stat''
            local statlabel "`matstatnm'"
            if ("`stat'"=="estimate") local matstatnm estimate
                *                local statlabel "estimate"
            if (`statsN'==1) local statlabel `irow'
            local rownms `"`rownms' "`statlabel'""'
            matrix `ivec' = _mtab_`matstatnm'[`irow',1...]
            matrix _mtab_statL = nullmat(_mtab_statL) \ `ivec'
            if `isatintable' matrix `atL' = nullmat(`atL') \ `atvec'
        }
    } // row labels for long list

    local colsstatLN = colsof(_mtab_statL)
    if `noatintable' {
        matrix _mtab_L = _mtab_statL
        local atstatorder "stat"
    }
    else if "`atright'"=="atright" {
        local atstatorder "stat at"
        matrix _mtab_L = _mtab_statL, `atL'
        matrix _mtab_atL = `atL'
    }
    else {
        local atstatorder "at stat"
        matrix _mtab_L = `atL', _mtab_statL
        matrix _mtab_atL = `atL'
    }
    * for dydx use name of variable
    if ((`statsN'==1) & `isdydx') local rownms `"`rownmsW'"'
    if _caller() <= 13{ // 2014-08-11
        local rownms : subinstr local rownms "|" "\", all
    }

    matrix rownames _mtab_L = `rownms'
    matrix rownames _mtab_statL = `rownms'

//  row names: revise when rowstub() or rowname()

    if "`rowstub'"!="" | "`rowname'"!="" { // rowstub() & rowname() options

        if "`rowname'"!="" {
            * 2014-04-13 to allow spaces            local rowname : subinstr local rowname " " "_", all
            * 2014-04-13 26 max length
            local rownmlen = strlen(`"`rowname'"')
            if (`rownmlen'>26) local rowname = substr("`rowname'",1,26)

            local rowstub "" // could stub be allowed?
            local isrowname = 1
            local isrowstub = 1 - `isrowname'
            local opt_rownm `"`rowname'"'
        }
        else { // no rowname
            local isrowname = 0
            local isrowstub = 1 - `isrowname'
            local opt_rownm `"`rowstub'"'
        }

        foreach type in W L {

            matrix _mtab_work = _mtab_`type'
            local curnms : rownames _mtab_work
            local _mtab_rowsN = rowsof(_mtab_work)

            local newnms ""
            local rownum = 0
            foreach rownm in `curnms' {
                local ++rownum
                if "`rownm'"=="estimate" {
                    local rownm "est" // to shorten? always?
                    if ("`estname'"!="") local rownm `"`estname'"'
                }
                * if only 1 stat use row number to label rows
                if "`rownm'"=="_" | `statsN'==1 {
                    if (`_mtab_rowsN'==1) local rownm `"`opt_rownm'"' // no #
                    else local rownm `"`opt_rownm'_`rownum'"' // add #
                }
                else { // use names of statistics
                    local rownm : subinstr local rownm "." "_", all // 1. fix
                    if "`type'"=="W" {
                        if `isrowstub' local rownm `"`opt_rownm'_`rownm'"'
                        if `isrowname' local rownm `"`opt_rownm'"'
                    }
                    if "`type'"=="L" {
                        local rownm : subinstr local rownm "." "_", all
                        local rownm `"`opt_rownm'_`rownm'"'
                    }
                }
                local newnms `"`newnms'"`rownm'" "'
            }
            matrix rownames _mtab_work = `newnms'
            matrix _mtab_`type' = _mtab_work // now has new rownames

            if `isatintable' {
                matrix rownames _mtab_work = `newnms' // same as for stats
                matrix _mtab_`type'at = _mtab_work
            }

            capture matrix _mtab_work
        } // W | L
    } // if rowstub or rowname

//  eq names names

    if `noatintable' {
        matrix roweq _mtab_W = ""
        matrix roweq _mtab_L = ""
    }
    if "`roweqnm'"!="" {
        matrix roweq _mtab_W = "`roweqnm'"
        matrix roweq _mtab_L = "`roweqnm'"
        if `isatintable' {
            matrix roweq _mtab_atW = "`roweqnm'"
            matrix roweq _mtab_atL = "`roweqnm'"
        }
        matrix roweq _mtab_statW = "`roweqnm'"
        matrix roweq _mtab_statL = "`roweqnm'"
    }
    if "`coleqnm'"!="" {
        matrix coleq _mtab_W = "`coleqnm'"
        matrix coleq _mtab_L = "`coleqnm'"
        if `isatintable' {
            matrix coleq _mtab_atW = "`coleqnm'"
            matrix coleq _mtab_atL = "`coleqnm'"
        }
        matrix coleq _mtab_statW = "`coleqnm'"
        matrix coleq _mtab_statL = "`coleqnm'"
    }

    matrix `currentmat' = _mtab_`LW'
    * current matrix (not stacked)
    matrix _mtab_display = `currentmat'
    local _mtab_rowsN = rowsof(_mtab_display)

    if `ismultiple' {
        foreach outval of numlist `outcomes' {
            capture matrix drop Mtable_`outval'
        }
    }

//  determine matlist names(): needed before cspec

    if `nonamesopt' {
        if (`islong' & `statsN'>1) local names "all"
        if (`estimatesN'>1) local names "all"
        if (`isbelow') local names "all"
        if ("`rowname'"!="") local names "all"
    }

//  cpsec for current matrix

    local roweqnm : roweq _mtab_display
    local roweqnm : word 1 of `roweqnm'
    local roweqlen = strlen("`roweqnm'")
    local lblcollen = `roweqlen' + 1
    if (`lblcollen'<9) local lblcollen = 9

    * width of columns with names
    *2014-04-13    local rownms : rownames _mtab_display
    local rownms : rownames _mtab_display, quoted
    local maxrownmlen = 0
    foreach rownm in `rownms' {
        local rownmlen = strlen("`rownm'") + 1
        if (`rownmlen'>`maxrownmlen') local maxrownmlen = `rownmlen'
    }
    if (`stackwithprior') capture local stackrownms : rownames _mtab_stack

    foreach rownm in `stackrownms' {
        local rownmlen = strlen("`rownm'") + 1
        if (`rownmlen'>`maxrownmlen') local maxrownmlen = `rownmlen'
    }
    if (`maxrownmlen'>`lblcollen') local lblcollen = `maxrownmlen'
    if (`twidth'>0) local lblcollen = `twidth'
    local cspec_names "o1& %`lblcollen's |" // for names(rows) or names(all)
    local currCat = `colsatN'
    local currCstat = `colsstat`LW'N'
    local currRat = rowsof(`currentmat')

    local decplus1 = `decimals' + 1
    local currcpsec_at "" // save current at cspec for later stacking
    forvalues i = 1/`currCat' { // g format for at matrix
        if ("`atstatorder'"=="at stat") | ///
           ("`atstatorder'"=="stat") local icol = `i'
        else local icol = `i' + `currCstat'
        mat `vec' = _mtab_display[1...,`icol']
        local colnm : colnames `vec'
        local xwidth = strlen(`"`colnm'"')
        local xwidth = max(`xwidth',`mincolwidth')
        local currcpsec_at "`currcpsec_at' %`xwidth'.`decimals'g &"
    }
    local currcspec_stat ""
    forvalues i = 1/`currCstat' {
        local icol = `i'
        if ("`atstatorder'"!="stat") & ("`atright'"=="") {
            local icol = `currCat' + `i'
        }
        mat `vec' = _mtab_display[1...,`icol']
        local colnm : colnames `vec'
        local xwidth = strlen(`"`colnm'"')
        local xwidth = max(`xwidth',`mincolwidth')
        local currcspec_stat "`currcspec_stat' %`xwidth'.`decimals'f &"
    }

    * combine cpsecs in order depending at left or right
    local cspec "" // start blank and build
    foreach nm in `atstatorder' {
        if ("`nm'"=="at") local cspec "`cspec' `currcpsec_at'"
        if ("`nm'"=="stat") local cspec "`cspec' `currcspec_stat'"
    }
    if "`names'"=="all" | "`names'"=="rows" {
        local cspec "`cspec_names' `cspec'" // add column for name
    }
    else local cspec `"& `cspec'"'

    local rspec "&"
    if ("`names'"=="all" | "`names'"=="columns") local rspec "`rspec'-"
    local _mtab_rowsN = rowsof(_mtab_display)
    forvalues i = 1/`_mtab_rowsN' {
        local rspec "`rspec'&"
    }

//  stack current with prior results

    * use globals from last time mtable was run
    local priorcspec "$mtable_cspec "
    local priorrspec "$mtable_rspec "
    local priortype  "$mtable_type"
    local priorexp   "$mtable_expression"
    local priorcpsecnames "$mtable_cspecnames"

    if `stackwithprior' {
        if "`LW'"!="`priortype'" {
            display as error ///
"when stacking, current & prior matrix must both be long or both wide"
            exit
        }
        if `isright' {
            local nrowsstack = rowsof(_mtab_stack)
            local nrowsdisp = rowsof(_mtab_display)
            if `nrowsstack'!=`nrowsdisp' {
                display as error ///
                    "current table does not match rows of saved table"
                exit
            }
            matrix _mtab_display = _mtab_stack, _mtab_display
            local is_cnames = strpos("`cspec'","`cspec_names'")
            * if names specification, remove names cspec portion of cpsec
            if `is_cnames'>0 {
                local cspectrim = subinstr("`cspec'","`cspec_names'"," ",1)
            }
            else local cspectrim = subinstr("`cspec'","&"," ",1)
            * if no row names, remove names spec from prior
            if "`names'"=="none" | "`names'"=="columns" {
                local priorcspec ///
                    = subinstr("`priorcspec'","$mtable_cspecnames"," ",1)
                local priorcspec "& `priorcspec'"
            }
            local cspec "`priorcspec' `cspectrim'"
        }
        if `isbelow' {
            if colsof(_mtab_stack)!=colsof(_mtab_display) {
                display as error ///
                    "current table does not match columns of saved table"
                exit
            }
            matrix _mtab_display = _mtab_stack \ _mtab_display
            local rspectrim = subinstr("`rspec'","&-","",1)
            local rspec "`priorrspec' `rspectrim'"
        }
        local cspec = subinstr("`cspec'","& &","&",1)
    }
    global mtable_cspec "`cspec'"
    global mtable_rspec "`rspec'"
    global mtable_type  "`LW'"
    global mtable_cspecnames "`cspec_names'"

//  print results

    if ("`title'"!="") display _new "{bf}`title'{sf}"
    global mtable_expression "`Mtitle'" // `expout'"
    display _new "Expression: `Mtitle'" // `expout'
    if ("nobs"=="`nobs'") display _new "N = `totalN'"

    * when stacking, make sure cspec has correct prefix for columns
    *   - might not be right if prior mtable used norownumbers
    local opos = strpos("`cspec'","o1&")
    if ("`names'"=="all" | "`names'"=="rows") & `opos'==0 {
        local cspec "o1& %9s | `cspec'"
        * add cspec for row labels
        local cspec = subinstr("`cspec'", "o1& %9s | &", "o1& %9s | ", 1)
    }

    matlist _mtab_display, names(`names') title("") nohalf ///
        cspec(`cspec') rspec(`rspec') `underscore' // blank row if _ is name

//  at

    capture confirm matrix _mtab_atstack
    local atstackexists = 0
    if (_rc==0)  local atstackexists = 1
    capture matrix drop _mtab_atdisplay
    capture matrix drop _atcurrent
    if `isatconstant' matrix _atcurrent = `atconstant'
    else {
        matrix _atcurrent = J(1,1,.n)
        matrix colna _atcurrent = `""No at()""' // No at()"
    }
    matrix rowna _atcurrent = Current

    if `stackwithprior' {
        mat_rapp _atdisplay : _mtab_atstack _atcurrent, miss(.)
    }
    else matrix _atdisplay = _atcurrent

    * is no at
    local atcnms : colnames _atdisplay, quoted
    local noatnm `""No at()""'
    local noatpos = 0
    local i = 0
    foreach nm in `atcnms' {
        local ++i
        if ("`nm'"=="No at()") local noatpos = `i'
    }
    local attitle "Specified values of covariates"
    if (`noatpos'>0) ///
        local attitle "Specified values where .n indicates no values specified with at()"

    if "`brief'"=="" {
        local colsN = colsof(_atdisplay)
        capture _assert_mreldif "J(`rowN',1,.)" _atdisplay, nonames nolist
        if _rc != 0 {
            local atformat "format(%`width'.`decimals'g)"
            make_rcspec , mat(_atdisplay) width(`width') decimals(`decimals')
            local cspec `s(cspec)'
            local rspec "`s(rspec)'&"
            matlist _atdisplay, nohalf title(`attitle') ///
                cspec(`cspec') rspec(`rspec')
        }
        else display _new "No specified values of covariates"
    }

    if `atstackexists' & `stackwithprior' {
        _get_nextsetnumber _mtab_atstack
        local nextset `s(nextset)'
    }
    else local nextset = 1
    matrix rowna _atcurrent = `"Set `nextset'"'

    if `stackwithprior' { // restack with new names
        mat_rapp _mtab_atstack : _mtab_atstack _atcurrent, miss(.)
    }
    else matrix _mtab_atstack = _atcurrent
    matrix rename _atdisplay _mtab_atdisplay

    if ("`matrix'"!="") matrix `matrix' = _mtab_display
    matrix _mtab_stack = _mtab_display
    return matrix table = _mtab_display, copy

    capture matrix drop _atcurrent
    foreach m in L W statL statW ul ll p z se estimate {
        capture matrix drop _mtab_`m'
    }

end

program define _get_nextsetnumber, sclass
    args matnm
    local rownms : rownames `matnm'
    local rownms : subinstr local rownms "Set " " ", all
    local rownms : list sort rownms
    local rownmsN = wordcount("`rownms'")
    local lastset : word `rownmsN' of `rownms'
    local nextset = abs(`lastset') + 1
    sreturn local nextset `nextset'
end

program define _parse_stat, sclass
    syntax , [ ESTimate coef Se STDerr Pvalue Zvalue ///
        Ub ul UPper Lb ll LOwer * ] // ENd STart BEgin ///

    if ("`coef'"!="") local estimate estimate
    if ("`stderr'"!="") local se se
    if ("`zvalue'"!="") local zvalue z
    if ("`ub'"!="" | "`upper'"!="") local ul ul
    if ("`lb'"!="" | "`lower'"!="") local ll ll
    if ("`begin'"!="") local start start

    local stat = trim("`estimate' `se' `pvalue' `zvalue' `ul' `ll'")
    local isbad = wordcount("`stat'")>1
    if "`options'"!="" {
        local isbad = 1
        local stat "`options'"
    }

    sreturn local stat "`stat'"
    sreturn local isbad "`isbad'"
end

program define make_rcspec, sclass
    version 11.2
    syntax  , mat(string) width(string) decimals(string)
    local decplus1 = `decimals' + 1
    local colnms : colnames `mat', quoted
    local cspec "o1& %9s | "
    foreach colnm in `colnms' {
        local xwidth = strlen(`"`colnm'"')
        local xwidth = max(`xwidth',`width')
        local cspec "`cspec' %`xwidth'.`decimals'g &"
    }
    sreturn local cspec "`cspec'"

    local rspec "&|"
    local rowsN = rowsof(`mat') - 1
    forvalues i = 1/`rowsN' {
        local rspec "`rspec'&"
    }
    sreturn local rspec "`rspec'"
end
exit

*   DO: get value labels: < search for that and change 2.dog to value label
*   DO: test multiple row and col eq nms
*   DO: Consider adding _N over as a new statistic
