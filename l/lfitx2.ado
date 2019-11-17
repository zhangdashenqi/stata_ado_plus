*! 1.0.2 20May97  Jeroen Weesie/ICS   STB-44 sg87

* the first few lines of the code and the subroutine Getivars were 
* copied from -lfit- (v3.2.4) by StataCorp

program define lfitx2
    version 5.0

  quietly {

  * scratch
        
    tempvar  touse g p w x
    tempname vn nvarn V

  * Parse and generate `touse', `p' (predicted prob), and `w' (weights).

    lfit_p `touse' `p' `w' `*'

    local obs   "$S_1"
    local y     "$S_2"
    local beta  "$S_3"
    local rules "$S_4"

  * weights are not supported as of now

    if "$S_E_wgt" != "" {
        di in bl "lfitx2 ignores weights"
    }
    
  * defaults
  
    local deps "1E-5"                       /* Beware: default eps */
    
  * parse other options 

    local options "eps(real `deps') rules"  
    parse ", $S_5"
    global S_5                              /* erase macro */

  * discard observations with p < eps or p > 1-eps

    if `eps' < 0 | `eps' > 0.5 { 
        local eps "`deps'" 
    } 
    count if `touse' & min(`p',1-`p') < `eps' 
    if _result(1) > 0 {
        noi di in bl _result(1) " observations with min(p,1-p)<`eps' " /*
         */ "are excluded in computing X2/H" 
        replace `touse' = `touse' & (`p' >= `eps') & (`p' <= 1-`eps')
    }
    count if `touse'
    if _result(1) == 0 {
        noi di in bl "no observations left to compute X2"
        global S_1 0
        global S_2 .
        global S_3 .
        global S_4 .
        exit
    }
    
  * independent variables
        
    if "`rules'" != "" {                    /* get indepvars from $S_E_vl */
        parse "$S_E_vl", parse(" ")
        macro shift
        local ivars "`*'"
        local nvar : word count `ivars' _cons
    }
    else {                                  /* get indepvars from `beta' */
        Getivars `beta'
        local ivars "$S_1"
        local nvar  "$S_2"
    }

  * Compute chi-squared statistic

    gen `x' = (`y'-`p')^2 / (`p'*(1-`p')) if `touse'
    summ `x' if `touse', meanonly
    global S_1 = _result(1)                 /* number of obs */
    global S_2 = _result(18)                /* X2-statistic */
    local df   = $S_1 - $S_E_mdf - 1        /* #df for invalid chi2 distr */

  * Compute variance nvarn = n*var(n) of X2 (See Windmeijer '95: 274) 

    replace `x' = (1-2*`p')^2 / (`p'*(1-`p')) if `touse'
    summ `x' if `touse', meanonly
    scalar `nvarn' = _result(18)

    replace `x' = 1 - 2*`p' if `touse'
    mat vecacc `vn' = `x' `ivars' if `touse'
        
  * beware of robust standard errors

    if "$S_E_vce" == "" {
        mat `V' = get(VCE)
    }
    else {
        * "manually" compute AVAR for logistic regression
        mat vecacc `V' = `ivars' [iw=`p'*(1-`p')] if `touse'      
        mat `V' = syminv(`V')
    }
   
  * AVAR of X2
  
    mat `V' = `V' * `vn''
    mat `V' = `vn' * `V'
    scalar `nvarn' = `nvarn' - `V'[1,1]

  * AVAR is not ensured to be positive in finite samples (!)
    
    if `nvarn' < 0 {
        noi di in bl "lfitx2: negative approximate variance, test skipped"
        global S_3 .
        global S_4 .
        exit
    }
                
  * Windmeijer's H-statistic, asymptotically Chi2 under H0

    global S_3 = ($S_2 - $S_1)^2 / `nvarn'
    global S_4 = `nvarn'    

  } /* end quietly */

  * Display results
        
    di _n in gr "Logistic model for `y', Pearson's goodness-of-fit test" _n
    di in gr "         number of observations = " in ye %9.0g $S_1
    di in gr "                   Pearson's X2 = " in ye %9.3f $S_2
    di in gr "               Prob > chi2(" in ye `df' in gr ")" /*
             */ _col(33) "= " in ye %9.4f chiprob(`df', $S_2) /*
             */ _col(50) in bl "Beware: Invalid!" 
    di in gr "Windmeijer's H = normalized(X2) = " in ye %9.3f $S_3
    di in gr "                 Prob > chi2(1) = " in ye %9.4f chiprob(1,$S_3)

    if "$S_E_cvn" != "" {
        di in bl "Significance of X2 is not adjusted for clustering"
    }
end

* Getivars was copied from lfit (version 3.2.4)
program define Getivars
        version 5.0
        local beta "`1'"

        if "`beta'" == "" {
                tempname beta
                matrix `beta' = get(_b)
        }
        local ivars : colnames(`beta')
        local nvar  : word count `ivars'
        parse "`ivars'", parse(" ")
        if "``nvar''" == "_cons" { /* look at last element */
                local `nvar'       /* erase last macro */
                local ivars "`*'"
        }
        else if "`1'" == "_cons" { /* look at first element */
                macro shift
                local ivars "`*'"
        }
        else { /* step through elements to capture "_cons" */
                local ivars "`1'"
                local i 2
                while "``i''" != "" {
                        if "``i''" != "_cons" {
                                local ivars "`ivars' ``i''"
                        }
                        local i = `i' + 1
                }
        }
        global S_1 "`ivars'"
        global S_2 "`nvar'"
end
