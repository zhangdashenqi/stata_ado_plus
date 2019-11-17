*! version 2.1.8  12feb2010  Markus Froelich and Blaise Melly
*2.0.1: allow for lambda=0
*2.1.0: use of _caller()
*2.1.1: allow weights
*2.1.2: provide an output
*2.1.3: provide more saved results
*2.1.4: variable declarations in Mata
*2.1.5: infinite bandwidth is ".". No negative values are allowed
*2.1.6: replace is allowed for generate and sample
*2.1.7: option logit allowed for non-binary dependent variables
*2.1.8: implement higher-order kernel functions

program locreg, rclass
	version 9.2
	capt findfile lmoremata.mlib
	if _rc {
      	di as error "-moremata- is required; type {stata ssc install moremata}"
		error 499
	}
	syntax varname [if] [in] [aweight fweight/][, Generate(string) Bandwidth(string) Lambda(string) Continuous(varlist) Dummy(varlist) Unordered(varlist) Kernel(string) LOGit mata_opt Sample(string)]
	marksample touse
	markout `touse' `varlist' `continuous' `dummy' `unordered'
	quietly summarize `touse'
	local obs=r(sum)
	if "`weight'"==""{
		tempvar exp
		quietly gen `exp'=1
	}
	else{
		quietly sum `exp' if `touse'
		quietly replace `exp'=`exp'/r(mean) if `touse'
	}
	if "`logit'"!=""{
		quietly sum `varlist'
		if r(max)>1 | r(min)<0{
			dis as error "The range of the dependent variable must be between 0 and 1 when the option logit is activated"
			exit
		}
	}
	if _caller()<10 & "`mata_opt'"=="mata_opt" {
     		di as error "The option mata_opt can only be used with Stata 10 or newer."
		exit
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
	if "`generate'"!=""{
		tokenize "`generate'", parse(",")
		gettoken generate :1, parse("")
		capture confirm variable `generate', exact
		if _rc==0 & "`3'"!="replace"{
      		di as error "`generate' already exists"
			exit
		}
		else if _rc==0 & "`3'"=="replace"{
			quietly drop `generate'
		}
	}				
	if "`sample'"!=""{
		tokenize "`sample'", parse(",")
		gettoken sample :1, parse("")
		capture confirm variable `sample', exact
		if _rc==0 & "`3'"!="replace"{
      		di as error "`sample' already exists"
			exit
		}
		else if _rc==0 & "`3'"=="replace"{
			quietly drop `sample'
		}
		quietly generate `sample'=`touse'
	}				
	if "`continuous'"=="" & "`dummy'"=="" & "`unordered'"==""{
		dis in green "There is no covariate and, therefore, the cross-validation cannot be done."
		if "`generate'"!=""{
			dis in green "The unconditional mean is the mean squared error minimizing estimator."
			quietly sum `varlist' if `touse'
			quietly replace `generate'=r(mean) if `touse'
		}
		return local depvar "`varlist'"
		return scalar N=`obs'
	}
	else{
		if "`bandwidth'"==""{
			local bandwidth=.
		}
		if "`continuous'"==""{
			local bandwidth=.
		}
		if "`dummy'"=="" & "`unordered'"==""{
			local lambda=1
		}
		if "`lambda'"==""{
			local lambda=1
		}
		tempname cross_val band lam
		tokenize "`bandwidth'", parse(" ")
		local i=1
		while "`1'" != "" {
			if `1'<=0{
				di as error "Bandwidth must be strictly positive. A missing value is treated as an infinite value."
				error 499
			}
			matrix `band'=nullmat(`band')\(`1')
			mac shift 
			local i=`i'+1
		}
		tokenize "`lambda'", parse(" ")
		local i=1
		while "`1'" != "" {
			if `1'<0 | `1'>1{
				di as error "Lambda must be between 0 and 1."
				error 499
			}
			matrix `lam'=nullmat(`lam')\(`1')
			mac shift 
			local i=`i'+1
		}
		matrix `cross_val'=J(3,rowsof(`band')*rowsof(`lam'),0)
		local rb=rowsof(`band')
		local rl=rowsof(`lam')
		forvalues i=1/`rb'{
			forvalues j=1/`rl'{
				mat `cross_val'[1,(`i'-1)*rowsof(`lam')+`j']=`band'[`i',1]
				mat `cross_val'[2,(`i'-1)*rowsof(`lam')+`j']=`lam'[`j',1]
			}
		}
		if "`continuous'"!=""{
			_rmcollright `continuous'
			local continuous "`r(varlist)'"
		}
		if "`dummy'"!=""{
			_rmcollright `dummy'
			local dummy "`r(varlist)'"
		}
		if "`unordered'"!=""{	
			local index=1
			foreach x in `unordered'{
				tempvar reg`index'
				quietly tabulate `x' if `touse', generate(`reg`index'')
				drop `reg`index''1
				unab temp:`reg`index''*
				local listu "`listu' `temp'"
				local index=`index'+1
			}
			quietly _rmcollright `listu'
			local listu "`r(varlist)'"
		}
		if ("`dummy'"!="" & "`continuous'"!="") | ("`dummy'"!="" & "`unordered'"!="") | ("`continuous'"!="" & "`unordered'"!=""){
			quietly _rmcollright `dummy' `continuous' `listu'
			if "`r(dropped)'"!=""{
				di in red "The covariates are multicolinear."
				exit
			}
		}
*if kernel is missing, set kernel to epan2
		if "`kernel'"==""{
			local kernel "epan2"
		} 
		if "`continuous'"==""{
			local continuous "empty"
		}
		if "`dummy'"==""{
			local dummy "empty"
		}
		if "`unordered'"==""{
			local unordered "empty"
			local listu "empty"
		}
		tempvar pred
		quietly gen `pred'=.
		local cc=colsof(`cross_val')
		if `cc'==1{
			mat `cross_val'[3,1]=.
			local optl=`cross_val'[2,1]
			local optb=`cross_val'[1,1]
			local bestfit=.
		}
		else{
			local bestfit=.
			forvalues i=1/`cc'{
				local h=`cross_val'[1,`i']
				local l=`cross_val'[2,`i']
				if "`logit'"==""{
					mata loclincv("`varlist'","`continuous'","`dummy'","`unordered'","`listu'","`kernel'",`h',`l',"`touse'","`pred'",1,"`exp'")
				}
				else if "`mata_opt'"==""{
					mata loclog1cv("`varlist'","`continuous'","`dummy'","`unordered'","`listu'","`kernel'",`h',`l',"`touse'","`pred'",1,"`exp'")
				}
				else{
					mata loclogcv("`varlist'","`continuous'","`dummy'","`unordered'","`listu'","`kernel'",`h',`l',"`touse'","`pred'",1,"`exp'")
				}
				tempvar temp1
				quietly generate `temp1'=(`varlist'-`pred')^2 if `touse'
				quietly sum `temp1'
				mat `cross_val'[3,`i']=r(mean)
				if r(mean)<`bestfit'{
					local bestfit=r(mean)
					local optl=`l'
					local optb=`h'
				}
			}
		}
		if "`generate'"!=""{
			quietly generate `generate'=.
			if "`logit'"!=""{
				if "`mata_opt'"==""{
					mata loclog1cv("`varlist'","`continuous'","`dummy'","`unordered'","`listu'","`kernel'",`optb',`optl',"`touse'","`generate'",0,"`exp'")
				}
				else{
					mata loclogcv("`varlist'","`continuous'","`dummy'","`unordered'","`listu'","`kernel'",`optb',`optl',"`touse'","`generate'",0,"`exp'")
				}
			}
			else if (`optb'<. & "`continuous'"!="empty") | (`optl'<1 & ("`dummy'"!="empty" | "`unordered'"!="empty")){
				mata loclincv("`varlist'","`continuous'","`dummy'","`unordered'","`listu'","`kernel'",`optb',`optl',"`touse'","`generate'",0,"`exp'")
			} 
			else {
				tempname temp3
				if "`dummy'"!="empty"{
					local globallist "`dummy'"
				}
				if "`continuous'"!="empty"{
					local globallist "`globallist' `continuous'"
				}
				if "`unordered'"!="empty"{
					local globallist "`globallist' `listu'"
				}
				quietly regress `varlist' `globallist' if `touse'
				quietly predict `temp3' if `touse'
				quietly replace `generate'=`temp3' if `touse'
				drop `temp3'
			}
		}
*display the results
		if `cc'>1{
			dis
			dis in green "Leave-one-out cross-validation"
			local k=1
			dis as text "{hline 20}" "{c TT}" "{hline 20}" "{c TT}" "{hline 25}"
			dis as text _column(6) "Bandwidth" _column(21) "{c |}" _column(28) "Lambda"  _column(42) "{c |}" _column(46) "Mean Squared Error"
			dis as text "{hline 20}" "{c +}" "{hline 20}" "{c +}" "{hline 25}"
			while `k'<=`cc'{
				if `cross_val'[1,`k']<.{
					dis as text _column(9) %17s `cross_val'[1,`k'] as text _column(21) "{c |}" as text _column(30) %17s `cross_val'[2,`k'] as text _column(42) "{c |}" as result _column(49) %17s `cross_val'[3,`k']
				}
				else{
					dis as text _column(9) "infinity" as text _column(21) "{c |}" as text _column(30) %17s `cross_val'[2,`k'] as text _column(42) "{c |}" as result _column(49) %17s `cross_val'[3,`k']
				}
				if `k'==`cc' {
					dis as text "{hline 20}" "{c BT}" "{hline 20}" "{c BT}" "{hline 25}" 
				}
				local k=`k'+1
			}
		}
		dis
		dis as text "Among the grid of values tested, the optimal bandwidth is " as result "`optb'" as text " and the optimal lambda is " as result "`optl'" as text "."
		if "`generate'"!=""{
			dis
			dis as text "The fitted values obtained with the optimal smoothing parameters have been saved in `generate'."
		}
		return matrix cross_valid=`cross_val'
		return scalar optl=`optl'
		return scalar optb=`optb'
		return local depvar "`varlist'"
		return local kernel "`kernel'"
		return scalar N=`obs'
		if "`logit'"==""{
			return local method "Local linear regression"
		}
		else {
			return local method "Local logit regression"
			if "`mata_opt'"==""{
				return local optimization "Simple Gauss-Newton algorithm"
			}
			else{
				return local optimization "Official Mata optimizer optimize"
			}
		}
		return scalar best_mse=`bestfit'
	}
	return local command "locreg"
end

*Mata function estimating the propensity score by local linear regression
version 9.2
mata void loclincv(string scalar dep, string scalar continuous, string scalar dummy, string scalar unordered, string scalar unord_list, string scalar kernel, real scalar bandwidth, real scalar lambda, string scalar touse, string scalar out, real scalar cv, string scalar weight)
{
//Variable declarations
	real colvector y, weights, pred, sel, w, yt, wt
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
	weights=st_data(.,weight,touse)
	nc=cols(xc)
	nd=cols(xd)
	nu=cols(xuk)
	pred=J(n,1,.)
	sel=(1..n)'
	for(i=1; i<=n; i++){
		h1=bandwidth
		l1=lambda
		if(cv==1){
			if(i>1){
				if(i<n) sel=(1..(i-1))'\((i+1)..n)'
				else sel=(1..(n-1))'
			}
			else sel=(2..n)'
		}
		mkernel((xd,xuk)[sel,.],xc[sel,.],xur[sel,.],(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n-cv,nd,nc,nu,w=.,reg=.,weights[sel])
		dettemp=det(reg'reg)
		while(dettemp<1e-7 & h1<100 & h1>0){
			h1=h1*1.05
			mkernel((xd,xuk)[sel,.],xc[sel,.],xur[sel,.],(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n-cv,nd,nc,nu,w=.,reg=.,weights[sel])
			dettemp=det(reg'reg)
		}
		if(dettemp<1e-7){
			h1=1e10
			l1=1
			mkernel((xd,xuk)[sel,.],xc[sel,.],xur[sel,.],(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n-cv,nd,nc,nu,w=.,reg=.,weights[sel])
		}
		yt=select(y[sel,.],w)
		wt=select(w,w)
		pred[i,1]=(invsym((reg:*wt)'reg)*(reg:*wt)'yt)[1,1]
	}
	st_store(.,out,touse,pred)
}

*Mata function estimating the propensity score by local logit, optimization using Stata 10 optimizer
version 9.2
mata void loclogcv(string scalar dep, string scalar continuous, string scalar dummy, string scalar unordered, string scalar unord_list, string scalar kernel, real scalar bandwidth, real scalar lambda, string scalar touse, string scalar out, real scalar cv, string scalar weight)
{
//Variable declarations
	real colvector y, weights, pred, sel, w, yt, wt
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
	weights=st_data(.,weight,touse)
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
	sel=(1..n)'
	for(i=1; i<=n; i++){
		if(cv==1){
			if(i>1){
				if(i<n) sel=(1..(i-1))'\((i+1)..n)'
				else sel=(1..(n-1))'
			}
			else sel=(2..n)'
		}
		h1=bandwidth
		l1=lambda
		mkernel((xd,xuk)[sel,.],xc[sel,.],xur[sel,.],(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n-cv,nd,nc,nu,w=.,reg=.,weights[sel])
		dettemp=det(reg'reg)
		while(dettemp<1e-7 & h1<100 & h1>0){
			h1=h1*1.05
			mkernel((xd,xuk)[sel,.],xc[sel,.],xur[sel,.],(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n-cv,nd,nc,nu,w=.,reg=.,weights[sel])
			dettemp=det(reg'reg)
		}
		if(dettemp<1e-7){
			h1=1e10
			l1=1
			mkernel((xd,xuk)[sel,.],xc[sel,.],xur[sel,.],(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n-cv,nd,nc,nu,w=.,reg=.,weights[sel])
		}
		ret=1
		while(ret!=0){
			yt=select(y[sel,.],w)
			wt=select(w,w)
			optimize_init_params(S,((invsym((reg:*wt)'reg)*(reg:*wt)'yt))')
			optimize_init_argument(S, 1, reg)
			optimize_init_argument(S, 2, yt)
			optimize_init_argument(S, 3, wt)
			ret = _optimize(S)
			if(ret!=0){
				if(h1<100 & h1>0){
					h1=h1*1.05
				}
				else{
					h1=1e10
					l1=1
				}
				mkernel((xd,xuk)[sel,.],xc[sel,.],xur[sel,.],(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n-cv,nd,nc,nu,w=.,reg=.,weights[sel])
			}
		}
		pred[i,1]=logisticcdf(optimize_result_params(S)[1])
	}
	st_store(.,out,touse,pred)
}

*Mata function estimating the propensity score by local logit, optimization using self written codes
version 9.2
mata void loclog1cv(string scalar dep, string scalar continuous, string scalar dummy, string scalar unordered, string scalar unord_list, string scalar kernel, real scalar bandwidth, real scalar lambda, string scalar touse, string scalar out, real scalar cv, string scalar weight)
{
//Variable declarations
	real colvector y, weights, pred, sel, w, yt, wt
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
	weights=st_data(.,weight,touse)
	nc=cols(xc)
	nd=cols(xd)
	nu=cols(xuk)
	pred=J(n,1,0)
	sel=(1..n)'
	for(i=1; i<=n; i++){
		if(cv==1){
			if(i>1){
				if(i<n) sel=(1..(i-1))'\((i+1)..n)'
				else sel=(1..(n-1))'
			}
			else sel=(2..n)'
		}
		h1=bandwidth
		l1=lambda
		mkernel((xd,xuk)[sel,.],xc[sel,.],xur[sel,.],(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n-cv,nd,nc,nu,w=.,reg=.,weights[sel])
		dettemp=det(reg'reg)
		while(dettemp<1e-7 & h1<100 & h1>0){
			h1=h1*1.05
			mkernel((xd,xuk)[sel,.],xc[sel,.],xur[sel,.],(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n-cv,nd,nc,nu,w=.,reg=.,weights[sel])
			dettemp=det(reg'reg)
		}
		if(dettemp<1e-7){
			h1=1e10
			l1=1
			mkernel((xd,xuk)[sel,.],xc[sel,.],xur[sel,.],(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n-cv,nd,nc,nu,w=.,reg=.,weights[sel])
		}
		convergence=.
		while(convergence!=0){
			convergence=.
			yt=select(y[sel,.],w)
			wt=select(w,w)
			bt = intlog(yt,reg,wt,convergence)
			if(convergence!=0){
				if(h1<100 & h1>0){
					h1=h1*1.05
				}
				else{
					h1=1e10
					l1=1
				}
				mkernel((xd,xuk)[sel,.],xc[sel,.],xur[sel,.],(xd[i,.],xuk[i,.],xc[i,.]),xur[i,.],kernel,h1,l1,n-cv,nd,nc,nu,w=.,reg=.,weights[sel])
			}
		}
		pred[i,1]=logisticcdf(bt[1])
	}
	st_store(.,out,touse,pred)
}

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
mata void mkernel(real matrix regd, real matrix regc, real matrix regu, real rowvector ev, real rowvector evu, string scalar kernel, real scalar band, real scalar lambda, real scalar n, real scalar nd, real scalar nc, real scalar nu, real colvector w, real matrix reg, real colvector weights)
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
	w=weights
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

*Mata, logistic distribution
version 9.2
mata real colvector logisticcdf(real colvector x) return(1:/(1:+exp(-x)))

*Mata, objective function of the weighted logit estimator
version 9.2
mata void lnwlogit(real scalar todo, real rowvector p, real matrix x, real colvector y, real colvector w, real colvector lnf, real matrix S, real matrix H)
{
//Variable declaration
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
