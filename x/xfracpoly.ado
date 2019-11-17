*! version 1.0.2 PR 11feb2016
program define xfracpoly, eclass
	local VV : di "version " string(_caller()) ":"
	version 11.0
	local cmdline : copy local 0
	mata: _parse_colon("hascolon", "rhscmd")	// _parse_colon() is stored in _parse_colon.mo
	if (`hascolon') {
		`VV' newfracpoly `"`0'"' `"`rhscmd'"'
	}
	else {
		`VV' xfracpoly_10 `0'
	}
	// ereturn cmdline overwrites e(cmdline) from fracpoly_10
	ereturn local cmdline `"fracpoly `cmdline'"'
end

program define newfracpoly
	local VV : di "version " string(_caller()) ":"
	version 11.0
	args 0 statacmd

	// Extract fracpoly options
	syntax, [*]
	local fracpolyopts `options'

/*
	It is important that the fracpoly options precede the Stata command options.
	To ensure this, must extract the Stata options and reconstruct the command
	before presenting it to fracpoly_10.
*/
	local 0 `statacmd'
	syntax [anything] [if] [in] [aw fw pw iw], [*]
	if `"`weight'"' != "" local wgt [`weight'`exp']

	`VV' xfracpoly_10 `anything' `if' `in' `wgt', `fracpolyopts' `options'
end
