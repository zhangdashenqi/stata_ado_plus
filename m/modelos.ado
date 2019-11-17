*! Version 1.0   (STB-54: sbe32)

cap program drop modelos
program define modelos
version 5.0
qui {
	use `1', clear
	sum casos in 36
	global yo=_result(6)
	sum orden in 36
	global to=_result(6)
	sum nhosp in 36
	global no=_result(6)
	keep if id==1
	poisson casos orden nhosp
	matrix b0=get(_b)            /* initial values matrix */
	matrix colnames b0=casos:orden casos:nhosp casos:_cons
	tempvar mui col
	tempname X
	predict `mui'
	replace `mui'=exp(`mui')
	gen double `col'=1
	mkmat `col' orden nhosp, matrix(`X')
	matrizh `mui' `X'             /* calculating the hat matrix */
	disper `mui'                  /* testing for overdispersion */
	if $t>1.64 {                  /* overdispersion present */ 
		bnmod `2'               /* negative binomial regression model */
	}
	else {                        /* no overdispersion*/
		pmodelo `2'             /* poisson regression model*/	
	}
}	
end


**POISSON REGRESSION MODEL**
cap program drop pmodelo
program define pmodelo
poisml casos orden nhosp, nolog robust cluster(ano)
matrix b=get(_b)
global mucero= exp(b[1,3]+$to*b[1,1]+$no*b[1,2])       
trend                                           /* testing the significance of the trend */

if $mucero>$m | $pvalor>0.05 {                         /*trend no significant */
	poisml casos nhosp, nolog robust cluster(ano)
	tempvar mui col
	tempname X
	predict `mui'
	replace `mui'=exp(`mui')
	gen double `col'=1
	mkmat `col' nhosp, matrix(`X')
	matrizh `mui' `X'                                /* calculating the hat matrix */
	disper `mui'                                     /* testing the overdispersion */
	if $t<1.64 {                                     /* overdispersion no present */
		lincom _cons+$no*nhosp, or         
		global mucero=$S_1                         
		global varmu=$S_2^2                        
		global fi=1
	}
	else {                                           /* overdispersion present */
		bnmod_nt `1'                           /* negative binomial regression model */
	}
}
else {                                                 /* trend significant */
	lincom _cons+$to*orden+$no*nhosp, or       
	global varmu=$S_2^2                              
	global fi=1
}
end


**NEGATIVE-BINOMIAL REGRESSION MODEL WITH TREND**
cap program drop bnmod
program define bnmod
version 5.0

**INITIAL MODEL**
	ml begin
	ml function funver1
	ml method lf
	eq casos orden nhosp
	ml model b1=casos, depv(1) from(b0)
	ml sample muestra id
	ml maximize f V
	tempvar mui col
	tempname X
	gen double `mui'=exp(b1[1,3]+b1[1,1]*orden+b1[1,2]*nhosp)
	gen double `col'=1
	mkmat `col' orden nhosp, matrix(`X')
	matrizh `mui' `X'                      /* calculating the hat matrix */
	pesos `mui' $fi                        /*calculating the weights*/

** ADJUST MODEL**
	tempvar ui
	gen double `ui'=[(casos-`mui')^2]/`mui'
	replace `ui'=`ui'*wi
	sum `ui'
	local fi=_result(18)/32
	if `fi'<=1  {                          /* overdispersion no present */
		pmodelo		               /* poisson regression model */
	}
	else {	                           /* overdispersion present */	
		ml begin
		ml function funver2
		ml method lf
		eq casos orden nhosp
		ml model b2=casos, depv(1) from(b1)
		ml sample muestra id
		ml maximize f V

		tempvar mui
		gen double `mui'=exp(b2[1,3]+b2[1,1]*orden+b2[1,2]*nhosp)
		global mucero=exp(b2[1,3]+b2[1,1]*$to+b2[1,2]*$no)
		local test=abs(b2[1,1]/sqrt(V[1,1]))     /*testing the significance of the trend*/
		local pvalor=2*(1-normprob(`test'))
		sum casos
		local m=_result(6)
		if $mucero>`m' | `pvalor'>0.05 {         /* trend no significant */
			bnmod_nt `1'                   /* negative binomial regression model */
		}

		else  {                                  /* trend significant */
			varian `mui' `1'
			global varmu=$fi*$var
		}
	}
end


**NEGATIVE-BINOMIAL REGRESSION MODEL WITHOUT TREND**
cap program drop bnmod_nt
program define bnmod_nt
version 5.0

**INITIAL VALUES**
	poisson casos nhosp 
	matrix b0=get(_b)
	matrix colnames b0=casos:nhosp casos:_cons 

**INITIAL MODEL**
	ml begin
	ml function funver1
	ml method lf
	eq casos nhosp
	ml model b1=casos , depv(1) from(b0)
	ml sample muestra id
	ml maximize f V
	tempvar mui col
	tempname X
	gen double `mui'=exp(b1[1,2]+b1[1,1]*nhosp)
	gen double `col'=1
	mkmat `col' nhosp, matrix(`X')
	matrizh `mui' `X'                 /* calculating the hat matrix */
	pesos `mui' $fi                   /* calculating the weights */
	
** ADJUST MODEL**
	tempvar ui
	gen double `ui'=[(casos-`mui')^2]/`mui'
	replace `ui'=`ui'*wi
	qui sum `ui'
	local fi=_result(18)/33
	if `fi'<=1  {                     /* overdispersion no present */
		poisml casos nhosp, nolog robust cluster(ano)
		lincom _cons+$no*nhosp, or
		global mucero=$S_1
		global varmu=$S_2^2
		global fi=1
	}
	else {                             /* overdispersion present */
		ml begin
		ml function funver2
		ml method lf
		eq casos nhosp
		ml model b2=casos , depv(1) from(b1)
		ml sample muestra id
		ml maximize f V
		tempvar mui
		gen double `mui'=exp(b2[1,2]+b2[1,1]*nhosp)
		global mucero=exp(b2[1,2]+b2[1,1]*$no)
		varian `mui' `1'
		global varmu=$fi*$var
	}
end


**PROGRAM TO CALCULATE THE HAT MATRIX**
cap program drop matrizh
program define matrizh
qui {
	tempvar mui rmui
	gen double `mui'=`1' 
	gen double `rmui'=sqrt(`mui') 
	tempname X XWX WX W RW H DH
	mkmat `mui', matrix(`W')
	matrix `W'=diag(`W')
	matrix `X'=`2' 
	matrix `XWX'=`X''*`W'
	matrix `XWX'=`XWX'*`X'
	matrix `XWX'=inv(`XWX')
	mkmat `rmui', matrix(`RW')
	matrix `RW'=diag(`RW')
	matrix `WX'=`RW'*`X'
	matrix `H'=`WX'*`XWX'
	matrix `H'=`H'*`WX''
	matrix `DH'=vecdiag(`H')
	matrix `DH'=`DH''
	cap drop hi*
	svmat `DH', names(hi)
}
end	


**PROGRAM TO TEST FOR OVERDISPERSION**
cap program drop disper
program define disper
qui {
	tempvar mui test
	gen double `mui'=`1'
	gen `test'=[(casos-`mui')^2-(1-hi)*`mui']/`mui'
	sum `test'
	global t=_result(18)/sqrt(70)
}
end

		
**PROGRAM TO TEST FOR TREND**
cap program drop trend
program define trend
qui {
	test orden
	local chi=_result(6)
	local gl=_result(3)
	global pvalor=chiprob(`gl',`chi')
	qui sum casos
	global m=_result(6)
}
end


**PROGRAM TO CALCULATE THE WEIGHTS Wi**
cap program drop pesos
program define pesos
qui {
	tempvar mui v1 v2 v3 si
	gen double `mui'=`1'
	local phi=`2'
	gen double `v1'=3*(casos^(2/3)-`mui'^(2/3))
	gen double `v2'=2*[`phi'^0.5]*[`mui'^(1/6)]*[(1-hi)^0.5]
	gen double `si'=`v1'/`v2'
	count if `si'<=1
	local a=_result(1)
	gen double `v3'=`si'^(-2)
	qui sum `v3' if `si'>1
	local b=_result(18)
	local gamma=35/(`a'+`b')
	cap drop  wi
	gen double wi=.
	replace wi=`gamma'*`v3' if `si'>1
	replace wi=`gamma' if `si'<=1 
}
end

	
**PROGRAM TO CALCULATE THE VARIANCE OF MUCERO**
cap program drop varian
program define varian
qui {
	tempname o m r ano
	matrix `r'=`2'
	mkmat col, matrix(`o') 
	mkmat ano, matrix(`ano')
	mkmat `1', matrix(`m')
	sum `1'
	local var1=_result(18)
	local var2=0
	local i=1
	while `i'<36 {
		local j=`i'+1
		while `j'<36 {
			if `ano'[`i',1]==`ano'[`j',1] {
				local k=`o'[`i',1]
				local l=`o'[`j',1]
				local var2=`var2'+((`m'[`i',1]*`m'[`j',1])^0.5*`r'[`k',`l'])
			}
			local j=`j'+1
		}
	local i=`i'+1
	}
	global var=(`var1'+2*`var2')/1225
}
end

	
