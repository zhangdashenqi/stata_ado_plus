*! v1.1, updated 3/30/01, mnm
*! 1.1 removes intro screen, and takes r and n as parms

program define regpt
  version 6.0
  syntax [, r(real .3) n(integer 30) ]

  * check that r and n have OK values
  if (`r' < -1) | (`r' > 1) {
    display "correlation must be between -1 and 1"
    exit
  }
  if (`n' <= 1) {
    display "N must be greater than 1"
    exit
  }

  * make data based on r and r
  qui rp_mkdat `r' `n'

  * set x and y to 0, title of plot
  global DB_x 0
  global DB_y 0
  global DB_plot OLS Scatterplot with Regression Line

  * plot the data
  qui rp_plot $DB_x $DB_y

  * show window so you can move the point
  capture rp_win
end

* make data given corr and n
program define rp_mkdat
  version 6.0
  args corr n

  clear
  qui set obs `n'

  generate ty = invnorm(uniform())
  egen y = std(ty)

  generate z = invnorm(uniform())
  generate tx = sqrt(1 - (`corr')^2)*z + `corr'*y
  egen x = std(tx)

  qui regress y x in 2/l
  global orig_b0 = _b[_cons]
  global orig_b1 = _b[x]

  predict origyhat
  replace origyhat = . in 1

  keep x y origyhat
  label var x ""
  label var y ""
end

* show window that allows you to move moving point
program define rp_win
  version 6.0
  window manage forward dialog

  global DByplus "rp_yplus"
  window control button "Y+.5" 10 10 20 10 DByplus

  global DBymin "rp_ymin"
  window control button "Y-.5" 10 25 20 10 DBymin

  global DBxmin "rp_xmin"
  window control button "X-.5" 35 35 20 10 DBxmin

  global DBxplus "rp_xplus"
  window control button "X+.5" 65 35 20 10 DBxplus

  global mvtemp "Shift Moving Point Using Buttons Below" 
  window control static mvtemp 1 1 120 8

  global temp2 "MP at Y-Yhat=" 
  window control static temp2 40 15 50 10
  window control static DB_y  90 15 15 10

  global temp1 "     MP at X="
  window control static temp1 40 25 50 10 
  window control static DB_x  90 25 15 10 


  window control static eq1   1 50 170 10
  window control static eq2   6 57 170 10
  window control static eq3   6 64 170 10

  global DB_xxx = "OLS Reg. Diag. Stats with Moving Pt."
  window control static DB_xxx 1 74 130 10 

  global temp3 "Residual" 
  window control static temp3   6 81 30 10
  window control static DB_res  6 88 30 10

  global temp4 "Leverage" 
  window control static temp4   40 81 30 10
  window control static DB_lev  40 88 30 10 

  global temp5 "Cook's D" 
  window control static temp5    80 81 30 10
  window control static DB_cook  80 88 35 10 

  global temp9 "Choose Plot Type (then click Reshow Now)"
  window control static temp9  1 100 130 10
  global DB_plotL OLS Scatterplot with Regression Line,rreg Scatterplot with Regression Line,qreg Scatterplot with Regression Line,Residual vs. Fitted Plot,Leverage vs. Residual Squared,Lev vs. Res Squared with Cooks D
  window control scombo DB_plotL 5 110 130 60 DB_plot parse(,)

  global DB_show "rp_resh"
  window control button "Reshow Now" 5 123 50 10 DB_show


  global DB_done "quietly exit 3000"
  window control button "Done" 10 150 30 10 DB_done escape

  global DB_reset "rp_reset"
  window control button "Reset" 50 150 30 10 DB_reset 

  global DB_help "rp_help"
  window control button "Help" 90 150 30 10 DB_help

  window dialog "Regression with Moving Point" . .  140 180
  window dialog update

end

* plot the data
program define rp_plot
  version 6
  args atx incy 

  * change data for moving point, at observation #1
  replace x = `atx' in 1
  replace y = $orig_b0 + $orig_b1*x + `incy' in 1

  * run the regression, depending on type of regression
  if "$DB_plot" == "rreg Scatterplot with Regression Line" {
    capture drop genwt
    rreg y x, tune(7) genwt(genwt)
  } 
  else if "$DB_plot" == "qreg Scatterplot with Regression Line" {
    qreg y x
  } 
  else {
    regress y x
  }

  * make predicted values
  capture drop yhat
  predict yhat

  * get revised parameter estimates
  global b0r = string(_b[_cons],"%6.2f")
  global b1r = string(_b[x],"%6.2f")

  * rerun OLS regression
  regress y x

  * compute OLS residual for moving point
  capture drop res
  predict res , resid
  global DB_res = string(res[1],"%6.2f")

  * compute cooks d for moving point
  capture drop cook
  predict cook , cooksd
  global DB_cook = string(cook[1],"%6.2f")

  * compute leverage for moving point
  capture drop lev
  predict lev , leverage
  global DB_lev = string(lev[1],"%6.2f")

  * make macro with original parameter estiamtes
  global ob0r = string($orig_b0,"%6.2f")
  global ob1r = string($orig_b1,"%6.2f")

  * make macro with info with moving point, and w/o moving point
  global eq1 "Reg. Equations without and with Moving Pt."
  global eq2 "W/O (green line) : Y = $ob0r + X * $ob1r"
  global eq3 "with (red line)       : Y = $b0r + X * $b1r"
 
  * if making scatterplot, do the following
  if "$DB_plot" == "OLS Scatterplot with Regression Line" | "$DB_plot" == "rreg Scatterplot with Regression Line" | "$DB_plot" == "qreg Scatterplot with Regression Line" {
    capture drop y2
    gen y2 = y in 1
    replace y = . in 1
    label var y2 "Moving Point"
    label var y "Rest of Sample"
    graph y2 y yhat origyhat x, symbol(Soii) c(..ll) /*
      */ /* t1title(`"`t1tit'"') t2title(`"`t2tit'"')*/ /*
      */ pen(2334)    /*
      */ ylabel(-3 -2 to 6) xlabel(-6 -5 to 3) /*
      */ l2title("Value of Y") b2title("Value of X") sort `options'
  }

  * if doing residual vs. fitted, do the following
  capture drop rstan
  predict rstan , rstan
  capture drop rstan2
  predict rstan2 in 1, rstan
  replace rstan = . in 1
  label var rstan "Rest of Sample"
  label var rstan2 "Moving Point"
  if "$DB_plot" == "Residual vs. Fitted Plot" {
    graph rstan2 rstan yhat, xlabel(-1.5 -1 to 1.5) ylabel(-3 -2 to 3) symbol(So)
  }

  * if doing lev vs. residual, do the following
  if "$DB_plot" == "Leverage vs. Residual Squared" {
    rp_lvr , symbol(So)
  }

  * if doing lev vs. resid with cooks, do the following
  if "$DB_plot" == "Lev vs. Res Squared with Cooks D" {
    rp_lvr , symbol(So) cook
  }
end

** Functions called by buttons from rp_win **  

* rp_resh plot
program define rp_resh
  rp_plot $DB_x $DB_y
  window manage forward dialog
end

* show help file
program define rp_help
  whelp regpt
end

* add .5 to x
program define rp_xplus
  global DB_x = $DB_x + .5
  rp_plot $DB_x $DB_y
  window manage forward dialog
end

* subtract .5 from x
program define rp_xmin
  global DB_x = $DB_x -.5
  rp_plot $DB_x $DB_y
  window manage forward dialog
end

* add .5 to x
program define rp_yplus
  global DB_y = $DB_y + .5
  rp_plot $DB_x $DB_y
  window manage forward dialog
end

* subtract .5 from x
program define rp_ymin
  global DB_y = $DB_y -.5
  rp_plot $DB_x $DB_y
  window manage forward dialog
end

* reset x and y to 0
program define rp_reset 
  global DB_y = 0
  global DB_x = 0
  rp_plot $DB_x $DB_y
  window manage forward dialog
end

** program for making lvr2plot, (borrowed from stata lvr2plot command)
program define rp_lvr 
     /* leverage vs. residual squared */
	version 6
	_isfit cons
	syntax [, XLIne(string) YLIne(string) cook *]

      * mnm add
      if "`cook'" != "" {
        local w [w=cook]
      }

	if "`e(vcetype)'"=="Robust" { 
		di in red "leverage plot not available after robust estimation"
		exit 198
	}

	tempvar h h2 r 
	quietly { 
		_predict `h' if e(sample), hat
		_predict `r' if e(sample), resid
		replace `r'=`r'*`r'
		sum `r'
		replace `r'=`r'/(r(mean)*r(N))
		local x=1/r(N)
		local y=(e(df_m)+1)*`x'
	}
	if "`xline'"!="" {
		if "`xline'"!="." { local xline "xline(`xline')" }
		else local xline
	}
	else	local xline "xline(`x')"
	if "`yline'"!="" {
		if "`yline'"!="." { local yline "yline(`yline')" }
		else local yline
	}
	else	local yline "yline(`y')"

      gen `h2' = `h' in 1
      replace `h' = . in 1

	label var `h' "Rest of Sample"
      label var `h2' "Moving Point"
	label var `r' "Normalized residual squared"

	gr `h2' `h' `r' `w', `options' `xline' `yline' l1title("Leverage") 
end
