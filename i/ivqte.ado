*! version 2.1.15  17feb2010  Markus Froelich and Blaise Melly
*2.0.1: add proportion of compliers, correct the function e(sample)
*2.0.2: regressors are always continuous, dummy and unordered when aai is selected.
*2.1.0: lambda=0 allowed, estimation of AAI has a new option vaai to select the method to estimate H(x)
*2.1.1: variance of FM estimator: estimation of the proportion of compliers by matching, estimation of the density tested
*2.1.2: option vaai suppressed
*2.1.3: more information is displayed, small correction by as_var1
*2.1.3: check that there is a treatment variable and that it is not linearly dependent with the other regressors
*2.1.4: replace the Kronecker product by a runningsum
*2.1.5: use of _caller()
*2.1.6: declaration of all variables in Mata
*2.1.7: provide more saved results
*2.1.8: infinite bandwidth is ".". No negative values are allowed
*2.1.9: replace is allowed for generate_w and generate_p
*2.1.10: change default for pbandwith, plambda, pkernel, vbandwidth, vlambda, vkernel
*2.1.11: warning when variables are trimmed
*2.1.12: non-binary treatments are allowed when quantile regression is estimated
*2.1.13: implement higher-order kernel functions
*2.1.14: allow for an instrument negatively correlated with the treatment. Correction of minor mistakes concerning the standard errors
*2.1.15: correction of a mistake when the option phat was used and the instrument was negatively correlated with the treatment

program ivqte, eclass
	version 9.2
	capt findfile lmoremata.mlib
	if _rc {
      	di as error "-moremata- is required; type {stata ssc install moremata}"
		error 499
	}
	capt findfile lkdens.mlib
	if _rc {
      	di as error "-kdens- is required; type {stata ssc install kdens}"
		error 499
	}
	syntax anything(name=0) [if] [in] [, Continuous(varlist) Dummy(varlist) Unordered(varlist) Kernel(string) Bandwidth(string) Lambda(real 1) Quantiles(numlist >0 <1 sort) LInear Positive PBandwidth(string) PLambda(string) PKernel(string) Variance VBandwidth(string) VLambda(string) VKernel(string) mata_opt aai generate_w(string) generate_p(string) what(varname) phat(varname) trim(real 0.001) LEvel(cilevel)] 
	if "`linear'"==""{
		local logit="logit"
	}
	if "`continuous'"!=""{
		unab continuous : `continuous'
	}
	if "`unordered'"!=""{
		unab unordered : `unordered'
	}
	if "`dummy'"!=""{
		unab dummy : `dummy'
	}
	gettoken dependent 0 : 0, parse("(")
	gettoken dependent regressor : dependent, parse(" ")
	capture confirm variable `regressor'
	if _rc!=0{
		local regressor ""
	}
	if "`regressor'"!="" & ("`continuous'"!="" | "`dummy'"!="" | "`ordered'"!=""){
		dis as error "The options continuous, dummy and ordered can be selected only when indepvarlist is empty."
		exit
	}
	gettoken weg 0 : 0, parse("(")
	gettoken 0 weg : 0, parse(")")
	gettoken weg empty : weg, parse(")")
	if "`empty'"!=""{
		dis as error "Syntax error: `empty' is not at the correct place."
		exit
	}
	gettoken treatment 0 : 0, parse("=")
	if "`treatment'"==""{
		dis as error "A treatment variable must be provided"
		exit
	}
	gettoken weg 0 : 0, parse("=")
	local instrument="`0'"
	marksample touse
	markout `touse' `dependent' `treatment' `instrument' `continuous' `dummy' `unordered' `phat' `what' `regressor'
	tempvar touse1
	quietly gen `touse1'=`touse'
	if "`what'"!=""{
		confirm numeric variable `what'
	}
	if "`phat'"!=""{
		confirm numeric variable `phat'
	}
	if "`generate_w'"!=""{
		tokenize "`generate_w'", parse(",")
		gettoken generate_w :1, parse("")
		capture confirm variable `generate_w', exact
		if _rc==0 & "`3'"!="replace"{
      		di as error "`generate_w' already exists"
			exit
		}
		else if _rc==0 & "`3'"=="replace"{
			quietly drop `generate_w'
		}
	}				
	if "`generate_p'"!=""{
		tokenize "`generate_p'", parse(",")
		gettoken generate_p :1, parse("")
		capture confirm variable `generate_p', exact
		if _rc==0 & "`3'"!="replace"{
      		di as error "`generate_p' already exists"
			exit
		}
		else if _rc==0 & "`3'"=="replace"{
			quietly drop `generate_p'
		}
	}
	if "`phat'"!=""{
		local phat1 "`phat'"
		local phat
		tempvar phat
		quietly generate `phat' = `phat1'
	}
	if "`instrument'"=="" & "`aai'"=="aai"{
		dis in red "An instrument must be provided when the option aai is activated."
		exit
	}
	if "`instrument'"==""{
		local instrument="`treatment'"
	}
	if _caller()<10 & "`mata_opt'"=="mata_opt" {
     		di as error "The option mata_opt can only be used with Stata 10 or newer."
		exit
	}
*check that there are one enodogen and one instrument
	tokenize `treatment'
	local treatment="`1'"
	if "`2'"!=""{
		di in red "Only one treatment variable may be specified"
		exit
	}
	tokenize `instrument'
	local instrument="`1'"
	if "`2'"!=""{
		di in red "Only one instrumental variable may be specified"
		exit
	}
	quietly summarize `touse'
	tempname quants results q1 q0 quantile_show temp1 var
	local obs=r(sum)
	local exogenous=("`treatment'"=="`instrument'")
	if "`variance'"=="variance" & `exogenous'==0 & "`aai'"=="" & "`regressor'"!=""{
		dis in green "There is no estimator of the asymptotic variance for this configuration."
		dis in green "Bootstrap the results or use the option aai."
	}
* check that there is no singularity within the continuous variables
	if "`continuous'"!=""{
		_rmcollright `continuous'
		local continuous "`r(varlist)'"
	}
* check that there is no singularity within the continuous variables
	if "`dummy'"!=""{
		_rmcollright `dummy'
		local dummy "`r(varlist)'"
	}
	if "`regressor'"!=""{
		_rmcollright `regressor'
		local regressor " `r(varlist)'"
		quietly _rmcollright `regressor' `treatment' 
		if "`r(dropped)'"!=""{
			di in red "The treatment is linearly dependent with the regressors."
			exit
		}
	}
	if "`unordered'"!=""{	
		foreach x in `unordered'{
			tempvar `x'
			quietly tabulate `x' if `touse', generate(``x'')
			local nc=r(r)
			forvalues i=2/`nc'{	
				local listu1 "`listu1' `x'`i'"
			}
			drop ``x'`index''1
			unab temp:``x'`index''*
			local listu "`listu' `temp'"
		}
	}
	if ("`dummy'"!="" & "`continuous'"!="") | ("`dummy'"!="" & "`unordered'"!="") | ("`continuous'"!="" & "`unordered'"!=""){
		quietly _rmcollright `dummy' `continuous' `listu' 
		if "`r(dropped)'"!=""{
			di in red "The covariates are multicollinear."
			exit
		}
	}
	if "`aai'"=="aai"{
		local regressor="`continuous' `dummy' `listu'"
	}
*check that treatment and instrument are binary 0 or 1
	quietly tab `treatment' if `touse'
	if r(r)!=2 & ("`regressor'"=="" | `exogenous'==0){
		di in red "The treatment variable, `treatment', is not binary"
		exit
	}
	quietly sum `treatment'  if `touse'
	if (r(min)!=0 | r(max)!=1) & ("`regressor'"=="" | `exogenous'==0){
		di in red "The treatment variable, `treatment', is not a 0/1 variable"
		exit
	}
	quietly tab `instrument'  if `touse'
	if r(r)!=2 & ("`regressor'"=="" | `exogenous'==0){
		di in red "The instrument, `instrument', is not binary"
		exit
	}
	quietly sum `instrument'  if `touse'
	if (r(min)!=0 | r(max)!=1) & ("`regressor'"=="" | `exogenous'==0){
		di in red "The instrument, `instrument', is not a 0/1 variable"
		exit
	}
*put the logit method in a scalar
	local logit=("`logit'"=="logit")
*put the logit method in a scalar
	local method=("`mata_opt'"=="")
*put the positive indicator in a scalar
	local pos=("`positive'"=="positive")
*if kernel is missing, set kernel to epan2
	if "`kernel'"==""{
		local kernel "epan2"
	} 
	if "`pkernel'"==""{
		local pkernel "`kernel'"
	} 
	if "`vkernel'"==""{
		local vkernel "`kernel'"
	} 
*put the quantiles in a matrix
	if "`quantiles'"==""{
		if "`regressor'"=="" & "`aai'"==""{
			local quantiles "0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9"
		}
		else{
			local quantiles "0.5"
		}
	}
	tokenize "`quantiles'", parse(" ")
	local i=1
	while "`1'" != "" {
		matrix `quants'=nullmat(`quants')\(`1')
		mac shift 
		local i=`i'+1
	}
	if `i'>2 & "`regressor'"!=""{
		di as error "Only one quantile may be specified if conditional QTE are estimated."
		exit
	}
*Bandwidth
	if "`bandwidth'"==""{
		local bandwidth=.
	}
	else{
		gettoken bandwidth : bandwidth
		if `bandwidth'<=0{
				di as error "Bandwidth must be strictly positive. A missing value is treated as an infinite value."
				error 499
			}
	}
	if "`pbandwidth'"==""{
		local pbandwidth=`bandwidth'
	}
	else{
		gettoken pbandwidth :pbandwidth
		if `pbandwidth'<=0{
				di as error "Pbandwidth must be strictly positive. A missing value is treated as an infinite value."
				error 499
			}
	}
	if "`vbandwidth'"==""{
		local vbandwidth=`bandwidth'
	}
	else{
		gettoken vbandwidth :vbandwidth
		if `vbandwidth'<=0{
				di as error "Vbandwidth must be strictly positive. A missing value is treated as an infinite value."
				error 499
			}
	}
*Lambda
	if "`plambda'"==""{
		local plambda=`lambda'
	}
	if "`vlambda'"==""{
		local vlambda=`lambda'
	}
	if `lambda'<0 | `lambda'>1 | `plambda'<0 | `plambda'>1 | `vlambda'<0 | `vlambda'>1{
		di as error "The options lambda, plambda and vlambda must be between 0 and 1"
		exit
	}
*Trimming
	if `trim'>=0.5 | `trim'<0{
		di as error "The option trim must be positive but strictly below 0.5."
		exit
	}
*Calculate the propensity score
	local continuous1 "`continuous'"
	if "`continuous'"==""{
		local continuous "empty"
	}
	local dummy1 "`dummy'"
	if "`dummy'"==""{
		local dummy "empty"
	}
	local unordered1 "`unordered'"
	local listu2 "`listu'"
	if "`unordered'"==""{
		local unordered "empty"
		local listu "empty"
	}
	if "`phat'"!="" local iphat "iphat"
	if "`phat'"=="" & "`what'"=="" & ("`regressor'"=="" | `exogenous'==0){
		tempname phat
		if (("`dummy1'"=="" & "`unordered1'"=="") | `lambda'==1) & ("`continuous1'"=="" | `bandwidth'==.){
			if `logit'==0{
				quietly regress `instrument' `dummy1' `continuous1' `listu2' if `touse'
				quietly predict `phat'
			}
			else{
				quietly logit `instrument' `dummy1' `continuous1' `listu2' if `touse'
				quietly predict `phat'
			}
		}
		if (("`dummy'"!="empty" | "`unordered'"!="empty") & `lambda'<1) | ("`continuous'"!="empty" & `bandwidth'<.){
			quietly generate `phat'=.
*call mata to estimate the propensity score by local linear regression
			if `logit'==0{
				mata: loclin("`instrument'","`continuous'","`dummy'","`unordered'","`listu'","`kernel'",`bandwidth',`lambda',"`touse'","`phat'")
			}
			else {
				if `method'==0{
					mata: loclog("`instrument'","`continuous'","`dummy'","`unordered'","`listu'","`kernel'",`bandwidth',`lambda',"`touse'","`phat'")
				}
				else {
					mata: loclog1("`instrument'","`continuous'","`dummy'","`unordered'","`listu'","`kernel'",`bandwidth',`lambda',"`touse'","`phat'")
				}
			}	
		}
		if "`generate_p'"!=""{
			quietly generate `generate_p'=`phat'
		}
	}
	if "`regressor'"!="" & `exogenous'==1{
		tempname phat
		generate `phat'=0.5
	}
*calculate the weights
	local instrumentname "`instrument'"
	if `exogenous'==0{
		tempvar new_instrument
		quietly gen `new_instrument'=`treatment'*(`instrument'-`phat')
		quietly sum `new_instrument' if `touse'
		if r(mean)<0{
			quietly replace `new_instrument'=1-`instrument'
			quietly replace `phat'=1-`phat'
			local instrument "`new_instrument'"
		}
	}
	quietly sum `touse' if (`phat'<`trim' | `phat'>(1-`trim')) & `touse'==1
	local trimmed=r(N)
	quietly replace `touse'=0 if `phat'<`trim'
	quietly replace `touse'=0 if `phat'>(1-`trim')
	if `trimmed'>0{
		local remaining=`obs'-`trimmed'
		dis in green `trimmed' " observations have been trimmed. " `remaining' " observations are left after trimming."
		if "`regressor'"==""{
			quietly _rmcollright `dependent' `treatment' if `touse'==1
		}
		else{
			quietly _rmcollright `dependent' `treatment' `regressor' if `touse'==1
		}
		if  "`r(dropped)'"!=""{
			dis in red "The regressors are multicolinear after trimming. Reduce the amount of trimming."
			exit
		}
	}
	if "`what'"==""{
		tempname what
		if "`regressor'"!="" & `exogenous'==1{
			generate `what'=1
		}
		if ("`regressor'"=="" | `exogenous'==0) & "`aai'"==""{
			quietly generate `what'=(`instrument'-`phat')/(`phat'*(1-`phat')) if `touse'
			quietly sum `what'
			quietly replace `what'=`what'-r(mean) if `touse'
			if "`positive'"=="positive" & `exogenous'==0{
				tempvar pos_w
				if `pbandwidth'==.{
					quietly regress `what' `dependent' if `treatment'==0 & `touse'==1
					quietly predict `pos_w' if e(sample)
					quietly regress `what' `dependent' if `treatment'==1 & `touse'==1
					tempvar temp
					quietly predict `temp' if e(sample)
					quietly replace `pos_w'=`temp' if e(sample)
	
				}
				else{
					quietly gen `pos_w'=.
					tempvar temp
					gen `temp'=`touse'*(1-`treatment')
					mata: loclin("`what'","`dependent'","empty","empty","empty","`pkernel'",`pbandwidth',1,"`temp'","`pos_w'")
					quietly replace `temp'=`touse'*`treatment'
					mata: loclin("`what'","`dependent'","empty","empty","empty","`pkernel'",`pbandwidth',1,"`temp'","`pos_w'")
				}
				quietly replace `what'=`pos_w'*(2*`treatment'-1)
			}
			if `exogenous'==1{
				quietly replace `what'=`what'*(2*`treatment'-1)
			}
		}
		else if "`regressor'"=="" | `exogenous'==0 {
			quietly generate `what'=1-`treatment'*(1-`instrument')/(1-`phat')-(1-`treatment')*`instrument'/`phat' if `touse'
			if `pbandwidth'==. & `plambda'==1{
				if "`dummy'"!="empty"{
					local globallist "`dummy'"
				}
				if "`continuous'"!="empty"{
					local globallist "`globallist' `continuous'"
				}
				if "`unordered'"!="empty"{
					local globallist "`globallist' `listu'"
				}
				quietly regress `what' `dependent' `globallist' if `treatment'==0 & `touse'==1
				tempvar temp
				quietly predict `temp' if e(sample)
				quietly replace `what'=`temp' if e(sample)
				drop `temp'
				tempvar temp
				quietly regress `what' `dependent' `globallist' if `treatment'==1 & `touse'==1
				quietly predict `temp' if e(sample)
				quietly replace `what'=`temp' if e(sample)	
			}
			else{
				tempvar temp
				if "`continuous'"!="empty"{
					gen `temp'=`touse'*(1-`treatment')
					mata: loclin("`what'","`dependent' `continuous'","`dummy'","`unordered'","`listu'","`pkernel'",`pbandwidth',`plambda',"`temp'","`what'")
					quietly replace `temp'=`touse'*`treatment'
					mata: loclin("`what'","`dependent' `continuous'","`dummy'","`unordered'","`listu'","`pkernel'",`pbandwidth',`plambda',"`temp'","`what'")
				}
				else{
					gen `temp'=`touse'*(1-`treatment')
					mata: loclin("`what'","`dependent'","`dummy'","`unordered'","`listu'","`pkernel'",`pbandwidth',`plambda',"`temp'","`what'")
					quietly replace `temp'=`touse'*`treatment'
					mata: loclin("`what'","`dependent'","`dummy'","`unordered'","`listu'","`pkernel'",`pbandwidth',`plambda',"`temp'","`what'")
				}
			}
		}
		if "`generate_w'"!=""{
			quietly generate `generate_w'=`what'
		}
	}
	else local iwhat "iwhat"
	if "`aai'"=="aai"{
		quietly replace `touse'=0 if `what'<0
		quietly _rmcollright `dependent' `treatment' `regressor' if `touse'==1
		if  "`r(dropped)'"!=""{
			dis in red "The regressors are multicolinear in the weighted sample."
			exit
		}
	}
*estimate the QTE
	mat `quantile_show'=.
	local nq=rowsof(`quants')
*if the option positive has not been activated, then the distribution function is estimated and then inverted in the mata function est_qte
	if "`positive'"=="" & `exogenous'==0 & "`aai'"=="" & "`regressor'"==""{
		mata: est_qte("`dependent'","`treatment'","`what'","`touse'","`quants'","`results'","`q1'","`q0'")
	}
*if the option positive has been selected, then weighted quantile regression can be used to calculate the results
	else if "`regressor'"=="" & "`aai'"==""{
		forvalues i=1/`nq'{
			local estq=`quants'[`i',1]
			quietly _qreg `dependent' `treatment' [aweight=`what'] if `touse' & `what'>0, quantile(`estq')
			matrix `temp1'=e(b)
			matrix `results'=nullmat(`results'),`temp1'[1,1]
			mat `q0'=nullmat(`q0'),`temp1'[1,2]
			mat `q1'=nullmat(`q1'),(`temp1'[1,2]+`temp1'[1,1])
		}
	}
	else{
		local estq=`quants'[1,1]
		quietly _qreg `dependent' `treatment' `regressor'  [aweight=`what'] if `touse', quantile(`estq')
		local pseudo_r2=1-r(sum_adev)/r(sum_rdev)
		matrix `results'=e(b)
		mat `quants'=`quants'[1,1]
		if "`aai'"=="aai" & "`listu1'"!=""{
			mat colname `results' = `treatment' `continuous1' `dummy1' `listu1' _cons
		}
	}
*give names to the colunm of results
	if "`regressor'"=="" & "`aai'"!="aai"{
		local temp=rowsof(`quants')
		forvalues i = 1/`temp'{
			local names "`names' Quantile_`i'"
		}
		mat colnames `results'=`names'
	}
*post results
* if required: estimate variance and post it, too
	if "`variance'"!="" & "`phat'"!="" & ("`aai'"!="" | `exogenous'==1 | "`regressor'"==""){
		if "`aai'"==""{
			if "`regressor'"==""{
				if `exogenous'==0{
					mata: as_var(`logit', `pos',`method',"`q1'","`q0'", "`quants'","`dependent'", "`treatment'","`instrument'", "`continuous'","`dummy'","`unordered'","`listu'","`what'","`phat'","`vkernel'",`vbandwidth',`vlambda',"`touse'","`var'")
				}
				else{
					mata: as_var1(`logit', `method', "`q1'", "`q0'", "`quants'", "`dependent'", "`treatment'", "`continuous'", "`dummy'", "`unordered'", "`listu'", "`what'", "`phat'", "`vkernel'", `vbandwidth', `vlambda', "`touse'", "`var'")
				}
				mat colnames `var'=`names'
				mat rownames `var'=`names'
			}
			else{
				mata: as_var3("`results'", "`quants'", "`dependent'", "`treatment' `regressor'", "`what'", "`touse'", "`var'", 1-0.01*`level')
				local names : colnames `results'
				mat rownames `var'=`names'
				mat colnames `var'=`names'
			}
		}
		else{
			mata: as_var2("`results'", "`quants'", "`dependent'", "`treatment'", "`instrument'", "`regressor'", "`continuous'", "`dummy'", "`unordered'", "`listu'", "`what'", "`phat'", "`touse'", "`var'","`vkernel'",`vbandwidth',`vlambda')
			local names : colnames `results'
			mat rownames `var'=`names'
			mat colnames `var'=`names'
		}
		ereturn post `results' `var', esample(`touse1')  dep("`dependent'") obs(`obs')
	} 
	else{
		if "`variance'"!="" & "`phat'"=="" & ("`aai'"!="" | `exogenous'==1 | "`regressor'"==""){
			display in red "The variance cannot be estimated when the option phat is not specified."
			local variance ""
		}
		ereturn post `results', esample(`touse1') dep("`dependent'") obs(`obs')
	}
	mat `quants'=`quants''
	ereturn matrix quantiles=`quants'
	ereturn local command "ivqte"
	ereturn local depvar "`dependent'"
	ereturn local treatment "`treatment'"
	if `exogenous'==0{
		ereturn local instrument "`instrumentname'"
	}
	ereturn local continuous "`continuous'"
	ereturn local dummy "`dummy'"
	ereturn local unordered "`unordered'"
	ereturn local regressors "`regressor'" 
	if "`trimmed'"!=""{
		ereturn scalar trimmed=`trimmed'
	}
	if `exogenous'==0 | "`regressor'"==""{
		ereturn scalar bandwidth=`bandwidth'
		ereturn scalar lambda=`lambda'
		ereturn local kernel="`kernel'"
		if "`variance'"!=""{
			ereturn scalar vbandwidth=`vbandwidth'
			ereturn scalar vlambda=`vlambda'
			ereturn local vkernel="`vkernel'"
		}
		if "`linear'"==""{
			ereturn local ps_method "Local logit regression"
			if "`mata_opt'"==""{
				ereturn local optimization "Simple Gauss-Newton algorithm"
			}
			else{
				ereturn local optimization "Official Mata optimizer optimize"
			}
		}
		else {
			ereturn local ps_method "Local linear regression"
		}
	}
	if "`aai'"=="aai" | "`positive'"=="positive"{
		ereturn scalar pbandwidth=`pbandwidth'
		ereturn scalar plambda=`plambda'
		ereturn local pkernel="`pkernel'"
	}
*display results
	dis
	tempname temp1 tempsca tempsca2
	mat `temp1'=e(quantiles)
	if "`regressor'"!=""{
		sca `tempsca'=`temp1'[1,1]
		sca `tempsca2'=round(`tempsca',0.001)
		local qu=string(`tempsca2')
	}
	else{
		tempname temp1 tempsca tempsca2
		mat `temp1'=e(quantiles)
		forvalues i=1/`nq'{
			sca `tempsca'=`temp1'[1,`i']
			sca `tempsca2'=round(`tempsca',0.001)
			if `i'==1{
				local qu=string(`tempsca2')
			}
			else{
				local qu="`qu' " + string(`tempsca2')
			}
		}
	}
	if `exogenous'==1 & "`regressor'"!=""{
		dis in green "Quantile regression"
		dis "Estimator suggested in Koenker and Bassett (1978)"
		ereturn local estimator "Koenker and Bassett(1978)"
		ereturn scalar pseudo_r2=`pseudo_r2'
		dis
		dis "Quantile:" _column(30) "`qu'"
		dis "Dependent variable:" _column(30) "`dependent'"
		if "`aai'"==""{
			dis "Regressor(s):" _column(30) "`treatment'`regressor'"
		}
		else{
			dis "Control variable(s):" _column(30) "`continuous1' `dummy1' `unordered1'"
		}
		dis "Number of observations:" _column(30)  "`obs'"
	}
	if `exogenous'==1 & "`regressor'"==""{
		dis in green "Unconditional Quantile Treatment Effects under exogeneity"
		dis in green "Estimator suggested in Firpo (2007)"
		ereturn local estimator "Firpo (2007)"
		dis
		dis "Quantile(s):" _column(30) "`qu'"
		dis "Dependent variable:" _column(30) "`dependent'"
		dis "Treatment variable:" _column(30) "`treatment'"
		dis "Control variable(s):" _column(30) "`continuous1' `dummy1' `unordered1'"
		dis "Number of observations:" _column(30)  "`obs'"
	}
	if `exogenous'==0 & "`aai'"=="aai"{
		dis in green "IV quantile regression"
		dis in green "Estimator suggested in Abadie, Angrist and Imbens (2002)"
		ereturn local estimator "Abadie, Angrist and Imbens (2002)"
		dis
		dis "Quantile(s):" _column(30) "`qu'"
		dis "Dependent variable:" _column(30) "`dependent'"
		dis "Treatment variable:" _column(30) "`treatment'"
		dis "Instrumental variable:" _column(30) "`instrumentname'"
		dis "Control variable(s):" _column(30) "`continuous1' `dummy1' `unordered1'"
		dis "Number of observations:" _column(30)  "`obs'"
		quietly sum `what' if e(sample)
		local pc=round(r(mean),0.001)
		dis "Proportion of compliers:" _column(30) "`pc'"
		ereturn scalar compliers=`pc'
	}
	if `exogenous'==0 & "`aai'"==""{
		dis in green "Unconditional Quantile Treatment Effects under endogeneity"
		dis in green "Estimator suggested in Froelich and Melly (2008)"
		ereturn local estimator "Froelich and Melly (2008)"
		dis
		dis "Quantile(s):" _column(30) "`qu'"
		dis "Dependent variable:" _column(30) "`dependent'"
		dis "Treatment variable:" _column(30) "`treatment'"
		dis "Instrumental variable:" _column(30) "`instrumentname'"
		dis "Control variable(s):" _column(30) "`continuous1' `dummy1' `unordered1'"
		dis "Number of observations:" _column(30)  "`obs'"
		tempvar dwhat
		quietly generate `dwhat'=`what'*`treatment'
		quietly sum `dwhat' if e(sample)
		local pc=round(r(mean),0.001)
		dis "Proportion of compliers:" _column(30) "`pc'"
		ereturn scalar compliers=`pc'
	}
	dis
	if `exogenous'==0 | "`regressor'"==""{
		if `bandwidth'==.{
			local bandwidth "infinity"
		}
		if `pbandwidth'==.{
			local pbandwidth "infinity"
		}
		if `vbandwidth'==.{
			local vbandwidth "infinity"
		}
		if `logit'==1 & "`iphat'"==""{
			dis "Propensity score estimated by local logit regression with h = `bandwidth' and lambda = `lambda'"
		} 
		else if "`iphat'"==""{
			dis "Propensity score estimated by local linear regression with h = `bandwidth' and lambda = `lambda'"
		}
		else{
			dis "The propensity score has been provided by the variable `phat'"
		}
		if "`positive'"=="positive" & `exogenous'==0 & "`aai'"=="" & "`iwhat'"==""{
			dis "Positive weights estimated by local linear regression with h = `pbandwidth'"
		}
		if "`aai'"=="aai" & "`iwhat'"==""{
			dis "Positive weights estimated by local linear regression with h = `pbandwidth' and lambda = `plambda'"
		}
		if "`iwhat'"=="iwhat"{
			dis "The weights have been provided by the variable `what'"
		}
		if "`variance'"=="variance" & "`aai'"==""{
			if `logit'==1{
				dis "Variance estimated using local logit regression with h = `vbandwidth' and lambda = `vlambda'"
			}
			else{
				dis "Variance estimated using local linear regression with h = `vbandwidth'  and lambda = `vlambda'"
			}
		}
		if "`variance'"=="variance" & "`aai'"=="aai"{
				dis "Variance estimated using local linear regression with h = `vbandwidth' and lambda = `vlambda'"
		}
	}
	dis
	ereturn display, level(`level')
end

*Higher order kernels
mata real colvector fm_kern(string scalar name, real colvector u)
{
	if(name=="epanechnikov_o3" | name=="epanechnikov_o4"){
		w=(3/4):*(15/8:-7/8*5:*u:^2):*(1:-u:^2):*(u:^2:<1)
	} else if(name=="epanechnikov_o5" | name=="epanechnikov_o6"){ 
		w=(3/4):*(175/64:-105/32*5:*u:^2+231/320*25:*u:^4):*(1:-u:^2):*(u:^2:<1)
	} else if(name=="gaussian_o3" | name=="gaussian_o4"){
		w=(1/2):*(3:-u:^2):*normalden(u)
	} else if(name=="gaussian_o5" | name=="gaussian_o6"){
		w=(1/8):*(15:-10:*u:^2+u:^4):*normalden(u)
	} else if(name=="gaussian_o7" | name=="gaussian_o8"){
		w=(1/48):*(105:-105:*u:^2:+21:*u:^4-u:^6):*normalden(u)
	} else{
		w=mm_kern(name,u)
	}
	return(w)
}

*Mata function calculating mixed kernel and returning the regressors with a constant in the first column
version 9.2
mata void mkernel(real matrix regd, real matrix regc, real matrix regu, real rowvector ev, real rowvector evu, string scalar kernel, real scalar band, real scalar lambda, real scalar n, real scalar nd, real scalar nc, real scalar nu, real colvector w, real matrix reg)
{
//variable declarations
	real matrix regdt, regct, regut
	real scalar i
	if(nd+nu>0) regdt=regd:-ev[1..(nd+nu)] 
	else regdt=regd
	if(nc>0) regct=(regc:-ev[(nd+nu+1)..(nd+nu+nc)])
	else regct=regc
	if(nu>0) regut=regu:-evu
	else regut=regu
	w=J(n,1,1)
	if(nc>0 & band<.) for(i=1;i<=nc;i++) w=w:*fm_kern(kernel,regct[.,i]:/band)
	if((nd+nu)>0 & lambda<1) w=w:*(lambda:^((nd+nu):-rowsum(regdt:==0)))
	if(lambda==0){
		reg=select((J(n,1,1),regct),w)
	}
	else{
		if(nd>0) reg=select((J(n,1,1),regdt[.,1..nd],regut,regct),w)
		else reg=select((J(n,1,1),regut,regct),w)
	}
} 

*Mata function estimating the propensity score by local linear regression
version 9.2
mata void loclin(string scalar dep, string scalar continuous, string scalar dummy, string scalar unordered, string scalar unord_list, string scalar kernel, real scalar bandwidth, real scalar lambda, string scalar touse, string scalar out)
{
//Variable declarations
	real colvector y, pred, w, yt, wt
	real scalar n, nc, nd, nu, h1, l1, dettemp, i
	real matrix xc, xd, xur, xuk, reg
//read the data into Mata
	y=st_data(.,dep,touse)
	n=rows(y)
	if(continuous~="empty") {
		xc=st_data(.,tokens(continuous),touse)
		xc=xc*luinv(cholesky(variance(xc)))'
	}  
	else xc=J(n,0,0)
	if(dummy~="empty"){
		xd=st_data(.,tokens(dummy),touse) 
	}
	else xd=J(n,0,0)
	if(unordered~="empty"){
		xur=st_data(.,tokens(unord_list),touse)
		xuk=st_data(.,tokens(unordered),touse)	
	}
	else xur=xuk=J(n,0,0)	
	nc=cols(xc)
	nd=cols(xd)
	nu=cols(xuk)
	pred=J(n,1,.)
	for(i=1; i<=n; i++){
		h1=bandwidth
		l1=lambda
		mkernel((xd,xuk),xc,xur,(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n,nd,nc,nu,w=.,reg=.)
		dettemp=det(reg'reg)
		while(dettemp<1e-7 & h1<100 & h1>0){
			h1=h1*1.05
			mkernel((xd,xuk),xc,xur,(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n,nd,nc,nu,w=.,reg=.)
			dettemp=det(reg'reg)
		}
		if(dettemp<1e-7){
			h1=1e10
			l1=1
			mkernel((xd,xuk),xc,xur,(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n,nd,nc,nu,w=.,reg=.)
		}
		yt=select(y,w)
		wt=select(w,w)
		pred[i,1]=(invsym((reg:*wt)'reg)*(reg:*wt)'yt)[1,1]
	}
	st_store(.,out,touse,pred)
}

*Mata, logistic distribution
version 9.2
mata real colvector logisticcdf(real colvector x) return(1:/(1:+exp(-x)))

*Mata, logistic density
version 9.2
mata real colvector logisticpdf(real colvector x)
{
	real colvector temp
	temp=exp(-x)
	return(temp:/(1:+temp)^2)
}

*Mata, objective function of the weighted logit estimator
version 9.2
mata void lnwlogit(real scalar todo, real rowvector p, real matrix x, real colvector y, real colvector w, real colvector lnf, real matrix S, real matrix H)
{
	real colvector prob
	prob=logisticcdf(x*p')
	lnf=w:*log(y:*prob:+(1:-y):*(1:-prob))
	if (todo >= 1) {
		S=w:*(x:*(y-prob))
		if (todo==2) {
			H=-(w:*x:*prob:*(1:-prob))'x
		}
	}
}

*Mata function estimating the propensity score by local logit, optimization using Stata 10 optimizer
version 9.2
mata void loclog(string scalar dep, string scalar continuous, string scalar dummy, string scalar unordered, string scalar unord_list, string scalar kernel, real scalar bandwidth, real scalar lambda, string scalar touse, string scalar out)
{
//Variable declarations
	real colvector y, pred, w, yt, wt
	real scalar n, nc, nd, nu, h1, l1, dettemp, i, ret
	real matrix xc, xd, xur, xuk, reg
	transmorphic S
//read the data into Mata
	y=st_data(.,dep,touse)
	n=rows(y)
	if(continuous~="empty") {
		xc=st_data(.,tokens(continuous),touse)
		xc=xc*luinv(cholesky(variance(xc)))'
	}  
	else xc=J(n,0,0)
	if(dummy~="empty"){
		xd=st_data(.,tokens(dummy),touse) 
	}
	else xd=J(n,0,0)
	if(unordered~="empty"){
		xur=st_data(.,tokens(unord_list),touse)
		xuk=st_data(.,tokens(unordered),touse)	
	}
	else xur=xuk=J(n,0,0)	
	nc=cols(xc)
	nd=cols(xd)
	nu=cols(xuk)
	pred=J(n,1,0)
	S = optimize_init()
	optimize_init_evaluator(S, &lnwlogit())
	optimize_init_evaluatortype(S, "v2")
	optimize_init_conv_maxiter(S, 300)
	optimize_init_verbose(S, 0)
	optimize_init_tracelevel(S, "none")
	for(i=1; i<=n; i++){
		h1=bandwidth
		l1=lambda
		mkernel((xd,xuk),xc,xur,(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n,nd,nc,nu,w=.,reg=.)
		dettemp=det(reg'reg)
		while(dettemp<1e-7 & h1<100 & h1>0){
			h1=h1*1.05
			mkernel((xd,xuk),xc,xur,(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n,nd,nc,nu,w=.,reg=.)
			dettemp=det(reg'reg)
		}
		if(dettemp<1e-7){
			h1=1e10
			l1=1
			mkernel((xd,xuk),xc,xur,(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n,nd,nc,nu,w=.,reg=.)
		}
		ret=1
		while(ret!=0){
			yt=select(y,w)
			wt=select(w,w)
			optimize_init_params(S,((invsym((reg:*wt)'reg)*(reg:*wt)'yt))')
			optimize_init_argument(S, 1, reg)
			optimize_init_argument(S, 2, yt)
			optimize_init_argument(S, 3, wt)
			ret = _optimize(S)
			if(ret!=0){
				if(h1<100){
					h1=h1*1.05
				}
				else{
					h1=1e10
					l1=1
				}
				mkernel((xd,xuk),xc,xur,(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n,nd,nc,nu,w=.,reg=.)
			}
		}
		pred[i,1]=logisticcdf(optimize_result_params(S)[1])
	}
	st_store(.,out,touse,pred)
}

version 9.2
mata real rowvector intlog(real colvector dep, real matrix reg, real colvector we, real scalar convergence)
{
//variable declarations
	real scalar objo, objn, it
	real rowvector b, db
	real colvector prob
	objo=0
	b=((invsym((reg:*we)'reg)*(reg:*we)'dep))'
	prob=logisticcdf(reg*b')
	objn=colsum(we:*log(dep:*prob:+(1:-dep):*(1:-prob)))
	db=colsum(we:*(reg:*(dep-prob)))*invsym((we:*reg:*prob:*(1:-prob))'reg)
	it=1
	while(it<100 & sum(abs(db):>1e-8)>0 & abs(objn-objo)>1e-8){
		objo=objn
		b=b+db
		it=it+1
		prob=logisticcdf(reg*b')
		objn=colsum(we:*log(dep:*prob:+(1:-dep):*(1:-prob)))
		db=colsum(we:*(reg:*(dep-prob)))*invsym((we:*reg:*prob:*(1:-prob))'reg)
	}
	convergence=(it==100)
	return(b)
}

*Mata function estimating the propensity score by local logit, optimization using self written codes
version 9.2
mata void loclog1(string scalar dep, string scalar continuous, string scalar dummy, string scalar unordered, string scalar unord_list, string scalar kernel, real scalar bandwidth, real scalar lambda, string scalar touse, string scalar out)
{
//Variable declarations
	real colvector y, pred, w, yt, wt
	real rowvector bt
	real scalar n, nc, nd, nu, h1, l1, dettemp, i, convergence
	real matrix xc, xd, xur, xuk, reg
//read the data into Mata
	y=st_data(.,dep,touse)
	n=rows(y)
	if(continuous~="empty") {
		xc=st_data(.,tokens(continuous),touse)
		xc=xc*luinv(cholesky(variance(xc)))'
	}  
	else xc=J(n,0,0)
	if(dummy~="empty"){
		xd=st_data(.,tokens(dummy),touse) 
	}
	else xd=J(n,0,0)
	if(unordered~="empty"){
		xur=st_data(.,tokens(unord_list),touse)
		xuk=st_data(.,tokens(unordered),touse)	
	}
	else xur=xuk=J(n,0,0)	
	nc=cols(xc)
	nd=cols(xd)
	nu=cols(xuk)
	pred=J(n,1,0)
	for(i=1; i<=n; i++){
		h1=bandwidth
		l1=lambda
		mkernel((xd,xuk),xc,xur,(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n,nd,nc,nu,w=.,reg=.)
		dettemp=det(reg'reg)
		while(dettemp<1e-7 & h1<100 & h1>0){
			h1=h1*1.05
			mkernel((xd,xuk),xc,xur,(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n,nd,nc,nu,w=.,reg=.)
			dettemp=det(reg'reg)
		}
		if(dettemp<1e-7){
			h1=1e10
			l1=1
			mkernel((xd,xuk),xc,xur,(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n,nd,nc,nu,w=.,reg=.)
		}
		convergence=.
		while(convergence!=0){
			convergence=.
			yt=select(y,w)
			wt=select(w,w)
			bt = intlog(yt,reg,wt,convergence)
			if(convergence!=0){
				if(h1<100){
					h1=h1*1.05
				}
				else{
					h1=1e10
					l1=1
				}
				mkernel((xd,xuk),xc,xur,(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n,nd,nc,nu,w=.,reg=.)
			}
		}
		pred[i,1]=logisticcdf(bt[1])
	}
	st_store(.,out,touse,pred)
}

*Mata function estimating the qte using the propensity score
version 9.2
mata void est_qte(string scalar dep, string scalar treatment, string scalar weight, string scalar touse, string scalar quantiles, string scalar out, string scalar out1, string scalar out0)
{
//Variable declarations
	real colvector y, d, w, quant, ys, oy, dist1, dist0
	real rowvector q1, q0, temp1, temp0
	real scalar n, nq, i, Pc, ns
//read the data into Mata
	y=st_data(.,dep,touse)
	n=rows(y)
	d=st_data(.,treatment,touse)
	w=st_data(.,weight,touse)
	quant=st_matrix(quantiles)
	nq=rows(quant)
	w=w:-mean(w)
	Pc=mean(d:*w)
	oy=order(y,1)
	ys=sort(uniqrows(y),1)
	ns=rows(ys)
	dist1=J(ns,1,.)
	dist0=J(ns,1,.)
	temp1=runningsum(d[oy]:*w[oy])/Pc/n
	temp0=runningsum(((d[oy]:-1):*w[oy]))/Pc/n
	for(i=1;i<=ns;i++){
		dist1[i,1]=temp1[colsum(y:<=ys[i])]
		dist0[i,1]=temp0[colsum(y:<=ys[i])]
	}
	q1=J(1,nq,0)
	q0=J(1,nq,0)
	for(i=1;i<=nq;i++){
		q1[1,i]=ys[max(1\colsum(dist1:<=quant[i,1]))]
		q0[1,i]=ys[max(1\colsum(dist0:<=quant[i,1]))]
	}
	st_matrix(out,q1-q0)
	st_matrix(out1,q1)
	st_matrix(out0,q0)
}

*Mata function estimating the counterfactual quantiles using the propensity score, data already in Mata
version 9.2
mata void est_qteb(real colvector y, real colvector d, real colvector w, real scalar n, real colvector quant, real colvector q1, real colvector q0)
{
//Variable declarations
	real colvector ys, oy, dist1, dist0
	real scalar nq, i, Pc
	nq=rows(quant)
	Pc=mean(d:*w)
	oy=order(y,1)
	ys=sort(uniqrows(y),1)
	ns=rows(ys)
	dist1=J(ns,1,.)
	dist0=J(ns,1,.)
	temp1=runningsum(d[oy]:*w[oy])/Pc/n
	temp0=runningsum(((d[oy]:-1):*w[oy]))/Pc/n
	for(i=1;i<=ns;i++){
		dist1[i,1]=temp1[colsum(y:<=ys[i])]
		dist0[i,1]=temp0[colsum(y:<=ys[i])]
	}
	q1=J(nq,1,.)
	q0=J(nq,1,.)
	for(i=1;i<=nq;i++){
		q1[i,1]=ys[max(1\colsum(dist1:<=quant[i,1]))]
		q0[i,1]=ys[max(1\colsum(dist0:<=quant[i,1]))]
	}
}

*Mata function calculating the asymptotic variance
version 9.2
mata void as_var(real scalar logit, real scalar pos, real scalar nine, string scalar quant1, string scalar quant0, string scalar quantiles, string scalar dep, string scalar treatment, string scalar instrument, string scalar continuous, string scalar dummy, string scalar unordered, string scalar unord_list, string scalar weight, string scalar pscore, string scalar kernel, real scalar bandwidth, real scalar lambda, string scalar touse, string scalar var)
{
//Variable declarations
	real colvector y, d, z, w, p, q1, q0, quants, res, pi1, pi0, temp, q1_var, q0_var, den1, den0, fi11, fi01, fi10, fi00
	real scalar n, nq, n1, n0, q, Pc, bw1, bw0
	real matrix xc, xd, xur, xuk, cond_dist11, cond_dist10, cond_dist01, cond_dist00, variance
	y=st_data(.,dep,touse)
	n=rows(y)
	if(continuous~="empty") {
		xc=st_data(.,tokens(continuous),touse)
		xc=xc*luinv(cholesky(variance(xc)))'
	}  
	else xc=J(n,0,.)
	if(dummy~="empty"){
		xd=st_data(.,tokens(dummy),touse) 
	}
	else xd=J(n,0,.)
	if(unordered~="empty"){
		xur=st_data(.,tokens(unord_list),touse)
		xuk=st_data(.,tokens(unordered),touse)	
	}
	else xur=xuk=J(n,0,0)	
	d=st_data(.,treatment,touse)
	z=st_data(.,instrument,touse)
	w=st_data(.,weight,touse)
	p=st_data(.,pscore,touse)
	q1=st_matrix(quant1)'
	q0=st_matrix(quant0)'
	res=q1-q0
	quants=st_matrix(quantiles)
	nq=rows(res)
	if(logit==0){
		pi1=loclinb(select(d,z:==1),select(xc,z:==1),select(xd,z:==1),select(xuk,z:==1),select(xur,z:==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
		pi0=loclinb(select(d,z:==0),select(xc,z:==0),select(xd,z:==0),select(xuk,z:==0),select(xur,z:==0),xc,xd,xuk,xur,kernel,bandwidth,lambda)
	}
	else{
		if(nine==1){
			pi1=loclog1b(select(d,z:==1),select(xc,z:==1),select(xd,z:==1),select(xuk,z:==1),select(xur,z:==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
			pi0=loclog1b(select(d,z:==0),select(xc,z:==0),select(xd,z:==0),select(xuk,z:==0),select(xur,z:==0),xc,xd,xuk,xur,kernel,bandwidth,lambda)
		}
		if(nine==0){
			pi1=loclogb(select(d,z:==1),select(xc,z:==1),select(xd,z:==1),select(xuk,z:==1),select(xur,z:==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
			pi0=loclogb(select(d,z:==0),select(xc,z:==0),select(xd,z:==0),select(xuk,z:==0),select(xur,z:==0),xc,xd,xuk,xur,kernel,bandwidth,lambda)
		}
	}
	Pc=mean(pi1)-mean(pi0)
	n1=sum(d)
	n0=sum(1:-d)
	if(pos==0){
		est_qteb(y,d,w,n,(1/(n1+1))*(1..n1)',q1_var=.,temp=.)
		bw1=kdens_bw(q1_var)
		est_qteb(y,d,w,n,(1/(n0+1))*(1..n0)',temp,q0_var=.)
		bw0=kdens_bw(q0_var)
		den1=kdens_gen(q1_var[.,1],1,q1,bw1)
		den0=kdens_gen(q0_var[.,1],1,q0,bw0)
	}
	else{
		q0_var=mm_quantile(select(y,(1:-d):*(w:>0)),select(w,(1:-d):*(w:>0)),(1/(n0+n1+1))*(1..(n0+n1))')
		q1_var=mm_quantile(select(y,d:*(w:>0)),select(w,d:*(w:>0)),(1/(n0+n1+1))*(1..(n0+n1))')
		bw1=kdens_bw(q1_var)
		bw0=kdens_bw(q0_var)
		den1=kdens_gen(q1_var[.,1],1,q1,bw1)
		den0=kdens_gen(q0_var[.,1],1,q0,bw0)
	}
	cond_dist11=J(n,nq,.)
	cond_dist01=J(n,nq,.)
	cond_dist10=J(n,nq,.)
	cond_dist00=J(n,nq,.)
	for(q=1;q<=nq;q++){
		if(logit==0){
			cond_dist11[.,q]=loclinb(select(y,(z:*d):==1):<=q1[q,1],select(xc,(z:*d):==1),select(xd,(z:*d):==1),select(xuk,(z:*d):==1),select(xur,(z:*d):==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
			cond_dist10[.,q]=loclinb(select(y,((1:-z):*d):==1):<=q1[q,1],select(xc,((1:-z):*d):==1),select(xd,((1:-z):*d):==1),select(xuk,((1:-z):*d):==1),select(xur,((1:-z):*d):==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
			cond_dist01[.,q]=loclinb(select(y,(z:*(1:-d)):==1):<=q0[q,1],select(xc,(z:*(1:-d)):==1),select(xd,(z:*(1:-d)):==1),select(xuk,(z:*(1:-d)):==1),select(xur,(z:*(1:-d)):==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
			cond_dist00[.,q]=loclinb(select(y,((1:-z):*(1:-d)):==1):<=q0[q,1],select(xc,((1:-z):*(1:-d)):==1),select(xd,((1:-z):*(1:-d)):==1),select(xuk,((1:-z):*(1:-d)):==1),select(xur,((1:-z):*(1:-d)):==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
		}
		else{
			if(nine==1){
				cond_dist11[.,q]=loclog1b(select(y,(z:*d):==1):<=q1[q,1],select(xc,(z:*d):==1),select(xd,(z:*d):==1),select(xuk,(z:*d):==1),select(xur,(z:*d):==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
				cond_dist10[.,q]=loclog1b(select(y,((1:-z):*d):==1):<=q1[q,1],select(xc,((1:-z):*d):==1),select(xd,((1:-z):*d):==1),select(xuk,((1:-z):*d):==1),select(xur,((1:-z):*d):==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
				cond_dist01[.,q]=loclog1b(select(y,(z:*(1:-d)):==1):<=q0[q,1],select(xc,(z:*(1:-d)):==1),select(xd,(z:*(1:-d)):==1),select(xuk,(z:*(1:-d)):==1),select(xur,(z:*(1:-d)):==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
				cond_dist00[.,q]=loclog1b(select(y,((1:-z):*(1:-d)):==1):<=q0[q,1],select(xc,((1:-z):*(1:-d)):==1),select(xd,((1:-z):*(1:-d)):==1),select(xuk,((1:-z):*(1:-d)):==1),select(xur,((1:-z):*(1:-d)):==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
			}
			if(nine==0){
				cond_dist11[.,q]=loclogb(select(y,(z:*d):==1):<=q1[q,1],select(xc,(z:*d):==1),select(xd,(z:*d):==1),select(xuk,(z:*d):==1),select(xur,(z:*d):==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
				cond_dist10[.,q]=loclogb(select(y,((1:-z):*d):==1):<=q1[q,1],select(xc,((1:-z):*d):==1),select(xd,((1:-z):*d):==1),select(xuk,((1:-z):*d):==1),select(xur,((1:-z):*d):==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
				cond_dist01[.,q]=loclogb(select(y,(z:*(1:-d)):==1):<=q0[q,1],select(xc,(z:*(1:-d)):==1),select(xd,(z:*(1:-d)):==1),select(xuk,(z:*(1:-d)):==1),select(xur,(z:*(1:-d)):==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
				cond_dist00[.,q]=loclogb(select(y,((1:-z):*(1:-d)):==1):<=q0[q,1],select(xc,((1:-z):*(1:-d)):==1),select(xd,((1:-z):*(1:-d)):==1),select(xuk,((1:-z):*(1:-d)):==1),select(xur,((1:-z):*(1:-d)):==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
			}
		}
	}
	variance=J(nq,1,.)
	for(q=1;q<=nq;q++){
		variance[q,1]=1/(Pc^2*den1[q,1]^2)*mean(pi1:/p:*cond_dist11[.,q]:*(1:-cond_dist11[.,q]))
		variance[q,1]=variance[q,1]+1/(Pc^2*den1[q,1]^2)*mean(pi0:/(1:-p):*cond_dist10[.,q]:*(1:-cond_dist10[.,q]))
		variance[q,1]=variance[q,1]+1/(Pc^2*den0[q,1]^2)*mean((1:-pi1):/p:*cond_dist01[.,q]:*(1:-cond_dist01[.,q]))
		variance[q,1]=variance[q,1]+1/(Pc^2*den0[q,1]^2)*mean((1:-pi0):/(1:-p):*cond_dist00[.,q]:*(1:-cond_dist00[.,q]))
		fi11=(quants[q,1]:-cond_dist11[.,q]):/Pc:/den1[q,1]
		fi10=(quants[q,1]:-cond_dist10[.,q]):/Pc:/den1[q,1]
		fi01=(quants[q,1]:-cond_dist01[.,q]):/Pc:/den0[q,1]
		fi00=(quants[q,1]:-cond_dist00[.,q]):/Pc:/den0[q,1]
		variance[q,1]=variance[q,1]+mean((pi1:*fi11:^2:+(1:-pi1):*fi01:^2):/p:+(pi0:*fi10:^2:+(1:-pi0):*fi00:^2):/(1:-p))
		variance[q,1]=variance[q,1]+mean(p:*(1:-p):*((pi1:*fi11:+(1:-pi1):*fi01):/p+(pi0:*fi10:+(1:-pi0):*fi00):/(1:-p)):^2)
	}
	variance=diag(variance:/n)
	st_matrix(var,variance)
}

*Mata function calculating the asymptotic variance of Firpo
version 9.2
mata void as_var1(real scalar logit, real scalar nine, string scalar quant1, string scalar quant0, string scalar quantiles, string scalar dep, string scalar treatment, string scalar continuous, string scalar dummy, string scalar unordered, string scalar unord_list, string scalar weight, string scalar pscore, string scalar kernel, real scalar bandwidth, real scalar lambda, string scalar touse, string scalar var)
{
//Variable declarations
	real colvector y, d, w, p, q1, q0, quants, res, den1, den0, fi1, fi0
	real scalar n, nq, q, bw1, bw0
	real matrix xc, xd, xur, xuk, cond_dist1, cond_dist0, variance
	y=st_data(.,dep,touse)
	n=rows(y)
	if(continuous~="empty") {
		xc=st_data(.,tokens(continuous),touse)
		xc=xc*luinv(cholesky(variance(xc)))'
	}  
	else xc=J(n,0,.)
	if(dummy~="empty"){
		xd=st_data(.,tokens(dummy),touse) 
	}
	else xd=J(n,0,.)
	if(unordered~="empty"){
		xur=st_data(.,tokens(unord_list),touse)
		xuk=st_data(.,tokens(unordered),touse)	
	}
	else xur=xuk=J(n,0,0)	
	d=st_data(.,treatment,touse)
	w=st_data(.,weight,touse)
	p=st_data(.,pscore,touse)
	q1=st_matrix(quant1)'
	q0=st_matrix(quant0)'
	res=q1-q0
	quants=st_matrix(quantiles)
	nq=rows(res)
	bw1=kdens_bw(select(y,d:*(w:>0)),select(w,d:*(w:>0)))
	bw0=kdens_bw(select(y,(1:-d):*(w:>0)),select(w,(1:-d):*(w:>0)))
	den1=kdens_gen(select(y,d:*(w:>0)),select(w,d:*(w:>0)),q1,bw1)
	den0=kdens_gen(select(y,(1:-d):*(w:>0)),select(w,(1:-d):*(w:>0)),q0,bw0)
	cond_dist1=J(n,nq,.)
	cond_dist0=J(n,nq,.)
	for(q=1;q<=nq;q++){
		if(logit==0){
			cond_dist1[.,q]=loclinb(select(y,d:==1):<=q1[q,1],select(xc,d:==1),select(xd,d:==1),select(xuk,d:==1),select(xur,d:==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
			cond_dist0[.,q]=loclinb(select(y,(1:-d):==1):<=q0[q,1],select(xc,(1:-d):==1),select(xd,(1:-d):==1),select(xuk,(1:-d):==1),select(xur,(1:-d):==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
		}
		else{
			if(nine==0){
				cond_dist1[.,q]=loclogb(select(y,d:==1):<=q1[q,1],select(xc,d:==1),select(xd,d:==1),select(xuk,d:==1),select(xur,d:==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
				cond_dist0[.,q]=loclogb(select(y,(1:-d):==1):<=q0[q,1],select(xc,(1:-d):==1),select(xd,(1:-d):==1),select(xuk,(1:-d):==1),select(xur,(1:-d):==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
			}
			if(nine==1){
				cond_dist1[.,q]=loclog1b(select(y,d:==1):<=q1[q,1],select(xc,d:==1),select(xd,d:==1),select(xuk,d:==1),select(xur,d:==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
				cond_dist0[.,q]=loclog1b(select(y,(1:-d):==1):<=q0[q,1],select(xc,(1:-d):==1),select(xd,(1:-d):==1),select(xuk,(1:-d):==1),select(xur,(1:-d):==1),xc,xd,xuk,xur,kernel,bandwidth,lambda)
			}
		}
	}
	variance=J(nq,1,.)
	for(q=1;q<=nq;q++){
		variance[q,1]=1/den1[q,1]^2*mean(cond_dist1[.,q]:*(1:-cond_dist1[.,q]):/p)
		variance[q,1]=variance[q,1]+1/den0[q,1]^2*mean(cond_dist0[.,q]:*(1:-cond_dist0[.,q]):/(1:-p))
		fi1=(quants[q,1]:-cond_dist1[.,q]):/den1[q,1]
		fi0=(quants[q,1]:-cond_dist0[.,q]):/den0[q,1]
		variance[q,1]=variance[q,1]+mean(fi1:^2:/p:+fi0:^2:/(1:-p))
		variance[q,1]=variance[q,1]+mean(p:*(1:-p):*(fi1:/p:+fi0:/(1:-p)):^2)
	}
	variance=diag(variance:/n)
	st_matrix(var,variance)
}

*Mata function calculating the asymptotic variance of AAI
version 9.2
mata void as_var2(string scalar coefficients, string scalar quantile, string scalar dep, string scalar treatment, string scalar instrument, string scalar regressor, string scalar continuous, string scalar dummy, string scalar unordered, string scalar unord_list, string scalar weight, string scalar pscore, string scalar touse, string scalar var, string scalar kernel, real scalar bandwidth, real scalar lambda)
{
//Variable declarations
	real colvector y, d, z, w, p, kappa, coef, resid, t, der, quants
	real scalar n, i, h
	real matrix x, xc, xd, xur, xuk, variance, W, J, Hi, H, phi, S
	y=st_data(.,dep,touse)
	n=rows(y)
	x=st_data(.,tokens(regressor),touse)
	if(continuous~="empty") {
		xc=st_data(.,tokens(continuous),touse)
		xc=xc*luinv(cholesky(variance(xc)))'
	}  
	else xc=J(n,0,.)
	if(dummy~="empty"){
		xd=st_data(.,tokens(dummy),touse) 
	}
	else xd=J(n,0,.)
	if(unordered~="empty"){
		xur=st_data(.,tokens(unord_list),touse)
		xuk=st_data(.,tokens(unordered),touse)	
	}
	else xur=xuk=J(n,0,0)	
	d=st_data(.,treatment,touse)
	z=st_data(.,instrument,touse)
	p=st_data(.,pscore,touse)
	kappa=st_data(.,weight,touse)
	w=1:-d:*(1:-z):/(1:-p):-(1:-d):*z:/p
	coef=st_matrix(coefficients)'
	quants=st_matrix(quantile)
	quants=quants[1,1]
	W=(d,x,J(n,1,1))
	resid=y:-W*coef
	h=(n^(-1/5))*sqrt(variance(resid))
	t=(15/(16*h))*((1:-((resid:/h):^2)):^2):*(abs((resid:/h)):<1)
	J = W'(W:*kappa:*t)
	der = ((1:-d):*z:/(p:^2)) - (d:*(1:-z):/((1:-p):^2))
	Hi=(quants:-(resid:<0)):*der:* W
	H=Hi
	for(i=1;i<=cols(Hi);i++) H[.,i]=loclinb(Hi[.,i], xc, xd, xuk, xur, xc, xd, xuk, xur, kernel, bandwidth, lambda)
	phi=w:*(quants:-(resid:<0)):* W:+(z:-p):*H
	S=phi'phi
	variance = invsym(J)*S*invsym(J)
	st_matrix(var,variance)
}

*Mata function calculating Hall and Sheather bandwidth
version 9.2
mata real scalar rq_band(real scalar p, real scalar n, real scalar alpha)
{
//variable declaration
	real scalar x0, f0
	x0 = invnormal(p)
	f0 = normalden(x0)
	return(n^(-1/3) * invnormal(1 - alpha/2)^(2/3) * ((1.5 * f0^2)/(2 *x0^2 + 1))^(1/3))
}

*Mata function calculating the asymptotic variance of quantile regression
version 9.2
mata void as_var3(string scalar coefficients, string scalar quantile, string scalar dep, string scalar regressor, string scalar weight, string scalar touse, string scalar var, real scalar alpha)
{
//variable declaration
	real colvector y, w, coef, quants, resid, phi
	real scalar n, h
	real matrix x, X, J, sigma, variance
	y=st_data(.,dep,touse)
	n=rows(y)
	x=st_data(.,tokens(regressor),touse)
	w=st_data(.,weight,touse)
	coef=st_matrix(coefficients)'
	quants=st_matrix(quantile)
	quants=quants[1,1]
	X=(x,J(n,1,1))
	y=y:*w
	X=X:*w	
	resid=y:-X*coef
	h=rq_band(quants, n, alpha)
	if(quants-h<0.005) h=quants/2
	if(quants+h>0.995) h=(1+quants)/2
	h=(invnormal(quants+h)-invnormal(quants-h))*min(sqrt(variance(resid,w))\(mm_quantile(resid,w,0.75)-mm_quantile(resid,w,0.25))/1.34)
	phi=normalden(resid:/h):/h
	J=invsym((phi:*X)'X)
	X=(quants:-(resid:<=0)):*X
	sigma=X'X
	variance=J*sigma*J
	st_matrix(var,variance)
}

*Mata function estimating the propensity score by local logit, optimization using self written codes, data already in mata
version 9.2
mata real colvector loclog1b(real colvector y, real matrix xc, real matrix xd, real matrix xuk, real matrix xur, real matrix evc, real matrix evd, real matrix evuk, real matrix evur, string scalar kernel, real scalar bandwidth, real scalar lambda)
{
	real scalar n_use, nc, nd, nu, n, h1, l1, dettemp, convergence, i
	real rowvector bt
	real colvector pred, w, yt, wt
	real matrix xct, reg, evct
	n_use=rows(xc)
	nc=cols(xc)
	nd=cols(xd)
	nu=cols(xuk)
	n=rows(evc)
	if((nc>0)*(bandwidth<.)+(nd>0)*(lambda<1)+(nu>0)*(lambda<1)==0){
		bt=intlog(y,(J(n_use,1,1),xd,xc,xur),J(n_use,1,1),convergence=.)
		pred=logisticcdf((J(n,1,1),evd,evc,evur)*bt')
	} 
	else{
		if (nc>0) evct=evc*luinv(cholesky(variance(xc)))'
		else evct=evc
		if (nc>0) xct=xc*luinv(cholesky(variance(xc)))'
		else xct=xc
		pred=J(n,1,0)
		for(i=1; i<=n; i++){
			h1=bandwidth
			l1=lambda
			mkernel((xd,xuk),xct,xur,(evd[i,.],evuk[i,.],evct[i,.]),evur[i,.],kernel,h1,l1,n_use,nd,nc,nu,w=.,reg=.)
			dettemp=det(reg'reg)
			while(dettemp<1e-7 & h1<100 & h1>0){
				h1=h1*1.05
				mkernel((xd,xuk),xct,xur,(evd[i,.],evuk[i,.],evct[i,.]),evur[i,.],kernel,h1,l1,n_use,nd,nc,nu,w=.,reg=.)
				dettemp=det(reg'reg)
			}
			if(dettemp<1e-7){
				h1=1e10
				l1=1
				mkernel((xd,xuk),xct,xur,(evd[i,.],evuk[i,.],evct[i,.]),evur[i,.],kernel,h1,l1,n_use,nd,nc,nu,w=.,reg=.)
			}
			convergence=.
			while(convergence!=0){
				convergence=.
				yt=select(y,w)
				wt=select(w,w)
				bt = intlog(yt,reg,wt,convergence)
				if(convergence!=0){
					if(h1<100){
						h1=h1*1.05
					}
					else{
						h1=1e10
						l1=1
					}
					mkernel((xd,xuk),xct,xur,(evd[i,.],evuk[i,.],evct[i,.]),evur[i,.],kernel,h1,l1,n_use,nd,nc,nu,w=.,reg=.)
				}
			}
			pred[i,1]=logisticcdf(bt[1])
		}
	}
	return(pred)
}

*Mata function estimating the propensity score by local logit, optimization using Stata 10 optimizer, data already in Mata
version 9.2
mata real colvector loclogb(real colvector y, real matrix xc, real matrix xd, real matrix xuk, real matrix xur, real matrix evc, real matrix evd, real matrix evuk, real matrix evur, string scalar kernel, real scalar bandwidth, real scalar lambda)
{
	real scalar n_use, nc, nd, nu, n, ret, i, h1, l1, dettemp
	real colvector pred, w, yt, wt
	real matrix evct, xct, reg
	transmorphic S
	n_use=rows(xc)
	nc=cols(xc)
	nd=cols(xd)
	nu=cols(xuk)
	n=rows(evc)
	if((nc>0)*(bandwidth<.)+(nd>0)*(lambda<1)+(nu>0)*(lambda<1)==0){
		S = optimize_init()
		optimize_init_evaluator(S, &lnwlogit())
		optimize_init_evaluatortype(S, "v2")
		optimize_init_conv_maxiter(S, 300)
		optimize_init_verbose(S, 0)
		optimize_init_tracelevel(S, "none")
		optimize_init_params(S,(invsym((J(n_use,1,1),xd,xc,xur)'(J(n_use,1,1),xd,xc,xur))*(J(n_use,1,1),xd,xc,xur)'y)')
		optimize_init_argument(S, 1, (J(n_use,1,1),xd,xc,xur))
		optimize_init_argument(S, 2, y)
		optimize_init_argument(S, 3, J(n_use,1,1))
		ret = _optimize(S)
		pred=logisticcdf((J(n,1,1),evd,evc,evur)*optimize_result_params(S)')
	} 
	else {
		if(nc>0) evct=evc*luinv(cholesky(variance(xc)))'
		else evct=evc
		if(nc>0) xct=xc*luinv(cholesky(variance(xc)))'
		else xct=xc
		pred=J(n,1,0)
		S = optimize_init()
		optimize_init_evaluator(S, &lnwlogit())
		optimize_init_evaluatortype(S, "v2")
		optimize_init_conv_maxiter(S, 300)
		optimize_init_verbose(S, 0)
		optimize_init_tracelevel(S, "none")
		for(i=1; i<=n; i++){
			h1=bandwidth
			l1=lambda
			mkernel((xd,xuk),xct,xur,(evd[i,.],evuk[i,.],evct[i,.]),evur[i,.],kernel,h1,l1,n_use,nd,nc,nu,w=.,reg=.)
			dettemp=det(reg'reg)
			while(dettemp<1e-7 & h1<100 & h1>0){
				h1=h1*1.05
				mkernel((xd,xuk),xct,xur,(evd[i,.],evuk[i,.],evct[i,.]),evur[i,.],kernel,h1,l1,n_use,nd,nc,nu,w=.,reg=.)
				dettemp=det(reg'reg)
			}
			if(dettemp<1e-7){
				h1=1e10
				l1=1
				mkernel((xd,xuk),xct,xur,(evd[i,.],evuk[i,.],evct[i,.]),evur[i,.],kernel,h1,l1,n_use,nd,nc,nu,w=.,reg=.)
			}
			ret=1
			while(ret!=0){
				yt=select(y,w)
				wt=select(w,w)
				optimize_init_params(S,((invsym((reg:*wt)'reg)*(reg:*wt)'yt))')
				optimize_init_argument(S, 1, reg)
				optimize_init_argument(S, 2, yt)
				optimize_init_argument(S, 3, wt)
				ret = _optimize(S)
				if(ret!=0){
					if(h1<100){
						h1=h1*1.05
					}
					else{
						h1=1e10
						l1=1
					}
					mkernel((xd,xuk),xct,xur,(evd[i,.],evuk[i,.],evct[i,.]),evur[i,.],kernel,h1,l1,n_use,nd,nc,nu,w=.,reg=.)
				}
			}
			pred[i,1]=logisticcdf(optimize_result_params(S)[1])
		}
	}
	return(pred)
}

*Mata function estimating the propensity score by local linear regression
version 9.2
mata real colvector loclinb(real colvector y, real matrix xc, real matrix xd, real matrix xuk, real matrix xur, real matrix evc, real matrix evd, real matrix evuk, real matrix evur, string scalar kernel, real scalar bandwidth, real scalar lambda)
{
	real scalar n_use, nc, nd, nu, n, i, h1, l1, dettemp
	real colvector pred, w, yt, wt
	real matrix evct, xct, reg
	real rowvector b
	n_use=rows(xc)
	n=rows(evc)
	nc=cols(xc)
	nd=cols(xd)
	nu=cols(xuk)
	if((nc>0)*(bandwidth<.)+(nd>0)*(lambda<1)+(nu>0)*(lambda<1)==0){
		reg=J(n_use,1,1),xc,xd,xur
		b=invsym(reg'reg)*reg'y
		pred=(J(n,1,1),evc,evd,evur)*b
	} 
	else {
		if (nc>0) evct=evc*luinv(cholesky(variance(xc)))'
		else evct=evc
		if (nc>0) xct=xc*luinv(cholesky(variance(xc)))'
		else xct=xc
		pred=J(n,1,.)
		for(i=1; i<=n; i++){
			h1=bandwidth
			l1=lambda
			mkernel((xd,xuk),xct,xur,(evd[i,.],evuk[i,.],evct[i,.]),evur[i,.],kernel,h1,l1,n_use,nd,nc,nu,w=.,reg=.)
			dettemp=det(reg'reg)
			while(dettemp<1e-7 & h1<100 & h1>0){
				h1=h1*1.05
				mkernel((xd,xuk),xct,xur,(evd[i,.],evuk[i,.],evct[i,.]),evur[i,.],kernel,h1,l1,n_use,nd,nc,nu,w=.,reg=.)
				dettemp=det(reg'reg)
			}
			if(dettemp<1e-7){
				h1=1e10
				l1=1
				mkernel((xd,xuk),xct,xur,(evd[i,.],evuk[i,.],evct[i,.]),evur[i,.],kernel,h1,l1,n_use,nd,nc,nu,w=.,reg=.)
			}
			yt=select(y,w)
			wt=select(w,w)
			pred[i,1]=(invsym((reg:*wt)'reg)*(reg:*wt)'yt)[1,1]
		}
	}
	return(pred)
}
