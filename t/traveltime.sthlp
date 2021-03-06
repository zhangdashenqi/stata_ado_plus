{smcl}
{* 12jul2010}{...}
{cmd:help traveltime}{right: ({browse "http://www.stata-journal.com/article.html?article=dm0053":SJ11-1: dm0053})}
{hline}

{title:Title}

{p2colset 5 19 21 2}{...}
{p2col :{hi:traveltime} {hline 2}}Find travel time between points using Google Maps{p_end}
{p2colreset}{...}


{title:Syntax}
{p 8 17 2}
{cmd:traveltime}{cmd:,}
{cmd:start_x(}{it:varname}{cmd:)}
{cmd:start_y(}{it:varname}{cmd:)} 
{cmd:end_x(}{it:varname}{cmd:)} 
{cmd:end_y(}{it:varname}{cmd:)}  
[{cmd:mode(}{it:varname}{cmd:)}
{cmd:km}]


{title:Description} 

{p 4 4 2} {cmd:traveltime} uses Google Maps to generate travel time
and calculate distance between sets of points.  {cmd:start_x()},
{cmd:start_y()}, {cmd:end_x()}, and {cmd:end_y()} contain the latitude and
longitude of the origin and destination points, in decimal degrees.  Choice of
travel
mode can also be specified with the {cmd:mode()} option.

{p 4 4 2} {cmd:traveltime} generates the variables {cmd:days},
{cmd:hours}, {cmd:mins}, and {cmd:traveltime_dist}. The first three variables
correspond to the number of days, hours, and
minutes it takes to travel between the origin and destination.  For example,
if the travel time between origin and destination is 1 day, 7 hours, and 37
mins, the values for {cmd:days}, {cmd:hours}, and {cmd:mins} would be 1, 7, and
37, respectively.  The variable {cmd:traveltime_dist} is the distance between
the sets of points.  The {cmd:traveltime_dist} will be reported in miles
unless the kilometers ({cmd:km}) option is specified.


{title:Options}

{phang} {cmd:start_x(}{it:varname}{cmd:)} specifies the variable containing
the geocoded x coordinate of the starting point.  {cmd:start_x()} is
required.

{phang} {cmd:start_y(}{it:varname}{cmd:)} specifies the variable containing
the geocoded y coordinate of the starting point.  {cmd:start_y()} is required.

{phang} {cmd:end_x(}{it:varname}{cmd:)} specifies the variable containing
the geocoded x coordinate of the destination.  {cmd:end_x()} is required.

{phang} {cmd:end_y(}{it:varname}{cmd:)} specifies the variable containing
the geocoded y coordinate of the destination.  {cmd:end_y()} is required.

{phang} {cmd:mode(}{it:varname}{cmd:)} specifies the mode choice of the trip.
The values are set to {cmd:1} for car, {cmd:2} for public transportation, and {cmd:3} for
walking.  The default mode is car.

{phang} {cmd:km} specifies that {cmd:traveltime_dist} be reported in
kilometers rather than in miles (the default).


{title:Note and warning} 

{p 4 4 2} {cmd:traveltime} requires that the latitude and longitude of the
origin and destination points be in decimal degrees.  This task can be
accomplished using the {cmd:geocode} command.

{p 4 4 2}Google Maps has a daily limit of maximum queries that is not
currently known.  If you use {cmd:traveltime}, you should use it in accordance
with Google's terms of use.  For more information on the terms of service of Google
Maps, see {browse "http://code.google.com/apis/maps/terms.html"}.


{title:Example}

{phang}{cmd:. traveltime, start_x(begin_long) start_y(begin_lat) end_x(end_long) end_y(end_lat) mode(autochoice)}{p_end} 


{title:Authors}

{pstd}Adam Ozimek{p_end}
{pstd}Econsult Corporation{p_end}
{pstd}Philadelphia, PA{p_end}
{pstd}ozimek@econsult.com{p_end}
      
{pstd}Daniel Miles{p_end}
{pstd}Econsult Corporation{p_end}
{pstd}Philadelphia, PA{p_end}
{pstd}miles@econsult.com{p_end}
    

{title:Also see}

{p 4 14 2}Article:  {it:Stata Journal}, volume 11, number 1: {browse "http://www.stata-journal.com/article.html?article=dm0053":dm0053}

{p 4 14 2}{space 3}Help:  {helpb geocode} (if installed){p_end}
