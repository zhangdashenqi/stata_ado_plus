*! PROBPRED.ADO by Mead Over, October 30, 1996 Version 1.0.1  STB 42 sg42.2
*  Program to plot predicted values for probit or logit regression models 
*  Based on LOGPRED.ADO by Joanne M. Garrett published 02/20/95 
*  in sg42: STB-26.
*  Extended to perform simulations with some of the control variables set to equal zero 
*  or one instead of to their means.  The level option is also implemented following 
*  standard STATA usage.  Default is to estimate a probit model using the dprobit command.
*  Adding the option -logit- specifies the logit model instead.
*  Form:  probpred y x, from(#) to(#) inc(#) adj(cov_list) options        
*  Options required: from(#), to(#), increment(#)                         
*  Options allowed: logit, poly, adjust, nomodel, noplot, xlab, ylab, nolist, one, zero, level
*  Note:  X variable must be continuous (interval or ordinal)             */

program define probpred
  version 4.0
  #delimit ;
    local options 	"From(real 2) To(real 1) Inc(real 1) Poly(real 0)
       	NOModel Adjust(string) NOList NOPlot T1title(string) L1title(string)
       	Logit Zero(string) One(string) LEVel(real 0) *";     
  #delimit cr
  local varlist "req ex min(2) max(2)"
  local if "opt"
  parse "`*'"
  if `from' >= `to' {
  	di in red "The interval over which the simulation is to be performed must be specified"
  	di in red "in the From() and To() options and To() must be greater than From()."
  	error 198
  	/* This line is not reached.*/
  }
  parse "`varlist'", parse(" ")
  local lvl = $S_level                                                       
    if `level' > 0  {  local lvl = `level'  }                                
  preserve
  capture keep `if'
  keep `varlist' `adjust'
  local varlbly : variable label `1'
  local yvar="`1'"
  local varlblx : variable label `2'
  local xvar="`2'"
  quietly drop if `xvar'==. | `yvar'==.

* If there are covariates, drop obs. with missing, then set them to means 
  parse "`adjust'", parse(" ")
  local numcov=0
  local i=1
  while "`1'"~=""  {
    local cov`i'="`1'"
    quietly drop if `cov`i''==.
    local i=`i'+1
    macro shift
    local numcov=`i'-1
    }

* Set each covariate to zero, one or to the sample mean.
  local i=1
  while `i'<=`numcov'  {
    local set0 = 0                                       
    local set1 = 0                                       
    parse "`zero'", parse(" ")                           
    while "`1'"~=""  {                                   
        if "`cov`i''" == "`1'"  {local set0 = 1 }        
        macro shift                                      
    }                                                    
    parse "`one'", parse(" ")                            
    while "`1'"~=""  {                                   
        if "`cov`i''" == "`1'"  {local set1 = 1 }        
        macro shift                                      
    }                                                    
    if `set0' == 0 & `set1' == 0 {                       
        quietly sum `cov`i''
        local mcov`i'=_result(3)
    }                                                    
    else  {                                              
	if `set0' == 1 & `set1' ==1 {                    
	    di in red "The same variable cannot be set to both 0 and 1."   
	    error 198                                    
	}                                                
	if `set0' == 1  {                                
	    local mcov`i'=0                              
	}                                                
	else  {                                          
	    local mcov`i'=1                              
	}                                                
    }                                                    
    local i=`i'+1
    }

* If polynomial terms are requested, create them
  if `poly'==2  {
     gen x_sq=`xvar'^2
     local polylst="x_sq"
     }
  if `poly'==3  {
     gen x_sq=`xvar'^2
     gen x_cube=`xvar'^3
     local polylst="x_sq x_cube"
     }
  
* Run logit or probit regression model.
  if "`nomodel'"=="nomodel"  { local shhh = "quietly"  }                   
	if "`logit'"=="logit"  {
		`shhh' logistic `yvar' `xvar' `polylst' `adjust', level(`lvl') 
	}
	else  {
		`shhh' dprobit `yvar' `xvar' `polylst' `adjust', level(`lvl') 
	}
  if "'shhh'"==""  { more }                                                
  local newn=_result(1)

* Generate the values of x to calculate the predicted values
  drop _all
  local i=`from'
  while `i'<`to'  {
    local i=`i'+`inc'
    }
  if `i'>`to'  {
    local to=`i'-`inc'
    }
  local newobs=((`to'-`from')/`inc')+1
  local newobs=round(`newobs',1)
  quietly range `xvar' `from' `to' `newobs'
  label var `xvar' "`varlblx'"
  if `poly'==2  {
     gen x_sq=`xvar'^2
     }
  if `poly'==3  {
     gen x_sq=`xvar'^2
     gen x_cube=`xvar'^3
     }
  local i=1
  while `i'<=`numcov'  {
    quietly gen `cov`i''=`mcov`i''
    local i=`i'+1
    }
  
* Calculate the predicted values and confidence intervals
  tempvar se linpred
  local tail = (100-`lvl')/2/100                                            
  predict pred
  predict `se', stdp
  predict `linpred', xb
  if "`logit'"=="logit"  {
	gen lower=1/(1+exp(-`linpred'- invnorm(`tail') *`se')) 
	gen upper=1/(1+exp(-`linpred'- invnorm(1-`tail') *`se')) 
  }
  else  {
	gen lower=normprob(`linpred'+ invnorm(`tail') *`se')
	gen upper=normprob(`linpred'+ invnorm(1-`tail') *`se')
  }
  
* Plot and list results
  if "`noplot'"~="noplot"  {
    if "`t1title'"=="" {
       local t1title "Predicted Values for `varlbly' -- $S_E_depv"
       }
    if "`l1title'"=="" {local l1title "Probabilities and `lvl'% CI"}
    #delimit ;
    graph pred upper lower `xvar', sort c(sss) s(Oii) t1("`t1title'")
       l1("`l1title'") `options' ;
    #delimit  cr
    }
  if "`nolist'"~="nolist"  {
     display "  "
     display in green "Probabilities and `lvl'% Confidence Intervals"
     display "  "
     display "  Outcome Variable:     `varlbly' -- $S_E_depv"
     display "  Independent Variable: `varlblx' -- `xvar'"
     if `poly'==2 | `poly'==3  {
        display "  Polynomial Terms:     `polylst'
        }
     display "  Covariates:           `adjust'"
     display "  Variables set to Zero:`zero'"            /* MO */
     display "  Variables set to One: `one'"             /* MO */
     display "  Total Observations:   `newn'"
     if `level' > 0  {                                   /* MO */ 
	display "  Confidence interval:   `level'"       /* MO */
     }                                                   /* MO */  
     list `xvar' pred lower upper 
     }
end
