* rdecode
* Program to decode variable and replace original as desired.
* Like decode, but can specify replace option instead of generate(name).
* This program also compresses the generated variable to a more efficient datatype if possible.
* Kenneth L. Simons, September 2006.
program define rdecode
	version 9.0
	syntax varname [if] [in], [Generate(name) MAXLength(integer 244) REPLACE]
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
	}
	* Run the decode command.
	decode `varlist' `if' `in', generate(`generate') maxlength(`maxlength')
	quietly compress `generate'
	* If replacing the original variable, do so.
	if "`replace'"=="replace" {
		move `generate' `varlist'
		nobreak {
			drop `varlist'
			rename `generate' `varlist'
		}
	}
end
