{smcl}
{* 2014-08-06 scott long & jeremy freese}{...}
{title:Title}

{p2colset 5 19 19 2}{...}
{p2col:{cmd:mlogitplot} {hline 2}}Creates an odds ratios plot for {cmd:mlogit}{p_end}
{p2colreset}{...}

{title:General syntax}

{p 6 18 2}
{cmd:mlogitplot} [ {it:varlist} ] [ {cmd:,} {it:options} ]
{p_end}

{p 4 4 2}
where {it:varlist} contains variables from {cmd:mlogit}.  If no variables
are named, all variables are graphed.
{p_end}

{marker overview}
{title:Overview}

{pstd}
{cmd:mlogitplot} creates plots of the coefficients from a multinomial logit
model fit by {cmd:mlogit}. Each category is plotted with the distance
between categories corresponding to the magnitude of the coefficients for the
contrast between those categories.
If marginal effects were computed with {cmd:mchange}, the size of the
effect can be indicated by the area of the symbols used to
represent outcome categories.


{title:Table of contents}

    {help mlogitplot##amount:Amount of change}
    {help mlogitplot##outcomes:Base category and outcome symbols}
    {help mlogitplot##axes:Axes and plot region}
    {help mlogitplot##lines:Lines among outcomes and vertical offsets}
    {help mlogitplot##labels:Labels and notes}
    {help mlogitplot##tweaking:Tweaking defaults}

{title:Options}
{marker amount}
{dlgtab:Amount of change}

{pstd}
The odds ratios can be computed for a unit change in the independent variable,
a standard deviation change, or a change over the range. For {helpb fvvarlist:factor variables}
specified with the {cmd:i.} syntax in the model, changes from 0 to 1 are plotted.
For non-factor variables (i.e., those not specified as {bf:i.}{it:varname}), the amount of change can
be selected with the {cmd:amount()} option.
{p_end}
{p2colset 7 24 25 0}
{synopt:{opt am:ount( var1-amount var2-amount ...)}}

{p2colset 10 23 22 12}{...}
{p2col : amount}Description{p_end}
{p2line}
{p2col :{bf:bin}}Binary change from 0 to 1 [0 to 1].{p_end}
{p2col :{bf:one}}Change of one unit [Unit change].{p_end}
{p2col :{bf:range}}Change over predictor's range [Range change].{p_end}
{p2col :{bf:sd}}Change of a standard deviation [SD change].{p_end}
{p2line}

{pstd}
The default labels are shown in brackets above. You can specify the labels
to use for each type of change with these options. Using the string "_none_"
will remove the label.
{p_end}
{p2colset 7 24 25 0}
{synopt:{opt binlab:el(string)}}

{synopt:{opt marglab:el(string)}}

{synopt:{opt onelab:el(string)}}

{synopt:{opt rangelab:el(string)}}

{synopt:{opt sdlab:el(string)}}

{marker outcomes}
{dlgtab:Base categories and symbols for outcome categories}
{pstd}

{pstd}
Each outcome is represented by a marker that can be the
first letter of the outcome variable's value labels, the numeric value
of the category (use option {cmd:values}), or symbols specified with {cmd:symbol()}.
You can align categories for different base values from the {cmd:mlogit}
and let the size of the marker correspond to discrete change.
{p_end}
{p2colset 7 24 25 0}
{synopt:{opt base:outcome(#)}}
Odds ratios are shown relative to this category. See {helpb mlogit}'s
option {cmd:baseoutcome()} for details.

{p 5 5 2}
{ul:Appearance of the symbols}
{p_end}
{p2colset 7 24 25 0}
{synopt:{opt mchange}}
Symbols for categories are proportional to the size of the discrete
change coefficients for that variable. Negative changes will be underlined.
Option {cmd:nosign} suppresses the underlining.

{synopt:{opt values}}
Represent categories by their numeric value.
By default outcomes are indicated by the first letter of their
value label.

{synopt:{opt sym:bols(catsym1 catsym2 ...)}}
Each category is represented by the symbols specified. For example,
{cmd:sym(A1 A2 A3 A4)} would use A1, A2, etc. as the markers.

{synopt:{opt mcol:ors(colorstylelist)}}
Specify the colors of the markers. Different colors can be used
for each marker, such as {cmd:mcol(red orange green blue)}. Colors use
Stata's {helpb colorstyle}. The color option {cmd:rainbow} picks colors in
the order of the rainbow.

{synopt:{opt mshade:s}}
Using the single color selected by {cmd:mcolor()}, uses shades of that
color for each symbol. {opt mshadesmin(#)} chooses the lightest shade and
is by default .25. Experiment with various numbers to create the shades you want.

{synopt:{opt msiz:efactor(#)}}
Adjust the size of the markers by this factor.

{marker lines}
{dlgtab:Lines among outcomes and vertical offsets}
{pstd}

{pstd}
In odds ratios plots it is useful to indicate whether the odds ratio for outcomes A
and B is significant. This is done by drawing lines connecting A and B if the
coefficient is {ul:not} significant (i.e., the outcomes are "linked").
When connecting lines are added it is necessary to add a vertical offset to
the markers to avoid overlapping lines. The vertical offset has no substantive
meaning.
{p_end}

{pstd}
{ul:When to draw lines}
{p_end}
{p2colset 7 18 19 0}
{synopt:{opt linep:values([# [#]...])}}
Lines connect outcomes if the odds ratios is not significant at this value.
If multiple values are used, lines are drawn to represent each level.
The appearance of the line is control with {cmd:lcolor()} and {cmd:lwidth()}.
The default value is .10.

{p 5 5 2}
{ul:Appearance of lines}
{p_end}
{p2colset 7 18 19 0}
{synopt:{opt lc:olor(colorstyelist)}}
Specify the colors of the connecting lines.
Different colors can be used if multiple line p-values are specified.
Colors use Stata's {helpb colorstyle}.
The color option {cmd:rainbow} picks colors in the order of the rainbow.

{synopt:{opt lshade:s}}
Using the single color selected by {cmd:lcolor()}, uses shades of that
color for lines indicating different p-values.
{opt lshadesmin(#)} choses the lightest shade and
is by default .25. Experiment with various numbers to create the shades you want.

{synopt:{opt lw:idth(linewidthlist)}}
Specify the line widths for the connecting lines.
Different widths can be used if multiple line p-values are specified.
Widths use Stata's {helpb linewidthstyle}.

{synopt:{opt linegap:factor(number)}}
No lines are shown in a circular region around each outcome symbol.
You can change the size of this region with this option. Larger numbers
move the lines further away from the symbol.

{p 5 5 2}
{ul:Vertical offsets}
{p_end}
{p2colset 7 18 19 0}
{synopt:{opt pack:ed}}
Do not use any vertical offset.

{synopt:{opt offsetlist(# # #...)}}
The vertical offset for each outcome for each variable are specified to
precisely locate each plot symbol. The scale of offsets is from -5 to 5.
The offsets are entered in the order: var1-outcome1 var1-outcome2 ...
var2-outcome1 var2-outcome2 ...

{marker axes}
{dlgtab:Axis and graph region}
{pstd}

{pstd}
These options control how the x-axes are displayed. In an {cmd:mlogitplot}, the
bottom x-axis is in units of the beta coefficients while the
upper x-axis is in units of the odds ratio. No options are required
but the graph often benefits by setting the values of the tic marks
with {cmd:min()}, {cmd:max()}, {cmd:gap()} and {cmd:ntics()}.
Setting the aspect ratio with {cmd:aspectratio()} is useful
depending on the number of variables in the
graph and the graph scheme being used.
{p_end}

{pstd}
{ul:x-axis, x-tics and x-lines}
{p_end}
{p2colset 7 23 24 0}
{synopt:{opt max(#)}}
Maximum value on the x-axis.

{synopt:{opt ormax(#)}}
Maximum value on the x-axis for the odds ratio.
Cannot be used with {opt max(#)} or {opt gap(#)}.

{synopt:{opt min(#)}}
Minimum value on the x-axis.

{synopt:{opt ormin(#)}}
Minimum value on the x-axis for the odds ratio.
Cannot be used with {opt min(#)} or {opt gap(#)}.

{synopt:{opt ntics(#)}}
Number of tic markers on x-axis; alternatively use {cmd:gap()}.

{synopt:{opt gap(#)}}
Numerical gap between tic marks; alternatively use {cmd:ntics()}.
For gap to work as expected, the gap needs to divide evenly into the
range; you might need to specify {cmd:min()} and {cmd:max()}.

{synopt:{opt xli:ne(numlist [, line-options])}}
Add vertical lines at specified values. Values and {it:line-options}
are passed to {cmd:graph}'s {cmd:xline()} option.

{synopt:{opt leftmargin(#)}}
Adds space to the left margin where # is the percent of the graph
width to add. This command is equivalent to the {opt graphregion(margin(l+#))}
option from {cmd: graph}.
See {helpb region_options}.
This option prevents truncation of value labels with factor variables.

{synopt:{opt graphregion(string)}}
Specify the {opt graphregion()} option from {cmd: graph}.

{synopt:{opt aspect:ratio(#)}}
Set the {helpb aspect_option:aspect ratio} of the plot region. Ratio is height/width.

{synopt:{opt xsize(#)}}
Set size of x-axis in inches.

{synopt:{opt ysize(#)}}
Set size of y-axis in inches. Changing the ysize will remove "white space" that sometimes
appears at the top and bottom of the graph, especially with small aspect ratios. Changing
the ysize affects the size of the text which can be adjusted by {cmd:scale()}

{synopt:{opt scale(#)}}
Make text, markers, and line widths smaller or larger. See example in the help
file for {helpb mchangeplot}.

{synopt:{opt dec:imals(#)}}
Number of decimal digits on the lower x-axis scale. That scale is in
units of the beta's.

{synopt:{opt ordec:imals(#)}}
Number of decimal digits on the upper x-axis scale. That scale is in
units of odds ratios (i.e., exp(beta)).
{p_end}

{marker labels}
{dlgtab:Labels and notes}
{pstd}

{pstd}
You can customize labels on the y-axis and add text to your graph
using standard {cmd:graph} options. The title text can be a simple text string or use Stata's {help title_options}.
{p_end}
{p2colset 7 23 24 0}
{synopt:{opt varl:abels}}
Use a variable's label rather than its name on the left axis.
{p_end}

{synopt:{opt ti:tle(text)}}
Add a title at the top using {cmd:graphs}'s {cmd:title()} option.

{synopt:{opt titleb:ottom(text)}}
Replace the default label for the logit coefficients at the bottom of the graph.

{synopt:{opt titlet:op(text)}}
Replace the default label for the odds ratios scale at the top of the graph.

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
{synopt:{opt offsetf:actor(#)}}
Multiply the vertical offsets in an OR-plot by this factor. Values
greater than one increase the spread; less than one decrease the spread.

{synopt:{opt offsetseq:uence(# #...)}}
By default offsets are rotated among the values 1 2 0. You can use
other values to change the pattern of offsets.

{synopt:{opt amountlabelsp:aces(#)}}
The amount of change listed below a variable's name on the
y-axis. The amount of spacing between this label and the y-axis can be modified.
Negative values move the label closer to the axis; positive values move the label
further from the axis.

{synopt:{opt graph:options(string)}}
Graphing options that are passed through to {helpb graph}.
{p_end}

{dlgtab:Examples}

{pstd}
{ul:{bf:Example 1: mlogitplot with adjusted axes and value labels}}{p_end}

{phang2}{cmd:. spex mlogit}{p_end}
{phang2}{cmd:. mlogitplot age female, symbols(D d I r R) min(-.1) max(.6) gap(.1) base(3)}{p_end}

{pstd}
{ul:{bf:Example 2: mlogitplot with added marginal effects}}{p_end}

{phang2}{cmd:. spex mlogit}{p_end}
{phang2}{cmd:. mchange black income}{p_end}
{phang2}{cmd:. mlogitplot black income, mchange varlabel ///}{p_end}
{phang3}{cmd:    title("OR plot with marginal effects") aspect(.3)}{p_end}

{pstd}
{ul:{bf:Example 3: Adjusting symbol offsets, changing significance of connecting lines}}{p_end}

{phang2}{cmd:. spex mlogit}{p_end}
{phang2}{cmd:. mlogitplot age income, symbols(D d i r R) base(3) ///}{p_end}
{phang3}{cmd:    ormin(.5) ormax(2) ntics(5) aspect(.3) ///}{p_end}
{phang3}{cmd:    offsetlist(2 -2 0 2 -2 2 -2 0 2 -2) linepvalue(.05) }{p_end}

INCLUDE help spost13_footer


