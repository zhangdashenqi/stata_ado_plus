*! version 1.2.0  07may2003                     (SJ3-4: st0049, st0050, st0051)
program define _qvferr
	local err  `1'
	local mess `2'
	
	if `err' == 0  | `mess' == 0 {
		exit	
	}
	if `err' == 1 {
		di in red "bootstrap failure"
	}
	else if `err' == 3 {
		di in red "singular matrix in QVF"
	}	
	else if `err' == 4 {
		di in red "failed to converge in QVF"
	}
	else if `err' == 5 {
		di in red "OLS singularity in QVF"
	}
	else if `err' == 6 {
		di in red "floating point exception in QVF"
	}
	else if `err' == 7 {
		di in red "singular matrix in RCAL"
	}
	else if `err' == 8 {
		di in red "singular matrix in IVAR"
	}
	else if `err' == 9 {
		di in red "singular matrix in SIMEX"
	}
	else if `err' == 10 {
		di in red "general failure in SIMEX"
	}
	else if `err' == 12 {
		di in red "failure in linear extrapolation in SIMEX"
	}
	else if `err' >= 13 & `err' <= 16 {
		di in red "failure in nonlinear extrapolation in SIMEX"
	}
	else if `err' == 17 {
		di in red "no replications, specify suu()"
	}
	else if `err' == 19 {
		di in red "out of memory"
	}
	else {
		di in red "internal error"
	}
end
exit

#define StatusNullError         21
#define StatusInvalidDim1       22
#define StatusSAS               23
#define StatusUnknownFamily     24

