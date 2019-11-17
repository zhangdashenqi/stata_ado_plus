{smcl}
{* *! Help file version 1.2.1 written by Mead Over (mover@cgdev.org) 15Apr2016}{...}
{* *! Based on the help file for grc1leg by Vince Wiggins.}{...}
{viewerdialog grc1leg2 "dialog grc1leg2"}{...}
{vieweralsosee "[G-2] graph combine" "mansection G-2 graphcombine"}{...}
{vieweralsosee "[G-3] graph ..., by()" "mansection G-3 by_option"}{...}
{vieweralsosee "[G-4] gph files and sersets" "mansection G-4 conceptgphfiles"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[G-2] gr combine" "help gr_combine##remarks4"}{...}
{vieweralsosee "[G-3] gr ..., by()" "help by_option"}{...}
{vieweralsosee "[G-4] gph files and sersets" "help gph_files"}{...}
{vieweralsosee "[SJ] grc1leg by Vince Wiggins" "net describe grc1leg,from(http://www.stata.com/users/vwiggins)"}{...}
{viewerjumpto "Syntax" "grc1leg2##syntax"}{...}
{viewerjumpto "Description" "grc1leg2##description"}{...}
{viewerjumpto "Options" "grc1leg2##options"}{...}
{viewerjumpto "Remarks" "grc1leg2##remarks"}{...}
{viewerjumpto "Examples" "grc1leg2##examples"}{...}
{viewerjumpto "Authors" "grc1leg2##author"}{...}
{title:Title}

{p2colset 5 22 26 2}{...}
{p2col :{cmd:grc1leg2} {hline 2}}Combine multiple graphs with a single common legend{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 23}
{cmd:grc1leg2}
{it:name}
[{it:name} ...]
[{cmd:,}
{it:{help graph_combine:combine_options}}
{it:legend_options}
{it:xtitle_options}
]

{p 4 4 2}
where {it:name} is

	{it:name}{col 40}description
	{hline 65}
	{it:simplename}{...}
{col 40}name of graph in memory
	{it:name}{cmd:.gph}{...}
{col 40}name of graph stored on disk
	{cmd:"}{it:name}{cmd:"}{...}
{col 40}name of graph stored on disk
	{hline 65}
	See {help graph_combine} for full details on syntax and options.
	
{p 4 4 2}
and where {it:legend_options} are

	{it:legend_options}{col 40}description
	{hline 69}
{col 9}{...}
{col 9}{...}
{cmdab:leg:endfrom:(}{it:name}{cmd:)}{...}
{col 40}graph from which to take legend
{...}
{col 9}{...}
{cmdab:pos:ition:(}{it:{help clockpos}}{cmd:)}{...}
{col 40}where legend appears
{...}
{col 9}{...}
{cmd:ring(}{it:{help ringpos}}{cmd:)}{...}
{col 40}where legend appears (detail)
{...}
{col 9}{...}
{cmd:span}{...}
{col 40}"centering" of legend
{...}
{col 9}{...}
{cmd:holes(}{it:{help numlist}}{cmd:)}{...}
{col 40}specify how the resulting graphs are arrayed
{...}
{col 9}{...}
{cmdab:ls:ize:(}{it:{help textsizestyle}}{cmd:)}{...}
{col 40}size of the key labels in the legend
	{hline 69}
{p 8 8 2}
Stata has many other {help legend_options:legend options},
none of which is available here in {cmd:grc1leg2}. 
These other legend options, if desired, must be used
to specify the legend on the component graph 
that {cmd:grc1leg2} is to use for the combined graph. 
See the 
{view grc1leg2.sthlp##examples:examples} 
below for guidance on using the 
{cmd:ring(}{it:{help ringpos}}{cmd:)}
and the
{cmdab:pos:ition:(}{it:{help clockpos}}{cmd:)}
options.  
See 
{hi:Positioning of titles} in help
{it:{help title_options##suboptions}}
for definitions of {it:clockpos} and {it:ringpos}.
	
{p 4 4 2}
and the {it:xtitle_options} are:

	{it:xtitle_options}{col 40}description
	{hline 69}
{col 9}{...}
{col 9}{...}
{cmdab:xtob:1title}{...}
{col 40}Suppress the {it:xtitle} on individual panels
{col 40}and use the {it:xtitle} from one of the panels 
{col 40}as the {it:b1title} on the combined graph.
{col 9}{...}
{cmdab:xti:tlefrom:(}{it:name}{cmd:)}{...}
{col 40}graph from which to take the {it:xtitle}
{...}
	{hline 69}

{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:grc1leg2}, like {help graph combine}, arrays separately drawn graphs as panels 
in a single combined graph.  In addition, {cmd:grc1leg2} suppresses the legends in
the individual graphs and adds a common legend taken from one of them.  
Optionally {cmd:grc1leg2} can also replace the separate {it:xtitles} 
on each of the individual graphs with a single {it:b1title} on the combined graph.
Optionally {cmd:grc1leg2} can also alter the {help textsizestyle} of
the text labels in the common legend.  All other attributes of the 
common legend are inherited from the legend on the component graph.

{marker options}{...}
{title:Options}

{p 4 8 2}
{cmd:legendfrom(}{it:name}{cmd:)} specifies the graph from which the legend for
   the combined graphs is to be taken, the default is the first graph in the
   list.  The argument {it:name} must match one of the names from the list of 
   graph names specified.

{p 4 8 2}
{cmd:position(}{it:clockpos}{cmd:)} and
{cmd:ring(}{it:ringpos}{cmd:)}
    override the default location of the legend, which is usually centered
    below the plot region.  {cmd:position()} specifies a direction {it:(sic)}
    according to the hours on the dial of a 12-hour clock, and {cmd:ring()}
    specifies the distance from the plot region.

{p 8 8 2}
    {cmd:ring(0)} is defined as being inside the plot region itself and allows you
    to place the legend inside the plot.  {cmd:ring(}{it:k}{cmd:)}, {it:k}>0,
    specifies positions outside the plot region; the larger the {cmd:ring()}
    value, the farther away from the plot region is the legend.  {cmd:ring()}
    values may be integers or nonintegers and are treated ordinally.

{p 8 8 2}
    {cmd:position(12)} puts the legend directly above the plot region
    (assuming {cmd:ring()}>0), {cmd:position(3)} directly to the right
    of the plot region, and so on.

{p 8 8 2}
	See the 
	{view grc1leg2.sthlp##examples:examples} 
	below for guidance on using the 
	{cmd:ring(}{it:{help ringpos}}{cmd:)}
	and the
	{cmdab:pos:ition:(}{it:{help clockpos}}{cmd:)}
	options and see 
    {hi:Positioning of titles} in
    {it:{help title_options}} for more information on
    the {cmd:position()} and {cmd:ring()} suboptions.

{p 4 8 2}
{cmd:span} specifies that the legend is to be placed in an area spanning the
    entire width (or height) of the graph rather than an area spanning the
    plot region.
    This affects whether the legend is centered with respect to the plot
    region or the entire graph.
    See {hi:Spanning} in
    {it:{help title_options}} for more information on {cmd:span}.

{p 4 8 2}
{cmd:holes(}{it:{help numlist}}{cmd:)}
    specify how the resulting graphs are arrayed.  These are the same
    options described in {manhelpi by_option G-3}.  Note that the
	{cmd:holes(}{it:{help numlist}}{cmd:)} does not work when there 
	are only two panels.

{p 4 8 2}
{cmdab:ls:ize:(}{it:{help textsizestyle}}{cmd:)}
	size of the key labels in the legend.  The single legend displayed by 
	{cmd:grc1leg2} is drawn from either the first graph name 
	appearing after the the {cmd:grc1leg2} command or from the graph named
	by the {cmd:legendfrom(}{it:name}{cmd:)} option. By default, all
	the characteristics of the legend displayed by {cmd:grc1leg2} are inherited 
	from the legend in that component graph.  Using this
	{cmdab:ls:ize:(}{it:{help textsizestyle}}{cmd:)} option enables the 
	user to specify the size of the text used for the key labels in this legend,
	overriding the original size specifications for these labels.
	The size of other text in the legend, such as the legend's title, 
	note or caption, is unchanged.
	This option is new to {cmd:grc1leg2}.

{p 4 8 2}
{cmdab:xtob:1title}
	suppresses the {it:xtitle} on individual panels
	and uses the {it:xtitle} from one of the panels 
	as the {it:b1title} on the combined graph. This option
	is consistent with this program's objective of simplifying
	and de-cluttering a multi-panel combined graph.
	However it should never be used if the panels have
	different x axes.  Thus, it is not a default option.
	This option is new to {cmd:grc1leg2}.

{p 4 8 2}
{cmdab:xti:tlefrom:(}{it:name}{cmd:)}
	specifies the graph from which the {it:xtitle} for
	the combined graphs is to be taken, the default is the first graph in the
	list.  The argument {it:name} must match one of the names from the list of 
	graph names specified.
	This option is new to {cmd:grc1leg2}.

{p 4 8 2}
{it:combine_options} specify how the graphs are combined, titling the combined
    graphs, and other common graph options.  A particularly important option 
	for legend placement is the holes() option.  See 
    {help graph_combine} for details.

{marker remarks}
{title:Remarks}

{p 4 4 2}
{cmd:grc1leg2} is like Stata's {cmd:graph combine} except it 
reduces the clutter in the combined graph by displaying a
single common legend for all of the combined graphs.  
The legend displayed is one of the legends from the graphs being combined.  
Optionally {cmd:grc1leg2} can also suppress the {it:xtitle} 
on each of the individual graphs, while using the {it:xtitle} 
from one of them as the {it:b1title} of the combined graph.
Optionally {cmd:grc1leg2} can also alter the {help textsizestyle} of
the text labels in the common legend.
Otherwise, {cmd:grc1leg2} behaves like {help graph_combine}.

{p 4 4 2}
While this program, {cmd:grc1leg2}, and its original incarnation, {help grc1leg} 
can be viewed as simply "wrappers" for Stata's {help graph combine} command,
they help the user to reduce the clutter on multi-panel graphs, a worthwhile objective

{p 4 4 2}
	When constructing a multi-panel graph with at least three panels,
	it is rarely satisfying for each panel to have its own legend.
	In most cases, it would be analytically and aesthetically preferable 
	to have a single common legend, with a common set of legend keys, 
	for all panels in the graph.  

{p 4 4 2}
	Stata's graph commands offer several ways to display a single
	common legend for all the panels in a multi-panel graph.
	However, by default, Stata puts the legend of a multi-panel 
	graph outside the multi-panel layout, squeezing all the panels 
	either vertically or horizontally.  This solution works logically
	but typically makes it hard to read the separate panels. 

{p 4 4 2}
	With approriate options, you can enhance the legibility 
	of the multi-panel graph by leaving room for the legend 
	in the multi-panel layout and using the approriate 
	legend options to place the legend in that empty spot.
	In Stata there are several ways to accomplish this objective without 
	resorting to the graph editor:{p_end}

{p 8 12 2}
	{ul:1.	One-step procedure, using {help by_option:graph ..., by()}}{p_end}
{p 12 16 2}
		a.	When feasible, construct the multi-panel graph using 
			a single graph command with the -by- option.  Stata
			will automatically construct a single legend with keys
			that are common across all panels of the graph.{p_end}
{p 12 16 2}
		b.	Optimum legend placement is typically in a "hole" 
			at the bottom right of the multi-panel layout. 
			To achieve this effect, use the legend options:
				- at(#) pos(5) -.{p_end}
{p 12 16 2}
		c.	Unlike the {help gr combine} and the 
			{cmd:grc1leg2} commands discussed below,
			the {help by_options:graph ..., by()} command accepts the full 
			range of {help legend_options:legend options}. See 
			{help by_options:help by_options##use_of_legends} for details.
			{p_end}
			
{p 8 12 2}
	{ul:2.	Two-step procedure, using {help gr combine:gr combine}} {p_end}
{p 12 16 2}
		a.	Construct and name the graphs for each of the separate panels{p_end}
{p 16 20 2}
				i.   Assure that the assignment of marker styles, line styles
				     and, especially, colors matches across named graphs.{p_end}
{p 16 20 2}
				ii.  Suppress the legend in all but the last of the separate graphs.{p_end}
{p 16 20 2}
				iii. For the last graph, specify legend options
					    -ring(0) pos(5) xoffset(#)-
				     with experimentation on the value of the offset.
					 This is also the place to specify any other
					 of the full range of Stata 
					 {help legend_options:legend options}.{p_end}
{p 12 16 2}
		b.	Combine the named graphs using {cmd:gr combine}.{p_end}
{p 20 20 2}
			Since {cmd:gr combine} does not have a {cmd:legend} option, 
			use the layout options -cols(#)- or -rows(#)- to assure 
			that the last specifed graph will be in the 
			bottom row of the panel layout.  This result is assured 
			if the number of component graphs is odd and no "holes"
			are specified prior to the ower right posiiton.{p_end}

{p 8 12 2}
	{ul:3.	Two-step procedure using this program, {cmd:grc1leg2}}{p_end}
{p 12 16 2}
		a.	Construct and name the graphs for each of the separate panels{p_end}
{p 16 20 2}
				i.  Assure that the assignment of marker styles, line styles
				    and, especially, colors matches across named graphs.{p_end}
{p 16 20 2}
				ii. No need to suppress the legends on any of the 
					component graphs{p_end}
{p 16 20 2}
				iii. For one of the component graphs, by default the first,
					optionally specify any desired {help legend_options:legend options}
					other than those allowed by the {cmd:grc1leg2} command.
					{p_end}
{p 12 16 2}
		b.	Combine the named graphs using {cmd:grc1leg2}{p_end}
{p 16 20 2}
			i.	Unlike {cmd:gr combine}, {cmd:grc1leg2} has a few 
				legend options to control legend placement.
				For example, to achieve a similar legend placement to
				method -2- above, one can specify:
					-ring(0) pos(5)-{p_end}
{p 16 20 2}
			ii. Optionally use the {cmdab:xtob:1title} option to suppress the 
			{it:xtitle} on each of the individual graphs and insert an overall
			{it:b1title} for the combined multi-panel graph.  Of course,
			this option is only approriate if all panels should have the same 
			{it:xtitle}{p_end}
{p 16 20 2}
			iii. Optionally use the {cmdab:ls:ize:(}{it:{help textsizestyle}}{cmd:)}
			option to specify the size of the key labels in the legend. 
			This specification overrides the key label sizes in 
			the legend when it was originally constructed for one of 
			the component graphs.{p_end}

{p 4 4 2}
The above remarks apply when the multi-panel graph has at least 3 component graphs
or panels.  
The strategies for placing a common legend are more restricted when there are only
two panels, because in that case 
Stata's {help by_option:graph ..., by()} 
and {help gr combine} commands do not respond to the 
{cmd:holes(}{it:{help numlist}}) option.
The do file entitled {cmd:testgrc1.do} available with this package includes examples
of situations with only two panels.{p_end}

{marker examples}
{title:Examples}

{p 4 4 2}
Examples of all three approaches when the number of panels >= 3{p_end}

{p 4 4 2}
First load Stata's {cmd:auto.dta} data and define a trichotomy based 
on the categorical value {it:rep78}.  The following lines
of code load the data and then create and label a new categorical 
variable, {it:qual}{p_end}

{p 8 8 2}sysuse auto {p_end}
{p 8 8 2}gen byte qual = 1*(rep78<3)+2*(rep78==3)+3*(rep78>=4){p_end}
{p 12 12 2}lab def qual 1 "Low Score"  2  "Medium"  3  "High Score"{p_end}
{p 12 12 2}lab value qual qual{p_end}
{p 12 12 2}lab var qual "Quality - Mapping of rep78 into trichotomy"{p_end}

		{it:({stata "grc1leg2_examples setup":click to run, prior to running the examples below})}

{p 8 12 2}
	1.	One-step procedure, using -graph ..., by()-

{p 12 12 2}
		Using a single graph command with the -by- option
		automatically assigns only a single legend.  Here are examples
		with three panels and with five panesls.  Both examples use
		the options {cmd:at(#)} and {cmd:pos(#)} to insert the legend 
		into the multi-panel array. Note that two {cmd:legend}
		options are specified in each command, one outside and one
		inside the by() option.  See 
		{help by_options##use_of_legends:help by_options} 
		for details. {p_end}

	twoway  ///
		(scatter mpg weight)  ///
		(lfit mpg weight ),  ///
			legend(col(1)) ///
			by(qual,  ///
				legend(pos(0) at(4))  ///
				title("Three panels, with legend in a hole")  ///
				subtitle("Use -twoway ..., by()- with -at(4) pos(5)-") ///
			)  ///
		name(grby3, replace)

		{it:({stata "grc1leg2_examples grby3":click to run, after clicking above to get the data})}

	twoway  ///
		(scatter mpg weight)  ///
		(lfit mpg weight ),  ///
			legend(col(1)) ///
			by(rep78,  ///
				legend(pos(0) at(6))  ///
				title("Five panels, with legend in a hole")  ///
				subtitle("Use -twoway ..., by()- with -at(6) pos(0)-") ///
			)   ///
		name(grby5, replace)

		{it:({stata "grc1leg2_examples grby5":click to run})}

{p 8 12 2}
	2.	Two-step procedure, using {help gr combine}: 

{p 4 4 2}
	The Stata command {help gr combine} does not have a {cmd:legend} option.
	In order for the combined graph to have only one legend,
	we must assure that only 1 of the component graphs has a legend.

{p 4 4 2}
	First create the three component graphs and name them panel1, 2 and 3.  
	In order for {help gr combine} to display a single common legend, 
	the legends must be suppressed on all but one of the individual component 
	graphs at the time they are originally created. 
	The legend to be displayed can be on the last of the component graphs 
	and can be moved to a "hole" using the xoffset and yoffset options
	at the time this component graph is originally created.{p_end}

	set graph off
	twoway  ///
		(scatter mpg weight if qual==1)  ///
		(lfit mpg weight if qual==1),  ///
			subtitle("Low Score")  ///
			legend(col(1) off) /// 
			name(panel1, replace)

	twoway  ///
		(scatter mpg weight if qual==2)  ///
		(lfit mpg weight if qual==2),  ///
			subtitle("Medium")  ///
			legend(off) ///
			name(panel2, replace)

	twoway  ///
		(scatter mpg weight if qual==3)  ///
		(lfit mpg weight if qual==3),  ///
			subtitle("High Score")  ///
			legend(col(1) ring(0) pos(5) xoffset(40) )  ///
			name(panel3, replace)
	set graph on
	graph dir, memory // These named graphs are now in memory

		{it:({stata "grc1leg2_examples make3panels":click to run, before running the {cmd:gr combine} and {cmd:grc1leg2} examples})}

{p 4 4 2}
	Using {help gr combine} when the last of the component graphs
	has been specified with options -ring(0) pos(5) xoffset(#)- , 
	works well when we have suppressed the legends on the
	first two panels, properly calibrated the offset
	and arranged the placement of the panels to allow
	for a "hole" which can accommodate the legend.{p_end}

	gr combine panel1 panel2 panel3,  ///
		xcommon ycommon      ///
		title("Three panels, with legend in a hole")  ///
		subtitle("Use -gr combine ...  , having specified"  ///
			"-ring(0) pos(5) xoffset(40)- on the last graph")  ///
		name(grcomb3, replace) 

		{it:({stata "grc1leg2_examples grcomb3":click to run, after creating panels 1, 2 & 3 above})}
	
{p 4 4 2}
	{help gr combine} works equally well when there are 
	five panels, so that the offset legend from the 
	fifth panel ends up in location 6.{p_end}

	gr combine panel1 panel2 panel1 panel2 panel3,  ///
		xcommon ycommon      ///
		title("Five panels, with legend in a hole")  ///
		subtitle("Use -gr combine ...  , having specified"  ///
			"-ring(0) pos(5) xoffset(40)- on the last graph")  ///
		name(grcomb5, replace) 

		{it:({stata "grc1leg2_examples grcomb5":click to run})}

{p 4 4 2}
	Here's an example with eight panels and the legend in the middle. 
	In the above two examples there was no need to specify the
	holes option, since the number of panels and the default panel layout assured there
	would be a "hole" in the lower right hand corner of the array.  
	In this example, because we want the hole in the middle, we must 
	use the {cmd:holes(}{it:{help numlist}}{cmd:)} option.{p_end}
	
	gr combine panel1 panel2 panel1 panel3 panel1 panel2 panel1 panel2,  ///
		xcommon ycommon holes(5)    ///
		title("Eight panels, with legend in the middle")  ///
		subtitle("Use -gr combine ...  , having specified"  ///
			"-ring(0) pos(5) xoffset(40)- on the fourth graph")  ///
		b1title("Weight")  ///
		name(grcomb8, replace) 

		{it:({stata "grc1leg2_examples grcomb8":click to run})}

{p 4 4 2}
	3.	Two-step procedure using {cmd:grc1leg2}{p_end}

{p 4 4 2}
	Using {cmd:grc1leg2} avoids the need to suppress the legends on all but the
	last panel.  But to avoid squeezing the multi-panel layout,
	one should still take care to leave a "hole" at the lower right
	of the layout and then place the legend in that hole.{p_end}

	grc1leg2 panel1 panel2 panel3,  ///
		xcommon ycommon ring(0) pos(5) legendfrom(panel1)    ///
		title("Three panels, with legend in a hole")  ///
		subtitle("Use -grc1leg2- with options -ring(0) pos(5)-  " /// 
			"without the option -xtob1title-")  ///
		name(grc13woxtob1, replace)

		{it:({stata "grc1leg2_examples grc13woxtob1":click to run})}
	
{p 4 4 2}
	Use of the {cmdab:xtob1title} option saves additional space in the y-dimension
	and reduces the excess "ink" in the graph by suppressing {it:xtitle}s
	on the individual panels and instead using a single overall {it:b1title}
	for the entire combined graph.{p_end}

	grc1leg2 panel1 panel2 panel3,  ///
		xcommon ycommon ring(0) pos(5) legendfrom(panel1)    ///
		title("Three panels, with legend in a hole")  ///
		subtitle("Use -grc1leg2- with options -ring(0) pos(5)-  " /// 
			"with the option -xtob1title-")  ///
		xtob1title  ///
		name(grc13, replace)

		{it:({stata "grc1leg2_examples grc13":click to run})}

{p 4 4 2}
	Use of the {cmdab:ls:ize:(}{it:{help textsizestyle}}{cmd:)}
	option allows the user to change the size of the labels
	inside the legend box, overriding the font size specified
	when the legend was created.{p_end}

	grc1leg2 panel1 panel2 panel3,  ///
		xcommon ycommon ring(0) pos(5) legendfrom(panel1)    ///
		title("Three panels, with legend in a hole")  ///
		subtitle("Use -grc1leg2- with options -ring(0) pos(5)-  " /// 
			"with the option -xtob1title-")  ///
		xtob1title lsize(large) ///
		name(grc13lsize, replace)

		{it:({stata "grc1leg2_examples grc13lsize":click to run})}

{p 4 4 2}
	To position the legend in the middle of an eight-panel array,
	we use the options -ring(0) pos(0) holes(5)-{p_end}

	grc1leg2 panel1 panel2 panel1 panel3 panel1 panel2 panel1 panel3,  ///
		xcommon ycommon ring(0) pos(0) holes(5) legendfrom(panel1)    ///
		title("Eight panels: with legend in middle")  ///
		subtitle("Use -grc1leg2- with options -ring(0) pos(0) holes(5)-  "  ///
			"with the option -xtob1title-")  ///
		xtob1title  ///
		name(grc18, replace)
		
		{it:({stata "grc1leg2_examples grc18":click to run})}


{marker author}{...}
{title:Authors}

{phang}Vince Wiggins coded {help grc1leg} and distributed it on Statalist 16 June 2003.
His version 1.0.5, dated 02jun2010, is available from
{net "describe grc1leg, from(http://www.stata.com/users/vwiggins)":Stata}.
This program is a hack of his version 1.0.5.  This help file is an edit of his 
original help file for {cmd:grc1leg}, with added documentation
of {cmd:cgc1leg2}'s options and added examples of Stata's alternative
approaches to control the placement of a single legend in a multi-panel 
graph.  In April 2016, Derek Wagner of StataCorps added code 
to implement the -lsize(textsizestyle)- option.
{p_end}

{phang}{browse "http://www.cgdev.org/expert/mead-over/":Mead Over} added additional 
functionality in May-August, 2015.  Contact him at:
Email: {browse "mailto:mover@cgdev.org":MOver@CGDev.Org} if you observe any
problems. {p_end}

{* Version History}
{* Version 1.0.5 of grc1leg	02jun2010 by Mead Over}
{* Version 1.1.0  1Apr2016: Added xtob1title and xtitlefrom}
{* Version 1.2   11Apr2016: Added lsize(textsizestyle) option.}
{* Version 1.2.1 15Apr2016: Edit.}

