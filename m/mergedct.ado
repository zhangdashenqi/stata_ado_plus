*! mergedct -- merge a raw or dictionary file into the current data set
*! version 1.0.0     Jonathan Nash     May 1994         (STB-20: dm19)
program define mergedct
quietly {
	version 3.1
	if "`*'"=="" { exit 198 }
	if "`1'"!="using" { local varlist "req ex" }
	local using "req pre"
	local options "Automatic Byvariable(int 0) noLabel U2(str) Vlist(str)"
	parse "`*'"
        if `byvaria'>0 { local b "byvaria(`byvaria')" }
        if "`u2'"!="" { local u "using(`u2')" }
	preserve
	drop _all
	infile `vlist' `using', `automat' `b' `u'
	if "`varlist'"!="" { sort `varlist' }
	tempfile temp
	save `temp'
	restore
	merge `varlist' using `temp', `label'
}	/* end quietly */
end
