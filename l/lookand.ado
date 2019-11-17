program define lookand, rclass
*!	program lookand by Mead Over Version 1.2 8/19/14

//	Stata's program -lookfor- finds the variables in memory that
//	conatain any of the list of character strings.
//	This program instead lists variables that contain
//	all the character strings.

//	Optionally, -lookand- will execute the -describe- command
//	with either the -fullnames- or the -short- option.
//	Optionally -lookand- will also summarize the selected variables.

	version 12.1
	syntax anything [, Fullnames SUm Short SImple Detail]

	local nchunks : word count `anything'
	local chunks `anything'
	tokenize `chunks'
	qui lookfor `1'
	local lookvars `r(varlist)'

	if `nchunks'>1 {
		local i = 2
		while "``i''" ~= "" {
			qui lookfor ``i''
			local holdlist `r(varlist)'
			local lookvars : list lookvars & holdlist
			local i = `i' + 1
		}
	}
	
	if "`lookvars'"=="" {
		di as txt "No variables contain all of the following character strings:" ///
			_n as res "`anything'"
			exit
	}
	else {
		des `lookvars' , `fullnames' `short' `simple'
		if "`sum'" ~= "" {
			sum `lookvars', `detail'
		}
		return local varlist `lookvars'
	}
end	
*	Version 1.1 4/28/12 adds the -detail- option
*	Version 1.2 8/19/14 corrects spelling of "version 12.1"
