*! NJC and JBW 1.2.2 30 March 2000  (STB-56: dm80)
* NJC 1.0.0 2 November 1999 
program def tostring

	version 6.0
	syntax varlist [ , Format(str) noDecode Usedisplayformat ]

	if "`usedisplayformat'" != "" & "`format'" != "" {
		di in r  /* 
	*/ "must choose between -usedisplayformat- and -format( )- options"
		exit 198
	}

	if "`format'" != "" { /* try it out */
		capture di `format' 12345.67890
		if _rc {
			di in r "format( ) option invalid"
			exit 111
		}
		local format `", "`format'""'
	}
	else local format `", "%12.0g""' 

	local u = "`usedisplayformat'" != "" 
	
	tokenize `varlist'
	tempvar temp
	
	qui nobreak {
		while "`1'" != "" {
			capture confirm str var `1'
		        if _rc == 0 { 
				noi di in g "`1' already " in y "string" 
			}
			else {
			        if `u' { /* use display format */
					local format: format `1'
				        local format `", "`format'""'
		        	}
				
				local varlab : variable label `1'
			        local vallab : value label `1'
				
			        if "`decode'" == "" & "`vallab'" != "" {
					decode `1', generate(`temp')
         			}
			        else {
			        	gen str1 `temp' = ""
				        replace `temp' = string(`1'`format')
				        replace `temp' = "" /* 
					*/ if trim(`temp') == "."
			        }

			        local oldtype : type `1'
			        move `temp' `1'
				char rename `1' `temp' 
				drop `1'
			        rename `temp' `1'
			        local newtype : type `1'
			        label var `1' `"`varlab'"'
			        noi di in g "`1' was " in y "`oldtype'" /*
			         */ in g " now " in y "`newtype'"
		      }
		      mac shift
		}
	}
end

