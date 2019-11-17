{smcl}
{* *! version 3.0.0  22may2017}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col :{hi:tftools} {hline 2}}Various financial technical analysis tools{p_end}

{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:tftools} {it:subcommand} [if] [in] [{cmd:,} {it:options}]

{synoptset 16}{...}
{synopthdr:subcommand}
{synoptline}
{synopt :{helpb tftools movingaverage:movingaverage}}moving averages including sma, ema, sd, sum, min and max{p_end}
{synopt :{helpb tftools bollingerbands:bollingerbands}}Bollinger bands including upper, lower and middle bands{p_end}
{synopt :{helpb tftools macd:macd}}Moving average conversion and diversion{p_end}
{synopt :{helpb tftools rsi:rsi}}Relative strength index{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tftools} calculates four most popular financial technical analysis tools.
These tools include, moving averages, Bollinger bands, MACD and RSI. 
A time series variable is required for the technical analysis tools. 
{p_end}

{title:Authors}
{pstd}{hi:Mehmet F. Dicle}, Loyola University New Orleans, USA ({hi:mfdicle@gmail.com}){p_end}
{pstd}{hi:John Levendis}, Loyola University New Orleans, USA{p_end}
