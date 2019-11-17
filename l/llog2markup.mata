*! Source code of llog2markup.mlib
*	2017-02-12 > TODO: Handling for-loops. Workaround: /***/display `"code"'
*	2016-09-01 > In case "Ignore code, keep pure sample" string trimming is removed
*	2016-08-18 > Added remove_line_pattern() and substitute_line_pattern() to simplify code and sample output
*	2016-03-16 > Removing dots after samples
*	2016-03-16 > Commented code (starting with a * or // are ignored in the output
*	2016-03-02 > keep_sample not set properly to 0 when markup block starts
*	2016-03-02 > Left aligned output for option log
* version 1.0.1	Niels Henrik Bruun	2016-02-15
*	2016-02-15 > Kit Baum discovered bug when logfile doesn't exist. Thanks
* version 1.0		Niels Henrik Bruun	2016-02-15


*	2016-02-22 > ignore blanks after ***/ so that that blanks do not prevent closing of textblocks

version 12

mata:
	mata clear
	mata set matalnum on

	string colvector file2mata(string scalar filename)
	// consider using cat
	{
		string colvector lines
		string scalar line
		real scalar fh

		if (fileexists(filename)) {
			fh = fopen(filename, "r")
			lines = J(0,1,"")
			while ( (line=fget(fh)) != J(0,0,"") ) {
				lines = lines \ line
			}
		} else {
			printf(`"{error} File "%s" does not exist!"', filename)
			lines = J(0,0,"")
		}
		fclose(fh)
		return(lines)
	}

	string colvector prune_code(string colvector lines)
	/*
		Requires:	A string vector log lines without log start and log end
		Returns:	A string vector without code blocks within //OFF and //ON
	*/
	{
		real scalar keep, r
		string colvector new_lines 
		
		new_lines = J(0,1,"")
		keep = 1
		for(r=1;r<=rows(lines);r++){
			keep = keep & !regexm(lines[r], "^\. //OFF")
			if ( keep ) {
				new_lines = new_lines \ lines[r]
			} else {
				keep = regexm(lines[r], "^\. //ON")
			}
		}
		return(new_lines)
	}

	string colvector prune_comment(string colvector lines)
	/*
		Requires:	A string vector log lines without log start and log end
		Returns:	A string vector without comments within /* and */
	*/
	{
		real scalar keep, r
		string colvector new_lines 
		
		new_lines = J(0,1,"")
		keep = 1
		for(r=1;r<=rows(lines);r++){
			if ( regexm(lines[r], "^\. //") ) continue
			if ( regexm(lines[r], "^\. \*") 
				& !regexm(lines[r], "^\. \*\*\*/") ) continue
			keep = (keep & !(regexm(lines[r], "^\. /\*") 
								& !regexm(lines[r], "^\. /\*\*")))
			if ( keep ) {				
				new_lines = new_lines \ lines[r]
			} else {
				keep = (regexm(lines[r], "\*/$") 
								& !regexm(lines[r], "\*\*\*/ *$"))
			}
		}
		return(new_lines)
	}

	string colvector lines2markup(string colvector lines, string scalar code_start, code_end, sample_start, sample_end)
	/*
		Requires:	Log lines pruned for log start, log end, comments and code 
					blocks to be ignored.
		Returns: 	md lines with code marked as code and output as quote
	*/
	{
		string scalar codeline
		string colvector md_lines 
		real scalar r, R, is_md, is_code, is_sample
		real scalar keep_code, keep_sample
		
		is_md = 0
		is_code = 0
		is_sample = 0
		keep_code = 0
		keep_sample = 0
		md_lines = J(0,1,"")
		R = rows(lines)
		for(r=1;r<=R;r++){
			// Not markup block
			if ( !is_md ) {
				// markup block starts
				if ( is_md=regexm(lines[r], "^\. /\*\*\*") 
							& !regexm(lines[r], "^\. /\*+/") ) {
					if ( is_sample ) {
						is_sample = 0
						if ( keep_sample ) {
							md_lines = md_lines \ sample_end \ ""
							keep_sample = 0
						}
					}
					if ( regexm(lines[r], "^\. /\*\*\*(.*)") & regexs(1) != "" ) {
						md_lines = md_lines \ "" \ regexs(1)
					}
				// Or line is in a code/sample block 
				} else {
					// Code block starts
					if ( regexm(lines[r], "^\. (.+)") ) {
						if ( is_sample ) {
							is_sample = 0
							if ( keep_sample ) md_lines = md_lines \ sample_end \ ""
						}
						codeline = regexs(1)
						is_code = 1
						// Ignore code, keep verbatim sample
						if ( regexm(codeline, "^/\*\*\*/") ) {
							keep_code = 0
							keep_sample = 1
						// Keep verbatim code, ignore sample
						} else if ( regexm(codeline, "^/\*\*/ *(.+)") ) {
							codeline = regexs(1)
							keep_code = 1
							keep_sample = 0
						// Ignore code, keep pure sample
						} else if ( regexm(codeline, "^/\*\*\*\*/")) {
							keep_code = 0
							keep_sample = 0
						} else {
							keep_code = 1
							keep_sample = 1
						}
						if ( keep_code ) {
							md_lines = md_lines \ code_start
							md_lines = md_lines \ codeline
						}						
					// Code block continues
					} else if ( regexm(lines[r], "^> (.*)") ) {
						if ( keep_code ) md_lines = md_lines \ regexs(1)
					// Code block ends and sample block starts
					} else if ( is_code & !regexm(lines[r], "^> .*") ) {
						if ( keep_code ) md_lines = md_lines \ code_end
						if ( keep_sample ) md_lines = md_lines \ "" \ sample_start
						is_code = 0
						is_sample = 1
						// keep verbatim sample
						if ( keep_sample ) {
							md_lines = md_lines \ lines[r]
						// Ignore code, keep pure sample
						} else if ( !keep_code ) {
							md_lines = md_lines \ lines[r]
						}
					// Sample block continues
					} else if ( is_sample ) {
						// keep verbatim sample
						if ( keep_sample ) {
							// Ignore final dot in sample
							if ( !regexm(lines[r], "^\. *$") ) md_lines = md_lines \ lines[r]
						// Ignore code, keep pure sample
						} else if ( !keep_code ) {
							if ( !regexm(lines[r], "^\. *$") ) md_lines = md_lines \ lines[r]
						}
					}
				}
			// markup block ends
			} else if ( is_md & regexm(lines[r], "^> (.*)\*\*\*/ *$") ) {
				// Save last markup line
				md_lines = md_lines \ regexs(1) \ ""
				is_md = 0
			// markup block continues
			} else if ( is_md & regexm(lines[r], "^> (.*)") ) {
				md_lines = md_lines \ regexs(1)
			}
		}
		if ( keep_sample ) md_lines = md_lines \ sample_end
		return(md_lines)
	}

	string colvector remove_line_pattern(	string colvector lines, 
											string colvector pattern)
	{
		real scalar r, np, R
		string colvector out
		
		out = J(0,1,"")
		np = rows(pattern) - 1
		R = rows(lines)
		for(r=1;r<=R;r++) {
			if ( r < R - np ) {
				if ( lines[(r..r+np)] != pattern ) out = out \ lines[r]
				if ( lines[(r..r+np)] == pattern ) r = r + np
			} else {
				out = out \ lines[r]
			}
		}
		return(out)
	}	

	string colvector substitute_line_pattern(	string colvector lines, 
												string colvector pattern, 
												string colvector replacelines)
	{
		real scalar r, np, R
		string colvector out
		
		out = J(0,1,"")
		np = rows(pattern) - 1
		R = rows(lines)
		for(r=1;r<=R;r++) {
			if ( r <= R - np ) {
				if ( lines[(r..r+np)] != pattern ) out = out \ lines[r]
				if ( lines[(r..r+np)] == pattern ) {
					r = r + np
					out = out \ replacelines
				}
			} else {
				out = out \ lines[r]
			}
		}
		return(out)
	}
	
	string colvector loglines2markup(string scalar logfile, extension, code_start, code_end, sample_start, sample_end, real scalar log, replace)
	/*
		Requires:	Path and name on a text log file in a string
		TODO: 		Verify string input as an existing text! log file
	*/
	{	
		string colvector lines
		string scalar fn
		real scalar rc, fh, r

		if ( !fileexists(logfile) ) _error(sprintf("File %s do not exist!!", logfile))
		lines = file2mata(logfile)
		if ( lines[4] != "  log type:  text" ) _error(sprintf("File %s is not a Stata text log file!!", logfile))
		lines = lines[6..rows(lines)-6] // Remove log start and log end
		lines = prune_code(lines)
		lines = prune_comment(lines)
		lines = lines2markup(lines, code_start, code_end, sample_start, sample_end)

		lines = substitute_line_pattern(lines, ("" \ code_start), (code_start))
		lines = substitute_line_pattern(lines, (code_end \ ""), (code_end))
		lines = substitute_line_pattern(lines, (sample_start \ ""), (sample_start))
		lines = substitute_line_pattern(lines, ("" \ sample_end), (sample_end))
		lines = substitute_line_pattern(lines, ("" \ sample_end), (sample_end))

		lines = remove_line_pattern(lines, (sample_start \ sample_end))
		lines = remove_line_pattern(lines, (code_end \ code_start))
		lines = remove_line_pattern(lines, (code_end \ "" \ code_start))
		
		if ( log ) {
			for(r=1;r<=2;r++) ""	// Empty lines before printing
			for(r=1;r<=rows(lines);r++) lines[r]
		} else {
			fn = subinstr(logfile,".log", sprintf(".%s", extension))
			if ( replace ) rc = _unlink(fn)
			fh = fopen(fn, "w")
			for(r=1;r<=rows(lines);r++) {
				rc = _fput(fh, lines[r]) 
			}
			fclose(fh)
		}
		return(lines)
	}
end
