*! downame -- Map DOW code to DOW name
*! version 1.0     Sean Becketti     June 1994          STB-20: dm20
program define downame
	version 3.1
	local d `1'
	mac shift
	if "`d'"=="" { error 198 }
/*
	Check for comma attached to token #1
*/
	local j = index("`d'",",")
	if `j' {
		local s = substr("`d'",`j',.)
		local 1 "`s' `1'"
		local j = `j' - 1
		if `j'<=0 { error 198 }
		local d = substr("`d'",1,`j')
	}
	local options "Generate(str)"
	parse "`*'"
      	if "`generat'"=="" {	/* Immediate form */
		conf integer n `d'
		if      `d'== 0 { 
			local dn Sunday
			local dl Sun
		}
		else if `d'== 1 { 
			local dn Monday
			local dl Mon
		}
		else if `d'== 2 { 
			local dn Tuesday
			local dl Tue
		}
		else if `d'== 3 { 
			local dn Wednesday
			local dl Wed
		}
		else if `d'== 4 { 
			local dn Thursday
			local dl Thu
		}
		else if `d'== 5 { 
			local dn Friday
			local dl Fri
		}
		else if `d'== 6 { 
			local dn Saturday
			local dl Sat
		}
		else {
			di in re "illegal day: `d'"
			exit 99
		}
		global S_1 `dn'
		global S_2 `dl'
		global S_3 "`dl'."
		di in ye "`dn'"
	}
	else {
		conf var `d'
		parse "`generat'", parse(" ")
		local day "`1'"
		if "`2'"!="" { error 198 }
		conf new v `day'
		label def `day' 0 "Sunday" 1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday"
		label values `d' `day'
		decode `d', gen(`day')
		label drop `day'
		qui recast str9 `day'
		qui replace `day' = "Wednesday" if `day'=="Wednesda"
	}
end
