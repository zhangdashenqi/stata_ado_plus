*! 3.3.1  Jan 03, 97 Jeroen Weesie/ICS  STB-38 dm48
*! 3.0.5  mar 08, 95 StataCorp

capture program drop reshape2
program define reshape2
	version 5.0
	local c "`1'"
	if "`c'" == "" { error 198 }
	mac shift
	local l = length("`c'")

        if "`c'" == substr("clear",1,`l') {               /* reshape clear  */
                rsclear
        }
	else if "`c'" == substr("cons",1,`l') {           /* reshape cons   */
		if "`*'" == "" { error 198 }
		unabbrev "`*'"
		global rCONS "$S_1"
	}
	else if "`c'" == substr("groups",1,`l') {         /* reshape groups */
		rsgroup `*'
	}
	else if "`c'" == substr("id",1,`l') {             /* reshape id     */
		if "`*'" == "" { error 198 }
		unabbrev "`*'", min(1) max(8)
		global rID "$S_1"
	}
	else if "`c'" == "long" {                         /* reshape long   */
		rslong `*'
	}
	else if "`c'" == substr("query",1,`l') {          /* reshape query  */
                rsquery
	}
	else if "`c'" == substr("vars",1,`l') {           /* reshape vars   */
		if "`*'" == "" { error 198 } 
                rsmasks `*'
	}
	else if "`c'" == "wide" {                         /* reshape wide   */
		rswide `*'
	}
	else    error 198
end

program define rsclear /* reshape clear */
        version 5.0
	global rCONS
        global rGRPINT
	global rGRPVAR
	global rID
	global rMASKS
	global rVALUES
	global rVARS
end

program define rsquery /* reshape query */ 
        version 5.0
	rsmacro
        local rvlong "$rVLONG"
        if "`rvlong'" == "" { local rvlong "<nothing>" }

	capture confirm var $rGRPVAR
        if _rc { local mode "wide" }
        else     local mode "long" 

        di _n in gr "Declarations for reshape " /* 
                 */ " (currently in mode " in ye "`mode'" in gr ")"

        di in gr _dup(79) "-"
	rsdilist "level 1 id variables     " 27 "$rID"
	rsdilist "        cons variables   " 27 "$rCONS"
        di in gr _dup(25) "-"
	rsdilist "level 2 group variable   " 27 "$rGRPVAR"
	rsdilist "        masks for vars   " 27 "$rMASKS"
        di in gr _dup(25) "-"
	rsdilist "wide:   group values     " 27 "@ = $rVALUES"
        rsdilist "long:   character        " 27 "@ = `rvlong'"
        di in gr _dup(79) "-"
end

* utility for rsquery
*   displays a list (arg3) starting at column col (arg2) with title 
*   (arg 1) displayed as a hanging indent in column 1.
program define rsdilist
        version 5.0
        local title "`1'"
        local col   "`2'"
        local list  "`3'"

        parse "`list'", p(" ")
        while "`*'" != ""{
                local llist "`1'" /* di at least on term */
                mac shift
                while "`1'" != "" & length("`llist' `1'") <= 80-`col' {
                        local llist "`llist' `1'" 
                        mac shift
                }
                if "`title'" != "" {
                        di in gr "`title'" _col(`col') in ye "`llist'"
                        local title
                }
                else    di _col(`col') "`llist'"
        }
end
        
* usage: rsvnames mask val 
* creates the wide- and long-format of the -vars- variable names S_1 and S_2  
program define rsvnames          
        version 5.0
        local mask "`1'"
        local val  "`2'"
        local ind = index("`mask'", "@")
        if `ind' > 0 {
                local pre  = substr("`mask'",1,`ind'-1)
                local post = substr("`mask'",`ind'+1,.)
	        global S_1 "`pre'`val'`post'"
	        global S_2 "`pre'$rVLONG`post'"
        } 
        else { 
                global S_1 "`mask'`val'" 
                global S_2 "`mask'$rVLONG" 
        }
end

* usage: rsmasks masks
* creates the global macros rVARS and rMASKS
program define rsmasks
        version 5.0
        global rMASKS "`*'"
        parse "$rMASKS", p(" ")
        while "`1'" != "" {
                rsvnames `1' 0
                global rVARS "$rVARS$S_2 "
                mac shift
        }
end

program define rswide /* reshape wide */
	version 5.0
	rsmacro
	capture confirm var $rGRPVAR
	if _rc { 
		di in bl "(already wide)"
		exit
	}
	confirm var $rGRPVAR $rVARS $rID $rCONS
	tempfile master cons

	if "$rID" == "" { local mergev "$rCONS" }
	else            local mergev "$rID" 

	preserve
	quietly {

             *  save master 

		keep $rGRPVAR $rVARS $rID $rCONS
		sort `mergev' $rGRPVAR
		capture by `mergev' $rGRPVAR : assert _N==1
		if _rc {
			di in re "(case-id,group-id) should be unique"
			exit 198
		}
		save `master', replace 

             *  save cons
      
		by `mergev' : keep if _n==1
		keep $rID $rCONS
		save `cons', replace

              * save groups

		parse "$rVALUES", parse(" ")
                local v 1
		while "``v''" != "" { 
			use `master', clear
                        if $rGRPINT == 1 { keep if $rGRPVAR == ``v''   }
                        else               keep if $rGRPVAR == "``v''" 
			if _N == 0 { 
				noisily di in bl /*
				*/ "(note:  no data for $rGRPVAR == ``v'')"
			}
			else { 
				keep `mergev' $rVARS 
				noisily rsfixlst ``v''
                                sort `mergev'
                                tempfile F`v'
                                local Files "`Files' `F`v''"
                                save `F`v''
                        }
                        local v = `v'+1
                }

              * merge cons and groups

                use `cons'
                parse "`Files'", p(" ")
                while "`1'" != "" {
			merge `mergev' using `1'
			drop _merge 
			sort `mergev' 
			mac shift 
                }
        }
	restore, not
end

program define rsfixlst /* reshape wide utility */
	version 5.0
	local val "`1'"
	parse "$rMASKS", parse(" ")
	while "`1'" != "" { 
                rsvnames "`1'" "`val'"
	        local wname "$S_1"      /* -wide- name */
		local lname "$S_2"      /* -long- name */
		capture confirm new var `wname'
		if _rc {
			capture confirm var `wname'
			if _rc {
				di in red "`wname' variable name too long"
				exit 198
			}
			else {
				di in red "`wname' already defined"
				exit 110
			}
		}
		rename `lname' `wname'
		label var `wname' "`val' `1'"
		mac shift 
	}
end

program define rslong /* reshape long */
	version 5.0
	rsmacro
	confirm var $rID $rCONS
	capture confirm new var $rGRPVAR
	if _rc { 
		di in bl "(already long)"
		exit
	}
	tempfile new
	preserve
	quietly {
		mkrtmpST

              * save the groups in files
  
		parse "$rVALUES", parse(" ")
		while "`1'" != "" { 
			restore, preserve
			noisily rslongdo `1'
                        tempfile F`1'
                        local Files "`Files' `F`1''"
                        save `F`1''
			mac shift 
		}
                
              * append the files
                
                parse "`Files'", parse(" ")
                use `1'
                mac shift
                while "`1'" != "" {
                        append using `1'
                        mac shift
                }
		global rtmpST
	}
	restore, not
end

program define mkrtmpST
	version 5.0
	global rtmpST
	parse "$rMASKS", parse(" ")
	while "`1'" != "" {
                local mask "`1'"
		local ct "empty"
		local i 1
		local val : word `i' of $rVALUES
		while "`val'" != "" {
                        rsvnames  "`mask'" "`val'"
	                local wname "$S_1"      /* -wide name */
			capture confirm var `wname'
			if _rc == 0 {
				local nt : type `wname'
				rsrecast "`ct'" `nt'
				local ct "$S_1"
                                if "`ct'" == "" {
               noi di in re "`wname' type mismatch with other `mask' variables"
					exit 198
				}
			}
			else {
				capture confirm new var `wname'
				if _rc {
					di in re /*
					*/ "`wname' implied name too long"
					exit 198
				}
			}
			local i = `i'+1
			local val : word `i' of $rVALUES
		}
		if "`ct'" == "empty" { 
			local ct "byte"
		}
		global rtmpST "$rtmpST `ct'"
		mac shift
	}
end

program define rslongdo /* reshape long dolist utility */
	version 5.0
	local val "`1'"
	parse "$rMASKS", parse(" ")
	local i 1
	while "``i''" != "" {
                rsvnames "``i''" "`val'"
	        local wname "$S_1"              /* -wide- name */
		local lname "$S_2"              /* -long- name */
                local wnames "`wnames' `wname'"
                local lnames "`lnames' `lname'"

		local typ : word `i' of $rtmpST
		capture confirm var `wname'
		if _rc { 
			di in bl "(note:  `wname' not found)"
			if substr("`typ'",1,3)=="str" {
				quietly gen `typ' `wname' = "" 
			}
			else    quietly gen `typ' `wname' = . 
		}
		else    recast `typ' `wname'
		local i=`i'+1
	}

	keep $rID $rCONS `wnames'
        if $rGRPINT==1 { quietly gen int  $rGRPVAR =  `val'  }
        else             quietly gen str8 $rGRPVAR = "`val'" 

        local i 1
        local nmask : word count `wnames'
        while `i' <= `nmask' {
                local wname : word `i' of `wnames'
                local lname : word `i' of `lnames'
                rename `wname' `lname'
                label var `lname'
                local i = `i'+1
        }
end

program define rsrecast /* recast command to maintain precision */
	version 5.0

	if "`1'" == "empty" | "`1'" == "`2'" {
		global S_1 "`2'"
		exit
	}

	local a "`1'"
	local b "`2'"

	local aisstr = substr("`a'",1,3)=="str"
	local bisstr = substr("`b'",1,3)=="str"
	if `aisstr'!=`bisstr' {
		global S_1
		exit
	}

	if "`a'" == "byte" {
		global S_1 "`b'"
		exit
	}

	global S_1 "`a'"
	if "`a'" == "int" {
		if "`b'" != "byte" {
			global S_1 "`b'"
		}
		exit
	}

	if "`a'" == "float" {
		if "`b'" == "`double'" {
			global S_1 "`b'"
		}
		exit
	}
	if "`a'" == "double" { exit }

	local l1 = real(substr("`a'",4,.))
	local l2 = real(substr("`b'",4,.))
	if `l2' > `l1' {
		global S_1 "`b'"
	}
end

program define rsgroup /* reshape group command: varname values [, string] */
        version 5.0
        parse "`*'", p(",")
        local grpart "`1'"
        mac shift
        local options "String Long(str)"
        parse "`*'"
        if "`string'" != "" {           /* interpret values as strings */
                parse "`grpart'", p(" ")
                global rGRPVAR "`1'"
                global rGRPINT 0 
                mac shift
                * no support for range for alphanumeric values
                global rVALUES "`*'"
        }
        else {                          /* interpret values as int,ranges */
                                        /* to be replaced by -numlist- */
	        parse "`grpart'", parse(" -")
	        if "`3'" == "" { error 198 } 
	        global rGRPVAR "`1'"
                global rGRPINT 1 
	        mac shift
	        confirm integer number `1'
	        global rVALUES `1'
	        local last `1'
	        mac shift
	        while "`1'" != "" {
		        if "`1'" == "-" {
			        mac shift
			        confirm integer number `1'
			        if `1' <= `last' { error 198 }
			        local i = `last'+1
			        while `i '<= `1' {
				        global rVALUES "$rVALUES `i'"
				        local i = `i'+1
			        }
			        local last `1'
		        }
		        else {
			        confirm integer number `1'
			        global rVALUES "$rVALUES `1'"
			        local last `1'
		        }
		        mac shift
	        }
        }
        if "`long'" != "" {
                global rVLONG "`long'"
        }
end

program define rsmacro  /* reshape macro check utility */
	version 5.0
	if "$rGRPVAR" == "" { 
		di in red "grouping variable not defined"
		exit 111
	}
	if "$rVALUES" == "" {
		di in red "values not defined"
		exit 111
	}
	if "$rCONS" == "" { 
		di in red "constants not defined"
		exit 111
	}
	if "$rVARS" == "" { 
		di in red "vars not defined"
		exit 111
	}
	if "$rID" == "" { 
		di in bl "-id- variable(s) not defined, -cons- variables used instead"
	}
end
exit
