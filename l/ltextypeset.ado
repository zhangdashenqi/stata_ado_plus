*! version 0.1 Juli 8, 2009 @ 10:39:31 UK
*! Subprogram for ltex
program ltextypeset
version 10.0

syntax anything 

local anything = subinstr(`anything',".tex","",1)

if "$MYPDFVIEWER" == "" global MYPDFVIEWER acroread

// TeX-File complete?
tempname fh
local full 0
local i 1
file open `fh' using "`anything'.tex", read
while `full'==0 & `i' < 30 {
	file read `fh' line
	if strpos("`line'","documentclass") > 0 local full 1
	local i = `i'+1
}
file close `fh'


// Complete TeX-File and TeX
if !`full' {
	tempname main
	file open `main' using _ltex.tex, write replace
	
	file write `main' ///
	  _n `"\documentclass{article}"'  ///
	  _n `"\begin{document}"' _n `"\input{`anything'}"' _n `"\end{document}"'
	file close `main'

	!pdflatex _ltex
	winexec $MYPDFVIEWER _ltex.pdf
	erase _ltex.tex
}

// LaTeX an already complet TeX-File
else if `full' {
	!pdflatex `anything'
	winexec $MYPDFVIEWER `anything'.pdf
}

end
exit

Author: Ulrich Kohler
	Tel +49 (0)30 25491 361
	Fax +49 (0)30 25491 360
	Email kohler@wzb.eu



