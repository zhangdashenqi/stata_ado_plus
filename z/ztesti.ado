*! $Revision: 1.5 $
*! $Date: 2001/05/15 05:52:40 $
*! Written by: Jeff Pitblado

program define ztesti, rclass
	version 6.0

/* Parse. */

	gettoken 1 0 : 0 , parse(" ,")
	gettoken 2 0 : 0 , parse(" ,")
	gettoken 3   : 0 , parse(" ,")

	if "`3'"=="" | "`3'"=="," { /* Do McNemar test */
		syntax [, Xname(string) Yname(string) Level(int $S_level)]
		checkLevel `level'

                McNemarTest `1' `2' `level' `"`xname'"' `"`yname'"'
		ret add
                exit
        }

/* Here only if not McNemar test. */

	gettoken 3 0 : 0 , parse(" ,")
	gettoken 4   : 0 , parse(" ,")

	if "`4'"=="" | "`4'"=="," { /* Do one sample test */
		syntax [, Xname(string) Yname(string) Level(int $S_level)]
		checkLevel `level'

        	OneTest `1' `2' `3' `level' /*
		*/ `"`xname'"' `"`yname'"' "`unequal'" "`welch'"
		ret add
		exit
	}

/* Here only if two sample test. */

	gettoken 4 0 : 0 , parse(" ,")
	syntax [, Xname(string) Yname(string) Level(int $S_level)]
	checkLevel `level'

       	TwoTest `1' `2' `3' `4' `level' /*
	*/ `"`xname'"' `"`yname'"' "`unequal'" "`welch'"
	ret add
	exit
end

program define checkLevel
	args level
        if `level' < 10 | `level' > 99 {
                c_local level 95
        }
end

program define McNemarTest, rclass
	args b c level xname yname
	confirm integer number `b'
	confirm integer number `c'

/* Compute statistics. */

	local chi2 = ((`b' - `c')^2)/(`b'+`c')

	local p = chi2tail(1,`chi2')

/* Display table of p, std err, etc. */

	di _n in gr "McNemar test"

	_ztest header `level' `"`xname'"' `"`yname'"'

	if `"`xname'"'=="" { local xname "x" }
	if `"`yname'"'=="" { local yname "y" }

	local n = `b'+`c'

	_ztest table `level' `"`xname'>`yname'"' `n' `b'
	_ztest table `level' `"`xname'<`yname'"' `n' `c'
	_ztest botline

/* Display Ho. */

	di _n
	_ztest center `"Ho: Pr(@`xname'>`yname'@) = Pr(@`xname'<`yname'@)"'

/* Display Ha. */

	local cf : di %8.4f `chi2'
	local pf : di %8.4f `p'


        di
	_ztest center `"Ha: Pr(@`xname'>`yname'@) ~= Pr(@`xname'<`yname'@)"'

	_ztest center "    chi2 = @`cf'@"
	_ztest center "P > chi2 = @`pf'@"

	/* save in r() */
	ret scalar b    = `b'
	ret scalar c    = `c'
	ret scalar chi2 = `chi2'
	ret scalar p    = `p'
end

program define CheckNS, sclass
	args n s

	confirm integer number `n'
	confirm integer number `s'
	if `n'<`s' {
		di in smcl as err "{it:#N} < {it:#succ}"
		exit 198
	}
end

program define CheckProb
	args prob

	capture confirm integer number `prob'
	if _rc==0 {
		di in smcl as err "{it:#p} is not a fraction between 0 and 1"
		exit 198
	}
end

program define OneTest, rclass
	args n s p0 level xname

	CheckNS `n' `s'
	CheckProb `p0'

/* Compute statistics. */
	tempname p1 sd1 z se

	scalar `p1' = `s'/`n'
	scalar `sd1' = sqrt(`p0'*(1-`p0'))
	scalar `z' = (`p1' - `p0')*sqrt(`n')/`sd1'
	scalar `se' = `sd1'/sqrt(`n')

	local p = 2*(1-norm(abs(`z')))
	if `z' < 0 {
		local pl = `p'/2
		local pr = 1 - `pl'
	}
	else {
		local pr = `p'/2
		local pl = 1 - `pr'
	}

/* Display table of p, std err, etc. */

	di _n in gr "One-sample z test"

	_ztest header `level' `"`xname'"'

	if `"`xname'"'=="" { local xname "x" }

	_ztest table `level' `"`xname'"' `n' `s'
	_ztest botline

/* Display Ho. */

	if length("`p0'") > 8 {
		local p0 : di %9.0g `p0'
		local p0 = trim("`p0'")
	}

	di _n
	_ztest center `"Ho: Pr(@`xname' = 1@) = p = @`p0'@"'

/* Display Ha. */

	local zt : di %8.4f `z'
	local p_l : di %8.4f `pl'
        local p_  : di %8.4f `p'
        local p_r : di %8.4f `pr'

        di
        _ztest center "Ha: p < @`p0'@"  /*
	*/            "Ha: p ~= @`p0'@" /*
	*/            "Ha: p > @`p0'@"

	_ztest center "    z = @`zt'@"    /*
	*/            "      z = @`zt'@"  /*
	*/            "    z = @`zt'@"
	_ztest center "P < z = @`p_l'@"   /*
	*/            "P > |z| = @`p_'@" /*
	*/            "P > z = @`p_r'@"

	/* double save in S_# and r() */
	ret scalar N_1  = `n'
	ret scalar p_1 = `p1'
	ret scalar z    = `z'
	ret scalar p    = `p'
	ret scalar p_l  = `pl'
	ret scalar p_u  = `pr'
	ret scalar se   = `se'
	ret scalar sd_1 = `sd1'
end

program define TwoTest, rclass
	args n1 s1 n2 s2 level xname yname

/* Compute statistics. */

        if `n1' == 1 { local sd1 . } /* error check allows std dev to be 0 */
        if `n2' == 1 { local sd2 . }

	local p1 = `s1'/`n1'
	local p2 = `s2'/`n2'
	local n = `n1' + `n2'
	local comb = `s1'+`s2'
	local pbar = (`comb')/`n'
	local sd = sqrt(`pbar'*(1-`pbar'))
	local se = `sd'*sqrt(`n'/(`n1'*`n2'))
	local z  = (`p1'-`p2')/`se'
	local sd1 = sqrt(`p1'*(1-`p1'))
	local sd2 = sqrt(`p2'*(1-`p2'))
	local diff = (`p1'-`p2')*`n'

	local p = 2*(1-norm(abs(`z')))
	if `z' < 0 {
		local pl = `p'/2
		local pr = 1 - `pl'
	}
	else {
		local pr = `p'/2
		local pl = 1 - `pr'
	}

/* Display table of p, std err, etc. */

	di _n in gr "Two-sample z test"

	_ztest header `level' `"`xname'"'

	if `"`xname'"'=="" { local xname "x" }
	if `"`yname'"'=="" { local yname "y" }

	_ztest table `level' `"`xname'"' `n1' `s1'
	_ztest table `level' `"`yname'"' `n2' `s2'
	_ztest divline

/* Display combined p, etc. */

	_ztest table `level' "combined" `n' `comb' `se' `sd'
	_ztest divline 

/* Display difference. */

	_ztest table `level' "diff" `n' `diff' `se' `sd'
	_ztest botline

/* Display Ho. */

	di _n
	_ztest center `"Ho: Pr(@`xname' = 1@) - Pr(@`yname' = 1@) = diff = 0"'

/* Display Ha. */

	local zt : di %8.4f `z'
	local p_l : di %8.4f `pl'
        local p_  : di %8.4f `p'
        local p_r : di %8.4f `pr'

        di
        _ztest center "Ha: diff < 0" "Ha: diff ~= 0" "Ha: diff > 0"

	_ztest center "    z = @`zt'@"    /*
	*/            "      z = @`zt'@"  /*
	*/            "    z = @`zt'@"
	_ztest center "P < z = @`p_l'@"   /*
	*/            "P > |z| = @`p_'@" /*
	*/            "P > z = @`p_r'@"

	/* double save in S_# and r() */
        ret scalar N_1  = `n1'
        ret scalar p_1  = `p1'
        ret scalar N_2  = `n2'
        ret scalar p_2  = `p2'
        ret scalar z    = `z'
        ret scalar p    = `p'
        ret scalar p_l  = `pl'
        ret scalar p_u  = `pr'
        ret scalar se   = `se'
        ret scalar sd_1 = `sd1'
        ret scalar sd_2 = `sd2'
        ret scalar sd   = `sd'
end

program define _ztest, rclass
	version 6.0
/*
    This command consists of a group of helper commands for ztesti.

    _ztest header
    _ztest table
    _ztest center
    _ztest botline
    _ztest divline
*/
	gettoken cmd 0 : 0

	if "`cmd'"=="center" {
		tokenize `"`0'"'
		_center `"`1'"' `"`2'"' `"`3'"'
	}
	else {
		gettoken t1 0 : 0
		gettoken t2 0 : 0
		_`cmd' `"`t1'"' `"`t2'"' `0'
		ret add
	}
end

program define _header
	args level xname

	if `"`xname'"'!="" {
		capture confirm variable `xname'
		if _rc == 0 {
			local col1 "Variable"
		}
		else	local col1 "   Group"
	}

	di _n in smcl in gr /*
	*/ "{hline 9}{c TT}{hline 68}" _n /*
	*/ "`col1'" _col(10) "{c |}" _col(16) "Obs" /*
	*/ _col(27) "Prop" _col(35) "Std. Err." _col(47) "Std. Dev."     /*
	*/ _col(59) "[`level'% Conf. Interval]" _n /*
	*/ "{hline 9}{c +}{hline 68}"
end
/*
    5   10   15   20   25   30   35   40   45   50   55   60   65   70   75
++++|++++|++++|++++|++++|++++|++++|++++|++++|++++|++++|++++|++++|++++|++++|++++
Variable |     Obs        Prop    Std. Err.   Std. Dev.   [95% Conf. Interval]
---------+--------------------------------------------------------------------
     mpg | 1234567   123456789   123456789   123456789   123456789   123456789
*/

program define _botline
	di in smcl in gr "{hline 9}{c BT}{hline 68}"
end

program define _divline
	di in smcl in gr "{hline 9}{c +}{hline 68}"
end

program define _table
/*
    This program displays table with information about #obs, p, sd,
    when std. err. = (std. dev.)/sqrt(n).

    Syntax:
            _table level name #obs #succ

    Note: expressions without blanks are OK.
*/
	args level name n s se sd

	confirm integer number `n'
	confirm number `s'
	local p = `s'/`n'
	capture confirm number `sd'
	if _rc {
		local sd = sqrt(`p'*(1-`p'))
	}
	capture confirm number `se'
	if _rc {
		local se = (`sd')/sqrt(`n')
	}
	local q = invnorm((100+`level')/200)

	#delimit ;
	di in smcl in gr %8s abbrev(`"`name'"',8) " {c |}" in ye
		 _col(12) %7.0f `n'
		 _col(22) %9.0g `p'
		 _col(34) %9.0g `se'
		 _col(46) %9.0g `sd'
		 _col(58) %9.0g (`p')-`q'*(`se')
		 _col(70) %9.0g (`p')+`q'*(`se') ;
	#delimit cr
end

program define _center
/*
   Syntax:

   _center "string"                        [displays centered "string"]

   _center "string1" "string2" "string3"   [displays centered in 3 columns]

   @ character in string toggles color from green to yellow (or from yellow
   to green); green is the default and initial color.

   Example: "green @yellow@ green @yellow@"

*/
	local left  12  /* columns centered about these values */
	local mid   39
	local right 66

	if `"`2'"'=="" {
		Display `"`1'"' `mid' 0
		di /* newline */
		exit
	}

	Display `"`1'"' `left'  0
	Display `"`2'"' `mid'   `r(DispAt)'
	Display `"`3'"' `right' `r(DispAt)'
	di /* newline */
end

program define Display, rclass
	args string center last
	/* center = value to center about */
	/* last   = column of last character printed */

	Length `"`string'"'
	local length `r(length)'

	local skip = max((`last'!=0), `center' - int(`length'/2) - 1 - `last')

	di _skip(`skip') _c /* skip spaces */

	Print `"`string'"' /* print out string */

	ret scalar DispAt = `last'+`skip'+`length' /* last character printed */
end

program define Length, rclass
	args string
	local length 0
	while `"`string'"'!="" {
		local i = index(`"`string'"',"@")
		if `i' == 0 {
			local length = `length' + length(`"`string'"')
			local string
		}
		else {
			local length = `length' + `i' - 1
			local iplus1 = `i' + 1
			Substr `"`string'"' `iplus1' .
			local string `"`r(substr)'"'
		}
	}
	ret scalar length = `length'
end

program define Print
	args string
	local color "gr"
	while `"`string'"'!="" {
		local i = index(`"`string'"',"@")
		if `i' == 0 {
			di in `color' `"`string'"' _c
			local string
		}
		else {
			local iminus1 = `i' - 1
			Substr `"`string'"' 1 `iminus1'
			di in `color' `"`r(substr)'"' _c

			if "`color'"=="gr" { local color ye }
			else local color gr

			local iplus1 = `i' + 1
			Substr `"`string'"' `iplus1' .
			local string `"`r(substr)'"'
		}
	}
end

program define Substr, rclass
	args string a b

	if `b' == . {
		local b = length(`"`string'"') - `a' + 1
	}

	local sub = substr(`"`string'"',`a',`b')

	local lsub = length(`"`sub'"')

	if `lsub' < `b' {
		local nblank = `b' - `lsub'
		local blanks : di _skip(`nblank') 
		local sub `"`blanks'`sub'"'
	}

	ret local substr `"`sub'"'
end
exit

------------------------------------------------------------------------------
NOTES
------------------------------------------------------------------------------

Comments:
*?	- unclear what to do
*c	- yet to be checked
*r	- remove later

Examples:

McNemar test:
	ztesti 5 7

One sample test:
	ztesti 13 5 .5

Two sample test:
	ztesti 13 5 18 7
<end>
