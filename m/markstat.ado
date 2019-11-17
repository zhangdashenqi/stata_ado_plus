program define markstat
version 14
*! v 1.6 <grodri@princeton.edu> 26oct2016 rev 25may2017
	capture noisily _markdown `0'
	if _rc > 0 _closeAllFiles
end

program _markdown
	syntax using/	[, pdf mathjax strict plain BIBliography]
	local tex = "`pdf'" == "pdf"
	local strict = "`strict'" == "strict"
	local plain = "`plain'" == "plain"
	local bib = "`bibliography'" == "bibliography"

	// script
	mata: splitPath(`"`using'"') // sets macros
	if "`isurl'" != "" {
		display as error "input must be a local file, not a url"
		display as error "consider using {bf}copy{sf} first"
		exit 632
	}
	if "`suffix'" != "" & "`suffix'" != ".stmd" {
		display as error "file suffix must be .stmd or blank"
		exit 198
	}
	if "`suffix'" == "" local suffix .stmd
	local filename `folder'`file'
	confirm file "`filename'.stmd"	
	
	// output 
	local output "html"
	if `tex' local output "tex"	
	if `tex' == 0 & "`mathjax'" != "" local mj --mathjax
	
	// tangle	
	mata tangle(`"`filename'"', `tex', `strict')
	
	// stata
	do `"`filename'"'		
	
	// pandoc
	whereis pandoc
	if `tex' local output "latex"
	local flags -f markdown -t `output' -s `mj'		
	if `bib' local flags --filter pandoc-citeproc `flags'
	capture erase "`filename'.pdx"
	local cmd `""`r(pandoc)'" "`filename'.md" `flags' -o "`filename'.pdx""'
	shell `cmd'
	confirm file "`filename'.pdx"
	
	// weave
	mata weave(`"`filename'"', `tex', `plain')
	
	// pdflatex
	if `tex' {
		whereis pdflatex
		local cmd `""`r(pdflatex)'" "`file'.tex""' 
		if "`folder'" != "" {
			local cmd `cmd' -output-directory="`folder'"
		}
		shell `cmd'
		confirm file "`filename'.pdf"
	}
	
	// view
	if `tex' local output pdf
	view browse "`filename'.`output'"
end

program _closeAllFiles
	forvalues i = 0(1)12 {
		capture mata: fclose(`i')
	}
end

mata:

// ---------------------------------------------------------------------------
//  Tangling
// ----------

void tangle(string scalar filename, real scalar tex, real scalar strict) {
 // split stmd file into do and md files with strict or relaxed syntax
	real scalar fh, dofile, mdfile, chunk, echo, mata
	string scalar mode, line, tag, closer, code, placeholder, match, prefix, args
 
	// open files
	fh = fopen(filename + ".stmd", "r")
	dofile = fopenwr(filename + ".do")
	mdfile = fopenwr(filename + ".md")
	
	// start do file with log
	fput(dofile, "capture log close")
	fput(dofile, `"log using ""' + filename + `"", replace"')
	
	// read all lines
	chunk = 0
	mode = "markdown"
	while( (line = fget(fh)) != J(0, 0, "")) {
		line = usubinstr(line, uchar(9), "    ", .)

		// Markdown
		if(mode == "markdown") {
		
			// stata code block?
			if(startsStata(line, strict, echo = 1, mata = 0)) {
				mode = "stata"
				chunk++
				// placeholder
				tag = strofreal(chunk)
				fput(mdfile, "")
				fput(mdfile, "{{" + tag + "}}")
				fput(mdfile, "")
				// start block
				if(echo == 0) tag = tag + "q"
				if(mata) tag = tag + "m"
				fput(dofile, "//_" + tag)
				if(mata) fput(dofile, "mata:")
				if(!strict) fput(dofile, usubstr(line, 5, .))
			}
			
			// verbatim or math block?
			else if(startsBlock(line)) {
				mode = "block"
				closer = blockCloser(line)				
				fput(mdfile, line)
			}
			
			else {			
				// stata.mata inline code?
				code = ""
				prefix = ""
				while(hasInlineCode(line, code, prefix)) {
					chunk++
					tag = strofreal(chunk)
					fput(dofile, "//_" + tag)
					// mata
					if(prefix == "m") {
						if(startsWith(ustrtrim(code), "%")) {
							args = `"""' + usubinstr(code, " ", `"", "', 1)
						}
						else {
							args = `""%f", "' + code
						}
						fput(dofile, "mata:printf(" + args + ")")
					}
					// stata
					else {
						fput(dofile, "display " + code)
					}
					placeholder = "{{." + tag + "}}"
					match = "`" + prefix + " " + code + "`" 
					line = usubinstr(line, match, placeholder, 1)					
				}
				// code extension
				if(tex) tag2tex(line)
				// markdown
				fput(mdfile, line)
			}
		}
		
		// Code Fences or Display Math
		else if (mode == "block") {
			fput(mdfile, line)
			if(endsBlock(line, closer)) {
				mode = "markdown"				
			}
		}
		
		// Stata
		else {			
			if(endsStata(line, strict)) {
				mode = "markdown"
				if(mata) fput(dofile, "end")
				if(!strict) fput(mdfile, line)
			}
			else {
				if(isIndented(line)) line = usubstr(line, 5, .)
				fput(dofile, line)
			}
		}
	}
	// close files
	fput(dofile, "//_^")	
	fput(dofile, "log close")
	fclose(fh)
	fclose(dofile)
	fclose(mdfile)		
}
real scalar isIndented(string scalar line) {
 // line starts with four spaces after detab
	if(ustrtrim(line) == "") return(0)
	return(startsWith(line, "    "))
}

real scalar startsStata(string scalar line, real scalar strict, 
	real scalar echo, real scalar mata) {
 // line starts Stata code using strict or relaxed syntax
	string scalar next
	echo = 1
	mata = 0
	if(!strict) {
		return(isIndented(line))
	}
	else { 
		// ```s/ or ```m/ for no echo		
		if(!startsWith(line, "```")) return(0)
		next = ustrtrim(usubstr(line, 4, .))
		if (ustrregexm(next, "^\{(.+)\}$") > 0) next = ustrregexs(1)
		if(ustrregexm(next, "^([s|m][/]?)$") != 1) return(0)
		if(ustrpos(ustrregexs(1), "/") > 0) echo = 0
		mata = usubstr(next, 1, 1) == "m"
		return(1)
	}					
}

real scalar endsStata(string scalar line, real scalar strict) {
 // line ends Stata code using relaxed or strict syntax
	if(!strict) {
		return(!isIndented(line))
	}
	else {
		return(startsWith(line, "```"))
	}
}

real scalar startsBlock(string scalar line) {
 // line is a code fence or display math opener
	if(ustrtrim(line) == "$$") return(1)
	return(startsWith(line, "```") || startsWith(line, "~~~"))
}

string scalar blockCloser(string scalar line) {
 // dollars or code fence with at least as many backticks/tildes as opener
	string scalar trimmed, tick
	real scalar n
	trimmed = ustrtrim(line)
	if(usubstr(trimmed, 1, 2) == "$$") return("$$")
	tick = usubstr(trimmed, 1, 1)
	n = indexnot(trimmed, tick) - 1
	if(n < 1) n = ustrlen(trimmed)
	return(n * tick)
}	

real scalar endsBlock(string scalar line, string scalar closer) {
 // line starts with current block closer
	return(startsWith(line, closer))
}

// ---------------------------------------------------------------------------
//  Weaving
// ---------
	
void weave(string scalar filename, real scalar tex, real scalar plain) {
 // weave stata and markdown output into html or latex file
 
	real scalar outfile, infile, i, n
	real vector markers
	string scalar outext, line, blockhold, inlinehold, logline, includefile
	string vector lines
	pointer(function) handler	
 
	// output file
	outext = tex ? ".tex" : ".html"
	outfile = fopenwr(filename + outext)
	
	// get translated smcl
	lines = translateLog(filename, tex, plain)
	markers = select(1::length(lines), ustrregexm(lines, "[.|:] //_") :> 0)
	
	// open Pandoc output
	infile = fopen(filename + ".pdx", "r")	
	if(tex) {
		// inject stata.sty
		line = fget(infile)
		fput(outfile, line)
		fput(outfile, "\usepackage{stata}")
	}
	
	// code placeholders and handlers
	blockhold  = tex?  "^\\\{\\\{([0-9]+)\\\}\\\}$" : "<p>\{\{([0-9]+)\}\}</p>"
	inlinehold = tex?  "\\\{\\\{\.([0-9]+)\\\}\\\}" : "\{\{\.([0-9]+)\}\}"				
	handler = tex ? &log2tex() : &log2html()		
	
	// process pdx file
	n = 0
	while( (line = fget(infile)) != J(0, 0, "") ) {
		
		// handle code block 
		if(ustrregexm(line, blockhold) > 0) {			
			n = strtoreal(ustrregexs(1))
			(*handler)(outfile, lines, markers[n], markers[n + 1] - 1)
		}
		// handle includes
		else if (ustrregexm(line,"<p>.include ([^<]+)</p>") > 0) {
			includefile = ustrregexs(1)
			printf(".include file %s\n", includefile)
			if(!fileexists(includefile)) {
				errprintf("include file %s not found", includefile)
				exit(601)
			}
			fputvec(outfile, cat(includefile))
		}
		// resize LaTeX graphs
		else if (startsWith(line,"\includegraphics{")) {
			line = usubinstr(line, "{", "[width=0.75\linewidth]{", 1)
			fput(outfile, line)
		}
		else {	
			// handle inline code
			while(ustrregexm(line, inlinehold) > 0) {
				n = strtoreal(ustrregexs(1))
				logline = lines[markers[n] + 2]
				if(!tex) logline = htmlEncode(logline, 1, 1)
				line = usubinstr(line, ustrregexs(0), logline, 1)
			}				
			// write markdown
			fput(outfile, line)				
			if(!tex && n == 0) { 
				if(ustrtrim(line) == "<head>") injectCss(outfile)
			}
		}
		
	}
	fclose(infile)
	fclose(outfile)
}		

string vector translateLog(string scalar filename, real scalar tex, real scalar plain) {
 // process echo and rules in smcl log, then translate
	real scalar changed, fh, i
	real vector markers	
	string scalar infile, logfile, cmd, dashes, hrule, width
	string vector lines, hide
	
	// get smcl
	infile = filename + ".smcl"
	lines = cat(infile)
	
	// handle echo and mata rules
	changed = removeCommands(lines)
	
	// smart rules using drawing characters
	if(!tex & !plain) {		
		drawRules(lines)
		changed = 1
	}

	// save copy of log
	if(changed) {
		infile = st_tempfilename()
		fh = fopenwr(infile)
		fputvec(fh, lines)
		fclose(fh)
	}
	
	// translate smcl to TeX or Unicode text
	logfile = st_tempfilename()
	cmd = tex ?   "log texman " : "translate "
	cmd = cmd + `"""' + infile + `"" "' + logfile
	if(!tex) {
		width = strofreal(c("linesize"))
		cmd = cmd + ", translator(smcl2log) linesize(" + width + ")"
	}
	stata("quietly " + cmd)
	lines = cat(logfile)
	
	// handle hlines (3 or more -)
	if(!tex) {
		for(i = 1; i <= length(lines); i++) {
			while(ustrregexm(lines[i], "(--[-]+)") > 0) {
				dashes = ustrregexs(1)
				hrule = ustrlen(dashes) * "─"
				lines[i] = usubinstr(lines[i], dashes, hrule, 1)
			}
		}
	}
	
	// return translated log	
	return(lines)
}
void drawRules(string vector lines) {
 // modifies lines in place using IBM drawing characters for rules <>
	string vector c, d
	string scalar line, capture
	real scalar i, k, n
	
	c = "-", "|", "+", "TLC", "TT", "TRC", "LT", "RT", "BLC", "BT", "BRC"
	d = "─", "│", "┼", "┌",   "┬",  "┐",   "├",  "┤",  "└",   "┴",  "┘"
	
	for(i = 1; i <= length(lines); i++) {
		line = lines[i]
		capture = "\-|\||\+|TLC|TT|TRC|LT|RT|BLC|BT|BRC"
		// corners and singles
		while(ustrregexm(line, "\{c (" + capture + ")\}") > 0) {
			for(k = 1; k <= length(c); k++) {
				if(ustrregexs(1) == c[k]) break
			}
			line = usubinstr(line, ustrregexs(0), d[k], .)		
		}
		// hlines left for Stata
		lines[i] = line
	}
}
real scalar removeCommands(string vector lines) {
 // blocks with q in marker don't echo commands, with m remove mata rules <>
 // returns 1 if lines changed

	// check for q or m blocks
	markers = select(1::length(lines), ustrregexm(lines, "[\.|:] //_") :> 0)
	n = sum(ustrregexm(lines[markers], "[0-9]+[q|m]") :> 0)
	if (n < 1) return(0)

	// loop by block
	for(k = 1; k < length(markers); k++) {
		bot = markers[k] 
		top = markers[k + 1] - 1
		mark = usubstr(lines[bot], ustrpos(lines[bot], "//_"), .)
		
		// mata rules in m		
		if(ustrpos(mark, "m") > 0) {			
			j = bot + 1 \ bot + 2 \ top - 2\ top - 1
			block = lines[j]
			assert(isMataRules(block[1::2]) & isMataRules(block[3::4]))
			lines[j] = J(4, 1, "")
		}
		// commands in q
		if(ustrpos(mark, "q") > 0) {
			for(j = bot + 1; j <= top; j++) {
				two = usubstr(lines[j], 1, 2)
				if(two != "> ") { 
					iscmd = two == ". " || two == ": " || ustrpos(lines[j], "{com}") > 0
				}
				if(iscmd) {					
					// mata rules in q
					if (j < top) {
						if(isMataRules(lines[j\j+1]) ) lines[j + 1] = ""
					}
					lines[j] = ""
				}
			}
		}							
	}
	return(1)
}
function isMataRules(string vector lines) {
	if(!startsWith(lines[2], "{txt}{hline")) return(0)
	cmd = ustrtrim(usubinstr(lines[1], "{com}", "", 1))
	return(cmd == ". mata:" | cmd == ". mata" | cmd == ": end")
}	
void log2html(real scalar outfile, string vector lines, real scalar bot, real scalar top) {	
 // trim log snipet and wrap in preformatted tag with html encoding <>	
	string vector encoded
	real scalar trim
	trim = ustrregexm(lines[bot], "//_[0-9]+[m|q]+") > 0
	bot++
	
    // remove excess blank lines
    if(trim) unify(lines, bot, top, "")
        while(top >= bot) {
                if(ustrtrim(lines[top]) != "") break
                top--
        }

	while(top >= bot) {
		if(ustrtrim(lines[top]) != "") break
		top--
	}
	// empty
	if(top < bot) {
		fput(outfile, "")
	}
	// encode
	else {
		encoded = htmlEncode(lines, bot, top)
		fput(outfile, "<pre class='stata'>" + encoded[1])
		fputvec(outfile, encoded, 2, length(encoded))
		fput(outfile, "</pre>")
	}	
}

void log2tex(real scalar outfile, string vector lines, real scalar bot, real scalar top) {
 // wrap tex log in stlog environment  <>
	real scalar trim
  // unify multiple smallskips
	trim = ustrregexm(lines[bot], "//_[0-9]+[m|q]+") > 0
	bot++
	if(trim) unify(lines, bot, top, "{\smallskip}") 
	// empty
	if(top < bot) {
		fput(outfile, "")
	}
	// fix index and write
	else {
		if(usubstr(lines[bot], 1, 1) == " ") lines[bot] = "\" + lines[bot]
		fput(outfile, "\begin{stlog}")
		fputvec(outfile, lines, bot, top)
		fput(outfile, "\end{stlog}")
	}
}

void unify(string vector lines, real scalar bot, real scalar top, string scalar ws) {
 // unify multiple blank lines in output <>
	real scalar isws, inws, i, j	
	j = bot - 1
	inws = 1
	for(i = bot; i <= top; i++) {
		isws = ustrtrim(lines[i]) == ws
		if(!isws || (isws && !inws)) {
			j++
			if(j < i) lines[j] = lines[i]
			inws = isws
		}
	}
	top = j
}
void injectCss(real scalar outfile) {
 // inject markstat.css wrapping in style tags
	string scalar path
	string vector css
	path = findfile("markstat.css")
	if(path == "") return
	css = cat(path)
	fput(outfile, "<style>")
	fputvec(outfile, css)
	fput(outfile, "</style>")
}
string vector htmlEncode(string vector lines, real scalar bot, real scalar top) {
 // encode & and < as entities
	real scalar j
	string vector encoded, fixamp
	encoded = J(1, top - bot + 1, "")
	for(j = bot; j <= top; j++) {
		fixamp = usubinstr(lines[j], "&", "&amp;", .)
		encoded[j - bot + 1] = usubinstr(fixamp, "<", "&lt;", .)
	}
	return(encoded)
}

real scalar hasInlineCode(string scalar line, string scalar match, string scalar prefix) {
 // non-greedy regex for inline code
	real scalar r, pos, ns, i
	real vector stack
	string scalar pattern, shorter, here

	// greedy match
	pattern = "`([s|m]) (.+)`"
	r = ustrregexm(line, pattern)
	if(r <= 0) return(0)
	prefix = ustrregexs(1)
	match  = ustrregexs(2)
	pos = ustrpos(match, "`")
	if(pos < 1) return(1)
	
	// less greedy
	r = ustrregexm(match, "`[s|m] ")
	if(r > 0) {
		pos = ustrpos(match, ustrregexs(0))
		shorter = "`" + prefix + " " + usubstr(match, 1, pos - 1)
		r = ustrregexm(shorter, pattern)
		if (r < 1) return(0)
		match = ustrregexs(2)
		pos = ustrpos(match, "`")
		if(pos < 1) return(1)
	}
	
	// allow pairs
	stack = J(24, 1, 0)
	ns = 0
	for(i = 1; i <= ustrlen(match); i++) {
		here = usubstr(match, i, 1)
		if(here == "`") {				
			stack[++ns] = i // push
		}
		else if (here == "'" && ns > 0) {
			ns-- // pop
		}
	}
	if(ns > 0) {
		pos = stack[1]
		match = substr(match, 1, pos - 1)
	}
	return(1)		
}

void tag2tex(string scalar line) {
 // translate code,  underline and italics tags to LaTeX
	string vector tags, tex
	real scalar i
	tags = "<code>", "</code>", "<u>", "</u>", "<i>", "</i>"
	tex  = "\texttt{", "}", "\underline{", "}", "\emph{", "}"
	for(i = 1; i <= 6; i++) {
		if(ustrpos(line, tags[i]) < 1) continue
		line = usubinstr(line, tags[i], tex[i], .)
	}
}
// ---------------------------------------------------------------------------
//  Utilities
// -----------
	
real scalar startsWith(string scalar line, string scalar stem) {
 // check if beginning of string matches a stem
	real scalar m, r
	m = ustrlen(stem)
	r = usubstr(line, 1, m) == stem
	return(r)
}	
string scalar addSuffix(string scalar name, string scalar suffix) {
 // add file extension if not there
	return(pathsuffix(name) == "" ? name + suffix : name)
}
real scalar fopenwr(string scalar filename) {
 // file open write with replace
	if(fileexists(filename)) unlink(filename)
	return(fopen(filename, "w"))
}
void fputvec(real scalar fh, string vector lines, | real scalar bot, real scalar top) {
 // write string array to file
	real scalar i
	if (args() < 4) { 
		bot = 1; 
		top = length(lines);
	}
	for(i = bot; i <= top; i++) {
		fput(fh, lines[i])
	}
}
void splitPath(string scalar filename) {
 // returns folder, file and suffix in locals, sets isurl 
	pathsplit(filename, path = ., file = .)
	if(pathisurl(path)) {
		st_local("isurl", "isurl")
	}
	st_local("folder", path)
	st_local("file", pathrmsuffix(file))
	st_local("suffix", pathsuffix(file))	
}	
	
end
exit
