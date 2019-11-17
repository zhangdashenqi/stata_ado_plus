{smcl}
{* 02oct2012}{...}
{cmd:help shapley2}{right:Patrick Royston (after Stas Kolenikov)}
{hline}


{title:Shapley value decomposition}


{title:Syntax}

{p 8 12 2}
{cmd:shapley} {it:factor_list}
[{cmd:,} {it:options}]
{cmd::} {it:call_to_program} {cmd:@}
[{cmd:,} {it:calling_program_options}]


{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt d:ots}}display progress indicator{p_end}
{synopt :{opt fromto}}reports statistic when all or no factors are present{p_end}
{synopt :{opt noi:sily}}dislays all program output for debugging{p_end}
{synopt :{opt res:ult(sample_statistic)}}[required]sample statistic to be "shapleyed"{p_end}
{synopt :{opt perc:ent}}report percentages of Shapley value contributions{p_end}
{synopt :{opt replace}}replace {it:filename} if it exists{p_end}
{synopt :{opt sav:ing(filename)}}saves factor-patterns to {it:filename}{p_end}
{synopt :{opt stor:ing(filename)}}saves marginal differences to {it:filename}{p_end}
{synopt :{opt ti:tle(text)}}title to annotate the output{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
where {it:factor_list} is of the form {it:element} [ {it:element} ... ],
and {it:element} is either [{cmd:i.}]{it:varname}
or {it:name}{cmd:(}{it:varlist}{cmd:)}.


{title:Description}

{pstd}
{cmd:shapley2} performs (exact additive) decomposition of a sample statistic
according to effects on the outcome variable (i.e. predictors) specified
in {it:factor_list}. To perform Shapley decomposition, the effects are
eliminated one by one, and marginal effects from each exclusion
are weighted according to the stage of exclustion. The weights of the
marginal effects are assigned in such a way that all exclusion trajectories
have equal weights.

{pstd}
In other words, {cmd:shapley2} effectively creates 2^(# factors) patterns of
included and excluded factors from the list specified in {it:factor_list},
runs {it:call_to_program} with {it:calling_program_options} where the {cmd:@}
is substituted for the current pattern, saves the results and weights them
in some 'fair' way.

{pstd}
The syntax of {it:factor_list} allows elements that specify ordinary variables,
factor variables, and/or a list of variables enclosed in parentheses and
preceded by a label called {it:name}. {it:name} may be a {it:varname}
or just some simple text without spaces. It is used only to label the output
related to {cmd:(}{it:varlist}{cmd:)}. See {it:Remarks} for further details.

{pstd}
{cmd:shapley2} is written in the most general way and saves as many results
as possible to enable you to populate the Shapley framework with whatever
contents you require.


{title:Options}

{phang}
{opt dots} entertains you by displaying a progress indicator.

{phang}
{opt fromto} reports the values of the statistic when all factors are present
and when no factor is present.

{phang}
{opt noisily} displays the output of the program you are calling. Be prepared
for a huge amount of output if you specify this; you won't want it
unless your {it:program} returns crazy results. You might want to use
{cmd:quietly} in your program to reduce amount of output produced.

{phang}
{opt percent} is used to report the percentages of Shapley value contributions
corresponding to the elements in {it:factor_list}.

{phang}
{opt replace} indicates to Stata that the files specified in options
{opt saving()} and {opt storing()} may be replaced if they already exist.

{phang}
{cmd:result(}[{cmd:global}] {it:sample_statistic}{cmd:)} defines the sample statistic
to be 'shapleyed' in the form {cmd:r(}{it:something}{cmd:)},
{cmd:e(}{it:something}{cmd:)}, or a global macro defined by the called program.
Specify {cmd:global} if you are referring to a global macro defined by your program
and strip the leading {cmd:$} from it. For instance, if your program saves $S_1
for future reference, you need to specify {cmd:result(global S_1)}.

{phang}
{opt saving(filename)} saves the results of various patterns of factor
substitution in the call to the external program to {it:filename}. You would
need this file for a hierarchical Shapley-Owen decomposition, where a different
set of weights is to be used.

{phang}
{opt storing(filename)} saves the marginal differences of the factor exclusions
to {it:filename}.

{phang}
{opt title(text)} allows you to add to the output the name of the statistic
you are decomposing.


{title:Remarks}

{pstd}
Elements in {it:factor_list} of the form {it:name}{cmd:(}{it:varlist}{cmd:)} are
used for specifying multiple variables, for example

{phang}. fracgen weight -2 -1{p_end}
{phang}. shapley2 fp_weight(weight_1 weight_2) foreign i.rep78 mpg length, result(e(r2)):regress price @{p_end}

{pstd}
This would assess the joint effect of the transformed variables
{cmd:weight_1 weight_2} on the explained variation, labelling the output for these
variables as {cmd:fp_weight}. Note that {cmd:fp_weight} need not be an actual
variable. The command would also assess the joint effect of the
levels of the categorical variable {cmd:rep78}.


{title:Tips}

{phang}
1. Since {cmd:shapley2} can be computationally intensive, you might
   consider writing your own simplified and thus faster versions of standard or
   contributed programs, or dropping unnecessary observations before running
   {cmd:shapley2}.
{p_end}

{phang}
2. {it:call_to_program} {cmd:@} [{cmd:,} {it:call_options} might in fact
   be any valid Stata statement, where {cmd:@} would be substituted
   with the current pattern of factors: do-file, ado-file, built-in command,
   whatever, and {cmd:@} may be among options, as well. It is your
   responsibility to use these patterns appropriately, and to supply
   non-missing returned values to {cmd:shapley2}. A returned missing value
   is likely to crash {cmd:shapley2} at some point.
{p_end}

{phang}
3. No standard errors for factor contributions have been provided so far.
   A reasonable thing to do would be to bootstrap your data; see
   {help bootstrap}. Doing so, however, would result in even more
   computationally intensive calculations...
{p_end}


{title:Saved results}

{pstd}
{cmd:shapley2} saves the following:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(decompos)}}the Shapley decomposition results, by factor{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(varlist)}}list of variables comprising the model{p_end}
{synopt:{cmd:r(factors)}}list of variables comprising the factors{p_end}
{synopt:{cmd:r(call)}}call statement including {cmd:@}{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Files}{p_end}
{syntab :{opt saving()} option}
{synopt:{cmd: __ID}}binary representation of 0/1 pattern{p_end}
{synopt:{cmd: __result}}the corresponding result{p_end}
{synopt:{cmd: __round}}number of 1s in the pattern; round of exclusion = #factors - it{p_end}

{syntab :{opt storing()} option}
{synopt:{cmd: __factor}}the name of the factor{p_end}
{synopt:{cmd:__fno}}the number of the factors in the list{p_end}
{synopt:{cmd:__from}}the pattern of the parent node{p_end}
{synopt:{cmd:__to}}the pattern of the successor node{p_end}
{synopt:{cmd:__stage}}stage of exclusion: 0 = nothing excluded;
# = factors when all excluded{p_end}
{synopt:{cmd:__weight}}the number of trajectories passed through{p_end}
{synopt:{cmd:__diff}}the marginal difference{p_end}
{synoptline}
{p2colreset}{...}


{title:Examples}

{phang}{stata sysuse auto}{p_end}
{phang}{stata replace price = price/1000}{p_end}
{phang}
{stata "shapley2 weight i.foreign i.rep78 mpg length, result(e(r2)):regress price @"}
{p_end}

        Shapley decomposition


     Factors | 1st round |  Shapley  
             |  effects  |   value   
    ---------+-----------+-----------
    weight   |    .2901  |    .2473  
    foreign  |  .002374  |  .092834  
    rep78    |  .014495  |  .025609  
    mpg      |   .21958  |  .086631  
    length   |   .18648  |   .11039  
    ---------+-----------+-----------
    Residual |  -.15027  |
    ---------+-----------+-----------
       Total |   .56276  |   .56276  


{pstd}
This sequence performs the Shapley value decomposition of the explained
variance from the regression model of price on weight, foreign, rep78, mpg and
length variables. The scaling of price is done to make output more
readable. The first-round effects are obtained for the factor on its own,
compared with the null model.

{pstd}
(In fact, the original aim of the Shapley decomposition was to isolate the
effects of various sources of income on the income inequality indices.
Detailed examples with the do-files and dta-files are available upon
request.)


{title:Authors and Acknowledgment}

{pstd}
Theoretical foundation: Tony Shorrocks, shora@essex.ac.uk{break}
Old draft is available at http://www.komkon.org/~tacik/science/shapley.pdf

{pstd}
Implementation:{break}
Stas Kolenikov, University of Missouri; kolenikovs@missouri.edu{break}
Patrick Royston, MRC Clinical Trials Unit, London; pr@ctu.mrc.ac.uk

{pstd}
Stata stuff: net from http://www.komkon.org/~tacik/stata/


{title:Reference}

{phang}
Shorrocks AF. 2012. Decomposition procedures for distributional analysis: a
unified framework based on the Shapley value. Published online, Jan 2012,
Journal of Economic Inequality; DOI 10.1007/s10888-011-9214-z.
