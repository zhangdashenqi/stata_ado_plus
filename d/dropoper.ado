*! version 6.0.0	29dec1998	(www.stata.com/users/becketti/tslib)
*! dropoper 
*! drop all operator variables
*! Sean Becketti, April 1991.
program define dropoper
	version 3.0
	if "`*'"!="" {
		error 198
	}
	local varlist "req ex"
	parse "_all"
	parse "`varlist'", parse(" ")
	local i 1
	while "``i''"!="" {
		if index("``i''","_") {
			local todrop "`todrop' ``i''"
		}
		local i=`i'+1
	}
	if "`todrop'" != "" {
		drop `todrop'
	}
end
