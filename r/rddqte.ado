*Version 1.0.1 27july2010

program rddqte, eclass
	version 9.2
	capt findfile lmoremata.mlib
	if _rc {
      	di as error "-moremata- is required; type {stata ssc install moremata} and restart Stata."
		exit
	}
	syntax varlist(min=3 max=3) [if] [in] , Bandwidth(real) [Discontinuity(string) Report(string) CONtrol(varlist) NReg(real 100) Quantiles(numlist >0 <1 sort) Kernel(string) Level(cilevel) noVAR_qte COV_qte var_dte var_lte var_summary]
	marksample touse
	gettoken dep varlist : varlist
	gettoken treat varlist : varlist
	gettoken z varlist : varlist
	if "`discontinuity'"=="" local discontinuity=0
	capture confirm numeric variable `discontinuity'
	if _rc>0{
		capture 
		local disc=`discontinuity'
		tempvar discontinuity
		quietly generate `discontinuity'=`disc'
	}
	else{
		markout `discontinuity'
	}
	tempname results variance bq vq bd vd bl vl bs vs quants dte lte qte summary nregs levels
	quietly sum `touse'
	local obs=r(N)
	sca `nregs'=round(`nreg')
	if `nregs'<=0{
		dis as error "The option nreg must contain a positive integer."
		exit
	}
	if "`kernel'"==""{
		local kernel "epan2"
	} 
	if "`quantiles'"==""{
		local quantiles "0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9"
	}
	tokenize "`quantiles'", parse(" ")
	local i=1
	while "`1'" != "" {
		matrix `quants'=nullmat(`quants')\(`1')
		mac shift 
		local i=`i'+1
	}
	local nq=rowsof(`quants')
	if "`report'"==""{
		local report "qte"
	}
	tokenize "`report'", parse(" ")
	while "`1'" != "" {
		if "`1'"=="all"{
			local rep_qte=1
			local rep_dte=1
			local rep_lte=1
			local rep_stat=1
		}
		else if "`1'"=="qte"{
			local rep_qte=1
		}
		else if "`1'"=="dte"{
			local rep_dte=1
		}
		else if "`1'"=="lte"{
			local rep_lte=1
		}
		else if "`1'"=="summary"{
			local rep_stat=1
		}
		mac shift 
	}
	if "`kernel'"==""{
		local kernel "epan2"
	}
	if "`control'"==""{
		mata: rddint("`dep'", "`treat'", "`touse'", "`z'", "`discontinuity'", `bandwidth', "`nregs'", "`kernel'", "`quants'", "`levels'", "`var_qte'"=="", "`cov_qte'"=="cov_qte", "`var_dte'"=="var_dte", "`var_lte'"=="var_lte", "`var_summary'"=="var_summary", "`bq'", "`vq'", "`bd'", "`vd'", "`bl'", "`vl'", "`bs'", "`vs'", "`qte'", "`dte'", "`lte'", "`summary'")
	}
	else{
		tempvar iplus fitted
		quietly generate `iplus'=(`z'>`discontinuity')
		quietly logit `iplus' `control' if `touse'
		quietly predict `fitted' if `touse'
		mata: rddint2("`fitted'", "`dep'", "`treat'", "`touse'", "`z'", "`discontinuity'", `bandwidth', "`nregs'", "`kernel'", "`quants'", "`levels'", "`var_qte'"=="", "`cov_qte'"=="cov_qte", "`var_dte'"=="var_dte", "`var_lte'"=="var_lte", "`var_summary'"=="var_summary", "`bq'", "`vq'", "`bd'", "`vd'", "`bl'", "`vl'", "`bs'", "`vs'", "`qte'", "`dte'", "`lte'", "`summary'")
	}
	local conam ""
	forvalues i=1/`nq'{
		local conam "`conam' q`i'"
	}
	mat colnames `bq'=`conam'
	mat rownames `bq'="`dep'"
	mat rownames `vq'=`conam'
	mat colnames `vq'=`conam'
	mat colnames `bl'=`conam'
	mat rownames `bl'="`dep'"
	mat rownames `vl'=`conam'
	mat colnames `vl'=`conam'
	mat rowname `bs'="`dep'"
	mat colname `bs'=mean median sd 9010range 7525range gini
	mat colname `vs'=mean median sd 9010range 7525range gini
	mat rowname `vs'=mean median sd 9010range 7525range gini
	mat rownames `qte'=`conam'
	mat rownames `lte'=`conam'
	mat colnames `qte'=q0 se_0 q1 se_1 qte se_qte
	mat colnames `dte'=d0 se_0 d1 se_1 dte se_dte
	mat colnames `lte'=l0 se_0 l1 se_1 lte se_lte
	mat colnames `summary'=s0 se_0 s1 se_1 ste se_ste
	mat rowname `summary'=mean median sd 9010range 7525range gini
	local conam ""
	local nreg=`nregs'
	forvalues i=1/`nreg'{
		local conam "`conam' d`i'"
	}
	mat colnames `bd'=`conam'
	mat rownames `bd'="`dep'"
	mat rownames `vd'=`conam'
	mat colnames `vd'=`conam'
	mat rownames `dte'=`conam'
	mat rownames `levels'=`conam'
	mat `results'=`bq'
	mat `variance'=`vq'
	tempname tempsca tempsca2
	forvalues i=1/`nq'{
		sca `tempsca'=`quants'[`i',1]
		sca `tempsca2'=round(`tempsca',0.001)
		if `i'==1{
			local qu=string(`tempsca2')
		}
		else{
			local qu="`qu' " + string(`tempsca2')
		}
	}
	dis
	dis in green "Quantile treatment effects based on the regression discontinuity design "
	dis "Estimator suggested in Froelich and Melly (2010)"
	dis
	dis "Dependent variable:" _column(30) "`dep'"
	dis "Treatment variable:" _column(30) "`treat'"
	if "`control'"!=""{
		dis "Control variable(s):" _column(30) "`control'"
	}
	dis "Running variable:" _column(30) "`z'"
	if "`disc'"!=""{
		dis "Discontinuity:" _column(30) "`disc'"
	}
	else{
		dis "Discontinuity:" _column(30) "saved in `discontinuity'"
	}
	dis "Bandwidth:" _column(30) "`bandwidth'"
	dis "Kernel function:" _column(30) "`kernel'"
	dis "Number of observations:" _column(30)  "`obs'"
	dis "Number of regressions:"	_column(30) "`nreg'"
	dis "Quantiles:" _column(30) "`qu'"
	if "`control'"!=""{
		dis
		dis "No analytic estimator for the standard errors is available."
		dis "You can try bootstraping the results (without guarantee!)."
	}
	else if "`var_qte'"=="" & "`cov_qte'"==""{
		dis
		dis "The covariances between the QTEs have note been estimated."
		dis "They have been set arbitrarily to 0."
		dis "Activate the option cov_qte if you want to test hypotheses based on several QTEs."
	}
	dis
	if "`rep_qte'"!=""{
		dis
		dis "Quantile treatment effects"
		ereturn post `bq' `vq'
		ereturn display, level(`level')
	}
	if "`rep_dte'"!=""{
		dis
		dis "Distribution treatment effects"
		cap ereturn clear
		ereturn post `bd' `vd'
		ereturn display, level(`level')
	}
	if "`rep_lte'"!=""{
		dis
		dis "Lorenz treatment effects"
		cap ereturn clear
		ereturn post `bl' `vl'
		ereturn display, level(`level')
	}
	if "`rep_stat'"!=""{
		dis
		dis "Treatment effects on several summary statistics"
		cap ereturn clear
		ereturn post `bs' `vs'
		ereturn display, level(`level')
	}
	cap ereturn clear
	ereturn post `results' `variance', depname(`dep') obs(`obs') esample(`touse') 
	ereturn matrix qte=`qte'
	ereturn matrix lte=`lte'
	ereturn matrix dte=`dte'
	ereturn matrix summary=`summary'
	ereturn matrix quantiles=`quants'
	ereturn local command "rddqte"
	ereturn local depvar "`dep'"
	ereturn local treatment "`treat'"
	ereturn local running "`z'"
	ereturn local control "`control'" 
	ereturn scalar bandwidth=`bandwidth'
	ereturn local kernel="`kernel'"
	ereturn scalar nreg=`nregs'
	ereturn matrix dist_level=`levels'
end

*Mata, weighted OLS, return the constant
mata numeric scalar lm(numeric colvector n_dep, numeric matrix reg, numeric colvector w)
{
regc=(J(rows(reg),1,1),reg):*sqrt(w)
dep=n_dep:*sqrt(w)
res=invsym(regc'regc)*(regc'dep)
return(res[1])
}

*Mata, weighted OLS, return the coefficients
mata numeric colvector lm1(numeric colvector n_dep, numeric matrix reg, numeric colvector w)
{
regc=(J(rows(reg),1,1),reg):*sqrt(w)
dep=n_dep:*sqrt(w)
res=invsym(regc'regc)*regc'dep
return(res)
}

*Mata, weighted OLS, return the variance of the constant
mata real matrix lm2(numeric colvector n_dep, numeric matrix reg, numeric colvector w)
{
regc=(J(rows(reg),1,1),reg):*sqrt(w)
dep=n_dep:*sqrt(w)
coef=invsym(regc'regc)*regc'dep
resid=dep:-regc*coef
temp=invsym(cross(regc,regc))
var=temp*cross(resid:*regc,resid:*regc)*temp
return(var[1,1])
}

*Mata, 2 OLS regressions with different y and same x, return the variances and the covariance of the constants
mata void lm3(real colvector n_dep1, real colvector n_dep2, real matrix reg, real colvector w, real scalar var1, real scalar var2, real scalar cov)
{
	regc=(J(rows(reg),1,1),reg):*sqrt(w)
	dep1=n_dep1:*sqrt(w)
	dep2=n_dep2:*sqrt(w)
	coef1=invsym(regc'regc)*regc'dep1
	coef2=invsym(regc'regc)*regc'dep2
	resid1=dep1:-regc*coef1
	resid2=dep2:-regc*coef2
	temp=invsym(cross(regc,regc))
	temp1=cross(resid1:*regc,resid1:*regc)
	temp2=cross(resid1:*regc,resid2:*regc)
	temp3=cross(resid2:*regc,resid2:*regc)
	var=(temp*temp1*temp,temp*temp2*temp)\(temp*temp2*temp,temp*temp3*temp)
	var1=var[1,1]
	var2=var[3,3]
	cov=var[1,3]
}

*************************************************************************************
* Rearrangement (due to Chernozhukov et al), alternative for insertionsort function *
*************************************************************************************
mata real rearrange(real colvector v){
	n = rows(v)
	F = J(n,1,0)
	vs = J(n,1,0)
	for( i=1 ; i<=n ; i++ ){
		F[i] = colsum(v :<= v[i])
	}
	for( i=1 ; i<=n ; i++ ){
		vs[i] = colmin(select(v,F:>=i))
	}
	return(vs)
}

*************************************************************************************
* Clean Distribution Function                                                       *
*************************************************************************************
mata real cleandist(real colvector v){
	n = rows(v)
	for( i=1 ; i<=n ; i++ ){
		if( v[i] < 0 ){
			v[i] = 0
		}
		if( v[i] > 1 ){
			v[i] = 1
		}
	}
	return(v)
}

*************************************************************************************
* Get Inverse (Quantile Function)                                                   *
*************************************************************************************
mata numeric getquantile(numeric colvector y, numeric colvector F, numeric colvector TAU_)
{
	real colvector Q
	NumRows = rows(y)
	NumTau = rows(TAU_)
	for( i=1 ; i<=NumTau ; i++ ){
		Q = Q \ y[min((colsum( F :<= TAU_[i] )+1,NumRows))]
	}
	return(Q)
}

mata void rddint(string scalar dep, string scalar treat, string scalar touse, string scalar running, string scalar discontinuity, real scalar bandwidth, string scalar nregs, string scalar kernel, string scalar quantss, string scalar levels, real scalar var_qte, real scalar cov_qte, real scalar var_dte, real scalar var_lte, real scalar var_stats, string scalar qtes, string scalar varqtes, string scalar dtes, string scalar vardtes, string scalar ltes, string scalar varltes, string scalar stes, string scalar varstes, string scalar quantiles, string scalar distributions, string scalar lorenzs, string scalar statistics)
{
	quants=st_matrix(quantss)
	if(var_stats==1){
		if(sum(quants:==0.1)==0){
			quants=quants\0.1
		}
		if(sum(quants:==0.25)==0){
			quants=quants\0.25
		}
		if(sum(quants:==0.5)==0){
			quants=quants\0.5
		}
		if(sum(quants:==0.75)==0){
			quants=quants\0.75
		}
		if(sum(quants:==0.9)==0){
			quants=quants\0.9
		}
	}
	quants=sort(quants,1)
	st_matrix(quantss,quants)
	y=st_data(.,dep,touse)
	d=st_data(.,treat,touse)
	z=st_data(.,running,touse)
	disc=st_data(.,discontinuity,touse)
	nq=rows(quants)
	z=z:-disc
	iplus=z:>0
	if(bandwidth<.){
		w=mm_kern(kernel,z:/bandwidth) 
	} else w=J(rows(z),1,1)
	w1=select(w,iplus)
	w0=select(w,1:-iplus)
	dep0=select(y,(1:-iplus))
	dep1=select(y,iplus)
	z0=select(z,1:-iplus)
	z1=select(z,iplus)
	treat1=select(d,iplus)
	treat0=select(d,(1:-iplus))
	nreg=st_numscalar(nregs)
	if(nreg<.){
		level=uniqrows(mm_quantile(y,w,(0,(1..(nreg-2)):/(nreg-2):-0.5/(nreg-2),1))')
	}
	else{
		level=uniqrows(y)
	}
	nreg=rows(level)
	st_numscalar(nregs,nreg)
	st_matrix(levels,level)
	dist00=dist01=dist11=dist10=J(nreg,1,.)
	d0=lm(treat0,z0,w0)
	d1=lm(treat1,z1,w1)
	Pc=d1-d0
	for(i=1;i<=(nreg);i++){
		dist00[i]=lm((1:-treat0):*(dep0:<=level[i]),z0,w0)
		dist01[i]=lm((1:-treat1):*(dep1:<=level[i]),z1,w1)
		dist11[i]=lm(treat1:*(dep1:<=level[i]),z1,w1)
		dist10[i]=lm(treat0:*(dep0:<=level[i]),z0,w0)
	}
	dist1=(dist11:-dist10):/Pc
	dist0=(dist00:-dist01):/Pc
	dist1=cleandist(rearrange(dist1))
	dist0=cleandist(rearrange(dist0))
	q0=getquantile(level,dist0,quants)
	q1=getquantile(level,dist1,quants)
	dte=J(nreg,6,.)
	dte[.,1]=dist0
	dte[.,3]=dist1
	dte[.,5]=dist1:-dist0
	qte=J(nq,6,.)
	qte[.,1]=q0
	qte[.,3]=q1
	qte[.,5]=q1:-q0
	for(i=1;i<=nq;i++){
		lor0=runningsum(q0):/sum(q0)
		lor1=runningsum(q1):/sum(q1)
	}
	lte=J(nq,6,.)
	lte[.,1]=lor0
	lte[.,3]=lor1
	lte[.,5]=lor1:-lor0
	dispersion=J(6,6,.)
	q10=sum(quants:<=0.1)
	q25=sum(quants:<=0.25)
	q50=sum(quants:<=0.5)
	q75=sum(quants:<=0.75)
	q90=sum(quants:<=0.9)
	dispersion[1,1]=mean(q0)
	dispersion[1,3]=mean(q1)
	dispersion[1,5]=dispersion[1,3]-dispersion[1,1]
	dispersion[2,1]=q0[q50]
	dispersion[2,3]=q1[q50]
	dispersion[2,5]=dispersion[2,3]-dispersion[2,1]
	dispersion[3,1]=variance(q0):^0.5
	dispersion[3,3]=variance(q1):^0.5
	dispersion[3,5]=dispersion[3,3]-dispersion[3,1]
	dispersion[4,1]=q0[q90]-q0[q10]
	dispersion[4,3]=q1[q90]-q1[q10]
	dispersion[4,5]=dispersion[4,3]-dispersion[4,1]
	dispersion[5,1]=q0[q75]-q0[q25]
	dispersion[5,3]=q1[q75]-q1[q25]
	dispersion[5,5]=dispersion[5,3]-dispersion[5,1]
	dispersion[6,1]=1-2*mean(lor0)
	dispersion[6,3]=1-2*mean(lor1)
	dispersion[6,5]=dispersion[6,3]-dispersion[6,1]
	vardte=J(nreg,nreg,0)
	if(var_dte==1){
		for(i=1;i<=nreg;i++){
			lm3((dep1:<=level[i]):*treat1:-dist1[i]:*treat1,(dep1:<=level[i]):*(treat1:-1):-dist0[i]:*(treat1:-1),z1,w1,varf1plus=.,varf0plus=.,covplus=.)
			lm3((dep0:<=level[i]):*treat0:-dist1[i]:*treat0,(dep0:<=level[i]):*(treat0:-1):-dist0[i]:*(treat0:-1),z0,w0,varf1minus=.,varf0minus=.,covminus=.)
			dte[i,4]=((varf1plus+varf1minus)/Pc^2):^0.5
			dte[i,2]=((varf0plus+varf0minus)/Pc^2):^0.5
			vardte[i,i]=(varf1plus+varf1minus-2*(covplus+covminus))/Pc^2
			dte[i,6]=(dte[i,4]+dte[i,2]-2*(covplus+covminus)/Pc^2):^0.5
		}
	}
	st_matrix(distributions,dte)
	st_matrix(dtes,dte[.,5]')
	st_matrix(vardtes,vardte)
	varqte=J(nq,nq,0)
	if(var_qte==1 | cov_qte==1 | var_lte==1 | var_stats==1){
		varq00=varq11=varq01=varq10=J(nq,nq,.)
		quantsv=(1..rows(select(y,w:>0)))':/rows(select(y,w:>0))
		q1v=getquantile(level,dist1,quantsv\quants)
		q0v=getquantile(level,dist0,quantsv\quants)
		fy1=_kdens(q1v,1,q1)
		fy0=_kdens(q0v,1,q0)
		for(i=1;i<=rows(q0);i++){
			lm3((dep1:<=q1[i]):*treat1:-quants[i]:*treat1,(dep1:<=q0[i]):*(treat1:-1):-quants[i]:*(treat1:-1),z1,w1,varf1plus=.,varf0plus=.,covplus=.)
			lm3((dep0:<=q1[i]):*treat0:-quants[i]:*treat0,(dep0:<=q0[i]):*(treat0:-1):-quants[i]:*(treat0:-1),z0,w0,varf1minus=.,varf0minus=.,covminus=.)
			varq11[i,i]=(varf1plus+varf1minus)/Pc^2/fy1[i]^2
			varq00[i,i]=(varf0plus+varf0minus)/Pc^2/fy0[i]^2
			varq01[i,i]=varq10[i,i]=(covplus+covminus)/Pc^2/fy0[i]/fy1[i]
		}
		for(i=1;i<=nq;i++){
			varqte[i,i]=varq11[i,i]+varq00[i,i]-varq01[i,i]-varq10[i,i]
		}
		if(cov_qte==1 | var_lte==1 | var_stats==1){
			for(i=1;i<=nq;i++){
				for(j=1;j<i;j++){
					lm3((dep1:<=q1[i]):*treat1:-quants[i]:*treat1,(dep1:<=q1[j]):*treat1:-quants[j]:*treat1,z1,w1,varf1plus=.,varf0plus=.,covplus=.)
					lm3((dep0:<=q1[i]):*treat0:-quants[i]:*treat0,(dep0:<=q1[j]):*treat0:-quants[j]:*treat0,z0,w0,varf1minus=.,varf0minus=.,covminus=.)
					varq11[i,j]=(covplus+covminus)/Pc^2/fy1[i]/fy1[j]
					lm3((dep1:<=q0[i]):*(treat1:-1):-quants[i]:*(treat1:-1),(dep1:<=q1[j]):*treat1:-quants[j]:*treat1,z1,w1,varf1plus=.,varf0plus=.,covplus=.)
					lm3((dep0:<=q0[i]):*(treat0:-1):-quants[i]:*(treat0:-1),(dep0:<=q1[j]):*treat0:-quants[j]:*treat0,z0,w0,varf1plus=.,varf0plus=.,covminus=.)
					varq01[i,j]=(covplus+covminus)/Pc^2/fy0[i]/fy1[j]
					lm3((dep1:<=q1[i]):*treat1:-quants[i]:*treat1,(dep1:<=q0[j]):*(treat1:-1):-quants[j]:*(treat1:-1),z1,w1,varf1plus=.,varf0plus=.,covplus=.)
					lm3((dep0:<=q1[i]):*treat0:-quants[i]:*treat0,(dep0:<=q0[j]):*(treat0:-1):-quants[j]:*(treat0:-1),z0,w0,varf1minus=.,varf0minus=.,covminus=.)
					varq10[i,j]=(covplus+covminus)/Pc^2/fy0[j]/fy1[i]
					lm3((dep1:<=q0[i]):*(treat1:-1):-quants[i]:*(treat1:-1),(dep1:<=q0[j]):*(treat1:-1):-quants[j]:*(treat1:-1),z1,w1,varf1plus=.,varf0plus=.,covplus=.)
					lm3((dep0:<=q0[i]):*(treat0:-1):-quants[i]:*(treat0:-1),(dep0:<=q0[j]):*(treat0:-1):-quants[j]:*(treat0:-1),z0,w0,varf1minus=.,varf0minus=.,covminus=.)
					varq00[i,j]=(covplus+covminus)/Pc^2/fy0[j]/fy0[i]
				}
			}
			_makesymmetric(varq00)
			_makesymmetric(varq11)
			for(i=1;i<=nq;i++){
				for(j=(i+1);j<=nq;j++){
					lm3((dep1:<=q0[i]):*(treat1:-1):-quants[i]:*(treat1:-1),(dep1:<=q1[j]):*treat1:-quants[j]:*treat1,z1,w1,varf1plus=.,varf0plus=.,covplus=.)
					lm3((dep0:<=q0[i]):*(treat0:-1):-quants[i]:*(treat0:-1),(dep0:<=q1[j]):*treat0:-quants[j]:*treat0,z0,w0,varf1plus=.,varf0plus=.,covminus=.)
					varq01[i,j]=(covplus+covminus)/Pc^2/fy0[i]/fy1[j]
					lm3((dep1:<=q1[i]):*treat1:-quants[i]:*treat1,(dep1:<=q0[j]):*(treat1:-1):-quants[j]:*(treat1:-1),z1,w1,varf1plus=.,varf0plus=.,covplus=.)
					lm3((dep0:<=q1[i]):*treat0:-quants[i]:*treat0,(dep0:<=q0[j]):*(treat0:-1):-quants[j]:*(treat0:-1),z0,w0,varf1minus=.,varf0minus=.,covminus=.)
					varq10[i,j]=(covplus+covminus)/Pc^2/fy0[j]/fy1[i]
				}
			}
			for(i=1;i<=nq;i++){
				for(j=1;j<i;j++){
					varqte[i,j]=varq11[i,j]+varq00[i,j]-varq01[i,j]-varq10[j,i]
				}
			}
		}
		_makesymmetric(varqte)
		qte[.,2]=diagonal(varq00):^0.5
		qte[.,4]=diagonal(varq11):^0.5
		qte[.,6]=diagonal(varqte):^0.5
	}
	st_matrix(quantiles,qte)
	st_matrix(qtes,(q1:-q0)')
	st_matrix(varqtes,varqte)
	varlte=J(nq,nq,0)
	if(var_lte==1 | var_stats==1){
		varl00=varl11=varl01=varl10=J(nq,nq,.)
		for(i=1;i<=nq;i++){
			for(j=1;j<=nq;j++){
				varl00[i,j]=1/mean(q0)/mean(q0)*(sum(varq00[1..i,1..j])/nq^2+lor0[i]*lor0[j]*sum(varq00)/nq^2-lor0[i]*sum(varq00[1..j,.])/nq^2-lor0[j]*sum(varq00[.,1..i])/nq^2)
				varl11[i,j]=1/mean(q1)/mean(q1)*(sum(varq11[1..i,1..j])/nq^2+lor1[i]*lor1[j]*sum(varq11)/nq^2-lor1[i]*sum(varq11[1..j,.])/nq^2-lor1[j]*sum(varq11[.,1..i])/nq^2)
				varl01[i,j]=1/mean(q0)/mean(q1)*(sum(varq01[1..i,1..j])/nq^2+lor0[i]*lor1[j]*sum(varq01)/nq^2-lor0[i]*sum(varq01[1..j,.])/nq^2-lor1[j]*sum(varq01[.,1..i])/nq^2)
				varl10[i,j]=1/mean(q1)/mean(q0)*(sum(varq10[1..i,1..j])/nq^2+lor1[i]*lor0[j]*sum(varq10)/nq^2-lor1[i]*sum(varq10[1..j,.])/nq^2-lor0[j]*sum(varq10[.,1..i])/nq^2)
			}
		}
		lte[.,2]=diagonal(varl00):^0.5
		lte[.,4]=diagonal(varl11):^0.5
		lte[.,6]=(diagonal(varl00):+diagonal(varl11):-2*diagonal(varl01)):^0.5
		for(i=1;i<=nq;i++){
			varlte[i,i]=lte[i,6]^2
		}
	}
	st_matrix(lorenzs,lte)
	st_matrix(ltes,lte[.,5]')
	st_matrix(varltes,varlte)
	varste=J(6,6,0)
	if(var_stats==1){
		var11=var00=var01=var10=J(nq,nq,.)
		for(i=1;i<=nq;i++){
			for(j=1;j<=nq;j++){
				var11[i,j]=(varq11[i,j]+sum(varq11)/nq^2-sum(varq11[i,.])/nq-sum(varq11[.,j])/nq)*4*(q1[i]-mean(q1))*(q1[j]-mean(q1))
				var00[i,j]=(varq00[i,j]+sum(varq00)/nq^2-sum(varq00[i,.])/nq-sum(varq00[.,j])/nq)*4*(q0[i]-mean(q0))*(q0[j]-mean(q0))
				var10[i,j]=(varq10[i,j]+sum(varq10)/nq^2-sum(varq10[i,.])/nq-sum(varq10[.,j])/nq)*4*(q1[i]-mean(q1))*(q0[j]-mean(q0))
				var01[i,j]=(varq01[i,j]+sum(varq01)/nq^2-sum(varq01[i,.])/nq-sum(varq01[.,j])/nq)*4*(q0[i]-mean(q0))*(q1[j]-mean(q1))
			}
		}
		dispersion[1,2]=(sum(varq00)/nq^2)^0.5
		dispersion[1,4]=(sum(varq11)/nq^2)^0.5
		dispersion[1,6]=(sum(varq11)/nq^2+sum(varq00)/nq^2-sum(varq10)/nq^2-sum(varq01)/nq^2)^0.5
		dispersion[2,2]=varq00[q50,q50]^0.5
		dispersion[2,4]=varq11[q50,q50]^0.5
		dispersion[2,6]=(varq00[q50,q50]+varq11[q50,q50]-varq01[q50,q50]-varq10[q50,q50])^0.5
		dispersion[3,2]=(sum(var00)/nq^2)^0.5
		dispersion[3,4]=(sum(var11)/nq^2)^0.5
		dispersion[3,6]=(dispersion[3,2]^2+dispersion[3,4]^2-sum(var10)/nq^2-sum(var01)/nq^2)^0.5
		dispersion[4,2]=(varq00[q90,q90]+varq00[q10,q10]-2*varq00[q90,q10])^0.5
		dispersion[4,4]=(varq11[q90,q90]+varq11[q10,q10]-2*varq11[q90,q10])^0.5
		dispersion[4,6]=(dispersion[4,2]^2+dispersion[4,4]^2-2*(varq10[q90,q90]-varq10[q90,q10]-varq10[q10,q90]+varq10[q10,q10]))^0.5
		dispersion[5,2]=(varq00[q75,q75]+varq00[q25,q25]-2*varq00[q75,q25])^0.5
		dispersion[5,4]=(varq11[q75,q75]+varq11[q25,q25]-2*varq11[q75,q25])^0.5
		dispersion[5,6]=(dispersion[5,2]^2+dispersion[5,4]^2-2*(varq10[q75,q75]-varq10[q75,q25]-varq10[q25,q75]+varq10[q25,q25]))^0.5
		dispersion[6,2]=(4*sum(varl00)/nq^2)^0.5
		dispersion[6,4]=(4*sum(varl11)/nq^2)^0.5
		dispersion[6,6]=(dispersion[6,2]^2+dispersion[6,4]^2-4*sum(varl01)/nq^2-4*sum(varl10)/nq^2)^0.5
		for(i=1;i<=6;i++){
			varste[i,i]=dispersion[i,6]^2
		}
	}
	st_matrix(statistics,dispersion)
	st_matrix(stes,dispersion[.,5]')
	st_matrix(varstes,varste)
}

*qte with covariates
mata void rddint2(string scalar props, string scalar dep, string scalar treat, string scalar touse, string scalar running, string scalar discontinuity, real scalar bandwidth, string scalar nregs, string scalar kernel, string scalar quantss, string scalar levels, real scalar var_qte, real scalar cov_qte, real scalar var_dte, real scalar var_lte, real scalar var_stats, string scalar qtes, string scalar varqtes, string scalar dtes, string scalar vardtes, string scalar ltes, string scalar varltes, string scalar stes, string scalar varstes, string scalar quantiles, string scalar distributions, string scalar lorenzs, string scalar statistics)
{
	quants=st_matrix(quantss)
	if(var_stats==1){
		if(sum(quants:==0.1)==0){
			quants=quants\0.1
		}
		if(sum(quants:==0.25)==0){
			quants=quants\0.25
		}
		if(sum(quants:==0.5)==0){
			quants=quants\0.5
		}
		if(sum(quants:==0.75)==0){
			quants=quants\0.75
		}
		if(sum(quants:==0.9)==0){
			quants=quants\0.9
		}
	}
	quants=sort(quants,1)
	st_matrix(quantss,quants)
	nq=rows(quants)
	y=st_data(.,dep,touse)
	d=st_data(.,treat,touse)
	z=st_data(.,running,touse)
	prop=st_data(.,props,touse)
	disc=st_data(.,discontinuity,touse)
	z=z:-disc
	if(bandwidth<.){
		w=mm_kern(kernel,z:/bandwidth) 
	} else w=J(rows(z),1,1)
	nreg=st_numscalar(nregs)
	if(nreg<.){
		level=uniqrows(mm_quantile(y,w,(0,(1..(nreg-2)):/(nreg-2):-0.5/(nreg-2),1))')
	}
	else{
		level=uniqrows(y)
	}
	nreg=rows(level)
	st_numscalar(nregs,nreg)
	st_matrix(levels,level)
	iplus=z:>0
	wi=(iplus:-prop):/(prop:*(1:-prop))
	c1=lm(select(wi,d),select((z:*iplus,z:*(1:-iplus)),d),select(w,d))
	c0=lm(select(wi,1:-d),select((z:*iplus,z:*(1:-iplus)),1:-d),select(w,1:-d))
	dist0=dist1=J(nreg,1,.)
	for(i=1;i<=nreg;i++){
		dist1[i]=lm(select((y:<=level[i]):*wi,d),select((z:*iplus,z:*(1:-iplus)),d),select(w,d)):/c1
		dist0[i]=lm(select((y:<=level[i]):*wi,1:-d),select((z:*iplus,z:*(1:-iplus)),1:-d),select(w,1:-d)):/c0
	}
	dist1=cleandist(rearrange(dist1))
	dist0=cleandist(rearrange(dist0))
	q0=getquantile(level,dist0,quants)
	q1=getquantile(level,dist1,quants)
	dte=J(nreg,6,.)
	dte[.,1]=dist0
	dte[.,3]=dist1
	dte[.,5]=dist1:-dist0
	qte=J(nq,6,.)
	qte[.,1]=q0
	qte[.,3]=q1
	qte[.,5]=q1:-q0
	for(i=1;i<=nq;i++){
		lor0=runningsum(q0):/sum(q0)
		lor1=runningsum(q1):/sum(q1)
	}
	lte=J(nq,6,.)
	lte[.,1]=lor0
	lte[.,3]=lor1
	lte[.,5]=lor1:-lor0
	dispersion=J(6,6,.)
	q10=sum(quants:<=0.1)
	q25=sum(quants:<=0.25)
	q50=sum(quants:<=0.5)
	q75=sum(quants:<=0.75)
	q90=sum(quants:<=0.9)
	dispersion[1,1]=mean(q0)
	dispersion[1,3]=mean(q1)
	dispersion[1,5]=dispersion[1,3]-dispersion[1,1]
	dispersion[2,1]=q0[q50]
	dispersion[2,3]=q1[q50]
	dispersion[2,5]=dispersion[2,3]-dispersion[2,1]
	dispersion[3,1]=variance(q0):^0.5
	dispersion[3,3]=variance(q1):^0.5
	dispersion[3,5]=dispersion[3,3]-dispersion[3,1]
	dispersion[4,1]=q0[q90]-q0[q10]
	dispersion[4,3]=q1[q90]-q1[q10]
	dispersion[4,5]=dispersion[4,3]-dispersion[4,1]
	dispersion[5,1]=q0[q75]-q0[q25]
	dispersion[5,3]=q1[q75]-q1[q25]
	dispersion[5,5]=dispersion[5,3]-dispersion[5,1]
	dispersion[6,1]=1-2*mean(lor0)
	dispersion[6,3]=1-2*mean(lor1)
	dispersion[6,5]=dispersion[6,3]-dispersion[6,1]
	vardte=J(nreg,nreg,0)
	st_matrix(distributions,dte)
	st_matrix(dtes,dte[.,5]')
	st_matrix(vardtes,vardte)
	varqte=J(nq,nq,0)
	st_matrix(quantiles,qte)
	st_matrix(qtes,(q1:-q0)')
	st_matrix(varqtes,varqte)
	varlte=J(nq,nq,0)
	st_matrix(lorenzs,lte)
	st_matrix(ltes,lte[.,5]')
	st_matrix(varltes,varlte)
	varste=J(6,6,0)
	st_matrix(statistics,dispersion)
	st_matrix(stes,dispersion[.,5]')
	st_matrix(varstes,varste)
}


