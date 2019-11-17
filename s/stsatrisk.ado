*! version 1.0.1 26jun2003 Jean Marie Linhart and Jeffrey S. Pitblado
*! version 1.0.2 2dec2003 addition Jens Lauritsen of showing group labels
*! version 1.0.3 18dec2003 Jean Marie Linhart added many options
*! version 1.0.4 02jan2004 Jean Marie Linhart small improvements
*! version 1.0.5 18mar2004 Jean Marie Linhart fix for stsplit data
*! version 1.0.6 26apr2004 Jean Marie Linhart fix mult rec and respect tmax tmin
program define stsatrisk, sort
	version 8
	st_is 2 analysis
	syntax [if] [in] [,			///
		CATRisk(passthru)		///
		per(real 1.0)			///
		tmax(real 0.0)			/// label space adj
		tmin(real 0.0)			/// label space adj
		SEParate			///
                noLabel                         ///
		SHOWEvents			///
		TABLEGend			/// Table legend
		CLabel(passthru)		///
		TABLABel(string )		/// table label
		LLength(int 16)			/// label length
		LSpace(real 1.0)		/// label space adj
		VSpace(real 1.0)		/// vertical space adj 
		STrata(varlist)			///
		Hazard Gwood NA CNA		/// NOT allowed
		XMTIck(passthru)		/// NOT allowed
		YMTIck(passthru)		/// NOT allowed
		TLABel(passthru)		/// NOT allowed
		XTIck(passthru)			/// NOT allowed
		*				/// -graph- options
	]
	if `tmax' != 0 {
		local tma tmax(`tmax')
	}
	if `tmin' != 0 {
		local tmi tmin(`tmin')
	}
	local showev `showevents'
	local tabl `tablegend'
	
	if `"`separate'"' != "" {
		di as err "option separate is not allowed with stsatrisk"
		exit 198
	}
	if `"`xmtick'"' != "" {
		di as err "option xmtick() is not allowed with stsatrisk"
		exit 198
	}
	if `"`ymtick'"' != "" {
		di as err "option ymtick() is not allowed with stsatrisk"
		exit 198
	}
	if `"`tlabel'"' != "" {
		di as err "option tlabel() is not allowed, use
		catrisk()"
		exit 198
	}
	if `"`xtick'"' != "" {
		di as err "option xtick() is not allowed, use catrisk()"
		exit 198 
	}
	if `"`hazard'`na'`cna'"'!="" {
	di as err "hazard, na, cna may not be specified with stsatrisk"
		exit 198
	}
	local gropts `"`options'"'
	_get_gropts , graphopts(`gropts') grbyable
	local by `s(varlist)'
	if "`strata'"!="" & "`by'"!="" {
		di as err "strata may not be specified with by in stsatrisk"
		exit 198
	}
	else if "`strata'"!="" {
		local by `"`strata'"'
	}
	if `"`by'"' != "" & `"`gwood'"' != "" {
	di as err "gwood may not be specified with by or strata in stsatrisk"
		exit 198
	}

	/* go grab out the custom labels into a useable macro */
	CLABEL `clabel'

	marksample touse
	qui replace `touse' = 0 if !_st
	CATRISK if `touse', `catrisk' `tma' `tmi'
	local catrisk `s(catrisk)'
	local txtopts `s(txtopts)'
	
	/* start defining our space.  
	 * First, get the range of the time variable. */
	summarize _t if `touse', mean
	local rmin : word 1 of `catrisk'
	local wc : word count `catrisk'
	local rmax : word `wc' of `catrisk'
	if r(min) < `rmin' {
		local rmin `r(min)'
	}
	if r(max) > `rmax' {
		local rmax r(max)
	}
	local ranget = `rmax'-`rmin'
	
	/* Label space definition.
	 * Define where our x position for text is (xtx) is.
	 * we put it outside the normal graph by a fraction of
	 * the range.  You can modify the label space with the lspace
	 * option to give more or less label space (horizontal space) */
	local xtx = (`rmin'-`ranget'/5)*`lspace'
	
	/* the starting yposition for text.  The base range for
	 * survival plots is 0 to 1, so we go down by a .1 step
	 * from zero.  If `per' was specified, we multiply by
	 * that (since per multiplies the yrange).  Then
	 * we multiply by the user specified vspace multiplier
	 * which gives more or less vertical space. */
	local ypos = -( 0.1 )*`per' * `vspace'
	/* the first bit of text to add is the table label */
	if `"`tablabel'"' == "" {
		if `"`showev'"' !="" {
			local tablabel "At risk (events):"
		}
		else {
			local tablabel "At risk:"
		}
	}
	if (length(`"`tablabel'"') > 20) & `lspace'==1.0 {
		local lspace 1.5
	}
	local addtext `"text(`ypos'  `xtx'  `"`tablabel'"', `txtopts')"'
	
	
	/* define groups as specified by the by() option */
	tempvar group
	quietly egen int `group' = group(`by') if `touse'
	summarize `group' if `touse', mean
	local ngroup = r(max)
	/* too many and my hack to get things positioned right
	 * will break down */
	local ncatr : word count `catrisk'
	if `ngroup'*`ncatr'>30 {
		di as err "Too much information!  The number of -by-" _c
		di as err " groups times the number of at risk" _c
		di as err " labels must be 30 or less."
		exit 198
	}
	
	
	/* Determine the number of by variables.
	 * if there is one by variable, and it has labels we
	   are probably going to use them to label the at risk groups
	   if there are no custom labels specified */
	local nby : word count `by'
	if `nby' == 1 {
		tempvar mybyv
		qui gen `mybyv' = _n if `group'==1
	}

	
	/* Make a table in the legend */
	if "`tabl'" != "" {
		local lrd `"order(- " ""'
		local lrd2 `" - "Events""'
		local lrd3 `" - "Total""'
	}
	else if `"`clabel'"'!="" {
		local lrd `"order("'
	}
	/* In the forval j=1/`ngroup' loop we will
	 * first Define the At risk labels.  
	 * second Define the At risk data and event data */
	forval j = 1/`ngroup' {
	/* each group (row) gets its own yposition, this defines it.
	   This is a hack, I fiddled with the parameters until it looked
	   like it was working */
		local ypos = -( 0.1 + .125*(`j'))*`per'*`vspace'
		if (`ngroup'>1)	{
			local lab 
			/* one by variable, so can try to use value
			   labels */
			if `nby' == 1 {
		     		// addition by Jens lauritsen to show value
				// labels instead of group number
				/* get value label */
				local lab1: value label `by'
				/* scratch out `mybyvar' and
				get in it the value for the group
				we are on */
				qui replace `mybyv' = .
				qui replace `mybyv' = _n if `group'==`j'
				quietly summ `mybyv', meanonly
				local byv = `by'[r(min)] /* this is the value*/
				/* take the label from this value, restrict
				length to llength */
				capture local lab: label `lab1' `byv' ///
					`llength'
				/* if we've got a string variable, we
				 * want to use its value for the label */
				capture confirm numeric variable `by'
				if (_rc) {
					local lab `byv'
				}
			}
			/* If we have custom labels, they will be used
			 * to label the groups (rows).  Get
			 * the label we are on */
			local clab : word `j' of `clabel'
			/* if there is one replace the label with it */
			if (`"`clab'"' != "") local lab "`clab'"
			/* now, if there STILL isn't a label or
			if we said nolabels put a generic label on it */
			if ("`lab'" == "" | "`label'" != "" )	///
				local lab "`byv'"
			/* if there is more than one by variable that
			 * won't work, so label something generic */
			if (`"`lab'"' == "") ///
				local lab "At risk `j'"
		}
		else { /* only one group */
			local lab `clabel'
			if `"`lab'"' == "" { /* no custom label, use default */
				local lab ""
			}
		}
		/* legend */
		if "`tabl'" != "" | `"`clabel'"' != ""{
			local lrd `"`lrd' `j' `"`lab'"' "'
		}
                /* this addtext labels the row */
		local addtext `addtext'	///
			text(`ypos' `xtx' "`lab'", `txtopts')
		
		/* Now add the at risk and event data to the
		 * table */
		local ni : word count `catrisk'
		local ni = `ni' -1
		/* count the at-risk and the events */
		forval i = 1/`ni' {
			local k : word `i' of `catrisk'
			local i2 = `i'+1
			local k2 : word `i2' of `catrisk'
			if (`k' == 0) {
				quietly count if _t>=`k'&`group'==`j'&`touse'& _t0<=`k'
				local atrisk `r(N)'
			}
			else{
				quietly count if _t>=`k'&`group'==`j'&`touse'& _t0<`k'
				local atrisk `r(N)'
			}
			quietly count if (_d & ~missing(_d) & _t >= `k' & _t< `k2' ///
				&`group'==`j'&`touse' )
			local events `r(N)'
			local k2 = (`k' + `k2')/2
			/* add the at risk text */
			local addtext	///
			`"`addtext' text(`ypos' `k' "`atrisk'", `txtopts')"'
			if `"`showev'"' != "" {
			/* add the events text */
			local addtext	///
			`"`addtext' text(`ypos' `k2' "(`events')", `txtopts')"'
			}
		}
		/* the last one does not have events text, just at 
		 * risk text */
		local ni = `ni' + 1
		local k : word `ni' of `catrisk'
		quietly count if _t>=`k'&`group'==`j'&`touse'
		local atrisk `r(N)'
		local addtext	///
			`"`addtext' text(`ypos' `k' "`atrisk'", `txtopts')"'
		
		/* legend table, events then at risk info */
		if "`tabl'" != "" {
			quietly count if (_d & _t >= 0 ///
				&`group'==`j'&`touse')
			local lrd2 `"`lrd2' - "`r(N)'" "'
			quietly count if _t>=0&`group'==`j'&`touse'
			local lrd3 `"`lrd3' - "`r(N)'" "'
		}
	}
	
	if "`tabl'" != "" {
       		local lrd3 `"`lrd3' )"'
		local lrd `"legend(`lrd' `lrd2' `lrd3' on colfirst cols(3))"'
        }
	else if `"`clabel'"' != "" {
		local lrd `"legend( `lrd' ) )"'
	}
	/* Now we need to create space for this table.  We are
	 * going to make the graph smoosh to
	 * give us space via adding an invisible xmtick and ymtick */
	/* y position of the invisible ymtick.  Current text position
	 * then subtract 0.05*`per'*`vspace', since `per' and `vspace'
	 * both adjust the vertical space.  */
	local marg = `ypos'-(0.05*`per'*`vspace')
	/*  The xmtick is placed at the xtx location - 1/8 of the range
	 * *`lspace' to make place for the table heading and labels.
	 * The ymtick is just below the lowest of the text written above
	 * (-0.05*`per'*`vspace' below).  */
	local adjust					///
		ymtick(`marg' , notick)			///
		xmtick(`=`xtx'-(`ranget'/8)*`lspace'' , notick)	///
		// blank
	if `"`strata'"' != "" {
		local strata strata(`strata')
	}
	sts graph if `touse',			///
		`adjust'			///
		xlabel(`catrisk')		///
		`addtext'			///
		per(`per') `tma' `tmi' `strata' `gwood'	///
		`lrd' `options'

end


program CATRISK, sclass
	syntax [if] [, CATRisk(string asis) tmax(real 0.0) tmin(real 0.0)]
	local iftouse `if'
	local 0 `catrisk'
	syntax [anything] [, * ]
	local txtopts `"`options'"'
	local 0 , catrisk(`anything')
	syntax [, catrisk(numlist sort) ]
	if "`catrisk'" == "" {
		summarize _t `iftouse', mean
		if `tmin' == 0.0 {
			local tmin `r(min)'
		}
		if `tmax' == 0.0 {
			local tmax `r(max)'
		}
		_natscale `tmin' `tmax' 5
		numlist "`tmin'(`r(delta)')`tmax'", ascending sort
		local catrisk `r(numlist)'
	}

	sreturn clear
	sreturn local txtopts `txtopts'
	sreturn local catrisk `catrisk'
end

program define CLABEL
	local lab `0'
	local lab2 : subinstr local lab "clabel(" ""
	
	local lab3 : subinstr local lab2 ")" ""
	c_local clabel `"`lab3'"'
end
	


