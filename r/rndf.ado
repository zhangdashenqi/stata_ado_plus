*!version 1.1 Joseph Hilbe
* version 1.0.0 1993 Joseph Hilbe                            (sg44: STB-28)
* F distribution random number generator 
* Example: rndf 1000 4 15  [set obs 1000; 4=numerator df; 15=denominator df]

program define rndf
	version 3.1
	set type double
	cap drop xf
	qui     {
		local cases `1'
		set obs `cases'
		mac shift
		local dfn `1'
		mac shift
		local dfd `1'
		tempvar ran1 ran2
		noi di in gr "( Generating " _c
		local i=1
		gen `ran1'=0
		while `i'<=`dfn'  {
		    replace `ran1' = `ran1'+ (invnorm(uniform()))^2
		    local i=`i'+1
		    noi di in gr "." _c 
		}
		noi di in gr "|" _c
		local i=1
		gen `ran2'=0
		while `i'<=`dfd'  {
		    replace `ran2' = `ran2'+ (invnorm(uniform()))^2
		    local i=`i'+1
		    noi di in gr "." _c 
		}

		gen xf = (`ran1'/`dfn')/(`ran2'/`dfd')
		noi di in gr " )"
		noi di in bl "Variable " in ye "xf " in bl "created."
		lab var xf "F random variable"
		set type float
	}
end
