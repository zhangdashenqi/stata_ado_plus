capture program drop viblmgraph
program define viblmgraph

  version 8.2

  syntax , [b0(real 0) b1(real 0) ///
           xmin(real 0) xmax(real 1) ///
           xata(real -999) xatb(real -999) ///
           ccat(numlist) ccmin(real -4) ccmax(real 4) ///
           type(integer 1) logit ab v7 nodraw notable xcont xname(string) nopreserve *]

  if ("`preserve'" == "") preserve

  drop _all

  if ("`ccat'" == "") local ccat 0
  if (`xata' == -999) local xata = `xmin'
  if (`xatb' == -999) local xatb = `xmax'
  if ("`xname'" == "") local xname "x"

  if `type'==1 {

    if (`xmin' == 0 & `xmax' == 1) & ("`xcont'" == "") {
      * treat x as dummy
      local xlab xlabel(0 1)
      quietly range x `xmin' `xmax' 2
    } 
    else {
      * treat x as continuous
      quietly range x `xmin' `xmax' 50
      quietly set obs 52
      quietly replace x = `xata' in 51
      quietly replace x = `xatb' in 52
      sort x
    }
    label var x "`xname'"


    * make observations
    local yhatlist 
    local yhatcount 0
    foreach mycc of local ccat {
      * generate yhats
      local ++yhatcount
      quietly generate yhat`yhatcount' = `b0' + x*`b1' + `mycc' 
      if ("`logit'" == "") quietly replace yhat`yhatcount' =  1 - 1/(1 + exp(yhat`yhatcount')) // probability scale
      label variable yhat`yhatcount' "CC=`mycc'"
      local yhatlist `yhatlist' yhat`yhatcount'
    }

    * convert to probability scale, specify ylabels
    if "`logit'" == "" {
      local ylab8 ylabel(0(.1)1, angle(0) glpattern(shortdash) glwidth(thin)) 
      local ylab7 ylabel(0(.1)1) 
      local ytitle Pr(y)
    }
    else {
      local ylab7 ylabel(-10 -5 to 10) 
      local ylab8 ylabel(-10 -5 to 10) 
      local ytitle Logit(y)
    }

    * create labels for groups
    quietly gen str2 lab1 = "A"  if x == `xata'
    quietly replace  lab1 = "B"  if x == `xatb'

    if ("`ab'" == "")  {
       quietly replace lab1 = " "
    }

    if "`v7'" == "" {
      quietly twoway connected `yhatlist' x ,  ///
       msymbol(i i i i i i ) mlabel(lab1 lab1 lab1 lab1 lab1 lab1) mlabpos(12 12 12 12 12) ///
       `xlab' ytitle(`ytitle') `ylab8' `draw' `options'
    }
    else {        
      set graphics on
      if "`draw'" != "" {
        set graphics off
      }
      version 7: quietly graph `yhatlist' x, c(lllllllllll) symbol([lab1].......) psize(300) l1title(`ytitle') `ylab7' `options'
      if "`draw'" != "" {
        set graphics on
      }
    }
    if ("`table'" == "") {
      foreach mycc of local ccat {
        * make macros for table
        local a = `b0' + `xata'*`b1' + `mycc'
        local b = `b0' + `xatb'*`b1' + `mycc'
        * convert macros to probabilities for table
        if "`logit'" == "" {
          local a = 1 - 1/(1 + exp(`a'))
          local b = 1 - 1/(1 + exp(`b')) 
        }

        * show table after graph
        local a = round(`a',0.01)
        local b = round(`b',0.01)
        local bmina = round(`b' - `a',0.01)
        display in yellow "**For CC=`mycc'**"
        display in green "   " %~8s "`xname'"
        display in green "  `xata'         `xatb'"
        display in green "--------------------"
        display in yellow %5.2f `a'  in green " (A)  " in yellow %5.2f `b' in green " (B)" in green "   (B-A) = " %5.2f `bmina'
        display
      }    
    }
  }

  if `type'==2 | `type' == 3 {

    * make observations
    quietly range cc `ccmin' `ccmax' 50

    * for graph 2
    * generate yhats
    quietly gen yhat0 = `b0' + `xata'*`b1' + cc  // x1=0 & x2=0
    quietly gen yhat1 = `b0' + `xatb'*`b1' + cc  // x1=1 & x2=0

    if "`logit'" == "" {
      * probability scale
      quietly replace yhat0 = 1/(1 + exp(-yhat0))  // x1=0 
      quietly replace yhat1 = 1/(1 + exp(-yhat1))  // x1=1 
      local ylab8 ylabel(0(.1)1, angle(0) glpattern(shortdash) glwidth(thin)) 
      local ylab7 ylabel(0(.1)1) 
    }
    else {
      local ylab7 ylabel(-10 -5 to 10) 
      local ylab8 ylabel(-10 -5 to 10) 
    }

    * label variables
    label var yhat0 "`xname'=`xata'"
    label var yhat1 "`xname'=`xatb'"

    if "`ccat'" != "" {
      local xline xline(`ccat')
    }

    * for graph 3
    gen d = yhat1 - yhat0
    label variable d "(B - A)"

  }

  if `type' == 2 {

    if "`v7'" == "" {
      quietly twoway connected yhat0 yhat1 cc, ///
                     msymbol(i oh) clpattern(dash l) clcolor(blue red) ///
                     mcolor(blue red)  ///
                     `xline' legend(order(1 2) rows(1)) `ylab8' `draw' `options'
    }
    else {
      set graphics on
      if "`draw'" != "" {
        set graphics off
      }
      version 7: quietly graph yhat0 yhat1 cc, pen(35) symbol(.O) ///
                 c(ll) `xline' `ylab7' `options'
      if "`draw'" != "" {
        set graphics on
      }
    }
  }

  if `type' == 3 {
    if "`logit'" == "" {
      * probability scale
      local ylab7 ylabel(-.6 -.4 to .6)
      local ylab8 ylabel(-.6 -.4 to .6, angle(0) glpattern(shortdash) glwidth(thin))
    }
    else {
      local ylab7 ylabel(-10 -5 to 10)
      local ylab8 ylabel(-10 -5 to 10)
    }
    if "`v7'" == "" {
      twoway line d cc, `xline' legend(rows(1)) `ylab8' `draw' `options'
    }
    else {
      set graphics on
      if "`draw'" != "" {
        set graphics off
      }
      version 7: quietly graph d cc, symbol(.) c(l) `xline' yline(0) `ylab7' `options'
      if "`draw'" != "" {
        set graphics on
      }
    }
  }
end


/*

vmlmgraph , b0(-1) b1(.3) 
vmlmgraph , b0(-1) b1(.3) xmin(-1) xmax(1) 
vmlmgraph , b0(-1) b1(.3) xmin(-1) xmax(1)  type(2)
vmlmgraph , b0(-1) b1(.3) xmin(-1) xmax(1)  ccmin(-2) ccmax(2) type(2)
vmlmgraph , b0(-1) b1(.3) xmin(-1) xmax(1)  ccmin(-2) ccmax(2) type(3)

vmlmgraph , b0(-1) b1(.3) xmin(-1) xmax(1)  ccmin(-2) ccmax(2) type(2) ccat(1)


*/
