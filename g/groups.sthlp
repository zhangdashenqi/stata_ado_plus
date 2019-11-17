{smcl}
{* 28jul2003/5apr2007/11apr2007/20jan2010/21jan2010/24jan2011/31jan2012/19jun2015/29apr2016/30jun2017/20jul2017}{...}
{cmd:help groups}{right: ({browse "http://www.stata-journal.com/article.html?article=st0496":SJ17-3: st0496})}
{hline}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col :{hi:groups} {hline 2}}List group frequencies and percents{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:groups}
{it:varlist}
{ifin}
[{it:weight}]
[{cmd:,} {it:options}]

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Specification options}
{synopt :{cmdab:fill:in}}show cross-combinations with values of 0{p_end}
{synopt :{cmd:ge}}reverse frequencies and percents for current and later groups{p_end}
{synopt :{cmd:lt}}cumulatives for previous groups{p_end}
{synopt :{cmdab:miss:ing}}show missing values{p_end}
{synopt :{cmdab:sel:ect(}{it:condition}|{it:#}{cmd:)}}select results{p_end}
{synopt :{cmdab:sh:ow(}{it:what_to_show}{cmd:)}}specify to show frequencies,
percents, etc.{p_end}
{synopt :{cmdab:percent:var(}{it:varlist}{cmd:)}}specify the variables defining which
percents are calculated{p_end}

{syntab:Presentation options}
{synopt :{cmdab:form:at(}{it:format}{cmd:)}}display format for percents{p_end}
{synopt :{it:list_options}}options of {helpb list}{p_end}
{synopt :{cmdab:o:rder(}{cmdab:h:igh}|{cmdab:l:ow}{cmd:)}}order by frequency{p_end}
{synopt :{cmdab:rev:erse}}reverse display from default{p_end}
{synopt :{cmd:showhead(}{it:text}{cmd:)}}header text for frequencies{p_end}
{synopt :{cmd:colorder(}{it:integers}{cmd:)}}reorder or repeat columns of
table{p_end}

{syntab:Saving results}
{synopt :{cmd:saving(}{it:filename}[{cmd:,} {it:save_options}]{cmd:)}}save results to dataset{p_end}
{synoptline}

{p 4 4 2}
{cmd:by}{cmd::} may be used with {cmd:groups}; see {helpb by}.  This is one
key to controlling how percents are calculated; that is, under {cmd:by},
percents sum to 100 within distinct categories defined by its {it:varlist}.

{p 4 4 2}
{cmd:fweight}s and {cmd:aweight}s are allowed; see {help weight}.


{title:Description}

{p 4 4 2}
{cmd:groups} lists the distinct groups of {it:varlist} occurring in the
dataset and their frequencies or percents.  {cmd:groups} is perhaps most
useful with categorical variables but has other uses.  Groups are presented by
default in the sort order of {it:varlist}.  There is no limit on the number of
variables in {it:varlist}.

{p 4 4 2}
Frequencies are counts or other measures of abundance.

{p 4 4 2}
Percents are percents of each total frequency.

{p 4 4 2} 
Cumulative frequencies and percents are cumulated in the order of groups and
show frequency (percent) in each group and all earlier groups in the listing
(unless the {cmd:lt} option is specified).

{p 4 4 2}
Reverse cumulative frequencies and percents show frequency (percent) in all
later groups in the listing (unless the {cmd:ge} option is specified).

{p 4 4 2} 
"Valid" percents are calculated relative to all pertinent nonmissing values.


{title:Options}

{dlgtab:Specification options}

{p 4 8 2}
{cmd:fillin} specifies that groups (that is, cross-combinations) of
{it:varlist} that do not occur in the data be shown explicitly as having a
frequency of 0.  This has no effect with a single variable.  Note that this
option can backfire because the number of cross-combinations can explode
combinatorially.

{p 4 8 2}
{cmd:ge} (think {cmd:g}reater than or {cmd:e}qual to) specifies that reverse
frequencies and percents be calculated for the current and all later groups;
that is, they are for values greater than or equal to each value.

{p 4 8 2}
{cmd:lt} (think {cmd:l}ess {cmd:t}han) specifies that cumulative frequencies
and percents be calculated only for the previous groups; that is, they are for
values less than each value.

{p 4 8 2}
{cmd:missing} specifies that observations with missing values on any of the
variables in {it:varlist} be included in the listing.  By default, they are
omitted.  Note that "valid" percents will be the same as other percents unless
the {cmd:missing} option is specified.

{p 4 8 2}
{cmd:select(}{it:condition}|{it:#}{cmd:)} specifies that only selected groups
be listed.  There are two syntaxes.

{p 8 8 2}
In the first syntax, selection is according to a condition imposed on the
frequencies, or on the percents, or on the cumulative frequencies, or on the
cumulative percents, or on the reverse cumulatives.  The syntax is exemplified
by 

{p 8 8 2}{cmd:select(freq == 1)}{p_end}
{p 8 8 2}{cmd:select(percent > 5)}{p_end}
{p 8 8 2}{cmd:select(Percent < 50)}

{p 8 8 2}
The elements {cmdab:f:req}, {cmdab:p:ercent}, {cmdab:F:req},
{cmdab:P:ercent}, {cmdab:RF:req}, {cmdab:RP:ercent}, {cmdab:v:percent},
{cmdab:V:percent}, and {cmdab:rv:percent} may be abbreviated down to
unambiguous abbreviations.  Note that case matters in distinguishing
{cmd:freq} and {cmd:Freq}, {cmd:percent} and {cmd:Percent}, and {cmd:vpercent}
and {cmd:Vpercent}.  What follows must complete a simple true-or-false
condition in Stata syntax, typically an inequality or equality.

{p 8 8 2}
In the second syntax, a positive or negative integer is specified.  A positive
integer specifies that only the {it:first #} groups be shown.  A negative
integer specifies that only the {it:last} {c |}{it:#}{c |} groups be shown.

{p 8 8 2}
First and last are determined with respect to the listing which would
otherwise have been given.

{p 8 8 2}
Thus, with {cmd:order(h)}, {cmd:select(5)} shows the five groups with the five
highest frequencies, while {cmd:select(-5)} shows the five groups with the
five lowest frequencies, ties being broken according to the sort order of
{it:varlist}.  With {cmd:order(l)}, the opposite is true.

{p 8 8 2}
Without {cmd:order()}, {cmd:select(5)} shows the first five groups of
{it:varlist}, and {cmd:select(-5)} shows the last five groups of {it:varlist}.
The most obviously useful example is when {it:varlist} consists of a single
variable, so the listing is of the five lowest (highest) groups of values of
that variable.

{p 4 8 2}
{opt show(what_to_show)} specifies which frequencies should be shown.  By
default, frequencies, percents, and cumulative percents are shown with one
variable, and frequencies and percents are shown with two or more variables,
in that order.  {cmd:show()} may be used to specify one or two or three of
those, or cumulative frequencies, or reverse cumulative frequencies, or
reverse cumulative percents, or equivalent percents for "valid" values, or to
change the order of presentation.  The elements {cmd:freq}, {cmd:percent},
{cmd:Freq}, {cmd:Percent}, {cmd:RFreq}, {cmd:RPercent}, {cmd:vpercent},
{cmd:Vpercent}, and {cmd:rvpercent} may be abbreviated down to unambiguous
abbreviations.  Note that case matters in distinguishing {cmd:freq} and
{cmd:Freq}, {cmd:percent} and {cmd:Percent}, and {cmd:vpercent} and
{cmd:Vpercent}.

{p 8 8 2}
{cmd:show(none)} may be used to specify that none of these should be shown.
For example, with {cmd:select(f == 1)}, the frequencies would all be 1 and are
thus unnecessary to display, while the percents and cumulative percents may
not be of interest, so {cmd:show(none)} may be desired.

{p 4 8 2} 
{opt percentvar(varlist)} specifies that percents and cumulatives be
calculated with respect to the combinations of the variables specified.  The
results shown will resemble those with {cmd:by:}, except that the variables
named are displayed within each body of results.  The default is that percents
and cumulatives are calculated with respect to all observations selected.

{p 8 8 2}
For example, the same numerical results will appear for

{p 8 8 2}
{cmd:. bysort foreign: groups rep78} 

{p 8 8 2}
and for 

{p 8 8 2}
{cmd:. groups foreign rep78, percentvar(foreign)} 

{p 8 8 2}
so that, in either case, percents are calculated for groups defined by
distinct categories of {cmd:foreign}.


{dlgtab:Presentation options}

{p 4 8 2}
{opt format(format)} specifies a numeric format for percent and cumulative
percent frequencies.  The default is {cmd:format(%6.2f)}.

{p 4 8 2}
{it:list_options} are options of {helpb list}.  These offer several ways to
change the appearance of the listing.  Note that {cmd:sum} by itself produces
sums only of frequencies and percents, where shown.  {cmd:sepby()} and
{cmd:separator()} are often especially helpful.

{p 4 8 2}
{cmd:order(high}|{cmd:low)} specifies that groups be listed in order of their
frequencies.  Ordering may be {cmd:high} (highest frequencies first) or
{cmd:low} (lowest frequencies first).

{p 4 8 2}
{cmd:reverse} reverses what would otherwise be displayed, putting the last
values first.

{p 4 8 2}
{opt showhead(text)} specifies alternative text for the header explaining
frequency variables.  There should be as many elements as the number of
frequency, percent, cumulative frequency, cumulative percent, reverse
cumulative frequency, reverse cumulative percent, and valid percent variables
listed, and they should occur in the same order as those variables are listed.
Text containing spaces should be bound in {cmd:" "}.  Thus, with 
{cmd:show(f RF)}, {cmd:showhead(# "# bigger")} specifies that
{cmd:f}requencies are indicated by {cmd:"#"} and {cmd:r}everse cumulative
{cmd:f}requencies are indicated by {cmd:"# bigger"}.

{p 4 8 2}
{opt colorder(integers)} specifies a reordering of what would otherwise be
shown as the columns of the listing.  You may specify one or more positive
integers.  Suppose {cmd:groups} would show four columns, but you want the
third and fourth columns to be shown first (that is, as the leftmost columns)
and then the first and second columns.  {cmd:colorder(3 4 1 2)} or just
{cmd:colorder(3 4)} would specify that.  (It follows that this option will not
omit columns, although it may be used to repeat columns.) Therefore, this
option is typically used on a second or later pass of {cmd:groups}.

{dlgtab:Saving results}

{p 4 8 2}
{cmd:saving(}{it:filename}[{cmd:,} {it:save_options}]{cmd:)} specifies that
the results listed be saved to a named Stata {cmd:.dta} file using 
{helpb save}.  That does not include any sums, means, or similar summaries.
Options of {cmd:save} may be specified in the usual way.  This option may not
be combined with {cmd:by:}.


{title:Examples}

{phang}{cmd:. sysuse auto}

{phang}{cmd:. groups foreign}{p_end}
{phang}{cmd:. tabulate foreign}{p_end}
{phang}{cmd:. groups foreign rep78}{p_end}
{phang}{cmd:. tabulate foreign rep78}

{phang}{cmd:. groups foreign rep78, fillin}{p_end}
{phang}{cmd:. groups foreign rep78, fillin saving(mytable, replace)}

{phang}{cmd:. bysort foreign: groups rep78}{p_end}
{phang}{cmd:. groups foreign rep78, percentvar(foreign)}{p_end}
{phang}{cmd:. groups foreign rep78, percentvar(foreign) show(f p P)}

{phang}{cmd:. groups mpg, select(f == 1) show(none)}{p_end}
{phang}{cmd:. groups mpg, select(5)}{p_end}
{phang}{cmd:. groups mpg, select(-5)}{p_end}
{phang}{cmd:. groups mpg, select(5) order(h)}

{phang}{cmd:. groups foreign rep78, fillin select(f == 0) show(none)} 

{phang}{cmd:. groups foreign rep78, sepby(foreign)}{p_end}
{phang}{cmd:. groups foreign rep78, sepby(foreign) showhead(# %)} 

{phang}{cmd:. groups rep78, missing show(freq percent vpercent) separator(0)}{p_end}
{phang}{cmd:. groups rep78, show(freq rfreq RPercent) ge}{p_end}
{phang}{cmd:. groups rep78, show(F f Rf) lt showhead(< = >)}

{phang}{cmd:. groups mpg, reverse}{p_end}
{phang}{cmd:. groups mpg, reverse show(f p RP) ge}

{phang}{cmd:. webuse nlswork}{p_end}
{phang}{cmd:. groups collgrad not_smsa c_city south, order(high) separator(0)}{p_end}
{phang}{cmd:. groups collgrad not_smsa c_city south, order(high) separator(0) colorder(5 6)}


{title:Acknowledgments}

{p 4 4 2}
Fred Wolfe made very helpful comments.  He, Roger Harbord, and Eric Zbinden
all found a bug.  A question from Stefan Gawrich led to the {cmd:ge} option.
A question from James Keeler led to the {cmd:reverse} option.  A question from
William Parry led to the {cmd:saving()} option.


{title:Author}

{pstd}
Nicholas J. Cox{break}
Department of Geography{break}
Durham University{break}
Durham, UK{break}
n.j.cox@durham.ac.uk


{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 17, number 3: {browse "http://www.stata-journal.com/article.html?article=st0496":st0496}

{p 7 14 2}
Help:  {manhelp tabulate R}, 
{manhelp table R}, 
{manhelp list D}; 
{manhelp duplicates D}, 
{manhelp contract D}, 
{helpb modes}, 
{helpb fre},
{helpb qplot}, 
{helpb distplot} (if installed){p_end}
