*! version 1.1.1  13aug2013
program define getcmds, rclass
	version 8.2

	syntax using [,		///
		replace		/// -file- option
		append		/// -file- option
		ADOonly		/// output options
		NONADOonly	///
		ALLcmds		///
		HLPonly		///
	]

	local base : subinstr local using "." "_"
	if `"`base'"' == `"`using'"' {
		tokenize `using'
		local using `"using `"`2'.txt"'"'
	}

	local types `adoonly' `nonadoonly' `allcmds' `hlponly'
	if `:word count `types'' > 1 {
		di as err "options `:list retok types' may not be combined"
		exit 198
	}
	else if "`types'" == "" {
		local types allcmds
	}

	local pwd : pwd

	tempname ww
	file open `ww' `using', write text `replace' `append'

	preserve
	drop _all

capture noisily quietly {

	cd `"`c(sysdir_base)'"'
	GetFiles `ww' `types'
	if c(stata_version) < 13 {
		cd `"`c(sysdir_updates)'"'
		GetFiles `ww' `types'
	}
	cd `"`c(sysdir_plus)'"'
	GetFiles `ww' `types'

	if "`types'" != "hlponly" {
		ReadAlias `ww' `types'
	}

}

	local rc = c(rc)
	capture file close `ww'

	quietly cd `"`pwd'"'
	if (`rc') exit `rc'

	quietly infile str80 cmds `using', clear
	sort cmds
	by cmds: gen copy = _n
	quietly drop if copy > 1
	quietly outfile cmds `using', replace noquote
	tokenize `using'
	di as txt `"file `2' saved"'
end

// use the alias help file to find other built-in and ado-file programs that
// do not have hlp-files with the same name
program ReadAlias
	args ww types
	if c(stata_version) < 9 {
		local flist help_alias.maint
	}
	else {
		local llist _ a b c d e f g h i j k l m n o p q r s	///
			t u v w x y z
		foreach l of local llist {
			local flist `flist' `l'help_alias.maint
		}
	}
	foreach file of local flist {
		quietly findfile `file'
		quietly infile str80 cmd str80 hlp using `"`r(fn)'"', clear
		forval i = 1/`=c(N)' {
			local cmd `=cmd[`i']'
			capture unabcmd `cmd'
			if !c(rc) {
				if "`r(cmd)'" != "`cmd'" {
					local abcmd file write `ww' "`cmd'" _n
				}
				else	local abcmd
				local cmd `r(cmd)'
				capture findfile `cmd'.ado
				if c(rc) & "`types'" != "adoonly" {
					`abcmd'
					file write `ww' "`cmd'" _n
				}
				else if !c(rc) & "`types'" != "nonadoonly" {
					`abcmd'
					file write `ww' "`cmd'" _n
				}
			}
		}
	}
end

program GetFiles
	args ww types
	local dlist : dir "." dirs "*"
	foreach dir of local dlist {
		`types' `ww' `dir'
	}
end

program allcmds
	args ww dir
	TypeLoop `ww' `dir' ado
	TypeLoop `ww' `dir' hlp
	if c(stata_version) >= 10 {
		TypeLoop `ww' `dir' sthlp
	}
end

program adoonly
	args ww dir
	TypeLoop `ww' `dir' ado
end

program nonadoonly
	args ww dir
	TypeLoop `ww' `dir' hlp
	if c(stata_version) >= 10 {
		TypeLoop `ww' `dir' sthlp
	}
end

program hlponly
	args ww dir
	TypeLoop `ww' `dir' hlp ado
	if c(stata_version) >= 10 {
		TypeLoop `ww' `dir' sthlp ado
	}
end

program TypeLoop
	args ww dir type ado
	local list : dir "`dir'" files "*.`type'"
	foreach file of local list {
		// remove the ".hlp" extension
		local base : subinstr local file ".`type'" ""
		if "`type'" != "ado" {
			// not an ado-file
			capture findfile `base'.ado
			if c(rc) {
				// but is a command
				capture which `base'
				if c(rc) local base
			}
			else if "`ado'" == "" {
				local base
			}
		}
		if "`base'" != "" {
			file write `ww' "`base'" _n
		}
	}
end

exit
