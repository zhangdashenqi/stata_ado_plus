*! version 1.0.0  18apr2005
program labelrename, rclass
	version 8.1, born(09sep2003)

	#del ;
	syntax  namelist(min=2 max=2 id=labellist)
	[,
		Current  /// undocumented
		FORCE
	] ;
	#del cr

	local oldname : word 1 of `namelist'
	local newname : word 2 of `namelist'

	quiet label dir
	local lablist `r(names)'

	if !`:list oldname in lablist' {
		if "`force'" == "" {
			dis as err "value label `oldname' not found"
			exit 111
		}
		preserve
	}
	else {
		// oldname was defined

		if !`:list newname in lablist' {
		
			// create new value label newname identical to oldname

			preserve
			uselabel `oldname' , clear
			tempname fh
			tempfile f
			
			file open `fh' using `"`f'"', text write
			
			file write `fh' "label define `newname'  " ///
			     (value[1]) `" `"`=label[1]'"'"' _n
			forvalues i = 2 / `c(N)' {
				file write `fh' "label define `newname' " ///
				     (value[`i']) `" `"`=label[`i']'"' , add"' _n
			}
			
			file close `fh'

			restore, preserve
			run `"`f'"'
		}
		else {
		
			// newname already exists
			// verify that oldname/newname are identical value labels

			if `"`oldname'"' == `"`newname'"' {
				dis as txt "(nothing to do)"
				exit
			}

			preserve
			uselabel `oldname' `newname' , clear
			if mod(`c(N)',2) == 1 {
				Differ `oldname' `newname'
			}	
			local n = int(`c(N)'/2)

			sort lname value
			capt assert (value==value[_n+`n']) ///
			          & (label==label[_n+`n']) in 1/`n'
			if _rc {
			   Differ `oldname' `newname'
			}
			
			restore, preserve
		}
	}

// rename value label in all languages //////////////////////////////////////////////

	qui label language
	local cln `r(language)'
	local lns `r(languages)'

	dis _n "{txt}Value label {res:`oldname'} renamed to {res:`newname'}"
	if (`:list sizeof lns' == 1) | ("`current'" != "") {
	
		// in current language only
		
		Rename `oldname' `newname'
		local vlist `r(vlist)'
		if "`vlist'" != "" {
			dis "{p 0 8 2}{txt}value label {res:`oldname'} " ///
			    "was attached to variables {res}`vlist'{p_end}"
		}
		else {
			dis "{txt} Note: value label {res:`oldname'} " ///
			    "was not attached to any variable"
		}
		return local varlist `vlist'
	}
	else {
		// in all languages
		
		foreach	ln of local lns {
			quiet  label language `ln'

			Rename `oldname' `newname'
			local vlist `r(vlist)'
			if "`vlist'" != "" {
				dis "{p 0 21 2}{txt}" ///
				    "In language {res:`ln'} : {res:`oldname'} " ///
				    "attached to variables {res}`vlist'{p_end}"
			}
			else {
				dis "{txt}In language {res:`ln'} : " ///
				    "{res:`oldname'} not attached to any variable"
			}
			return local varlist_`ln' `vlist'
		}

		return local varlist `return(varlist_`cln')'
		label language `cln'
	}

	capture label drop `oldname'
	restore, not
end


program Differ
	args oldname newname

	dis as err "value labels `oldname' and `newname' are different"
	exit 198
end


program Rename, rclass
	args oldname newname

	foreach v of varlist _all {
		if "`:value label `v''" == "`oldname'" {
			label value `v' `newname'
			local vlist `vlist' `v'
		}
	}
	return local vlist `vlist'
end
exit
