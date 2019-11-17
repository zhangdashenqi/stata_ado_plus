*! version 1.1 -- 22july2003: -sample-
* version 1.0 -- 18may2003
*! suggestions and complaints to Daniel (danielix@gmx.net)

prog def spatsam
	version 8.0
	syntax , Gap(int) Xcoord(varname) Ycoord(varname) ///
		[ INSample(str) SAVing(str) NORESTore REPLACE ]

	tempvar select
	if "`norestore'" == "" preserve
	gen `select' = 0
	qui replace `select' = 1 if (`xcoord'/`gap')==int(`xcoord'/`gap') ///
					& (`ycoord'/`gap')==int(`ycoord'/`gap')
	if "`insample'" != "" {
		gen `insample' = (`select' == 1)
	}
	qui keep if `select' == 1
	drop `select'
	qui cou
	di as txt "{p}you selected " as res "`r(N)'" as txt " observations{p_end}"
	if "`saving'" != "" {
		save "`saving'", `replace'
	}
	if "`norestore'" == "" restore
end
