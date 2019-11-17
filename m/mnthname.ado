*! mnthname -- Map month code to month name
*! version 1.0     Sean Becketti     June 1994          STB-20: dm20
program define mnthname
	version 3.1
	local m `1'
	mac shift
	if "`m'"=="" { error 198 }
/*
	Check for comma attached to token #1
*/
	local j = index("`m'",",")
	if `j' {
		local s = substr("`m'",`j',.)
		local 1 "`s' `1'"
		local j = `j' - 1
		if `j'<=0 { error 198 }
		local m = substr("`m'",1,`j')
	}
	local options "Generate(str)"
	parse "`*'"
      	if "`generat'"=="" {	/* Immediate form */
		conf integer n `m'
		if      `m'== 1 { 
			local mn January   
			local ml Jan
		}
		else if `m'== 2 { 
			local mn February  
			local ml Feb
		}
		else if `m'== 3 { 
			local mn March     
			local ml Mar
		}
		else if `m'== 4 { 
			local mn April     
			local ml Apr
		}
		else if `m'== 5 { 
			local mn May       
			local ml May	
		}
		else if `m'== 6 { 
			local mn June      
			local ml Jun
		}
		else if `m'== 7 { 
			local mn July      
			local ml Jul
		}
		else if `m'== 8 { 
			local mn August    
			local ml Aug
		}
		else if `m'== 9 { 
			local mn September 
			local ml Sep
		}
		else if `m'==10 { 
			local mn October   
			local ml Oct
		}
		else if `m'==11 { 
			local mn November  
			local ml Nov
		}
		else if `m'==12 { 
			local mn December
			local ml Dec
		}
		else {
			di in re "illegal month: `m'"
			exit 99
		}
		global S_1 `mn'
		global S_2 `ml'
		global S_3 "`ml'."
		di in ye "`mn'"
	}
	else {
		conf var `m'
		parse "`generat'", parse(" ")
		local mon "`1'"
		if "`2'"!="" { error 198 }
		conf new v `mon'
		label def `mon' 1 "January" 2 "February" 3 "March" 4 "April" 5 "May" 6 "June" 7 "July" 8 "August" 9 "September" 10 "October" 11 "November" 12 "December"
		label values `m' `mon'
		decode `m', gen(`mon')
		label drop `mon'
		qui recast str9 `mon'
		qui replace `mon' = "September" if `mon'=="Septembe"
	}
end
