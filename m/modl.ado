*--------------------------------------------------------------------------
* John H. Tyler                                ph. (617) 576-3507
* Harvard Graduate School of Education        fax  (617) 496-3095
* Internet: tylerjo@hugse1.harvard.edu
*--------------------------------------------------------------------------
*!version 3.0.3      11aug97  (John H. Tyler)  STB-40 sg73
program define modl
    version 5.0

    capture macro drop thsmod
    capture macro drop format3
    capture macro drop format2
    capture macro drop uservars
    capture macro drop nocon
    capture macro drop ccol
    capture macro drop c
    capture matrix drop B
    capture matrix drop V
    local command "$S_E_cmd"
    if "`command'"=="xtreg" {
        local command "$S_E_cmd2"
    }

    if "`command'"=="" {
        di in red "Last estimates not found."
        di in ye "modl " in red "must immediately follow an " /*
        */ "estimation procedure."
        exit 301
    }
    tempname obs rsq
    matrix V = get(VCE)
    matrix B = get(_b)

    *------------------------------------------------------------------
    * Making sure the model is one character and stands alone
    *------------------------------------------------------------------
    if substr("`1'",2,1)~="" {
        di in red "The " _quote "model identifier" _quote " you use must" /*
        */ " be an alpha-numeric character of length 1, and it must be" /*
        */ " followed by a blank space."
        exit 198
    }

    global thsmod `1'
    macro shift

    *--------------------------------------
    * Making sure that "nocon" is flanked by blank spaces
    *--------------------------------------
    if substr("`1'",1,5)=="nocon" & substr("`1'",6,1)~="" {
        di in red "The " _quote "noncon" _quote " option must have a" /*
        */ " blank space on either side."
        exit 198
    }
    local frstarg "`1'"
    *--------------------------------------
    * Making sure that "nocon" is used if the model does not include a
    * constant and picking out the column the constant is in =>
    * "global ccol `i'"
    *--------------------------------------
    local coeffs : colnames(B)
    local ncoeffs : word count `coeffs'
    scalar ncoeffs=`ncoeffs'
    local i 1
    while `i'<= ncoeffs {
        local cname : word `i' of `coeffs'
        if "`cname'"~="_cons" {
            local i=`i'+1
        }
        else if "`cname'"=="_cons" {
            local cons `cname'
            global ccol `i'
            local i=`i'+1
        }
    }
    if "`cons'"=="" & "`frstarg'"~="nocon" {
        di in red "The last model did not have a constant included.
        di in red "Choose the " _quote "nocon" _quote /*
        */ " option with the modl command."
        exit 198
    }
    *---------------------------------------------------------------------
    * Getting ests of constant term if "nocon" not chosen
    *---------------------------------------------------------------------
    if "`frstarg'"~="nocon" {
        GETests intcpt $ccol
    }
    *---------------------------------------------------------------------
    * Getting estimates of other vars if "nocon" not chosen
    *---------------------------------------------------------------------
    if "`frstarg'"~="nocon" {
        local fstvars `*'
        USERvars `fstvars'
    }
    *---------------------------------------------------------------------
    * Getting other estimates if "nocon" chosen
    *---------------------------------------------------------------------
    else if "`frstarg'"=="nocon" {
        global nocon `frstarg'
        macro shift
        local fstvars `*'
        USERvars `fstvars'
    }
    *---------------------------------------------------------------------
    * Doing checks on the number of vars chosen and disallowed characters
    *---------------------------------------------------------------------
    local varnum :word count $uservars
    local i = 1
    local j = 1
    local numrhs = 0
    while `i' <= `varnum' {
        local var : word `i' of $uservars
        local z=substr("`var'",1,1)
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
            local numrhs=`numrhs'+1
            if "$nocon"=="" & "`var'"=="intcpt" {
               local numrhs=`numrhs'-1
            }
        }
        local i=`i'+1
    }

    *---------------------------------------------------------------------
    * Check # of requested vars in -modl- with rhs vars in estimation
    *---------------------------------------------------------------------
    CKVARnm `command' `numrhs'
    *---------------------------------------------------------------------
    * Check that -modl- vars don't contain disallowed characters
    *---------------------------------------------------------------------
    local i 1
    local chkvar : word `i' of $uservars
    while "`chkvar'"~="" {
        ISOKvar "`chkvar'"
        local i=`i'+1
        local chkvar : word `i' of $uservars
    }
    *---------------------
    * Getting # of obs
    *---------------------
    global obs$thsmod=_result(1)
    *---Getting obs if not in _result(1)-----------------------------------
    if "${obs$thsmod}"=="" | "${obs$thsmod}"=="." | "`command'"=="eivreg" {
        global obs$thsmod $S_E_nobs
    }
    *---------------------
    * Getting R-sq.
    *---------------------
    local rsq=round(_result(7),.001)
    *---Getting R-sq if not in _result(7)----------------------------------
    if ("`rsq'"=="" | "`rsq'"==".") & "$S_E_r2"~="" {
        local rsq=round($S_E_r2,.001)
    }
    else if ("`rsq'"=="" | "`rsq'"==".") {local rsq "."}
    if "`rsq'"~="0" {global rsq$thsmod "0" + "`rsq'"}
    else if "`rsq'"=="0" {global rsq$thsmod "0.000"}
    local dec=index("${rsq$thsmod}",".")
    global rsq$thsmod=substr("${rsq$thsmod}",1,`dec'+3)
    if "`command'"=="xtreg_re" {global rsq$thsmod "--"}
    global depvar$thsmod $S_E_depv
    *---------------------
    * R-sq if hreg2sls
    *---------------------
    if "`command'"=="hreg2sls" {
        global depvar$thsmod $S_dv
        global obs$thsmod $S_E_nobs
        global rsq$thsmod="."
    }
    *---------------------------------
    * Formatting the R2 global macro
    *---------------------------------
    *FORMr2 "${rsq$thsmod}" "$thsmod"

    global vars$thsmod $uservars
    local number: word count ${vars$thsmod}
    global numvar$thsmod `number'
    capture macro drop thsmod
    capture macro drop format3
    capture macro drop format2
    capture macro drop setvars
    capture macro drop uservars
    capture macro drop nocon
    capture macro drop c
    capture macro drop ccol
    capture matrix drop B
    capture matrix drop V
end

*-----------Beginning of subroutines-------------------------------------
*------------------------------------------------------------------------
* This program formats ests. to have 3 decimal places...for use w/ coeff.
* ests. and se ests.
*------------------------------------------------------------------------
program define FORMAT3
    version 4.0
    local thisest="`1'"
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
    global format3 "`thisest'"
end


*------------------------------------------------------------------------
* This program formats ests. to have two decimal places...for use w/ t-stats
*------------------------------------------------------------------------
program define FORMAT2
    version 4.0
    local thisest="`1'"
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
    global format2 "`thisest'"
end


*------------------------------------------------------------------------
* This program checks to make sure that the chosen variable names do not
* have unacceptable characters in them.
*------------------------------------------------------------------------
program define ISOKvar
    version 4.0
        if index("`1'","`")~=0 | index("`1'","~")~=0 | index("`1'","!")~=0 |/*
        */ index("`1'","@")~=0 | index("`1'","#")~=0 | index("`1'","$")~=0 |/*
        */ index("`1'","%")~=0 | index("`1'","^")~=0 {
            di in red "Improper syntax in variable name " _quote "`1'" /*
            */_quote "."
            exit 198
        }
        else if index("`1'","&")~=0 &/*
        */ index("`1'","*")~=0 | index("`1'","(")~=0 | index("`1'",")")~=0 |/*
        */ index("`1'","-")~=0 | index("`1'","+")~=0 | index("`1'","=")~=0 {
            di in red "Improper syntax in variable name " _quote "`1'" /*
            */_quote "."
            exit 198
        }
end

*------------------------------------------------------------------------
* This program formats the R-squared statistics.
*------------------------------------------------------------------------
program define FORMr2
    version 4.0
    local r2 `1'
    local thsmod `2'
    if length("`r2'")==3 {global rsq$thsmod="`r2'"+"00"}
    if length("`r2'")==4 {global rsq$thsmod="`r2'"+"0"}
    if "`r2'"=="0." {global rsq$thsmod=".   "}
    if "`r2'"=="." {global rsq$thsmod=".   "}
end

*----------------------------------------------------------------------
* Making sure that the # of vars in the model statement does not exceed
* the number of RHS vars
*----------------------------------------------------------------------
program define CKVARnm
    version 4.0
    local command `1'
    local numrhs `2'
    local rhsvars= _result(3)
    if "`command'"~="xtreg_fe" & `numrhs'>`rhsvars' {
        di in red "The number of variables requested in -modl- is greater" /*
        */ " than the number of independent variables in the regression."
        di
        di in yellow "If you are using the -testres- command, you must" /*
        */ " immediately follow the estimation with a -modl- command," /*
        */ " then carry out the tests and issue -testres-."
        exit 198
    }
    else if "`command'"=="xtreg_re" & `numrhs'>`rhsvars'-1 {
        di in red "The number of variables requested in -modl- is greater" /*
        */ " than the number of independent variables in the regression."
        di
        di in yellow "If you are using the -testres- command, you must" /*
        */ " immediately follow the estimation with a -modl- command," /*
        */ " then carry out the tests and issue -testres-."
        exit 198
    }
end
*----------------------------------------------------------------------
* Program to identify user-called variables and get the associated ests.
*----------------------------------------------------------------------
program define USERvars
    version 4.0
    local z=substr("`1'",1,1)
    local coeffs : colnames(B)
    local varnum : word count `coeffs'
    *------------------------------------------------------------------
    * Case where `*'=="" or `*'==_all
    *------------------------------------------------------------------
    if ("`1'"=="" | "`1'"=="_all" | substr("`1'",1,4)=="_all" | /*
    */ substr("`1'",1,1)==",") & index("`2'","=")==0 {
        local i 1
        * Intercept included case
        if "$nocon"=="" {
            while `i' <= `varnum'-1 {
                local var : word `i' of `coeffs'
                GETests `var' `i'
                local i=`i'+1
            }
        }
        * Intercept in model, but not in table case
        if "$nocon"=="nocon" & "$ccol"~="" {
            while `i' <= `varnum'-1 {
                local var : word `i' of `coeffs'
                GETests `var' `i'
                local i=`i'+1
            }
        }
        * Intercept not in model case
        if "$nocon"=="nocon" & "$ccol"=="" {
            while `i' <= `varnum' {
                local var : word `i' of `coeffs'
                GETests `var' `i'
                local i=`i'+1
            }
        }
        if "`1'"=="" {exit}
        if substr("`1'",1,4)=="_all" {
            local spec=substr("`*'",5,.)
            GETspec `spec'
            exit
        }
        else {
            local spec "`*'"
            GETspec `spec'
            exit
        }
    }
    * Case of _all and newvarname=oldvarname
    if "`1'"=="_all" & index("`2'","=")~=0 {
        if "$ccol"=="" {
            scalar num=0
        }
        else if "$ccol"~="" {
            scalar num=1
        }
        macro shift
        local end ""
        while index("`1'","=")~=0 & "`end'"~="yes" {
            local argvar "`1'"
            local z=substr("`argvar'",1,1)
            local comma=index("`argvar'",",")
            if `comma'~=0 {
                local varspec "`argvar'"
                local argvar=substr("`argvar'",1,`comma'-1)
                local z=substr("`argvar'",1,1)
            }
            local usevar=rtrim(substr("`argvar'",1,index("`argvar'","=")-1))
            local thisvar=ltrim(substr("`argvar'",index("`argvar'","=")+1,.))
            local newvars `newvars' `usevar'
            local equals `equals' `argvar'
            if index("`varspec'",",")==0 {
                macro shift
            }
            else if index("`varspec'",",")~=0{
                local spec=substr("`*'",index("`*'",","),.)
                GETspec `spec'
                local end "yes"
            }
        }
        if "`end'"~="yes" {
            local spec "`*'"
            if "`spec'"~="" {
                GETspec `spec'
            }
        }
        local numnew :word count `newvars'
        local i 1
        local vec0 `coeffs'
        while `i'<=`numnew' {
            if `i'==1 {
                local vec`i' `coeffs'
            }
            local lag=`i'-1
            local lagvec `vec`lag''
            local new`i' : word `i' of `newvars'
            local eql`i' :word `i' of `equals'
            local old`i'=substr("`eql`i''",index("`eql`i''","=")+1,.)
            local k 1
            while `k'<=`varnum'-scalar(num) {
                local vecwrd : word `k' of `vec`i''
                if "`old`i''"=="`vecwrd'" {
                    local match=`k'
                    local k=`varnum'+1
                }
                else {
                    local k=`k'+1
                }
            }
            local k=1
            while `k'<=`varnum'-scalar(num) {
                if `k'<`match' {
                    local tempvar : word `k' of `vec`i''
                    local newvec `newvec' `tempvar'
                    local k=`k'+1
                }
                else if `k'==`match' {
                    local newvec `newvec' `new`i''
                    local k=`k'+1
                }
                else if `k' > `match' {
                    local tempvar : word `k' of `vec`i''
                    local newvec `newvec' `tempvar'
                    local k=`k'+1
                }
            }
            local i=`i'+1
            local vec`i' `newvec'
            local newvec ""
        }
        local j 1
        while `j' <= `varnum'-scalar(num) {
            local var : word `j' of `vec`i''
            GETests `var' `j'
            local j=`j'+1
        }
    }
    else {
        local comma=0
        while "`1'"~="" & `comma'==0 {
            local argvar `1'
            local z=substr("`argvar'",1,1)
            *--------------------------------------------------------------
            * Extracting varname if comma is right-abutted or getting
            * "spec" if at end of varlist and then exiting
            *--------------------------------------------------------------
            local comma=index("`argvar'",",")
            if `comma'~=0 & `comma'~=1 & length("`argvar'")>1 {
                if substr("`argvar'",`comma'+1,1)~="" {
                    local spec=substr("`argvar'",`comma'+1,.)
                    GETspec `spec'
                    local argvar=substr("`argvar'",1,`comma'-1)
                    local z=substr("`argvar'",1,1)
                }
                else if substr("`argvar'",`comma'+1,1)=="" {
                    local argvar=substr("`argvar'",1,`comma'-1)
                    local z=substr("`argvar'",1,1)
                    macro shift
                    local spec "`*'"
                    GETspec `spec'
                }
            }
            else if `comma'==1 {
                local spec `*'
                GETspec `spec'
                exit
            }
            *------------------------------------------
            * Stepping through the different cases: 1. number, 2. varname,
            * 3. oldvarname=newvarname
            *------------------------------------------
            local first=substr("`argvar'",1,1)
            capture confirm integer number `first'
            * 1.
            if _rc==0 {
                * Single number case
                if index("`argvar'","-")==0 {
                    local thisvar : word `argvar' of `coeffs'
                    GETests `thisvar' `argvar'
                    macro shift
                }
                * Case of (e.g.) 1-4
                else {
                    local i=substr("`argvar'",1,index("`argvar'","-")-1)
                    local j=substr("`argvar'",index("`argvar'","-")+1,.)
                    local p=`i'
                    while `p'<=`j' {
                        local thisvar :word `p' of `coeffs'
                        GETests `thisvar' `p'
                        local p=`p'+1
                    }
                    macro shift
                }
            }
            else {
                * Single oldvarname case
                if index("`argvar'","=")==0 {
                    local rhsnum=colnumb(B,"`argvar'")
                    if "`rhsnum'"=="."  &  "`z'"~="A" & "`z'"~="B" & /*
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
                        di
                        di in red "The variable " in blue "`argvar' " /*
                        */ in red "was not an " /*
                        */ "independent variable in the last model " /*
                        */ "estimated."
                        di
                        di in yellow "If you want to rename an independent"/*
                        */ " variable that was in the last model,"/*
                        */ _newline "use the" in blue " newname=oldname" /*
                        */ in yellow " option."
                        exit 198
                    }
                    GETests `argvar' `rhsnum'
                    macro shift
                }
                * Case of newvarname=oldvarname
                else {
                    local usevar=substr("`argvar'",1,index("`argvar'","=")-1)
                    local thisvar=substr("`argvar'",index("`argvar'","=")+1,.)
                    local rhsnum=colnumb(B,"`thisvar'")
                    GETests `usevar' `rhsnum'
                    macro shift
                }
            }
        }
    }
end
*--------------------------------------------------------------------------
* Program to capture specification option
*--------------------------------------------------------------------------
program define GETspec
    version 4.0
    scalar start=index("`*'",",")
    global spec$thsmod=ltrim(substr("`*'",scalar(start)+1,.))
    if length("${spec$thsmod}")==80 {
        di in yellow "The text in your model specification must be 80" /*
        */ " characters or less."
        di
        di in yellow "You may have acceeded that length and lost some of" /*
        */ " your text."
    }
end
*--------------------------------------------------------------------------
* Program to capture coeff. ests, t-stats, and standard errors.
*--------------------------------------------------------------------------
program define GETests
    version 4.0
    local var `1'
    if length("`var'")>6 {
        di in red "Variable names in the" in yellow " modl" /*
        */ in red " statement must be no longer than 6 characters."
        di in yellow "Choose a shorter name for" in blue /*
        */ " `var'" in yellow " using a " _quote "newname=oldname" _quote /*
        */ " expression."
        exit 198
    }
    global uservars $uservars `var'
    macro shift
    local numrhs `1'
    local z=substr("`var'",1,1)
    if "`var'"~="." &  "`z'"~="A" & "`z'"~="B" & /*
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
        global e`var'$thsmod=B[1,`numrhs']
        global t`var'$thsmod=(B[1,`numrhs'])/((V[`numrhs',`numrhs'])^0.5)
        global s`var'$thsmod=(V[`numrhs',`numrhs'])^0.5
        if abs(${t`var'$thsmod})>=1.96 & abs(${t`var'$thsmod})<2.58 {
            global a`var'$thsmod "~"
        }
        else if abs(${t`var'$thsmod})>=2.58 {
            global a`var'$thsmod "*"
        }
    }
    *---Dealing with var if it is a CAPITAL control var----------------
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
        global e`var'$thsmod="Yes  "
        global t`var'$thsmod="---  "
        global s`var'$thsmod="---  "
    }
end
exit
