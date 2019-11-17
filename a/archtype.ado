*! Version NJC 1.1.0 7 October 1999  (STB-52 ip29)
* NJC 1.0.0 11 May 1999 
program def archtype
        version 6.0
	if "`0'" == "" { 
		di in g "syntax: " in w "archtype " in g "filename.ext" 
		exit 198 
	}	

	local init = substr("`1'",1,1) 
	type http://fmwww.bc.edu/repec/bocode/`init'/`1'
end 	
