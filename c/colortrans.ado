*! version 1.0.1  19jan2004
program define colortrans, rclass
	version 8.2
	syntax anything(id="color spec" name=incolor) [, FRACtion ]

	local cnt : word count `incolor'
	if `cnt' == 3 {
		local format rgb
	}
	else if `cnt' == 4 {
		local format cmyk
	}
	else {
		di as err ///
		"{it:input_color} misspecified; please specify 3 or 4 numbers"
		exit 198
	}
	from`format' `incolor' , `fraction'
	return add

	local formats rgb cmyk
	foreach f of local formats {
		di as txt %5s "`f'" " = " as res "`return(`f')'"
	}
end

program FromFrac, rclass
	local k : word count `0'
	forval i = 1/`k' {
		return scalar r`i' = ``i''*255
	}
end

program ToFrac, rclass
	local k : word count `0'
	forval i = 1/`k' {
		return scalar r`i' = ``i''/255
	}
end

* Original source:
* 	http://community.borland.com/article/0,1410,17948,00.html
program fromcmyk, rclass
	syntax anything [, fraction ]
	tokenize `anything'
	args c m y k

	return local cmyk = "`c' `m' `y' `k'"

	if "`fraction'" != "" {
		FromFrac `c' `m' `y' `k'
		local c = `r(r1)'
		local m = `r(r2)'
		local y = `r(r3)'
		local k = `r(r4)'
	}

	Check4Range cyan	`c', `fraction'
	Check4Range magenta	`m', `fraction'
	Check4Range yellow	`y', `fraction'
	Check4Range black	`k', `fraction'

	return scalar r = cond(`c'+`k' < 255, 255 - (`c'+`k'), 0)
	return scalar g = cond(`m'+`k' < 255, 255 - (`m'+`k'), 0)
	return scalar b = cond(`y'+`k' < 255, 255 - (`y'+`k'), 0)

	if "`fraction'" != "" {
		ToFrac `return(r)' `return(g)' `return(b)'
		return scalar r = `r(r1)'
		return scalar g = `r(r2)'
		return scalar b = `r(r3)'
	}

	return local rgb = "`return(r)' `return(g)' `return(b)'"
end

* Original source:
* 	http://community.borland.com/article/0,1410,17948,00.html
program fromrgb, rclass
	syntax anything [, fraction]
	tokenize `anything'
	args r g b

	return local rgb = "`r' `g' `b'"

	if "`fraction'" != "" {
		FromFrac `r' `g' `b'
		local r = `r(r1)'
		local g = `r(r2)'
		local b = `r(r3)'
	}

	Check4Range red		`r', `fraction'
	Check4Range green	`g', `fraction'
	Check4Range blue	`b', `fraction'

	return scalar k = 255 - max(`r',`g',`b')
	return scalar c = 255 - `r' - return(k)
	return scalar m = 255 - `g' - return(k)
	return scalar y = 255 - `b' - return(k)

	if "`fraction'" != "" {
		ToFrac `return(k)' `return(c)' `return(m)' `return(y)'
		return scalar k = `r(r1)'
		return scalar c = `r(r2)'
		return scalar m = `r(r3)'
		return scalar y = `r(r4)'
	}

	return local cmyk = "`return(c)' `return(m)' `return(y)' `return(k)'"
end

program Check4Range
	syntax anything [, FRACtion ]
	tokenize `anything'
	args specname val
	if "`val'" == "" {
		di as err "`specname' specification required"
		exit 198
	}
	if "`fraction'" == "" {
		confirm integer number `val'
	}
	else	confirm number `val'
	if `val' < 0 | `val' > 255 {
		di as err "value `val' out of range"
		exit 198
	}
end

exit
