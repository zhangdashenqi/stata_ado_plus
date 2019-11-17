*! version  1.0.0  18jan1999
program define lr, rclass
	version 6.0
	
	* keyword style, no abbreviation implemented yet
	gettoken cmd 0 : 0
	if `"`cmd'"' == "clear" {
		lrtest2, clear
	}
	
	else if `"`cmd'"' == "drop" {
		lrtest2, drop(`0')
	}
	
	else if `"`cmd'"' == "list" | `"`cmd'"' == "dir" {
		lrtest2, list
	}
	
	else if `"`cmd'"' == "define" {
		gettoken name note: 0, quotes
		if `"`note'"' ~= "" { local note `"note(`note')"' }
		lrtest2, saving(`name') `note'
	}
	
	else if `"`cmd'"' == "test" {
		gettoken name1 0 : 0, parse(", ")
		gettoken name2 0 : 0, parse(", ")
		lrtest2, using(`name1') model(`name2') switch detail
	}
	
	else {
		di in re `"unknown keyword `0'"'
		exit 198
	}
end	
