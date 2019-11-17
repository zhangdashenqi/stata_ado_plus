{smcl}
{* 2013-07-02 scott long}{...}
{hi:help dcplot}{right:also see: {helpb orplot}, {helpb mchange}}
{hline}

2013-01-24
symbols() symbols for outcome categories to overwrite val labels
    * symbols(SR R I D SD)
mcolor(rainbow)
TITLETop(string) TITLEBottom(string) replace default title

Customize change type labels _none_ for none
    stdulabel() Unit change
    stdrlabel() Range change
    stdslabel() SD change
    stdblabel() 0 to 1
    stdplabel() Partial

Add stars for sig of changes
    stars: plot pvalues *=.10 **=.05 ***=.001
    star10(text) _none_ if no star can use stars star10(_none_) star05(_none_) star01("{sup:*}")
    star05(text)
    star01(text)

stagger(#) offset symbols vertically for packed

{title:Plotting discrete change for multicategory outcome models}

{p2colset 5 16 24 2}{...}
{p2col:{cmd:dcplot} {hline 2}}Plotting discrete change coefficients from
regression models for nominal and ordinal outcomes{p_end}
{p2colreset}{...}

{marker overview}
{title:Overview}

{pstd}
{cmd:dcplot} plots discrete change coefficients computed by {cmd:mchange}
for various regression models for categorical outcomes, such as
{cmd:mlogit}, {cmd:ologit}, {cmd:oprobit}, {cmd:slogit}, and {cmd:to be determined}.

{pstd}
To plot odds ratios along with discrete changes, see {help orplot}.

{pstd}
For more information and examples, see {browse "http://www.indiana.edu/~jslsoc/":SPost Website}.


{title:General syntax}

{p 4 18 2}
{cmd:dcplot }[{it:varlist}]{cmd:,} {it:options}
{p_end}

{p 8 10 2}
where {it:varlist} is variables from the regression model used to compute
the discrete changes. If no name is specified all variables are graphed.
{p_end}


{title:Table of contents}

    {help dcplot##todo:To do list: things to add, test or fix}
    {help dcplot##axes:Axes and plot region}
    {help dcplot##outcomes:Symbols for outcome categories}
    {help dcplot##lines:Lines among outcomes and vertical offsets}
    {help dcplot##labels:Labels and notes}
    {help dcplot##tweaking:Tweaking defaults}

{title:Options}
{marker axes}
{dlgtab:Axis and graph region}
{pstd}

{pstd}
These options control how the x-axes are displayed.
The x-axis contains the scale for the discrete changes.
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

{synopt:{opt xli:ne(numlist [, line-options])}}
Add vertical lines at specified values. Values and {it:line-options}
are passed to {cmd:graph}'s {cmd:xline()} option.

{p 5 5 2}
{ul:Plot region and labeling}
{p_end}
{p2colset 7 24 25 0}
{synopt:{opt aspect:ratio(#)}}
Set the aspect ratio of the plot region. Ratio is height/width.

{synopt:{opt dec:imals(#)}}
Number of decimal digits on the lower x-axis scale. That scale is in
units of the beta's for an OR-plot or probabilities for a DC-plot.

{marker outcomes}
{dlgtab:Symbols for outcome categories}
{pstd}

{pstd}
Eeach outcome category is represented by a marker that can be either the
first letter of the outcome variable's value labels or the numeric value
of the category (use option {cmd:values}). Coefficients can represent
different amounts of change in the predictor, controled by the
{cmd:std()} option. In OR plots, you can align plots by different base
values from the {cmd:mlogit} and let the size of the marker correspond
to discrete change.
{p_end}

{pstd}
{ul:Which coefficients to plot}
{p_end}
{p2colset 7 24 25 0}
{synopt:{opt std( u|s|b|r u|s|b|r ...)}}
Specify the standardizatin to be used for each variable being plotted.
For example {cmd:std(uubr)} By default, binary variables are plotted as
type {cmd:b}; other variables as type {cmd:s}.

{p2colset 10 23 22 12}{...}
{p2col : std-symbol}Description{p_end}
{p2line}
{p2col :{bf:u}}Unstandardized coefficient for a unit change{p_end}
{p2col :{bf:s}}Standardized coefficient for a standard deviation change.{p_end}
{p2col :{bf:r}}Coefficient for a change over the range of the predictor.{p_end}
{p2col :{bf:b}}Binary change from 0 to 1.{p_end}
{p2line}

{p 5 5 2}
{ul:Appearance of the symbols}
{p_end}
{p2colset 7 24 25 0}
{synopt:{opt values}}
Represent categories by their numeric value.
By default outcomes are indicated by the first letter of their
value label.

{synopt:{opt m:color(colorstylelist)}}
Specify the colors to use for outcome markers. Different colors can be used
for each marker, such as {cmd:mcol(red orange green blue). Colors use
Stata's {helpb colorstyle}.

{synopt:{opt msiz:efctor(#)}}
Adjust the size of the markers by this factor.

{marker labels}
{dlgtab:Labels and notes}
{pstd}

{pstd}
You can customize labels on the y-axis and add notes to your graph
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
{p2colset 7 24 25 0}
{synopt:{opt ti:tile(tinfo)}}
Add a title using {cmd:graphs}'s {cmd:title()} option. {it:tinfo} can be
a simple text string or use Stata's {help title_options}.

{synopt:{opt sub:title(tinfo)}}
Add a subtitle.

{synopt:{opt note(tinfo)}}
Add a note.

{synopt:{opt cap:tion(tinfo)}}
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
{p2colset 7 24 25 0}
{synopt:{opt stdlabelsp:aces(#)}}
The number of spaces at the end of the labels for coefficient types at
on the y-axis. Negative values can be used to move the labels closer to
the axis.

{synopt:{opt graph:options(string)}}
Graphing options that are passed through to {cmd:graph}.
{p_end}


{title:Development work}
{marker todo}
{dlgtab:Things to do, test or debug}
{pstd}

{pstd}
1. How many variables can be graphed? What happens with no var list?
2. Add matrix input.
{p_end}


{title:Also see}

{pstd}
Manual: {hi:[G] graph}

INCLUDE help spost13_footer
