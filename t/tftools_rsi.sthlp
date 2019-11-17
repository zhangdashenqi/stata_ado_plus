{smcl}
{* 22jun2017}{cmd:help tftools rsi}
{hline}

{title:Title}
{pstd}{hi:tftools rsi} {hline 2} Calculates the relative strength index (RSI) for a single time-series variable. {p_end}

{title:Syntax}
{pstd}{cmdab:tftools rsi [if] [in]}{cmd:, symbol({it: variable}) generate({it: newvar})}{p_end}

{title:Description}
{pstd}
{it:tftools rsi} calculates the relative strength index (RSI) for a single time-series variable.
{it:tftools rsi} creates a new variable: RSI14.
Calculation is based on the {it:tsset}.
{p_end}

{synoptset 16 tabbed}
{synopthdr}
{synoptline}
{synopt:{opt symbol}} is the variable that the RSI calculation is based upon (usually the stock symbol that contains the daily prices).{p_end}
{synopt:{opt generate}} is the new variable prefix for the calculated RSI values.{p_end}
{synoptline}

{title:Example}
{pstd}freduse SP500, clear{p_end}
{pstd}drop if SP500==.{p_end}
{pstd}drop date{p_end}
{pstd}rename daten date{p_end}
{pstd}gen obs=_n{p_end}
{pstd}tsset obs{p_end}
{pstd}tftools rsi if year(date)>2015, symbol(SP500) generate(SP500){p_end}
{pstd}twoway (line SP500_RSI date) if year(date)>2015{p_end}

{title:Authors}
{pstd}{hi:Mehmet F. Dicle}, Loyola University New Orleans, USA ({hi:mfdicle@gmail.com}){p_end}
{pstd}{hi:John Levendis}, Loyola University New Orleans, USA{p_end}
