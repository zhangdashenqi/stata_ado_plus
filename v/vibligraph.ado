*! Updated Dec 9th, changed marker symbols for version 8 graphs
*! Updated Oct 25, 2004 - Modified xat & xinc, added xcont, added table when continuous
*! Updated Oct 25, 2004 - Added *For CC=__**
*! ** Changes sep 20, 2004
*! swap b1 and b2 axes
*! change noabcd to abcd
*! change v8 to v7
*! change x2at to xat, x2inc to xinc, x2min to xmin, x2max to xmax
*! added "notable" to supress table
*! added "nopreserve" to supress preserve
*! Fixed "omitint()" option
capture program drop vibligraph
program define vibligraph

  version 8.2

  syntax , [b0(real 0) b1(real 0) b2(real 0) b12(real 0) ///
           xat(real -999) xinc(real -999) ///
           xmin(real 0) xmax(real 1) ///
           ccat(numlist) ///
           ccmin(real -5) ccmax(real 5) ///
           type(integer 1) xcont logit omitint(integer 0) abcd v7 nodraw notable ///
           x1name(string) x2name(string) nopreserve *]

  if ("`preserve'" == "") preserve

  if ("`table'"=="notable") {
    local showtable 0
  }
  else {
    local showtable 1
  }

  drop _all

  if ("`ccat'" == "") local ccat 0
  if (`xat' == -999)  local xat = `xmin'
  if (`xinc' == -999) local xinc = `xmax'-`xmin'
  local xata = `xat'
  local xatb = `xat' + `xinc'

  if `type'==1 {
    if (`xmin' == 0 & `xmax' == 1) & ("`xcont'" == "") {
      * treat x as dummy
      local xlab xlabel(0 1)
      quietly range x1 0 1 2
    }
    else {
      quietly range x1 `xmin' `xmax' 50
      quietly set obs 52
      quietly replace x1 = `xat' in 51
      quietly replace x1 = `xat'+`xinc' in 52
      sort x1

      * local showtable 0
    }
    if ("`x1name'" == "") local x1name "x1"
    if ("`x2name'" == "") local x2name "x2"

    * make observations

    label var x1 "`x1name'"


    * make macros for table
    local a = `b0' + `xata'*`b1' + 0*`b2' + `xata'*0*`b12' + `ccat' // x1=0 x2=0
    local b = `b0' + `xatb'*`b1' + 0*`b2' + `xatb'*0*`b12' + `ccat' // x1=1 x2=0
    local c = `b0' + `xata'*`b1' + 1*`b2' + `xata'*1*`b12' + `ccat' // x1=0 x2=1
    local d = `b0' + `xatb'*`b1' + 1*`b2' + `xatb'*1*`b12' + `ccat' // x1=1 x2=1

    * generate yhats
    quietly generate yhat1      = `b0' + x1*`b1' + 0*`b2'  + 0*x1*`b12' + `ccat' // x2 == 0
    quietly generate yhat2      = `b0' + x1*`b1' + 1*`b2'  + 1*x1*`b12' + `ccat' // x2 == 1
    quietly generate yhat2noint = `b0' + x1*`b1' + 1*`b2'  + 0*`b12'    + `ccat' // x2 == 1 but interaction 0

    * label variables
    if "`abcd'" == "" {
      label var yhat1 "`x2name'=0"
      label var yhat2 "`x2name'=1"
    }
    else {
      label var yhat1 "`x2name'=0 A & B"
      label var yhat2 "`x2name'=1 C & D"
    }
    label var yhat2noint "x2=1 C & D Int. Omitted"

    if `omitint'==0 {
      local yhat2noint 
      local pen1 63
    }
    else {         
      local yhat2noint yhat2noint
      local pen1 633
    }

    * convert to probability scale, specify ylabels
    if "`logit'" == "" {
      * probability scale
      quietly replace yhat1 =  1 - 1/(1 + exp(yhat1))
      quietly replace yhat2 =  1 - 1/(1 + exp(yhat2))
      quietly replace yhat2noint =  1 - 1/(1 + exp(yhat2noint))
      local ylab8 ylabel(0(.1)1, angle(0) glpattern(shortdash) glwidth(thin)) 
      local ylab7 ylabel(0(.1)1) 

      * convert macros to probabilities for table
      local a = 1 - 1/(1 + exp(`a'))
      local b = 1 - 1/(1 + exp(`b'))
      local c = 1 - 1/(1 + exp(`c'))
      local d = 1 - 1/(1 + exp(`d'))

    }
    else {
      local ylab7 ylabel(-10 -5 to 10)
      local ylab8 ylabel(-10 -5 to 10)
    }

    * create labels for groups
    quietly gen str2 lab1 = "A" if x1 == `xat'
    quietly gen str2 lab2 = "C" if x1 == `xat'
    quietly replace  lab1 = "B"  if x1 == `xat'+`xinc'
    quietly replace  lab2 = "D"  if x1 == `xat'+`xinc'

    if "`abcd'" == "" {
       quietly replace lab1 = " "
       quietly replace lab2 = " "
    }

    if "`v7'" == "" {
      quietly twoway connected yhat1 yhat2 `yhat2noint' x1 , ///
         clpattern(dash l l) clcolor(blue red red) mcolor(blue red red) mlabcolor(blue red red) ///
         msymbol(i i x) mlabel(lab1 lab2 lab2) mlabpos(12 12 12) mlabgap(*.1) mlabsize(*1.2) ///
         legend(rows(1)) `xlab' `ylab8' `draw' `options'
    }
    else {        
      set graphics on
      if "`draw'" != "" {
        set graphics off
      }
      version 7: quietly graph yhat1 yhat2 `yhat2noint' x1, symbol([lab1] [lab2] x) ///
                 psize(300) pen(`pen1') c(lll) `ylab7' `options'
      if "`draw'" != "" {
        set graphics on
      }
    }
    if (`showtable' == 1) {
      * show table after graph
      display in yellow "**For CC=`ccat'**"
      local a = round(`a',0.01)
      local b = round(`b',0.01)
      local c = round(`c',0.01)
      local d = round(`d',0.01)
      local bmina = round(`b' - `a',0.01)
      local dminc = round(`d' - `c',0.01)
      local diffdiff = round((`d' - `c') - (`b' - `a'),0.01)
      display 
      display in green   _col(10)     "|   " %~8s "`x1name'"     
      display in green %8s "`x2name'" " |  `xata'         `xatb'"
      display in green "---------+--------------------"
      display in green   _col(6) "  0 | " in yellow %5.2f `a'  in green " (A)  " in yellow %5.2f `b' in green " (B)" in green "   (B-A) = " %5.2f `bmina'
      display in green   _col(6) "  1 | " in yellow %5.2f `c'  in green " (C)  " in yellow %5.2f `d' in green " (D)" in green "   (D-C) = " %5.2f `dminc' 
      display in green   _col(6) "                 (D-C) minus (B-A) = " %5.2f `diffdiff'


      * display in green "  1 | " in yellow %5.2f `c'  in green " (C)  " in yellow %5.2f `d' in green " (D)" in green "   (D-C) = " %5.2f `dminc' in green "           (D-C) minus (B-A) = " %5.2f `diffdiff'
    }

  }


  if `type'==2 | `type'==3 | `type'== 4 {

    * make observations
    quietly range cc `ccmin' `ccmax' 50

    * for graph 2
    * generate yhats
    quietly gen yhat00      = `b0' + (`xat')       *`b1' + 0*`b2' + 0*0*`b12'              + cc  // x1=0 & x2=0
    quietly gen yhat01      = `b0' + (`xat')       *`b1' + 1*`b2' + 1*0*`b12'              + cc  // x1=0 & x2=1
    quietly gen yhat10      = `b0' + (`xat'+`xinc')*`b1' + 0*`b2' + 0*(`xat')*`b12'        + cc  // x1=1 & x2=0
    quietly gen yhat11      = `b0' + (`xat'+`xinc')*`b1' + 1*`b2' + 1*(`xat'+`xinc')*`b12' + cc  // x1=1 & x2=1
    quietly gen yhat11noint = `b0' + (`xat'+`xinc')*`b1' + 1*`b2' + 1*(`xat'+`xinc')*0     + cc  // x1=1 & x2=1

    if "`logit'" == "" {
      * probability scale
      quietly replace yhat00 = 1/(1 + exp(-yhat00))  // x1=0 & x2=0
      quietly replace yhat01 = 1/(1 + exp(-yhat01))  // x1=0 & x2=1
      quietly replace yhat10 = 1/(1 + exp(-yhat10))  // x1=1 & x2=0
      quietly replace yhat11 = 1/(1 + exp(-yhat11))  // x1=1 & x2=1
      quietly replace yhat11noint = 1/(1 + exp(-yhat11noint))  // x1=1 & x2=1
      local ylab8 ylabel(0(.1)1, angle(0) glpattern(shortdash) glwidth(thin)) 
      local ylab7 ylabel(0(.1)1) 
    }
    else {
      local ylab7 ylabel(-10 -5 to 10)
      local ylab8 ylabel(-10 -5 to 10)
    }
    * label variables
    label var yhat00 "A"
    label var yhat10 "B"
    label var yhat01 "C"

    * for graph 3
    gen d1 = yhat10 - yhat00
    gen d2 = yhat11 - yhat01
    gen d2noint = yhat11noint - yhat01
    label variable d1 "(B - A)"
    label variable d2 "(D - C)"
    label variable d2noint "(D - C) Int. Omitted"

    * for graph 4
    gen dd = d2 - d1
    gen ddnoint = d2noint - d1
    label variable dd "(D - C) - (B - A)"
    label variable ddnoint "(D - C) - (B - A) Int. Omitted"

    if `omitint'==0 {
      label var yhat11 "D"
      local yhat11noint 
      local d2noint 
      local ddnoint 
      local pen2 6633
      local pen3 63
      local pen4 4
    }
    else {         
      label var yhat11 "D o=with int, x=noint"
      local yhat11noint yhat11noint
      local d2noint d2noint
      local ddnoint ddnoint
      local pen2 66333
      local pen3 633
      local pen4 48
    }


  }

  if `type' == 2 {
    if "`logit'" == "" {
      * probability scale
      local ylab8 ylabel(0(.1)1, angle(0) glpattern(shortdash) glwidth(thin)) 
      local ylab7 ylabel(0(.1)1) 
    }
    else {
      local ylab7 ylabel(-10 -5 to 10)
      local ylab8 ylabel(-10 -5 to 10)
    }

    if "`v7'" == "" {
      quietly twoway connected yhat00 yhat10 yhat01 yhat11 `yhat11noint' cc, ///
                     msymbol(i i i i x) clpattern(dash dash l l) clcolor(blue blue red red red) ///
                     mcolor(blue blue red red red)  clwidth(thin thick thin thick) ///
                     xline(`ccat') legend(order(1 2 3 4) rows(1)) `ylab8' `draw' `options'
    }
    else {
      set graphics on
      if "`draw'" != "" {
        set graphics off
      }
      version 7: quietly graph yhat00 yhat10 yhat01 yhat11 `yhat11noint' cc, pen(`pen2') symbol(.O.Ox) ///
                 c(lllll) xline(`ccat') `ylab7' `options'
      if "`draw'" != "" {
        set graphics on
      }
    }
  }

  if `type' == 3 {
    if "`logit'" == "" {
      * probability scale
      local ylab8 ylabel(-.6 -.4 to .6, angle(0) glpattern(shortdash) glwidth(thin))
      local ylab7 ylabel(-.6 -.4 to .6)
    }
    else {
      local ylab8 ylabel(-10 -5 to 10)
      local ylab7 ylabel(-10 -5 to 10)
    }
    if "`v7'" == "" {
      twoway connected d1 d2 `d2noint' cc, ///
         msymbol(i i X) clpattern(dash l l) clcolor(blue red red) ///
         mcolor(blue red red) xline(`ccat') legend(rows(1)) `ylab8' `draw' `options'
    }
    else {
      set graphics on
      if "`draw'" != "" {
        set graphics off
      }
      version 7: quietly graph d1 d2 `d2noint' cc, pen(`pen3') symbol(..x) c(lll) xline(`ccat') yline(0) `ylab7' `options'
      if "`draw'" != "" {
        set graphics on
      }
    }
  }

  if `type' == 4 {
    if "`logit'" == "" {
      * probability scale
      local ylab8 ylabel(-.4 -.2 to .4, angle(0) glpattern(shortdash) glwidth(thin))
      local ylab7 ylabel(-.4 -.2 to .4)
    }
    else {
      local ylab8 ylabel(-10 -5 to 10)
      local ylab7 ylabel(-10 -5 to 10)
    }
    if "`v7'" == "" {
      twoway connected dd `ddnoint' cc, ///
         msymbol(i X) clpattern(l l) clcolor(green orange) ///
         mcolor(green orange) xline(`ccat') legend(rows(1)) `ylab8' `draw' `options'
    }
    else {
      set graphics on
      if "`draw'" != "" {
        set graphics off
      }
      version 7: quietly graph dd `ddnoint' cc , c(ll) symbol(.x) pen(`pen4') xline(`ccat') yline(0) `ylab7' `options'
      if "`draw'" != "" {
        set graphics on
      }
    }
  }

end

