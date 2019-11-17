{smcl}
{* *! Help file for linewrap.ado version 1.0 written by Mead Over (mover@cgdev.org) 7Sep2015}{...}
{vieweralsosee "[P] display" "mansection P display"}{...}
{vieweralsosee "[P] tokenize" "mansection P tokenize"}{...}
{vieweralsosee "[R] display" "mansection R display"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "help display" "help display"}{...}
{vieweralsosee "help tokenize" "help tokenize"}{...}
{vieweralsosee "help return" "help return"}{...}
{viewerjumpto "Syntax" "linewrap##syntax"}{...}
{viewerjumpto "Options" "linewrap##options"}{...}
{viewerjumpto "Description" "linewrap##description"}{...}
{viewerjumpto "Examples" "linewrap##examples"}{...}
{viewerjumpto "Author" "linewrap##author"}{...}
{title:Title}

{p2colset 5 22 26 2}{...}
{p2col :{cmd:linewrap} {hline 2}}Split a long string into shorter strings 
and, optionally, display them{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:linewrap}
{cmd:,}
{opt lo:ngstring(string)}
[{it:options}]{p_end}

{marker options}{...}
{title:Options}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Lines of equal length (Default)}
{synopt:{opt max:length(integer)}}Each line will be either exactly or 
approximately the same length, with the length controlled by this option.  
If this option is omitted the default maximum line length will be about 80 characters.{p_end}
{synopt:{opt s:quare}}Each line before the last is chopped at exactly 
{opt max:length(integer)} characters.  If this option is omitted
the default behavior is to wrap the long string at spaces, in order to avoid
splitting individual words.{p_end}

{syntab:A line for each word}
{synopt:{opt w:ords}}This option is an alternative to the default 
{opt max:length(integer)} option. With {opt w:ords} specified,
:cmd:linewrap} chops the long string into Stata "word", which 
are defined by the spaces in the input string.  Unlike the programmer's 
command {help tokenize}, {cmd:linewrap} only uses blanks to define words, 
not other user specified characters such as commas or semi-colons.
Multiple spaces are treated as a single space. {p_end}

{syntab:Display the wrapped text}
{synopt:{opt d:isplay}}Display the wrapped lines in the results window 
and print them in the output log.  If this option is omitted, {cmd:linewrap}
only returns the separate lines in the {help return:r()} space{p_end}
{synopt:{opt li:nenumbers}}Number the displayed lines.  Only relevant if 
option {opt d:isplay} is also specified{p_end}
{synopt:{opt t:itle(string)}}Optionally display a title before 
displaying any other output{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:linewrap} chops a long string into a set of shorter "lines" 
and returns them in Stata's {help return:r()} space in macros named
{opt r(line1)}, {opt r(line2)}, {opt r(line3)}, ... {opt r(line1n)},
where {it:n}, the total number of lines, is returned as macro
{opt r(nlines)}. Optionally, with the addition of the {opt d:isplay} option,
{cmd:linewrap} also displays a list of 
the character strings into which it has chopped the long string.

{pstd}
Without options, {cmd:linewrap} wraps the {opt lo:ngstring(string)}
into lines of approximately 80 characters in length, breaking each line
at the last blank space before the 80'th character.  Character strings longer
than 80 characters (or longer than the user specified {opt max:length(integer)})
are presented in their entirety as a single "line". By adding the {opt s:quare} option, 
the user can require the lines to break exactly at {opt max:length(integer)}
characters, regardless of blank space.
 
{pstd}
The {opt w:ords} option specifies that the lines into which the long character
string is apportioned are "words", defined by the blanks. Each line containing 
a single word can be of any length.

{marker examples}{...}
{title:Examples}

{phang}{cmd:. linewrap, longstr(Four score and seven years ago our fathers brought} 
{cmd:forth on this continent, a new nation, conceived in Liberty, and dedicated to} 
{cmd:the proposition that all men are created equal.}  
{cmd:The quick red fox jumped over the lazy dog.)} 
{cmd:title(Example with default maxlength of 80) display linenumbers } {p_end}

{phang}{it:Produces output:} {p_end}

Example with default maxlength of 80

             1         2         3         4         5         6         7         8
    12345678901234567890123456789012345678901234567890123456789012345678901234567890

1   Four score and seven years ago our fathers brought forth on this continent, a
2   new nation, conceived in Liberty, and dedicated to the proposition that all
3   men are created equal. The quick red fox jumped over the lazy dog.

{phang}{cmd:. return list} {p_end}

{phang}{it:Produces output:} {p_end}

macros:
             r(nlines) : "3"
              r(line3) : "men are created equal. The quick red fox jumped over the laz.."
              r(line2) : "new nation, conceived in Liberty, and dedicated to the propo.."
              r(line1) : "Four score and seven years ago our fathers brought forth on .."


{marker author}{...}
{title:Authors}

{phang}{browse "http://www.cgdev.org/expert/mead-over/":Mead Over} at:
Email: {browse "mailto:mover@cgdev.org":MOver@CGDev.Org} if you observe any
problems. {p_end}

{* Version history of this help file}
{* Version 1.0 6Nov2015}

