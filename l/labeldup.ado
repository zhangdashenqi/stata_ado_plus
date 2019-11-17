*! version 1.0.0  18apr2005
program labeldup, rclass
	version 8.1, born(09sep2003)

	#del ;
	syntax  [ anything(id=labellist) ]
	[,
		Select
		Names(namelist)
		noDrop
		Display
	] ;
	#del cr

	quiet label dir
	local lablist `r(names)'
	if "`lablist'" == "" {
		dis as txt "(no value labels found)"
		exit
	}

	if "`names'" != "" {
		local diflist : list names - lablist
		if "`diflist'" != "" {
			dis as err "value labels `diflist' not found"
			exit 111
		}
	}

	preserve
	uselabel `anything' , clear

// mark mappings

	bys label value : gen long map = _n==1   // mark mappings  value -> label
	qui replace map = sum(map)               // unique code for mappings

// drop value label with unique map values -- these can't have duplicates

	bys map : gen N = _N
	qui bys lname (N) : drop if N[1]==1
	qui drop N
	if (`c(N)'==0) {
		dis as txt "(all value labels are unique)"
		exit
	}

// drop value labels with unique map-sums (hash codes) -- these can't have duplicates

	bys lname (value) : gen nmap = _N
	bys lname (value) : gen long summap = sum(_n*map)
	qui  bys lname (value) : replace summap = summap[_N]*(_n==_N)

	bys summap : gen byte todrop = _N==1
	qui  bys lname (todrop) : drop if todrop[_N]==1
	if (`c(N)'==0) {
		dis as txt "(all value labels are unique)"
		exit
	}
	drop todrop
	qui bys lname (value) : replace summap = summap[_N]

// assess uniquess of remaining value labels, restricting search to value labels
// with the same summap (hash code).
//
// generates: id_<j>  llist<j>, j=.1..n

	local n    = 0  // number of duplicate sets found
	local n0   = 0  // index of first dupset with same mapsum of set <n>
	local id_0 = 0  // junk, just set for first test
	local i1    = 1

	sort summap lname value
	while `i1' <= `c(N)' {
		if (`i1' == 1) | (summap[`i1'] != summap[`id_`n0'']) {
		
			// value label set found with new summap
			
			local n  = `n'+1
			local n0 = `n'
			local id_`n' = `i1'
			local llist`n' `=lname[`i1']'
		}
		else {
			// compare vlabel that starts at i1 with unique
			// value labels starting at uniq<n0>..uniq<n>
			
			local found 0
			local i2 = `i1' + nmap[`i1'] - 1
			local found 0
			forvalues j = `n0' / `n' {
				capt assert map == map[`id_`j''-`i1'+_n]  in `i1'/`i2'
				if !_rc {
					local llist`j' `llist`j'' `=lname[`i1']'
					local found 1
					continue , break
				}
			}
			
			if !`found' {
				// new value found with same summap
				// don't change n0
				local n = `n'+1
				local id_`n' = `i1'
				local llist`n' `=lname[`i1']'
			}
		}

		local i1 = `i1' + nmap[`i1']
	}

// non-unique value labels

	local m = 0
	forvalues j = 1 / `n' {
		if `:list sizeof llist`j'' > 1 {
			local ++m
			local llist`m' `llist`j''
		}
	}

	if `m' == 0 {
		dis as txt "(all value labels are unique)"
		exit
	}

// names of value names to be retained

	if "`names'" == ""{
		// adopt first of sets of non-unique value labels
		
		forvalues j = 1 / `m' {
			gettoken lselect`j' lrename`j' : llist`j'
		}
	}
	else {
		// search for non-unique value labels in names()
		
		forvalues j = 1 / `m' {
			local s : list names & llist`j'
			if "`s'" == "" {
				gettoken lselect`j' lrename`j' : llist`j'
			}
			else if `:list sizeof s' == 1 {
				local lselect`j' `s'
				local lrename`j' : list llist`j' - s
			}
			else {
				dis as err "names() invalid"
				dis as err "`s' are duplicate value labels"
				exit 198
			}
		}
	}

// display report

	if "`select'" != "" {
		restore, preserve
	}
	else if "`display'" != "" {
		restore
	}

	forvalues j = 1/`m' {
		return local select`j'  `lselect`j''
		return local dupset`j'  `lrename`j''
	}

	dis _n as txt "`m' sets of duplicate value labels found:" _n
	
	forvalues j = 1 / `m' {
		local sp = cond(`j'<10,"{space 1}","")
		dis "{p 0 11}{txt}Dupset `sp'`j': " ///
		   "{res:{ul:`lselect`j''} `lrename`j''}{p_end}"

		if "`display'" != "" {
			label list `lselect`j''
			dis
		}
	}
	
	if "`select'" == "" {
		dis _n as txt ///
			"Specify option {cmd:select} to compress value labels using underlined labels"
		dis    as txt ///
			"Specify option {cmd:names()} to select other value names to be retained"
		exit
	}

// compress/reduce the value labels

	qui label language
	local lns `r(languages)'
	local cln `r(language)'
	local otherlns : list lns - cln

	foreach v of varlist _all {
	
		// current language
		local vl : value label `v'
		if "`vl'" != "" {
			forvalues j = 1 / `m' {
				if `:list vl in lrename`j'' {
					label value `v' `lselect`j''
					continue, break
				}
			}
		}

		// other languages
		foreach ln of local otherlns {
			local vlln : char `v'[_lang_l_`ln']
			if "`vlln'" != "" {
				forvalues j = 1 / `m' {
					if `:list vlln in lrename`j'' {
						char `v'[_lang_l_`ln'] `lselect`j''
						continue, break
					}
				}
			}
		}
	}

	if "`drop'" == "" {
		forvalues j = 1 / `m' {
			label drop `lrename`j''
		}
	}

	restore, not
end
exit
