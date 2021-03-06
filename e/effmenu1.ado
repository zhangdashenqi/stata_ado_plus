*! Menu for specifying effects
*! Michael Hills 1/5/2002
*! version 3.0.0

program define effmenu1
version 7.0
syntax [varlist] [if] [in] [,CLEAR Display]

if "`clear'" == "clear" {
  macro drop EF*
  macro drop ef*
}

/* sets defaults */

global ef_opt ""

if "" == "$ef_lev" { global ef_lev=$S_level}
if "" == "$ef_bas" { global ef_bas 1}
if "" == "$ef_peru" { global ef_peru 1}
if "" == "$ef_pery" { global ef_pery 1000}
if "" == "$ef_perc" {global ef_perc 100}
if "" == "$ef_ver" { global ef_ver 0}

/* Sets all variables to categorical as default */

tokenize "`varlist'"
while "`1'" != "" {
    char `1'[type] "categorical"
    mac shift 
}

global EF_var "`varlist'"
global EF_typ "binary metric failure count"

cap window control, clear


/* response variable */

global EF_out1 "Select response"
global EF_out2 "variable" 
window control static EF_out1 5 5  70 9
window control static EF_out2 5 12 70 9
window control ssimple EF_var 5 22 50 80 ef_res

/* type of response */

global EF_out3 "Select type of"
global EF_out4 "response" 
window control static EF_out3 65 5  50 9
window control static EF_out4 65 12 50 9
window control ssimple EF_typ 65 22 50 80 ef_typ

/* Follow-up time */

global EF_fup1 "Select follow-up time"
global EF_fup2 "if appropriate" 
window control static EF_fup1 125 5  80 9
window control static EF_fup2 125 12 80 9
window control ssimple EF_var 125 22 50 80 ef_fup

/* matched cc */

global EF_mcc1 "Matched case-control" 
global EF_mcc2 "study?" 
window control static EF_mcc1 195  5 80 9 
window control static EF_mcc2 195 12 20 9 
window control check " " 225 12 10 9 ef_mcc

global EF_mcc3 "Select matched" 
global EF_mcc4 "set variable" 
window control static EF_mcc3 195 30 80 9 
window control static EF_mcc4 195 37 80 9 
window control ssimple EF_var 195 45 50 60 ef_mvar

/* explanatory variable */

global EF_exp1 "Select exposure"
window control static EF_exp1 5 122  80 9
window control ssimple EF_var 5 132 50 80 ef_exp

/* modifying variable */

global EF_mod1 "Select modifier"
window control static EF_mod1  75 122  80 9
window control ssimple EF_var  75 132 50 80 ef_mod

/* categorical variables */

window control check "Is exposure metric?" 145 155 80 10 ef_exm
window control check "Is modifier metric?" 145 175 80 10 ef_mom

/* exit buttons */

global EF_exit "exit 3000" 
global EF_eff "exit 3003"  
window control button "Exit"    200 200 40 10 EF_exit
window control button "Effects" 140 200 40 10 EF_eff

cap window dialog "Variable attributes" . . 270 230

if _rc==3000 {
    exit
}


if $ef_exm==1 {
    char $ef_exp[type] "metric"
}
if $ef_mom==1  {
    if "$ef_mod" == "" {
      di as error "No modifier specified, but metric box checked"
      exit
    }
    else {
      char $ef_mod[type] "metric"
    }
}

/* basic error checking */

global ef_exp = ltrim("$ef_exp")
global ef_mod = ltrim("$ef_mod")
global ef_res = ltrim("$ef_res")

if "$ef_res"=="" {
    di as error "No response variable has been specified"
    exit
}
else {
    cap confirm numeric variable $ef_res
    if _rc==7 {
      di as error "Response variable must be numeric"
      exit
    }
}
if "$ef_typ" == "" {
    di as error "Type of response variable must be selected"
    exit
}
if "$ef_exp"=="" {
    di as error "Explanatory variable must be specified"
    exit
}
else {
    cap confirm numeric variable $ef_exp
    if _rc==7 {
      di as error "Exposure variable must be numeric"
      exit
    }
}
if "$ef_res"=="$ef_exp" {
    di as error "Variable occurs as both response and main explanatory"
    exit
}
if "$ef_res"=="$ef_mod" {
    di as error "Variable occurs as both response and modifier"
    exit
}
if "$ef_mod"=="$ef_exp" {
    di as error "Variable occurs as both main explanatory and modifier"
    exit
}
if "$ef_mod" != "" {
    cap confirm numeric variable $ef_mod
    if _rc==7 {
      di as error "Modifier variable must be numeric"
      exit
    }
}
if "$ef_typ"=="binary" {
    cap assert $ef_res ==0 | $ef_res ==1 | $ef_res==.
    if _rc==9 {
        di in red "Binary response must be coded 0/1"
        exit
    }
}
if "$ef_typ"=="binary" | "$ef_typ"=="metric" {
    cap assert "$ef_fup"==""
    if _rc==9 {
        di in red "Cannot have follow-up time with binary or metric response"
        exit
    }
}
if "$ef_typ"=="failure" {
    cap assert $ef_res ==0 | $ef_res ==1 | $ef_res==.
    if _rc==9 {
        di in red "Failure response must be coded 0/1"
        exit
    }
}
if "$ef_typ"=="failure" | "$ef_typ"=="count"  {
    cap assert "$ef_fup" != ""
    if _rc==9 {
        di in red "Failure and count responses must have follow-up time"
        exit
    }
}
qui inspect $ef_exp
if r(N_unique)>15 & "`$ef_exp[type]'"!="metric" {
    display as error" More than 15 values for exposure ($ef_exp)" 
    display as text "Should it be declared as metric?"
    exit
}
if "$ef_mod" != "" {
    qui inspect $ef_mod
    if r(N_unique)>15 & "`$ef_mod[type]'"!="metric" {
        display as error " More than 15 values for modifier ($ef_mod)"
        di as text "Should it be declared as metric?"
        exit
    }
}

/* effects */

if "$ef_sca" == "" {
    if "$ef_typ" == "metric" {
        global ef_sca 1
    }
    if "$ef_typ" == "binary" {
        global ef_sca 3
    }
    if "$ef_typ" == "failure" | "$ef_typ" == "count" {
        global ef_sca 2
    }
}

global EF_eff1 "Effects on response ($ef_res)"
window control static EF_eff1 10 20 120 10

if $ef_mcc == 1 {
    global EF_eff2 "Measured as odds ratios"
    window control static EF_eff2 10 40 120 10
}
if "$ef_typ"=="metric"{
    window control radbegin "Difference in means"      10 35 100 10 ef_sca
    window control radend    "Ratio of means"          10 55 100 10 ef_sca
}
if "$ef_typ"=="binary" &  $ef_mcc != 1 {
    window control radbegin "Differences in  proportions" 10 35 100 10 ef_sca
    window contro radio "Ratios of proportions"           10 55 100 10 ef_sca
    window control radend "Odds ratios"                   10 75 100 10 ef_sca
    global EF_perc "Per"
    window control static EF_perc 20 45 20 10 
    window control edit          40 45 30 10 ef_perc
}
if "$ef_typ"=="binary" &  $ef_mcc == 1 {
    global ef_sca 4
}
if "$ef_typ"=="failure" | "$ef_typ"=="count" {
    window control radbegin "Rate differences"             10 35 100 10 ef_sca
    window control radend "Rate ratios"                    10 75 100 10 ef_sca
    global EF_pery "Per"
    window control static EF_pery 20 50 20 10 
    window control edit          40 50 30 10 ef_pery
}

/* Control variables */

global EF_con "Select control variables"
window control static EF_con 115  20 80 7
window control msimple EF_var 115  27 80 80 ef_con

/* Modifier variables */

global EF_mod "Declare metric control variables"
window control static EF_mod 210  20 100 7
window control msimple EF_var 210 27 80 80 ef_met

/* baseline */

if "`$ef_exp[type]'" == "categorical" {
    global EF_bas "Baseline"
    window control static EF_bas 80 120 40 7
    window control edit          80 130 15 10 ef_bas
}

/* per unit for metric exposure */

if "`$ef_exp[type]'" == "metric" {
    global EF_peru "Per unit"
    window control static EF_peru 90 120 40 7
    window control edit          90 130 20 10 ef_peru
}

/* showat */

if "`$ef_mod[type]'" == "metric" {
    global EF_sho "Showat"
    window control static EF_sho 90 145 40 7
    window control edit          90 155 60 10 ef_sho 
}

/* displays exposure and modifier type */

if "$ef_exp" != "" {
    if "`$ef_exp[type]'" == "categorical" {
        global EF_exptype "is categorical"
    }
    if "`$ef_exp[type]'" == "metric" {
        global EF_exptype " is metric"
    }
}

if "$ef_mod" != "" {
    if "`$ef_mod[type]'" == "categorical" {
        global EF_modtype "is categorical"
        global ef_sho
    }
    if "`$ef_mod[type]'" == "metric" {
        global EF_modtype "is metric"
    }
}

global EF_type1  "Explanatory ($ef_exp)"
global EF_type2  "Modifier ($ef_mod)"
window control static EF_type1    10 120 70 9
window control static EF_exptype  10 130 70 9
if "$ef_mod" != "" {
    window control static EF_type2    10 145 70 9
    window control static EF_modtype  10 155 70 9
}

global EF_lev "Level of confidence"
window control static EF_lev 130 120 80 10
window control edit  130 130 15 10 ef_lev

/* verbose */

window control check "More detailed output" 10 180 100 10 ef_ver

/* exit buttons */

global EF_ok "exit 3001"
global EF_exit "exit 3000"
window control button "OK"     120 180 40 10 EF_ok
window control button "Exit  " 180 180 40 10 EF_exit

cap window dialog "Choosing how to measure the effects" 10 10 340 210

dis ""

qui inspect $ef_exp
if $ef_bas == 0 | $ef_bas > r(N_unique) {
    di as error "Baseline out of range"
    exit
}
if "$ef_con"!="" {
    tokenize "$ef_con"
    while "`1'" != "" {
        if "`1'" == "$ef_mod" {
            di as error "Cannot include variable as both modifier and control"
            exit
        }
    mac shift
    }
}

if _rc==3000 {
  exit
}

tokenize "$ef_met"
while "`1'" != "" {
    char `1'[type] "metric"
    mac shift 
}


if _rc==3001 {

    if "`display'"=="display" {
        local effmenu2 "effmenu2 `if' `in', res($ef_res) typ($ef_typ) exp($ef_exp)"
        if "$ef_typ"=="metric" {
            if $ef_sca==1 {local effmenu2 "`effmenu2' effects(md)"}
            if $ef_sca==2 {local effmenu2 "`effmenu2' effects(mr)"}
        }
        if "$ef_typ"=="binary" {
            if $ef_sca==1 {local effmenu2 "`effmenu2' effects(pd)"}
            if $ef_sca==2 {local effmenu2 "`effmenu2' effects(pr)"}
            if $ef_sca==3 {local effmenu2 "`effmenu2' effects(or)"}
        }
        if "$ef_typ"=="failure" {
            if $ef_sca==1 {local effmenu2 "`effmenu2' effects(rd)"}
            if $ef_sca==2 {local effmenu2 "`effmenu2' effects(rr)"}
        }
        if "$ef_mod"!="" {local effmenu2 "`effmenu2' mod($ef_mod)"}
        if "$ef_fup"!="" {local effmenu2 "`effmenu2' fup($ef_fup)"}
        if $ef_perc!=100 {local effmenu2 "`effmenu2'  perc($ef_perc)"}
        if $ef_pery!=1000 {local effmenu2 "`effmenu2'  pery($ef_pery)"}
        if $ef_peru!=1 & $ef_exm==1 {local effmenu2 "`effmenu2'  peru($ef_peru)"}
        if $ef_lev!=95 {local effmenu2 "`effmenu2' level($ef_lev)"}
        if $ef_bas!=1&$ef_exm==0 {local effmenu2 "`effmenu2' base($ef_bas)"}
        if $ef_exm==1 {local effmenu2 "`effmenu2' exm"}
        if $ef_mom==1 {local effmenu2 "`effmenu2' mom"}
        if $ef_mcc==1 {local effmenu2 "`effmenu2' mcc mvar($ef_mvar)"}
        if "$ef_sho"!="" {local effmenu2 "`effmenu2' showat($ef_sho)"}
        if "$ef_con"!="" {local effmenu2 "`effmenu2' con($ef_con)"}
        if "$ef_met"!="" {local effmenu2 "`effmenu2' met($ef_met)"}
	if $ef_ver==1 {local effmenu2 "`effmenu2' ver"}
        di
        di as res "`effmenu2'"
        di
    }
    effects1 `if' `in' , level($ef_lev)
}
end

