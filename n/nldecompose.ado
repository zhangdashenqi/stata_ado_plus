// ------------------------------------------------------
// Authors: Mathias Sinning  (mathias.sinning@anu.edu.au)
//          Markus Hahn      (mhahn@unimelb.edu.au)
//
// Date  :  August 19, 2008
// -------------------------------------------------------

program define nldecompose
version 10
    * parse syntax
    
    capture _on_colon_parse `0'
    if !_rc {
    	local regcmd `"`s(after)'"'
	local 0 `"`s(before)'"'
    }
    else {
       	syntax, regcmd(string asis) [*]
	local 0 , `options'
    }
    
    syntax, [bootstrap] [bs] [BSOptions(string asis)] [bs_step] [THREEfold] [omega(passthru)] [*]
    
     if "`bs'" != "" {
        if "`bootstrap'" == "" {
            local bootstrap = "bootstrap"
            }
        else {
            di as error "You are not allowed to specify <bootstrap> and <bs> at the same time!"
            error 99999
        }
    }
    
    if "`bootstrap'" == "" {
        if "`bs_step'" == "" {
            nld_dropnlds
        }
        
        nld_decomposition `", `threefold' `omega' `options'"' `"`regcmd'"'
        
        if "`bs_step'" == "" {
            nld_setreturns
            ereturn clear
            sreturn clear
        }
    }
    else {
        nld_dropnlds
        
        // exps for bootstrap
        if "`threefold'" == "" {
            local exps raw charAB coefAB charBA coefBA
        }
        else {
            local exps raw charAB coefAB intAB charBA coefBA intBA
        }
        if "`omega'" != "" {
            local exps `exps' prod adv disadv
        }
	
	
        foreach exp of local exps {
            local nld_exps `nld_exps' nld_`exp'
        }
	
	qui bootstrap `nld_exps', `bsoptions': nldecompose, regcmd(`regcmd') bs_step `threefold' `omega' `options'
        nld_create_bootstrap_nlds `exps'
        nld_setreturns
        ereturn clear
        sreturn clear
    }
    
    if "`bs_step'" == "" {
        nld_output, `bootstrap'
    }
    
end


program define nld_decomposition, rclass
    args 0 regcmd
    syntax , BY(varname) [THREEfold] [omega(string)] [REGOUTput] [ll(string)] [ul(string)]
    
    global nld_threefold `threefold'
    global nld_omega `omega'
    
    nld_parse_regcmd `regcmd'
    local svy `r(svy)'      // only not empty if "svy:" prefix was specified
    local regmodel `r(regcmd)'
    local 0 `r(rest)'
    syntax varlist(min=2) [if/] [in] [aweight iweight pweight fweight], *
    if `"`if'"' == "" {
        local if = 1
    }
    if "`weight'" != "" {
        local wght = `"[`weight' `exp']"'
    }
    if "`regoutput'" != "regoutput" {
        local regquietly quietly
    }
    nld_getcmd `regmodel'
    local regcmd `r(cmd)'
    
    /////////////////////////////////
        
    tempvar group 
    qui gen double `group' = 1-`by' 

    * temporary variables / scalars 
    tempvar sampleA sampleB
        foreach X in A B AB BA {
            tempname _expval`X' 
            scalar `_expval`X'' = 0
            tempname c_expval`X'
            scalar `c_expval`X'' = 0
        }
    tempname result // result matrix
    tempname sigmaA sigmaB
    tempname raw

    // matrices
    tempname getbA betaA gammaA nameA est_b cats getbB betaB gammaB getb beta_star gamma_star beta_1 gamma_1 gamma_mat gamma_vec diag1 diag2 diag1_g diag2_g inv inv_g omega_mat omega_vec out _O W W_gamma I I_gamma
    //
    
    //////////////////////////////////
    
    
    * parse varlist
    nld_parse_varlist "`varlist'" "`regcmd'"
    local depvar `r(depvar)'
    local indvar `r(indvar)'

    * regressions 
    * do regression for group A
    `regquietly' `svy' `regcmd' `depvar' `indvar' if (`group'==0) & (`if') `in' `wght', `options'
    qui gen byte `sampleA' = e(sample)
    est store A
    
    * get beta vector
    mat `getbA' = e(b)
    local dim1 = wordcount("`indvar'")
    local dim2 = colsof(`getbA')
    if ("`regcmd'"!="zip" & "`regcmd'"!="zinb" & "`regcmd'"!="ologit" & "`regcmd'"!="oprobit") {
        mat `betaA' = `getbA'[1,1..`dim1'+1]
        local k1 = `dim1'+1
    }
    else if ("`regcmd'"=="ologit" | "`regcmd'"=="oprobit") {
        mat `betaA' = `getbA'[1,1..`dim1']
        local k1 = `dim1'
    }
    else if ("`regcmd'"=="zip") {
        local k1 = `dim1'+1
        mat `betaA' = `getbA'[1,1..`k1']
        mat `gammaA' = `getbA'[1,`k1'+1..`dim2']        
        local k2 = colsof(`gammaA')
        mat `nameA' = `getbA'[1,`k1'+1..`dim2'-1]
        mat `nameA' = `nameA''
        local namesA : rownames `nameA'
    }
    else if ("`regcmd'"=="zinb") {
        local k1 = `dim1'+1
        mat `betaA' = `getbA'[1,1..`k1']
        mat `gammaA' = `getbA'[1,`k1'+1..`dim2'-1]
        local k2 = colsof(`gammaA')
        mat `nameA' = `getbA'[1,`k1'+1..`dim2'-2]
        mat `nameA' = `nameA''
        local namesA : rownames `nameA'
    }
    if "`k2'" == "" {
        local k2 = 0
    }
    
    local obsA = e(N)   // save number of observations

    * retrieve sigma - needed for censored and truncated regression models
    if ("`regcmd'"=="intreg" | "`regcmd'"=="truncreg") {
        scalar `sigmaA' = e(sigma)
    }
    else if ("`regcmd'"=="tobit") {
        scalar `sigmaA' = r(est)
    }
    
    * retrieve categories and threshold values - needed for ordered choice models
    if ("`regcmd'"=="ologit" | "`regcmd'"=="oprobit") {
        mat `est_b' = e(b)
        local k = colsof(`est_b')
        mat `cats' = e(cat)
        local category = colsof(`cats')
        local threshnum = `category'-1
        forvalues num = 1/`threshnum' {
            local mathias = `k'-`threshnum'+ `num'
            scalar mu`num'A = `est_b'[1,`mathias']
        }
    }

    * do regression for group B
    `regquietly' `svy' `regcmd' `depvar' `indvar' if (`group'==1) & (`if') `in' `wght', `options'
    qui gen byte `sampleB' = e(sample)
    est store B
    
    * get beta vector
    mat `getbB' = e(b)
    local dim1 = wordcount("`indvar'")
    local dim2 = colsof(`getbB')
    if ("`regcmd'"!="zip" & "`regcmd'"!="zinb" & "`regcmd'"!="ologit" & "`regcmd'"!="oprobit") {
        mat `betaB' = `getbB'[1,1..`dim1'+1]
    }
    else if ("`regcmd'"=="ologit" | "`regcmd'"=="oprobit") {
        mat `betaB' = `getbB'[1,1..`dim1']
    }
    else if ("`regcmd'"=="zip") {
        mat `betaB' = `getbB'[1,1..`dim1'+1]
        mat `gammaB' = `getbB'[1,`dim1'+2..`dim2']
    }
    else if ("`regcmd'"=="zinb") {
        mat `betaB' = `getbB'[1,1..`dim1'+1]
        mat `gammaB' = `getbB'[1,`dim1'+2..`dim2'-1]    
    }
    local obsB = e(N)   // save number of observations

    * retrieve sigma - needed for censored and truncated regression models
    if ("`regcmd'"=="intreg" | "`regcmd'"=="truncreg") {
        scalar `sigmaB' = e(sigma)
    }
    else if ("`regcmd'"=="tobit") {
        scalar `sigmaB' = r(est)
    }
    
    * retrieve categories and threshold values - needed for ordered choice models
    if ("`regcmd'"=="ologit" | "`regcmd'"=="oprobit") {
        mat `est_b' = e(b)
        local k = colsof(`est_b')
        mat `cats' = e(cat)        
        local category_B = colsof(`cats')
        if `category_B'!=`category' { 
            di as error "ERROR: dependent variables of group A and B have different number of categories"
            error 99999    
        }
        local threshnum = `category'-1
        forvalues num = 1/`threshnum' {
            local mathias = `k'-`threshnum'+ `num'
            scalar mu`num'B = `est_b'[1,`mathias']
        }
    }

    * temporary variables
    foreach X in A B AB BA {
        tempvar _pred`X'
        tempvar _pred2`X'
        tempvar _value`X'
        tempvar c_pred`X'
        tempvar c_pred2`X'
        tempvar c_value`X'
    }
    
    * predictions 
    qui est restore A
    qui predict double `_predA'  if `sampleA' == 1, xb
    qui predict double `_predAB' if `sampleB' == 1, xb // counterfactual
    if ("`regcmd'"=="zip" | "`regcmd'" == "zinb") {
        qui predict double `_pred2A'  if `sampleA' == 1, xb equation(inflate)
        qui predict double `_pred2AB' if `sampleB' == 1, xb equation(inflate)
    }
    qui est restore B
    qui predict double `_predB'  if `sampleB' == 1, xb
    qui predict double `_predBA' if `sampleA' == 1, xb // counterfactual
    if ("`regcmd'"=="zip" | "`regcmd'"=="zinb") {
        qui predict double `_pred2B'  if `sampleB' == 1, xb equation(inflate)
        qui predict double `_pred2BA' if `sampleA' == 1, xb equation(inflate)
    }

    est drop A B

    * create omega matrix    
    if "`omega'" != "" {
    
    * omega matrix proposed by Cotton (1988)
        if "`omega'" == "cotton" {
            if `obsA' >= `obsB' {
                local shareAB = `obsA'/(`obsA'+`obsB')            
                local omega = `shareAB'
            }
            else if `obsA' < `obsB' {
                local shareAB = `obsB'/(`obsA'+`obsB')
                local omega = `shareAB'
            }
        } 
    
    * omega matrix proposed by Reimers (1983)
        else if "`omega'" == "reimers" {
            local omega = .5
        }
   
    * omega matrix proposed by Neumark (1988) 
        else if ("`omega'" == "neumark") {
        
            `regquietly' `svy' `regcmd' `depvar' `indvar' if (`if') `in' `wght', `options'
            mat `getb' = e(b)
            if ("`regcmd'"!="zip" & "`regcmd'"!="zinb" & "`regcmd'"!="ologit" & "`regcmd'"!="oprobit") {
                    mat `beta_star' = `getb'[1,1..`k1']
            }
            else if ("`regcmd'"=="ologit" | "`regcmd'"=="oprobit") {
                mat `beta_star' = `getb'[1,1..`k1']
            }
            else if ("`regcmd'"=="zip") {
                mat `beta_star' = `getb'[1,1..`k1']
                mat `gamma_star' = `getb'[1,`k1'+1..`dim2']
            }
            else if ("`regcmd'"=="zinb") {
                mat `beta_star' = `getb'[1,1..`k1']
                mat `gamma_star' = `getb'[1,`k1'+1..`dim2'-1]
            }

            mat `beta_1' = J(`k1',1,1)
            forvalues one=1/`k1' {
                mat `beta_1'[`k1',1] = 1
            }
            mat `diag1' = diag(`betaA'-`betaB')
            mat `diag2' = diag(`beta_star'-`betaB')
            mat `inv' = inv(`diag1')
            mat `omega_mat' = `diag2'*`inv'
            mat `omega_vec' = `omega_mat'*`beta_1'
            mat `omega_vec' = `omega_vec''
            forvalues one=1/`k1' {
                if `one'==1 {
                    local omega1 = `omega_vec'[1,1]
                    local omega2 `omega1'  
                }
                else if `one'>1 {
                    local comma ,
                    local omega_`one' = `omega_vec'[1,`one']
                    local omega2 `omega2' `comma' `omega_`one''
                }  
            }
            local omega `omega2'
            if ("`regcmd'"=="zip") | ("`regcmd'"=="zinb") {
                    mat `gamma_1' = J(`k2',1,1)
                    forvalues one=1/`k2' {
                        mat `gamma_1'[`k2',1] = 1
                    }
                    mat `diag1_g' = diag(`gammaA'-`gammaB')
                    mat `diag2_g' = diag(`gamma_star'-`gammaB')
                    mat `inv_g' = inv(`diag1_g')
                    mat `gamma_mat' = `diag2_g'*`inv_g'
                    mat `gamma_vec' = `gamma_mat'*`gamma_1'
                    mat `gamma_vec' = `gamma_vec''
                    forvalues one=1/`k2' {
                        if `one'==1 {
                            local gamma1 = `gamma_vec'[1,1]
                            local gamma2 `gamma1'  
                        }
                        else if `one'>1 {
                            local comma ,
                            local gamma_`one' = `gamma_vec'[1,`one']
                            local gamma2 `gamma2' `comma' `gamma_`one''
                        }  
                    }
                    local gamma `gamma2'
            }        
        }

    * output of omega
        matrix input `out' = (`omega')
        mat `_O' = diag(`out')
        local dimension = colsof(`_O')
        if `dimension' == 1 {
            local w_noout = 0
            local weight = `omega'
        }
        else if `dimension' != 1 {
            local w_noout = 1
        }

    * calculate omega using nld_progomega
        if "`threshnum'" == "" {
            local threshnum = 0
        }
        
    * nld_progomega
        nld_progomega, omega(`omega') dim1(`k1') dim2(`k2') 

    * get omega matrix
        matrix `W' = r(W)

    * get matrix for gamma
        if ("`regcmd'"=="zip" | "`regcmd'" == "zinb") {
            mat `W_gamma' = r(W_gamma)
        }
    local noout = 0
    }
    
    * create default matrix omega 
    else if "`omega'" == "" {
        matrix `W' = I(`k1')
    
    * create default matrix gamma
        if ("`regcmd'"=="zip" | "`regcmd'" == "zinb") {
            mat `W_gamma' = I(`k2')
        }

    *suppress output
        local noout = 1
        local w_noout = 1
    }    
    
    * counterfactual beta
    mat `I' = I(`k1')    
    mat `beta_star' = `W'*`betaA'' + (`I'-`W')*`betaB''
    mat `beta_star' = `beta_star''
    
    * counterfactual gamma
    if ("`regcmd'"=="zip" | "`regcmd'" == "zinb") {
        mat `I_gamma' = I(`k2')    
        mat `gamma_star' = `W_gamma'*`gammaA'' + (`I_gamma'-`W_gamma')*`gammaB''
        mat `gamma_star' = `gamma_star''
    }

    * mu
    if ("`regcmd'"=="ologit" | "`regcmd'" == "oprobit") {
        forvalues num = 1/`threshnum' {
            scalar mu`num'BA = mu`num'A     
            scalar mu`num'AB = mu`num'A   
        }   
    }
    
    * counterfactual predictions
    qui gen double `c_predA' = 0 if `sampleA' == 1
    qui gen double `c_predB' = 0 if `sampleB' == 1
    qui gen double `c_predAB' = 0 if `sampleB' == 1
    qui gen double `c_predBA' = 0 if `sampleA' == 1
    if ("`regcmd'"=="zip" | "`regcmd'" == "zinb") {
        qui gen double `c_pred2A' = 0 if `sampleA' == 1
        qui gen double `c_pred2B' = 0 if `sampleB' == 1
        qui gen double `c_pred2AB' = 0 if `sampleB' == 1
        qui gen double `c_pred2BA' = 0 if `sampleA' == 1
    }
    local cnt = 1
    tempvar const
    qui gen double `const' = 1
    if ("`regcmd'"!="ologit" & "`regcmd'" != "oprobit") {
        local indvar2 `indvar' `const'
    }
    else if ("`regcmd'"=="ologit" | "`regcmd'" == "oprobit") {
        local indvar2 `indvar' 
    }
    foreach var in `indvar2' {
        qui replace `c_predA' = `c_predA' + `betaA'[1,`cnt']*`var' if `sampleA' == 1
        qui replace `c_predB' = `c_predB' + `betaB'[1,`cnt']*`var' if `sampleB' == 1
        qui replace `c_predAB' = `c_predAB' + `beta_star'[1,`cnt']*`var' if `sampleB' == 1
        qui replace `c_predBA' = `c_predBA' + `beta_star'[1,`cnt']*`var' if `sampleA' == 1
        local cnt = `cnt'+1
    }
    if ("`regcmd'"=="zip" | "`regcmd'" == "zinb") {
        local cnt2 = 1
        local indvar3 `namesA' `const'
        foreach var in `indvar3' {    
            qui replace `c_pred2A' = `c_pred2A' + `gammaA'[1,`cnt2']*`var' if `sampleA' == 1
            qui replace `c_pred2B' = `c_pred2B' + `gammaB'[1,`cnt2']*`var' if `sampleB' == 1
            qui replace `c_pred2AB' = `c_pred2AB' + `gamma_star'[1,`cnt2']*`var' if `sampleB' == 1
            qui replace `c_pred2BA' = `c_pred2BA' + `gamma_star'[1,`cnt2']*`var' if `sampleA' == 1
            local cnt2 = `cnt2'+1
        }
    }
    
    * decomposition 

    * compute conditional expected values 
    if ("`regcmd'"=="intreg" | "`regcmd'"=="tobit" | "`regcmd'"=="truncreg" ) {
    
    	// retrieve limits used in regression
	local llimit `ll'
	local ulimit `ul'
	
	if "`llimit'" == "" {
		local llimit .
	}
	
	if "`ulimit'" == "" {
		local ulimit .
	}
	
    	tempvar ll ul
        nld_dcp_limits, regcmd(`regcmd') ll(`ll') ul(`ul') llimit(`llimit') ulimit(`ulimit')
	
	
        
        if ("`regcmd'"=="intreg" | "`regcmd'"=="tobit" ) {
            local DUMMY = 1
            }
        else if ("`regcmd'"=="truncreg") {
            local DUMMY = 0
            }
        foreach z in _ c_ {
            * decomposition depends on specified limits
	    
           	    
            qui gen double ``z'valueA'  = .
	    qui gen double ``z'valueB'  = .
	    qui gen double ``z'valueAB' = .
	    qui gen double ``z'valueBA' = .
	    
	    
	    ////////////////////////////////
	    // observations with no limits
	    
	    foreach X in A B {
	    	qui replace ``z'value`X'' = ``z'pred`X'' if `sample`X'' == 1 & (`ll'==.) & (`ul'==.)
	    }
	    qui replace ``z'valueAB' = ``z'predAB' if `sampleB' == 1 & (`ll'==.) & (`ul'==.)
	    qui replace ``z'valueBA' = ``z'predBA' if `sampleA' == 1 & (`ll'==.) & (`ul'==.)
	    
	    /////////////////////////////
	    // observations with ll only
	    
                * group A + B
                foreach X in A B {
                    qui replace ``z'value`X'' = `DUMMY'*`ll'*normal((`ll'-``z'pred`X'')/`sigma`X'') + ///
                        (1-normal((`ll'-``z'pred`X'')/`sigma`X''))*``z'pred`X''+`sigma`X''*normalden((`ll'-``z'pred`X'')/`sigma`X'') if `sample`X'' == 1 & (`ll'!=.) & (`ul'==.)
                }
    
                * AB 
                    qui replace ``z'valueAB' = `DUMMY'*`ll'*normal((`ll'-``z'predAB')/`sigmaA') + ///
                        (1-normal((`ll'-``z'predAB')/`sigmaB'))*``z'predAB'+`sigmaB'*normalden((`ll'-``z'predAB')/`sigmaB') if `sampleB'==1 & (`ll'!=.) & (`ul'==.)
                * BA 
                    qui replace ``z'valueBA' = `DUMMY'*`ll'*normal((`ll'-``z'predBA')/`sigmaA') + ///
                        (1-normal((`ll'-``z'predBA')/`sigmaA'))*``z'predBA'+`sigmaA'*normalden((`ll'-``z'predBA')/`sigmaA') if `sampleA'==1 & (`ll'!=.) & (`ul'==.)
            
	    /////////////////////////////
	    // observations with ul only
            
                * group A + B 
                foreach X in A B {
                    qui replace ``z'value`X'' = `DUMMY'*`ul'*(1-normal((`ul'-``z'pred`X'')/`sigma`X'')) + ///
                        normal((`ul'- ``z'pred`X'')/`sigma`X'')*``z'pred`X''-`sigma`X''*normalden((`ul'-``z'pred`X'')/`sigma`X'') if `sample`X''==1 & (`ll'==.) & (`ul'!=.)
                }
            
                * AB
                    qui replace ``z'valueAB' = `DUMMY'*`ul'*(1-normal((`ul'-``z'predAB')/`sigmaB')) + ///
                        normal((`ul'- ``z'predAB')/`sigmaB')*``z'predAB'-`sigmaB'*normalden((`ul'-``z'predAB')/`sigmaB') if `sampleB'== 1 & (`ll'==.) & (`ul'!=.)
    
                * BA 
                    qui replace ``z'valueBA' = `DUMMY'*`ul'*(1-normal((`ul'-``z'predBA')/`sigmaA')) + ///
                        normal((`ul'- ``z'predBA')/`sigmaA')*``z'predBA'-`sigmaA'*normalden((`ul'-``z'predBA')/`sigmaA') if `sampleA'== 1 & (`ll'==.) & (`ul'!=.)
            
	    
	    ///////////////////////////////
	    // observations with ll and ul
                * group A + B 
                foreach X in A B {
                    qui replace ``z'value`X'' = `DUMMY'*`ll'*normal((`ll'-``z'pred`X'')/`sigma`X'') + ///
                        `DUMMY'*`ul'*(1-normal((`ul'-``z'pred`X'')/`sigma`X'')) + ///
                        (normal((`ul'-``z'pred`X'')/`sigma`X'')-normal((`ll'-``z'pred`X'')/`sigma`X'')) * ///
                        (``z'pred`X''+`sigma`X''*((normalden((`ll'-``z'pred`X'')/`sigma`X'') ///
                        - normalden((`ul'-``z'pred`X'')/`sigma`X''))/( normal((`ul' ///
                        - ``z'pred`X'')/`sigma`X'') - normal((`ll'-``z'pred`X'')/`sigma`X'')))) if `sample`X'' == 1 & (`ll'!=.) & (`ul'!=.)
                }
    
                * AB 
                    qui replace ``z'valueAB' = `DUMMY'*`ll'*normal((`ll'-``z'predAB')/`sigmaB') + ///
                        `DUMMY'*`ul'*(1-normal((`ul'-``z'predAB')/`sigmaB')) + ///
                        (normal((`ul'-``z'predAB')/`sigmaB')-normal((`ll'-``z'predAB')/`sigmaB')) * ///
                        (``z'predAB'+`sigmaB'*((normalden((`ll'-``z'predAB')/`sigmaB') ///
                        - normalden((`ul'-``z'predAB')/`sigmaB'))/( normal((`ul' ///
                        - ``z'predAB')/`sigmaB') - normal((`ll'-``z'predAB')/`sigmaB')))) if `sampleB'== 1 & (`ll'!=.) & (`ul'!=.)
			
                * BA
                    qui replace ``z'valueBA' = `DUMMY'*`ll'*normal((`ll'-``z'predBA')/`sigmaA') + ///
                        `DUMMY'*`ul'*(1-normal((`ul'-``z'predBA')/`sigmaA')) + ///
                        (normal((`ul'-``z'predBA')/`sigmaA')-normal((`ll'-``z'predBA')/`sigmaA')) * ///
                        (``z'predBA'+`sigmaA'*((normalden((`ll'-``z'predBA')/`sigmaA') ///
                        - normalden((`ul'-``z'predBA')/`sigmaA'))/( normal((`ul' ///
                        - ``z'predBA')/`sigmaA') - normal((`ll'-``z'predBA')/`sigmaA')))) if `sampleA'== 1 & (`ll'!=.) & (`ul'!=.)
	    
	    
	    // generating means
	    foreach X in A B AB BA {
                    qui su ``z'value`X'', meanonly
                    scalar ``z'expval`X'' = r(mean)
            }
        }
    }

    else {
        if ("`regcmd'"!="tobit" & "`regcmd'"!="intreg" & "`regcmd'"!="truncreg") {
            foreach z in _ c_ {
                foreach X in A B AB BA {
                    if ("`regcmd'"=="regress") {
                        qui gen double ``z'value`X'' = ``z'pred`X''
                    }
                    else if ("`regcmd'"=="poisson" | "`regcmd'"=="nbreg" | "`regcmd'"=="ztp" | "`regcmd'"=="ztnb") {
                        qui gen double ``z'value`X'' = exp(``z'pred`X'')
                    }
                    else if ("`regcmd'"=="probit") {
                        qui gen double ``z'value`X'' = normal(``z'pred`X'')
                    }
                    else if ("`regcmd'"=="logit") {
                        qui gen double ``z'value`X'' = 1 / (1 + exp(-``z'pred`X''))
                    }
                    else if ("`regcmd'"=="ologit") {
                        if `threshnum' == 1 {
                            qui gen double ``z'value`X'' = 1-(exp(mu1`X'-``z'pred`X'')/(1+exp(mu1`X'-``z'pred`X'')))
                        }
                        else if `threshnum' > 1 {
                            qui gen double ``z'value`X'' = exp(mu1`X'-``z'pred`X'')/(1+exp(mu1`X'-``z'pred`X'')) - exp(-``z'pred`X'')/(1+exp(-``z'pred`X''))
                            forvalues _high = 2/`threshnum' {
                                if `_high'==`threshnum' {
                                    local _low = `_high'-1
                                    qui replace ``z'value`X'' = ``z'value`X'' + `_high'*(1-(exp(mu`_low'`X'-``z'pred`X'')/(1+exp(mu`_low'`X'-``z'pred`X'')))) 
                                }
                                else if `_high'<`threshnum' {
                                    local _low = `_high'-1
                                    qui replace ``z'value`X'' = ``z'value`X'' + `_high'*((exp(mu`_high'`X'-``z'pred`X'')/(1+exp(mu`_high'`X'-``z'pred`X''))) - (exp(mu`_low'`X'-``z'pred`X'')/(1+exp(mu`_low'`X'-``z'pred`X'')))) 
                                }
                            }
                        }                    
                    }
                    else if ("`regcmd'"=="oprobit") {
                        if `threshnum' == 1 {
                            qui gen double ``z'value`X'' = 1-normal(mu1`X'-``z'pred`X'')
                        }
                        else if `threshnum' > 1 {
                            qui gen double ``z'value`X'' = normal(mu1`X'-``z'pred`X'') - normal(-``z'pred`X'')
                            forvalues _high = 2/`threshnum' {
                                if `_high'==`threshnum' {
                                    local _low = `_high'-1
                                    qui replace ``z'value`X'' = ``z'value`X'' + `_high'*(1 - normal(mu`_low'`X'-``z'pred`X'')) 
                                }
                                else if `_high'<`threshnum' {
                                    local _low = `_high'-1
                                    qui replace ``z'value`X'' = ``z'value`X'' + `_high'*(normal(mu`_high'`X'-``z'pred`X'') - normal(mu`_low'`X'-``z'pred`X'')) 
                                }
                            }
                        }                    
                    }
                    else if ("`regcmd'"=="zip" | "`regcmd'"=="zinb") {
                        qui gen double ``z'value`X'' = exp(``z'pred`X'')*(1 - (exp(``z'pred2`X'') / (1 + exp(``z'pred2`X''))))
                    }
                }
            }
        }
    
        if `noout' == 0 {    
            foreach z in _ c_ {
                foreach X in A B AB BA {
                    qui su ``z'value`X'', meanonly
                    scalar ``z'expval`X'' = r(mean)
                    }
                }
            }
        else if `noout' == 1 {
            foreach X in A B AB BA {
                qui su `_value`X'', meanonly
                scalar `_expval`X'' = r(mean)
                }
            }
    }
    
    
    ereturn clear   // bootstrap without 'nodrop' possible (-> e(sample))

    
    
    //////////////////////////////////////////////////////////////////////
    // perform calculations with expected values and create nld returns //
    //////////////////////////////////////////////////////////////////////
    
    scalar `raw' =  `_expvalA' - `_expvalB'
    scalar nld_raw = `raw'
  
    
    * AB                                                          
    if "`threefold'" == "" {
        scalar nld_charAB  = `_expvalA' - `_expvalAB'
        scalar nld_pcharAB = (`_expvalA' - `_expvalAB') / `raw'
    }
    else {
        scalar nld_charAB  = `_expvalBA' - `_expvalB'
        scalar nld_pcharAB = (`_expvalBA' - `_expvalB') / `raw'
        scalar nld_intAB   = `_expvalA' - `_expvalBA' - `_expvalAB' + `_expvalB'
        scalar nld_pintAB  = (`_expvalA' - `_expvalBA' - `_expvalAB' + `_expvalB') / `raw'
    }
    scalar nld_coefAB      = `_expvalAB' - `_expvalB'
    scalar nld_pcoefAB     = (`_expvalAB' - `_expvalB') / `raw'
   
   
    * BA
    if "`threefold'" == "" {
        scalar nld_charBA  = `_expvalBA' - `_expvalB'
        scalar nld_pcharBA = (`_expvalBA' - `_expvalB') / `raw'
    }
    else {
        scalar nld_charBA  = `_expvalA' - `_expvalAB'
        scalar nld_pcharBA = (`_expvalA' - `_expvalAB') / `raw'
        scalar nld_intBA   = `_expvalAB' - `_expvalB' - `_expvalA' + `_expvalBA'
        scalar nld_pintBA  = (`_expvalAB' - `_expvalB' - `_expvalA' + `_expvalBA') / `raw'
    }
    scalar nld_coefBA      = `_expvalA' - `_expvalBA'
    scalar nld_pcoefBA     = (`_expvalA' - `_expvalBA') / `raw'
   
   
   
    if "`omega'" != "" {
        if `dimension' == 1 {
            scalar nld_wgt = `weight'
        }
        else {
            matrix nld_wgt = `W'
        }
        
        scalar nld_adv     = `_expvalA' - `c_expvalBA'
        scalar nld_disadv  = `c_expvalAB' - `_expvalB'  
        scalar nld_prod    = `c_expvalBA' - `c_expvalAB'
        scalar nld_padv    = (`_expvalA' - `c_expvalBA') / `raw'
        scalar nld_pdisadv = (`c_expvalAB' - `_expvalB') / `raw'
        scalar nld_pprod   = (`c_expvalBA' - `c_expvalAB') / `raw'
    }   
    
    
    
    global nld_regcmd `regcmd'
    
    * number of observations for a - defined only once 
    capture confirm scalar nld_obsA
    if _rc {
        scalar nld_obsA = `obsA'
    }
    
    * number of observations for b - defined only once 
    capture confirm scalar nld_obsB
    if _rc {
        scalar nld_obsB = `obsB'
    }
    
     
end

program define nld_progomega, rclass
    syntax, omega(string) dim1(string) dim2(string) 
    
    tempname inp W W_gamma
    
    * return weights for omega
    matrix input `inp' = (`omega')
    mat `W' = diag(`inp')
    local w = "`omega'"
    local dimw = colsof(`W')
    if `dimw' == 1 & `dimw' != `dim1' {
        mat `W' = I(`dim1')*`w'
    }    
    else if `dimw' > 1 & `dimw' != `dim1' {
        di as error "ERROR: wrong number of weights in omega()"
        error 99999
    }
    return matrix W = `W'
    
    * return weights for gamma
    if "`dim2'" != "0" {
            if `dimw' == 1 {
                mat `W_gamma' = I(`dim2')*`w'
            }
            else if `dimw' > 1 {
                mat `W_gamma' = I(`dim2')
            }
        return matrix W_gamma = `W_gamma'
    }

end

program define nld_parse_regcmd, rclass
    local before `0'
    local after  : subinstr local before "svy:" ""
    
    if "`before'" != "`after'" {
        return local svy = "svy:"
    }
    
    local regcmd: word 1 of `after'
    return local regcmd `regcmd'
    return local rest: subinstr local after "`regcmd'" ""

end

program nld_dcp_limits
    syntax, regcmd(string) ll(string) ul(string) [llimit(string)] [ulimit(string)]
    
    qui gen `ll' = .
    qui gen `ul' = .
    
    if "`regcmd'" == "intreg" {
    	if "`llimit'`ulimit'" == ".." {
		di as error "You have to specify ll() and/or ul() when working with intreg!"
		error 99999
	}
    	
    	if "`llimit'" != "." {
		qui replace `ll' = `llimit'
	}

	if "`ulimit'" != "." {
		qui replace `ul' = `ulimit'
	}
	
    }
    else if "`regcmd'" == "tobit" {
        foreach xx in ll ul {
	    capture confirm scalar e(`xx'opt)
	    if !_rc {
	    	qui replace ``xx'' = e(`xx'opt)
	    }
        }
    }
    else if "`regcmd'" == "truncreg" {
        foreach xx in ll ul {
            if "`e(`xx'opt)'" != "" {
                qui replace ``xx'' = `e(`xx'opt)'
            }
        }
    }
    
end

program nld_getcmd, rclass
    // "local cmds" holds all allowed commands
    #delimit ;
    local cmds
        regress
        tobit
        intreg
        truncreg
        poisson
        nbreg
        zip
        zinb
        ztp
        ztnb
        logit
        probit
        ologit
        oprobit
    ;
    #delimit cr

    * code which checks the given abbreviation
    args abbrev
    local abbrev = trim("`abbrev'")
    local length = length("`abbrev'")
    local matches = 0
    foreach cmd of local cmds {
        local abbrecmd = substr("`cmd'", 1, `length')
        if "`abbrecmd'" == "`abbrev'" {
            local unabbrecmd = "`cmd'"
            local ++matches
            if "`abbrecmd'" == "`cmd'" {
                // if abbrecmd == cmd -> cmd must be the right command!
                local matches = 1
                continue, break
            }
        }
    }
    if `matches' == 0 {
        di as error "<`abbrev'> is not supported!"
        error 9999
    }
    if `matches' == 1 {
        return local cmd = "`unabbrecmd'"
    }
    else if `matches' > 1 {
        di as error "The given abbreviation <`abbrev'> is ambiguous!"
        error 9999
    }

end

program define nld_parse_varlist, rclass
    args varlist model
    if "`model'" == "intreg" {
        local depvar1: word 1 of `varlist'
        local depvar2: word 2 of `varlist'
        local depvar `depvar1' `depvar2'
    }
    else {
        local depvar: word 1 of `varlist'
    }
    return local depvar "`depvar'"
    return local indvar: subinstr local varlist "`depvar' " ""

end

program define nld_create_bootstrap_nlds
    
    // scalars
    scalar nld_level  = e(level)
    scalar nld_N_reps = e(N_reps)
    
    
    // matrices
    tempname level N_reps  // scalars
    tempname mcoef mse mcin mcip mcib mresult // matrices
    
    matrix `mcoef'    = e(b)
    matrix `mse'      = e(se)
    matrix `mcin'     = e(ci_normal)
    matrix `mcip'     = e(ci_percentile)
    matrix `mcib'     = e(ci_bc)
                    
    local ncoefs: word count `0'
    matrix `mresult' = J(10,`ncoefs',.) 
    matrix rownames `mresult' = coef se z p cin_ll cin_ul cip_ll cip_ul cib_ll cib_ul
    matrix colnames `mresult' = `0'
    
    matrix `mresult'[1,1] = `mcoef'
    matrix `mresult'[2,1] = `mse'
    forval i = 1 / `ncoefs' {
        matrix `mresult'[3,`i'] = `mcoef'[1, `i']/`mse'[1, `i']
        matrix `mresult'[4,`i'] = 2*(1-normal(abs(`mresult'[3,`i'])))
    }
    matrix `mresult'[5,1] = `mcin'
    matrix `mresult'[7,1] = `mcip'
    matrix `mresult'[9,1] = `mcib'
            
    local n = 0
    foreach exp of local 0 {
        local ++n
        scalar nld_`exp' = `mcoef'[1,`n']
    }

    matrix nld_bootstrap = `mresult'
    
end

program define nld_setreturns, rclass
    syntax, [order]
        
    //////////////////////
    // get all (nld_*)s //
    //////////////////////
    local nld_scalars  : all scalars "nld_*"
    local nld_scalars  : subinstr local nld_scalars "nld_" "", all
    local nld_matrices : all matrices "nld_*"
    local nld_matrices : subinstr local nld_matrices "nld_" "", all
    local nld_globals  : all globals "nld_*"
    local nld_globals  : subinstr local nld_globals "nld_" "", all
    
    
    ////////////////////
    // order (nld_*)s //
    ////////////////////
    local return_order raw charAB coefAB intAB pcharAB pcoefAB pintAB charBA coefBA intBA pcharBA pcoefBA pintBA prod adv disadv pprod padv pdisadv obsA obsB N_reps level sigmaA sigmaB regcmd bootstrap wgt
    
    foreach return of local return_order {
        if `: list return in nld_scalars' {
            local ord_scalars `ord_scalars' `return'          //note: a possible bug requires a reverse order of the returns!
            local nld_scalars : list nld_scalars - return
        }
        else if `: list return in nld_matrices' {
            local ord_matrices `return' `ord_matrices'
            local nld_matrices : list nld_matrices - return
        }
        else if `: list return in nld_globals' {
            local ord_globals `return' `globals'
            local nld_globals : list nld_globals - return
        }
    }
    
    local scalars  `ord_scalars'  `nld_scalars'      //note: a possible bug requires a reverse order of the returns!
    local matrices `nld_matrices' `ord_matrices'
    local globals  `nld_globals'  `ord_globals'
    
    
    ////////////////////////////////
    // return (nld_*)s as returns //
    ////////////////////////////////
    
    return clear
    
    // scalars
    foreach scalar of local scalars {
        return scalar `scalar' = nld_`scalar'
        scalar drop nld_`scalar'
    }
    
    // matrices
    foreach matrix of local matrices {
        return matrix `matrix' = nld_`matrix'
    }
    
    // globals -> macros (locals)
    foreach global of local globals {
        return local `global' ${nld_`global'}
        global nld_`global'
    }
    
end


program define nld_output
    syntax, [bootstrap]
    
    if "`r(threefold)'" != "" {
    	local threefold threefold
    }
    
    if "`r(omega)'" != "" {
    	local omega omega
    }
    

    local col  = 13
    local hlen = 63
                        
                            
    local space  = "{dup 2: }"   // space between "|"-line and first number
    
        
    
    local header   = "`space'{ralign 9:Coef.}"
    if "`bootstrap'" == "" {
        local header = "`header'`space'{ralign 10:Percentage}"
    }
    else {
        local header = "`header'`space'{ralign 9:Std. Err.}`space'{ralign 7:z }`space'{ralign 5:P>|z|}`space'{ralign 23:[`r(level)'% Conf. Interval]}"
    }
    
    
    //
    //   Begin output
    //  
    
    di
    di as text "{col 52}{lalign 17:Number of obs (A)} = " as result %7.0g r(obsA)
    di as text "{col 52}{lalign 17:Number of obs (B)} = " as result %7.0g r(obsB)
    if "`bootstrap'" != "" {
        di as text "{col 52}{lalign 17:BS Replications} = " as result %7.0g r(N_reps)
    }
    di
    
    
    di as text "{hline `col'}{c -}{c TT}{hline `hlen'}"
    di as text "{ralign `col':Results} {c |}" "`header'" 
    
    foreach xx in AB BA {
        if "`xx'" == "AB" {
            local x = 1
        }
        else {
            local x = 0
        }
        
        di in text "{hline `col'}{c -}{c +}{hline `hlen'}"
        di as result "{lalign `col': Omega = `x'} " as text  "{c |}" 
        nld_outputline, coef(char`xx') begin("{ralign `col':Char} {c |}")  space(`space') `bootstrap'
        nld_outputline, coef(coef`xx') begin("{ralign `col':Coef} {c |}")  space(`space') `bootstrap'
        
        if "`threefold'" != "" {
            nld_outputline, coef(int`xx') begin("{ralign `col':Int} {c |}") space(`space') `bootstrap'
        }
    }
    
    if "`omega'" != "" {
        di as text  "{hline `col'}{c -}{c +}{hline `hlen'}"
        
        capture confirm scalar r(wgt)
        if !_rc {
            if r(wgt) < 0 {
                local wgt: di "Omega < 0"
            }
            else if r(wgt) > 1 {
                local wgt: di "Omega > 1"
            }
            else {
                local wgt: di "Omega = " %3.2f r(wgt)
            }
            
            di as result "{lalign `col': {stata return list wgt:`wgt'}} " as text  "{c |}" 
        
        }
        else {
            di as result "{lalign `col': {stata matrix list r(wgt):Omega = wgt}} " as text  "{c |}" 
        }
        
        nld_outputline, coef(prod)   begin("{ralign `col':Prod} {c |}")   space(`space') `bootstrap'
        nld_outputline, coef(adv)    begin("{ralign `col':Adv} {c |}")    space(`space') `bootstrap'
        nld_outputline, coef(disadv) begin("{ralign `col':Disadv} {c |}") space(`space') `bootstrap'
    }
    
    
    di as text "{hline `col'}{c -}{c +}{hline `hlen'}"
    nld_outputline, coef(raw)          begin("{ralign `col': Raw} {c |}") space(`space') `bootstrap'
    di as text "{hline `col'}{c -}{c BT}{hline `hlen'}"
    
end

program define nld_outputline
    syntax, begin(string) coef(string) space(string) [bootstrap]
    
    local fmt1     = "%9.0g"        // format of numbers
    local fmt2     = "%7.2f"        // format of numbers
    local fmt3     = "%5.3f"        // format of numbers
    
    di as text "`begin'`space'" _c
    
    if "`bootstrap'" == "" {
        di as result `fmt1' r(`coef') "`space'" as result `fmt1' r(`coef')/r(raw)*100 "%"
    }
    else {
        tempname output
        matrix `output' = r(bootstrap)
        matrix `output' = `output'[1..., "`coef'"]
        
        di as result `fmt1' `output'[1, 1] "`space'" _c
        di as result `fmt1' `output'[2, 1] "`space'" _c
        di as result `fmt2' `output'[3, 1] "`space'" _c
        di as result `fmt3' `output'[4, 1] "`space' `space'" _c
        di as result `fmt1' `output'[5, 1] "`space'"  _c
        di as result `fmt1' `output'[6, 1]
    }
        
end


program define nld_dropnlds
    local todrop: all globals "nld_*"
    foreach global of local todrop {
        global `global'
    }
        
    local todrop: all scalars "nld_*"
    capture scalar drop`todrop'
    
    local todrop: all matrices "nld_*"
    capture matrix drop`todrop'
end

