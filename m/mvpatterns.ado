*! 2.0.0  10jan2001   (STB-61: dm91)
* uses variables _mv _pattern _freq
program define mvpatterns, rclass by(recall) sort
	version 7.0

	syntax [varlist] [if] [in] [, Minfreq(int 1) noTable SKip SOrt noDrop]

	* scratch
	tempvar  g isf mv_patt mv_n ng
	tempname nsmall nsmallg

	* touse: marks included observations

	marksample touse, novarlist
	qui count if `touse'
	local N = r(N)

	* select/sort variables

	foreach v of local varlist {
		qui count if missing(`v') & `touse'
		if r(N) > 0 | "`drop'" != "" {
			local p : display %8.0f r(N)
			local nmv `nmv' `p'
			local vlist `vlist' `v'
		}
		else	local varnomv `varnomv' `v'
	}
	local varlist `vlist'
	if "`sort'" != "" {
		qsortidx `nmv' \ `varlist' , descend
		local varlist `s(slist2)'
	}
	if "`varnomv'" != "" {
		di as txt "{p 0 20}variables with no mv's: {res}`varnomv'" _n
	}

	* ===================================================================
	* display list-of-variables
	* ===================================================================

	local nvar : word count `varlist'
	local linesize : set linesize

	if "`table'" == "" {
		local len 14
		foreach v of local varlist {
			local vlab : var label `v'
			local len = max(`len', length(`"`vlab'"'))
		}
		local vlwidth = min(`linesize'-35,`len')   /* width for varlabel */
		local ndup = 21 + `vlwidth'                /* #dashes in line */

		di as txt "Variable     {c |} type     obs   mv   variable label"
		di as txt "{hline 13}{c +}{hline `ndup'}"

		local i 0
		foreach v of local varlist {
			local i = `i'+1

			qui count if missing(`v') & `touse'
			local nmv = r(N)

			local vt : type `v'
			local vlab : var label `v'
			local vl : piece 1 `vlwidth' of `"`vlab'"'

			local vn = abbrev("`v'",12)
			di "{txt}{lalign 12:`v'}{col 14}{c |}{res}" /*
			 */ _col(16) "`vt'"           /*
			 */ _col(23) %5.0f `N'-`nmv'  /*
			 */ _col(28) %5.0f `nmv'      /*
			 */ _col(36) `"{txt}`vl'"'

			* rest of variabele label
			local j 2
			local vl : piece `j' `vlwidth' of `"`vlab'"'
			while `"`vl'"' != "" {
				di `"{txt}{col 14}{c |}{col 36}`vl'"'
				local j = `j'+1
				local vl : piece `j' `vlwidth' of `"`vlab'"'
			}

		 	* seperator line
			if "`skip'" != "" & `i' >= 1 & mod(`i',5) == 0 {
				di as txt "{hline 13}{c +}{hline `ndup'}"
			}
		}
		di as txt "{hline 13}{c BT}{hline `ndup'}"
	}
	else {
		* list of variables only
		di as txt "variables   {...}"
		forv i = 1 / `nvar' {
			local vn = abbrev("``i''",12)
			di "{lalign 12:`vn'} {...}"
			if mod(`i',5) == 0 {
				if `i' < `nvar' { di _n "{space 12}{...}" }
			}
		}
		display
	}

	* ===================================================================
	* patterns
	* ===================================================================

	local nskip = cond("`skip'"!="", int((`nvar'-1)/5), 0)
	if `nvar' > 80 | 15+`nvar'+`nskip' > `linesize' {
		if `nvar' <= 80 & 15+`nvar' <= `linesize' {
			di as txt "too many variables to honor option -skip-"
			local skip
			local nskip 0
		}
		else {
			di in err "too many variables to list"
			exit 198
		}
	}
	local nstr = `nvar'+`nskip'

	quietly {
	  	* mv_patt: string representation of missing value pattern
	  	gen str`nstr' `mv_patt' = "" if `touse'
		* mv_n:    #mv's in observation
		gen int `mv_n' = 0 if `touse'

		tokenize `varlist'
		forv i = 1 / `nvar' {
			if "`skip'" != "" & `i' > 1 & mod(`i'-1,5) == 0 {
				replace `mv_patt' = `mv_patt' + " " if `touse'
			}
			replace `mv_patt' = `mv_patt' + cond(missing(``i''),".","+") if `touse'
			replace `mv_n'    = `mv_n'    + 1           if missing(``i'') & `touse'
		}

		bys `touse' `mv_patt' : gen byte `g'=1  if _n==1 & `touse'==1
		summ `g'
		replace `g' = sum(`g')
		replace `g' = .  if `touse'!=1

		bys `g' : gen `isf' = (_n==1) & `touse'
		bys `g' : gen `ng' = _N  if `touse'
		count if `ng' < `minfreq' & `touse'
		scalar `nsmall' = r(N)
		count if `ng' < `minfreq' & `isf' & `touse'
		scalar `nsmallg' = r(N)
		replace `isf' = 0 if `ng' < `minfreq' & `isf' & `touse'
		gsort -`ng' `mv_n' `mv_patt'
	}

   * ===================================================================
	* display patterns
   * ===================================================================

	if `minfreq' > 1 & `nsmallg' > 0 {
		di _n as txt "Patterns of missing values (freq >= `minfreq')"
	}
	else	di _n as txt "Patterns of missing values"

	* list patterns and frequencies
	nobreak {
		capture drop _pattern
		capture drop _mv
		capture drop _freq
		rename `mv_patt' _pattern
		rename `mv_n'    _mv
		rename `ng'      _freq
		format _freq %7.0f
		format _mv   %4.0f
		capture break noisily list _pattern _mv _freq if `isf', noobs
		drop _pattern _mv _freq
	}

	* summarize patterns not listed
	if `nsmallg' > 0 {
		if `minfreq' == 2 {
			di _n as txt "In addition: {res} " `nsmall'  /*
			  */ "{txt} observations with unique missing values patterns"
		}
		else	di _n as txt "In addition:{res} "`nsmall' "{txt} observations in " /*
			  */ "{res}" `nsmallg' "{txt} patterns with " /*
			  */ "frequency < `minfreq'"
	}
end
exit

Possible enhancement
--------------------

* Is it useful to "export" groupsize etc?
* Had anybody ever considered using "boolean factor-analysis" (compare BMDP)
  to study missing value patterns?
* should we also display (tetrachoric) correlation between missingness of
  variables, or even a factor-analysis of it?
* should we propensity scores?
