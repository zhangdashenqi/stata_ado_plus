*! version 1.0.3 PR 11feb2016
program define mfpa, eclass 
	local VV : di "version " string(_caller()) ", missing:"
	version 11.0
	local cmdline : copy local 0
	mata: _parse_colon("hascolon", "rhscmd")	// _parse_colon() is stored in _parse_colon.mo
	if (`hascolon') {
	        `VV' newmfp `"`0'"' `"`rhscmd'"'
	}
	else {
	        `VV' xmfp_10 `0'
	}
	// ereturn cmdline overwrites e(cmdline) from xmfp_10
	ereturn local cmdline `"mfp `cmdline'"'
end

program define newmfp
	local VV : di "version " string(_caller()) ", missing:"
	version 11.0
	args 0 statacmd

	// Extract mfp options
	syntax, [*]
	local mfpopts `options'

/*
	It is important that the mfpoptions precede the Stata command options.
	To ensure this, must extract the Stata options and reconstruct the command
	before presenting it to xmfp_10.
*/
	local 0 `statacmd'
	syntax [anything] [if] [in] [aw fw pw iw], [*]
	if `"`weight'"' != "" local wgt [`weight'`exp']
	local options `options' hascolon
	`VV' xmfp_10 `anything' `if' `in' `wgt', mfpopts(`mfpopts') `options'
end
