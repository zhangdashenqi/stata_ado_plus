*! Version 1.0, August 2010, by Graham K. Brown and Thanos Mergoupis

program itreatreg, rclass

	syntax varlist [if] [in], treat(string) x(string) gen(string) [oos] [twostep]

/*
   first, we separate out the dependent variable from the non-interacted variables and define some
   temporary variables and macros used in the process
*/

	tokenize `varlist'
	local depvar `1'
	macro shift
	local indvars `*'
	local npairs=0
	tempvar y1diff


/*
   this section checks the syntax of the information entered into the x() option, and then breaks up the contents 
   of the option and structures it into three strings, one of which contains a list of interaction terms where the 
   original variable was not included, the other two containing a co-ordered list of interaction terms and the 
   original variables.  the macro npairs keeps track of the number of paired variables 
*/

	foreach xpair in `x' {

		tokenize `xpair', parse("=")
		if "`1'"=="" {
			display in red "Syntax error in x()"
			exit 198
		}

		if "`2'"=="" {
			local Xnoivs "`Xnoivs' `1' "
		}

		else {

			if "`2'"!="=" {
				display in red "Syntax error in x()"
				exit 198
			}

			if "`3'"=="" {
				display in red "Syntax error in x()"
				exit 198
			}
	
			if "`4'"!="" {
				display in red "Syntax error in x()"
				exit 198
			}


			local ivstoX="`ivstoX' `3' "
			local Xivs="`Xivs' `1' "
			local ++npairs

		}
	}

/*
   this section moves onto the gen() option, checks its syntax and creates macros to store the names of the variables
   that will hold the predicted values.  the variables themselves are not yet created, as they are created by the
   predict command below
*/


	tokenize `gen'

	if "`1'"=="" {
		display in red "Syntax error in gen()"
		exit 198
	}

	if "`2'"!="" {
		display in red "Syntax error in gen()"
		exit 198
	}

	local y1ctrt "`1'ctrt"
	local y1cntrt "`1'nctrt"
	
/*
   estimate the model
*/

	treatreg `depvar' `indvars' `ivstoX' `Xivs' `Xnoivs' `if' `in', treat(`treat') `twostep'

/*
   having estimated the model, we can jettison the treatment equation, but need to keep the name of the
   treatment variable itself
*/

	tokenize `"`treat'"', parse("=")

	local y2 "`1'"

/*  generate the unadjusted predicted values  */


	if "`oos'"=="oos" {

		qui predict "`y1ctrt'", yctrt
		qui predict "`y1cntrt'", ycntrt	
	}
	
	else {
		qui predict "`y1ctrt'" `if' `in', yctrt
		qui predict "`y1cntrt'" `if' `in', ycntrt	
	}

/*  construct two strings that contain the adjustment code for the treatment and non-treatment estimations */

	foreach t_Xnoiv in `Xnoivs' {

		local adjustctrt="`adjustctrt' [`depvar']_b[`t_Xnoiv'] +"
	
	}


	forvalues i=1/`npairs' {

		tokenize `Xivs'
		local t_Xivs `1'
		macro shift
		local Xivs `*'

		tokenize `ivstoX'
		local t_ivstoX `1'
		macro shift
		local ivstoX `*'

		local adjustctrt="`adjustctrt' [`depvar']_b[`t_Xivs']*`t_ivstoX' +"
		local adjustcntrt="`adjustcntrt' [`depvar']_b[`t_Xivs']*`t_ivstoX' +"

	}

	local adjustctrt="`adjustctrt' 0"
	local adjustcntrt="`adjustcntrt' 0"

/* apply the adjustment, compute the difference and generate the adjusted average treatment effect */

	qui replace `y1ctrt' = `y1ctrt' + (1-`y2')*(`adjustctrt') 
	qui replace `y1cntrt' = `y1cntrt' - `y2'*(`adjustcntrt') 

	qui gen `y1diff' = `y1ctrt' - `y1cntrt'

	qui sum `y1diff'
	local ysc = r(mean)
	local ymwm = r(sd)
	local aypiap = r(N)

	display as text "Average Treatment Effect (ATE)  = " as result r(mean)
	display as text "Standard deviation of Treatment Effect = " as result r(sd)
	return scalar ate=`ysc'
	return scalar te_sd=`ymwm'
	return scalar N_ate=`aypiap'
	return local varctrt "`y1ctrt'"
	return local varcntrt "`y1cntrt'"

end
