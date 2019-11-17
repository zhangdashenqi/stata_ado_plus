{smcl}
{* *! version 1.0.1  14dec2013}{...}
{vieweralsosee "[D] export" "help export"}{...}
{vieweralsosee "[D] import" "help import"}{...}
{vieweralsosee "[P] postfile" "help postfile"}{...}
{vieweralsosee "[P] return" "help return"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[M-5] xl()" "help mf_xl"}{...}
{viewerjumpto "Syntax" "tab2xl##syntax"}{...}
{title:Title}

{p2colset 5 13 23 2}{...}
{p2col :{cmd:tab2xl}} {hline 2} Export tabulate table to an Excel file{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 4 8 2}
{title:Basic syntax}

{p 8 32 2}
{cmd:tab2xl} {it:{help varlist:varname}}
{cmd:using} {it:{help filename}}
{cmd:,} {cmd:col(}{it:integer}{cmd:)} {cmd:row(}{it:integer}{cmd:)} [{it:{help putexcel##options_tbl:options}}]


{marker options_tbl}{...}
{synoptset 30}{...}
{synopthdr}
{synoptline}
{synopt :{opt replace}}overwrite Excel file{p_end}
{synopt :{cmdab:sh:eet("}{it:sheetname}{cmd:"} [{cmd:, replace}]{cmd:)}}write to Excel worksheet {it:sheetname}{p_end}
{synopt :{cmd:col(}{it:integer}{cmd:)}}specify the Excel column number to start writing the {help tabulate:tabulate} table to{p_end}
{synopt :{cmd:row(}{it:integer}{cmd:)}}specify the Excel row number to start writing the {help tabulate:tabulate} table to{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:tab2xl} was written for the Stata blog.  You can view the blog at {browse "http://blog.stata.com"}
{p_end}
