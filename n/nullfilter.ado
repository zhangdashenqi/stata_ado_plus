*  nullfilter:  Generic example of a file filter that copies one file to another.
*
*  John Eng, M.D.
*! version 1.0.1  November 2006
*
*  Version history:
*  1.0.0   Sep 2005   Initial version
*  1.0.1   Nov 2006   Added comments

program nullfilter
	version 8.0
	args inputFileName outputFileName dummy

	** Check for correct number of arguments
	if (("`inputFileName'" == "") | ("`outputFileName'" == "") | ("`dummy'" != "")) error 198

	** Open input and output files
	tempname inputFileHandle
	tempname outputFileHandle
	file open `inputFileHandle' using "`inputFileName'", read text
	file open `outputFileHandle' using "`outputFileName'", write text

	** Null file filter
	local lineCount = 0
	file read `inputFileHandle' textLine
	while (r(eof) == 0) {
		* File filter code goes here
		file write `outputFileHandle' `"`macval(textLine)'"' _n
		local lineCount = `lineCount' + 1
		file read `inputFileHandle' textLine
		}

	** Clean up
	file close `inputFileHandle'
	file close `outputFileHandle'
	display as text "Copied `lineCount' lines."
end
