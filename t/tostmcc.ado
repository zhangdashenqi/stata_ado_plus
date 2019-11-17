*! version 1.6.0 02mar2014 by alexis dot dinno at pdx dot edu
*! perform two one-sided tests for stochastic equivalence in paired data

* Syntax:  tostmcc varname [if exp] [in range] [fweight exp], [ 
*          eqvtype(type) eqvlevel(#) uppereqvlevel(#) yates edwards level(#) ]

program define tostmcc

  if int(_caller())<8 {
    di in r "tostmcc- does not support this version of Stata." _newlineewline
    di as txt "Requests for a version compatible with versions of STATA earlier than v8 are "
    di as txt "untenable since I do not have access to the software." _newlineewline 
    exit
  }
   else tostmcc8 `0'
end

program define tostmcc8, rclass
  version 8, missing
  syntax varlist(min=2 max=2) [if] [in] [fw] [, EQVType(string) /*
*/       EQVLevel(real 1) UPPEReqvlevel(real 0) yates edwards Level(cilevel) ]

* Validate eqvtype
  if lower("`eqvtype'") == "" {
    local eqvtype = "delta"
    }

  if !(lower("`eqvtype'") == "delta" | lower("`eqvtype'") == "epsilon") {
    noisily: di as err "option eqvtype() must be one of: delta, or epsilon"
    exit 198
    }

* Validate eqvlevel
  if (lower("`eqvtype'") == "delta") & (`eqvlevel' == 1 & `uppereqvlevel'==0) {
    local eqvlevel = 0.1
    }

  if (lower("`eqvtype'") == "epsilon") & (`eqvlevel' == 1 & `uppereqvlevel'==0) {
    local eqvlevel = 2
    }

  if (lower("`eqvtype'") == "delta" || lower("`eqvtype'") == "epsilon") & (`eqvlevel' <= 0 & `uppereqvlevel' != abs(`eqvlevel')) {
    noisily: di as err "option eqvlevel() incorrectly specified" _newline "the tolerance must be a positive real value"
    exit 198
    }

  if lower("`eqvtype'") == "delta" & (`eqvlevel' >= 1 | `uppereqvlevel' >= 1) {
    noisily: di as err "option eqvlevel() incorrectly specified" _newline "you are likely to find all proportions equivalent within an interval of plus or minus 1 or more"
    exit 198
    }

* Validate uppereqvlevel
  if (`uppereqvlevel'<0) {
    noisily: di as err "option uppereqvlevel() must be a positive real value"
    exit 198
    }
 
  if (`uppereqvlevel'==0 | `uppereqvlevel' == abs(`eqvlevel')) {
    local upper = abs(`eqvlevel')
    local lower = abs(`eqvlevel')
    }

  if (`uppereqvlevel'>0) {
    local upper = abs(`uppereqvlevel')
    local lower = abs(`eqvlevel')
    }

* Validate continuity correction option
  if ("`yates'" != "" & "`edwards'" != "") {
    noisily di as err "continuity correction options must be either yates or edwards, but not both"
    exit 198
    }

  tokenize `varlist'
  local excas `1'
  local excon `2'

  marksample use
  tempvar WGT one
  quietly { 
    if "`weight'"!="" { 
      gen double `WGT' `exp' if `use'
      local w "[fweight=`WGT']"
    }
  }

  quietly { 
    gen byte `one'=1
    safesum `one' `w' if `excas' & `excon' & `use'
    local a=r(sum)
    safesum `one' `w' if `excas' & `excon'==0 & `use'
    local b=r(sum)
    safesum `one' `w' if `excas'==0 & `excon' & `use'
    local c=r(sum)
    safesum `one' `w' if `excas'==0 & `excon'==0 & `use'
    local d=r(sum)
  }
  tostmcci `a' `b' `c' `d', eqvtype(`eqvtype') eqvlevel(`eqvlevel') uppereqvlevel(`upper') `yates' `edwards' level(`level')
  ret add   /* return the r() values from tostmcci call */
end
