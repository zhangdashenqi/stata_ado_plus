*--------------------------------------------------------------------------
* John H. Tyler                                ph. (617) 576-3507
* Harvard Graduate School of Education        fax  (617) 496-3095
* Internet: tylerjo@hugse1.harvard.edu   or   john_tyler@hugse1.harvard.edu
*--------------------------------------------------------------------------
*! version 2.2.1        11aug97  (John H. Tyler)  STB-40 sg73
program define testres
    version 5.0

    *-----------------------------------------------------------------------
    * Separating out the text description of the null hypothesis, if any,
    * from the models
    *-----------------------------------------------------------------------
    local comma=index("`*'", ",")
    if `comma'==0 {
        local modnum `1'
        local tstnum `2'
    }
    else if `comma'~=0 {
        local tests=substr("`*'",1,`comma'-1)
        local modnum : word 1 of `tests'
        local tstnum : word 2 of `tests'
        global null`tstnum'=substr("`*'",`comma'+1,.)

    }
    confirm integer number `tstnum'
    if `tstnum'>9 {
        di in red "The test-designator in -testres- must take on a number" /*
        */ " between 1 and 9."
        di in red "Change the value of `tstnum' in your -testres- syntax."
        exit 198
    }
    if length("`modnum'")>1 {
        di in red "The model-designator in -testrers- must be 1 character" /*
        */ " and must correspond to the immediately preceding model" /*
        */" identifier."
        di
        di in red "Change the value of `modnum' in your -testres- syntax."
        exit 198
    }

    local stat=_result(6)
    local df1=_result(3)
    local df2=_result(5)
    if "`stat'"=="" {
        di in red "Cannot find results from the last -test- command."
        exit 198
    }
    if "`df2'"~="." {
        local thistst=round(fprob(`df1',`df2',`stat'),.001)
        if "`thistst'"=="0" {local thistst "0.000"}
        global ftst`modnum'`tstnum'= /*
         */substr("`thistst'",1,index("`thistst'",".")+3)
        if substr("${ftst`modnum'`tstnum'}",1,1)~="0" {
            global ftst`modnum'`tstnum'="0" + "${ftst`modnum'`tstnum'}"
        }
    }
    if "`df2'"=="." {
        local thistst=round(chiprob(`df1',`stat'),.001)
        if "`thistst'"=="0" {local thistst "0.000"}
        global xtst`modnum'`tstnum'= /*
         */ substr("`thistst'",1,index("`thistst'",".")+3)
        if substr("${xtst`modnum'`tstnum'}",1,1)~="0" {
            global xtst`modnum'`tstnum'="0" + "${xtst`modnum'`tstnum'}"
        }
    }
end
exit
