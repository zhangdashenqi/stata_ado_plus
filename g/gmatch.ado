program gmatch, rclass byable(onecall)
*! $Revision: 1.6 $
*! Author:  Mark Lunt
*! Date:    June 25, 2012 @ 10:49:35


	// TODO: Convert to a plugin for the matching for efficiency
	//       Put distances into a priority heap
  //       Both of those now done in gmatchp.ado

version 9

syntax varlist [if] [in] [,Set(namelist min=1 max=1)  ///
                           Diff(namelist min=1 max=1) ///
			                     Caliper(numlist max=1)     ///
			                     maxc(integer 1)            ///
                           LP prematch(varname) ]       

tokenize `varlist'
local group `1'
macro shift
local prop  `1'

if "`caliper'" == "" {
  local caliper .
}

if "`set'" == "" {
  local set set
}

qui isvar `set'
if "`set'" == "`r(varlist)'" {
  noi di as error "The variable `set' already exists: unable to proceed."
  exit 100
}

if "`diff'" == "" {
  local diff diff
}

qui isvar `diff'
if "`diff'" == "`r(varlist)'" {
  noi di as error "The variable `diff' already exists: unable to proceed."
  exit 100
}

	local sortvars : sortedby
  noi di "`sortvars'"

  if "`lp'" == "lp" {
  tempvar nprop
  gen `nprop' = log(`prop'/(1-`prop'))
  local prop `nprop'
}

	// Expand treated if they can be reused
	// Usual  context has few treated, lots of potential matches, may
	// want to use more than one match per treated subject
	
	tempvar orig_order
	gen `orig_order' = _n
	
	marksample touse
	local byprefix
	if "`_byvars'" ~= "" {
		local byprefix by `_byvars':
	}

	quietly {
		tempvar matched du dd d mind minmind matches mc mcc
		gen `matched' = 0 if `touse'
		gen `du' = .
		gen `dd' = .
		gen `set' = .
		gen `diff' = .
    gen `matches' = 0
    if ("`prematch'" != "") {
      summ `prematch'
      local pm = `r(max)'
      replace `orig_order' = `orig_order' + `pm'
      replace `orig_order' = `prematch' if `group' == 1
      sort `prematch' `group'
      by `prematch': replace `matches' = _N - 1 if `prematch' < . &  ///
          `group' == 1
      replace `matched' = 1 if `prematch' < .
      replace `set' = `prematch'
      by `prematch': replace `diff' = abs(`prop' - `prop'[_N]) if  ///
          `group' == 0 & `prematch' < .
    }

    if `maxc' > 1 {
      tempvar expand
      gen `expand' = 1
      replace `expand' = `maxc' if `group' == 1 & `touse'
      expand `expand'
      if ("`prematch'" != "") {
        sort `prematch' `group'
        by `prematch' `group': replace `matched' = 0 if     ///
            `group' == 1 & _n > `matches'
      }
    }

    drop `matches'
		local last_match 1
		local last_count 0  
    local iter = 1

		while `last_match' == 1 {
			gsort `_byvars' -`touse' -`matched' `prop'
			`byprefix' replace `du' = abs(`prop' - `prop'[_n-1]) if `touse' & `touse'[_n-1] ///
					& `group' == 1 &  `group'[_n-1] == 0       ///
					& `matched' == 0 &  `matched'[_n-1] == 0  
			`byprefix' replace `dd' = abs(`prop' - `prop'[_n+1]) if `touse' & `touse'[_n+1] ///
					& `group' == 1 &  `group'[_n+1] == 0       ///
					& `matched' == 0 &  `matched'[_n+1] == 0  
			egen `d' = rowmin(`du' `dd')
			`byprefix' egen `mind' = min(`d')
      replace `mind' = . if `mind' > `caliper'
      egen `minmind' = min(`mind')
      
			if `minmind'[1] == . | `minmind'[1] > `caliper' {
				local last_match = 0
			}
			else {
        // match with case below control
				`byprefix' replace `matched' = 2 if `matched' == 0 &  ///
            `du' == `mind' & `matched'[_n-1] == 0 & `touse' &  ///
            `du' != . & `group' == 1 & `group'[_n-1] == 0
				`byprefix' replace `matched' = 3 if `matched' == 0 &  ///
            `matched'[_n+1] == 2
        // match with case above control
				`byprefix' replace `matched' = 4 if `matched' == 0 &  ///
            `dd' == `mind' & `matched'[_n+1] == 0 & `touse' &  ///
            `dd' != .
				`byprefix' replace `matched' = 5 if `matched' == 0 &  ///
            `matched'[_n-1] == 4

				`byprefix' replace `d' = `d'[_n+1] if `matched' == 3
				`byprefix' replace `d' = `d'[_n-1] if `matched' == 5 
        replace `set' = `orig_order' if `matched' == 2 | `matched' == 4
        replace `set' = `orig_order'[_n+1] if `matched' == 3
        replace `set' = `orig_order'[_n-1] if `matched' == 5
        replace `matched' = 1 if `matched' == 2 | `matched' == 3 | `matched' == 4 | `matched' == 5
				`byprefix' replace `diff' = `d' if `diff' == . &    ///
            `matched' == 1 & `group' == 0
				replace `d' = .
				replace `du' = .
				replace `dd' = .
        //        tab `set' `matched' if `group' == 0
        bys `_byvars' `set': gen `mc' = _n == 1 if `set' < .
        egen `mcc' = sum(`matched') if `group' == 0
        preserve
        sort `group'
				local count = `mcc'[1]
        restore
        drop `mc' `mcc'
				while `last_count' < `count' {
					//      noi di as error "`count' `last_count'" 
					if (round(`last_count'/50,1) == `last_count'/50) {
						noi di as text _n %5.0f `last_count' ": " _cont
					}
					noi di as result "." _cont
					local last_count = `last_count' + 1
				}
			}
			drop `d' `mind' `minmind'
      local iter = `iter' + 1
		}
    di 
		// Reduce back to a single record per case, if necessary
		// Collapse all sets matched to that case to have a single id
		if `maxc' > 1 | "`_byvars'" != "" {
      quietly {
        tempvar newset
        egen `newset' = group(`set') if `set' ~= .
        replace `set' = `newset'
        sort `orig_order' `newset'
        by `orig_order': keep if _n == 1
      }
    }
		noi di _n _n "Found `count' matches" _n 
	}
  
	sort `sortvars' `orig_order'

end
