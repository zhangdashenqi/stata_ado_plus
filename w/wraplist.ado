*! 2.0.0  10Jan1999  Jeroen Weesie/ICS - programming utility -
program define wraplist
	version 6.0

	gettoken list 0: 0, parse(",")
	
	local lsize : set display linesize
	syntax [, LColor(str) LEft(int 1) RIght(int `lsize') TItle(str) /*
		*/ TColor(str) CUrsor(int 1) BEfore(str) AFter(str) ]

	/*
		check options
	*/

	if `"`tcolor'"' == "" {
		local tcolor "green"
	}
	else {
		Color `tcolor'
		local tcolor `s(color)'
	}

	if `"`lcolor'"' == "" {
		local lcolor "yellow"
	}
	else {
		Color `lcolor'
		local lcolor `s(color)'
	}

	if `left' < 1 {
		di in re "left margin should be >= 1"
		exit 198
	}
	if `right' < `left'+1 {
		di in re "right margin should exceed left margin"
		exit 198
	}
	if `right' > `lsize' {
		di in re `"right margin should not exceed "display linesize""'
		exit 198
	}

	if `"`after'"' ~= "" {
		local rright = `right'+1
		local After `"_col(`rright') `after'"'
	}

	/*
		display title with list
	*/

	* first line/header
	if `"`title'"' ~= "" {
		local lmarg = max(`left'-`cursor', length(`"`title'"')) + 1
		di in `tcolor' `"`title'"' _col(`lmarg') _c
		* precaution lmarg > right ??
	}
	else {
		local lmarg `left'
	}


	local first 1
	tokenize `list'
	local i 1
	while `"``i''"' ~= "" {
		* display at least one term
		local llist `"``i''"'
		local lenlist = length(`"``i''"')

		* add terms until too long
		local i = `i'+1
		local len = length(`"``i''"')
		while `len' > 0 & `lenlist'+`len' <= `right'-`lmarg' {
			local llist `"`llist' ``i''"'
			local lenlist = `lenlist' + `len' + 1
			local i = `i'+1
			local len = length(`"``i''"')
		}

		* display line
		if "`first'" ~= "" {
			* no "before" and "after" in first line
			local rright = `right' - `lmarg' - 1
			di in `lcolor' `"`llist'"' _col(`rright') `after'
			local first
			local lmarg `left'
		}
		else {

			di `before' _col(`left') in `lcolor' `"`llist'"' `After'
		}
	}
end

* -Color c- returns in s(color) the interpreted color of c
program define Color, sclass
	args c

	local lc = length(`"`c'"')
	     if `"`c'"' == substr("green",1,`lc')  { sreturn local color green }
	else if `"`c'"' == substr("yellow",1,`lc') { sreturn local color yellow }
	else if `"`c'"' == substr("blue",1,`lc')   { sreturn local color blue }
	else if `"`c'"' == substr("white",1,`lc')  { sreturn local color white }
	else if `"`c'"' == substr("red",1,`lc')    { sreturn local color red }
	else {
		di in re `"unknown color `c'"'
		exit 198
	}
end

exit

Implementation problems and nagging thought while development

  * the title and words in the lists should not exceed 80 chars

  * to avoid length() applied to strings of length > 80 (in case linesize
    exceeds 80, we have to take extra trouble. Why is life so hard?

  * it would be nice if arguments of type real/int allow modifiers
    min=.., max=.. and allow default==none

  * for string arguments: allow default
