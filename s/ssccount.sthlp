{smcl}
{* *! version 0.3  07nov2014}{...}
{hi:help ssccount}{right: ({browse "http://www.stata-journal.com/article.html?article=dm0086":SJ16-1: dm0086})}
{vieweralsosee "[G-2] graph twoway line" "help line"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] ssc hot" "help ssc"}{...}
{viewerjumpto "Syntax" "ssccount##syntax"}{...}
{viewerjumpto "Description" "ssccount##description"}{...}
{viewerjumpto "Options" "ssccount##options"}{...}
{viewerjumpto "Examples" "ssccount##examples"}{...}
{hline}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{hi:ssccount} {hline 2}}Download Statistical Software Components hits over time for user-written packages{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}{cmd:ssccount} [{cmd:,} {it:options}]

{synoptset 26}{...}
{synopthdr}
{synoptline}
{synopt :{opt fr:om(month)}}specify first month to download data for, in {cmd:%tm} format; default is {cmd:from(2007m7)}{p_end}
{synopt :{opt to(month)}}specify last month to download data for, in {cmd:%tm} format; default is the current month minus three months{p_end}
{synopt :{opt au:thor(author_name)}}specify name of author whose packages are of interest, if applicable{p_end}
{synopt :{opt clear}}specify that existing data be cleared from memory{p_end}
{synopt :{opt f:illin(#)}}specify the {it:#} to fill in for missing months; default is to not use {helpb fillin}{p_end}
{synopt :{opt gr:aph}}specify that a graph be drawn of results{p_end}
{synopt :{opt pack:age(pkg_name)}}specify exact name of the package of interest, if applicable{p_end}
{synopt :{cmdab:sav:ing(}{it:filename}{cmd:, replace)}}specify that the downloaded data be saved as {it:filename}{cmd:.dta}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
For authors of user-written packages released on the Statistical Software
Components (SSC) archive, {cmd:ssccount} is a command to track monthly hits.
It uses the same datasets as {cmd:ssc hot} and appends them over time.
Datasets are downloaded for the specified date range and loaded into memory.
If {opt author()} and {opt package()} are not specified, {cmd:ssccount} will
download data for all authors and packages for the specified months.  Users
can then process these data as they wish.

{pstd}
Records available for this command in the SSC archive begin in July 2007 (that
is, {cmd:2007m7}), and {cmd:ssccount} will return an error if dates before
this are specified.  Likewise, if the dates specified are in the future,
{cmd:ssccount} will obviously not return any results.  There also tends to be
a lag on the release of the datasets of about two months.  Specifying months
that are not yet available will display an error, but {cmd:ssccount} will load
into memory (and save, if specified) the datasets it was able to download, if
any.


{marker options}{...}
{title:Options}

{phang}
{opt from(month)} specifies the earliest month of data to download.  This must
be entered in Stata's {cmd:%tm} format (for example, January 2011 is specified
by {cmd:2011m1}).  Specifying a month before July 2007 ({cmd:2007m7}) will
return an error because this is before records began.  The default is
{cmd:from(2007m7)}.

{phang}
{opt to(month)} specifies the latest month of data to download.  As with
{cmd:from()}, this must be entered in Stata's {cmd:%tm} format (for example,
January 2011 is specified by {cmd:2011m1}).  Specifying a month before July
2007 ({cmd:2007m7}) will return an error.  The default is the current month
minus three months, which helps users avoid trying to download datasets that
do not yet exist, though one further month may be available.  (Users can check
the latest available month by typing {cmd:ssc hot}.)

{phang}
{opt author(author_name)} specifies the name of the author whose packages are
of interest.  The names on SSC packages can be inconsistent.  You do not have
to get it exactly right, as long as the name used contains what you specify in
{cmd:author()}.  The option is not case sensitive, so specifying
{cmd:author(bloggs)} is the same as {cmd:author(BLOGGS)} or anything in
between, like {cmd:author(BlOgGs)}.

{phang}
{opt clear} specifies that the data in memory will be cleared.  If
{cmd:saving()} or {cmd:clear} is not specified and you have data in memory,
{cmd:ssccount} will exit with an error.

{phang}
{opt fillin(#)} calls the {cmd:fillin} command (see {manhelp fillin D}).
This option is used with plots when more than one author or package
has been specified.  It creates missing months to form a rectangular dataset
and fills each one with {it:#} hits.  Filling as missing ({cmd:.}) is
allowed.  The default is to not fill anything.

{phang}
{cmd:graph} draws a simple graph of the month-by-month hits using {cmd:twoway}
{cmd:line} and overlays a smoothed trend using {cmd:lowess}.  If the data
contain multiple authors or packages, the graphs will be drawn by author and
package.

{phang}
{opt package(pkg_name)} specifies the name of the package of interest.  This
may be useful if an author has written multiple packages but a user is
interested in one in particular.  It can also be helpful if the author's name
is a substring of one or more other authors' names.

{phang}
{cmd:saving(}{it:filename}{cmd:, replace)} specifies the downloaded data be
saved as {it:filename}{cmd:.dta}.


{marker examples}{...}
{title:Examples}

{pstd}
Download all hits for 2008{p_end}
{phang2}
{cmd:. ssccount, from(2008m1) to(2008m12) saving(2008data)}

{pstd}
Download and plot hits for the {cmd:ice} package by Patrick Royston from June
2007 to September 2014{p_end}
{phang2}
{cmd:. ssccount, from(2007m7) to(2014m9) author(Royston) graph package(ice) saving(icehits)}

{pstd}
Download and plot hits for the {cmd:psmatch2} package from January 2015 to May
2015{p_end}
{phang2}
{cmd:. ssccount, from(2015m1) to(2015m5) graph package(psmatch2) saving(psmatch2_2015)}


{title:Acknowledgements}

{pstd}
We are grateful to Patrick Royston and Roger Newson for helpful advice on the
command.


{title:Authors}

{pstd}Tim Morris{break}
Hub for Trials Methodology Research{break} 
MRC Clinical Trials Unit{break}
University College London{break}
and{break} 
Department of Medical Statistics{break} 
London School of Hygiene and Tropical Medicine{break} 
London, UK{break}
{browse "mailto:tim.morris@ucl.ac.uk":tim.morris@ucl.ac.uk}{break}
Twitter: {browse "https://twitter.com/tmorris_mrc":@tmorris_mrc}

{pstd}Babak Choodari-Oskooei{break}
Hub for Trials Methodology Research{break}
MRC Clinical Trials Unit{break}
University College London{break}
London, UK{break}
{browse "mailto:b.choodari-oskooei@ucl.ac.uk":b.choodari-oskooei@ucl.ac.uk}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 16, number 1: {browse "http://www.stata-journal.com/article.html?article=dm0086":dm0086}

{p 7 14 2}Help:  {manhelp line G-2:graph twoway line}, {manhelp ssc R:ssc hot}{p_end}
