{smcl}
{* 05feb2009}{...}
{cmd:help pmbeval}, {cmd:help pmbevalfn}, {cmd:help pmbstabil}{right: ({browse "http://www.stata-journal.com/article.html?article=st0177":SJ9-4: st0177})}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{hi:pmbeval} {hline 2}}Evaluate fractional polynomial functions and stability measures{p_end}
{p2colreset}{...}

{title:Syntax}

{phang}{it:First syntax}{p_end}
{p 8 14 2}
{cmd:pmbeval} {ifin}{cmd:,}
{cmd:clear}
{cmdab:r:awdata(}{it:filename}{cmd:)}
{cmdab:x:var:(}{it:xvarname}{cmd:)}
[{cmdab:c:entiles:(}{it:numlist}{cmd:)}
{cmdab:m:ean}
{cmdab:s:d}
{cmd:n}
{cmdab:st:andardize}]


{phang}{it:Second syntax}{p_end}
{p 8 14 2}
{cmd:pmbeval} {ifin}{cmd:,}
{cmdab:sav:ing(}{it:newfilename}{cmd:)}
{cmdab:r:awdata(}{it:filename}{cmd:)}
{cmdab:x:var:(}{it:xvarname}{cmd:)}
[{cmdab:st:andardize}]


{phang2}
{cmd:pmbevalfn} {ifin}{cmd:,}
{cmd:clear}
{cmdab:r:awdata(}{it:filename}{cmd:)}
[{cmdab:st:andardize}]


{phang2}
{cmd:pmbstabil} {ifin}{cmd:,}
[{cmd:by(}{it:varname}{cmd:)}
{cmdab:c:onditional}
{opt tr:unc(#)}]


{pstd}
You must load a file of results created by {helpb mfpboot}
before using {cmd:pmbeval}
or {cmd:pmbevalfn}.  {cmd:pmbstabil} requires that you load
the dataset {it:newfilename} created by {cmd:pmbeval} (second syntax).


{title:Description}

{pstd}
These programs compute fitted fractional polynomial (FP) functions and
stability measures following the use of {helpb mfpboot}.
A "replication" denotes a bootstrap sample.

{pstd}
{cmd:pmbeval} (first syntax) evaluates the FP function
of the covariate {it:xvarname} for each available replication and saves the
results to the workspace, replacing the current data. The values of
{it:xvarname} are read from {it:filename} and are also saved to the workspace.
The resulting data are suitable for plotting the fitted functions.

{pstd}
{cmd:pmbeval} (second syntax) evaluates the FP function of the covariate
{it:xvarname} for each available replication and saves the results to
{it:newfilename}. The values of {it:xvarname} are read from {it:filename}. The
data saved in {it:newfilename} are in a format suitable for stability analysis
using {helpb pmbstabil} but are not intended for plotting.

{pstd}
{cmd:pmbevalfn} evaluates the linear predictor for the model from each
replication and saves the results to the workspace, replacing the
current data. The current data are the contents of the file
created by {cmd:mfpboot}, which must be loaded first.
The values of the covariates are supplied in {it:filename}.
Usually, {it:filename} is the file holding the data on which
{cmd:mfpboot} was originally run, although another file
may be used instead if it contains appropriate data.

{pstd}
{cmd:pmbstabil} computes instability measures V, D^2, T, and R^2 for a 
continuous covariate for which the fitted values were created by
{cmd:pmbeval} (second syntax) and which have been loaded into the workspace.

{pstd}
See {it:{help pmbeval##remarks:Remarks}} for further details.


{title:Options for pmbeval (first syntax)}

{phang}
{cmd:clear} is required and signifies willingness for the data in the
workspace to be replaced.

{phang}
{cmd:rawdata(}{it:filename}{cmd:)} is required and specifies the name
of the file that holds the desired values of {it:xvarname}.
This file is typically the original data file used with
{cmd:mfpboot}, but it need not be.

{phang}
{cmd:xvar(}{it:xvarname}{cmd:)} is required and specifies the name of the
covariate whose function is to be evaluated.

{phang}
{cmd:centiles(}{it:numlist}{cmd:)} calculates and saves centiles
of the fitted curves across replications at the observed values
of {it:xvarname}. The required centiles are listed in {it:numlist}.

{phang}
{cmd:mean} calculates and saves the mean of the fitted curves across
replications at the observed values of {it:xvarname}.

{phang}
{cmd:sd} calculates and saves the standard deviation of the fitted curves across
replications at the observed values of {it:xvarname}.

{phang}
{cmd:n} calculates and saves the frequencies of the observed values of
{it:xvarname}.

{phang}
{cmd:standardize} standardizes the fitted values for each curve to have mean
zero.


{title:Options for pmbeval (second syntax)}

{phang}
{opt saving(newfilename)} is required and specifies the name of
a new file to hold values of {it:xvarname} and its fitted functions
suitable for stability analysis using {cmd:pmbstabil}.
If {it:newfilename} already exists, it is replaced without warning.

{phang}
{opt rawdata(filename)} is required and specifies the name
of the file that holds the desired values of {it:xvarname}.
This file is typically the original data file used with
{cmd:mfpboot}, but it need not be.

{phang}
{cmd:xvar(}{it:xvarname}{cmd:)} is required and specifies the name of the
covariate whose function is to be evaluated.

{phang}
{cmd:standardize} standardizes the fitted values for each curve to have mean
zero.


{title:Options for pmbevalfn}

{phang}
{cmd:clear} is required and signifies willingness for the data in the
workspace to be replaced.

{phang}
{cmd:rawdata(}{it:filename}{cmd:)} is required and specifies the name
of the file that holds the desired values of {it:xvarname}.  This file is
typically the original data file used with {cmd:mfpboot}, but it need not be.

{phang}
{cmd:standardize} standardizes each linear predictor to have mean zero.


{title:Options for pmbstabil}

{phang}
{cmd:by(}{it:varname}{cmd:)} reports instability measures for two complementary
subsets of the bootstrap replications:{p_end}

{p 8 8 2}1. Replications in which {it:varname} has nonzero,
nonmissing values;{p_end}

{p 8 8 2}2. Replications in which {it:varname} is
either zero or missing.   

{phang}
{cmd:conditional} calculates instability measures conditional on {it:xvarname}
entering the model.  The default is to compute unconditional measures assuming
that f({it:xvarname}) = 0 when {it:xvarname} does not enter.

{phang}
{opt trunc(#)} specifies that 100*{it:#}% of the most extreme observations be
dropped.  {it:#} can be 0 or less than 1.  The default is {cmd:trunc(0)}.


{marker remarks}{...}
{title:Remarks}

{pstd}
The current dataset is envisaged as the output file from a bootstrap or
simulation investigation, which generates B replications (rows of the file).
Such a file must be created using {helpb mfpboot}.  Each
row contains several variables corresponding to each covariate in the original
analysis. These covariates are called {it:xvarname}{cmd:p1} and
{it:xvarname}{cmd:p2} (i.e., FP powers) and {it:xvarname}{cmd:b1} and
{it:xvarname}{cmd:b2} (the corresponding regression coefficients). A term fit
as linear in the model will have just two variables: {it:xvarname}{cmd:p1}
taking on the value 1 and {it:xvarname}{cmd:b1} being the regression
coefficient. If a constant term has been fit, its presence is recognized by the
existence of a variable called {cmd:b0}.

{pstd}
{cmd:pmbstabil} expects that the current data is in an appropriate
format, as indicated by its characteristics stored in {cmd:char _dta[pb_x]},
{cmd:char _dta[pb_v]}, and {cmd:char _dta[pb_f]}. It also expects to find the
raw data in the file indicated by {cmd:char _dta[pmb_fn]}.  The data contain
the fitted values for a given predictor, stored rowwise; that is, the first
row contains the fitted curve from the first replication, the second row
contains the fitted curve from the second replication, and so on. The variables
in the file correspond to the unique values of the predictor.


{title:Examples}

{phang}{cmd:. use rawdata}{p_end}
{phang}{cmd:. mfpboot regress y x1 x2 x3, saving(bootresults) rep(200) basedata select(0.05)}

{phang}{cmd:. use simdata}{p_end}
{phang}{cmd:. mfpboot regress y x1 x2 x3, saving(simresults) select(0.05)}

{phang}{cmd:. use bootresults, clear}{p_end}
{phang}{cmd:. pmbeval, clear xvar(x1) rawdata(rawdata) standardize}{p_end}
{phang}{cmd:. graph twoway line v1-v20 x1, legend(off)}

{phang}{cmd:. use simresults, clear}{p_end}
{phang}{cmd:. pmbeval, clear xvar(x1) rawdata(rawdata) standardize centiles(10 90) mean}{p_end}
{phang}{cmd:. graph twoway line _mean _c1 _c2 x1}

{phang}{cmd:. use bootresults, clear}{p_end}
{phang}{cmd:. pmbevalfn, clear rawdata(rawdata) standardize}{p_end}

{phang}{cmd:. use bootresults, clear}{p_end}
{phang}{cmd:. pmbeval, saving(x1fn) xvar(x1) rawdata(rawdata) standardize}{p_end}
{phang}{cmd:. use x1fn, replace}{p_end}
{phang}{cmd:. pmbstabil}{p_end}
{phang}{cmd:. pmbstabil, by(x2i)}{p_end}
{phang}{cmd:. pmbstabil, conditional}


{title:Author}

{pstd}
Patrick Royston, MRC Clinical Trials Unit, London{break}
pr@ctu.mrc.ac.uk


{title:Also see}

{psee}
Article: {it:Stata Journal}, volume 9, number 4: {browse "http://www.stata-journal.com/article.html?article=st0177":st0177}{p_end}

{psee}
Manual:  {manlink R mfp}

{psee}
Online:  {manhelp mfp R}, {manhelp fracpoly R}, {helpb mfpboot}
{p_end}
