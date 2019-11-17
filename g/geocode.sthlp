{smcl}
{* 12jul2010}{...}
{cmd:help geocode}{right: ({browse "http://www.stata-journal.com/article.html?article=dm0053":SJ11-1: dm0053})}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{hi:geocode} {hline 2}}Geocode addresses using Google Geocoding API{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:geocode}{cmd:,} 
[{cmd:address(}{it:varname}{cmd:)}
{cmd:city(}{it:varname}{cmd:)} 
{cmd:state(}{it:varname}{cmd:)} 
{cmd:zip(}{it:varname}{cmd:)} {cmd:fulladdr(}{it:varname}{cmd:)}]
 
{pstd}See {help geocode##remarks:{it:Remarks}} for details on specifying
options.

 
{title:Description} 

{p 4 4 2} {cmd:geocode} uses Google Geocoding API to geocode addresses and
calculate latitudes and longitudes.

{p 4 4 2} The {cmd:geocode} command generates four new variables:
{cmd:geocode}, {cmd:geoscore}, {cmd:latitude}, and {cmd:longitude}.  The
{cmd:geocode} variable contains a numerical indicator of geocoding success or
type of failure, and {cmd:geoscore} provides a measure of accuracy.
{cmd:latitude} and {cmd:longitude} contain the geocoded coordinates for each
observation in decimal degrees.  


{title:Options}

{phang} {cmd:address(}{it:varname}{cmd:)} specifies the variable containing a
street address.  {it:varname} must be a string.  Cleaned address names will
provide better results, but the program performs some basic cleaning.

{phang} {cmd:city(}{it:varname}{cmd:)} specifies the variable containing
the name or common abbreviation for the city, town, county, metropolitan
statistical area, or equivalent.  {it:varname} must be a string.

{phang} {cmd:state(}{it:varname}{cmd:)} specifies the variable containing
the name or the two-letter abbreviation of the state of the observation.  An
example of such an abbreviation is Pa for Pennsylvania.  {it:varname} must be a
string.

{phang} {cmd:zip(}{it:varname}{cmd:)} specifies the variable
containing the standard United States Postal Service 5-digit postal zip code
or zip code +4.  If zip code +4 is specified, it should be in the form
12345-6789.  {it:varname} must be a string.

{phang} {cmd:fulladdr(}{it:varname}{cmd:)} allows users to specify all or
some of the above options in a single string.  {it:varname} must be a string
and should be in a format that would be used to enter an address using
{browse "http://maps.google.com"}.


{marker remarks}{...}
{title:Remarks}

{pstd}When geocoding within the United States, one or all of the options
{cmd:address(}{it:varname}{cmd:)}, {cmd:city(}{it:varname}{cmd:)},
{cmd:state(}{it:varname}{cmd:)}, and {cmd:zip(}{it:varname}{cmd:)} may be
specified, with more information allowing for a higher degree of geocoding
detail.  This allows for the geocoding of zip codes, counties, cities, or other
geographic areas.  In general, when a specific street address is not specified,
a latitude and longitude will be provided for a central location within the
specified city, state, or zip code.  The same option for specifying geographic
detail applies using {cmd:fulladdr()}.

{pstd}When geocoding outside the United States, the {cmd:fulladdr()} option
must be used and the country must be specified.  When inputting data using
{cmd:fulladdr()}, any string that would be usable with 
{browse "http://maps.google.com"} is in an acceptable format.  Acceptable
examples for {cmd:fulladdr()} in the United States include but are not limited
to these formats:

{pin}"street address, city, state, zip code"{p_end}
{pin}"street address, city, state"{p_end}
{pin}"city, state, zip code"{p_end}
{pin}"city, state"{p_end}
{pin}"state, zip code"{p_end}
{pin}"state"{p_end}

{pstd}Acceptable examples for {cmd:fulladdr()} outside the United States
include but are not limited to these formats:

{pin}"street address, city, state, country"{p_end}
{pin}"street address, city, country"{p_end}
{pin}"city, state, country"{p_end}
{pin}"city, country"{p_end}

{pstd}Country should be specified using the full country name.  State can be
whatever regional entity exists below the country level -- for instance,
Canadian provinces or Japanese prefectures.  Again, format acceptability may be
gauged using the Google Maps website.

{pstd}The {cmd:geocode} command queries Google Maps, which allows for a fair
degree of tolerance in how addresses can be entered and still be geocoded
correctly.  The inputs are not case sensitive and are robust to a wide range
of abbreviations and spelling errors.  For instance, each of the following
would be an acceptable way to enter the same street address:

{pin}"123 Fake Street"{p_end}
{pin}"123 Fake St."{p_end}
{pin}"123 fake st"{p_end}

{pstd}Common abbreviations for cities, states, towns, counties, and other
relevant geographies are also often acceptable.  For instance, it is fine to
use "Phila" for "Philadelphia", "PA" for "Pennsylvania",
"NYC" for "New York City", and "UK" for "United
Kingdom".  The program is also fairly robust to spelling errors; it is capable
of accepting "Allantown, PA" for "Allentown, PA".  It is
recommended that addresses be as accurate as possible to avoid geocoding
errors, but the program is as flexible as Google Maps.

{pstd}The {cmd:geocode} command generates four new variables: {cmd:geocode},
{cmd:geoscore}, {cmd:latitude}, and {cmd:longitude}.  {cmd:latitude} and
{cmd:longitude} contain the geocoded coordinates for each observation in
decimal degrees.  The {cmd:geocode} variable contains a numerical indicator of
geocoding success or type of failure, and {cmd:geoscore} provides a measure of
accuracy.  These values and their definitions are provided by Google Maps.  For
more information, see
{browse "http://code.google.com/apis/maps/documentation/geocoding/"}.


{title:geocode error definitions}

{pstd}200 = no errors{p_end}
{pstd}400 = incorrectly specified address{p_end}
{pstd}500 = unknown failure reason{p_end}
{pstd}601 = no address specified{p_end}
{pstd}602 = unknown address{p_end}
{pstd}603 = address cannot be geocoded due to legal or contractual reasons{p_end}
{pstd}620 = Google Maps query limit reached{p_end}

{p 4 4 2}For more information on codes, see
{browse "http://code.google.com/apis/maps/documentation/geocoding/":http://code.google.com/apis/maps/documentation/geocoding/}.


{title:geoscore accuracy levels}

{pstd}0 = unknown accuracy{p_end}
{pstd}1 = country-level accuracy{p_end}
{pstd}2 = region-level (state, province, prefecture, etc.) accuracy{p_end}
{pstd}3 = subregion-level (county, municipality, etc.) accuracy{p_end}
{pstd}4 = town-level (city, village, etc.) accuracy{p_end}
{pstd}5 = postal code-level (zip code) accuracy{p_end}
{pstd}6 = street-level accuracy{p_end}
{pstd}7 = intersection-level accuracy{p_end}
{pstd}8 = address-level accuracy{p_end}
{pstd}9 = premise-level (building name, property name, shopping center, etc.) accuracy{p_end}

{p 4 4 2}For more information on codes, see
{browse "http://code.google.com/apis/maps/documentation/geocoding/":http://code.google.com/apis/maps/documentation/geocoding/}.


{title:Note and warning}

{p 4 4 2}Google Maps has a daily limit of maximum geocode queries that is not
known.  If you use this command, you should use it in accordance with Google's
terms of use.  For more information on the terms of service of Google
Geocoding API, see {browse "http://code.google.com/apis/maps/terms.html":http://code.google.com/apis/maps/terms.html}.


{title:Examples}

{p 4 8 2}{cmd:. geocode, address(home_address) city(city_name) state(name_of_state) zip(numerical_zipcode)}{p_end} 
{p 4 8 2}{cmd:. geocode, fulladdr(full_address_string)}


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

{p 4 14 2}
Article:  {it:Stata Journal}, volume 11, number 1: {browse "http://www.stata-journal.com/article.html?article=dm0053":dm0053}

{p 4 14 2}
{space 3}Help:  {helpb traveltime} (if installed){p_end}
