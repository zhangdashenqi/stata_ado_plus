{smcl}
{* *! version 1.00  31aug2010}{...}
{cmd:help greek_in_word}{right: ({browse "http://www.stata-journal.com/article.html?article=sg97_5":SJ12-4: sg97_5})}
{hline}

{title:Title}

{p2colset 5 22 24 2}{...}
{p2col :{hi:greek_in_word} {hline 2}}Greek and other Unicode characters in
Microsoft Word Rich Text Format documents{p_end}
{p2colreset}{...}


{title:Description}

{pstd}
In Microsoft Word Rich Text Format (RTF) files, Greek letters and other
Unicode characters can be included in the text by using a four-digit
Unicode code preceded by {cmd:\u} and followed by {cmd:?}.  Complete
Unicode code tables are available at
{browse "http://www.unicode.org/charts":www.unicode.org/charts}.  For
use in Microsoft Word RTF files, the hexadecimal codes in the tables
must be converted to decimal numbers.

{pstd}
For example, for the Greek lowercase character alpha, the hexadecimal
Unicode code is 03B1, which is equivalent to the decimal 945; we make
945 into a four-digit number by putting a "0" at the front, so the
appropriate RTF code would be {cmd:\u0945?}.

{pstd}
The Unicode characters displayed in the Microsoft Word file are limited
only by which Unicode characters are included in the font being used.
For fonts like Times New Roman and Arial, a very wide range of
characters are included.

{pstd}
Below are Unicode decimal codes for lowercase and uppercase Greek
letters.

{marker lower}{...}
{phang}
{bf:Lowercase Greek letters}

{p2colset 10 25 27 45}{...}
{p2col:Greek letter}RTF code{p_end}
{p2line}
{p2col:alpha}{cmd:\u0945?}{p_end}
{p2col:beta}{cmd:\u0946?}{p_end}
{p2col:gamma}{cmd:\u0947?}{p_end}
{p2col:delta}{cmd:\u0948?}{p_end}
{p2col:epsilon}{cmd:\u0949?}{p_end}
{p2col:zeta}{cmd:\u0950?}{p_end}
{p2col:eta}{cmd:\u0951?}{p_end}
{p2col:theta}{cmd:\u0952?}{p_end}
{p2col:iota}{cmd:\u0953?}{p_end}
{p2col:kappa}{cmd:\u0954?}{p_end}
{p2col:lambda}{cmd:\u0955?}{p_end}
{p2col:mu}{cmd:\u0956?}{p_end}
{p2col:nu}{cmd:\u0957?}{p_end}
{p2col:xi}{cmd:\u0958?}{p_end}
{p2col:omicron}{cmd:\u0959?}{p_end}
{p2col:pi}{cmd:\u0960?}{p_end}
{p2col:rho}{cmd:\u0961?}{p_end}
{p2col:sigma}{cmd:\u0963?}{p_end}
{p2col:tau}{cmd:\u0964?}{p_end}
{p2col:upsilon}{cmd:\u0965?}{p_end}
{p2col:phi}{cmd:\u0966?}{p_end}
{p2col:chi}{cmd:\u0967?}{p_end}
{p2col:psi}{cmd:\u0968?}{p_end}
{p2col:omega}{cmd:\u0969?}{p_end}
{p2line}


{marker upper}{...}
{phang}
{bf:Uppercase Greek letters}{p_end}

{p2colset 10 25 27 45}{...}
{p2col:Greek letter}RTF code{p_end}
{p2line}
{p2col:Alpha}{cmd:\u0913?}{p_end}
{p2col:Beta}{cmd:\u0914?}{p_end}
{p2col:Gamma}{cmd:\u0915?}{p_end}
{p2col:Delta}{cmd:\u0916?}{p_end}
{p2col:Epsilon}{cmd:\u0917?}{p_end}
{p2col:Zeta}{cmd:\u0918?}{p_end}
{p2col:Eta}{cmd:\u0919?}{p_end}
{p2col:Theta}{cmd:\u0920?}{p_end}
{p2col:Iota}{cmd:\u0921?}{p_end}
{p2col:Kappa}{cmd:\u0922?}{p_end}
{p2col:Lambda}{cmd:\u0923?}{p_end}
{p2col:Mu}{cmd:\u0924?}{p_end}
{p2col:Nu}{cmd:\u0925?}{p_end}
{p2col:Xi}{cmd:\u0926?}{p_end}
{p2col:Omicron}{cmd:\u0927?}{p_end}
{p2col:Pi}{cmd:\u0928?}{p_end}
{p2col:Rho}{cmd:\u0929?}{p_end}
{p2col:Sigma}{cmd:\u0931?}{p_end}
{p2col:Tau}{cmd:\u0932?}{p_end}
{p2col:Upsilon}{cmd:\u0933?}{p_end}
{p2col:Phi}{cmd:\u0934?}{p_end}
{p2col:Chi}{cmd:\u0935?}{p_end}
{p2col:Psi}{cmd:\u0936?}{p_end}
{p2col:Omega}{cmd:\u0937?}{p_end}
{p2line}


{title:Author}

{pstd}John Luke Gallup{p_end}
{pstd}Portland State University{p_end}
{pstd}Portland, OR{p_end}
{pstd}jlgallup@pdx.edu{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 12, number 4: {browse "http://www.stata-journal.com/article.html?article=sg97_5":sg97_5},{break}
                    {it:Stata Journal}, volume 12, number 1: {browse "http://www.stata-journal.com/article.html?article=sg97_4":sg97_4},{break}
                    {it:Stata Technical Bulletin} 59: {browse "http://www.stata.com/products/stb/journals/stb59.pdf":sg97.3},{break}
                    {it:Stata Technical Bulletin} 58: {browse "http://www.stata.com/products/stb/journals/stb58.pdf":sg97.2},{break}
                    {it:Stata Technical Bulletin} 49: {browse "http://www.stata.com/products/stb/journals/stb49.pdf":sg97.1},{break}
                    {it:Stata Technical Bulletin} 46: {browse "http://www.stata.com/products/stb/journals/stb46.pdf":sg97}
{p_end}
