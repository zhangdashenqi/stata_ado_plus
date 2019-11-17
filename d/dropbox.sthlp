{smcl}
{cmd:help dropbox}{right: ({browse "http://www.stata-journal.com/article.html?article=pr0058":SJ14-3: pr0058})}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col:{cmd:dropbox} {hline 2}}Command to find Dropbox directory{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 15 2}
{cmd:dropbox}
[{cmd:,} {cmd:nocd}] 


{title:Description}

{pstd}
{cmd:dropbox} searches for a user's main dropbox directory and
switches to that directory.  From there, users can use relative paths to move
between their shared folders.


{title:Option}

{phang}
{cmd:nocd} tells Stata not to change to the dropbox directory.


{title:Stored results}

{pstd}
The program stores the dropbox directory in {cmd:r(db)}.


{title:Authors} 

{pstd}Raymond Hicks{p_end}
{pstd}Woodrow Wilson School{p_end}
{pstd}Niehaus Center for Globalization and Governance{p_end}
{pstd}Princeton University{p_end}
{pstd}Princeton, NJ{p_end}
{pstd}rhicks@princeton.edu{p_end}
  
{pstd}{browse "http://scholar.harvard.edu/dtingley":Dustin Tingley}{p_end}
{pstd}Government Department{p_end}
{pstd}Harvard University{p_end}
{pstd}Boston, MA{p_end}


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 14, number 3: {browse "http://www.stata-journal.com/article.html?article=pr0058":pr0058}{p_end}
