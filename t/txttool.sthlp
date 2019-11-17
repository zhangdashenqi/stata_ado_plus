{smcl}
{cmd:help txttool}{right: ({browse "http://www.stata-journal.com/article.html?article=dm0077":SJ14-4: dm0077})}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col:{hi:txttool} {hline 2}}Utilities for text analysis{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{cmd:txttool} {varname} {ifin}{cmd:,}
{{opth gen:erate(newvar)}|{cmd:replace}}
[{cmd:stem}
{cmdab:stop:words(}{it:filename}{cmd:)}
{cmdab:sub:words(}{it:filename}{cmd:)}
{cmdab:bag:words}
{cmdab:pre:fix(}{it:string}{cmd:)}
{cmd:noclean}
{cmdab:noout:put}]

{pstd}
{it:varname} is the string variable containing the text to be processed.{p_end}


{title:Description}

{pstd}
{cmd:txttool} provides a set of tools for managing and analyzing
free-form text.  The command integrates several built-in Stata functions
with new text capabilities, including a utility to create a bag-of-words
representation of text and an implementation of Porter's (1980) word-stemming
algorithm.


{title:Options}

{phang}
{opth generate(newvar)} creates a new string variable, {it:newvar},
containing the processed text of {it:varname}.  The {it:newvar} will be
a copy of {it:varname} that has been stemmed, has had the stop words
removed, has had words substituted, or has been cleaned, depending on
the other options specified.  Either {opt generate()} or {opt replace} is
required.

{phang}
{opt replace} replaces the original text in {it:varname} with text that has
been stemmed, has had the stop words removed, has had words substituted, or has
been cleaned, depending on the other options specified.  Either
{cmd:generate()} or {opt replace} is required.

{phang}
{opt stem} calls the Porter stemmer implementation to stem all the words in
{it:varname}.

{phang}
{opt stopwords(filename)} indicates that the program should remove all
instances of words contained in {it:filename}.  The {it:filename} is a list of
words in a text file.  Although a list of frequently used English words is
supplied with {cmd:txttool}, users can use different lists of stop words in
different applications by specifying different filenames.  Stop-word lists
without punctuation are recommended.

{phang}
{opt subwords(filename)} indicates that the program should substitute
instances of words in {it:filename} with another word in {it:filename}.  The
filename is a tab-delimited text file, where the first column is the word to
be replaced and the second column is the substitute text.  Users can use
different lists of words to substitute in different applications by specifying
different filenames.  Subword lists without punctuation are recommended.

{phang}
{opt bagwords} tells {cmd:txttool} to create a bag-of-words representation of
the text in {it:varname}.  The bag-of-words representation consists of new
variables, one for each unique word in {it:varname}, with the count of the
occurrences of each word.  The new variables are named with the convention
{it:prefix_word}, where {it:prefix} is optionally supplied by the user, and
{it:word} is the unique word in the text.  The options {cmd:generate()} and
{cmd:bagwords} can be used together to represent the processed text as one
column with word counts.

{phang}
{opt prefix(string)} supplies a prefix for the variables created in
{cmd:bagwords}.  The default is {cmd:prefix(w_)}.  Supplying a prefix will
automatically invoke the {opt bagwords} option.  Note that {cmd:txttool} does
not know what variables will be created before processing the text, so it
cannot confirm the absence of variables already named with the specified
prefix.  Errors will therefore result if the chosen prefix matches an existing
variable.

{phang}
{opt noclean} specifies that the program should not remove punctuation, extra
white spaces, and special characters from {it:varname}.  By default,
{cmd:txttool} will clean and lowercase {it:varname}.  The {cmd:noclean} option
is not allowed with {cmd:bagwords}.  In addition, because the Porter stemmer
does not stem punctuation and because the stop-words and subwords lists should
not include punctuation, {cmd:noclean} should be used with caution.

{phang}
{cmd:nooutput} suppresses the default output.  By default, {cmd:txttool}
reports the total number of words and the count of unique words before and
after processing, as well as the time elapsed during processing.  The
{cmd:nooutput} option suppresses this output, which can save some time with
large processing tasks.


{title:Remarks}

{pstd}
{cmd:txttool} options are processed in the following order: {cmd:noclean},
{cmd:subwords()}, {cmd:stopwords()}, {cmd:stem}, {cmd:generate()} or
{cmd:replace}, and, finally, {cmd:bagwords}.

{pstd}
By default, {cmd:txttool} will lowercase {it:varname} and clean the text by
removing all characters except white space (American standard code for
information interchange [ASCII] code 32), numerals (ASCII codes 48-57), and
letters (ASCII codes 97-122).  To preserve any other characters, specify
{opt noclean}.  Note that the Porter stemmer stems only English words without
punctuation and may not function as expected with the {opt noclean} option.
Stata does not allow any other characters to appear in variable names, so
{cmd:bagwords} is not allowed with {opt noclean}.


{title:Examples}

{phang}{cmd:. txtttol(exampletext), replace}

{phang}{cmd:. txtttol(exampletext), generate(newtext) noclean}

{phang}{cmd:. txtttol(exampletext), generate(newtext) stem subwords("C:\sublist.txt") stopwords("C:\stoplist.txt")}

{phang}{cmd:. txtttol(exampletext), generate(newtext) stem bagwords prefix("w_")}


{title:Reference}

{phang}Porter, M. F. 1980. An algorithm for suffix stripping. 
{it:Program: Electronic library and information systems} 14: 130-137.


{title:Author}

{pstd}Unislawa Williams{p_end}
{pstd}Spelman College{p_end}
{pstd}Atlanta, GA{p_end}
{pstd}{browse "mailto:uwilliams@spelman.edu":uwilliams@spelman.edu}{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 14, number 4: {browse "http://www.stata-journal.com/article.html?article=dm0077":dm0077}

{p 7 14 2}Help:  {helpb replace}, {helpb generate},
{helpb regexm()}{p_end}
