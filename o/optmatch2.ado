program optmatch2, rclass

*! $Revision: 1.1 $
*! Author:  Mark Lunt
*! Date:    March 13, 2012 @ 15:07:05

	// Todo: Balancing: needs extra nodes
	//       Allow Linfinity distance measure (possibly others)
	//       Allow Mahalanobis distance

version 9

syntax varlist [if] [in] [, MINc(real 1) MAXc(integer 1) Nc(integer 0)      ///
			Omit(real 0) Gen(string) Id(string) TRace(integer 0) CALiper(real 0) ///
			Measure(string) EPSilon(real 0.000001) metric(string) REPeat  ///
			distmat(name) wt(string) TEMPdir(string)]

	display

	if "`tempdir'" == "" {
		tempfile fred
		_getfilename "`fred'"
		local fred2 = r(filename)
		local tempdir = substr("`fred'",1,strpos("`fred'","`fred2'")-2)
	}
	
// Get treatment and matching variables
	tokenize `varlist'
	local treated `1'
	macro shift
	local matcher `*'

// Create variable to hold the matched set identifiers
	if "`gen'" == "" {
		local gen set
	}
	qui isvar `gen'
	if "`gen'" == "`r(varlist)'" {
		noi di as error "The variable " as result "`gen' " as error ///
				"already exists: unable to proceed."
		exit 110
	}

  if "`wt'" != "" {
    qui isvar `wt'
    if "`wt'" == "`r(varlist)'" {
      noi di as error "The variable " as result "`wt' " as error ///
          "already exists: unable to proceed."
      exit 110
    }
  }

	// check that the measure requested is supported
	
	capture parse_dissim `measure', default(L2)
	if _rc == 0 {
		local dist_type `s(dist)'
		if "`dist_type'" == "L1" {
			local lpower 1
			local lroot  1
		}
		else if "`dist_type'" == "L2" {
			local lpower = 2
			local lroot  = 1/2
		}
		else if "`dist_type'" == "L2squared" {
			local lpower = 2
			local lroot  = 1
		}
		else if "`dist_type'" == "L" {
			local lpower = `s(darg)'
			local lroot  = 1/`s(darg)'
		}
		else if "`dist_type'" == "Lpower" {
			local lpower = `s(darg)'
			local lroot  = 1
		}
		else if "`dist_type'" == "Linfinity" {
			local lroot  = -1
		  local lpower = 0
		}
		else {
			noi di as error "Distance type `dist_type' is not supported"
			exit 198
		}
	}
	else {
		// Check if we have a mahalanobis type
		// Cater for M1,  M2, mahal (== M2), M(1), M(2)
		// M1 = M(1) = sqrt(M2) = sqrt(M(2)) = sqrt(mahal)
		if regexm(upper("`measure'"), "^M\(?([12])\)?") {
			local lpower = -1
			local lroot  = 0.5 * regexs(1)
		}
		else if regexm(upper("`measure'"), "MAHAL") {
			local lpower = -1
			local lroot  = 1
		}
		else {
			noi di as error "Distance type `dist_type' is not supported"
			exit 198
		}
	}

	if (`lpower' < 0)	{
		// Using mahalanobis distance: do we have metric or must we
		// calculate it ?
		if "`metric'" == "" {
			local k2: word count `matcher'
			tempname covmat metric
      if (`k2' > 1) {
        // calculate metric
        matcorr `matcher', m(`covmat') c
        matrix `metric' = invsym(`covmat')
      }
      else {
        // only have one variable
        summ `matcher'
        matrix `metric' = 1/`r(Var)'
      }
		}
		else {
			// Check metric is valid
			local k1 = colsof(`metric')
			local k2: word count `matcher'
			if `k1' != `k2' {
				noi di as error "Matrix `metric' is the wrong size"
				exit 503
			}
		}
	// Create a distance matrix to hold distances between observations
		local k1 = colsof(`metric')
		tempname distvec
		matrix `distvec' = J(1, `k1', 0)
	}
	
	// Check we have only one way to determine nc
	if `nc' != 0 & `omit' != 0 {
		noi di as error "You can only use at most one of the options {cmd:nc()} and {cmd:omit()}"
		exit 198
	}
	
	// Check we have a way of measuring distances
	if "`matcher'" == "" {
		noi di as error "You must tell me how to find distances between exposed and unexposed"
		exit 198
	}  
	
// Make sure that max number of controls is at least as big as min number	
	if `maxc' < `minc' {
		local maxc = `minc'
	}

	marksample touse
// calculate number of nodes
// = 2 + Nt + Nc
	tempname values
	if "`id'" == "" {
		tempvar ids
		quietly gen str10 `ids' = string(_n) if `touse'
	}
	else {
		local idtype : type `id'
	  if (substr("`idtype'", 1, 3) != "str") {
			tempvar ids
			quietly gen str10 `ids' = string(`id') if `touse'		
		}
		else {
			local ids `id'
		}
	}

	gsort -`touse' -`treated' `id'
	qui tab `treated' if `touse', matcell(`values')
	local n1 = el("`values'",1,1)
	local n2 = el("`values'",2,1)

	// Check there are enough controls for each case
	local flow = `n2'*`minc'
	if (`flow' > `n1') {
		noi di as error "There are not enough controls to match `minc' to each case"
		exit 2001
	}
	local nodes     = `n1' + `n2' + 2
	local csink_id   = `nodes'
	local overflow_id = `nodes' + 1
	local cdiff = `maxc' - `minc'
	local totextras = `n1' - `minc'*`n2'

	if `nc' == 0 {
		local nc = `maxc' * `n2'
		if `nc' > `n1' {
			local nc = `n1'
		}
	}
	else {
	  if `nc' > `n1' {
			noi di as error "There are not `nc' controls available for matching"
			exit 2001
		}
	}

//	noi di in red "`nc'"
	// n2 = number of treated
	// n1 = number of controls
	// calculate number of arcs
	// = Nt + Nt*Nc+ Nc
	local arcs = `n1' + `n2' + `n1'*`n2'
	if (`maxc' > `minc') {
		local arcs = `arcs' + `n2' + 1
	}
	quietly gen `gen' = .
	
	plugin call solver `ids' `gen' `matcher'

	if `ucount' < `nc' {
		noi di as text "Unable to match {result:`nc'} controls"
		noi di as text "Only {result:`ucount'} are matcheable."
		quietly replace `gen' = .
		if "`repeat'" != "" {
			local nc `ucount'
			plugin call solver `ids' `gen' `matcher' `if' `in'		
		}
		else {
			exit
		}
	}

  if "`wt'" != "" {
    tempvar cases controls tot
    sort `touse' `gen' `treated'
    by `touse' `gen': egen `cases' = sum(`treated')
    by `touse' `gen': gen `controls' = _N - `cases'
    gen `tot' = `cases' * `controls'
    gen `wt' = `cases' / `tot' if `treated' == 0
    replace `wt' = `controls' / `tot' if `treated' == 1
  }
  
	noi di as text _n "Matched " _cont
	noi di as result "`tcount' " _cont
	noi di as text "treated subjects and " _cont
	noi di as result "`ucount' " _cont
	noi di as text "untreated subjects"
	
	noi di as text "Sum of distances within matched sets = " _cont
	noi di as result "`cost'"


end

program solver, plugin using("optmatch.plugin")
