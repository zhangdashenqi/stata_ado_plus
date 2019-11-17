*! xtdcce2 1.32 - October 2017
*! author Jan Ditzen
*! www.jan.ditzen.net - j.ditzen@hw.ac.uk
*! see viewsource xtdcce2.ado for more info.
/*
This program estimates a dynamic common correlated effects model with or without pooled coefficients. The equation is (Eq. 48, Chudik, Pesaran 2015):

y(it) = c(i) + b1(i) y(i,t-1) +  b2(i) x(it) + b3(i) x(it-1) + sum(l=0,pT) bm(l,i) zm(t-l) + e(it)

b1(i) - b3(i) is a K vector of estimated coefficients. For each unit a seperate vector of coefficients is estimated. The constraint
b(i) = b, i.e. homogenous coefficients across groups, is possible.
pT is the number of lags.
zm(t-l) is the cross sectional average of the l-th lag of y and x. zm is partialled out and is the corresponding coefficient bm(l,i) , not estimated 
> and reported. 

In addition the estimator allows that any x(it) can be endogenous and instrumented by z(it), if exogenous_vars and endogenous_vars are defined. 
Endogenous variables (as well as exogenous) can be mean group and pooled. This function requires ivreg2.
Syntax:

xtdcce2 lhs rhs (endo = exo) [if/]  [in/] , [  [if/] [/in] , [ 
                        Pooled(varlist ts fv) CRosssectional(varlist ts fv)  lr(varlist ts fv)
                        cr_lags(string) cluster(string asis) lr_options(string) IVREG2options(string) 
                        POOLEDConstant REPORTConstant NOCONSTant full NOCROSSsectional nocd NOIsily trend POOLEDTrend fulliv post_full 
                        JACKknife RECursive fullsample  ]
                
        
where:
        lhs: dependent variable, time series operators allowed.
        rhs: independent variables , if crossectional is not defined, then the cross sectional averages of all variables in rhs are included.
                If crosssectional is defined, then the cross sectional averages in rhs are not included in the equation. Time series operators allowe
> d.
        endo: endogenous variables, time series operators allowed.
        exo: exogenous variables (instruments), time series operators allowed.

Options:
        Pooled(varlist ts): adds a pooled variable. For this variable the estimated coefficients are constrained to be equal across all units 
                (b(i) = b for all i). Time series operators allowed.
        CRosssectional(varlist): variables for which the cross sectional averages are included in the model. These are the xm(t) variables. 
                crosssectional, pooled and rhs can contain different variables. If not defined, all rhs variables are included as cross sectional
                averages. Time series operators allowed.
        lr: Variables to be included for long-run cointegration vector. Time series operators allowed.
        
        cr_lags(number): Adds lags of cross sectional averages. If not defined but crosssectional contains a variablelist, then no lags are added.
        lr_options: Options for Long Run coefficients. Options "nodivide" and "xtpmgnames" allowed. If set, then the coefficients are not divided by 
> the error correction speed of adjustment vector
        ivreg2options: further options relating to ivreg2. See ivreg2, options for more informations.
        cluster: clustered standard errors
        
        REPORTConstant: report constant
        POOLEDConstant: pooles constant
        NOCONnstant: suppresses a common intercept (b0) for all units.
        full: reports unit indiviual estimates.
        NOCROSSsectional: no cross sectional averages are added
        nocd: suppresses calculation of CD test statistic
        NOIsily: shows regression 
        trend: adds a linear trend
        POOLEDTrend: pools linear trend
        fulliv: post all ereturns form ivreg2
        
        jackknife: jackknife small time series sample  bias correction
        recursive: recursive mean small time series sample  bias correction
        
        post_full: posts b_full and V_full instead of b_p_mg V_p_mg
        
        fullsample: ignores touse but uses if/in

xtdcce2 stores the following in e():
scalars:
                  e(N) =  Number of Observations
                e(N_g) =  Number of Groups/Units
                  e(T) =  Time dimension
                                  e(K) =  Number of regressors (including partialled out)
                                 e(cd) =  CD Statistic
                                e(cdp) =  p-value of CD Statistic
                           e(df_m) =  model degrees of freedom
                            e(mss) =  model sum of squares
                                e(rss) =  residual sum of squares
                           e(df_r) =  residual degrees of freedom
                                 e(r2) =  R-squared
                           e(r2_a) =  adjusted R-squared
                                  e(F) =  F statistic
                           e(rmse) =  root mean squared error
                           e(ll)   = log likelihood
                e(N_partial)   = number of variables partialled out
                e(N_omitted)   = number of omitted variables
                e(N_pooled)        = number of pooled variables
                           e(minT) = minimum time dimension (unbalanced panel)
                           e(maxT) = maximum time dimension (unbalanced panel)
                           e(avgT) = average time dimension (unbalanced panel)
                    e(cr_lags) = number of lags of the cross sectional averages
macros:
               e(tvar) : time variable
              e(idvar) : unit variable
             e(depvar) : Name of dependent variable
                   e(indepvar) : Name of independent variables (mean group)
                    e(omitted) : Names of omitted Variables (variablename_id)
                        e(insts)   : Instruments
                        e(instd)   : Instrumented (RHS endogenous) variables
                                e(cmd) : command line
                  e(cmd_full)  : command line including options
                        e(pooled)  : Name of pooled variables
                        e(lr)      : long run variables
                        e(version) : version of xtdcce2
                        e(predict) : name of predict program
                        e(estat)   : name of estat program
matrices:
                  e(b) :  Vector of individual or mean group estimates, includes pooled variables
                  e(V) :  Variance/Covariance matrix of individual or mean group estimates and pooled variables
                         e(b_p_mg) :  Vector of mean group estimates, includes pooled variables
             e(V_p_mg) :  Variance/Covariance matrix of mean group estimates and pooled variables.
                         e(b_full) :  Vector of individual estimates, includes pooled variables
             e(V_full) :  Variance/Covariance matrix of individual estimates and pooled variables
functions:
             e(sample) : marks sample


References:
Chudik, Alexander; Pesaran, M. Hashem, 2015, "Large Panel Data Models with Cross-Sectional Dependence: A Survey", The Oxford Handbook Of Panel Data

Chudik, Alexander; Pesaran, M. Hashem, 2013, "Common Correlated Effects Estimation of Heterogeneous Dynamic Panel Data Models with Weakly Exogenous Regressors", CESifo Working Paper

Packages Required:
- ivreg2
- moremata

Changelog:
18.06.2015 Added lhs to variables which are cross sectioned 
19.06.2015 Added option CD for CD test (xtcd2 test required).	
		   Added pooled variables to cross section if not specified cr() not specified.
23.06.2015 Changed calculation of partialling out. Now a regression with cholsolve is performed.
		   Mata matrices are deleted
24.06.2015 - Pooled variables are now removed from rhs variables, thus pooled variables can appear in rhs as well
		   - long Variablenames (>24 characters are allowed)
		   - no output if pooled or mean group is empty.
		   - Corrected Error in number of periods
		   - Clustered SE work again
25.06.2015 - Added degrees of freedom
		   - Added option noi, which showes the regression
		   - Omitted Variables and their number saved in e()		   
01.12.2015 - added check if cce_lags > 0 and "local drop_before = (`=`tmin'-1*`tdelta'') + `cr_lags' * `tdelta'" when comuputing the number of lags		   
xx.12.2015 - added IV	
11.01.2016 - added e(cmd), fixed naming errors in macros for instruments and naming if varnames are too long, temp vars are removed	
18.01.2016 - naming of matrices correct (in case of endogenous regressors)
28.01.2016 - fixed errors if noconstant is not active and constant is pooled variable
05.02.2016 - fixed error if "if" is used; "if `touse' " was missing when sperate was used.
11.02.2016 - changed option CD into nocd
15.02.2016 - partial out on unit level
15.02.2016 - unbalanced panels: missing values are added for balanced panel
17-20.02.2016 	- long run effects included
21-22.02.2016 - ts added, all variables now in varlists
23.02.2016 - xtdcce_err program added
24.02.2016 - added trend
02.03.2016 - added xtpmg names option for lr_options
05.03.2016 - added post_full option
08.03.2016 - changed 	mata b[lr_index] = (b[lr_index] :/ lr_tmp) into mata b[lr_index] = -(b[lr_index] :/ lr_tmp)
07.04.2016 - check for moremata
29.05.2016 - partial out program added, option for reportconstant added
Up to 19.10.2016
		   - Added function selectindex if Stata Version < 13
		   - Syntax for IV now as for ivreg2
		   - Replaced Mata matrices with temporary names and matrices are deleted
		   - Revised error message if packages are missing.
		   - Added version
		   - Revised Output
		   - minor bug fixes
		   - factor variables support
Up to 28.11.2016
		   - included predict and estat function
14.12.2016 - fixed error in t-identifier in case of unbalanced panel 
		   - added temporary options; fd and demean option
04.01.2017 - residuals are calculated predict, avoids error with jackknife
09.01.2017 - implemented fullsample option
		   - fixed error in variance calculation if jackknife used
		   - cov/variance from m_reg symmetric
14.01.2017 - wrapper for selectindex
----------------------------------------xtdcce113
04.03.2017 - error in F-Test Spacing
----------------------------------------xtdcce2131
May 2017   - Major overhaul including program for individual and mean group estimation 
June 2017  - fixed errors in unbalanced panel
		   - Error in naming for LR b and V matrix when xtpmgnames used
		   - removed options: cluster (correct SE for pooled), noomit (not needed), post_full (default bi and Vi are given)
		   - replaced putmata and getmata with st_view and st_data. Only necessary for touse variable. Requires mm_which2 (xtdcce2 version).
		   - options changed fill into showindividual and fulliv into e_ivreg2 changed. 
05.07.2017 - added endogenous(), exogenous() and residual() for legacy	
----------------------------------------xtdcce2132	   
07.07.2017 - bug in max. number of groups fixed. 
18.07.2017 - bug if unbalanced panel and predict used fixed. Removed "tsfill".
20.07.2017 - fixed bug in predict command. replaced subinstr with subinword for var changes.
22.07.2017 - check for rank condition enabled
15.08.2017 - bug in xtdcce_m_meangroup fixed.
20.08.2017 - added option fast, does not calculate individual covariances.
20.09.2017 - bug if option showi used fixed. sd, sd_i, t and t_i now as row vectors.
10.10.2017 - bug if ecm mg, but rest of lr pooled. see lr_with_pooled_ecm file
		   - bug if pooled used, no F and R2 are shown.
*/
capture program drop xtdcce2
program define xtdcce2 , eclass sortpreserve
	** Stata Version check - version > 11.1 needed for putmata commands
	if `c(version)' < 11.1 {
		di in gr "xtdcce2 requires version 11.1 or higher."
		exit
	}
	version 11.1
	local xtdcce2_version = 1.32
	if replay() {
		syntax [, VERsion replay * ] 
		if "`version'" != "" {
			di in gr "`xtdcce2_version'"
			*ereturn clear
			ereturn local version `xtdcce2_version'
			exit
		}
	}
	
	else {
		syntax anything [if/] [in/] , [  /* 
			*/ Pooled(string) /*
			*/ lr(varlist ts fv) /*
			*/ CRosssectional(string) /*
			*/ NOCROSSsectional /*
			*/ cr_lags(string) /*
			*/ lr_options(string) /*
			*/ IVREG2options(string)  /*
			*/ POOLEDConstant /*
			*/ REPORTConstant /*
			*/ NOCONSTant /*
			*/ full /* keep for legacy, replaced by showindividual
			*/ SHOWIndividual /*
			*/ nocd /*
			*/ NOIsily /*
			*/ trend /*
			*/ POOLEDTrend /*
			*/ fulliv  /* keep for legacy, replaced by e_ivreg2
			*/ e_ivreg2 /*
			*/ JACKknife RECursive fullsample /*
			*/ ivslow  /*
			*/ fast /*
			For Legacy:
			*/ EXOgenous_vars(varlist ts fv) ENDOgenous_vars(varlist ts fv) RESiduals(string) /*
			Working options: */ xtdcceold ]
		
		tempvar id_t  esmpl Y_tilde idvar tvar
		
		local cmd_line xtdcce2 `0'
		* Legacy Locals
		if "`e_ivreg2'" != "" {
			local fulliv "fulliv"
		}
		if "`showindividual'" != "" {
			local full "full"
		}
		
		*Legacy for IV options and residuals
		if "`exogenous_vars'`endogenous_vars'" != "" {
			tokenize "`0'" , parse(",")
			while "`3'" != "" {
				gettoken next 3: 3
				if strmatch("`next'","*(`endogenous_vars')") == 0 & strmatch("`next'","*(`exogenous_vars')") == 0 {
					local op_woiv "`op_woiv' `next'"
				}			
			}
			noi disp as text "Options 'endogenous_vars' and 'exogenous_vars' not supported since version 1.2." , _continue
			noi disp as smcl "See {help xtdcce2:help xtdcce2}."
			noi disp as text "Please run instead:"
			noi disp in smcl " {stata xtdcce2 `anything' (`endogenous_vars' = `exogenous_vars') `if' `in', `op_woiv'}"
			exit			
		}
		if "`residuals'" != "" {
			local residuals_old `residuals'
		}
		
		* fast option
		if "`fast'" == "fast" {
			local fast = 1
		}
		
		*Check for moremata
		capture mata mm_nunique((10,1))
		if _rc != 0 {
		**check if moremata works!!
			xtdcce_err 3499  , msg("moremata not installed.") msg2("To update, from within Stata type ") msg_smcl("{stata ssc install moremata, replace :ssc install moremata, replace}"	)
		}
		qui{		
			tempname m_idt
			local mata_drop `m_idt'
			tsset
			local d_idvar  `r(panelvar)'
			local d_tvar  `r(timevar)'
			local d_balanced  `r(balanced)'
			egen `idvar' = group(`d_idvar')	
			egen `tvar' = group(`d_tvar')
			sort `idvar' `tvar'
			gen `id_t' = _n
			///putmata `m_idt' = `id_t' , replace
			*mata st_view(`id_t',.,"`id_t'")
			preserve
				tsset `idvar' `tvar'
				marksample touse
				***Assign lhs, rhs, exo and endo vars
				gettoken lhs 0 : anything
				while "`0'" != "" {
					gettoken next 0 : 0 , match(paren)
					if strmatch("`next'","*=*") == 1 {
						tokenize `next' , parse("*=*")
						local endogenous_vars `endogenous_vars' `1'
						local exogenous_vars `exogenous_vars' `3'
					}
					else {
						local rhs `rhs' `next'
					}
				}				
				* process pooled options
				if strmatch("`pooled'","*_all*") == 1 {
					local uniq  `rhs' `exogenous_vars' `endogenous_vars' `lr' 
					local pooled : list uniq uniq 
				}
				
				*process crosssectional options
				if "`crosssectional'`nocrosssectional'" == "" {
					xtdcce_err 198  , msg("option crosssectional() or nocrosssectional required")
				}
				else {
					if "`crosssectional'" == "" | strmatch("`crosssectional'","*_none*") == 1 {
						local nocrosssectional "nocrosssectional"
						local crosssectional ""
					}
					else if strmatch("`crosssectional'","*_all*") == 1 {
						local uniq `lhs' `rhs' `pooled' `exogenous_vars' `endogenous_vars' `lr' 
						local uniq = strlower("`uniq'")
						local crosssectional : list uniq uniq 
						noi disp "`crosssectional'"
					}
				}				
				
				*markout varlists not defined as varlist in syntax
				markout `touse' `lhs' `rhs' `exogenous_vars' `endogenous_vars' `crosssectional' `pooled'	

				**find ts operators
				*check if ts/fv vars 
				fvexpand `pooled' `crosssectional' `exogenous_vars' `endogenous_vars' `lr' `lhs' `rhs'
				if  "`r(fvops)'" == "true"  | "`r(tsops)'" == "true" {
					foreach  liste in pooled crosssectional exogenous_vars endogenous_vars lr lhs rhs {
						if "``liste''" != "" {
							**Expand list for all outcomes of ts and fv (fvexpand), then create tempvariables for these variables
							fvexpand ``liste''
							local stripped_name `r(varlist)'
							
							fvrevar `stripped_name'
							local l_tmp `r(varlist)'
							
							local changed_name : list l_tmp - `liste'
							local stripped_name : list stripped_name - l_tmp
							
							local `liste' `l_tmp'
							local change_list `change_list' `changed_name'						
							local old_list `old_list' `stripped_name'
						}
					}
				}
				recast double `lhs' `rhs' `crosssectional' `pooled' `exogenous_vars' `endogenous_vars' `lr'
			
				sort `idvar' `tvar'
				
				*Check for IV and if ivreg2 is installed
				if "`exogenous_vars'" != "" & "`endogenous_vars'" != "" {
					local IV = 1
					capture ivreg2, version
					if _rc != 0 {
						restore
						xtdcce_err 199 `d_idvar' `d_tvar' , msg("ivreg2 not installed.") msg2("To update, from within Stata type ")	msg_smcl("{stata ssc install ivreg2, replace :ssc install ivreg2, replace}"	)			
					}
				}
				else {
					local endogenous_vars ""
					local exogenous_vars ""
					local IV = 0
				}
				*Check for bias correction
				if "`jackknife'" == "jackknife" & "`recursive'" == "recursive" {
					restore
					xtdcce_err 184 `d_idvar' `d_tvar' , msg("options jackknife and recursive may not be combined.")	
				}
				
				*Check for clustered SE
				if "`cluster'" != "" {
					local cluster "cluster(`cluster')"
				}
						
				*Check for long run coefficients
				if "`lr'" == "" {
					local lr_options ""
				}				
				
				*Check for variablename length
				local i = 1
				local complist `rhs' `lhs' `pooled' `crosssectional' `exogenous_vars' `endogenous_vars' `lr'
				local complist : list uniq complist
				foreach var in `complist' {
					if length("`var'") > 24 {
						tempname short_`i'
						local change_list `change_list' `short_`i''
						local old_list `old_list' `var'
						rename `var' `short_`i''
						local lhs = subinword("`lhs'","`var'","`short_`i''",.)	
						local rhs = subinword("`rhs'","`var'","`short_`i''",.)
						local pooled = subinword("`pooled'","`var'","`short_`i''",.)
						local crosssectional = subinword("`crosssectional'","`var'","`short_`i''",.)
						local exogenous_vars = subinword("`exogenous_vars'","`var'","`short_`i''",.)
						local endogenous_vars = subinword("`endogenous_vars'","`var'","`short_`i''",.)
						local lr = subinword("`lr'","`lr'","`short_`i''",.)
						
						local i = `i' + 1
					}				
				}				
				
				*Remove pooled variables from rhs
				local rhs : list rhs - pooled
				local rhs : list rhs - endogenous_vars
				local rhs : list rhs - exogenous_vars
				
				*Identify LR not in pooled, endogenous or exogenous vars
				local lr_single: list lr - pooled
				local lr_single: list lr_single - rhs
				local lr_single: list lr_single - endogenous_vars
				local lr_single: list lr_single - exogenous_vars
				
				local rhs `rhs' `lr_single'
				
				local endo_pooled: list endogenous_vars & pooled
				local exo_pooled: list exogenous_vars & pooled
				
				local endogenous_vars : list endogenous_vars - endo_pooled
				local exogenous_vars : list exogenous_vars - exo_pooled
				
				local pooled: list pooled - endo_pooled
				local pooled: list pooled - exo_pooled
				
				**Recursive Mean adjustment - before constant and trends are added
				if "`recursive'" == "recursive" {
					tempvar s_mean
					gen double `s_mean' = .
					local r_varlist `lhs' `rhs' `pooled' `crosssectional' `endogenous_vars' `exogenous_vars' `endo_pooled' `exo_pooled'
					local r_varlist: list uniq r_varlist
					local r_varlist: list r_varlist - constant
					
					foreach var in `r_varlist' {
						by `idvar' (`tvar'), sort: replace `s_mean' = sum(`var'[_n-1]) / (_n-1) if `touse' & `var'[_n-1] != .
						replace `var' = `var' - `s_mean'
						replace `s_mean' = .						
					}					
					sort `idvar' `tvar'
					markout `touse' `lhs' `rhs' `pooled' `crosssectional' `endogenous_vars' `exogenous_vars' `endo_pooled' `exo_pooled'
				}				
				
				*Add trend
				if "`pooledtrend'" != "" | "`trend'" != "" {
					tempvar trendv
					sum `d_tvar'
					gen double `trendv' = `tvar'
					if "`pooledtrend'" == "" & "`trend'" != "" {
						local rhs `rhs' `trendv' 
					}
					else if "`pooledtrend'" != "" & "`trend'" == "" {
						local pooled `pooled' `trendv'
					}
					else {
						restore
						xtdcce_err 184 `d_idvar' `d_tvar' , msg("options trend and pooledtrend may not be combined.")	
					}
					local change_list `change_list' `trendv' 
					local old_list `old_list' trend
				}				
				
				/*
				Constant/Intercept block
				if reportconstant is switched on, constant will be reported, 
				otherwise it will be partialled out (if poolconstant not defined) 
				or all variables will be demeaned to remove homogenous constant
				 Types of constant: 
					0 no constant
					1 heterogenous & partialled out
					2 homogenous (pooled) & removed (set to zero) as it is zero (only in case of balanced panel)
					3 heterogenous & displayed
					4 homogenous & not displayed (calculated but supressed)
					5 homogenous & displayed
				*/
				if "`noconstant'" == "" {
					if "`reportconstant'" != "reportconstant" {
						if "`pooledconstant'" != "pooledconstant" {
							tempvar constant
							gen double `constant' = 1	
							local constant_type = 1
						}
						else if "`pooledconstant'" == "pooledconstant" {
							*Check if all vars are in crosssectional mean, if so, no constant needed
							local lhsrhs `lhs' `rhs' `pooled' `endogenous_vars' `endo_pooled' 
							local const_check : list lhsrhs - crosssectional
							if "`d_balanced'" == "strongly balanced" & "`rhs'`endogenous_vars'" == "" & "`const_check'" == "" {
								local constant_type = 2	
								local noconstant noconstant					
							}
							else {
								tempvar constant 
								gen double `constant' = 1
								local pooled `pooled' `constant'
								local constant_type = 4 
							}
						}
						local noconstant_reg noconstant
					}
					else if "`reportconstant'" == "reportconstant" {
						tempvar constant 
						gen double `constant' = 1
						local noconstant_reg noconstant
						if "`pooledconstant'" == "pooledconstant" {
							local pooled `pooled' `constant'
							local constant_type = 5
						}
						else if "`pooledconstant'" != "pooledconstant" {
							*constant not pooled
							local rhs `rhs' `constant'
							local constant_type = 3 
						}				
					}
				}
				else {
					local noconstant_reg noconstant
					local constant_type = 0
				}	
				
				if "`nocrosssectional'" == "nocrosssectional" {
					local crosssectional ""
					local cr_lags = 0
				}
				if "`crosssectional'" != "" & "`cr_lags'" == ""{
					local cr_lags = 0
				}
								
				*Check if number of variables exceeds number of observations
				local rhs_endo `rhs' `endogenous_vars' 
				local num_rhs : list sizeof rhs_endo
				local endo_tot `pooled' `endo_pooled' `exo_pooled'
				local num_pooled : list sizeof endo_tot
				local num_crosssectional : list sizeof crosssectional
				inspect `idvar' if `touse'
				local N = r(N)
				if `r(N_unique)' == . {
					tempvar N_gtmp N_gtmp2
					egen `N_gtmp' = tag(`idvar') if `touse'
					egen `N_gtmp2' = total(`N_gtmp') if `touse'
					sum `N_gtmp2' if `touse' , meanonly
					local N_g = r(mean)
					drop `N_gtmp' `N_gtmp2'
				}
				else {
					local N_g = r(N_unique)
				}
				local num_partialled_out = `N_g' * ((`cr_lags' + 1 *("`nocrosssectional'"=="") ) * (`num_crosssectional' ))
				local num_mg_regression = `num_pooled' + `N_g' * `num_rhs'
				local num_K = `num_pooled' +  `num_rhs'
				local K_total = `num_mg_regression' + `num_partialled_out'
				if `N' < `K_total' {
					restore
					xtdcce_err 2001 `d_idvar' `d_tvar' , msg("More variables (`K_total') than observations (`N').")
				}
							
				**Only working, for old results (<version 1.1)
				if "`xtdcceold'" == "xtdcceold" {
					if "`cr_lags'" > "0" {
						replace `touse' = 0 if `tvar' <= `cr_lags' 
					}
				}
				
				***Specify sample - if fullsample then ignore touse
				if "`fullsample'" != "" {
					local tousecr
					if "`if'" != "" {
						local tousecr "`tousecr' if `if'"
					}
					if "`in'" != "" {
						local tousecr "`tousecr' in `in'"
					}
				}
				else {
					local tousecr "if `touse'"
				}
				*noi disp "`crosssectional'"
				*make sure no double vars
				local crosssectional: list uniq crosssectional				
				*create CR Lags
				if "`crosssectional'" != "" {					
					tempvar cr_mean
					foreach var in `crosssectional' {
						by `tvar' , sort: egen double `cr_mean' = mean(`var')  `tousecr'
						forvalues lag=0(1)`cr_lags' {
							sort `idvar' `tvar'
							gen double L`lag'_m_`var' = L`lag'.`cr_mean'  if `touse'
							local clist1  `clist1'  L`lag'_m_`var' 
						}
						drop `cr_mean' 
					}
				}
				**Add constant if heterogenous to list with variable to partialled out
				if  "`constant_type'" == "1" {
					local clist1 `clist1' `constant'
					local crosssectional `crosssectional' `constant'
					local num_partialled_out = `num_partialled_out' + 1
				}

				local num_adjusted = `num_partialled_out' 
				*Restrict set and exclude variables with missings
				markout `touse' `lhs' `pooled' `rhs' `exogenous_vars' `endogenous_vars' `endo_pooled' `exo_pooled' 
				** Check for omitted variables
				local omitted `lhs' `rhs'  `pooled'  `endo_pooled' 
				_rmcoll `omitted' if `touse' , noconstant forcedrop
				local omitted_var `r(varlist)'
				local omitted : list omitted - omitted_var
				local omitted_N : list sizeof omitted
				
				local rhs : list rhs - omitted
				local pooled : list pooled - omitted
				local endo_pooled : list endo_pooled - omitted
			
	**********************************************************************************************************
	*******************************************  Partialling Out *********************************************
	**********************************************************************************************************
			local rank_cond = 0
			*only partial out if list with variables to partial out is not empty
			if "`clist1'" != "" {			
				tempvar touse_ctry
				tempname mrk
				local mata_drop `mata_drop' `mrk'
				gen double `touse_ctry' = 0
				sort `idvar' `tvar'	
				forvalues ctry = 1(1)`N_g' {
					replace `touse_ctry' =  1 if `touse'  & `ctry' == `idvar'
					mata xtdcce_m_partialout("`lhs' `pooled' `rhs' `exogenous_vars' `endogenous_vars' `endo_pooled' `exo_pooled'","`clist1'","`touse_ctry'",`mrk'=.)
					replace `touse_ctry' =  0
					*Check if X1X1 matrix is full rank
					mata st_local("rk",strofreal(`mrk'[1,1]))
					mata st_local("rkrow",strofreal(`mrk'[1,2]))
					if "`rk'" < "`rkrow'" {
					*	restore
					*	xtdcce_err 506 `d_idvar' `d_tvar' , msg("Rank condition on cross section means not satisfied.")
						local rank_cond = 1
						*disp "rank condition `rank_cond' - `rk' <? `rkrow'"
					}
				}
			}
	*************************************************************************************************************
	**************************************Regression*************************************************************
	*************************************************************************************************************
			** 	renew touse
			markout `touse' `rhs' `pooled' `endogenous_vars' `exogenous_vars'
			sort `idvar' `tvar'
			
			tempname cov_i sd_i t_i stats_i b_i
			
			tempvar residuals_var	 
			local residuals `residuals_var'
			
			
			if "`jackknife'" == "jackknife" {
				tempvar jack_indicator_a jack_indicator_b

				sum `tvar' if `touse'
				local jack_T = int(`r(max)' / 2)
				
				gen `jack_indicator_a' = `touse' * (`tvar' <= `jack_T')
				gen `jack_indicator_b' = `touse' * (`tvar' > `jack_T')
								
			}	
			
			*1 check if IV
			*2 run for IV and none IV 3 regressions: 
			*		i) all pooled, 
			*		ii) mix (as is), 
			*		iii) full mg
			*3 run program for mg calculation to correct b and V
			
			*** 1 - non IV case
			
			if `IV' == 0 {
				
				gen double `residuals' = 0
				
				*i) all pooled
				if "`pooled'" != "" & "`rhs'" == "" {
					tempname eb_pi
					mata xtdcce_m_reg("`lhs'","`touse'","`idvar'","`rhs' `pooled'","`lr'","`lr_options'",`num_adjusted',"`residuals'","`eb_pi'","`cov_i'","`sd_i'","`t_i'","`stats_i'","`jack_indicator_a' `jack_indicator_b'",`fast')
					matrix `b_i' = `eb_pi'
				}
				*ii) as is (inculdes all mg)
				if "`rhs'" != "" {
					tempname eb_asisi
					mata xtdcce_m_reg("`lhs' `rhs'","`touse'","`idvar'","`pooled'","`lr'","`lr_options'",`num_adjusted',"`residuals'","`eb_asisi'","`cov_i'","`sd_i'","`t_i'","`stats_i'","`jack_indicator_a' `jack_indicator_b'",`fast')
					matrix `b_i' = 	`eb_asisi'	
				}
				*iii) all MG (only needed if pooled var is used). If all MG not used. better speed option
				* Use fast option which does not calculate residuals, covariance and stats.
				if "`pooled'" != ""  {
					tempname eb_mgi cov_i_1_pooled stats_i_pooled
					mata xtdcce_m_reg("`lhs' `rhs' `pooled'","`touse'","`idvar'","","`lr'","`lr_options'",`num_adjusted',"`residuals'","`eb_mgi'","`cov_i_1_pooled'","`sd_i'","`t_i'","`stats_i_pooled'","`jack_indicator_a' `jack_indicator_b'",1)
				}
			}
			** 2 - IV case
			else if `IV' == 1 {

				tempname iv_stats iv_mg
				***seperate data
				xtdcce2_separate , rhs(`rhs') exogenous_vars(`exogenous_vars') endogenous_vars(`endogenous_vars') /*
						*/ touse(`touse') idvar(`idvar')		
				local exo_list  `r(exo_list)'
				local endo_list `r(endo_list)'
				local rhs_list `r(rhs_list)'
				
				
				*i) all pooled
				if "`rhs'" == "" & "`exogenous_vars'" == "" & "`endognous_vars'" == "" {
					tempname eb_pi
					`noisily' ivreg2 `lhs' `pooled' `rhs' (`endogenous_vars' `endo_pooled' = `exogenous_vars' `exo_pooled') if `touse' , /*
					*/ `cluster' `noconstant_reg' `ivdiag' `ivreg2options' sdofminus(`num_partialled_out') nocollin 
					matrix `eb_pi' = e(b)
					predict double `residuals' if `touse' , xb
										
					matrix `cov_i' = e(V)

					mata st_matrix("`sd_i'",sqrt(diagonal(st_matrix("`cov_i'"))))
					mata st_matrix("`t_i'",st_matrix("`eb_pi'")':/st_matrix("`sd_i'"))					
					
					** save stats
					_estimates hold `iv_stats'
					
					**jackknife
					if "`jackknife'" == "jackknife" {
						tempname ba bb
						tempvar xba xbb
						`noisily' ivreg2 `lhs' `pooled' `rhs' (`endogenous_vars' `endo_pooled' = `exogenous_vars' `exo_pooled') if `jack_indicator_a' , /*
						*/ `cluster' `noconstant_reg' `ivdiag' `ivreg2options' sdofminus(`num_partialled_out') nocollin 
						matrix `ba' = e(b)
						predict `xba' , xb
						
						`noisily' ivreg2 `lhs' `pooled' `rhs' (`endogenous_vars' `endo_pooled' = `exogenous_vars' `exo_pooled') if `jack_indicator_b' , /*
						*/ `cluster' `noconstant_reg' `ivdiag' `ivreg2options' sdofminus(`num_partialled_out') nocollin 
						matrix `bb' = e(b)
						predict `xbb' , xb	
						matrix `eb_pi' = 2*`eb_pi' - 0.5*(`bb' + `ba')

						*correct y_hat (called residual)
						replace `residuals' = 2*`residuals' - 0.5*(`xba' + `xbb')
					}
					matrix `b_i' = `eb_pi'
					replace `residuals' = `lhs' - `residuals'
				}
				*ii) as is
				if "`rhs'" != "" | "`exogenous_vars'" != "" | "`endognous_vars'" != ""{	
					tempname eb_asisi
					`noisily' ivreg2 `lhs' `pooled' `rhs_list' (`endo_list' `endo_pooled' = `exo_list' `exo_pooled') if `touse' , /*
					*/ `cluster' `noconstant_reg' `ivdiag' `ivreg2options' sdofminus(`num_partialled_out') nocollin 
					matrix `eb_asisi' = e(b)
					predict double `residuals' if `touse', xb
					
					
					matrix `cov_i' = e(V)
					mata st_matrix("`sd_i'",sqrt(diagonal(st_matrix("`cov_i'"))))
					mata st_matrix("`t_i'",st_matrix("`eb_asisi'")':/st_matrix("`sd_i'"))
					
					local tmp_col : colnames `cov_i'
					
					matrix rownames `sd_i' = `tmp_col'
					matrix rownames `t_i' = `tmp_col'
					
					** save stats
					capture _estimates drop `iv_stats'
					_estimates hold `iv_stats'
			
					**jackknife
					if "`jackknife'" == "jackknife" {
						tempname ba bb
						tempvar xba xbb
						`noisily' ivreg2 `lhs' `pooled' `rhs_list' (`endo_list' `endo_pooled' = `exo_list' `exo_pooled') if `jack_indicator_a' , /*
						*/ `cluster' `noconstant_reg' `ivdiag' `ivreg2options' sdofminus(`num_partialled_out') nocollin 
						matrix `ba' = e(b)
						predict double  `xba' , xb
						
						`noisily' ivreg2 `lhs' `pooled' `rhs_list' (`endo_list' `endo_pooled' = `exo_list' `exo_pooled') if `jack_indicator_b' , /*
						*/ `cluster' `noconstant_reg' `ivdiag' `ivreg2options' sdofminus(`num_partialled_out') nocollin 
						matrix `bb' = e(b)
						predict double  `xbb' , xb	
						
						matrix `eb_asisi' = 2*`eb_asisi' - 0.5*(`bb' + `ba')
						*correct y_hat (called residual)
						replace `residuals' = 2*`residuals' - 0.5*(`xba' + `xbb')
					}
					
					matrix `b_i' = 	`eb_asisi'			
					replace `residuals' = `lhs' - `residuals'	
				}
				*iii) all MG (only needed if pooled is used), no need for stats and residual
				if "`pooled'" != ""  | "`exo_pooled'" != "" | "`endo_pooled'" != ""  {					
					if "`ivslow'" == "ivslow" {
						xtdcce2_separate , rhs(`pooled') exogenous_vars(`exo_pooled') endogenous_vars(`endo_pooled') /*
							*/ touse(`touse') idvar(`idvar')					
						
						tempname eb_mgi iv_mg

						local rhs_tmp `r(rhs_list)'
						local exo_tmp `r(exo_list)'
						local endo_tmp `r(endo_list)'						
						
						
						local rhs_list2 `rhs_list' `rhs_tmp'
						local exo_list2 `exo_list' `exo_tmp'
						local endo_list2 `endo_list' `endo_tmp'
						
						`noisily' ivreg2 `lhs'  `rhs_list2' (`endo_list2'  = `exo_list2' ) if `touse' , /*
							*/ `cluster' `noconstant_reg' `ivdiag' `ivreg2options' sdofminus(`num_partialled_out') nocollin 
						
						matrix `eb_mgi'  = e(b)				
						
						** save stats
						capture _estimates drop `iv_mg'
						_estimates hold `iv_mg'		

			
						**jackknife
						if "`jackknife'" == "jackknife" {
							tempname ba bb
							`noisily' ivreg2 `lhs'  `rhs_list2' (`endo_list2'  = `exo_list2' )  if `jack_indicator_a' , /*
							*/ `cluster' `noconstant_reg' `ivdiag' `ivreg2options' sdofminus(`num_partialled_out') nocollin 
							matrix `ba' = e(b)
							`noisily' ivreg2 `lhs'  `rhs_list2' (`endo_list2'  = `exo_list2' )  if `jack_indicator_b' , /*
							*/ `cluster' `noconstant_reg' `ivdiag' `ivreg2options' sdofminus(`num_partialled_out') nocollin 
							matrix `bb' = e(b)

							matrix `eb_mgi' = 2*`eb_mgi' - 0.5*(`bb' + `ba')
						}
						drop `rhs_tmp' `exo_tmp' `endo_tmp'	
					}
					else {
						tempname eb_mgi  resid2 `cov_i1'
						
						mata xtdcce_m_reg("`lhs' `endogenous_vars' `endo_pooled' `rhs' `pooled'","`touse'","`idvar'","","`lr'","`lr_options'",`num_adjusted',"`resid2'","`eb_mgi'","`cov_i1'","`sd_i'","`t_i'","`stats_i'","`jack_indicator_a' `jack_indicator_b'",1,"`exogenous_vars' `exo_pooled' `rhs' `pooled'")
					}	
				}

				*claculate long run coefficients
				if "`lr'" != "" {
					*run over all three possibilities for coefficients
					foreach mat in eb_asisi eb_mgi eb_pi  {
						if "``mat''" != "" {
							tempname m_blr_names m_blr m_covlr
							*cov only needed for asisi and pooled case
							local ff = 1
							if "``mat''" == "eb_asisi" | "``mat''" == "eb_pi" {
								local ff = 0
							}
							mata `m_blr' = st_matrix("``mat''")
							mata `m_covlr' = st_matrix("`cov_i'")
							mata `m_blr_names' = st_matrixcolstripe("``mat''")[.,2]

							mata `m_blr' = xtdcce_m_lrcalc(`m_blr',`m_covlr',`m_blr_names',"`lr'","`lr_options'",`ff')	
							
							mata st_matrix("``mat''",`m_blr'[.,1]')
							mata st_matrixcolstripe("``mat''", (J(cols(`m_blr_names'),1,""),`m_blr_names'') )
							if `ff' == 0 {
								mata st_matrix("`cov_i'",`m_blr'[.,2..cols(`m_blr')])
								mata st_matrixcolstripe("`cov_i'", (J(cols(`m_blr_names'),1,""),`m_blr_names'') )
								mata st_matrixrowstripe("`cov_i'", (J(cols(`m_blr_names'),1,""),`m_blr_names'') )
							}
							mata mata drop `m_blr' `m_covlr	' `m_blr_names'				
						}
					}
				}
				*Creat Stats matrix
				tempname stats_i
				_estimates unhold `iv_stats'
				matrix `stats_i' = (e(rss),e(mss),e(yyc) , 0 , e(Fdf2), e(rmse) , e(F) , e(df_m) , `N_g' , e(N) , e(r2), e(r2_a) )
				**Save stats if full iv used
				if "`fulliv'" == "fulliv" {					
					foreach scal in N yy yyc rss mss df_m df_r r2u r2c r2 r2_a ll rankxx rankzz rankV ranks rmse F N_clust /*
						*/ N_clust1 N_clust2 bw lambda kclass full sargan sarganp sargandf j jp arubin /*
						*/ arubinp arubin_lin arubin_linp arubindf idstat idp iddf widstat arf arfp archi2 /*
						*/ archi2p ardf ardf_r redstat redp reddf cstat cstatp cstatdf cons center partialcons partial_ct {
							if "`e(`scal')'" != "" scalar ivreg2_`scal' = e(`scal')
					}
					foreach macr in cmd cmdline ivreg2cmd version model depvar instd insts inexog exexog collin dups ecollin clist redlist partial small wtype /*	
						*/ wexp clustvar vcetype kernel firsteqs rfeq sfirsteq predict {
							if "`e(`macr')'" != "" local ivreg2_`macr'  "`e(`macr')'"
					}
					foreach matr in S W first ccev dcef {
							if "`e(`matr')'" != "" matrix  ivreg2_`matr' = e(`matr') 
					}
				}
			}

			******************************Regression End************************************
			***CD Test			
			if "`cd'" == "" {	
				* noest because touse used --- ADD HERE DISTINCTION WHICH ERROR - IE if XTCD2 not found
				capture xtcd2 `residuals' if `touse', noest 
				if _rc != 0 {
					noi display as error "xtcd2 not installed" 
					local nocd nocd
					}
				else {
					tempname cds cdp
					scalar `cds' = r(CD)
					scalar `cdp' = r(p)
				}
			} 
			***MG program
			tempname b_mg cov sd t
			mata xtdcce_m_meangroup("`eb_asisi'","`eb_mgi'","`eb_pi'","`rhs' `endogenous_vars'","`pooled' `endo_pooled'","","`idvar'","`touse'","`b_mg'","`cov'","`sd'","`t'")
			
			*Change Names back (needed for ts vars)
			local i = 1
			foreach var in `change_list' {
				local old_name = word("`old_list'",`i')
				local rhs = subinstr("`rhs'","`var'","`old_name'",.)
				local rhs_list = subinstr("`rhs_list'","`var'","`old_name'",.)
				local pooled = subinstr("`pooled'","`var'","`old_name'",.)
				local crosssectional = subinstr("`crosssectional'","`var'","`old_name'",.)	
				local endogenous_vars = subinstr("`endogenous_vars'","`var'","`old_name'",.)
				local exogenous_vars = subinstr("`exogenous_vars'","`var'","`old_name'",.)
				local endo_list = subinstr("`endo_list'","`var'","`old_name'",.)
				local endo_pooled = subinstr("`endo_pooled'","`var'","`old_name'",.)
				local exo_pooled  = subinstr("`endo_pooled'","`var'","`old_name'",.)
				local omitted_var  = subinstr("`omitted_var'","`var'","`old_name'",.)
				*local b_v_names  = subinstr("`b_v_names'","`var'","`old_name'",.)
				local lr = subinstr("`lr'","`var'","`old_name'",.)
				local lhs = subinstr("`lhs'","`var'","`old_name'",.)
				local clist1 = subinstr("`clist1'","`var'","`old_name'",.)
				local i = `i' + 1
			}	
					
			*Rename constant in rhs and variable lists
			local rhs = subinstr("`rhs'","`constant'","_cons",.)
			local rhs_list = subinstr("`rhs_list'","`constant'","_cons",.)
			local pooled = subinstr("`pooled'","`constant'","_cons",.)
			local b_v_names  = subinstr("`b_v_names'","`constant'","_cons",.)
			local crosssectional = subinstr("`crosssectional'","`constant'","_cons",.) 
			local clist1 = subinstr("`clist1'","`constant'","_cons",.)
			
			
			*Change names back for b_mg cov sd t b_i cov_i sd_i and t_i
			foreach mat in `b_mg' `cov' `sd' `t'  {
				local tmp_row : rownames `mat'
				local tmp_col : colnames `mat'
				local i = 1
				foreach var in `change_list' { 
					local old_name = word("`old_list'",`i')
					local tmp_row = subinstr("`tmp_row'","`var'","`old_name'",.)
					local tmp_col = subinstr("`tmp_col'","`var'","`old_name'",.)
					local i = `i'+1
				}
				
				local tmp_row = subinstr("`tmp_row'","`constant'","_cons",.)
				local tmp_col = subinstr("`tmp_col'","`constant'","_cons",.)				
				
				matrix colnames `mat' = `tmp_col'
				matrix rownames `mat' = `tmp_row'
			}
			
			**seperate for unit specific matrices			
			foreach mat in `b_i' `cov_i' `sd_i' `t_i' {
				local tmp_row : rownames `mat'
				local tmp_col : colnames `mat'
				local i = 1
				foreach var in `change_list' { 					
					local old_name = word("`old_list'",`i')
					local tmp_row = subinstr("`tmp_row'","`var'","`old_name'",.)
					local tmp_col = subinstr("`tmp_col'","`var'","`old_name'",.)
					local i = `i'+1
				}
				local tmp_row = subinstr("`tmp_row'","`constant'","_cons",.)
				local tmp_col = subinstr("`tmp_col'","`constant'","_cons",.)

				matrix colnames `mat' = `tmp_col'
				matrix rownames `mat' = `tmp_row'
			}			
			local constant _cons
			
			**Remove omitted variables from variablelists
			foreach var in rhs rhs_list pooled endogenous_vars exogenous_vars endo_list endo_pooled exo_pooled lr {
				local `var' : list `var' - omitted		
			}		
			
			*Remove constant if type 4 from pooled list and matrices
			if "`constant_type'" == "4" {
				local pooled: list pooled - constant
			}	
			
			*Correct names if xtpmgnames option used
			if strmatch("`lr_options'","*xtpmg*") == 1 {
				gettoken lr_1 lr_rest : lr
				
				local lr = subinstr("`lr'","`lr_1'","ec",.)
				
				*change lists
				foreach liste in pooled endo_pooled  endogenous_vars rhs {
					local `liste' = subinstr("``liste''","`lr_1'","ec",.)
				}
				*change b_mg cov sd and t
				foreach mat in `b_mg' `cov'  `sd' `t' {
					local col_eq ""
					local row_eq ""
				
					local tmp_row : rownames `mat'
					local tmp_col : colnames `mat'
					
					local tmp_row = subinstr("`tmp_row'","`lr_1'","ec",.)
					local tmp_col = subinstr("`tmp_col'","`lr_1'","ec",.)
					
					matrix colnames `mat' = `tmp_col'
					matrix rownames `mat' = `tmp_row'
					
					*add rowcolumns only for cov
					if "`mat'" == "`cov'" | "`mat'" == "`sd'" {
						foreach row in `tmp_row' {
							if regexm("`lr_rest'",strtrim("`row'")) == 1 {
								local tmp "ec"
							}
							else {
								local tmp "SR"
							}
							local row_eq `row_eq' `tmp'
						}
					}
					foreach col in `tmp_col' {	
						if regexm("`lr_rest'",strtrim("`col'")) == 1 {
							local tmp "ec"
						}
						else {
							local tmp "SR"
						}
						local col_eq `col_eq' `tmp'
					}
					matrix coleq `mat' = `col_eq'
					matrix roweq `mat' = `row_eq'	
				}				
			}
	
			*Get Tmin, Tmax and Tmin in case of unbalanced dataset
			if "`d_balanced'" != "strongly balanced" {
				tempvar ts_stats
				by `touse' `idvar' , sort: gen `ts_stats' = _N 
				sum `ts_stats' if `touse'
				local minT = `r(min)'
				local maxT = `r(max)'
				local meanT = `r(mean)'
			}
			
			**put touse into mata to preserve it after restore
			mata st_view(`touse'=.,.,"`touse' `id_t'")	
			mata `touse'_s = `touse'			
		restore	
		**read back
		mata st_view(`touse'=.,.,"`id_t'")
		mata `touse'_s = `touse'_s[xtdcce2_mm_which2(`touse'_s[.,2],`touse',1),1]
		mata st_view(`touse',.,st_addvar("double","`touse'"))
		mata `touse'[.] = `touse'_s
		mata mata drop `touse' `touse'_s 
	****************************************************************************
	***********************************Return***********************************
	****************************************************************************
		qui tsset `d_idvar' `d_tvar'
		
		matrix b = `b_mg'
		matrix V = `cov'
		
		**load stats
		local i = 1
		foreach stat in SSR SSE SST S2 dfr rmse F K N_g N r2 r2_a{
			scalar `stat' = `stats_i'[1,`i']		
			local i = `i' + 1
		}
		return clear
		ereturn clear
		ereturn post b V , obs(`N') esample(`touse') depname(`lhs') 
		
		if `IV' == 1 {
			ereturn local insts "`exogenous_vars' `exo_pooled'"
			ereturn local instd "`endogenous_vars' `endo_pooled'"
			
			if "`fulliv'" == "fulliv" {
				foreach scal in N yy yyc rss mss df_m df_r r2u r2c r2 r2_a ll rankxx rankzz rankV ranks rmse F N_clust /*
					*/ N_clust1 N_clust2 bw lambda kclass full sargan sarganp sargandf j jp arubin /*
					*/ arubinp arubin_lin arubin_linp arubindf idstat idp iddf widstat arf arfp archi2 /*
					*/ archi2p ardf ardf_r redstat redp reddf cstat cstatp cstatdf cons center partialcons partial_ct {
						if "`ivreg2_`scal''" != "" ereturn scalar ivreg2_`scal' = `ivreg2_`scal''
				}
				foreach macr in cmd cmdline ivreg2cmd version model depvar instd insts inexog exexog collin dups ecollin clist redlist partial small wtype /*	
					*/ wexp clustvar vcetype kernel firsteqs rfeq sfirsteq predict{
					if "`ivreg2_`macr''" != "" 	ereturn local  ivreg2_`macr'  "`ivreg2_`macr''"
				}
				foreach matr in b V S W first ccev dcef {
					if "`ivreg2_`matr''" != "" matrix  ivreg2_`matr' = `ivreg2_`matr''
				}
			} 			
		}
		
		novarabbrev {		
			ereturn scalar N = N
			ereturn scalar N_g = N_g
			if "`d_balanced'" != "strongly balanced" {
				ereturn scalar Tmin = `minT'
				ereturn scalar Tmax = `maxT'
				ereturn scalar Tbar = `meanT'		
			}
			ereturn scalar T = e(N) / `N_g'
			ereturn scalar df_m = K
			ereturn scalar K_mg = K - `num_partialled_out'
			ereturn scalar K_partial = `num_partialled_out'
			ereturn scalar F = F
			ereturn scalar r2 = r2
			ereturn scalar r2_a = r2_a
			ereturn scalar rmse = rmse
			ereturn scalar df_r = dfr
			ereturn scalar rss = SSR
			ereturn scalar mss = SSE			
			ereturn scalar cr_lags = `cr_lags' 			
			ereturn local indepvar "`pooled' `rhs'"
			ereturn local idvar = "`d_idvar'"
			ereturn local tvar = "`d_tvar'"	
			
			ereturn local cmdline "`cmd_line'"
			ereturn local cmd "xtdcce2"								
			ereturn local predict "xtdcce2_p"
			ereturn local estat_cmd "xtdcce2_estat"

			if "`pooled'`endo_pooled'" != "" {
				ereturn local pooled "`pooled' `endo_pooled'"
				ereturn scalar K_pooled = `num_pooled'
			}
			if "`lr'" != "" {
				ereturn local lr "`lr'"
			}
			if "`omitted'" != "" {
				ereturn local omitted_var "`omitted_var'"
				ereturn scalar K_omitted = `omitted_N'
			}
			
			ereturn matrix bi = `b_i' , copy
			ereturn matrix Vi = `cov_i' , copy

			**Hidden returns for estat and predict
			ereturn hidden local p_mg_vars "`rhs' `endogenous_vars'"
			ereturn hidden local p_pooled_vars "`pooled' `endo_pooled'"
			ereturn hidden local p_cr_vars "`crosssectional'"
			ereturn hidden local p_lr_1 "`lr_1'"
			ereturn hidden local p_if "`if'"
			ereturn hidden local p_in "`in'"
			ereturn hidden scalar constant_type = `constant_type'

		}
		if "`cd'" == "" {
			ereturn scalar cd = `cds'
			ereturn scalar cdp = `cdp'
		}
		local pf = Ftail(e(df_m),e(df_r),e(F))
	**qui ends here!
	}
	****************************************************************************
	***********************************Output***********************************
	****************************************************************************
	if "`pooled'" != "" {
		local textpooled "Pooled "
	}
	if "`rhs'`endogenous_vars'" != "" {
		local textmg "Mean Group"
	}
	if `IV' == 1 {
		local textiv " IV"
	}
	display as text "(Dynamic) Common Correlated Effects Estimator - `textpooled'`textmg'`textiv'"
	#delimit ;
		di _n in gr "Panel Variable (i): " in ye e(idvar) 
				   _col(60) in gr "Number of obs" _col(79) "=" 
				   _col(81) in ye %9.0f e(N) ;
		di in gr "Time Variable (t): " in ye abbrev(e(tvar),12) in gr
					_col(60) "Number of groups" _col(79) "="
					_col(81) in ye %9.0g e(N_g) ;
	#delimit cr
	if "`d_balanced'" == "strongly balanced" {
		#delimit ;
			di in gr _col(60) in gr "Obs per group (T)" _col(79) "="
					_col(81) in ye %9.0f e(T) ;
		#delimit cr
	}
	else {	
		#delimit ;
			di "" ;
			di in gr _col(60) in gr "Obs per group:" _col(79) ;
			di in gr _col(75) in gr "min = "
					_col(81) in ye %9.0f e(Tmin) ;	
			di in gr _col(75) in gr "avg = " 
					_col(81) in ye %9.0f e(Tbar) ;	
			di in gr _col(75) in gr "max = " 
					_col(81) in ye %9.0f e(Tmax) ;
		#delimit cr	
	}
	#delimit ;
		di in gr "Degrees of freedom per country:" ;
		di in gr _col(2) "without cross-sectional averages"
					_col(38) "=" _col(41) e(T)-`num_pooled' - `num_rhs'
					_col(60) in gr "F(`e(df_m)', `e(df_r)')" _col(79) "="
					_col(81) in ye %9.2f e(F) ;
		di in gr _col(2) "with cross-sectional averages"
					_col(38) "=" _col(41) e(T)-`num_pooled' - `num_rhs' - (1+`cr_lags')*`num_crosssectional' - ((`constant_type'==1 | `constant_type' == 4))
					_col(60) in gr "Prob > F" _col(79) "="
					_col(81) in ye %9.2f `pf' ;
		di in gr "Number of "
					_col(60) in gr "R-squared" _col(79) "="
					_col(81) in ye %9.2f e(r2) ;
		di in gr _col(2) "cross sectional lags" 
					_col(38) "=" _col(41) "`cr_lags'"	
					_col(60) in gr "Adj. R-squared" _col(79) "="
					_col(81) in ye %9.2f e(r2_a) ;
		di in gr _col(2) "variables in mean group regression"
					_col(38) "=" _col(41) e(K_mg)
					_col(60) in gr "Root MSE" _col(79) "="
					_col(81) in ye %9.2f e(rmse) ;
		di in gr _col(2) "variables partialled out"
					_col(38) "=" _col(41)  "`num_partialled_out'";
	#delimit cr
	
	if "`omitted'" != "" {
		di in gr  _col(2) "omitted Variables:" _col(38) "=" _col(41) e(N_omitted)		
	}
	
	
	if "`cd'" == "" {
		#delimit ;
			di _col(60) in gr "CD Statistic" _col(79) "="
			   _col(81) in ye in ye %9.2f e(cd) ;
			di _col(60) in gr "   p-value" _col(79) "="
			   _col(81) in ye in ye %9.4f e(cdp) ;	
		#delimit cr
	
	}

	local level =  `c(level)'
	local col_i = 24
	
	di as text "{hline `col_i'}{c TT}{hline `=89-`col_i''}"
	di as text %`col_i's abbrev("`lhs'",`col_i') "{c |}" _c
	local col = `col_i' + 9
	di as text _col(`col') "Coef." _c
	local col = `col' + 8
	di as text _col(`col') "Std. Err."  _c
	local col = `col' + 15
	di as text _col(`col') "z"  _c
	local col = `col' + 5
	di as text _col(`col') "P>|z|"  _c
	local col = `col' + 10
	di as text _col(`col') "[`level'% Conf. Interval]"    

	di as text "{hline `col_i'}{c +}{hline `=89-`col_i''}"
	scalar cv = invnorm(1 - ((100-`level')/100)/2)
	if "`lr'" != "" {
		di "Short Run Estimates:" _col(`col_i') " {c |}" 
		di as text "{hline `col_i'}{c +}{hline `=89-`col_i''}"
		local sr_text "  "
	}
	
	local pooled_vars `pooled' `endo_pooled'
	local pooled_vars : list pooled_vars - lr
	if "`pooled_vars'" != "" { 
		di "`sr_text'Pooled Variables:" _col(`col_i') " {c |}" 
		foreach var in `pooled_vars' {
			xtdcce_output_table `var' `col_i' `b_mg' `sd' `t' cv `var'
		}
	}
	local rhs_vars `endogenous_vars' `rhs'
	local rhs_vars : list rhs_vars - lr
	if "`rhs_vars'" != ""   {
		di "`sr_text'Mean Group Estimates:" _col(`col_i') " {c |}"
		foreach var in `rhs_vars' {
			if "`full'" != "" {
				di "" _col(`col_i') " {c |}"
			}
			xtdcce_output_table `var' `col_i' `b_mg' `sd' `t' cv `var'
			if "`full'" != "" {
				di as text "`sr_text'`sr_text'Individual Results" _col(`col_i') " {c |}"
				forvalues j = 1(1)`N_g' {
					xtdcce_output_table `var'_`j' `col_i' `b_i' `sd_i' `t_i' cv `var'_`j'
				}
			}
		}
	}	
	if "`lr'" != "" {
		local lr_pooled : list lr & pooled
		local lr_rest : list lr - lr_pooled
		di as text "{hline `col_i'}{c +}{hline `=89-`col_i''}"
		di "Long Run Estimates:" _col(`col_i') " {c |}"
		di as text "{hline `col_i'}{c +}{hline `=89-`col_i''}"
		if "`lr_pooled'" != "" { 
			di "  Pooled Variables:" _col(`col_i') " {c |}" 
			foreach var in `lr_pooled' {
				xtdcce_output_table `var' `col_i' `b_mg' `sd' `t' cv `var'
			}
		}
		if "`lr_rest'" != ""   {
			di "  Mean Group Estimates:" _col(`col_i') " {c |}"
			foreach var in `lr_rest' {
				if "`full'" != "" {
					di "" _col(`col_i') " {c |}"
				}
				xtdcce_output_table `var' `col_i' `b_mg' `sd' `t' cv `var'
				if "`full'" != "" {
					di as text"  Individual Results" _col(`col_i') " {c |}"
					forvalues j = 1(1)`N_g' {
						xtdcce_output_table `var'_`j' `col_i' `b_i' `sd_i' `t_i' cv `var'_`j'
					}
					
				}
			}
		}
	}	
	
	di as text "{hline `col_i'}{c BT}{hline `=89-`col_i''}"
	if "`pooled'" != "" {
		display "Pooled Variables: `endo_pooled' `pooled'"
	}
	if "`rhs'" != "" {
		display "Mean Group Variables: `rhs'"
	}
	if "`crosssectional'" != "" {
		if "`constant_type'" == "2" | "`constant_type'" == "1" {
			local crosssectional_output : list crosssectional - constant
			if "`crosssectional_output'" != "" {
				display "Cross Sectional Averaged Variables: `crosssectional_output'"
			}
		}
		else {
			display "Cross Sectional Averaged Variables: `crosssectional'"
		}
	}
	if "`lr'" != "" {
		display "Long Run Variables: `lr'"
	}
	if `IV' == 1 {
		display "Endogenous Variables: `endo_pooled' `endogenous_vars'"
		display "Exogenous Variables: `exo_pooled' `exogenous_vars'"
	}
	
	if "`omitted'" != "" {
		display "Omitted Variables:"
		display _col(2) "`omitted'"
	}
	if "`constant_type'" == "1" {
		display "Heterogenous constant partialled out." , _c
	}
	if "`constant_type'" == "2" {
		display "Homogenous constant removed from model." , _c
	}
	if "`constant_type'" == "4" {
		display "Homogenous constant removed." , _c
	}
	if "`jackknife'" == "jackknife" {
		display "Jackknife bias correction used." , _c
		ereturn local bias_correction = "jackknife" 
	}
	if "`recursive'" == "recursive" {
		display "Recursive mean adjustment used to correct for small sample time series bias." , _c
		ereturn local bias_correction = "recursive mean correction" 
	}
	if `rank_cond' > 0 {
		display as error "Rank condition on matrix of cross product of cross sectional averages not satisfied! Only mean group estimates are consistent, unit specific estimates are inconsistent. See Chudik, Pesaran (2015, Journal of Econometrics), Assumption 6 and page 398." , _newline
	}
	capture mata mata drop `mata_drop' `cov_i1'

	if "`residuals_old'" != "" {
		predict `residuals_old' if e(sample) , residuals
		disp "", _newline
		disp "Option 'residuals()' not supported anymore. Residuals calculated using:" 
		disp in smcl "{stata predict `residuals_old' if e(sample) , residuals: predict `residuals_old' if e(sample) , residuals}"
	}
	}
end

capture program drop xtdcce_output_table
program define xtdcce_output_table
	syntax anything

	tokenize `anything'
	local var `1'
	local col =  `2'
	local b_p_mg `3'
	local se_p_mg `4'
	local t_p_mg `5' 
	local cv  `6'
	local i `7'

	di as text %`col's abbrev("`var'",`col')  "{c |}" as result _column(`=`col'+4') %8.7g `b_p_mg'[1,colnumb(`b_p_mg',"`i'")] _c
	local col = `col' + 16
	di as result _column(`col') %8.7g `se_p_mg'[1,colnumb(`se_p_mg',"`i'")] _continue
	local col = `col' + 11
	di as result _column(`col') %6.2f `t_p_mg'[1,colnumb(`t_p_mg',"`i'")] _continue
	scalar pval= 2*(1 - normal(abs(`t_p_mg'[1,colnumb(`t_p_mg',"`i'")])))
	local col = `col' + 9
	di as result _column(`col') %5.3f pval _continue
	local col = `col' + 10
	di as result _column(`col') %9.7g ( `b_p_mg'[1,colnumb(`b_p_mg',"`i'")] - `cv'*`se_p_mg'[1,colnumb(`se_p_mg',"`i'")]) _continue
	local col = `col' + 11
	di as result _column(`col') %9.7g ( `b_p_mg'[1,colnumb(`b_p_mg',"`i'")] + `cv'*`se_p_mg'[1,colnumb(`se_p_mg',"`i'")])
end


// Mata utility for sequential use of solvers
// Default is cholesky;
// if that fails, use QR;
// if overridden, use QR.
// By Mark Schaffer 2015
capture mata mata drop cholqrsolve()
mata:
	function cholqrsolve (  numeric matrix A,
							numeric matrix B,
						  | real scalar useqr)
	{
			if (args()==2) useqr = 0
			
			real matrix C

			if (!useqr) {
					C = cholsolve(A, B)
					if (C[1,1]==.) {
							C = qrsolve(A, B)
					}
			}
			else {
					C = qrsolve(A, B)
			}
			return(C)

	};
end


capture mata mata drop cholqrinv()
mata:
	function cholqrinv (  numeric matrix A,
						  | real scalar useqr)
	{
			if (args()==2) useqr = 0
			
			real matrix C

			if (!useqr) {
					C = cholinv(A)
					if (C[1,1]==.) {
							C = qrinv(A)
					}
			}
			else {
					C = qrinv(A)
			}
			return(C)

	};
end

***Point by point mata program
capture mata mata drop xtdcce_PointByPoint()
mata:
	function xtdcce_PointByPoint(real matrix nrows,
						   real matrix ncols,
						   real matrix expres,
						   real matrix XChange)
	{	
		p_ncols = ncols
		p_nrows = nrows
		p_expres = expres
		
		if (cols(p_ncols) == 1 & cols(p_nrows) > 1) p_ncols = J(1,cols(p_nrows),p_ncols)
		if (cols(p_ncols) > 1 & cols(p_nrows) == 1) p_nrows = J(1,cols(p_ncols),p_nrows)
		if (cols(expres) == 1 & rows(expres) == 1& cols(p_nrows) > 1 & cols(p_ncols) > 1) p_expres = J(1,cols(p_nrows),p_expres)
		for (i=1 ;i <=cols(p_ncols) ; i++) {
			XChange[p_nrows[i],p_ncols[i]] = p_expres[i]
		}
		return(XChange)
	}
end

**** Error program
capture program drop xtdcce_err
program define xtdcce_err
	syntax anything , msg(string) [msg2(string) msg_smcl(string)]
	tokenize `anything'
	local code `1'
	local idvar `2'
	local tvar `3'
	
	tsset `2' `3'
	di as error _n  "`msg'" 
	if "`msg2'" != "" {
		di as error  "`msg2'" _c
		di in smcl   "`msg_smcl'"
	}
	exit `code'
end


*** Partial Out Program
** quadcross automatically removes missing values and therefore only uses (and updates) entries without missing values
capture mata mata drop xtdcce_m_partialout()
mata:
	function xtdcce_m_partialout (  string scalar X2_n,
									string scalar X1_n, 
									string scalar touse,
									| real matrix rk)
	{
		"start partial out"
		real matrix X1
		real matrix X2
		real matrix to
		st_view(X2,.,tokens(X2_n),touse)
		st_view(X1,.,tokens(X1_n),touse)
		X1X1 = quadcross(X1,X1)
		X1X2 = quadcross(X1,X2)
		"x1x1 and x1x2 calculated"
		//Get Rank
		s = qrinv(X1X1,rk=.)		
		//output rank and then number of rows
		rk = (rk,rows(X1X1))
		X2[.,.] = (X2 - X1*cholqrsolve(X1X1,X1X2))
		"partial out done"
		"rank condition:"
		rk
	}
end
/*
Mata OLS Program
returns coefficient, error terms, covariance matrix, statistics
v3
includes
	- variance/covariance matrix estimation
	- statistics
	- long run estimation
	
	
order for stats:
SSR, SSE, SST, S2, dfr, rmse, F, K, N_g, N

*/
capture mata mata drop xtdcce_m_reg()
mata:
	function xtdcce_m_reg (  string scalar variablenames, ///variable names, first var independent, from second vars mean group
									string scalar touse,  ///touse
									string scalar id_var, /// idvar
									string scalar ccep,   ///names of pooled vars
									string scalar lr_vars , /// names of long run variables
									string scalar lr_options, /// lr options
									real scalar input_no_partial, /// number of partialled out variables
									string scalar e_output_name, ///name of error term
									string scalar output_eb, /// names of b matrix
									string scalar output_cov_name, /// name of covariance matrix
									string scalar output_sd_name, /// name of sd matrix
									string scalar output_t_name, /// name of t-sts
									string scalar output_stats_name, /// names of stats outpt	
									string scalar jackknife_names, ///name of jackknife touse
									|real scalar fast, /// if 1 then no cov and stats are calculated
									string scalar input_exo) /// name of exogenous vars 
	{
		lhs = tokens(variablenames)[1]
		mg_d = 0
		pooled_d = 0
		exo = 0
		fast = 0
		if (cols(tokens(variablenames)) > 1) {
			rhs = tokens(variablenames)[2..cols(tokens(variablenames))]
			mg_d = 1
		}
		if (cols(tokens(ccep)) > 0) {
			pooled = tokens(ccep)
			pooled_d = 1
		}

		if (args() == 16) {
			exo_vars = tokens(input_exo)
			if (cols(exo_vars) > 0 ) {
				exo = 1
				fast = 1
			}
		}
		else {
			input_exo = ""
		}
		
		
		if (args() == 15) {
			fast = 1
			/// dummy output_cov
			output_cov = .
		}

		id = st_data(.,id_var,touse)
		
		Y = st_data(.,lhs,touse)

		///pooled estimation only	
		if (pooled_d == 1 & mg_d == 0) {
			X = st_data(.,pooled,touse)
			X_p_X_p = quadcross(X,X)
			X_p_Y = quadcross(X,Y)
			XX_cov = X_p_X_p
			
			b_output = cholqrsolve(X_p_X_p,X_p_Y)	
			outputnames = pooled
		}

		if (mg_d == 1 ){
			outputnames = J(1,0,"")
			X_o = st_data(.,rhs,touse)
			b_output = J(0,1,.)
			XX_cov = J(0,0,.)
			///seperate data in block diagonal matrix
			i = 1
			if (exo == 0) {
				while (i <= rows(uniqrows(id))) {
					indic = (id :== i)
					tmp_x = select(X_o,indic)
					/// if mg only, do regression for each country seperately
					if (pooled_d == 0) {
						tmp_y = select(Y,indic)
						tmp_xx = quadcross(tmp_x,tmp_x)
						tmp_xy = quadcross(tmp_x,tmp_y)
						b_output = (b_output \ cholqrsolve(tmp_xx,tmp_xy))
						
						//for covariance
						if (fast == 0) {
							XX_cov = blockdiag(XX_cov,cholqrinv(tmp_xx))
						}
					}
					X = blockdiag(X,tmp_x)
					
					outputnames = (outputnames , (rhs:+"_":+strofreal(i)))
					i++
				}
				if (pooled_d == 1) {
					X = (X, st_data(.,pooled,touse))
					//outputnames_pooled = pooled
					(rows(X),cols(X))
					XX = quadcross(X,X)
					XY = quadcross(X,Y)
					b_output = cholqrsolve(XX,XY)	
					outputnames = (outputnames , pooled)				
					//for covariance
					if (fast == 0) {
						XX_cov = cholqrinv(XX)				
					}

				}
			}
			else {
				/// This is only the mg all case and no covariance etc. is calculated (also only fast case!)
				X_o = st_data(.,rhs,touse)
				Z_o = st_data(.,input_exo,touse)
				///check for overid case (more instruments than instrumented vars), if overid, use GMM estimator
				i = 1
				while (i <= rows(uniqrows(id))) {
					indic = (id :== i)
					
					tmp_x = select(X_o,indic)
					tmp_z = select(Z_o,indic)				
					tmp_y = select(Y,indic)
					
					if (cols(tmp_x) == cols(tmp_z)) {
						tmp_zx = quadcross(tmp_z,tmp_x)
						tmp_zy = quadcross(tmp_z,tmp_y)
						tmp_b = cholqrsolve(tmp_zx,tmp_zy)
					}
					else {
						tmp_zz = qrinv(quadcross(tmp_z,tmp_z))
						tmp_zx = quadcross(tmp_z,tmp_x)
						tmp_xz = quadcross(tmp_x,tmp_z)
						tmp_zy = quadcross(tmp_z,tmp_x)
						upper = tmp_xz*tmp_zz*tmp_zy
						lower = qrinv(tmp_xz*tmp_zz*tmp_zx)
						tmp_b = cholqrsolve(lower,upper)						
					}
					b_output = (b_output \ tmp_b )
					outputnames = (outputnames , (rhs:+"_":+strofreal(i)))
					i++
				}
			}
		}

		/// Jackknife
		if (cols(tokens(jackknife_names)) == 2) {
			jack_indic_a = tokens(jackknife_names)[1]
			jack_indic_b = tokens(jackknife_names)[2]
			input_exo
			b_a = xtdcce_m_reg(variablenames,jack_indic_a,id_var,ccep,"","",0,"e","eb","cov","sd","t","st","jack1",1,input_exo)

			b_b = xtdcce_m_reg(variablenames,jack_indic_b,id_var,ccep,"","",0,"e","eb","cov","sd","t","st","jack2",1,input_exo)
			b_output = 2:*b_output :- 0.5:*(b_a :+ b_b)

		}
				
		/// Return Part
		/// if jackknife nested, return b_output to mata, no other output needed
		if (cols(tokens(jackknife_names)) == 1) {
			return(b_output)
		}
		////no output needed if jackknife
		else {		
			K = rows(b_output) + input_no_partial
			N = rows(id)
			N_g = rows(uniqrows(id))
			/// check if fast option is used
			if (fast == 0) {
				if (missing(X) > 0) {
					_editmissing(X,0)
				}
				///Error Term
				Y_hat = X * b_output
				(rows(X),cols(X))
				(rows(b_output),cols(b_output))
				(rows(Y_hat),cols(Y_hat))
				(rows(Y),cols(Y))
				st_view(e_output=.,.,e_output_name,touse)
				e_output[.,1] = Y - Y_hat	
				/// variance/covariance matrix and stats	
				SSE = e_output' * e_output
				dfr = N - K
				s2 = SSE / dfr
				SST = sum((Y :- mean(Y)):^2)
				SSR = SST - SSE
				rmse = sqrt(s2)
				/// variance covariance matrix
				output_cov = XX_cov * s2
				
				// check if constant	
				has_c = 0
				r2 = SSR/(SSR+SSE)	
				
				if (sum((colsum(X):==rows(X)))) {
					has_c = 1	
                    r2 = 1 - SSR/(SSR+SSE)
				} 
				else {					
                        SSR = sum((Y_hat):^2)
                        r2 = SSR/(SSR+SSE)

				}
				r2_a = 1 - (1-r2) * (N - 1) / (N - K - 1)
				F = SSR/(K-has_c) / (SSE/(N-K))
				
			}

			tmp = xtdcce_m_lrcalc(b_output,output_cov,outputnames,lr_vars,lr_options,fast)
			b_output = tmp[.,1]
			output_cov = tmp[.,2..cols(tmp)] 			
			outputnames = (J(1,cols(outputnames),"") \ outputnames)'

			///Output Coefficient (as 1 x K)	
			output_eb
			st_matrix(output_eb,b_output')			
			st_matrixcolstripe(output_eb,outputnames)
			if (fast == 1) {

				output_cov = J(rows(outputnames),rows(outputnames),0)
				
				SD = sqrt(diagonal(output_cov))'	
				
				st_matrix(output_sd_name,SD)
				st_matrixcolstripe(output_sd_name,outputnames)

				t = SD:/b_output'			
				st_matrix(output_t_name,t)
				st_matrixcolstripe(output_t_name,outputnames)
				
				///output cov
				st_matrix(output_cov_name,output_cov)
				st_matrixcolstripe(output_cov_name,outputnames)
				st_matrixrowstripe(output_cov_name,outputnames) 
				
				///stats into matrix
				(K,N_g,N)
				stats = (0, 0, 0, 0, 0, 0,0, K, N_g,N,0,0)
				st_matrix(output_stats_name,stats)	
				
			}
			if (fast == 0) {				
				///SD and T-Stat
				SD = sqrt(diagonal(output_cov))'	
				st_matrix(output_sd_name,SD)
				st_matrixcolstripe(output_sd_name,outputnames)
				
				t = SD:/b_output'			
				st_matrix(output_t_name,t)
				st_matrixcolstripe(output_t_name,outputnames)
				
				///output cov
				st_matrix(output_cov_name,output_cov)
				st_matrixcolstripe(output_cov_name,outputnames)
				st_matrixrowstripe(output_cov_name,outputnames) 
				
				///stats into matrix
				stats = (SSR, SSE, SST, s2, dfr, rmse,F, K, N_g,N,r2,r2_a)
				st_matrix(output_stats_name,stats)	
		
			}		
		}
	}	
end

/*Mata MG program
1. select coefficients for MG 
2. calculate MG coefficients
3. build bi and b matrix
4. calculate Vi and V, correct if pooled
5. calculate sei and ti
6. Output b, V, sd and t directly into Stata with st_matrix and st_matrixrowstripe
*/

capture mata mata drop xtdcce_m_meangroup()
mata:
	function xtdcce_m_meangroup( ///
						string scalar b_asis_name , /// asis matrix name , matrix is 1xK
						string scalar b_mg_name , /// all mg matrix name, matrix is 1xK
						string scalar b_pooled_name, /// only pooled matrix name, matrix is 1xK
						string scalar input_mg_vnames, /// names of mean group variables 
						string scalar input_pooled_vnames, /// names of pooled
						string scalar weights, ///for later use
						string scalar idvar, /// name of id variable
						string scalar touse, /// name of touse variable
						///Output: post directly using st_matrix and st_matrixrowstripe
						string scalar output_eb,
						string scalar output_cov,
						string scalar output_sd,
						string scalar output_t)
						
	{
		id = st_data(.,idvar,touse) 
		N = (rows(uniqrows(id)))
	
		input_pooled_vnames = tokens(input_pooled_vnames)
		input_mg_vnames = tokens(input_mg_vnames)
		
		/// pooled only
		if (cols(input_pooled_vnames) > 0 & cols(input_mg_vnames) == 0 )  {
			bi = st_matrix(b_mg_name)
			bi_names =  st_matrixcolstripe(b_mg_name)
			bi_names = bi_names[.,2]
			v_names_mg= input_pooled_vnames
			
			bp = st_matrix(b_pooled_name)
			bp_names = st_matrixcolstripe(b_pooled_name)
			bp_names = bp_names[.,2]
			
			///v_names_bp_mg = input_pooled_vnames
			
			ind_pooled = 1		
		}
		/// mg only 
		else if (cols(input_mg_vnames) > 0 & cols(input_pooled_vnames) == 0) {
			bi = st_matrix(b_asis_name)
			bi_names =  st_matrixcolstripe(b_asis_name)
			bi_names = bi_names[.,2]
			v_names_mg = input_mg_vnames
			
			ind_pooled = -1
		}
		/// mixed 
		else if (cols(input_mg_vnames) > 0 & cols(input_pooled_vnames) > 0) {
			bi = st_matrix(b_asis_name)
			bi_names =  st_matrixcolstripe(b_asis_name)
			bi_names = bi_names[.,2]
			v_names_mg = input_mg_vnames			
			bp = bi
			bp_names = bi_names			
			bp_mg = st_matrix(b_mg_name)
			bp_mg_names =  st_matrixcolstripe(b_mg_name)
			bp_mg_names = bp_mg_names[.,2]
			v_names_bp_mg = input_pooled_vnames
			
			ind_pooled = 0
		}
		else {
			"error no case!!"
		}
		if (ind_pooled != -1 ) {
			i = 1
			b_pooled = J(1,0,.)
			while (i<= cols(input_pooled_vnames)) {
				b_pooled = (b_pooled,bp[1,xtdcce_m_selectindex(bp_names:==input_pooled_vnames[1,i])])
				i++
			}
		}
		//loop over cross sectional units and mg vars
		i = 1
		b_mg_w = J(cols(v_names_mg),N,0)
		while (i <= cols(v_names_mg)) {
			j = 1
			while (j <= N) {
				varn = v_names_mg[1,i]+"_"+strofreal(j)
				varn
				b_mg_w[i,j] = bi[1,xtdcce_m_selectindex(bi_names:==varn)]
				j++
			}
			i++
		}
		b_mg = mean(b_mg_w')		
		/// if pooled only then b_mg used for pooled
		b_1 = b_mg_w :- b_mg'
		b_1p = b_1
		/// loop over additional mg if mixed
		if (ind_pooled == 0) {
			i = 1
			b_mg_wmix = J(cols(v_names_bp_mg),N,0)
			while (i <= cols(v_names_bp_mg)) {
				j = 1
				while (j <= N) {
					varn = v_names_bp_mg[1,i]+"_"+strofreal(j)
					b_mg_wmix[i,j] = bp_mg[1,xtdcce_m_selectindex(bp_mg_names:==varn)]
					j++
				}
				i++
			}
			b_mg4p = mean(b_mg_wmix')
			
			///replace b_1p
			b_1p = b_mg_wmix :- b_mg4p'
		}
		///covariance for pooled vars
		if (ind_pooled != -1) {
			///construct R and PSI for Cov		
			X = st_data(.,input_pooled_vnames,touse)
			/// PSI is directly calculated in gauss
			PSI = J(rows(b_pooled),cols(b_pooled),0)
			/// R is Omega HS in gauss file
			R = J(rows(b_pooled),cols(b_pooled),0)		
			i = 1	
			/// w contains weights, w_s is the sum of the squares.
			w = J(N,1,1/N)
			w_s = sum(w:^2)
			while (i <= N) {			
					///weight	
					w_i = w[i]
					w_tilde = w_i :/ sqrt(1/N :* w_s)
					b_i1 = b_1p[.,i]
					indic = (id :== i)
					tmp_x = select(X,indic)
					tmptmp = quadcross(tmp_x,tmp_x):/ rows(tmp_x)
					///:/ rows(tmp_x)
					///tmptmp1 = cholqrinv(tmptmp)
					///eq. 68 Pesaran 2006
					PSI = PSI :+ w_i :* tmptmp
					/// eq. 26 from Pesaran, Tosetti (2011); no difference as long as weights 1/N
					///PSI = PSI :+ w_i :* tmptmp 
					///eq. 67 Pesaran 2006
					R = R :+ w_tilde:^2 :* tmptmp*b_i1*b_i1'*tmptmp
					"R done"
					i++
			}
			///divide by N-1
			R = R / (N - 1)
			PSI1 = cholqrinv(PSI)
			//// eq. 69 Pesaran 2006
			cov_p =  w_s :* PSI1 * R * PSI1
		}		
		///covariance for mg vars
		if (ind_pooled != 1) {
			///Divide by rows (N) as this is the variance of a sample mean (see Eberhardts xtmg for example), small sample adjustment (-1) done in quadvariance! 
			///Pesaran 2006, eq. (58) & Chudik Pesaran 2015, eq. (32)			
			w_i = 1
			cov_mg = quadvariance(b_1',w_i)/N
		}

		/// select output b and cov matrix
		/// mixed
		if (ind_pooled == -1) {
			output_b = b_mg
			cov = cov_mg
			output_names = input_mg_vnames
		}	
		/// pooled only
		else if (ind_pooled == 1) {
			output_b = b_pooled
			cov = cov_p
			output_names = input_pooled_vnames
		}
		/// mixed
		else if (ind_pooled == 0) {
			output_b = (b_mg,b_pooled)
			cov = blockdiag(cov_mg,cov_p)
			output_names = (input_mg_vnames,input_pooled_vnames)
			///"Mixed output"
		}	
		else {
			///"Error no b matrix output!"
		}

		///"here teo"
		/// t and sd_i
		sd = sqrt(diagonal(cov))
		t = output_b' :/ sd	
		
		///output
		st_matrix(output_eb,output_b)
		st_matrixcolstripe(output_eb,(J(cols(output_names),1,""),output_names'))

		///covariance
		st_matrix(output_cov,cov)
		st_matrixcolstripe(output_cov,(J(cols(output_names),1,""),output_names'))
		st_matrixrowstripe(output_cov,(J(cols(output_names),1,""),output_names'))
		
		///cov
		st_matrix(output_sd,sd')
		st_matrixcolstripe(output_sd,(J(cols(output_names),1,""),output_names'))
		
		st_matrix(output_t,t')
		st_matrixcolstripe(output_t,(J(cols(output_names),1,""),output_names'))
	}

end
**LR Computation program 
**program is called after IVreg2 or within xtdcce2_mreg program
capture mata mata drop xtdcce_m_lrcalc()
mata:
	function xtdcce_m_lrcalc( ///
								real matrix b_output , /// coefficients comes as Kx1
								real matrix output_cov , /// covariance
								string matrix outputnames , /// col/rownames
								string matrix lr_vars, /// lr variables
								string matrix lr_options, /// options
								real matrix fast) /// fast option
	{
		lr_vars = tokens(lr_vars)
		/// make sure b_output is Kx1 and outputnames is 1xK - required for later programs
		if (cols(b_output)>1) {
			b_output = b_output'
		}
		if (rows(outputnames) > 1 ) {
			outputnames = outputnames'
		}	
		
		if (cols(lr_vars)>1) {
			if (strmatch(lr_options,"*nodivide*") == 0) {			
				lr_1 = lr_vars[1]
				lr_rest = lr_vars[2..cols(lr_vars)]
				/// only +* to allow for pooled	
				m_lr_1_indic = strmatch(outputnames,lr_1+"*")	
				m_lr_1 = select(b_output,m_lr_1_indic')
				m_lr_1_index = xtdcce_m_selectindex(m_lr_1_indic)				
				m_lr_tmp = m_lr_1
				///b_output
				///outputnames
				m_g = I(rows(b_output))
				i=1
				while (i <= cols(lr_rest)) {
					/// only +* to allow for pooled					
					m_lr_indic = strmatch(outputnames,lr_rest[i]+"*") 
					m_lr_index = xtdcce_m_selectindex(m_lr_indic)
					///check if running lr variable is pooled, if so, then take mean of lr_1
					m_lr_tmp = m_lr_1
					if (fast == 0) {
						/// diagonal elements 
						m_g = xtdcce_PointByPoint(m_lr_index,m_lr_index, (1:/ m_lr_tmp),m_g)
						/// off diagonal elements
						m_g = xtdcce_PointByPoint(m_lr_index,m_lr_1_index, (- b_output[m_lr_index] :/ (m_lr_tmp:^2)), m_g)

					}
					if (sum(m_lr_indic) == 1 ) {
						m_lr_tmp = mean(m_lr_1)
					}
					b_output[m_lr_index] = -(b_output[m_lr_index] :/ m_lr_tmp)
					i++

				}
				if (fast == 0 ) {
					output_cov = m_g*output_cov*m_g'	
				}				
			}
		}
		if (fast == 1) {
			output_cov = J(rows(b_output),1,.)
		}
		(rows(b_output), cols(b_output))
		(rows(output_cov),cols(output_cov))
		return((b_output,output_cov))
	}
end




**Wrapper for selectindex, checks if version is smaller than 13, then runs code, otherwise uses mata function
capture mata mata drop xtdcce_m_selectindex()
mata: 
	function xtdcce_m_selectindex(a)
	{
		if (c("version") < 13) {
			row = rows(a)
			col = cols(a)
			if (row==1) {
				output = J(1,0,.)
				j = 1
				while (j<=col) {
					if (a[1,j] != 0) {
						output = (output , j)
					}
					j++
				}		
			}
			if (col==1) {
				output = J(0,1,.)
				j = 1
				while (j<=row) {
					if (a[j,1] != 0) {
						output = (output \ j)
					}
					j++
				}		
			}
		}
		else {
			output = selectindex(a)
		}
		return(output)
	}
end

capture program drop xtdcce2_separate
program define xtdcce2_separate , rclass
	syntax [anything] , [ ///
			rhs(string) ///
			exogenous_vars(string) ///
			endogenous_vars(string) ///
			touse(string) ///
			idvar(string) ]
			
			**empty output 
			local rhs_list ""
			local endo_list ""
			local exo_list ""
			
			foreach var in `rhs' {
				qui separate `var' if `touse' , by(`idvar') gen(`var'_)
				local rhs_list `rhs_list' `r(varlist)'
				recode `r(varlist)' (missing = 0) if `touse'	
			}		

			foreach var in `exogenous_vars' {
				qui separate `var' if `touse'  , by(`idvar') gen(`var'_)
				local exo_list `exo_list' `r(varlist)'
				recode `r(varlist)' (missing = 0) if `touse'	
			}
			local exo_list `exo_pooled'	 `exo_list' 
					
			foreach var in `endogenous_vars' {
				qui separate `var' if `touse' , by(`idvar') gen(`var'_)
				local endo_list `endo_list' `r(varlist)'
				recode `r(varlist)' (missing = 0) if `touse'	
			}
			
			return local exo_list `exo_list'
			return local endo_list `endo_list'
			return local rhs_list `rhs_list'

		
end

capture mata mata drop xtdcce2_mm_which2()
version 10
mata:
	function xtdcce2_mm_which2(source,search,|real scalar exact )
	{		
		sums = 0
		for (i=1;i<=length(search);i++) {
			sums = sums + sum(source:==search[i])
		}
		if (sums > 0) {
			real matrix output	
			output = J(0,1,.)
			if (args() == 2) {
				for (i=1; i<=length(search); i++) {
					output = (output \ (mm_which(source:==search[i])==J(0,1,.) ?  0 : mm_which(source:==search[i])))
				}
			}
			if (args() == 3) {

				if (eltype(search) == "string") {
					equals = J(0,1,"")
				}
				else {
					equals = J(0,1,.)
				}				
				
				if (exact == 1) {
					for (i=1; i<=length(search); i++) {
						mm_wh = mm_which(source:==search[i])
						if (sum(mm_wh)>0) {
							equals = (equals \ search[i])
							numb = rows(mm_which(equals:==search[i]))
							mm_wh = mm_wh[numb]
						}
						output = (output \ (mm_wh==J(0,1,.) ?  0 : mm_wh))
					}
				}
				if (exact == 0) {					
					for (i=1; i<=length(search); i++) {
						mm_wh = xtdcce2_mm_which2(equals,search[i])
						if (sum(mm_wh)==0) {
							equals = (equals \ search[i])
							output = (output \ (mm_which(source:==search[i])==J(0,1,.) ?  0 : mm_which(source:==search[i])))
						}
					}
					
				}
			}
		}
		else {
			output = 0
		}		
		return(output)		
	}
end
