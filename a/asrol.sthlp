{smcl}
{* 31Aug2015}{...}
{cmd:help asrol}{right:version:  1.0.0}
{hline}

{title:Title}

{p 4 8}{cmd:asrol}  -  Generates rolling-window descriptive statistics in time series or panel data {p_end}


{title:Syntax}

{p 4 6 2}
{cmd:asrol}
varlist [if] [in] {cmd:,} {cmdab:g:en(}{it:newvar}{cmd:)}
{cmdab:s:tat(}{it:statistic}{cmd:)}
{cmdab:w:indow(}{it:#}{cmd:)[}
{cmdab:n:omiss}{cmd:)}
{cmdab:min:mum(}{it:#}{cmd:)]}

{p 4 4 2}
The underlined letters signifies that user can abbreviate the full words only to the underlined letters. {p_end}



{title:Description}

{p 4 4 2} This program calculates descriptive statistics in a user's defined rolling-window.{break}
For example, in time series or panel data, a user might be interested in knowing standard deviation {break}
or coefficient of variation of a variable in a rolling window of last 4 years. {help asrol} provides {break}
efficient and simple way of finding such statistics. It also offers various options to specify minimum {break}
number of observations required for calculation of desired statistics in a rolling window. {p_end}



{title:Syntax Details}

{p 4 4 2}
The program has 3 required options: They are {break}
1. {opt g:en} : to generate new variable, where the variable name is enclosed in paranthesis after {opt g:en} {break}
2. {opt s:tat}: to specify required statistics. The following statistics are allowed; {p_end}

{p 8 8 4} {opt sd }    : for standard deviation {p_end}
{p 8 8 2} {opt mean }  : for mean {p_end} 
{p 8 8 2} {opt total}  : for sum or total {p_end}
{p 8 8 2} {opt median} : for median {p_end}
{p 8 8 2} {opt pctile} : for percentiles {p_end}
 
{p 4 4 2} 3. {opt w:indow} is to specify the length of rolling window for calculation of the {break}
required statistics. The length of window should be less than or equal to the total number {break}
of time-series observations per panel. {p_end}


{title:Other Options}

{p 4 4 2} 
1. {opt n:miss} {break}
 The option {opt n:omiss} forces {help asrol} to find required statistics with all available {break}
 observations, which results in no missing values at the start of the panel. Compare results {break}
 of {opt Example 1} below where n is not used with the results of the {opt Example 3} where n is used. {break}
 In the example 1, {help asrol} finds mean starting with the fourth observation of each panel, i.e. {break}
 the rolling window does not start working unless it reaches the required level of 4 observations. {p_end}
 
 {p 4 4 2} 
 2. {opt  min:mum} {break}
 The option {opt min:mum} forces {help asrol} to find required statistics where the minimum {break}
 number of observations are available. If a specific rolling window does not have that many {break}
 observations, values of the new variable will be replaced with missing values. {p_end}
 

{title:Example 1: Find Rolling Mean}
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "asrol invest, stat(mean) win(4) gen(mean_4) " :. asrol invest, stat(mean) win(4) gen(mean_4) } {p_end}

{p 4 8 2} This command calculates mean for the variable invest using a four years rolling window {break}
and stores the results in a new variable called mean_4. 


 {title:Example 2: Find Rolling Standard Deviation} 
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "asrol invest, stat(sd) win(6) gen(sd_6) " :. asrol invest, stat(sd) win(6) gen(sd_6)} {p_end}
 
 {p 4 8 2} This command calculates standard deviation for the variable invest {break}
   using a six years rolling window and stores the results in a new variable called sd_6 {p_end}

 {title:Example 3:  For Rolling Mean with no missing values} 
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "asrol invest, stat(mean) win(4) gen(sd_4) nomiss " :. asrol invest, stat(mean) win(4) gen(sd_4) nomiss } {p_end}
 
{p 4 4 2}
 This command calculates mean for the variable invest using a four years {break}
 rolling window and stores the results in a new variable called mean_4. The {opt n:omiss} option {break}
 forces asrol to find mean with all available observation, which results in no missing {break}
 values at the start of the panel. Compare results where {opt n:omiss} is not used in example 1 above. {break}
 In the example 1, {help asrol} finds mean starting with the fourth observation of each panel, i.e. {break}
 the rolling window does not start working unless it reaches the required level of 4 observations. {p_end}
 
 {title:Example 4:  Rolling mean with minimum number of observaton} 
 
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "asrol invest, stat(mean) win(4) gen(mean_4) min(3) " :. asrol invest, stat(mean) win(4) gen(mean_4) min(3) }

  {title:Example 5:  Rolling mean with minimum number of observaton including the start of the panel} 
 
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "asrol invest, stat(mean) win(4) gen(mean_4) min(3) nomiss " :. asrol invest, stat(mean) win(4) gen(mean_4) min(3) nomiss} {p_end}

 {p 4 4 2}
 This command forces calculates mean for the variable invest using a four years {break}
 rolling window and stores the results in a new variable called mean_4. The {opt n} option {break}
 and the {opt min(3)} force asrol to find mean with at least 3 available observations {break}
 even at the start of each panel i.e. {help asrol} will not wait until 4 observations are {break}
 are available, it will start calculation when at least three observations are available. {p_end}


{title:Author}

{p 4 8 2} 

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: *
*                                                                             *
*                       Dr. Attaullah Shah                                    *
*            Institute of Management Sciences, Peshawar, Pakistan             *
*                     Email: attaullah.shah@imsciences.edu.pk                 *
*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*


{marker also}{...}
{title:Also see}

{psee}
{help rolling}, {help tssmooth}, {stata "ssc desc mvsumm":mvsumm}, {stata "ssc desc tsegen":tsegen}
{p_end}







