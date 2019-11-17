{smcl}
{* *! version 1.2.0 22apr206}{...}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwANND {hline 2} Calculates Average Nearest Neighbor Degree (ANND) of a network's nodes and derivated indexes for weighted networks. }
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwANND}
[{it:{help netname}}]
[{cmd:,}
{opt valued}
{opt direction()}
]



{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt val:ued}} Consider edges values; calculate {it:strength} instead of {it:degree} 

{synopt:{opt dir:ection()}} Indicate {it:inward} or {it:outward} (default) degree direction for directed networks.

{synopt:{opt standardize}} Scales the output in the range [0,1].  


{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}
Calculates the average nearest neighbor degree {it:i} in a {help netname:network} and
saves the result as a Stata variable {it : _ANND}. 

{pstd}
The average nearest neighbor degree for node {it:i} is equal to average {help nwdegree:degree} of neighbouring vertices.

{pstd}
For weighted networks, if {bf:valued} option is specified, the average nearest neighbor {it:strength} is calculated. Two indicators are thus computed. The Weighted Average Nearest Neigbhour Degree
({it:_WANND}),  And the Average Nearest Neighbour Strength ({it: _ANNS = }).
For details see : Fagiolo G, Reyes J, Schiavo S (2010) The evolution of the world trade web: a weighted-network analysis. Journal of Evolutionary Economics 20: 479–514.


{pstd}
For directed networks, the {it:inward} or {it:outward} direction should be specified in option {cmd: direction()}. If neither of them is specified, the outward direction is assumed by default.

{pstd}
{bf:standardize} Option divides {it:_degree} by (N-1) with N the number of nodes. As a consequence {it:_ANND} ranges from 0 to 1.
Useful to compare centrality scores across networks of different size. 
{it:_strength} is divided by (N-1) and by {it:max_strength}, not to outpace unity.


{pstd}
{cmd:nwANND} also returns the assortativity coefficient (also known as degree-degree correlation or dependency), defined as the Pearson correlation coefficient between {it : _degree} and {it: _ANND}.
If positive (negative), the network is said to be {it:assortative} ({it:disassortative}) : nodes tend to be connected with other nodes with similar (different) degree values.
The assortative coefficient is not impacted by the option {it:standardize}.

{title:Saved results}
{pstd}{cmd:nwANND} saves the following in {cmd:r()}:

{synoptset 14 tabbed}{...}
{p2col 5 20 30 2: Scalars}{p_end}
{synopt:{cmd:r(D_assort)}} Degree assortativity coefficient {p_end}
{p2colreset}{...}

{pstd}{cmd:nwANND, valued} saves the following in {cmd:r()}:

{synoptset 14 tabbed}{...}
{p2col 5 20 30 2: Scalars}{p_end}
{synopt:{cmd:r(S_assort)}} Strength assortativity coefficient ({it :_Strengh} x {it :_ANNS} correlation) {p_end}
{synopt:{cmd:r(W_assort)}} Weighted Degree assortativity coefficient ({it :_Degree} x {it :_WANND} correlation) {p_end}
{p2colreset}{...}
	


{title:Examples}
	{cmd:. webnwuse glasgow, nwclear}
	{cmd:. nwANND glasgow3, direction(outward)}
		
	{cmd:. webnwuse gang, nwclear}
	{cmd:. nwANND gang_valued, valued}
	{cmd:. nwANND gang_valued, valued standardize}
	
	
{title:Author}
Charlie Joyez, Paris-Dauphine University
charlie.joyez@dauphine.fr

{title:See also}
{pstd}
{cmd:nwANND}  requires the {bf : nwcommands} package developed by Thomas Grund.

{pstd}

For do-files and ancillary files, see:

	{cmd:. net describe nwcommands-ado, from(http://www.nwcommands.org)}
	
For help files, see :

	{cmd:. net describe nwcommands-hlp, from(http://www.nwcommands.org)}
