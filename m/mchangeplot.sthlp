{smcl}
{* 2014-08-06 scott long & jeremy freese}{...}
{title:Title}

{p2colset 5 20 20 2}{...}
{p2col:{cmd:mchangeplot} {hline 2}}Plots of marginal effects for models with
nominal or ordinal outcomes{p_end}
{p2colreset}{...}

{title:General syntax}

{p 6 18 2}
{cmd:mchangeplot} [ {it:varlist} ] [ {cmd:,} {it:options} ]
{p_end}

{p 4 4 2}
where {it:varlist} contains variables from the regression model for which
marginal effects were computed using {help mchange}. If no variables
are named, all variables are graphed. Effects from models such as
{cmd:mlogit}, {cmd:ologit}, {cmd:oprobit}, and {cmd:slogit} can be plotted.
To plot odds ratios along with discrete changes for {cmd:mlogit}, see {help mlogitplot}.
{p_end}


{title:Overview}

{pstd}
{cmd:mchange} computes marginal effects for regression models with
ordinal and nominal outcomes. In the graphs created by {cmd:mchangeplot}, variables are arranged vertically with
marginal effects plotted on the horizonal axis, with each outcome
represented by a marker. Statistical significance of effects can be
indicated and many options are available to customize the graph.
{p_end}


{title:Table of contents}

    {help mchangeplot##amount:Amount of change}
    {help mchangeplot##outcomes:Symbols for outcome categories}
    {help mchangeplot##axes:Axes and plot region}
    {help mchangeplot##labels:Labels and notes}
    {help mchangeplot##tweaking:Tweaking defaults}

{title:Options}
{marker amount}
{dlgtab:Amount of change}

{pstd}
Marginal effects can be a marginal or instantaneous change or one of
several types of discrete changes. For {helpb fvvarlist:factor variables} specified with
the {cmd:i.} syntax in the model, changes from 0 to 1 are plotted. For non-factor variables
(i.e., those not specified as {bf:i.}{it:varname}), the amount of change can
be selected with the {cmd:amount()} option.
{p_end}
{p2colset 7 24 25 0}
{synopt:{opt am:ount( var1-amount var2-amount ...)}}

{p2colset 10 23 22 12}{...}
{p2col : amount}Description{p_end}
{p2line}
{p2col :{bf:bin}}Binary change from 0 to 1 [0 to 1].{p_end}
{p2col :{bf:marg}}Marginal change [Marginal].{p_end}
{p2col :{bf:one}}Change of one unit [Unit change].{p_end}
{p2col :{bf:range}}Change over a predictor's range [Range change].{p_end}
{p2col :{bf:sd}}Change of a standard deviation [SD change].{p_end}
{p2line}

{pstd}
The default labels are shown in brackets above. You can specify the labels
to use for each type of change with these options. Using the string {opt "_none_"}
will remove the label.
{p_end}
{p2colset 7 24 25 0}
{synopt:{opt binlab:el(string)}}

{synopt:{opt marglab:el(string)}}

{synopt:{opt onelab:el(string)}}

{synopt:{opt rangelab:el(string)}}

{synopt:{opt sdlab:el(string)}}

{marker outcomes}
{dlgtab:Symbols for outcome categories}
{pstd}

{pstd}
Eech outcome category is represented by a marker that can the
first letter of the outcome's value label or the numeric value
of the category.
{p_end}
{p2colset 7 24 25 0}
{synopt:{opt values}}
Represent categories by their numeric value.
By default outcomes are indicated by the first letter of their
value label.

{synopt:{opt sym:bols(catsym1 catsym2 ...)}}
Each category is represented by the symbols specified. For example,
{cmd:sym(A1 A2 A3 A4)} would use A1, A2, etc. as the markers.

{synopt:{opt sig:nificance(level)}}Add * to indicate significance of two-tailed
test that effect is 0 at the given level. Level must be between .01 and .99}

{synopt:{opt mcol:ors(colorstylelist)}}
Specify the colors of the markers. Different colors can be used
for each marker, such as {cmd:mcol(red orange green blue)}. Colors use
Stata's {helpb colorstyle}. The color option {cmd:rainbow} picks colors in
the order of the rainbow.

{synopt:{opt mshade:s}}
Using the single color selected by {cmd:mcolor()}, uses shades of that
color for each symbol. {opt mshadesmin(#)} choses the lightest shade and
is by default .25. Experiment with various numbers to create the shades you want.

{synopt:{opt msiz:efsctor(#)}}
Adjust the size of the markers by this factor.

{marker axes}
{dlgtab:Axis and graph region}
{pstd}

{pstd}
These options control how the x-axes are displayed.
The x-axis contains the scale for the marginal effects.
No options are required but the graph often benefits
by setting the values of the tic marks
with {cmd:min()}, {cmd:max()}, {cmd:gap()} and {cmd:ntics()}.
Setting the aspect ratio with {cmd:aspectratio()} is useful
depending on the number of variables in the
graph and the graph scheme being used.
{p_end}

{pstd}
{ul:X-axis, x-tics and x-lines}
{p_end}
{p2colset 7 24 25 0}
{synopt:{opt max(#)}}
Maximum value on the x-axis.

{synopt:{opt min(#)}}
Minimum value on the x-axis.

{synopt:{opt ntics(#)}}
Number of tic markers on x-axis; alternatively use {cmd:gap()}.

{synopt:{opt gap(#)}}
Numerical gap between tic marks; alternatively use {cmd:ntics()}.
For gap to work as expected, the gap needs to divide evenly into the
range; you might need to specify {cmd:min()} and {cmd:max()}.

{synopt:{opt xline:s(numlist [, line-options])}}
Add vertical lines at specified values. Values and {it:line-options}
are passed to {cmd:graph}'s {cmd:xline()} option.

{p 5 5 2}
{ul:Plot region and labeling}
{p_end}
{p2colset 7 24 25 0}
{synopt:{opt dec:imals(#)}}
Number of decimal digits on the x-axis scale for probabilities.

{synopt:{opt aspect:ratio(#)}}
Set the aspect ratio of the plot region. Ratio is height/width.

{synopt:{opt xsize(#)}}
Set size of x-axis in inches.

{synopt:{opt ysize(#)}}
Set size of y-axis in inches. Changing the ysize will remove "white space" that sometimes
appears at the top and bottom of the graph, especially with small aspect ratios. Changing
the ysize affects the size of the text which can be adjusted by {cmd:scale()}

{synopt:{opt scale(#)}}
Make text, markers, and line widths smaller or larger. See example below.

{marker labels}
{dlgtab:Labels and notes}
{pstd}

{pstd}
You can customize labels on the y-axis and add text to your graph
using standard {cmd:graph} options.
{p_end}

{pstd}
{ul:Variable labeling}
{p_end}
{p2colset 7 24 25 0}
{synopt:{opt varl:abels}}
Use a variable's label rather than its name on the left axis.
{p_end}

{p 5 5 2}
{ul:Adding notes and titles}
{p_end}

{p 6 6 2}
The title text can be a simple text string or use Stata's {help title_options}.
{p_end}
{p2colset 7 24 25 0}
{synopt:{opt ti:tle(text)}}
Add a title at the top using {cmd:graphs}'s {cmd:title()} option.

{synopt:{opt titleb:ottom(text)}}
Replace the default label at the bottom of the graph.

{synopt:{opt sub:title(text)}}
Add a subtitle.

{synopt:{opt note(text)}}
Add a note.

{synopt:{opt cap:tion(text)}}
Add a caption.

{synopt:{opt prov:enance(string)}}
Add a caption to show provenance information; this is a {cmd:caption()} with
convenient options automatically used.

{marker tweaking}
{dlgtab:Adjusting defaults controling the graph}
{pstd}

{pstd}
The defaults that control the graph work in most cases.
Depending on the number of variables or categories along with the
graph scheme you are using you might want to adjust some of the
defaults that control how the graph appears.
{p_end}
{p2colset 7 28 29 0}
{synopt:{opt amountlabelsp:aces(#)}}
The number of spaces at the end of the labels for amount labels at
the y-axis. Negative values can be used to move the labels closer to
the axis.

{synopt:{opt leftmargin(#)}}
When spaces are added to the label, the default left margin might be too
small to show all of the text. You can increase this margin with
the {opt leftmargin(#)} option. This adds a {cmd:graphregion(margin(l+}{it:#}{bf:))}
option to the graph.

{synopt:{opt graph:options(string)}}
Graphing options that are passed through to {cmd:graph}.
{p_end}


{marker examples}{...}
{dlgtab:Examples}

{pstd}
{ul:Example 1: Simple plot of all variables}{p_end}

{phang2}{cmd:. spex mlogit}{p_end}
{phang2}{cmd:. mchange}{p_end}
{phang2}{cmd:. mchangeplot}{p_end}

{pstd}
{ul:Example 2: Change value symbols}{p_end}

{phang2}{cmd:. spex mlogit}{p_end}
{phang2}{cmd:. mchange black income}{p_end}
{phang2}{cmd:. mchangeplot black income, symbols(SDem Dem Ind Rep SRep) msizefactor(0.75)}{p_end}

{pstd}
{ul:Example 3: Adjust axes labels}{p_end}

{phang2}{cmd:. spex mlogit}{p_end}
{phang2}{cmd:. mchange black income}{p_end}
{phang2}{cmd:. mchangeplot black income, min(-0.3) max(0.3) ntics(7)}{p_end}

{pstd}
{ul:Example 4: Changing aspect ratio and scaling}
{p_end}

{pstd}
If you are plotting effects for a few variables, you are likely to prefer the look
of the graph if you changes the aspect ratio. When you do this, "white space"
(which might be colored depending on your scheme) appears at the top and bottom of
the graph. To trim this off, you need to change the ysize of the graph. This will affect
the size of markers and text, so you also need to adjust these. The following
example shows how to do this so that the "trimmed" graph looks like the graph
before trimming.
{p_end}

{phang2}{cmd:* determine default xsize and ysize}{p_end}
{phang2}{cmd:viewsource scheme-s2manual.scheme}{p_end}
{phang2}{cmd:* assign defaults to locals}{p_end}
{phang2}{cmd:local xdefault = 3.12}{p_end}
{phang2}{cmd:local ydefault = 2.392}{p_end}
{phang2}{cmd:* aspect ratio on ysize for your graph}{p_end}
{phang2}{cmd:local asp = .4}{p_end}
{phang2}{cmd:local ynew = 1.5}{p_end}
{phang2}{cmd:* compute ratio used to adjust scale}{p_end}
{phang2}{cmd:local ratio = `ydefault'/`ynew'}{p_end}
{phang2}{cmd:* make graph}{p_end}
{phang2}{cmd:mchangeplot age income, ///}{p_end}
{phang2}{cmd:  aspect(`asp') xsize(`xdefault') ysize(`ynew') scale(*`ratio')}{p_end}

INCLUDE help spost13_footer
