*  matchfilter:  Example of a file filter than processes a complex text input
*  file into a form that can be read by Stata.
*
*  John Eng, M.D.
*! version 1.0.0  November 2006
*
*  The prototype for this program was nullfilter.ado.
*
*  Version history:
*  1.0.0   Nov 2006   Initial version

program matchfilter
	version 8.0
	args inputFileName outputFileName dummy

	** Check for correct number of arguments
	if (("`inputFileName'" == "") | ("`outputFileName'" == "") | ("`dummy'" != "")) error 198

	** Open input and output files
	tempname inputFileHandle
	tempname outputFileHandle
	file open `inputFileHandle' using "`inputFileName'", read text
	file open `outputFileHandle' using "`outputFileName'", write text

	** Copy matching lines
	local lineCount = 0
	file read `inputFileHandle' textLine
	while (r(eof) == 0) {
		if ((index(`"`macval(textLine)'"', " - User - Create") > 0) | (index(`"`macval(textLine)'"', " - Resolved") > 0) | (index(`"`macval(textLine)'"', "Priority:  ") == 1)) {
			file write `outputFileHandle' `"`macval(textLine)'"' _n
			local lineCount = `lineCount' + 1
			}
		file read `inputFileHandle' textLine
		}

	** Clean up
	file close `inputFileHandle'
	file close `outputFileHandle'
	display as text "Copied `lineCount' lines."
end
