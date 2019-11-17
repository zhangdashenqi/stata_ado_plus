*! 1.0.1  06sep1999  jw/ics
program define ado_upd
	version 6.0
	syntax , [ All From(str)]


	if "`from'" == "" {
		local from STBPLUS
	}
	*else {
	*	local from = upcase("`from'")
	*	if "`from'" ~= "STBPLUS" & "`from'" ~= "PERSONAL" & "`from'" ~= "SITE" {
	*		di in re "`from' invalid in from()"
	*		exit 198
	*	}
	*}

	preserve
	clear

	quiet {
		* read the file with installations
		local path : sysdir `from'
		if "`path'" == "" {
			* path is likely not a Stata system directory.
			local path `from'
		}
		infix str T 1-1 str X 3-80 using `path'stata.trk

		* keep only required lines
		keep if T=="S" | T=="N" | T=="U"

		* sloppy way to re-organize to 1 line per package-
		gen int id = int((_n-1)/3)
		sort id T
		qui by id: gen nr = real(X[3])
		qui by id: gen str80 location = X[2]
		qui by id: gen str12 pkgname  = X[1]
		qui by id: drop if _n>1
		drop T X
		qui compress

		* for multiple named packages, only keep highest nr
		sort pkgname nr
		by pkgname : drop if _n<_N
	}

	* re-install packages, taking care to connect to each location only once

	sort location pkgname
	local ok 0
	local i 1
	local lloc = location[1]
	while !`ok' {
		capt net from `lloc'

		if _rc {
			di _n in gr "failure to connect to " in ye "`lloc'"
			while `i' <= _N & location[`i'] == "`lloc'" {
				di in gr _col(5) "skipping re-installation of " in ye pkgname[`i']
				local i = `i'+1
			}
		}
		else {
			di _n in gr "connected to " in ye "`lloc'"
			while `i' <= _N & location[`i' ] == "`lloc'" {
				local lname = pkgname[`i']
				di in gr _col(5) "re-installation of " in ye %12s "`lname' " _c
				capt net install `lname', replace `all'
				di in gr =cond(_rc, "failed", "completed")
				local i = `i'+1
			}
		}

		if `i' == _N+1 {
			local ok 1
		}
		else {
			local lloc = location[`i']
		}
	}
end
exit

