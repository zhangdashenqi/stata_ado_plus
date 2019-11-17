*! version 1.0.0  02/02/93  STB-13: dm13.1
program define minlen /* # varlist */
	version 3.0
	local d=/*
	*/ cond(substr("`1'",1,3)=="str",real(substr("`1'",4,.)),real("`1'"))
	mac shift 
	local varlist "req ex"
	parse "`*'"
	parse "`varlist'", parse(" ")

	quietly {
		while ("`1'"!="") {
			confirm string var `1'
			local type : type `1'
			local oldd=real(substr("`type'",4,.))
			if `oldd'<`d' {
				recast str`d' `1'
			}
			mac shift
		}
	}
end
