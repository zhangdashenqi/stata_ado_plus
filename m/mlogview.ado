*! version 2.5.0 2009-10-28 jsl
*  - stata 11 update for returns from -mlogit-

window control clear

capture program drop mlogview
capture program drop _mlgetv
capture program drop _mlinit
capture program drop _mlplot
capture program drop _mlnxt7
capture program drop _mlprnt
capture program drop _mlhlp

program define mlogview
    if "`e(cmd)'"!="mlogit" {
        di in r "mlogview must be run after mlogit"
        exit
    }
    version 6.0

*=> Initialize
    global mlopts "`*'"
    _mlinit
    global ml_lbl ""

*=> List variables to plot
    local r1 = 2
    local c1 = 5
    local d1 = 12
    * c's are columns for radio buttons
    local c2 = `c1' + 55
    local c3 = `c2' + 20
    local c4 = `c3' + 28
    local c5 = `c4' + 24
* 18Nov2005 - add button for range
    local c6 = `c5' + 36

*    global ml_wi "Select Variables      Select Amount of Change"
*    window control static   ml_wi        `c1'  `r1'  146   9
    global ml_wi "Select Variables"
    window control static   ml_wi        `c1'  `r1'  146   9
    global ml_wi2 "Select Amount of Change"
    local c12 = `c1' + 56
    window control static   ml_wi2        `c12'  `r1'  146   9
    local r1 = `r1' + `d1' - 1

* var#1
    local n1 = 1
    window control scombo   ml_rhsnm     `c1'  `r1'  50  50  ml_v`n1'
    window control radbegin "+1"         `c2'  `r1'  20   9  ml_v`n1'r
    window control radio    "+SD"        `c3'  `r1'  24   9  ml_v`n1'r
    window control radio    "0/1"        `c4'  `r1'  24   9  ml_v`n1'r
* 18Nov2005 - add Range option
*    window control radend   "Don't Plot" `c5'  `r1'  40   9  ml_v`n1'r

window control radio    "Range"      `c5'  `r1'  32   9  ml_v`n1'r
window control radend   "Don't Plot" `c6'  `r1'  40   9  ml_v`n1'r
    local r1 = `r1' + `d1'
* var#2
    local n1 = 2
    window control scombo   ml_rhsnm     `c1'  `r1'  50  50  ml_v`n1'
    window control radbegin "+1"         `c2'  `r1'  20   9  ml_v`n1'r
    window control radio    "+SD"        `c3'  `r1'  24   9  ml_v`n1'r
    window control radio    "0/1"        `c4'  `r1'  24   9  ml_v`n1'r
* 18Nov2005
*    window control radend   "Don't Plot" `c5'  `r1'  40   9  ml_v`n1'r
window control radio    "Range"      `c5'  `r1'  32   9  ml_v`n1'r
window control radend   "Don't Plot" `c6'  `r1'  40   9  ml_v`n1'r
    local r1 = `r1' + `d1'
* var#3
    local n1 = 3
    window control scombo   ml_rhsnm     `c1'  `r1'  50  50  ml_v`n1'
    window control radbegin "+1"         `c2'  `r1'  20   9  ml_v`n1'r
    window control radio    "+SD"        `c3'  `r1'  24   9  ml_v`n1'r
    window control radio    "0/1"        `c4'  `r1'  24   9  ml_v`n1'r
* 18Nov2005
*    window control radend   "Don't Plot" `c5'  `r1'  40   9  ml_v`n1'r
window control radio    "Range"      `c5'  `r1'  32   9  ml_v`n1'r
window control radend   "Don't Plot" `c6'  `r1'  40   9  ml_v`n1'r
    local r1 = `r1' + `d1'
* var#4
    local n1 = 4
    window control scombo   ml_rhsnm     `c1'  `r1'  50  50  ml_v`n1'
    window control radbegin "+1"         `c2'  `r1'  20   9  ml_v`n1'r
    window control radio    "+SD"        `c3'  `r1'  24   9  ml_v`n1'r
    window control radio    "0/1"        `c4'  `r1'  24   9  ml_v`n1'r
* 18Nov2005
*    window control radend   "Don't Plot" `c5'  `r1'  40   9  ml_v`n1'r
window control radio    "Range"      `c5'  `r1'  32   9  ml_v`n1'r
window control radend   "Don't Plot" `c6'  `r1'  40   9  ml_v`n1'r
    local r1 = `r1' + `d1'
* var#5
    local n1 = 5
    window control scombo   ml_rhsnm     `c1'  `r1'  50  50  ml_v`n1'
    window control radbegin "+1"         `c2'  `r1'  20   9  ml_v`n1'r
    window control radio    "+SD"        `c3'  `r1'  24   9  ml_v`n1'r
    window control radio    "0/1"        `c4'  `r1'  24   9  ml_v`n1'r
* 18Nov2005
*    window control radend   "Don't Plot" `c5'  `r1'  40   9  ml_v`n1'r
window control radio    "Range"      `c5'  `r1'  32   9  ml_v`n1'r
window control radend   "Don't Plot" `c6'  `r1'  40   9  ml_v`n1'r
* var#6
    local r1 = `r1' + `d1'
    local n1 = 6
    window control scombo   ml_rhsnm     `c1'  `r1'  50  50  ml_v`n1'
    window control radbegin "+1"         `c2'  `r1'  20   9  ml_v`n1'r
    window control radio    "+SD"        `c3'  `r1'  24   9  ml_v`n1'r
    window control radio    "0/1"        `c4'  `r1'  24   9  ml_v`n1'r
* 18Nov2005
*    window control radend   "Don't Plot" `c5'  `r1'  40   9  ml_v`n1'r
window control radio    "Range"      `c5'  `r1'  32   9  ml_v`n1'r
window control radend   "Don't Plot" `c6'  `r1'  40   9  ml_v`n1'r

*>  18Nov2005 - Add 7th variable
* var#7
    local r1 = `r1' + `d1'
    local n1 = 7
    window control scombo   ml_rhsnm     `c1'  `r1'  50  50  ml_v`n1'
    window control radbegin "+1"         `c2'  `r1'  20   9  ml_v`n1'r
    window control radio    "+SD"        `c3'  `r1'  24   9  ml_v`n1'r
    window control radio    "0/1"        `c4'  `r1'  24   9  ml_v`n1'r
    window control radio    "Range"      `c5'  `r1'  32   9  ml_v`n1'r
    window control radend   "Don't Plot" `c6'  `r1'  40   9  ml_v`n1'r
*<

*=> Define buttons that execute the plot program
    local r1 = `r1' + `d1'
/* 18Nov2005 - change size
    window control button "DC Plot"         2 `r1' 40 13 ml_dc
    global ml_dc   "_mlplot 1"
    window control button "OR Plot"        46 `r1' 40 13 ml_or
    global ml_or   "_mlplot 2"
    window control button "OR+DC Plot"     90 `r1' 40 13 ml_od
    global ml_od "_mlplot 3"
    window control button "Next 6"   134 `r1' 40 13 ml_nxt7
    global ml_nxt7 "_mlnxt7"
*/
    local w = 52
    local w1 = `w' + 4
    local w2 = `w' + `w' + 4
    local w3 = `w' + `w' + `w' + 4

    window control button "DC Plot"         2 `r1' `w' 13 ml_dc
    global ml_dc   "_mlplot 1"
    window control button "OR Plot"        `w1' `r1' `w' 13 ml_or
    global ml_or   "_mlplot 2"
    window control button "OR+DC Plot"     `w2' `r1' `w' 13 ml_od
    global ml_od "_mlplot 3"
    window control button "Next 7"         `w3' `r1' `w' 13 ml_nxt7
    global ml_nxt7 "_mlnxt7"


*=> Add a note to graph
    local r1 = `r1' + `d1' + 7
    local r2 = `r1'
    global ml_wlbl "Note"
    window control static ml_wlbl  5 `r1' 18   9
    window control edit           25 `r2' 148  8 ml_lbl

*=> Plot options
    local r1 = `r1' + `d1' + 3
    global ml_opt "Plot Options"
    * window control static ml_opt 2  `r1'  173  40 blackframe
    * version 1.6.5
    * window control static ml_opt 2  `r1'  173 50 blackframe

* 17Nov2005
window control static ml_opt 2  `r1'  210 60 blackframe

    local r1 = `r1' - 3
    window control static ml_opt 5  `r1'  40   8
    local r1 = `r1' + `d1' - 3
    local r2 = `r1'
    * tics
    global ml_wtic "Number of tics"
    window control static ml_wtic   5 `r1' 47  8
    window control edit            50 `r2' 25  8 ml_tic
    * range of plot
    global ml_wmin "Plot from"
    window control static ml_wmin    90  `r1'  28   8
    window control edit              120 `r1'  17   8  ml_xmin
    global ml_wmax "to"
    window control static ml_wmax    140  `r1' 6   8
    window control edit              149  `r1' 17   8  ml_xmax
    * connect if p>
    local r1 = `r1' + `d1'
    local r2 = `r1'
    global ml_wpgt "Connect if p>="
    window control static ml_wpgt   5 `r1' 42  8
    window control edit            50 `r2' 25  8 ml_pval
    * set base category
    global ml_wb "Base category"
    window control static ml_wb    90 `r1' 45  8
    window control edit           137 `r2' 28  8 ml_bcat
    * pack odds and use variable labels
    local r1 = `r1' + `d1' - 2
    window control check "Pack odds ratio plot"  5  `r1'   80 10 ml_pack
    window control check "Use variable labels"   90  `r1'  75 10 ml_vlbl
    * pack odds and use variable labels
    local r1 = `r1' + `d1' - 2
    window control check "Use category values for plot symbols"  5  `r1' 180 10 ml_valu

* 17Nov2005 - add underline option for OR+DC plots
    local r1 = `r1' + `d1' - 2
    window control check "Underline indicates negative change"  5  `r1' 180 10 ml_under

*=> Buttons for odds and ends
    local r1 = `r1' + 15
* 18Nov2005 - drop help button - no longer works
* window control button "Help"      46 `r1' 40 13 ml_help
* global ml_help "_mlhlp"
* 18Nov2005
*    window control button "Exit"      2  `r1' 40 13 ml_ex
*    window control button "Print"     90 `r1' 83 13 ml_print

    local w = 103
    local wx = `w' + 5
    window control button "Exit"      2  `r1' `w' 13 ml_ex
    global ml_ex "exit 3000"
    window control button "Print"     `wx' `r1' `w' 13 ml_print
    global ml_print "_mlprnt"

*   window dialog "Multinomial Logit Plots" 10 10 180 192
*   window dialog "Multinomial Logit Plots" 230 80 180 192
* version 1.6.5
  *window dialog "Multinomial Logit Plots" 230 80 180 202
* 17Nov2005
*window dialog "Multinomial Logit Plots" 10 10 320 302
*                                             x   y
*window dialog "Multinomial Logit Plots" 10 10 220 302

window dialog "Multinomial Logit Plots" 10 10 220 225

end

program define _mlplot
    if "`1'" ~= "" {
        global ml_ordc = `1'
    }

*=> construct list of vars from the scombo boxes 1 through 6
*=> construct list of vars from the scombo boxes 1 through 7
* 18Nov2005
    local i = 1
    local varlst ""
    local stdlst ""
    while `i' < 8 {
*    while `i' < 7 {
        * type of plot: unstd, std, or 0 to 1
        local tmp "ml_v`i'r"
        * name of variable
        local tmpnm "ml_v`i'"
        if $`tmp'==1 {
            local varlst "`varlst' $`tmpnm'"
            local stdlst "`stdlst'u"
        }
        if $`tmp'==2 {
            local varlst "`varlst' $`tmpnm'"
            local stdlst "`stdlst's"
        }
        if $`tmp'==3 {
            local varlst "`varlst' $`tmpnm'"
            local stdlst "`stdlst'0"
        }
* 18Nov2005
        if $`tmp'==4 {
            local varlst "`varlst' $`tmpnm'"
            local stdlst "`stdlst'r"
        }
* 18Nov2005
* if type is not 1, 2, 3, or 4 it is not plotted
        * if type is not 1, 2, or 3, it is not plotted
        local i = `i' + 1
    }

*=> build options to pass to mlogplot
    local opts "std(`stdlst')"
    if "$ml_bcat"~="" {
        local opts "`opts' b($ml_bcat)"
    }
    local opts "`opts' p($ml_pval)"
    if "$ml_xmin"~="min" {
        local opts "`opts' min($ml_xmin)"
    }
    if "$ml_xmax"~="max" {
        local opts "`opts' max($ml_xmax)"
    }
    if "$ml_lbl" ~= "" {
        local opts "`opts' note($ml_lbl)"
    }
    if $ml_ordc>=2 {
        local opts "`opts' or"
    }
    if $ml_ordc~=2 {
        local opts "`opts' dc"
    }
    if $ml_pack==1 {
        local opts "`opts' packed"
    }
    if $ml_vlbl==1 {
        local opts "`opts' labels"
    }
    * 1.6.5
    if $ml_valu==1 {
        local opts "`opts' values"
    }
* 18Nov2005
    if $ml_under==1 {
        local opts "`opts' sign"
    }

    local opts "`opts' ntics($ml_tic)"
    local opts "`opts' $mlopts"
    di in white ". mlogplot `varlst', `opts'"
    mlogplot `varlst',`opts'
*    if $PE_mlerr==1 {
*        exit 3000
*    }
end

program define _mlinit

*=> set radio buttons
    local i = 1
    while `i' < 6 {
        global ml_v`i'r = 1
        local i = `i' + 1
    }

*=> defaults for check box
    global ml_rng = 1       /* use observed range */
    global ml_ordc = 1      /* DC plot */
    global ml_pack = 0      /* don't pack plot */
    global ml_vlbl = 0      /* don't plot value labels */
* 17Nov2005
global ml_under = 0      /* underline negative changes */

    * 1.6.5
    global ml_valu = 0      /* don't plot value labels */
    global ml_pval = .1     /* connect if p> */
    global ml_tic = 9
    global ml_lbl ""
    global ml_xmin "min"    /* plot from min to max */
    global ml_xmax "max"

 *=> get b from logit
    /* 2009-10-28
    version 5.0
    mat ml_b = get(_b)
    version 6.0
    */
    tempname v
    _get_mlogit_bv ml_b `v'
    global ml_nvars = colsof(ml_b) - 1

*=> get names of variables
    global ml_rhsnm : colnames(ml_b)
    global ml_nvar : word count $ml_rhsnm
    global ml_nvar = $ml_nvar - 1
    global ml_lastv = 1
    global ml_lastv = 0
    _mlgetv
end

* get the names of variables to fill in the scombo boxes
program define _mlgetv
    * get number of last variable in box; 0 if none plotted before.
    * if this is called from Next 6, this will not be 0.
    local k = $ml_lastv
    local i = 1
* 18Nov2005
    * loop through up to 6 new variables
*    while `i' < 7 {
* loop through up to 7 new variables
while `i' < 8 {
        local k = `k' + 1
        * if exceed max number of vars, do fill remaining scombo boxes
        if `k' > $ml_nvar {
            * do not plot
*18Nov2005
*            global ml_v`i'r = 4
global ml_v`i'r = 5
            * no name
            global ml_v`i' ""
        }
        * else, get next in list of variables
        else {
            global ml_v`i' : word `k' of $ml_rhsnm
            local tmp "ml_v`i'"
            _pedum $`tmp'
            global ml_v`i'r = 1
            if r(dummy) == 1 { global ml_v`i'r = 3 }
        }
        local i = `i' + 1
    }
    * ok that this can be larger than n vars in model
* 18Nov2005
    *global ml_lastv = $ml_lastv + 6
    global ml_lastv = $ml_lastv + 7
end

program define _mlnxt7
    * if last var from _mlgetv > n vars in model, reset
    if $ml_lastv > $ml_nvar {
        global ml_lastv = 0
    }
    _mlgetv
    _mlplot
end

program define _mlprnt
    gphprint,nologo
end
exit

* version 1.6.3 11Mar2001
* version 1.6.4 19Nov2003 - for stata 8, change where box opens
* version 1.6.5 30Mar2005 plot values not labels
* version 1.6.6 13Apr2005 plot values not labels
* version 1.7.0 18Nov2005 add sign and more variables - mlogview
* version 1.7.1 01Apr2006
*   -   fix dialog box

