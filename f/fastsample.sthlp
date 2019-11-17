{smcl}
{* *! version 13.0 27mar2014}{...}

{cmd:help fastsample}
{hline}

{title:Title}

{phang}
{bf:fastsample} {hline 2} Draw random sample (fast algorithm for Stata 13.0 or newer)

{title:Syntax}

{pstd}Sampling without replacement

{p 8 17 2}
{cmdab:fastsample} # {ifin} [, {opt count}]

{pstd}Sampling with replacement

{p 8 17 2}
{cmdab:fastbsample} {it:integer} {ifin}

{marker performance}{...}
{title:Performance gain}

{pstd}
The expected computation times for fastsample and fastbsample are strictly less
than the expected computation times for sample and bsample, for any population
size and any sample size. The performance gains of fastsample and fastbsample
relative to their counterparts increases greater than linearly with population
size.

{pstd}
For a population size of 10,000,000; sample size of 100,000; and 5 repetitions,
the computation times were benchmarked as:

{pin}
{opt sample}: 111.4 seconds 
{opt fastsample}: 3.4 seconds

{pin}
{opt bsample}: 211.5 seconds 
{opt fastbsample}: 1.0 seconds

{marker description}{...}
{title:Description}

{pstd}
{opt fastsample} and {opt fastbsample} draw random samples of the data in memory. 
{opt fastsample} draws samples without replacement, while {opt fastbsample} 
draws samples with replacement. These functions are substitutes to Stata's built-in functions 
{manhelp sample R} and {manhelp bsample R}, respectively. The below help documentation
is drawn from the documentation for {opt sample}.

{pstd}
For {opt fastsample}, the size of the sample to be drawn can be specified as a percentage or as a count:

{pin}
    {opt fastsample} without the {opt count} option draws a {it:#}%
    pseudorandom sample of the data in memory, thus discarding
    (100 - {it:#})% of the observations.

{pin}
    {opt fastsample} with the {opt count} option draws a {it:#}-observation
    pseudorandom sample of the data in memory, thus discarding {cmd:_N} - {it:#}
    observations.  {it:#} cannot be larger than {help _N}.

{pstd}
In either case, observations not meeting the optional {opt if} and {opt in}
criteria are dropt (sampled at 0%).

{pstd}
For {opt fastbsample}, the size of the sample to be drawn must be specified as a count.

{pstd}
If you are interested in reproducing results, you must first set the
random-number seed; see {manhelp set_seed R:set seed}.


{marker options}{...}
{title:Options}

{phang}
{opt count} specifies that {it:#} in {opt sample} {it:#} be
    interpreted as an observation count rather than as a percentage.  Typing
    {opt sample 5} without the {opt count} option means that a 5% sample be
    drawn; typing {opt sample 5, count}, however,
    would draw a sample of 5 observations.


{marker examples}{...}
{title:Examples}

    {hline}
    Setup
{phang2}{cmd:. webuse nlswork}

{pstd}Describe the data{p_end}
{phang2}{cmd:. describe, short}

{pstd}Draw a 10% sample{p_end}
{phang2}{cmd:. fastsample 10}

{pstd}Describe the resulting data{p_end}
{phang2}{cmd:. describe, short}

    {hline}
    Setup
{phang2}{cmd:. webuse bsample1, clear}

{pstd}Take bootstrap sample of size 200{p_end}
{phang2}{cmd:. fastbsample 200}{p_end}
    {hline}
	
{marker author}{...}
{title:Author}

{pstd}
Andrew Maurer
{p_end}
