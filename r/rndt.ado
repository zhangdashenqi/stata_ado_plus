*!version 1.1 1999 Joseph Hilbe
* version 1.0.0 1993 Joseph Hilbe                           (sg44: STB-28)
* Student's T distribution random number generator 
* Example: rndt 1000 10  [set obs 1000;  10 is the degrees of freedom]

program define rndt
	version 3.1
	set type double
	cap drop xt
	qui     {
		local cases `1'
		set obs `cases'
		mac shift
		local df `1'
		tempvar ran1 z
		noi di in gr "( Generating " _c
		local i=1
		gen `z'=invnorm(uniform())
		gen `ran1'=0
		while `i'<=`df'  {
		    replace `ran1' = `ran1'+ (invnorm(uniform()))^2
		    local i=`i'+1
		    noi di in gr "." _c 
		}
		gen xt = `z'/sqrt(`ran1'/`df')
		noi di in gr " )"
		noi di in bl "Variable " in ye "xt " in bl "created."
		lab var xt "T random variable"
		set type float
	}
end
