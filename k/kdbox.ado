*! version 1.1 (14nov02) pbe
program define kdbox
  version 7.0
  syntax varlist(max=1) [if] [in] [fweight] [, Mean by(string) * ]
  if `"`by'"' != "" {
    window manage forward results
    display as err "by option not allowed"
    exit 198
  }
  tokenize `varlist'
  gph open
  capture kdensityxx `1' `if' `in' [`weight' `exp'], bbox(600,0,23063,32000,850,390,0) `options'
  if _rc>0 {
    window manage forward results
    display as help "r(198)"
    exit
  } 
  local ay = r(ay)
  local by = r(by)
  local ax = r(ax)
  local bx = r(bx)
  local r1 = 50
  local r2 = 600
  local rc = (`r2'-`r1')/2+`r1'
  quietly summarize `1' `if' `in' [`weight' `exp'], detail
  local q1 = r(p25)
  local q2 = r(p50)
  local q3 = r(p75)
  local qm = r(mean)
  local ql = r(min) 
  local qu = r(max) 
  local cl = `ax'*`ql'+`bx'
  local c1 = `ax'*`q1'+`bx'
  local c2 = `ax'*`q2'+`bx'
  local c3 = `ax'*`q3'+`bx'
  local cu = `ax'*`qu'+`bx'
  local cm = `ax'*`qm'+`bx'
  gph pen 2
  gph line  `r1' `c1' `r1' `c3' 
  gph line  `r2' `c1' `r2' `c3'
  gph line  `r1' `cl' `r2' `cl'
  gph line  `r1' `c1' `r2' `c1'
  gph line  `r1' `c2' `r2' `c2'
  gph line  `r1' `c3' `r2' `c3'
  gph line  `r1' `cu' `r2' `cu'
  gph line  `rc' `cl' `rc' `c1'
  gph line  `rc' `c3' `rc' `cu'
  if "`mean'"~="" {
    gph pen 3
    gph point  `rc' `cm' 0 6
  } 
  gph close 
  window manage forward graph
end

/* modified from stata ado */
program define kdensityxx
	version 6.0

	syntax varname [if] [in] [fw aw] [, /*
		*/ Generate(string) N(integer 50) /*
		*/ Width(real 0.0) noGRaph noDENsity /*
		*/ BIweight COSine EPan GAUss RECtangle PARzen /*
		*/ TRIangle Symbol(string) Connect(string) /*
		*/ Title(string) AT(varname) NORmal STUd(int 0) * ]

	if "`at'"!="" & `n'!=50 {
		di in red "may not specify both the at() and n() options"
		exit 198
	}

	local ix `"`varlist'"'
	local ixl: variable label `ix'
	if `"`ixl'"'=="" { 
		local ixl "`ix'"
	}

	local gen `"`generat'"'

	local kflag = ( (`"`epan'"' != `""') + (`"`biweigh'"' != `""') + /*
			*/ (`"`triangl'"' != `""') + (`"`gauss'"' != `""') + /*
			*/ (`"`rectang'"' != `""')  + (`"`parzen'"' != `""'))
	if `kflag' > 1 {
		di in red `"only one kernel may be specified"'
		exit 198
	}

	if `"`biweigh'"'       != `""' { local kernel=`"Biweight"'     }
	else if `"`cosine'"'   != `""' { local kernel=`"Cosine"'       }
	else if `"`triangl'"'  != `""' { local kernel=`"Triangle"'     }
	else if `"`gauss'"'    != `""' { local kernel=`"Gaussian"'     }
	else if `"`rectang'"'  != `""' { local kernel=`"Rectangular"'  }
	else if `"`parzen'"'   != `""' { local kernel=`"Parzen"'       }
	else                       { local kernel=`"Epanechnikov"' }

	marksample use
	qui count if `use'
	if r(N)==0 { error 2000 } 

	tokenize `gen'
	local wc : word count `gen'
	if `wc' { 
		if `wc' == 1 {
			if `"`at'"' == `""' {
				error 198
			}
			confirm new var `1'
			local yl  `"`1'"'
			local xl `"`at'"'
			local nsave 1
		}
		else {
			if `wc' != 2 { error 198 }
			confirm new var `1'
			confirm new var `2'
			local xl  `"`1'"'
			local yl  `"`2'"'
			local nsave 2		
		}
	}
	else {
		local xl   `"X"'
		local yl   `"Density"'	
		local nsave 0		
	}
		
	tempvar d m z y
	qui gen double `d'=.
	qui gen double `y'=.
	qui gen double `z'=.
	qui gen double `m'=.

	if `"`at'"' != `""' {
		qui count if `at' != . 
		local n = r(N)
		qui replace `m' = `at' 
		local srtlst : sortedby
		tempvar obssrt
		gen `obssrt' = _n
		sort `m' `obssrt'
	}
	else {

		if `"`n'"'!= `""' {
			if `n' <= 1 { local n = 50 }
			if `n' > _N { 
				local n = _N
				noi di in gr `"(n() set to "' `n' `")"'
			}
		}
	}

	if "`weight'" != "" {
		tempvar tt
		qui gen double `tt' `exp' if `use'
		qui summ `tt', meanonly
		if "`weight'" == "aweight" {
			qui replace `tt' = `tt'/r(mean)
		}
	}
	else {
		local tt = 1
	}

	quietly summ `ix' [`weight'`exp'] if `use', detail
	local nmean = r(mean)
	local nsig = r(Var)

	tempname wwidth
	scalar `wwidth' = `width'
	if `wwidth' <= 0.0 { 
		scalar `wwidth' = min( sqrt(r(Var)), (r(p75)-r(p25))/1.349)
		scalar `wwidth' = 0.9*`wwidth'/(r(N)^.20)
	}

	tempname delta wid
	scalar `delta' = (r(max)-r(min)+2*`wwidth')/(`n'-1)
	scalar `wid'   = r(N) * `wwidth'

	if `"`at'"' == `""' {
		qui replace `m' = r(min)-`wwidth'+(_n-1)*`delta' in 1/`n'
	}

	tempname tmp1 tmp2 tmp3

	local i 1
	if `"`biweigh'"' != `""' {
		local con1 = .9375
		while `i'<=`n' {
			qui replace `z'=(`ix'-`m'[`i'])/(`wwidth') /*
				*/ if `use'
			qui replace `y'=`tt'*`con1'*(1-(`z')^2)^2 /*
				*/ if abs(round(`z',1e-8))<1
			qui summ `y', meanonly
			qui replace `d'=(r(sum))/`wid' in `i'
			qui replace `y'=.
			local i = `i'+1
		}
		qui replace `d'=0 if `d'==. in 1/`n'
	}
	else if `"`cosine'"' != `""' {
		while `i'<=`n' {
			qui replace `z'=(`ix'-`m'[`i'])/(`wwidth') /*
				*/ if `use'
			qui replace `y'= `tt'*(1+cos(2*_pi*`z')) /*
				*/ if abs(round(`z',1e-8))<0.5
			qui summ `y', meanonly
			qui replace `d'=(r(sum))/`wid' in `i'
			qui replace `y'=.
			local i = `i'+1
		}
		qui replace `d'=0 if `d'==. in 1/`n'
	}
	else if `"`triangl'"' != `""' {
		while `i'<=`n' {
			qui replace `z'=(`ix'-`m'[`i'])/(`wwidth') if `use'
			qui replace `y'= `tt'*(1-abs(`z')) /*
				*/ if abs(round(`z',1e-8))<1
			qui summ `y', meanonly
			qui replace `d'=(r(sum))/`wid' in `i'
			qui replace `y'=.
			local i = `i'+1
		}
		qui replace `d'=0 if `d'==. in 1/`n'
	}
	else if `"`parzen'"' != `""' {
		local con1 = 4/3
		local con2 = 2*`con1'
		while `i'<=`n' {
			qui replace `z'=(`ix'-`m'[`i'])/(`wwidth') if `use'
			qui replace `y'= `tt'*(`con1'-8*(`z')^2+8*abs(`z')^3) /*
				*/ if abs(round(`z',1e-8))<=.5
			qui replace `y'= `tt'*`con2'*(1-abs(`z'))^3       /*
				*/ if abs(round(`z',1e-8))>.5 & /*
				*/ abs(round(`z',1e-8))<1
			
			qui summ `y', meanonly
			qui replace `d'=(r(sum))/`wid' in `i'
			qui replace `y'=.
			local i = `i'+1
		}
		qui replace `d'=0 if `d'==. in 1/`n'
	}
	else if `"`gauss'"' != `""' {
		local con1 = sqrt(2*_pi)
		while `i'<=`n' {
			qui replace `z'=(`ix'-`m'[`i'])/(`wwidth') if `use'
			qui replace `y'= `tt'*exp(-0.5*((`z')^2))/`con1'
			qui summ `y', meanonly
			qui replace `d'=(r(sum))/`wid' in `i'
			local i = `i'+1
		}
		qui replace `d'=0 if `d'==. in 1/`n'
	}
	else if `"`rectang'"' != `""' {
		while `i'<=`n' {
			qui replace `z'=(`ix'-`m'[`i'])/(`wwidth') if `use'
			qui replace `y'= `tt'*0.5 if abs(round(`z',1e-8))<1
			qui summ `y', meanonly
			qui replace `d'=(r(sum))/`wid' in `i'
			qui replace `y'=.
			local i = `i'+1
		}
		qui replace `d'=0 if `d'==. in 1/`n'
	}
	else {
		local con1 = 3/(4*sqrt(5))
		local con2 = sqrt(5)
		while `i'<=`n' {
			qui replace `z'=(`ix'-`m'[`i'])/(`wwidth') if `use'
			qui replace `y'= `tt'*`con1'*(1-((`z')^2/5)) /* 
				*/  if abs(round(`z',1e-8))<=`con2'
			qui summ `y', meanonly
			qui replace `d'=(r(sum))/`wid' in `i'
			qui replace `y'=.
			local i = `i'+1
		}
		qui replace `d'=0 if `d'==. in 1/`n'
	}

	label var `d' `"`yl'"'
	label var `m' `"`ixl'"'

	qui summ `d' in 1/`n', meanonly
	local scale = 1/(`n'*r(mean))

	if `"`density'"' != `""' {
		qui replace `d' = `d'*`scale' in 1/`n'
	}

	if `"`graph'"'==`""' {
		if `"`symbol'"'  == `""' {local symbol `"o"'}
		if `"`connect'"' == `""' {local connect `"l"' }
		if `"`title'"'   == `""' {
			local title `"Kernel Density Estimate"'
		}
		if `"`normal'"' != `""' {
			tempvar znorm 
			scalar `tmp1' = 1/sqrt(2*_pi*`nsig')
			scalar `tmp2' = -0.5/`nsig'
			qui gen `znorm' = `tmp1'*exp(`tmp2'*(`m'-`nmean')^2)
			local symbol `"`symbol'i"'
			local connect `"`connect'l"'
			if `"`density'"' != `""' {
				tempvar fz
				qui gen `fz' = sum(`znorm')
				qui replace `znorm' = `znorm'/`fz'[_N]
			}
		}
		if `stud' > 0 {
			tempvar tm
			scalar `tmp1' = exp(lngamma((`stud'+1)/2)) /*
                                */ / exp(lngamma(`stud'/2)) /*
                                */ * 1/sqrt(`stud'*_pi)
			scalar `tmp2' = (`stud'+1)/2
			scalar `tmp3' = sqrt(`nsig')
			qui gen `tm' = `tmp1' * 1/((1+((`m'-`nmean') /*
				*/ / `tmp3' )^2/`stud')^`tmp2')
			local symbol `"`symbol'i"'
			local connect `"`connect'l"'
			tempvar ft
			qui gen `ft' = sum(`tm')
			if `"`density'"' != `""' {
				qui replace `tm' = `tm'/`ft'[_N]
			}
			else {
				qui replace `tm' = `tm'/`ft'[_N]/`scale'
			}
		}
		graph `d' `znorm' `tm' `m', s(`symbol') c(`connect') /*
		*/ title(`"`title'"') key2("") `options'
	}
	/* double save in S_# and r() */
	global S_1   `"`kernel'"'
	global S_3 = `wwidth'
	global S_2 = `n'
	global S_4 = `scale'

	if `nsave' == 1 {
		label var `d' `"density: `ixl'"'
		rename `d' `yl'
	}
	else if `nsave' == 2 {
		label var `m' `"`ixl'"'
		label var `d' `"density: `ixl'"'
		rename `d' `yl'
		rename `m' `xl'
	}
	if "`at'" != "" { 
		sort `srtlist' `obssrt'
	}
end	
 
