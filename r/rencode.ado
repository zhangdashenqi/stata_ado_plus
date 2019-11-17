* rencode
* Program to encode variable and replace original as desired.
* Like encode, but can specify replace option instead of generate(name).
* This program also compresses the generated variable to a more efficient datatype if possible.
* Kenneth L. Simons, March 2006.
program define rencode
	version 9.0
	syntax varname [if] [in], [Generate(name) Label(name) NOExtend REPLACE]
	* Parse options.
	if "`replace'"=="" & "`generate'"=="" {
		di as error "Use the replace option to overwrite the original variable, or use the generate(name) option to create a new variable."
		error 197
	}
	if "`replace'"=="replace" & "`generate'"!="" {
		di as error "Specify only one of generate(name) or replace options.  Replace will overwrite the original variable."
		error 197
	}
	if "`replace'"=="replace" {
		tempvar toGenerate
		local generate `toGenerate'
		if "`label'"=="" {
			local label `varlist'
		}
		local varlabel: variable label `varlist'
	}
	if "`label'"=="" {
		local labelOption
	}
	else {
		local labelOption label(`label')
	}
	* Run the encode command.
	encode `varlist' `if' `in', generate(`generate') `labelOption' `noextend'
	quietly compress `generate'
	* If replacing the original variable, do so.
	if "`replace'"=="replace" {
		move `generate' `varlist'
		nobreak {
			drop `varlist'
			rename `generate' `varlist'
			label values `varlist' `label'
			if "`varlabel'"!="" {
				label variable `varlist' `"`varlabel'"'
			}
		}
	}
end
