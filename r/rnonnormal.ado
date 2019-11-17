
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
//    rnnorm to simulate univariate non-normal data 
////////////////////////////////////////////////////////////////////////	
program define rnonnormal, rclass
	// Fleishman(1978)'s power method for generating non-normal data
	//  	1. for a given skewness and kurtosis, find a,b,c,d that 
    //         satisfy the following four equations: 
    //         a) a + c = 0
    //         b) b^2 + 6bd + 2c^2 + 15d^2 - 1 = 0
    //         c) 2c(b^2+24bd+105d^2+2)-skewness = 0 
    //         d) 24(bd+c^2(1+b^2+28bd)+d^2(12+48bd+141c^2+225d^2)) - kurtosis = 0 
    //      2. let X ~ N(0,1) then Y = a + b*X + c*X^2 + d*X^3 will have desired 
    //         skewness and kurtosis. 
	//args  n skew kurt 
	
	syntax , n(integer) SKEWness(real) KURTosis(real) 
	
	// check whether n is integer
	confirm integer number `n'
	
	// skew = a vector of k skewness of k non-normal variables
	// kurt = a vector of k kurtosis of k non-normal variables
	// k = number of non-normal variables
	drop _all
	quietly {
		set matsize 10000
		set more off
		// call mata function solver() to get a,b,c,d 
		// for a given skewness and kurtosis
		mata: solver(`skewness',`kurtosis')
		matrix b = r(p)
		// generate X ~ N(0,1)
		mata: X = (invnormal(uniform(`n',1)))
		mata: st_matrix("X",Re(X))
		matrix Y = J(`n',1,0)
		// given a,b,c,d, transform Y to x
		// ,where x = a + b*Y + c*Y^2 + d*Y^3
		forvalues j = 1/`n' {
			matrix Y[`j',1]=-b[1,2]+b[1,1]*X[`j',1]+b[1,2]*(X[`j',1])^2+b[1,3]*(X[`j',1])^3
		}
		svmat Y
	    summarize Y, detail
		return scalar mean = r(mean)
		return scalar sd = r(sd)
		return scalar skew = r(skewness)
		// set kurtosis of standard normal to be 0 
		return scalar kurt = r(kurtosis)-3
		return scalar d =  b[1,3]
		return scalar c =  b[1,2]
		return scalar b =  b[1,1]
		return scalar a = -b[1,2]
		return matrix Y = Y
    }	
end
////////////////////////////////////////////////////////////////////////


