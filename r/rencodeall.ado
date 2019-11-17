* rencodeall
* Program to encode multiple variables and replace originals.
* Like encode, but replaces instead of using generate(name), and operates on multiple variables.
* Ignores non-string variables.
* The generated variables are compressed to a more efficient datatype if possible.
* Kenneth L. Simons, September 2006.
program define rencodeall
	version 9.0
	syntax [varlist] [if] [in], [Label(name) NOExtend NOEXTENDAll]
	* Parse options.
	if "`label'"=="" {
		local labelOption
	}
	else {
		local labelOption label(`label')
	}
	if "`noextendall'"=="noextendall" {
		local noextend = "noextend"
	}
	local noextendToUse `noextend'
	* Run the rencode command on each variable in the varlist.
	preserve
	local nEncoded = 0
	foreach v of local varlist {
		local typ : type `v'
		if substr("`typ'",1,3)=="str" {
			if "`label'"=="" & "`noextend'"=="noextend" {
				local vLabMaxlen : label `v' maxlength
				if `vLabMaxlen'==0 {
					* No label exists with the same name as the variable.  Do not require noextend.
					if "`noextendall'" == "noextendall" {
						di as error "Variable `v' does not have a label, so the noextend option cannot be applied to it."
						di as error "Since you used the noextendall option, the rencodeall command is aborting."
						exit 198
					}
					local noextendToUse = ""
				}
				else {
					* A label exists with the same name as the variable.  Use noextend.
					local noextendToUse = "noextend"
				}
			}
			capture rencode `v' `if' `in', `labelOption' `noextendToUse' replace
			if _rc == 459 {
				local note = cond("`noextend'"=="",""," probably because noextend was specified and new values occur")
				di as result "Not encoded (error 459`note'): `v'"
				if "`noextendall'" == "noextendall" {
					di as error "Since you used the noextendall option, the rencodeall command is aborting."
					exit 459
				}
			}
			else {
				if _rc > 0 {
					di as error "Error while encoding `v':"
					error _rc
				}
				local nEncoded = `nEncoded' + 1
			}
		}
	}
	if `nEncoded'==0 {
		di as result "Nothing to encode."
	}
	else {
		local s = cond(`nEncoded'==1, "", "s")
		di as result "Encoded `nEncoded' variable`s'."
	}
	restore, not
end
