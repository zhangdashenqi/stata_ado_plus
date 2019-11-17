
**** Examples for help files ado

*! version 1.1.0  25oct2012
program xsmle_examples
	version 10
	set more off
	`0'
end

program NotSmall
	if "`c(flavor)'"=="Small" {
		window stopbox stop ///
		"Dataset used in this example" ///
		"too large for Small Stata"
	}
end
	
program Msg
	di as txt
	di as txt "-> " as res `"`0'"'
end

program Xeq
	di as txt
	di as txt `"-> "' as res `"`0'"'
	`0'
end


program define find_path
	args returmac 
		
	tempfile find_path
	qui log using `find_path'.txt, text replace
	net query
	qui log close
	qui {
	insheet using `find_path'.txt, clear
	ren v1 ___path
	mata: ___path = _get_data("___path")
	mata: sel = regexm(___path, "other")
	mata: st_local("pippo",select(___path,sel))
	local path = trim(regexr("`pippo'", "other", ""))
	mata: mata drop ___path
	mata: mata drop sel
	}
    c_local `returmac' `path' 		
end

mata

string matrix _get_data(string scalar name)
{	
	st_sview(sol, ., tokens(name))
	sol
	return(sol)		
}


end



program sar
	Msg preserve
	preserve
	
	find_path path
	if "`path'" == "(current directory)" local path "`c(pwd)'`c(dirsep)'"
	use "`path'product", clear
	capt findfile spmat.ado
    if _rc {
        di as error "-spmat- is required; type {stata ssc install sppack}"
        error 499
    }
	local vv = c(stata_version)
	if `vv' < 11 {
        di as error "This example cannot be run with Stata `vv' since it requires the use of -spmat- objects."
        error 499
    }
	qui {  
	spmat use usaww using "`path'usaww.spmat"
	gen lngsp = log(gsp)
	gen lnpcap = log(pcap)
	gen lnpc = log(pc)
	gen lnemp = log(emp)
	}

	Xeq xsmle lngsp lnpcap lnpc lnemp unemp, wmat(usaww)
	qui spmat drop usaww
	Msg restore
	restore
end


program sdm
	Msg preserve
	preserve
	find_path path
	if "`path'" == "(current directory)" local path "`c(pwd)'`c(dirsep)'"
	use "`path'product", clear
	capt findfile spmat.ado
    if _rc {
        di as error "-spmat- is required; type {stata ssc install sppack}"
        error 499
    }
	local vv = c(stata_version)
	if `vv' < 11 {
        di as error "This example cannot be run with Stata `vv' since it requires the use of -spmat- objects."
        error 499
    }
	qui {  
	spmat use usaww using "`path'usaww.spmat"
	gen lngsp = log(gsp)
	gen lnpcap = log(pcap)
	gen lnpc = log(pc)
	gen lnemp = log(emp)
	}

	Xeq xsmle lngsp lnpcap lnpc lnemp, re model(sdm) wmat(usaww) durbin(lnpcap lnpc)
	qui spmat drop usaww
	Msg restore
	restore
end


program sac
	Msg preserve
	preserve
	find_path path
	if "`path'" == "(current directory)" local path "`c(pwd)'`c(dirsep)'"
	use "`path'product", clear
	capt findfile spmat.ado
    if _rc {
        di as error "-spmat- is required; type {stata ssc install sppack}"
        error 499
    }
	local vv = c(stata_version)
	if `vv' < 11 {
        di as error "This example cannot be run with Stata `vv' since it requires the use of -spmat- objects."
        error 499
    }
	qui {  
	spmat use usaww using "`path'usaww.spmat"
	gen lngsp = log(gsp)
	gen lnpcap = log(pcap)
	gen lnpc = log(pc)
	gen lnemp = log(emp)
	}

	Xeq xsmle lngsp lnpcap lnpc lnemp, fe model(sac) wmat(usaww) emat(usaww)
	qui spmat drop usaww
	Msg restore
	restore
end


program sem
	Msg preserve
	preserve
	find_path path
	if "`path'" == "(current directory)" local path "`c(pwd)'`c(dirsep)'"
	use "`path'product", clear
	capt findfile spmat.ado
    if _rc {
        di as error "-spmat- is required; type {stata ssc install sppack}"
        error 499
    }
	local vv = c(stata_version)
	if `vv' < 11 {
        di as error "This example cannot be run with Stata `vv' since it requires the use of -spmat- objects."
        error 499
    }
	qui {  
	spmat use usaww using "`path'usaww.spmat"
	gen lngsp = log(gsp)
	gen lnpcap = log(pcap)
	gen lnpc = log(pc)
	gen lnemp = log(emp)
	}

	Xeq xsmle lngsp lnpcap lnpc lnemp, re model(sem) emat(usaww)
	qui spmat drop usaww
	Msg restore
	restore
end


program gspre
	Msg preserve
	preserve
	find_path path
	if "`path'" == "(current directory)" local path "`c(pwd)'`c(dirsep)'"
	use "`path'product", clear
	capt findfile spmat.ado
    if _rc {
        di as error "-spmat- is required; type {stata ssc install sppack}"
        error 499
    }
	local vv = c(stata_version)
	if `vv' < 11 {
        di as error "This example cannot be run with Stata `vv' since it requires the use of -spmat- objects."
        error 499
    }
	qui {  
	spmat use usaww using "`path'usaww.spmat"
	gen lngsp = log(gsp)
	gen lnpcap = log(pcap)
	gen lnpc = log(pc)
	gen lnemp = log(emp)
	}

	Xeq xsmle lngsp lnpcap lnpc lnemp, model(gspre) error(1) wmat(usaww) emat(usaww) 
	qui spmat drop usaww
	Msg restore
	restore
end



program rform
	Msg preserve
	preserve
	
	find_path path
	if "`path'" == "(current directory)" local path "`c(pwd)'`c(dirsep)'"
	use "`path'product", clear
	capt findfile spmat.ado
    if _rc {
        di as error "-spmat- is required; type {stata ssc install sppack}"
        error 499
    }
	local vv = c(stata_version)
	if `vv' < 11 {
        di as error "This example cannot be run with Stata `vv' since it requires the use of -spmat- objects."
        error 499
    }
	qui {  
	spmat use usaww using "`path'usaww.spmat"
	gen lngsp = log(gsp)
	gen lnpcap = log(pcap)
	gen lnpc = log(pc)
	gen lnemp = log(emp)
	}

	Xeq xsmle lngsp lnpcap lnpc lnemp unemp, wmat(usaww)
	Xeq predict y_hat
	Xeq sum lngsp y_hat
	qui spmat drop usaww
	Msg restore
	restore
end


program limited
	Msg preserve
	preserve
	find_path path
	if "`path'" == "(current directory)" local path "`c(pwd)'`c(dirsep)'"
	use "`path'product", clear
	capt findfile spmat.ado
    if _rc {
        di as error "-spmat- is required; type {stata ssc install sppack}"
        error 499
    }
	local vv = c(stata_version)
	if `vv' < 11 {
        di as error "This example cannot be run with Stata `vv' since it requires the use of -spmat- objects."
        error 499
    }
	qui {  
	spmat use usaww using "`path'usaww.spmat"
	gen lngsp = log(gsp)
	gen lnpcap = log(pcap)
	gen lnpc = log(pc)
	gen lnemp = log(emp)
	}

	Xeq xsmle lngsp lnpcap lnpc lnemp, fe model(sac) wmat(usaww) emat(usaww) type(ind, leeyu)
	Xeq predict y_hat, limited
	Xeq sum lngsp y_hat
	qui spmat drop usaww
	Msg restore
	restore
end



