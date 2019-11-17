*! beta version 0.2.0 2014-09-12 | scott long | use #

//  #1 / #2    or   1 / 2 allowed

//  generate nlcom expression and sent it to nlcom

*   DO: trap errors from nlcom

program define mnlcom

    version 11.2
    tempname newmat newmatall

    gettoken token 0 : 0, parse(",= ")
    while `"`token'"'!="" & `"`token'"'!="," {
        local expression `"`expression'`token'"'
        gettoken token 0 : 0, parse(",= ")
    }
    if `"`0'"'!="" {
        local 0 `",`0'"'
        syntax [, ///
        /// results to display
            STATS(string asis) STATistics(string asis) ///
            ALLstats /// all stats (p, z, se, level)
            Details /// show nlcom output
            NOTABle /// only show nlcom
        /// save results to matrix
            clear /// clear matrix before saving
            add save /// add results to matrix
        /// label matrix
            ROWName(string) label(string) /// row name for current estimate
            ROWEQnm(string) /// row eq name for current estimate
            ESTName(string asis) /// allow override margin name for estimate
        /// displaying matrix
            DECimals(integer 3) /// Digits when list matrix
            WIDth(integer 8) /// Column width when listing matrix
            title(string) /// Title when listing
        ]
    }
    else {
        local decimals 3
        local width 8
    }

    if ("`label'"=="") local label `"`rowname'"' // synonyms
    if ("`save'"=="save") local add "add" // synonyms
    if ("`details'"=="details") local quietly ""
    else local quietly "quietly"
    * if no table, show nlcom output
    if ("`notable'"=="notable") local quietly ""

    local matrix _mnlcom
    capture confirm matrix `matrix'
    if (_rc == 0) local matrixexists = 1
    else local matrixexists = 0
    local matrixall _mnlcom_allstats
    capture confirm matrix `matrixall'
    if (_rc == 0) local matrixallexists = 1
    else local matrixallexists = 0

    if "`expression'"=="" {
        if `matrixexists' == 1 {
            if "`clear'"=="clear" {
                capture matrix drop `matrix'
                capture matrix drop `matrixall'
                exit
            }
            * if no expression, list table
            matlist `matrix', format(%`width'.`decimals'f) title("`title'")
            exit
        }
        else if ("`clear'"=="clear") exit
        else {
            display as error "you must specify the nlcom expression"
            exit
        }
    }

    capture confirm matrix e(b)
    if _rc>0 {
        display as error ///
            "mnlcom requires e(b) to be in memory; use post with margins or mtable"
        exit
    }

//  remove o. names from column names

    tempname b
    matrix `b' = e(b)
    local orignms : colfullnames `b'
    local noomitnms "" // without o. names
    foreach var of local orignms {
        _ms_parse_parts `var'
        if (!`r(omit)') local noomitnms `noomitnms' `var'
    }
    local bN = wordcount("`noomitnms'") + 1

//  decode expression

    local expin "`expression'"

    * are estimates referred to as 1 / 2  or  #1 / #2    
    local ishash = 0
    if ((strpos("`expin'","#"))>0) {
        local hash "#"
        local ishash = 1 
    }
    forvalues i = `bN'(-1)1 {
        local expin : subinstr local expin "`hash'`i'" " `hash'`i' ", all
    }

    local expout ""
    foreach term in `expin' {

        * if #1, allow numbers in expession like exp(#1)-1
        if `ishash' {
            local isbloc = (strpos("`expin'","#")>0)
            if `isbloc' {
                local term2 : subinstr local term "`hash'" "", all    
                capture confirm integer number `term2'
                if  _rc!= 0 local expout "`expout' `term'"
                else {
                    local bnm : word `term2' of `noomitnms'
                    local expout "`expout' _b[`bnm']"
                }
            }
            else local expout "`expout' `term'"
        }            
        * #1 not used
        else {
            capture confirm integer number `term'
            if  _rc!= 0 local expout "`expout' `term'"
            else {
                local bnm : word `term' of `noomitnms'
                local expout "`expout' _b[`bnm']"
            }
        }
    }

        

//  run nlcom and compute stats

    `quietly' nlcom `expout'
    tempname levelval levelpval cifactorval
    tempname rb rv
    mat `rb' = r(b)
    mat `rv' = r(V)
    scalar estimate = `rb'[1,1]
    scalar se = sqrt(`rv'[1,1])
    scalar zvalue = estimate/se // zvalue
    scalar pvalue = 2*(1-normal(abs(zvalue))) // pvalue 2 tailed
    scalar `levelval'   = $S_level // level for CI
    scalar `levelpval'  = ( 1 - (`levelval'/100) )/2 // pval for ci
    scalar `cifactorval' =  abs(invnormal(`levelpval')) // +- multiplier for ci
    scalar ll = estimate - (`cifactorval'*se) // lb
    scalar ul = estimate + (`cifactorval'*se) // ub
/*
    _rm_nlcom_stats
    scalar estimate = r(est)
    scalar se = r(se)
    scalar zvalue = r(z)
    scalar pvalue = r(p)
    scalar ll = r(lb)
    scalar ul = r(ub)
    scalar lvl = r(level)
*/
//  add results to matrix

    * if not adding, clear matrix
    if "`clear'" == "clear" | "`add'"=="" {
        capture matrix drop `matrix'
        capture matrix drop `matrixall'
        local matrixexists = 0
    }

    local estimatenm "nlcom"
    if ("`estname'"!="") local estimatenm "`estname'"

    * what stats go in table
    if ("`stats'"!="" & "`statistics'"=="") local statistics "`stats'"
    local statlist "estimate pvalue ll ul" // default statistics
    local statsall "estimate se zvalue pvalue ll ul"
    if ("`allstats'"=="allstats") local statlist "`statsall'"
    if ("`statistics'"=="noci") local statistics "est"
    if "`statistics'"=="all" {
        local statlist "`statsall'"
    }
    else if "`statistics'"!="" {
        local newstatlist ""
        foreach opt in `statistics' {
            _parse_stat `opt'
            local newopt
            local stat "`s(stat)'"
            local newstatlist "`newstatlist'`stat' "
            if "`s(isbad)'"=="1" {
                display as error ///
                    "invalid statistic specified: `opt'"
                exit
            }
        }
        local statlist "`newstatlist'"
    }
    if ("`s(isbad)'"=="1") exit
    local statlist : list uniq statlist

    * column names for matrix
    foreach stat in `statlist' {
        if "`stat'"=="estimate" { // use option estimatenm
            local `stat' "estimate"
            local colnms "`colnms'`estimatenm' "
        }
        else {
                local `stat' "`stat'"
            local colnms "`colnms'`stat' "
        }
    }
    local colnms = trim("`colnms'")

    * if add, make sure column names match
    if "`add'"=="add" {
        if `matrixexists' == 1 {
            local priorcolnms : colnames `matrix'
        }
        if `matrixexists'==1 & "`colnms'"!="`priorcolnms'" {
            display as error ///
                "statistics in matrix `matrix' do not match those being added"
            exit
        }
    }

    * get ALL statistics to be saved
    foreach s in `statsall' {
        local colnmsall "`colnmsall'`s' "
        matrix `newmatall' = nullmat(`newmatall') , `s'
    }
    * list of selected statistics s084
    foreach s in `statlist' {
        matrix `newmat' = nullmat(`newmat') , `s'
    }

    matrix colname `newmat' = `colnms'
    matrix colname `newmatall' = `colnmsall'
    if  "`roweqnm'" != "" {
        matrix roweq `newmat' = `roweqnm'
        matrix roweq `newmatall' = `roweqnm'
    }

    if "`label'"!="" { // nolabel
        matrix rowname `newmat' = `"`label'"'
        matrix rowname `newmatall' = `"`label'"'
    }
    else { // label
        local n = 1
        if (`matrixexists'==1) local n = rowsof(`matrix') + 1
        matrix rowname `newmat' = "`n'"
        matrix rowname `newmatall' = "`n'"
    }
    if `matrixexists'==1 { // it has been deleted if add not specified
        matrix `matrix' = `matrix' \ `newmat'
        matrix `matrixall' = `matrixall' \ `newmatall'
    }
    else {
        matrix `matrix' = `newmat'
        matrix `matrixall' = `newmatall'
    }

    if "`notable'"=="" {
        matlist `matrix', format(%`width'.`decimals'f) title("`title'")
    }

end

program define _parse_stat, sclass
    local isbad = 1
    local stat "`1'"
    local is = inlist("`stat'","e","es","est","esti","estim","estima")
    if `is'==1 {
        local stat "estimate"
        local isbad = 0
    }
    local is = inlist("`stat'","estimat","estimate","coef")
    if `is'==1 {
        local stat "estimate"
        local isbad = 0
    }
    local is = inlist("`stat'","s","se","stderr")
    if `is'==1 {
        local stat "se"
        local isbad = 0
    }
    local is = inlist("`stat'","p","pv","pva","pval","pvalu","pvalue")
    if `is'==1 {
        local stat "pvalue"
        local isbad = 0
    }
    local is = inlist("`stat'","z","zv","zva","zval","zvalu","zvalue")
    if `is'==1 {
        local stat "zvalue  "
        local isbad = 0
    }
    local is = inlist("`stat'","upper","ub","u","ul")
    if `is'==1 {
        local stat "ul"
        local isbad = 0
    }
    local is = inlist("`stat'","lower","lb","l","ll")
    if `is'==1 {
        local stat "ll"
        local isbad = 0
    }
    sreturn local stat "`stat'"
    sreturn local isbad "`isbad'"
end
exit
