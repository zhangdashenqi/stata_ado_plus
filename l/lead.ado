*! version 3.0.0  
*! lead -- construct leads of existing variable
*! Sean Becketti, April 1991.
program define lead
	version 3.0
	capture confirm integer number `1'
	if _rc==0 { 
		local nlags =-`1'
		mac shift
	}
	else	local nlags -1
	lag `nlags' `*'
end
