*! version 1.2.0  07may2003                     (SJ3-4: st0049, st0050, st0051)
program define _crcdeq
	version 6.0
	local cmd "`1'"
	mac shift
	local 0 "`*'"

	#delimit ;
	syntax [, noRMDUP noRMCOLL noIF noIN INS HET SEL INF
		ALPHA(string) WEIGHT(string) TOUSE(string) ] ;
	#delimit cr

	local earg "noCONStant nc OFFset(string) off" 
	if "`ins'"     != "" { local rarg "`rarg' INSTrument ins" }
	if "`het'"     != "" { local rarg "`rarg' HETeros het"    }
	if "`sel'"     != "" { local rarg "`rarg' SELection sel"  }
	if "`inf'"     != "" { local rarg "`rarg' INFlation inf"  }
	if "``alpha''" != "" { local rarg "`rarg' `alpha' alp"    }
	if "`rarg'"    != "" { local rarg "roles(`rarg')"         }
	meqparse `"`cmd'"', `rarg' eqopts(`earg')

	if "`weight'" != "" {
		local weight "[`weight'/]"
	}

	if "`if'"=="" { local ifstr "[if]" }
	if "`in'"=="" { local instr "[in]" }

	#delimit ;
	syntax  `ifstr' `instr' [, ROBust CLuster(string)
		SCore(string) FROM(string) SKIP *] ;
	#delimit cr

	*mlopts mlopts opts, `options'	/* !! taken out on purpose */
	local opts `"`options'"'	/* !! to take place of mlopts */


	if "`cluster'" != "" {
		unabbrev `cluster', max(1)
		local cluster "`s(varlist)'"
		local clopt   "cluster(`cluster')"
		local robust  "robust"
	}
	if "`weight'"=="pweight" { local robust "robust" }

	if "`touse'" == "" { local use "*" }
	`use' mark `touse' `if' `in'
	`use' markout `touse' `cluster', strok

	if "`touse'" != "" {
		local i 1
		while `i' <= `e_n' {
			markout `touse' `e_y`i'' `e_x`i'' `off`i''
			local i = `i'+1
		}
	}
	if "`rmcoll'" == "" & "`touse'" != "" {
		local i 1
		while `i' <= `e_n' {
			_rmcoll `e_x`i'' if `touse', `nc`i''
			local i = `i'+1
		}
	}
	if "`score'" != "" {
		local n : word count `score'
		c_local nscores `"`n'"'
		local i 1
		while `i' <= `e_n' {
			local sss : word `i' of `score'
			confirm new var `sss'
			local i = `i'+1
		}
		c_local scvar "`score'"
	}


	/* Save macros */
	c_local inx	`"`in'"'
	c_local ifx	`"`if'"'
	c_local robust	"`robust'"
	c_local opts	`"`opts'"'
	c_local skip	"`skip'"
	c_local from	"`from'"
	c_local neq	"`e_n'"
	if "`weight'" != "" {
		c_local wtexp	`"`exp'"'
		c_local wtype	`"`weight'"'
		c_local wgt	`"[`weight'=`exp']"'
		local wtexp	"[`weight'=`exp']"
	}
	if "`cluster'" != "" {
		c_local clvar	`"`cluster'"'
		c_local clopt	`"cluster(`cluster')"'
	}
	local i 1
	while `i' <= `e_n' {
		if "`off`i''" != "" {
			c_local off`i'	"`off`i''"
			c_local offo`i'	"offset(`off`i'')"
		}
		c_local dep`i'	`"`e_y`i''"'
		c_local ind`i'	`"`e_x`i''"'
		c_local role`i'	`"`e_ro`i''"'
		c_local ref`i'	`"`e_re`i''"'
		c_local nc`i'	`"`nc`i''"'
		c_local eq`i'	`"`e_`i''"'
		local i = `i'+1 
	}
end
