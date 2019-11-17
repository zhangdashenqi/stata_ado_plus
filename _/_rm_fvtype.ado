*! version 1.0.0 2014-02-14 | long freese | spost13 release

** returns info on how each predictor is used; used by _rm_modelinfo
**
**        _rm_fvtype, rhsnms
**
**    returns are:
**
**        rhs_core            uniq set of variables on rhs
**        rhs_notfv           non fv in core
**        rhs_fv              fv in core
**        rhs_fvbin           i1. type fvs
**        rhs_fvcat           i234.. type fs
**        rhs_fvint           used in # term
**        rhs_fvintself       # with self
**        rhs_fvintselfonly   # with self only (e.g., age#age)
**        rhs_fvintother      # with other vars

capture program drop _rm_fvtype
program define _rm_fvtype, sclass

    version 11.2
    syntax , rhs_beta(string)
    local q ""
    local q "qui"

    tempname betas
    matrix `betas' = e(b)
    local betanms : colnames `betas'
    local rhs_core ""

    * determine core set of predictors
    foreach bnm in `betanms' {
        _ms_parse_parts `bnm'
        local corenm `r(name)'
        if "`corenm'"!="" {
            * local name with name of corenm
            local `corenm' "``corenm'' `corenm'"
            * allows up to four way interaction
            if ("`corenm'"!="") local rhs_core "`rhs_core'`corenm' "
            local corenm `r(name2)'
            if ("`corenm'"!="") local rhs_core "`rhs_core'`corenm' "
            local corenm `r(name3)'
            if ("`corenm'"!="") local rhs_core "`rhs_core'`corenm' "
            local corenm `r(name4)'
            if ("`corenm'"!="") local rhs_core "`rhs_core'`corenm' "
        }
    } // columns of e(b)
    local rhs_core : list uniq rhs_core
    local rhs_core : subinstr local rhs_core "_cons" " ", all // ologit etc

    * check if i.catvar
    foreach nm in `rhs_core' {
        local dupnms : list dups `nm'
        local ndups : list sizeof dupnms
        if (`ndups'>1) local `nm'iscatvar = 1
        else local `nm'iscatvar = 0
    }

    //  loop over core names to determine how used as factor variables

    local rhs_fvbin ""
    local rhs_fvcat ""
    local rhs_notfv "" // no fv stuff, simple variable
    local rhs_fvint ""
    local rhs_fvintself ""
    local rhs_fvintother ""

    foreach corenm of local rhs_core {

    `q' di _new "=========================================================="
    `q' di _new "Testing core variable: `corenm'" _new

        local coresimple = 1

        //  loop over beta's created with factor variables

        foreach betanm of local rhs_beta {

            *di "testing beta: `betanm'" _col(30) "betaword: `betaword'"

            * turn betanm into words
            * # to space
            local betaword : subinstr local betanm "#"  " ", all
            * c. to space
            local betaword : subinstr local betaword "c." " ", all
            * remove #.
            local betaword = regexr("`betaword'","[0-9]+\."," ")
            local betaword = regexr("`betaword'","[0-9]+\."," ")
            local betaword = regexr("`betaword'","[0-9]+\."," ")
            local betaword = regexr("`betaword'","[0-9]+\."," ")
            local betaword = regexr("`betaword'","[0-9]+\."," ")
            local betaword : list retokenize betaword

            local ibetapos : list posof "`corenm'" in betaword

            //  no core in betaword: skip to next betanm

            if `ibetapos'==0 {
`q' di "  corenm (`corenm') is not betanm (`betanm') 1" _new
            }

            //  yes core in beta: decide if 1. 2. #

            else { // corenm is IN betanm
`q' di "  corenm (`corenm') is IN betanm (`betanm') 2" _new

                local iscorei1 = regexm("`betanm'","1.`corenm'")

                //  yes i1. in beta
                if `iscorei1'== 1{
`q' di "     (1.`corenm') is IN betanm (`betanm') 3" _new
                    local coresimple = 0
                    local rhs_fvbin "`rhs_fvbin'`corenm' "
                }

                //  no i1 in beta
                else {
`q' di "     (1.`corenm') not in betanm (`betanm') 4" _new
                }

                local iscorei2 = regexm("`betanm'","[2-9]+\.`corenm'")

                //  yes i2+ in betanm
                if `iscorei2'== 1 {
`q' di "     (2+.`corenm') is IN betanm (`betanm') 5" _new
                    local coresimple = 0
                    local rhs_fvcat "`rhs_fvcat'`corenm' "
                    local rhs_fvbin : list rhs_fvbin - corenm
                }

                //  no i2+ in beta
                else {
`q' di "     (2+.`corenm') not in betanm (`betanm') 6" _new
                }

                local iscorepound = regexm("`betanm'","#")

                //  yes # in beta

                if `iscorepound'== 1 {
`q' di "     (#) is IN betanm (`betanm')" _new
                    local coresimple = 0
                    local rhs_fvint "`rhs_fvint'`corenm' "
                    local beta_core : list betaword - corenm
                    local beta_core : list uniq beta_core
                    local beta_core : list retokenize beta_core

                    //  yes only core in #
                    if "`beta_core'"=="`corenm'" {
`q' di "        - # corenm only `corenm' ( `betanm' ) 7" _new
                        local coresimple = 0
                        local rhs_fvintself "`rhs_fvintself'`corenm' "
                    }

                    //  not only core in beta
                    else {
`q' di "        - #xy -> # core `corenm' plus ( `betanm' ) 8" _new
                        local coresimple = 0
                        local rhs_fvintother "`rhs_fvintother'`corenm' "
                    }

                } // # in beta

                //  no # in beta: next beta

                else {
`q' di "     (#) not in betanm (`betanm') 9" _new
                } // no # in beta

            } // core in betaword

        } // next betanm

        if `coresimple'==1 local rhs_notfv "`rhs_notfv'`corenm' "

    } // next corenm

    local rhs_fvintselfonly : list rhs_fvintself - rhs_fvintother
    local rhs_fv : list rhs_core - rhs_notfv

//  clean up and create returns

    foreach fv in rhs_fvbin rhs_fvcat rhs_notfv rhs_fvint rhs_fvintself ///
        rhs_fvintother rhs_fvintselfonly rhs_notfv {
        local `fv' : list uniq `fv'
        local `fv' : list sort `fv'
        local `fv' : list retokenize `fv'
`q' di "`fv'" _col(25) "``fv''"
    }

`q' di _new "beta_sorted: `rhs_beta'"

    sreturn local rhs_core          "`rhs_core'"
    sreturn local rhs_fv            "`rhs_fv'"
    sreturn local rhs_notfv         "`rhs_notfv'"
    sreturn local rhs_fvbin         "`rhs_fvbin'"
    sreturn local rhs_fvcat         "`rhs_fvcat'"
    sreturn local rhs_fvint         " `rhs_fvint'"
    sreturn local rhs_fvintselfonly "`rhs_fvintselfonly'"
    sreturn local rhs_fvintself     "`rhs_fvintself'"
    sreturn local rhs_fvintother    "`rhs_fvintother'"

end
exit
