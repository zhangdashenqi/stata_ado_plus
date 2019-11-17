*--------------------------------------------------------------------------
* John H. Tyler                                ph. (617) 576-3507
* Harvard Graduate School of Education        fax  (617) 496-3095
* Internet: tylerjo@hugse1.harvard.edu
*--------------------------------------------------------------------------
*! version 3.0.1      11aug97  (John H. Tyler)  STB-40 sg73
program define modltbl
    version 5.0
    capture macro drop sigdig
    capture macro drop noR2
    local type `1'

    if "`type'"~="ts" & "`type'"~="se" {
        di in red "Invalid syntax."
        di
        di in red "1st argument to " in yellow "modltbl "/*
        */ in red "must be either " /*
        */ in yellow "ts " /*
        */ in red "or " /*
        */ in yellow "se " /*
        */ in red "."
        di
        di in red "Use " in yellow "ts " in red /*
        */"if you desire t-stats displayed."
        di in red "Use " in yellow "se " in red /*
        */"if you desire standard errors displayed."
        di
        exit 198
    }

    macro shift
    if substr("`1'",1,1)=="(" {
        OPTs `*'
        local rtparen=index("`1'",")")
        while `rtparen'==0 {
            macro shift
            local rtparen=index("`1'",")")
        }
        macro shift
    }
    *-------------------------------------------------
    * Separating out the title, if any, from the models
    *------------------------------------------------
    local comma=index("`*'", ",")
    if `comma'==0 {
        local models `*'
        local title ""
    }
    else if `comma'~=0 {
        local models=substr("`*'",1,`comma'-1)
        local title=substr("`*'",`comma'+1,.)
    }

    tempvar numvars
    local nummods : word count `models'
    local i 1
    while `i'<=`nummods' {
        local mdl`i' :word `i' of `models'
        local i=`i'+1
    }
    *----Setting tmpvars to the varlist of model in the first position
    local tmpvars ${vars`mdl1'}
    local k :word count `tmpvars'
    *---Moving past the first argument------------------------------
    *
    * The next section compares the pth var in the varlist of the ith
    * model to each var in tmpvars. If no match is found, the pth var
    * is added to tmpvars. If a match is found, the program goes to the
    * pth + 1 var in the varlist of the ith model
    *---------------------------------------------------------------
    local i 2
    while "`mdl`i''" ~= "" {
        if "${numvar`mdl`i''}"=="" {
            di in red "Model designations in -modltbl- command do not match" /*
              */ " model identifiers in your -modl- statements."
            exit 198
        }
        local p=1
        while `p'<=${numvar`mdl`i''} {
        /**    * Next take out embedded "." placeholders in the ith varlist
            local numdot=index("${vars`mdl`i''}",".")
            while `numdot'~=0 {
                local tvars1=substr("${vars`mdl`i''}",1,`numdot'-1)
                local tvars2=substr("${vars`mdl`i''}",`numdot'+2,.)
                global vars``i''="`tvars1'" + "`tvars2'"
                local numdot=index("${vars`mdl`i''}",".")
            }***/
            local varwrd : word `p' of ${vars`mdl`i''}
            local j=1
            *----------------------------------------------
            * Comparing the pth var of the ith varlist to each
            * jth var of tmpvars. k=number of vars currently in tmpvars.
            * k intially = number of vars in model in first position. k
            * is incremented for each var added to tmpvars
            *----------------------------------------------
            while `j'<=`k' {
                local tmp`j' : word `j' of `tmpvars'
                if "`varwrd'"~="`tmp`j''" {
                    local j=`j'+1
                }
                *---------------------------------------
                * If the pth var is matched to the jth
                * var, go to the pth + 1 word of the
                * ith varlist...get out of loop by setting
                * j=100
                *---------------------------------------
                else {
                    local varwrd ""
                    local j=100
                    local k=`k'-1
                }
            }
            * If pth word not found in tmpvars, add it, increment k
            local tmpvars  `tmpvars' `varwrd'
            local k=`k'+1
            local p=`p'+1
        }
        local i=`i'+1
    }
    *---Taking out embedded blanks in tmpvars----------
    local x=2
    local number :word count `tmpvars'
    local hold : word 1 of `tmpvars'
    while `x'<=`number' {
        local word : word `x' of `tmpvars'
        local hold `hold' `word'
        local x=`x'+1
    }
    *---Putting the control variables last in the tempvars list-----
    * This is the transition point from tmpvar to vars and I stack all of
    * the regression vars in vars1 and all of the control vars in vars2,
    * and then vars is vars1 vars2.
    *---------------------------------------------------------------
    local i 1
    local numvars : word count `tmpvars'
    while `i'<=`numvars' {
        local word : word `i' of `tmpvars'
        local z=substr("`word'",1,1)
        if "`z'"~="A" & "`z'"~="B" & /*
        */ "`z'"~="C" & "`z'"~="D" & /*
        */ "`z'"~="E" & "`z'"~="F" & /*
        */ "`z'"~="G" & "`z'"~="H" & /*
        */ "`z'"~="I" & "`z'"~="J" & /*
        */ "`z'"~="K" & "`z'"~="L" & /*
        */ "`z'"~="M" & "`z'"~="N" & /*
        */ "`z'"~="O" & "`z'"~="P" & /*
        */ "`z'"~="Q" & "`z'"~="R" & /*
        */ "`z'"~="S" & "`z'"~="T" & /*
        */ "`z'"~="U" & "`z'"~="V" & /*
        */ "`z'"~="W" & "`z'"~="X" & /*
        */ "`z'"~="Y" & "`z'"~="Z"   {
            local vars1 `vars1' `word'
            local i=`i'+1
        }
        else if "`z'"=="A" | "`z'"=="B" |/*
        */"`z'"=="C" | "`z'"=="D" |/*
        */"`z'"=="E" | "`z'"=="F" |/*
        */"`z'"=="G" | "`z'"=="H" |/*
        */"`z'"=="I" | "`z'"=="J" |/*
        */"`z'"=="K" | "`z'"=="L" |/*
        */"`z'"=="M" | "`z'"=="N" |/*
        */"`z'"=="O" | "`z'"=="P" |/*
        */"`z'"=="Q" | "`z'"=="R" |/*
        */"`z'"=="S" | "`z'"=="T" |/*
        */"`z'"=="U" | "`z'"=="V" |/*
        */"`z'"=="W" | "`z'"=="X" |/*
        */"`z'"=="Y" | "`z'"=="Z"  {
            local vars2 `vars2' `word'
            local i=`i'+1
        }
    }
    local vars `vars1' `vars2'
    global vars `vars'
    *-------Display results--setting up needed local macros--------------

    di
    di "$S_TIME on $S_DATE"
    di
    if "`title'"~="" {
        di "`title'"
        di
    }
    local i=1
    while "`mdl`i''"~="" {
        if "${spec`mdl`i''}"~="" {
            di "Model `mdl`i'': ${spec`mdl`i''}"
            local i=`i'+1
        }
        else {local i=`i'+1}
    }
    di
    if "`type'"=="ts" {di "(t-statistics in parentheses)" }
    else if "`type'"=="se" {
        di "(standard errors in parentheses with p<0.05 = ~, p<0.01 = *)"
    }
    *----------Setting the vector of displayed variables--------------
    tempvar num
    local v=1
    local numvars : word count `vars'
    *----------Attaching indexing numbers to the vector of displayed vars
    while `v'<=`numvars' {
        local var`v' : word `v' of `vars'
        local v=`v'+1
    }
 *---------Display model number------------------------------------------
    local length=7+12*`nummods'
    di _du(`length') "-"
    local i 1
    di  "Model :" _col(15) "`mdl`i''" _cont
    local i 2
    while "`mdl`i''"~="" {
        local j 1
        local h=12*`j'
        di _col(`h')  "`mdl`i''" _cont
        local i=`i'+1
        local j=`j'+1
    }
    di
*----------Display # of obs-----------------------------------------------
    di "# obs :" _col(7) ""  _cont
    local i=1
    while "`mdl`i''"~="" {
        local numlen=length("${obs`mdl`i''}")
        local h=10-`numlen'
        local g=`h'+`numlen'
        di _col(`h') %5.3f "${obs`mdl`i''}" _col(`g') "   " _cont
        local i=`i'+1
    }

    di
*----------Display dependent variable-------------------------------------
    di "Depvar:"  _cont
    local i=1
    while "`mdl`i''"~="" {
        local numlen=length("${depvar`mdl`i''}")
        local h=10-`numlen'
        local g=`h'+`numlen'
        di _col(`h') %5.3f "${depvar`mdl`i''}" _col(`g') "   " _cont
        local i=`i'+1
    }

    di
*---------Display variable name and coeff. estimate------------------------
    di _du(`length') "-"
    local k=1
    while `k'<=`numvars' {
        di "`var`k''" _col(7) " "_cont
        local i=1
        *-------------------------------------------------------------------
        * Note that each estimate and tstat (se) has 10 places within which
        * it must fit, and this allows for 1 space before and one space after
        * each display, hence the code, "local h=12-`numlen'".
        *-------------------------------------------------------------------
        while "`mdl`i''"~="" {
            if "`type'"=="se" {
                *----Program to display ests. if "se" option chosen--------
                DISPse "${e`var`k''`mdl`i''}" "${a`var`k''`mdl`i''}" /*
                */ "$sigdig" coeffest
                local i=`i'+1
            }
            else if "`type'"=="ts" {
                *----Program to display ests. if "ts" option chosen--------
                DISPts "${e`var`k''`mdl`i''}" "$sigdig" coeffest
                local i=`i'+1
            }
        }
        dis
*--------Display standard errors---------------------------------------------
        if "`type'"=="se" {
            dis _col(7) " " _cont
            local i=1
            while "`mdl`i''"~="" {
                *----Program to display ests. if "se" option chosen--------
                DISPse "${s`var`k''`mdl`i''}" "${a`var`k''`mdl`i''}" /*
                */ "$sigdig" se
                local i=`i'+1
            }
            dis
            dis
            local k=`k'+1
        }
        else if "`type'"=="ts" {
            dis _col(7) " " _cont
            local i=1
            while "`mdl`i''"~="" {
                *----Program to display ests. if "ts" option chosen--------
                DISPts "${t`var`k''`mdl`i''}" 2 ts
                local i=`i'+1
            }
            dis
            dis
            local k=`k'+1
        }
    }
    di _du(`length') "-"
    *--------Display R-squared statistic--------------------------------------
    if "$noR2"~="no" {
        di "R-sq" _col(7) " "  _cont
        local i=1
        while "`mdl`i''"~="" {
            local numlen=length("${rsq`mdl`i''}")
            local h=11-`numlen'
            local g=`h'+`numlen'
            di _col(`h') %5.3f "${rsq`mdl`i''}"  _col(`g') "  " _cont
            local i=`i'+1
        }
        di
        local i 1
        while `i'<=`nummods' {
            global mdl`i' `mdl`i''
            local i=`i'+1
        }
    }
    *----------------------------------------------------------------
    * Displaying resuls of F and chisq tests
    *----------------------------------------------------------------
    DItests f `nummods' `length'
    DItests x `nummods' `length'
    local i 1
    while `i'<=`nummods' {
        capture mac drop mdl`i'
        local i=`i'+1
    }
    di _du(`length') "="
    capture macro drop sigdig
    capture macro drop noR2
end

*-----------Beginning of subroutines-------------------------------------
*------------------------------------------------------------------------
* This program formats ests. to have 4 decimal places
*------------------------------------------------------------------------
program define FORMAT4
    version 4.0
    local thisest "`1'"
    local thisest=round(`thisest',.0001)
    scalar ind=index("`thisest'",".")
    local thisest=substr("`thisest'",1,scalar(ind)+4)
    if substr("`thisest'",1,1)=="." {
        local thisest = "0" + "`thisest'"
    }
    else if substr("`thisest'",1,1)=="-" & substr("`thisest'",2,1)=="." {
        local thisest = "-0" + substr("`thisest'",2,.)
    }
    if "`thisest'"=="0" {local thisest="0.0000"}
    if index("`thisest'",".")==0 {local thisest="`thisest'" + ".0000"}
    if substr("`thisest'",index("`thisest'",".")+4,index("`thisest'",".")+4) /*
    */ =="" {
        local thisest="`thisest'"+"0"
    }
    if substr("`thisest'",index("`thisest'",".")+3,index("`thisest'",".")+4) /*
    */ =="" {
        local thisest="`thisest'"+"00"
    }
    if substr("`thisest'",index("`thisest'",".")+2,index("`thisest'",".")+4) /*
    */ =="" {
        local thisest="`thisest'"+"000"
    }
    global frmatest "`thisest'"
end

*------------------------------------------------------------------------
* This program formats ests. to have 3 decimal places
*------------------------------------------------------------------------
program define FORMAT3
    version 4.0
    local thisest "`1'"
    local thisest=round(`thisest',.001)
    scalar ind=index("`thisest'",".")
    local thisest=substr("`thisest'",1,scalar(ind)+3)
    if substr("`thisest'",1,1)=="." {
        local thisest = "0" + "`thisest'"
    }
    else if substr("`thisest'",1,1)=="-" & substr("`thisest'",2,1)=="." {
        local thisest = "-0" + substr("`thisest'",2,.)
    }
    if "`thisest'"=="0" {local thisest="0.000"}
    if index("`thisest'",".")==0 {local thisest="`thisest'" + ".000"}
    if substr("`thisest'",index("`thisest'",".")+3,index("`thisest'",".")+3) /*
    */ =="" {
        local thisest="`thisest'"+"0"
    }
    if substr("`thisest'",index("`thisest'",".")+2,index("`thisest'",".")+3) /*
    */ =="" {
        local thisest="`thisest'"+"00"
    }
    global frmatest "`thisest'"
end


*------------------------------------------------------------------------
* This program formats ests. to have two decimal places...for use w/ t-stats
*------------------------------------------------------------------------
program define FORMAT2
    version 4.0
    local thisest "`1'"
    local thisest=round(`thisest',.01)
    scalar ind=index("`thisest'",".")
    local thisest=substr("`thisest'",1,scalar(ind)+2)
    if substr("`thisest'",1,1)=="." {
        local thisest = "0" + "`thisest'"
    }
    else if substr("`thisest'",1,1)=="-" & substr("`thisest'",2,1)=="." {
        local thisest = "-0" + substr("`thisest'",2,.)
    }
    if "`thisest'"=="0" {local thisest="0.00"}
    if index("`thisest'",".")==0 {local thisest="`thisest'" + ".00"}
    if substr("`thisest'",index("`thisest'",".")+2,index("`thisest'",".")+2) /*
    */ =="" {
        local thisest="`thisest'"+"0"
    }
    global frmatest "`thisest'"
end
*-------------------------------------------------------------------------
* This program formats display when the "se" option is chosen, allowing
* 3 decimal places for coeff. ests. and se ests., and truncating decimal
* places when the whole number portion of the est. is too large to fit into
* the allotted space. The difference in this and in DISPts is that * and ~
* are added to ests. in this program, and if not applicable, " " (a space)
* is added so that ests. will line up.
*-------------------------------------------------------------------------
program define DISPse
    version 4.0
    local thisest "`1'"
    local aval "`2'"
    local sigdig "`3'"
    local type "`4'"
    if "`thisest'"=="Yes  " | "`thisest'"=="---  " | "`thisest'"=="" {
        local control "yes"
        global frmatest "`thisest'"
    }
    else {
        if "$sigdig"=="" & "`control'"~="yes" {
            FORMAT3 `thisest'
        }
        else {
            if "$sigdig"~="" & "`control'"~="yes" {
                FORMAT$sigdig `thisest'
            }
        }
    }
    if "`thisest'"=="" {global frmatest "   "}
    if "`type'"=="se" {local aval " "}
    if "`type'"=="coeffest" & "`aval'"=="" {local aval " "}
    if "`type'"=="coeffest" {local numlen=length("$frmatest`aval'")}
        else {local numlen=length("$frmatest`aval'")+2}
    if `numlen'>10 {
        SHORTen $frmatest `numlen' "$sigdig" "`aval'" "`type'"
    }
    /***
    *-------------------------------------------------------
    * This part removes the last two decimal places from estimates
    * that are so large that they don't fit in the 10 space limit.
    * If still too large, remove the last decimal place and the
    * decimal itself. If still too large, display error msg.
    *-------------------------------------------------------
    if `numlen'>10 & substr("$frmatest",1,1)~="(" {
        global frmatest=substr("$frmatest",1,index("$frmatest",".")+1)
        local numlen=length("$frmatest`aval'")
        if `numlen'>10 {
           global frmatest=substr("$frmatest",1,index("$frmatest",".")-1)
           local numlen=length("$frmatest`aval'")
           if `numlen'>10 {
              di
              di in red "Some estimated coefficients are too" /*
              */" long to fit in the alotted space in the table."
              di in yellow "Try choosing the " _quote "tstat" /*
              */ _quote " option to perhaps provide more room."
              exit 130
           }
        }
    }
    else if `numlen'>10 & substr("$frmatest",1,1)=="(" {
        local thisest=substr("$frmatest",1,index("$frmatest",".")+1)+")"
        local numlen=length("$frmatest`aval'")
        if `numlen'>10 {
           local thisest=substr("$frmatest",1,index("$frmatest",".")-1)+")"
           local numlen=length("$frmatest`aval'")
           if `numlen'>10 {
              di
              di in red "Some estimated coefficients are too" /*
              */" long to fit in the alotted space in the table."
              di in yellow "Try choosing the " _quote "tstat" /*
              */ _quote " option to perhaps provide more room."
              exit 130
           }
        }
    }
    ***/
    if "$numlen"~="" {
        local numlen=$numlen
        macro drop numlen
    }
    local h=12-`numlen'
    local g=`h'+`numlen'
    if "`type'"=="coeffest" {
        di _col(`h') %5.3f "$frmatest`aval'" _col(`g') " "  _cont
    }
    if "`type'"=="se" & "`control'"~="yes" {
        di _col(`h') %5.3f "($frmatest)`aval'" _col(`g') " "  _cont
    }
    if "`type'"=="se" & "`control'"=="yes" {
        di _col(`h') %5.3f "  $frmatest`aval'" _col(`g') " "  _cont
    }
    macro drop frmatest
end

*-------------------------------------------------------------------------
* This program formats display when the "ts" option is chosen, allowing
* 3 decimal places for coeff. ests. and se ests., and truncating decimal
* places when the whole number portion of the est. is too large to fit into
* the allotted space.
*-------------------------------------------------------------------------
program define DISPts
    version 4.0
    local thisest "`1'"
    local sigdig "`2'"
    local type "`3'"
    if "`thisest'"=="Yes  " | "`thisest'"=="---  " | "`thisest'"=="" {
        local control "yes"
        global frmatest "`thisest'"
    }
    else {
        if "$sigdig"=="" & "`type'"=="coeffest" & "`control'"~="yes" {
            FORMAT3 `thisest'
        }
        else {
            if "$sigdig"~="" & "`type'"=="coeffest" & "`control'"~="yes" {
                FORMAT$sigdig `thisest'
            }
            else {
                if "`type'"=="ts" {
                    FORMAT2 `thisest'
                }
            }
        }
    }
    if "`thisest'"=="" {global frmatest "   "}
    if "`type'"=="coeffest" {local numlen=length("$frmatest")}
        else {local numlen=length("$frmatest")+2}
    if `numlen'>10 {
        SHORTen $frmatest `numlen' "$sigdig" "`aval'" "`type'"
    }
    /***
    *-------------------------------------------------------
    * This part removes the last two decimal places from estimates
    * that are so large that they don't fit in the 10 space limit.
    * If still too large, remove the last decimal place and the
    * decimal itself. If still too large, display error msg.
    *-------------------------------------------------------
    if `numlen'>10 {
        global frmatest=substr("$frmatest",1,index("$frmatest",".")+1)
        local numlen=length("$frmatest")
        if `numlen'>10 {
            global frmatest=substr("$frmatest",1,index("$frmatest",".")-1)
            local numlen=length("$frmatest")
            if `numlen'>10 {
                di
                di in red "Some estimated coefficients are too" /*
                */" long to fit in the alotted space in the table."
                di in yellow "Try choosing the " _quote "tstat" /*
                */ _quote " option to perhaps provide more room."
                exit 130
            }
        }
    }
    ***/
    if "$numlen"~="" {
        local numlen="$numlen"
        macro drop numlen
    }
    local h=12-`numlen'
    local g=`h'+`numlen'
    if "`type'"=="coeffest" {
        di _col(`h') %5.3f "$frmatest" _col(`g') " "  _cont
    }
    if "`type'"=="ts" & "`control'"~="yes" {
        di _col(`h') %5.3f "($frmatest)" _col(`g') " "  _cont
    }
    if "`type'"=="ts" & "`control'"=="yes" {
        di _col(`h') %5.3f "  $frmatest" _col(`g') " "  _cont
    }
    macro drop frmatest
end

*------------------------------------------------------------------------
* This progarm displays results of F and chisq tests
*------------------------------------------------------------------------
program define DItests
    local z `1'
    if "`z'"=="f" {local bigz "F"}
    else if "`z'"=="x" {local bigz "chi2"}
    local nummods `2'
    local length `3'
    local i 1
    local mark1 0
    while `i'<=`nummods' {
        local k 1
        while `k'<10 {
            if "${`z'tst${mdl`i'}`k'}"~="" {
                local ho`z'`k' `k'
                local mark1=`mark1'+1
                local k=`k'+1
            }
            else {
                local k=`k'+1
            }
        }
        local i=`i'+1
    }

    local mark 0
    local k 1
    while `k'<10 {
        if "`ho`z'`k''"~="" {
            local mark=`mark'+1
            if `mark'==1 {di _du(`length') "-"}
            else if `mark'>1 {di "-------"}
            di "Ho_`k':,
            if "`z'"=="f" {local dithis "`bigz'   "}
            else if "`z'"=="x" {local dithis "`bigz'"}
            di "Pr>" "`dithis'" _cont
            local i=1
            local j=0
                while "${mdl`i'}"~="" {
                    local numlen=5
                    local h=11-`numlen'
                    local g=`h'+ `numlen'
                    if "${`z'tst${mdl`i'}`k'}"~="" {
                        di _col(`h') /*
                         */ %5.3f ${`z'tst${mdl`i'}`k'} _col(`g') "  " _cont
                        local i=`i'+1
                        local j=`j'+1
                    }
                    else {
                        di _col(`h') "     " _col(`g') "  " _cont
                        local i=`i'+1
                        local j=`j'+1
                    }
                }
            di
            local k=`k'+1
        }
        else {
            local k=`k'+1
        }
    }
    if `mark1'>0 {di _du(`length') "="}

    local k 1
    while `k'<10 {
        if "`ho`z'`k''"~=""  {
            if "`z'"=="f" {
                di "Ho_`k', `bigz': ${null`k'}"
            }
            else if "`z'"=="x" {
                di "Ho_`k', `bigz': ${null`k'}"
            }
        }
        local k=`k'+1
    }
end
*---------------------------------------------------------------------------
* Program to deal w/ number of decimals and noR2 options
*---------------------------------------------------------------------------
program define OPTs
    version 4.0
    * If there is a blank space after left paren., shift
    if substr("`1'",2,1)=="" {
        macro shift
    }
    * Now, is the right-paren abutted or not?
    local paren=index("`1'","(")
    * Yes case
    if `paren'==1 {
        if index("`1'",")")==0 {
            local opt=substr("`1'",2,.)
        }
        else {
            local opt=substr("`1'",2,length("`1'")-2)
        }
    }
    * No case
    else if `paren'==0 {
        local opt=substr("`1'",1,.)
    }
    if "`opt'"=="2"|"`opt'"=="3"|"`opt'"=="4" {
        global sigdig=`opt'
        macro shift
    }
    else if "`opt'"=="noR2" {
        global noR2 "no"
        macro shift
    }
    if "`1'"=="" {
        exit
    }
    * Separating cases where right-paren is abutted vs. not abutted
    if index("`1'",")")~=0 {local opt=substr("`1'",1,index("`1'",")")-1)}
        else {local opt "`1'"
    }
    if "`opt'"=="2"|"`opt'"=="3"|"`opt'"=="4" {
        global sigdig=`opt'
    }
    else if "`opt'"=="noR2" {
        global noR2 "no"
    }
end

*--------------------------------------------------------------------------
* Program to shorten estimates by truncating decimal places if the ests.
* are too long for the 10 space limit
*--------------------------------------------------------------------------
program define SHORTen
    local frmtest "`1'"
    local numlen="`2'"
    local sigdig="`3'"
    if "`sigdig'"=="" {local sigdig=3}
    local aval "`4'"
    local type "`5'"
    if "`type'"=="ts" {local sigdig=2}
    local deci=index("`frmtest'",".")
    *------------------------------------------------------
    * Begin by taking off the right-most digit
    *------------------------------------------------------
    local frmtest=substr("`frmtest'",1,(`deci'+`sigdig'-1))
    if "`type'"=="coeffest" {local numlen=length("`frmtest'`aval'")}
    else if "`type'"=="se"|"`type'"=="ts" {
        local numlen=length("`frmtest'`aval'")+2
    }
    if `numlen'>10 & `sigdig'==2 {
        local frmtest=substr("`frmtest'",1,`deci')
        if "`type'"=="coeffest" {local numlen=length("`frmtest'`aval'")}
        else if "`type'"=="se"|"`type'"=="ts" {
            local numlen=length("`frmtest'`aval'")+2
        }
        if `numlen'>10 {
            di
            di in red "Some estimates are too" /*
            */" long to fit in the alotted space in the table."
            di in yellow "Try choosing the " _quote "tstat" /*
            */ _quote " option to provide more room."
            exit 130
        }
    }
    if `numlen'>10 & `sigdig'==3 {
        local frmtest=substr("`frmtest'",1,`deci'+`sigdig'-2)
        if "`type'"=="coeffest" {local numlen=length("`frmtest'`aval'")}
        else if "`type'"=="se"|"`type'"=="ts" {
            local numlen=length("`frmtest'`aval'")+2
        }
        if `numlen'>10 {
            local frmtest=substr("`frmtest'",1,`deci')
            if "`type'"=="coeffest" {local numlen=length("`frmtest'`aval'")}
            else if "`type'"=="se"|"`type'"=="ts" {
                local numlen=length("`frmtest'`aval'")+2
            }
            if `numlen'>10 {
                di
                di in red "Some estimates are too" /*
                */" long to fit in the alotted space in the table."
                di in yellow "Try choosing the " _quote "tstat" /*
                */ _quote " option to provide more room."
                exit 130
            }
        }
    }
    if `numlen'>10 & `sigdig'==4 {
        local frmtest=substr("`frmtest'",1,`deci'+`sigdig'-2)
        if "`type'"=="coeffest" {local numlen=length("`frmtest'`aval'")}
        else if "`type'"=="se"|"`type'"=="ts" {
            local numlen=length("`frmtest'`aval'")+2
        }
        if `numlen'>10 {
            local frmtest=substr("`frmtest'",1,`deci'+`sigdig'-3)
            if "`type'"=="coeffest" {local numlen=length("`frmtest'`aval'")}
            else if "`type'"=="se"|"`type'"=="ts" {
                local numlen=length("`frmtest'`aval'")+2
            }
            if `numlen'>10 {
                local frmtest=substr("`frmtest'",1,`deci')
                if "`type'"=="coeffest" /*
                */{local numlen=length("`frmtest'`aval'")}
                else if "`type'"=="se"|"`type'"=="ts" {
                    local numlen=length("`frmtest'`aval'")+2
                }
                if `numlen'>10 {
                    di
                    di in red "Some estimates are too" /*
                    */" long to fit in the alotted space in the table."
                    di in yellow "Try choosing the " _quote "tstat" /*
                    */ _quote " option to provide more room."
                    exit 130
                }
            }
        }
    }
    global frmatest "`frmtest'"
    global numlen=`numlen'
end
