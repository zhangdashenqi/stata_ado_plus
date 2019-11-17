{smcl}
{* version 1.1 of this help file 5Jun2014}{...}
{hline}
help for {hi:lookand}{right:{hi:Version 1.1, 4Apr2012}}
{hline}

{title:Search for variables whose names or labels contain all the listed character strings}

{p 8 17 2}
{cmdab:lookand} {it:charstring}
[{it:charstring} {it:charstring} {it:charstring}]
[
{cmd:,}
    {cmdab:f:ullnames}
    {cmdab:si:mple}
    {cmdab:s:hort}
    {cmdab:su:m}
    {cmdab:d:etail}
]

{title:Description}

{p 4 4 2}
{cmd:lookand} is an extension of STATA's {help lookfor} command.   
Stata's program {help lookfor} finds the variables in memory that
contain {it:any} of the user-specified list of character strings.
This program instead lists variables that contain
{it:all} the character strings.  

{p 4 4 2}
Thus, if the list of variables containing 
a given character string is defined as a mathematical "set,"
think of Stata's {help lookfor} command as identifying and listing 
the variables in the "union" of 
the sets associated with each user-specified character string. 
This program {cmd:lookand} on the other hand identifies and lists the
variables that constitute the "intersection" of these sets.

{p 4 4 2}
{cmd:lookand} uses Stata's {help describe} command to list the
variables that fit the user's criteria.  
Optionally, {cmd:lookand} will execute the {help describe} command
with either the {cmd:fullnames} or the {cmd:short} option.

{p 4 4 2}
Optionally {cmd:lookand} will also {help summarize} the selected variables,
with or without the {cmd:detail} option.

{p 4 4 2}
This command saves in {cmd:r(}{it:varlist}{cmd:)} a list of the full variables names 
it has identified as fulfilling the search conditions.

{title:Options}

{p 4 4 2}
See the above description.

{title:Author}

{p 4 8 20} 
{browse "http://www.cgdev.org/content/experts/detail/10007/":Mead Over},
Center for Global Development, Washington, DC 20036 USA. Email:
{browse "mailto:mover@cgdev.org":MOver@CGDev.Org} if you observe any
problems. 

{title:References} 

{p 4 8 2} {help lookfor}, {help describe}, {help summarize}  


