*! version 2.0.1 PR 30nov2009
program define mfpboot, eclass
	version 10
	local cmdline : copy local 0
	mata: _parse_colon("hascolon", "rhscmd")	// _parse_colon() is stored in _parse_colon.mo
	if (`hascolon') {
	        newmfpboot `"`0'"' `"`rhscmd'"'
	}
	else {
	        mfpboot_10 `0'
	}
	ereturn local cmdline `"mfp `cmdline'"'
end

program define newmfpboot
	version 9.2
	args 0 statacmd

	// Extract mfp and mfpboot options
	syntax, [*]
	local mfpopts `options'
/*
	It is important that the mfp/mfpboot options precede the Stata command options.
	To ensure this, must extract the Stata options and reconstruct the command
	before presenting it to mfpboot_10.
*/
	local 0 `statacmd'
	syntax [anything] [if] [in] [aw fw pw iw], [*]
	if `"`weight'"' != "" local wgt [`weight'`exp']

	mfpboot_10 `anything' `if' `in' `wgt', `mfpopts' `options'
end
