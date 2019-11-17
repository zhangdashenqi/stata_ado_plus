*! 1.0.0 NJC 29 April 2011
*! avplots 2.4.0  29sep2004
program favplots
	version 9  

	_isfit cons
	syntax [, * ]

	_get_gropts , graphopts(`options') getcombine getallowed(plot addplot)
	local options `"`s(graphopts)'"'
	local gcopts `"`s(combineopts)'"'
	if `"`s(plot)'"' != "" {
		di as err "option plot() not allowed"
		exit 198
	}
	if `"`s(addplot)'"' != "" {
		di as err "option addplot() not allowed"
		exit 198
	}		

	_getrhs rhs

	foreach x of local rhs { 
		tempname tname
		local base `names'
		local names `names' `tname'
		capture favplot `x', name(`tname') nodraw `options'
		if _rc { 
			if _rc != 399 exit _rc
			local names `base'
		}
	}

	graph combine `names', `gcopts'
	graph drop `names'
end
