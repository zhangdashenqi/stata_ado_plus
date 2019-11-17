capture program drop vardesc
*! version 0.5.1 jsl n option for names
* version 0.5.0 jsl string variables
* version 0.4.9b jsl trap some errors
* still buggy try vd-kins

* version 0.4.9 jsl sq bug fix
* version 0.4.8 jsl 01Jul2006 maxlen
* version 0.4.7 jsl 29Jun2006 with sq ad op overrides
* version 0.4.6b jsl 29Jun2006 with squeezing

* DO: add truncate for truncate at some column length

//  prints names, labels and descriptive statistics in a table
program define vardesc, byable(recall)
    version 8
    syntax [varlist(default=none)] [if] [in] ///
    [, ///
    SQueeze             /// squeeze out extra space
    SQMin(integer 6)    /// minimum column size if compression
    OPtimize            /// optimize space used without any truncation
    OPTMin(integer 5)   /// minimum column size if optimized
    OCLABel(integer 0)  /// column widths to override squeeze and optimize
        OCNAme(integer 0)   ///
        OCVAlues(integer 0) ///
        OCPCTile(integer 0) ///
        OCMAx(integer 0)    ///
        OCMEan(integer 0)   ///
        OCMOde(integer 0)   ///
        OCMIn(integer  0)   ///
        OCNobs(integer 0)   ///
        OCNMISS(integer 0)  ///
        OCSd(integer 0)     ///
        OCVar(integer 0)    ///
    SPacer(integer 1)   /// spacing added to minimum with squeeze and optimize
    Range(string)       /// range of values
    Style(string)       /// define style of output
    FORCEN              /// force printing of N's
    Values(string)      /// values to show % of cases with that value
        OTHervalues         /// show total of other values
    aorder              /// alphabetize output
    First(string)       /// first variable to list
    Basic               /// just the basic table
    Columns(integer 0)  /// change all column widths
    Decimal(integer 0)  /// change all # of decimals
    CLABel(integer 25)  ///
    CNAme(integer 12)   ///
    CVAlues(integer 6)  DVAlues(integer 1) /// columns and decimal digits
    CPCTile(integer 10) DPCTile(integer 2) ///
    CMAx(integer 9)    DMAx(integer 2)    ///
    CMEan(integer 9)   DMEan(integer 2)   ///
    CMOde(integer 9)   DMOde(integer 2)   ///
    CMIn(integer  9)    DMIn(integer 2)    ///
    CNobs(integer 6)    DNobs(integer 0)   ///
    CNMISS(integer 7)   DNMISS(integer 0)  ///
    CSd(integer 9)     DSd(integer 2)     ///
    CVar(integer 9)    DVar(integer 2)    ///
    LEFTLabel           /// left justify var label
    LEFTName            /// left justify var name
    MINLabel            /// minimize column size of variable labels
    MINName             /// do not minimize column size of variable names
    NBasic              /// basic table with numbered rows
    NOHeader            /// surpress header
    NOMiss              /// drop all missing cases
    NUMber              /// number the list of variables
    Order(string)       /// order for displaying items
    RIGHTLabel          /// right justify var labels
    RIGHTName           /// right justify var names
    VERBose             /// add extra output
    MAXLength(integer 0) /// truncated label if exceeds this length
    M80 /// maxlength 80
    NCOL80 /// print columns
    Names /// only list names
    ]

    if "`m80'"=="m80" {
        local maxlength = 80
    }
    if "`ncol80'"=="ncol80" {
di "0        1         2         3         4         5         6         7         8"
di "12345678901234567890123456789012345678901234567890123456789012345678901234567890"
    }

//  default ordering of statistics -- change for different default

    local orderdefault "name nobs mean sd min max label"

//  valid names for statistics being printed; see synonyms below

    local validnms mean min max sd var name label nobs nmiss mode
    local validpct pct1 pct5 pct01 pct05 pct10 pct25 ///
        pct50 pct75 pct90 pct95 pct99
    local validall `validnms' `validpct' values

//  experiment with defaults

/*
local optimize "optimize"
if "`squeeze'"=="squeeze" {
    local optimize ""
}
if "`fixed'"=="fixed" {
    local fixed "fixed"
}
*/

//  locals used to keep track of things

    local drop_ifin = 0 // drop for if and in conditions
    local drop_total = 0 // drop for any reason
    local drop_miss = 0 // drop due to missing values

    local ISsamenobs = 1 // same N for all variables? assume yes to start
    local ISmissing = 0 // is there missing? assume no to start
    local ISnomissing = 1 // assume no missing to start
    local ISpct = 0 // need to compute percentile?
    local ISmode = 0 // only compute mode if requested since it can be slow
    local ISvalues = 0 // need to % at values?
    if "`values'"!="" {
       local ISvalues = 1 // need to % at values?
    }
    local ISno_n_equal = 0 // supress n= at end of list

//  variables to be analyzed

    if "`varlist'" == "" {
        unab varlist : _all // if none, use all
        * remove variable create with byable
        if "`_byindex'"!="" {
            local varlist = subinstr("`varlist'","`_byindex'","",.)
        }
    }

//  decode range of values

    if "`range'"!="" {
        local nrange = 0
        foreach r in `range' {
            local ++nrange
            if `nrange'==1 local r1 = `r'
            if `nrange'==2 local r2 = `r'
            if `nrange'==3 {
                di in red "range option can have only two values"
            }
        }
        if `r1'<`r2' {
            local rangemin = `r1'
            local rangemax = `r2'
        }
        else {
            local rangemin = `r2'
            local rangemax = `r1'
        }
        local rangelist ""
        forvalues v = `rangemin'(1)`rangemax' {
            local rangelist `rangelist' `v'
        }
        local ISvalues = 1 // need to % at values?
        local values `rangelist'
    }

//  set up for printing of labels and names

    * spaces before variable label
    if `spacer'==1 local labeloffset "  "
    if `spacer'==2 local labeloffset "   "
    if `spacer'==3 local labeloffset "    "
    if `spacer'==4 local labeloffset "     "
    if `spacer'==5 local labeloffset "      "
    if `spacer'==6 local labeloffset "       "
    if `spacer'==7 local labeloffset "        "
    if `spacer'==8 local labeloffset "         "
    if `spacer'==9 local labeloffset "          "
    * justification of label
    local lblsign "-" // left by default
    if "`rightlabel'"=="rightlabel" {
        local lblsign ""
    }
    if "`leftlabel'"=="leftlabel" {
        local lblsign "-"
    }
    * alignment of name
    local namesign "-" // left by default
    if "`rightname'"=="rightname" {
        local namesign ""
    }
    if "`leftname'"=="leftname" {
        local namesign "-"
    }

//  global changes to column and decimal settings

    if `decimal'!=0 {
        foreach n in max mean min sd var pctile values {
            local d`n' = `decimal'
        }
    }
    if `columns'!=0 {
        foreach n in max mean min sd var pctile values {
            local c`n' = `columns'
        }
    }

//  arrange order of variables

    * alphabetize the list
    if "`aorder'"=="aorder" {
        local varlistunsorted `varlist'
        local varlist : list sort varlistunsorted
    }
    * put the first variable in front of the list
    if "`first'"!="" {
        local varlist = subinstr("`varlist'","`first'","",.)
        local varlist `first' `varlist'
    }

//  decode order in which items are printed

    local pctlist "" // list to hold requested percentiles
    * default order of statistics if order not specified
    if "`order'"=="" {
        local order `orderdefault'
    }

//  define styles

    if "`style'"=="basic" | "`style'"=="b" {
        local style basic
        local order name nobs mean sd min max label
    }
    else if "`style'"=="check" | "`style'"=="c" {
        local style check
        local order name mean med mode min p1 p99 max nmiss
    }
    else if "`style'"=="missing" | "`style'"=="miss" | "`style'"=="m" {
        local style missing
        local order name nmiss nobs mean min max label
    }
    else if "`style'"=="names" | "`style'"=="n" | ///
        "`style'"=="nam" | "`style'"=="nm" | "`style'"=="name" | ///
        "`names'"=="names" {
        local style names
        local order name label
        if `clabel'==25 {
            local clabel = 45
        }
    }
    else if "`style'"=="outliers" | "`style'"=="out" | "`style'"=="o" {
        local style outliers
        local order name min p1 p5 p10 p90 p95 p99 max
    }
    else if "`style'"=="range" | "`style'"=="r" {
        local style range
        local order name nobs values label
    }

//  synonyms

    local order = subinword("`order'","median"  ,"pct50" ,.)
    local order = subinword("`order'","med"     ,"pct50" ,.)
    local order = subinword("`order'","minimum" ,"min"   ,.)
    local order = subinword("`order'","maximum" ,"max"   ,.)
    local order = subinword("`order'","variance","var"   ,.)
    local order = subinword("`order'","mn"      ,"mean"  ,.)
    local order = subinword("`order'","stddev"  ,"sd"    ,.)
    local order = subinword("`order'","val"     ,"values",.)
    local order = subinword("`order'","value"   ,"values",.)
    local order = subinword("`order'","lab"     ,"label" ,.)
    local order = subinword("`order'","lbl"     ,"label" ,.)
    local order = subinword("`order'","nm"      ,"name"  ,.)
    local order = subinword("`order'","nam"     ,"name"  ,.)
    local order = subinword("`order'","obs"     ,"nobs"  ,.)
    local order = subinword("`order'","n"       ,"nobs"  ,.)
    foreach p in 1 5 10 25 50 75 90 95 99 {
        local order = subinword("`order'","p`p'","pct`p'",.)
    }

//  check order and make sure statistics are valid

    local isexit = 0
    foreach o in `order' {
        * check if valid item
        local isbad = 1
        foreach n in `validall' {
            if "`o'"=="`n'" {
                local isbad = 0
            }
        }
        if `isbad' {
            di in red "invalid name in order(): `o'"
            local isexit = 1
        }
    }
    if `isexit'==1 {
        exit
    }

    * list of statistics in order to be output
    local outorder  "`order'"
    * number of items in list
    local norder = wordcount("`order'")
    * is value among items
    local print_value = 0
    * check is item in list
    local i = 0
    foreach o in `order' {
        local ++i
        if `i'==1 {
            * no lead spacing if listed first
            if "`o'"=="label" {
                local labeloffset ""
            }
        }
        if "`o'"=="mode" {
            local ISmode = 1
        }
        if "`o'"=="values" {
            local print_value = 1
        }
        * check if valid item
        local isvalid = strpos("`validall'","`o'")
        if `isvalid'==0 {
            di in red "invalid name in order(): `o'"
            exit
        }
        * if pct, decode and add to list
        local o3 = substr("`o'",1,3) // grab ## from pct##
        * check if percentile
        if "`o3'"=="pct" { // is percentile
            local ISpct = 1
            local pctnum = substr("`o'",4,5) // if pct## retrieve ##
            local pctnum = `pctnum' // strip off leading 0
            local pctlist `pctlist' `pctnum'
        }

    } // loop over output order

    * add values at end if values() but values not in order() list
    if `print_value'==0 & `ISvalues'==1 {
        local outorder `order' values
    }

//  if minlabel, determine smallest size that will fit label

    if "`minlabel'"=="minlabel" {
        local maxlab = 0
        * check length of each label
        foreach v in `varlist' {
            local `v'label :  variable label `v'
            local ll = length("``v'label'")
            if `ll'>`maxlab' {
                local maxlab = `ll'
            }
        }
        * set new column size for labels as spacer larger than minimum
        local clabel = `maxlab' + `spacer'
    }

//  if minname, determine smallest size that will fit names

    if "`minname'"=="minname" {
        local maxname = 0
        foreach v in `varlist' { // loop through variables
            local ll = length("`v'")
            if `ll'>`maxname' {
                local maxname = `ll'
            }
        }
        * set new column size for names
        local cname = `maxname' + `spacer'
    }

    * need at least 9 for name
    if "`nbasic'"=="nbasic" | "`basic'"=="basic" {
        if `cname'<8 local cname = 9
    }

//  define sample and check missing values - 0.4.0 - 28Jun2006 - byable

    tempvar touse
    * initially, just use if and in
    mark `touse' `if' `in'
    * count sample based on if and in
    qui count if `touse'==0
    local drop_ifin = r(N) // total droppedbased on if and in

    * if nomiss, drop missing  0.4.0
    if "`nomiss'"=="nomiss" {
        markout `touse' `varlist'
    }
    * counted after missing might be dropped
    qui count if `touse'==0
    local drop_total = r(N) // total to drop
    local drop_miss = `drop_total' - `drop_ifin'

    if "`verbose'"=="verbose" {
        di
        di "Dropped for if & in conditions: " _col(50) `drop_ifin'
        di "Dropped for missing data: " _col(50) `drop_miss'
        di "Dropped for if, in or missing:" _col(50) `drop_total'
    }
    if "`nomiss'"=="nomiss" {
        local ISsamenobs = 1 // since all missing are dropped, same N
        local ISmissing = 0 // no missing since all missing dropped
    }

//  compute statistics

    local vnum = 0

    foreach v in `varlist' { // loop through variables

        local ++vnum
        * if pctiles need, use detail
        if `ISpct'==1 {
            qui sum `v' if `touse', detail
            foreach p in `pctlist' {
                local `v'pct`p' = r(p`p')
            }
        }
        * pctiles not used
        else {
            qui sum `v' if `touse'
        }
        * statistics based on nonmissing
        local `v'mean = r(mean)
        local `v'sd = r(sd)
        local `v'var = r(Var)
        local `v'min = r(min)
        local `v'max = r(max)
        local `v'label :  variable label `v'
        local `v'name "`v'"
        local `v'nobs = r(N)
        local nnow = r(N)

        * mode - missing if multipe modes
        local `v'mode = .
        if `ISmode'==1 {
            tempvar vmode
            qui egen `vmode' = mode(`v') if `touse'
            local `v'mode = `vmode'[1]
        }
        * compute number missing
        capture confirm string variable `v'
        if !_rc { // action for string variables
            qui count if `v'=="" & `touse'
        }
        else { // action for numeric variables
            qui count if `v'>=. & `touse'
        }

        local `v'nmiss = r(N)
        local nmissprior = r(N)
        if ``v'nmiss'!=0 {
            local ISmissing = 1 // missing data
        }
        * determine if n varies across variables due to missing values
        if `vnum'==1 { // for 1st variable, assume N's are the same
            local nprior = `nnow'
        }
        else { // now compare to prior variable
            * if prior and current differ
            if `nprior'!=`nnow' {
                local ISsamenobs = 0 // if n's differ, change indicator
            }
            local nprior = `nnow'
        }
        * compute % with given values
        if `ISvalues'==1 {
            local n_notother = 0 // # in other categories
            * non missing N
            local n = ``v'nobs'
            * compute pct at each value
            foreach val in `values' {
                qui count if `v'==`val' & `touse'
                local nval = r(N)
                local n_notother = `n_notother' + `nval'
                local `v'pval`val' = 100 * (`nval'/`n')
            }
            local `v'pvalother = 100 * ((`n'-`n_notother')/`n')
        }

    } // loop through variables for computations

//  decide on whether to print nobs and nmiss

    local n_for_all = `nprior'

    * value to possibly print at end of table
    if `ISmissing'==1 {
        local nmiss_for_all = `nmissprior'
    }
    * if miss style, don't check on nobs
    if "`style'"!="missing" {
        * remove nobs and nmiss
        if `ISsamenobs'==1 & "`forcen'"!="forcen" {
            local outorder = subinword("`outorder'","nobs","",.)
            local outorder = subinword("`outorder'","nmiss","",.)
        }
    }
    local ISnobs_in_order = strpos("`outorder'","nobs")>0
    local ISnmiss_in_order = strpos("`outorder'","nmiss")>0

//  squeeze or optimize

    if "`squeeze'"=="squeeze" | "`optimize'"=="optimize" ///
            | `maxlength'>0 {

        * set counters for columns need to 0
        foreach o in `outorder' {
             * if pct##, change to percentile
                local o3 = substr("`o'",1,3)
                if "`o3'"=="pct" {
                    local o "pctile"
                }

            local cis`o' = 0
        }

        * check needed lengths for each statistic for each variable
        foreach v in `varlist' {

            * loop through items to print
            foreach o in `outorder' {

                * name
                if "`o'"=="name" {
                    local l = length("`v'")
                    local cisname = max(`cisname',`l')
                }

                * variable label
                else if "`o'"=="label" {
                    local oout "``v'`o''"
                    * the following reduces it to clabel size
                    * local oout = substr("`oout'",1,`clabel')
                    local l = length("`labeloffset'`oout'") + 2 // for two spaces
                    local cislabel = max(`cislabel',`l')
                }

                * number missing
                else if "`o'"=="nmiss" {
                    local ofmt "%`c`o''.`d`o''f"
                    local stat = ``v'nmiss'
                    local l = length(string(`stat',"`ofmt'"))
                    local cis`o' = max(`cis`o'',`l')
                }

                * values
                else if "`o'"=="values" {
                    local ofmt "%`cvalues'.`dvalues'f"
                    foreach val in `values' {
                        local stat = ``v'pval`val''
                        local l = length(string(`stat',"`ofmt'"))
                        local cis`o' = max(`cis`o'',`l')
                    }
                    if "`othervalues'"=="othervalues" {
                        local stat = ``v'pvalother'
                        local l = length(string(`stat',"`ofmt'"))
                        local cis`o' = max(`cis`o'',`l')
                    }
                }

                * percentiles
                local o3 = substr("`o'",1,3) // if pct## retrieve pct
                else if "`o3'"=="pct" {
                    local pctnum = substr("`o'",4,5) // if pct## retrieve ##
                    local pctnum = `pctnum' // strip off leading 0
                    local ofmt "%`cpctile'.`dpctile'f"
                    local stat = ``v'pct`pctnum''
                    local l = length(string(`stat',"`ofmt'"))
                    local cis`o' = max(`cis`o'',`l')
                }

                * other statistics
                else {
                    local ofmt "%`c`o''.`d`o''f"
                    local stat = ``v'`o''
                    local l = length(string(`stat',"`ofmt'"))
/*
if "`o'"=="min" | "`o'"=="max" {
    local s = string(`stat',"`ofmt'")
    di "____12345678901234"
    di "s: >`s'<"
    di "l: >`l'"
}
*/
                    local cis`o' = max(`cis`o'',`l')
                }

            } // loop through items to print

        } // loop through variables

        * if squeeze, change column sizes

        if "`squeeze'"=="squeeze" {
            foreach o in `outorder' {

                * if override value, don't squeeze
                if `oc`o''!=0 {
                    local c`o' = `oc`o''
                }

                * else use squeezed value
                else {
                    if `cis`o''<`sqmin' {
                        local cis`o' = `sqmin'
                    }
                    if `c`o''>`cis`o'' {
                        local c`o' = `cis`o'' + `spacer'
                    }
                }
/*
if "`o'"=="min" | "`o'"=="max" {
    di "c: `c`o''"
}
*/
            } // loop through outorder
        }

        * if optimize,
        if "`optimize'"=="optimize" {
            foreach o in `outorder' {

                * if pct##, change to percentile
                local o3 = substr("`o'",1,3)
                if "`o3'"=="pct" {
                    local o "pctile"
                }


                * if override value
                if `oc`o''!=0 {
                    local c`o' = `oc`o''
                }

                * else use optimize value
                else {
        *di "From `o': " _col(15) "`c`o''"
                    if `cis`o''<`optmin' {
                        local cis`o' = `optmin'
                    }
                    local c`o' = `cis`o'' + `spacer'
        *di "To   `o': " _col(15) "`c`o''"
                }
            } // outorder loop
        }

        * get current total length of output
        local tlen = 2
        foreach o in `outorder' {
            * if pct##, change to percentile
            local o3 = substr("`o'",1,3)
            if "`o3'"=="pct" {
                local o "pctile"
            }
            local tlen = `tlen' + `c`o''
        } // outorder loop

        * if exceeds maxlength, reduce label length
        if `maxlength' != 0 {
            if `tlen' > `maxlength' {
                local dif = `tlen' - `maxlength'
                local cl = `clabel'
                local clabel = `clabel' - `dif'
            }
        }
/*
di "clabel: `clabel'"
di "tlen `tlen'"
di "maxlength: `maxlength'"
di "dif: `dif'"
di "clabel: `clabel'"
*/


    } // squeeze or optimize

//  print column headings

    if "`noheader'"!="noheader" {

        display
        local no = 0
        foreach o in `outorder' {

            local ++no
            * if pct, retrieve ## from pct##
            local o3 = substr("`o'",1,3)
            local isopct = 0
            if "`o3'"=="pct" {
                local pctnum = substr("`o'",4,5) // if pct## retrieve ##
                local pctnum = `pctnum' // strip off leading 0
                local isopct = 1
            }
            * if number option, print variable number
            if "`number'"=="number" {
                * add space before first item
                if `no'==1 {
                    di _cont %2.0f "    "
                }
            }
            * heading for name
            if "`o'"== "name" {
                if `c`o''>8 {
                    di _cont %`namesign'`c`o''s "Variable"
                }
                else {
                    di _cont %`namesign'`c`o''s "Var"
                }
            }
            * heading for nobs
            else if "`o'"== "nobs" {
                local nonobs ""
                local ISno_n_equal = 1
                di _cont %`c`o''s "Obs"
            }
            * heading for nmiss
            else if "`o'"== "nmiss" {
                if `c`o''>7 {
                    di _cont %`c`o''s "Missing"
                }
                else {
                    di _cont %`c`o''s "#Miss"
                }
            }
            * heading for mean
            else if "`o'"== "mean" {
                di _cont %`c`o''s "Mean"
            }
            * heading for mode
            else if "`o'"== "mode" {
                di _cont %`c`o''s "Mode"
            }
            * heading for sd
            else if "`o'"== "sd" {
                if `csd'<=6 {
                    di _cont %`c`o''s "SD"
                }
                else {
                    di _cont %`c`o''s "StdDev"
                }
            }
            * heading for var
            else if "`o'"== "var" {
                if `c`o''>7 {
                    di _cont %`c`o''s "Variance"
                }
                else {
                    di _cont %`c`o''s "Var"
                }
            }
            * heading for minimum
            else if "`o'"== "min" {
                if `c`o''>7 {
                    di _cont %`c`o''s "Minimum"
                }
                else {
                    di _cont %`c`o''s "Min"
                }
            }
            * heading for max
            else if "`o'"== "max" {
                if `c`o''>7 {
                    di _cont %`c`o''s "Maximum"
                }
                else {
                    di _cont %`c`o''s "Max"
                }
            }
            * heading for variable label
            else if "`o'"== "label" {
*di "lblsign: `lblsign'"
*di "x: `c`o''"
                di _cont %`lblsign'`c`o''s "`labeloffset'Label"
            }
            * headings if % at given value
            else if "`o'"=="values" {
                foreach val in `values' {
                    di _cont %`c`o''s "%`val's"
                }
                if "`othervalues'"=="othervalues" {
                    di _cont %`c`o''s "%Other"
                }
            }
            * heading for percentiles
            else if "`o3'"=="pct" {
                if `pctnum'==50 {
                    di _cont %`cpctile's "Median"
                }
                else {
                    di _cont %`cpctile's "`pctnum'%"
                }
            } // pctile

        } // loop through order

    } // if no header

    display

//  loop through variables and print table

    local vnum = 0

    foreach v in `varlist' { // loop through variables

        local ++vnum

        if "`number'"=="number" {
            di _cont %2.0f `vnum' ". "
        }

        * loop through items to print
        foreach o in `outorder' {

             * name
            if "`o'"=="name" {
                local ofmt "%`namesign'`c`o''s"
                di _cont `ofmt' "``v'`o''"
            }
            * variable label
            else if "`o'"=="label" {
                local ofmt "%`lblsign'`c`o''s"
                local oout "``v'`o''"
                * truncate based on clabel
                local oout = substr("`oout'",1,`clabel')
                di _cont `ofmt' "`labeloffset'`oout'"
            }
            * number missing
            else if "`o'"=="nmiss" {
                local stat = ``v'nmiss'
                local ofmt "%`c`o''.`d`o''f"
                di _cont `ofmt' `stat'
            }
            * values
            else if "`o'"=="values" {
                local ofmt "%`cvalues'.`dvalues'f"
                foreach val in `values' {
                    local stat = ``v'pval`val''
                    di _cont `ofmt' `stat'
                }
                if "`othervalues'"=="othervalues" {
                    local stat = ``v'pvalother'
                    di _cont `ofmt' `stat'
                }
            }
            * percentiles
            local o3 = substr("`o'",1,3) // if pct## retrieve pct
            else if "`o3'"=="pct" {
                local pctnum = substr("`o'",4,5) // if pct## retrieve ##
                local pctnum = `pctnum' // strip off leading 0
                local ofmt "%`cpctile'.`dpctile'f"
                local stat = ``v'pct`pctnum''
                di _cont `ofmt' `stat'
            }
            * other statistics
            else {
                local ofmt "%`c`o''.`d`o''f"
                    local stat = ``v'`o''
                    di _cont `ofmt' `stat'
            }

        } // loop through items to print

        display

    } // loop through variables

    * only print N= if all same n
    if `ISsamenobs'==1 {

        * if nobs still in order, don't print it
        if `ISnobs_in_order'==0 {
            di _new "N = `n_for_all'"
        }
        if `ISnmiss_in_order'==0 {
            if `ISmissing'==1 {
                di "N missing = `nmiss_for_all'"
            }
        }
    }
end

