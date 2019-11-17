
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
//    stata commands names: rnnorm and mvrnnorm 
//    purpose: simulating univariate (rnnorm) and multivariate (rmvnnorm)
//             non-normal data
//    written by: Sun Bok Lee (Ph.D.)
//    last updated: 12-28-2013
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////
//    mata functions for optimization 
////////////////////////////////////////////////////////////////////////
*clear all
capture mata mata drop eval()
capture mata mata drop solver()
capture program drop rmvtnnorm
capture program drop rnnorm
mata
void eval(todo, p, skew,kurt, lnf, S, H) {
	// evaluator function for optimize()
	b   = p[1]
    c   = p[2]
    d   = p[3]
	// following equations come from Fleishman(1978)
    lnf = (b^2 + 6*b*d + 2*c^2 + 15*d^2 - 1)^2 +(2*c*(b^2+24*b*d+105*d^2+2)-skew)^2 +(24*(b*d+c^2*(1+b^2+28*b*d)+(d^2)*(12+48*b*d+141*c^2+225*d^2))-kurt)^2    
}
void solver(skewness, kurtosis) {
	// optimize eval() to find a,b,c,d
	S = optimize_init()
	optimize_init_evaluator(S, &eval())
	optimize_init_evaluatortype(S, "d0")
	optimize_init_params(S, (1,0,0))
	optimize_init_argument(S,1,skewness)
	optimize_init_argument(S,2,kurtosis)
	optimize_init_which(S,  "min" )
	optimize_init_tracelevel(S,"none")
	optimize_init_conv_ptol(S, 1e-16)
	optimize_init_conv_vtol(S, 1e-16)
	p = optimize(S)
	st_matrix("r(p)", p)

}
end
////////////////////////////////////////////////////////////////////////








////////////////////////////////////////////////////////////////////////
//    rmvnonnormal to simulate multivariate non-normal data 
////////////////////////////////////////////////////////////////////////	
program define rmvnonnormal, rclass
	// Multivariate Fleishman Transformation (Vale & Maurelli, 1983)
	// n = sample size of data 
	// k = number of non-normal variables
	// skew = a vector of k skewness of k non-normal variables
	// kurt = a vector of k kurtosis of k non-normal variables
	// cor = desired correlation matrix between k non-normal variables (k by k)
	syntax , n(integer) SKEWness(string) KURTosis(string) CORRelation(string)
	// check whether n is integer
	confirm integer number `n'
	quietly {
		set matsize 10000
		set more off
		drop _all

		local lengthSkew = colsof(`skewness')
		local lengthKurt = colsof(`kurtosis')
		local rowCorr = rowsof(`correlation')
		local colCorr = colsof(`correlation')
		if `rowCorr' != `colCorr'  {
			di as error "Correlation matrix is not square"
			exit 198
		}
		if (`lengthSkew' != `lengthKurt') & (`lengthSkew' != `rowCorr')  {
			di as error "Dimensions of skewness, kurtosis, and correlation matrix does not match"
			exit 198
		}
		
		local k = rowsof(`correlation')
		matrix c = J(`k',4,0)
		forvalues i = 1/`k' {
			// call mata function solver() to get
			// k sets of Fleishman's coefficients
			local skewTemp = `skewness'[1,`i']
		    local kurtTemp = `kurtosis'[1,`i']
			mata: solver(`skewTemp',`kurtTemp')
			matrix b = r(p)
			matrix c[`i',1] = -b[1,2]
			forvalues j = 2/4 {
				matrix c[`i',`j'] = b[1,`j'-1]
			}
		}
		// create intermediate correlation matrix 
		matrix intercor = J(`k',`k',0)
		forvalues i = 1/`k' {
			forvalues j = 1/`k' {
				local xnew 0.5
				local xold 0.51
				local iteration 1
				// while loop for Newton-Raphson method
				while abs(`xnew'-`xold')>.000001 & `iteration'<500 {
					local xold `xnew'
					local xnew=`xold'- (((c[`i',2]*c[`j',2]+3*c[`i',2]*c[`j',4]+3*c[`i',4]*c[`j',2]+9*c[`i',4]*c[`j',4])*`xold')+((2*c[`i',3]*c[`j',3])*`xold'^2)+((6*c[`i',4]*c[`j',4])*`xold'^3)-`correlation'[`i',`j']) / ((c[`i',2]*c[`j',2]+3*c[`i',2]*c[`j',4]+3*c[`i',4]*c[`j',2]+9*c[`i',4]*c[`j',4])+((4*c[`i',3]*c[`j',3])*`xold')+((18*c[`i',4]*c[`j',4])*`xold'^2))
					local iteration = `iteration' + 1	
				}
				matrix intercor[`i',`j'] = `xnew'
			}
		}
		// create correlated multivariate normal variables
		mata: eigensystem(st_matrix("intercor"), U=., L=.)
		mata: A = U*sqrt(diag(L))
		mata: W = (invnormal(uniform(`n',`k')))
		mata: X = W*(A')
		mata: st_matrix("X",Re(X))
		matrix Y = J(`n',`k',0)
		// create correlated non-normal multivariate variables
		forvalues i = 1/`k' {
			forvalues j = 1/`n' {
				matrix Y[`j',`i']=c[`i',1]+c[`i',2]*X[`j',`i']+c[`i',3]*(X[`j',`i'])^2+c[`i',4]*(X[`j',`i'])^3
			}
		}
		svmat Y
		return matrix Y = Y
		matrix table = J(`k',4,0)
		forvalues i = 1/`k' {
			summarize Y`i', detail
			matrix table[`i',1] = r(mean)
			matrix table[`i',2] = r(sd)
			matrix table[`i',3] = r(skewness)
			matrix table[`i',4] = r(kurtosis)-3
		}
		matrix colnames table = mean sd skewness kurtosis
		ds
		matrix rownames table = `r(varlist)'
		return matrix table = table
	}

end







