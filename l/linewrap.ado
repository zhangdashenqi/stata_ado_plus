program define linewrap, rclass 
*!	linewrap 			by Mead Over    Version 1.3     5Nov2015
*	This program splits a long string into lines of -maxlength- characters each
*	There are -r(nlines)- lines of text, named -r(line1)-, -r(line2)- ...
*
*	The -square- option combines with -maxlength- to force a line break every =maxlength-
*	characters even if the break is in the middle of a word.  Without the -square- option,
*	default behavior is to break each line at the first word break before =maxlength-

*	Alternatively, with the -words- option, each line is a word.

*	The -display- option prints each of the multiple lines.  The -linenumber- option
*	adds sequence numbers to the displayed lines

	version 11.2
	syntax , LOngstring(string) [MAXlength(integer 80) Words Display LInenumbers Title(string) Square debug]
	
	if "`title'" ~= "" {
		di _n as txt "`title'"
	}

	if "`display'"~="" | "`linenumbers'"~="" {
		if "`linenumbers'"~="" {
			local tab5 _col(5)
		}
		local newline _n `tab5'
		foreach i of numlist 1/`maxlength' {
			if mod(`i',10) == 0 {
				di `newline' as txt int(`i'/10) _c
			}
			else {
				di `newline' " " _c
			}
			local newline _c
		}
		local newline _n `tab5'
		foreach i of numlist 1/`maxlength' {
			di as txt `newline' mod(`i',10) _c
			local newline _c
		}
		di _n
		if "`linenumbers'"~="" {
			local ln \`line' _col(5)
		}
		local show show
	}
*set trace on
	if "`words'"=="" {
		local lngth = length("`longstring'")  //  Number of characters
		if "`square'"~="" {    // Wrap at maxlength regardless of spaces
			local longstring = trim(itrim("`longstring'"))
			local nlines = ceil((`lngth'-1)/`maxlength')
			foreach line of numlist 1/`nlines' {
				local tmpstr = substr("`longstring'", (`line'-1)*`maxlength'+1,`maxlength')
				if "`show'"~="" {
					di as txt `ln'  as res `"`tmpstr'"'
				}
				return local line`line' = `"`tmpstr'"'
			}
		}
		else {
			local line = 1
			local i = 0  // Character position in rest of the string
			local blnkpos = .  // Characters until next blank  
			local restofstr `longstring'
			local lngthrest = length(`"`longstring'"')  //  Total number of characters in the rest of the string
			while `i' < `lngthrest' & `blnkpos' > 0 {
				local blnkpos = strpos(substr(`"`restofstr'"',`i'+1,.)," ") 
				local i = `i' + `blnkpos'
if "`debug'" ~="" {
	di as err "length of rest of string is " as txt "`lngthrest'" as err " and blnkpos is " as txt "`blnkpos'" as err " and i is " as txt "`i'"
}
				if `i' >= `maxlength' {
					if `i' - `blnkpos' > 0 {  
						local tmpstr = substr("`restofstr'", 1 ,`i' - `blnkpos' - 1)
						if "`show'"~="" {
							di as txt `ln'  as res `"`tmpstr'"'
						}
						return local line`line' = `"`tmpstr'"'
						local line = `line' + 1
						local restofstr = substr(`"`restofstr'"', `i' - `blnkpos' + 1 , .)
						local lngthrest = length("`restofstr'")  //  Number of characters left
						local blnkpos = strpos(substr(`"`restofstr'"',1,.)," ") 
						local i = 0
					}
					else {  // When a string of characters is longer than maxlength
						local tmpstr = substr("`restofstr'", 1 ,`blnkpos'-1)
						if "`show'"~="" {
							di as txt `ln'  as res `"`tmpstr'"'
						}
						return local line`line' = `"`tmpstr'"'
						local line = `line' + 1
						local restofstr = substr(`"`restofstr'"', `blnkpos' + 1 , .)
						local lngthrest = length("`restofstr'")  //  Number of characters left
						local blnkpos = strpos(substr(`"`restofstr'"',1,.)," ") 
						local i = 0				
					}
				}
			}
			else {  //  Rest of string fits in a single line
				local tmpstr `restofstr'
				if "`show'"~="" {
					di as txt `ln'  as res `"`tmpstr'"'
				}
				return local line`line' = `"`tmpstr'"'
				local nlines = `line'
			}
		}
	}
	else {  // Option words selected
		local nlines : word count `longstring'  //  Number of lines = number of words
		local longstring = trim(itrim("`longstring'"))
		foreach line of numlist 1/`nlines' {
			local tmpstr : word `line' of `longstring'
			if "`show'"~="" {
				di as txt `ln'  as res `"`tmpstr'"'
			}
			return local line`line' = `"`tmpstr'"'
		}
	}
	return local nlines = `nlines'

end
*	Ver 1.0 6/18/2012 Long string split into lines of -maxlength- each
*	Ver 1.1 9/3/2015  Add option to split the long string into words
*		with one word on each line.
*	Ver 1.2 9/5/2015  Add options -display- and -linenumbers- to print the long string
*		Adds the -square- option to cut each line precisely at -maxlength- characters.
*		Changes the default to cut lines at the first word break before -maxlength-.
*		Also add the -title- option 
*	Ver 1.3 11/5/2015  Fix a bug in the line wrapping under -maxlength- control
*		when the square option is not selected.
