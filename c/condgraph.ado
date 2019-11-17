*! Version 1.0.1   Marcelo Moreira and Brian Poi    (SJ3-1: st0033)
* Graphs test statistics and critical values as discussed in Moreira (2002)
* Created 20020811 by Brian Poi 
* Modified 20030130 by Brian Poi

* Changelog
* version 1.0.1 checks for version 8 and uses version 8 graphics if
* available.

* condgraph , stats(string) [reps(integer 200) range(numlist min=2 max=2) 
* 	points(integer 20) level(integer 95) saving(string) 
*  	replace text comma]

program define condgraph, rclass

	capture local grversion = _caller()
	if _rc != 0 {
	   local grversion = 7
	}

	version 7.0
 
	if "`e(cmd)'" ~= "condivreg" {
		di as error "last estimates not found."
		exit 301 
	}
	tempname results
	estimates hold `results', copy restore

	syntax , stats(string) [reps(integer 200) range(numlist min=2 /*
		*/ max=2) points(integer 20) level(integer 95) /*
		*/ saving(string) replace text comma]

	/* Some syntax checking.	*/
	if ("`saving'" == "" & "`replace'" ~= "") {
		di as error /*
		   */ "replace is only to be used if saving() is specified."
		exit 198
	}
	if ("`saving'" == "" & "`text'" ~= "") {
		di as error /*
			*/ "text is only to be used if saving() is specified."
		exit 198
	}
	if ("`saving'" == "" & "`comma'" ~= "") {
		di as error /*
			*/ "comma is only to be used if saving() is specified."
		exit 198
	}
	if ("`text'" == "" & "`comma'" ~= "") {
		di as error "comma is only to be used if text is specified."
		exit 198
	}
	if (`level' < 1 | `level' > 99) {
		di as error "level() must be an integer between 1 and 99."
		exit 198
	}
	if "`range'" ~= "" {
		loc rangeptcnt : word count `range'
	}
	else {
		loc rangeptcnt = 0
	}
	loc msize : set matsize
	if `msize' < `points' {
		di as error 
		"You must {cmd:set matsize} at least as large as points()."
		di as error "matsize too small"
		exit 908
	}
	if `rangeptcnt' == 2 {
		loc grmin : word 1 of `range'
		loc grmax : word 2 of `range'
		if (`grmin' == . | `grmax' == .) {
			di as error "Invalid graph() specification."
			exit 198
		}
	}
	loc grcnt : word count `stats'
	if (`grcnt' > 2) {
		di as error "You can specify at most two statistics to graph."
		exit 198
	}
	loc grlines = ""
	foreach x in `stats' {
		if ("`x'" == "ar" | "`x'" == "AR") {
			loc grlines "`grlines' ar"
		}
		else if ("`x'" == "lm" | "`x'" == "LM" | "`x'" == "score" /*
				*/ | "`x'" == "SCORE") {
			loc grlines "`grlines' lm"
		}
		else if ("`x'" == "lr" | "`x'" == "LR") {
			loc grlines "`grlines' lr"
		}
		else if ("`x'" == "wald" | "`x'" == "WALD") {
			loc grlines "`grlines' wald"
		}
		else {
			di "Illegal stats() specification"
			exit 198
		}
	}
	/* End of syntax checking.	*/

	quietly{
		tempname touse
		gen `touse' = e(sample)
		loc ry1 `e(depvar)'
		loc ry2 `e(instd)'
		/* Get graphics endpoints.	*/
		if (`rangeptcnt' ~= 2) {
			/* Compute our own graph endpoints.	*/
			tempname bg vg bg1 vg1 z
			mat `bg' = e(b)
			mat `vg' = e(V)
			mat `bg1' = `bg'[1, "`ry2'"]
			sca `bg1' = trace(`bg1')
			mat `vg1' = sqrt(det(`vg'["`ry2'","`ry2'"]))
			sca `vg1' = trace(`vg1')
			sca `z' = invnorm(0.5 + `level'/200)
			loc grmin = `bg1' - 2*`z'*`vg1'
			loc grmax = `bg1' + 2*`z'*`vg1'
		}
		/* get beta -- just the midpoint of the range.	*/
		loc beta = 0.5*(`grmin' + `grmax')

		/* Take care of constant term in main eq. if specified  */
		tempvar one
		gen `one' = 1
		if ("`e(cons)'" == "yes") {
			loc exog "`e(exog)' `one'"
		}
		else {
			loc exog "`e(exog)'"
		}
		loc instcons "`e(instcons)'"
		loc rinst "`e(inst)'"

		/* Regress raw y1, y2 on exog. */  
		tempvar y1 y2
		if ("`exog'" ~= "") {
			foreach v in y1 y2 {
				reg `r`v'' `exog' if `touse', nocons
				predict double ``v'' if `touse', residuals
			}
		}
		else {
			gen double `y1' = `ry1' if `touse'
			gen double `y2' = `ry2' if `touse'
		}
		/* Regress instruments on exog.*/
		loc inst = ""
		loc n = 1
		foreach v in `rinst' {
			tempvar inst`n'
			if ("`exog'" ~= "") {
				reg `v' `exog' if `touse', nocons
				predict double `inst`n'' if `touse', residuals
			}
			else {
				gen double `inst`n'' = `v' if `touse'
			}
			loc inst "`inst' `inst`n''"
		}
		/* Set up a and b vectors.  */
		tempname a b aprime bprime 
		mat `a' = (`beta'\1)
		mat `b' = (1\(-1*`beta'))
		mat `aprime' = `a''  /* Macro parser chokes  */
		mat `bprime' = `b''  /* otherwise.  */

		/* Compute Omega. */
		tempname mzy1 mzy2 n k omega
		if "`instcons'" == "yes" {
			reg `y1' `inst' if `touse'
		}
		else {
			reg `y1' `inst' if `touse', nocons
		}
		predict `mzy1' if `touse', residuals
		if "`instcons'" == "yes" {
			reg `y2' `inst' if `touse'
		}
		else {
			reg `y2' `inst' if `touse', nocons
		}
		predict `mzy2' if `touse', residuals
		mat accum `omega' = `mzy1' `mzy2', noconstant
		count if `touse'
		loc n = r(N)
		loc k : word count `inst'
		if ("`instcons'" == "yes") {
			loc k = `k' + 1
		}
		mat `omega' = `omega' / (`n'-`k')
		tempname oia
		mat `oia' = inv(`omega')*`a'
		/* Compute scalars b'*O*b and a'*O^-1*a	*/
		tempname bob aoia
		matrix `bob' = `bprime'*`omega'*`b'
		scalar `bob' = trace(`bob')
		matrix `aoia' = `aprime'*inv(`omega')*`a'
		scalar `aoia' = trace(`aoia')

		tempname cross zpz sqrtzpzi zpy sbar tbar
		if ("`instcons'" == "yes") {
			mat accum `cross' = `inst' `one' `y1' `y2' /*
				*/ if `touse', noconstant
		}
		else {
			mat accum `cross' = `inst' `y1' `y2' /*
				*/ if `touse', noconstant
		}
		mat `zpz' = `cross'[1..`k', 1..`k']
		mat `zpy' = `cross'[1..`k', (`k'+1)...]
		mat_inv_sqrt `zpz' `sqrtzpzi'
		/* The graphics routine includes an extra point at one end. */
		loc points = `points' - 1
		if "`instcons'" ~= "yes" {
			loc df = `k' - 1
		}
		else{
			loc df = `k'
		}
		ctgraph `grmin' `grmax' `points' `omega' `sqrtzpzi' `zpy' /*
			*/ `reps' `k' "`grlines'" `level' `df' "`saving'" /*
			*/ "`replace'" "`text'" "`comma'" `grversion'
	} /* quietly block */
  
end

/* Computes AR and LM statistics.	*/
prog def calcstat1

	args sbar tbar ar lm
	tempname sbarp tbarp

	mat `sbarp' = `sbar''
	mat `tbarp' = `tbar''
	mat `ar' = `sbarp'*`sbar'
	sca `ar' = trace(`ar')
	mat `lm' = (trace(`sbarp'*`tbar')^2) / trace(`tbarp'*`tbar')
	sca `lm' = trace(`lm')

end 

/* Computes LR and Wald statistics.	*/
prog def calcstat2

	args sbar tbar aoia bob beta omega lr wald
	tempname sbarp tbarp

	mat `sbarp' = `sbar''
	mat `tbarp' = `tbar''
	tempname ss st tt
	mat `ss' = `sbarp'*`sbar'
	sca `ss' = trace(`ss')
	mat `tt' = `tbarp'*`tbar'
	sca `tt' = trace(`tt')
	mat `st' = `sbarp'*`tbar'
	sca `st' = trace(`st')
	sca `lr' = 0.5*(`ss' - `tt' + sqrt((`ss' + `tt')^2 - /*
		*/ 4*(`ss'*`tt' - (`st')^2)))
  
	/* Wald is a fscking mess.*/
	tempname c d denom y2nzy2 y2nzy2i y2nzy1 middle num dp /*
		*/ b2sls b2slsp dif difp
	sca `denom' = (`omega'[1,1] - 2*`omega'[1,2]*`beta' + /*
		*/ `omega'[2,2]*`beta'^2)
	sca `num' = (`omega'[1,1]*`omega'[2,2] - `omega'[1,2]^2) 
	mat `c' = ( (`omega'[1,1] - `omega'[1,2]*`beta')/`denom' \ /*
		*/ `beta'*`num'/`denom' )
	mat `d' = ( (`omega'[1,2] - `omega'[2,2]*`beta')/`denom' \ /*
		*/ `num'/`denom')
	mat `dp' = `d''
	mat `middle' = ( `bob'*`sbarp'*`sbar',  /*
		*/ (sqrt(`bob')*sqrt(`aoia')*`sbarp'*`tbar') \ /*
		*/ (sqrt(`bob')*sqrt(`aoia')*`sbarp'*`tbar'), /*
		*/ `aoia'*`tbarp'*`tbar' )
	mat `y2nzy2' = `dp'*`middle'*`d'
	mat `y2nzy1' = `dp'*`middle'*`c'
	mat `y2nzy2i' = inv(`y2nzy2')
	mat `b2sls' = (1 \ (-1*`y2nzy2i'*`y2nzy1'))
	mat `b2slsp' = `b2sls''
	mat `denom' = `b2slsp'*`omega'*`b2sls'
	sca `denom' = trace(`denom')
	sca `b2sls' = -1*`b2sls'[2, 1]
	sca `dif' = `b2sls' - `beta'
	mat `wald' = `dif'^2*`y2nzy2'/`denom'
	sca `wald' = trace(`wald')

end

/* Graphics option here.	*/
/* results has b0, AR, ARcrit, LM, LMcrit, LR, LRcrit, Wald, Waldcrit */
prog def ctgraph

	args bmin bmax grpoints omega sqrtzpzi zpy reps k grlines level /*
		*/ df saving replace text comma grversion

	tempname a b aprime bprime oia aoia bob random ar lm lr wald sbar /*
		*/ tbar results

	local morecond : set more
	set more off

	/* This finds out if we need to do monte carlo to get crit. vals. */
	loc dosims = 0
	foreach x in `grlines' {
		if ("`x'" == "lr" | "`x'" == "wald") {
			loc dosims = 1
		}
	}
	if (`"`saving'"' ~= "") {
		loc dosims = 1
	}

	mat `results' = J((`grpoints'+1), 9, 0)
	loc step = (`bmax' - `bmin')/`grpoints'
	loc i = 1
	while (`i' <= (`grpoints'+1)) {
		loc beta = `bmin' + (`i'-1)*`step'
		mat `a' = (`beta'\1)
		mat `b' = (1\(-1*`beta'))
		mat `aprime' = `a''  /* Macro parser chokes  */
		mat `bprime' = `b''  /* otherwise.  */
		mat `oia' = inv(`omega')*`a'
		matrix `bob' = `bprime'*`omega'*`b'
		scalar `bob' = trace(`bob')
		matrix `aoia' = `aprime'*inv(`omega')*`a'
		scalar `aoia' = trace(`aoia')
		mat `sbar' = `sqrtzpzi'*`zpy'*`b'/sqrt(`bob')
		mat `tbar' = `sqrtzpzi'*`zpy'*`oia'/sqrt(`aoia')
		calcstat1 `sbar' `tbar' `ar' `lm'
		calcstat2 `sbar' `tbar' `aoia' `bob' `beta' `omega' `lr' `wald'
		mat `results'[`i', 1] = `beta'
		mat `results'[`i', 2] = `ar'
		mat `results'[`i', 3] = invchi2tail(`df', (1-`level'/100))
		mat `results'[`i', 4] = `lm'
		mat `results'[`i', 5] = invchi2tail(1, (1-`level'/100))
		mat `results'[`i', 6] = `lr'
		mat `results'[`i', 8] = `wald'
		/* Now get the critical values for LR and Wald	*/
		if `dosims' == 1 {
			quietly{
				preserve
				tempname random
				tempvar lrvals waldvals
				drop _all
				set obs `reps'
				mat `random' = J(`k', 1, 0)
				gen double `lrvals' = 0
				gen double `waldvals' = 0
				forv t = 1/`reps' {
					/* Get a random vector for sbar.*/
					forv j = 1/`k' {
						mat `random'[`j', 1] = /*
							*/ invnorm(uniform())
					}
					/* Compute LR and Wald statistics.  */
					calcstat2 `random' `tbar' `aoia' /*
						*/ `bob' `beta' `omega' /*
						*/ `lr' `wald'
					replace `lrvals' = `lr' in `t'
					replace `waldvals' = `wald' in `t'
				}
				_pctile `lrvals', p(`level')
				mat `results'[`i', 7] = r(r1)
				_pctile `waldvals', p(`level')
				mat `results'[`i', 9] = r(r1)
				restore
			}
		}
		loc i = `i' + 1
	}
	di
	preserve
	drop _all
	mat coln `results' = beta ar arcrit lm lmcrit lr lrcrit wald waldcrit
	qui svmat `results', names(col)
	noi di  `"`saving'"'
	if (`"`saving'"' ~= "") {
		if (`"`text'"' == "") {
			capture save `"`saving'"', `replace'
			if (_rc ~= 0) {
di as error "File `saving'.dta already exists or something else failed."
di as error "Use replace to overwrite."
			}
		}
		else {
			capture outsheet using `"`saving'"', `replace' `comma'
			if (_rc ~= 0) {
di as error "File `saving'.out already exists or something else failed."
di as error "Use replace to overwrite."
			}
		}
	}
	/* Go through and make up the graph command based on grlines.  */
	loc grcmd ""
	foreach x in `grlines' {
		loc grcmd = "`grcmd' `x' `x'crit"
	}
	loc wc : word count `grlines'
	if `wc' == 2 {
		loc grcon = "ll[-]l[_]l[.]"
		loc grsym = "o.o."
	}
	else {
		loc grcon = "ll[-]"
		loc grsym = "o."
	}
	loc grcmd = "`grcmd' beta"
	loc mid = 0.5*(`bmin'+`bmax')
	if (match("`grlines'", "*lr*") | match("`grlines'", "*wald*")) {
		loc gropt = "yline(3.8415)"
		loc subtitle = "Asymptotic CV also shown"
	}
	else {
		loc gropt = ""
		loc subtitle = ""
	}
	if `wc' == 1 {
		loc title "Confidence Region"
		loc ylab "Test statistic and critical value"
	}
	else {
		loc title "Confidence Regions"
		loc ylab "Test statistics and critical values"
	}
	if (`grversion' < 8) {
   		graph `grcmd', c(`grcon') s(`grsym') ylabel /*
			*/ xlabel(`bmin', `mid', `bmax') /*
			*/ ti(`"`title'"') `gropt' r2(`"`subtitle'"') /*
			*/ l2(`"`ylab'"')
	}
	else {
		version 8 : line `grcmd' , ti(`"`title'"') `gropt' /*
			*/ r2(`"`subtitle'"') ytitle(`"`ylab'"')
	}
	restore
	
	set more `morecond'

end

prog def mat_inv_sqrt

	args in out
	tempname v vpri lam srlam

	loc k = rowsof(`in')
	mat symeigen `v' `lam' = `in'
	mat `vpri' = `v''
	/* Get sqrt(lam)  */
	mat `srlam' = diag(`lam')
	forv i = 1/`k' {
		mat `srlam'[`i', `i'] = 1/sqrt(`srlam'[`i', `i'])
	}
	mat `out' = `v'*`srlam'*`vpri'

end

