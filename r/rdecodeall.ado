* rdecodeall
* Program to decode multiple variables and replace originals.
* Like decode, but replaces instead of using generate(name), and operates on multiple variables.
* Ignores non-labelled variables.
* The generated variables are compressed to the smallest string length possible.
* You may want to drop labels afterward, but this program does not drop any labels.
* Kenneth L. Simons, September 2006.
program define rdecodeall
	version 9.0
	syntax [varlist] [if] [in], [MAXLength(integer 244) RENcodecommands(string) REPLACE]
	* Run the rdecode command on each variable in the varlist.
	preserve
	local nDecoded = 0
	local rencodecommandsLen : length local rencodecommands
	if `rencodecommandsLen' {
		tempname fileHandle
		file open `fileHandle' using "`rencodecommands'", write text `replace'
	}
	foreach v of local varlist {
		local valLabel : value label `v'
		if "`valLabel'"!="" {
			if `rencodecommandsLen' {
				file write `fileHandle' "rencode `v', label(`valLabel') replace" _n
			}
			capture rdecode `v' `if' `in', maxlength(`maxlength') replace
			if _rc > 0 {
				local rc = _rc
				if `rencodecommandsLen' {
					* Erase the global with rencode commands, since the program is aborting with nothing encoded.
					file close `fileHandle'
					erase "`rencodecommands'"
				}
				di as error "Error while decoding `v':"
				error `rc'
			}
			local nDecoded = `nDecoded' + 1
		}
	}
	if `rencodecommandsLen' {
		file close `fileHandle'
	}
	if `nDecoded'==0 {
		di as result "Nothing to decode."
	}
	else {
		local s = cond(`nDecoded'==1, "", "s")
		di as result "Decoded `nDecoded' variable`s'."
	}
	restore, not
end
