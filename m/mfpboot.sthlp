{smcl}
{* 08sep2009}{...}
{cmd:help mfpboot}{right: ({browse "http://www.stata-journal.com/article.html?article=st0177":SJ9-4: st0177})}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{hi:mfpboot} {hline 2}}Bootstrap stability analysis of multivariable fractional polynomial (MFP) models{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 14 2}
{cmd:mfpboot,} {it:mfpboot_options}
	[{it:{help mfp:mfp_options}}]{cmd::} 
	{it:{help mfpboot##reg_cmd:regression_cmd}}
	[{it:{help mfpboot##yvar:yvar1}} [{it:{help mfpboot##yvar:yvar2}}]]
	{it:{help mfpboot##xvarlist:xvarlist}}
	{ifin}
	{weight}
	[{cmd:,} {it:{help mfpboot##reg_cmd_opts:regression_cmd_options}}]

{synoptset 26 tabbed}{...}
{synopthdr:mfpboot_options}
{synoptline}
{p2coldent :* {opt clear}}allow the data in the current workspace to be replaced{p_end}
{p2coldent:* {opt out:file(outfilename)}}specify the name of
the new file to be created holding the summaries of the bootstrapped MFP models{p_end}
{synopt :{opt keep:also(varlist)}}save additional {it:varlist} variables to {it:datafilename}{p_end}
{synopt :{opt nodry:run}}suppress the dry run of {cmd:mfp}{p_end}
{synopt :{opt replace}}allow {it:outfilename} to be replaced{p_end}
{synopt :{opt rep:licates(#)}}determine the number of bootstrap replicates{p_end}
{synopt :{opt sav:ing(datafilename)}}save bootstrap data to {it:datafilename}{p_end}
{synopt :{opt see:d(#)}}set the random-number seed{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* {cmd:clear} and {cmd:outfile()} are required.{p_end}

{p 4 6 2}
See {helpb mfp} for available {it:mfp_options}.{p_end}

{marker reg_cmd}{...}
{p 4 6 2}
{it:regression_cmd} may be
{helpb clogit},
{helpb cnreg},
{helpb glm},
{helpb intreg}, 
{helpb logistic},
{helpb logit},
{helpb mlogit},
{helpb nbreg},
{helpb ologit},
{helpb oprobit},
{helpb poisson},
{helpb probit},
{helpb qreg},
{helpb regress},
{helpb rreg},
{helpb stcox},
{helpb stcrreg},
{helpb streg},
or
{helpb xtgee}.

{marker yvar}{...}
{p 4 6 2}
{it:yvar1} is not allowed for {opt stcox}, {opt stcrreg}, and {opt streg}.
For these commands, you must first {helpb stset} your data.
{it:yvar1} and {it:yvar2} must both be specified when {it:regression_cmd} is
{opt intreg}.

{marker xvarlist}{...}
{p 4 6 2}
{it:xvarlist} has elements of type {varlist} or {opt (varlist)};
e.g.,

{pin2}
{cmd:x1 x2 (x3 x4 x5)}

{p 6 6 2}
Elements enclosed in parentheses are tested jointly for inclusion in the
model and are not eligible for fractional polynomial (FP) transformation.

{p 4 6 2}
All weight types supported by {it:regression_cmd} are allowed; see
{help weight}.

{marker reg_cmd_opts}{...}
{p 4 6 2}
{it:regression_cmd_options} are options appropriate to {it:regression_cmd}.


{title:Description}

{pstd}
{cmd:mfpboot} creates bootstrap estimates of multivariable fractional
polynomial (MFP) models, subject to selection of predictors in
{it:xvarlist} or functions thereof. It also fits the MFP model
on the original data and saves the results as "bootstrap replication
number 0".


{title:Note on Stata 11}

{pstd}
The syntax of {cmd:mfp} changed between Stata 10 and Stata 11. Specifically,
{cmd:mfp} became a "colon" (or prefix) command, and for clarity,
the {opt adjust()} option was renamed to {opt center()}. {cmd:mfpboot}
generates a command with the "old" form
of {cmd:mfp} syntax -- i.e., without the prefix structure and using the
{opt adjust()} option -- and issues that to run {cmd:mfp}. Because {cmd:mfp} in
Stata 11 still recognizes the earlier syntax, no difficulty ensues. 
{cmd:mfpboot} accepts {opt center()} as one of the valid {it:mfp_options} and
converts it to {opt adjust()} internally.


{title:Options}

{phang}
{cmd:clear} is required and signifies willingness for the data in the
workspace to be replaced.

{phang}
{cmd:outfile(}{it:outfilename}{cmd:)} is required and specifies the name of
the new file to be created holding the summaries of the MFP model from
each bootstrap replicate. If {it:outfilename}{cmd:.dta} exists, an error is
raised unless the {cmd:replace} option is used to allow the file to be
replaced.

{phang}
{cmd:keepalso(}{it:varlist}{cmd:)} causes the variables in {it:varlist}
to be stored in the file specified by {cmd:saving()}, along with the
standard variables stored there. See also the {cmd:saving()} option.

{phang}
{cmd:nodryrun} prevents {cmd:mfpboot} from doing a test run of the {cmd:mfp}
command. By default, a test run is done before the bootstrap procedure starts.
The aim is to detect syntax errors or other issues in the underlying {cmd:mfp}
command.  It is strongly recommended that you do not skip this check.
Once the {cmd:mfp} command is working on the original data, the production run
of {cmd:mfpboot} can be done with the {cmd:nodryrun} option.

{phang}
{cmd:replace} allows {it:outfilename}{cmd:.dta} to be overwritten if it already exists.

{phang}
{cmd:replicates(}{it:#}{cmd:)} sets the number of bootstrap replicates to
{it:#}.  If {it:#} = 0, then only results from the model for the original data
are saved.  The default is {cmd:replicates(100)}.

{phang}
{cmd:saving(}{it:datafilename}{cmd:)} saves the bootstrap samples 
to a new file called {it:datafilename}. By default, only
{it:yvar1} [{it:yvar2}] and {it:xvarlist} (and if Cox regression is used,
{it:deadvar}) are saved, but see the {cmd:keepalso()} option for how to extend
the list of saved variables.

{phang}
{cmd:seed(}{it:#}{cmd:)} sets the random-number seed to {it:#}. This option 
is intended to ensure reproducibility of the bootstrap samples.


{title:Remarks}

{pstd}
The coefficients and powers for FP2 functions of a member,
{it:xvar}, of {it:xvarlist} saved to
{it:newfilename} are named {it:xvar}{cmd:p1}, {it:xvar}{cmd:p2},
{it:xvar}{cmd:b1}, and {it:xvar}{cmd:b2}.  The constant is named {cmd:b0}.

{pstd}
{cmd:mfpboot} detects collinearities that manifest as a missing regression
coefficient for a variable whose power has apparently been estimated. The
variable is treated as dropped; that is, its power(s) and regression
coefficient(s) are set to missing. The program does not alert you that this has
happened.


{title:Examples}

{phang}{cmd:. sysuse auto}

{phang}{cmd:. mfpboot, clear outfile(boot) replicates(200) alpha(1): regress mpg weight}

{phang}{cmd:. mfpboot, clear outfile(boot) replicates(200) select(.05): regress mpg weight displ foreign}

{phang}{cmd:. mfpboot, clear outfile(boot) replicates(1000) df(2): regress mpg weight displ}

{phang}{cmd:. mfpboot, clear outfile(boot) replicates(100) saving(bootdata): regress mpg weight}


{title:Author}

{pstd}
Patrick Royston, MRC Clinical Trials Unit, London{break}
pr@ctu.mrc.ac.uk


{title:Also see}

{psee}
Article: {it:Stata Journal}, volume 9, number 4: {browse "http://www.stata-journal.com/article.html?article=st0177":st0177}{p_end}

{psee}
Manual:  {manlink R mfp}, {manlink R fracpoly}

{psee}
Online:  {manhelp fracpoly R}, {manhelp mfp R}, {helpb pmbeval},
 {manhelp bootstrap R}
{p_end}
