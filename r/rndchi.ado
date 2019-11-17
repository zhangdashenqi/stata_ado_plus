*!version 1.1 1999 Joseph Hilbe
* version 1.0.0  1993 Joseph Hilbe                            (sg44: STB-28)
* Chi-square distribution random number generator 
* Example: rndchi 1000 4  [set obs 1000;  4 is the degrees of freedom]

program define rndchi
	version 3.1
	set type double
	cap drop xc
	qui     {
		local cases `1'
		set obs `cases'
		mac shift
		local df `1'
		tempvar ran1
		noi di in gr "( Generating " _c
		local i=1
		gen `ran1'=0
		while `i'<=`df'  {
		    replace `ran1' = `ran1'+ (invnorm(uniform()))^2
		    local i=`i'+1
		    noi di in gr "." _c 
		}
		gen xc = `ran1'
		noi di in gr " )"
		noi di in bl "Variable " in ye "xc " in bl "created."
		lab var xc "Chi-square random variable"
		set type float
	}
end
