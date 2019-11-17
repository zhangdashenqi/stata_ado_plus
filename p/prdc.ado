*! version 0.0.4 jsl 13Apr2005 - beta version
*! To do: there are no IF, IN or ALL options
*! To do: Add if ystar or xb

capture program drop prdc
program define prdc, rclass
    version 8

*=> classify each valid type of model

    if "`e(cmd)'"=="cloglog"  {
        local io = "typical binary"
        }
    if "`e(cmd)'"=="gologit"  {
        local io = "typical ordered"
        }
    if "`e(cmd)'"=="logistic" {
        local io = "typical binary"
        }
    if "`e(cmd)'"=="logit"    {
        local io = "typical binary"
        }
    if "`e(cmd)'"=="mlogit"   {
        local io = "typical nomord"
        }
    if "`e(cmd)'"=="nbreg"    {
        local io = "typical count"
        }
    if "`e(cmd)'"=="ologit"   {
        local io = "typical nomord"
        }
    if "`e(cmd)'"=="oprobit"  {
        local io = "typical nomord"
        }
    if "`e(cmd)'"=="poisson"  {
        local io = "typical count"
        }
    if "`e(cmd)'"=="probit"   {
        local io = "typical binary"
        }
    if "`e(cmd)'"=="zinb"     {
        local io = "twoeq count"
        }
    if "`e(cmd)'"=="zip"      {
        local io = "twoeq count"
        }
    if "`io'"=="" {
        di
        di in y "prdc" in r " does not work for last model estimated."
        exit
    }

*=> decode input
    syntax [varlist(default=none)] ///
        [, x(string) Rest(passthru) LEvel(passthru) ///
        MAXcnt(passthru) noLAbel noBAse Brief Save Diff ///
        YStar ept DELta ///
        BOOTstrap REPs(passthru) SIze(passthru) DOts match ///
        NORMal PERCENTile BIAScorrected ///
        From(real 0) To(real 0) Change(real 0) ///
        BINary Unit SD UNCentered ]

local qui "quietly"

    local changetype "  Uncentered"
    if "`uncentered'"=="" {
        local changetype "  Centered"
    }

    if "`varlist'" =="" {
        di in red "you must specify a variable list."
        exit
    }

    * unit by default
    if `from'==0 & `to'==0 & `change'==0 ///
        & "`binary'"=="" & "`unit'"=="" & "`sd'"=="" {
        local unit "unit"
    }

    tempname mn sdval sdval2 fromto stval endval
    foreach v in `varlist' {

        matrix `fromto' = J(10,2,-99) // hold start and end
        local rownm ""
        local rows = 0
        qui sum `v' `if' `in'
        scalar `mn' = r(mean)
        scalar `sdval' = r(sd)
        local sdnm "sd"
        scalar `sdval2' = `sdval'/2
        if "`binary'"=="binary" {
            local rows = `rows' + 1
            local nm`rows' ""
            mat `fromto'[`rows',1] = 0
            mat `fromto'[`rows',2] = 1
        }
        if "`unit'"=="unit" {
            local rows = `rows' + 1
            local nm`rows' "[ -+1/2 ]"
            scalar `stval' = `mn' - 1/2
            if "`uncentered'"!="" {
                local nm`rows' "[ +1 ]"
                scalar `stval' = `mn'
            }
            scalar `endval' = `stval' + 1
            mat `fromto'[`rows',1] = `stval'
            mat `fromto'[`rows',2] = `endval'
        }
        if "`sd'"=="sd" {
            local rows = `rows' + 1
            local nm`rows' "[ -+sd/2 ]"
            scalar `stval' = `mn' - `sdval2'
            if "`uncentered'"!="" {
                local nm`rows' "[ +sd ]"
                scalar `stval' = `mn'
            }
            scalar `endval' = `stval' + `sdval'
            mat `fromto'[`rows',1] = `stval'
            mat `fromto'[`rows',2] = `endval'
        }
        if `change'!=0 {
            local rows = `rows' + 1
            local nm`rows' "[ -+(delta=`change'/2) ]"
            scalar `stval' = `mn' - (`change'/2)
            if "`uncentered'"!="" {
                local nm`rows' "[ +(delta=`delta') ]"
                scalar `stval' = `mn'
            }
            scalar `endval' = `stval' + `change'
            mat `fromto'[`rows',1] = `stval'
            mat `fromto'[`rows',2] = `endval'
        }
        if `from'==0 & `to'==0 {
        }
        else {
            local rows = `rows' + 1
            mat `fromto'[`rows',1] = `from'
            mat `fromto'[`rows',2] = `to'
            local nm`rows' ""
        }

        di _n in g "Discrete change for variable: " in y "`v' "

        tempname val dif diflb difub difmisc difout base stis endis
        foreach r of numlist  1/`rows'  {
            scalar `stis' = `fromto'[`r',1]
            scalar `endis' = `fromto'[`r',2]
            local xstis = `stis'
            local xendis = `endis'
      `qui' prvalue2, x(`x' `v'=`xstis') ///
              `rest' `level' save
            if `r'==1 {
                * get column names
                mat `val' = pepred[1,1...]
                local colnm ""
                local colnum = colsof(`val')
                foreach k of numlist  1/`colnum'  {
                    local a = `val'[1,`k']
                    local colnm "`colnm' `a'"
                }
            }
      `qui' prvalue2, x(`x' `v'=`xendis') ///
              `rest' `level' diff
            mat `dif' = pepred[6,1...]
            mat `diflb' = pelower[6,1...]
            mat `difub' = peupper[6,1...]
            mat `difmisc' = pepred[7,1...]
            matrix `difout' = `dif' \ `diflb' \ `difub'
            mat colnames `difout' = `colnm'
            mat rownames `difout' = "    Change" "    LowerBound" "    UpperBound"
            di _new in g "`changetype' change from " in y %6.4f `stis' ///
                in g " to " in y %6.4f `endis' ///
                in g " `nm`r''"
            mat list `difout', noheader
        } // rows

    } // list of variables

    * levels of variables
    mat `base' = r(x)
    mat list `base', noheader
end
