{smcl}
{* *! version 1.0.0  24july2018}{...}
{viewerjumpto "Syntax" "nba2stata##syntax"}{...}
{viewerjumpto "Options" "nba2stata##options"}{...}
{viewerjumpto "Appendix" "nba2stata##appendix"}{...}
{title:Title}

{p 4 8 2}
{cmd:nba2stata} {hline 2} Import NBA datasets into Stata{p_end}
{...}


{marker syntax}{...}
{title:Syntax}

{phang}
Web scrape player statistics into Stata

{p 8 16 2}
{cmd:nba2stata} {cmdab:players:tats}
 {it:{help nba2stata##name_pattern_help:"name_pattern"}}
 [, {it:{help nba2stata##playerstats_options_tbl:playerstats_options}}]

{phang}
Web scrape player profiles into Stata

{p 8 16 2}
{cmd:nba2stata} {cmdab:playerp:rofile}
 {it:{help nba2stata##name_pattern_help:"name_pattern"}} [,
 {it:{help nba2stata##playerprofile_options_tbl:playerprofile_options}}]

{phang}
Web scrape team statistics into Stata

{p 8 16 2}
{cmd:nba2stata} {cmdab:teams:tats}
 {it:{help nba2stata##team_abv_help:"team_abv"}} [, 
 {it:{help nba2stata##teamstats_options_tbl:teamstats_options}}]

{phang}
Web scrape team rosters into Stata

{p 8 16 2}
{cmd:nba2stata} {cmdab:teamr:oster}
 {it:{help nba2stata##team_abv_help:"team_abv"}} [,
 {it:{help nba2stata##teamroster_options_tbl:teamroster_options}}]

{p 4 8 2}
{marker name_pattern_help}
{it:name_pattern} is used to filter player names. To use it correctly, you
 must separate each quoted entry with a space, and denote any options with a
 comma followed by the option name. For an example, see
 {help nba2stata##name_pattern_ex:example}

{p 4 8 2}
{marker team_abv_help}
{it:team_abv} takes three letter abbreviations of team names as a filter
 option. To specify multiple teams, separate the abbrevations with a space as
 such: "hou" "gsw" "atl". A list of team abbrevations can be found in
 the {help nba2stata##appendix:appendix}.


{synoptset 37}{...}
{marker playerstats_options_tbl}{...}
{synopthdr :playerstats_options}
{synoptline}
{synopt :{cmd:stat(career|season|game)}}specify the type of player data to
 scrape. {cmd:career} is the default{p_end}
{synopt :{cmd:season(}{it:{help numlist:numlist}}{bf:)}}specify the seasons to
 scrape{p_end}
{synopt :{cmd:seasontype(reg|playoffs)}}filter the season type{p_end}
{synopt :{cmd:matchany|matchall}}specify the match options. {cmd:matchany} is
 the default{p_end}
{synopt :{cmd:clear}}replace data in memory{p_end}
{synoptline}


{synoptset 37}{...}
{marker playerprofile_options_tbl}{...}
{synopthdr :playerprofile_options}
{synoptline}
{synopt :{cmd:matchany|matchall}}specify the match options. {cmd:matchany} is
 the default{p_end}
{synopt :{cmd:clear}}replace data in memory{p_end}
{synoptline}


{synoptset 37}{...}
{marker teamstats_options_tbl}{...}
{synopthdr :teamstats_options}
{synoptline}
{synopt :{cmd:stat(season|game)}}specify the type of team data to scrape. {cmd:season} is the default{p_end}
{synopt :{cmd:season(}{it:{help numlist:numlist}}{bf:)}}specify the seasons to
 scrape{p_end}
{synopt :{cmd:seasontype(reg|playoffs)}}filters the season type{p_end}
{synopt :{cmd:clear}}replace data in memory{p_end}
{synoptline}
{p2colreset}{...}


{synoptset 37}{...}
{marker teamroster_options_tbl}{...}
{synopthdr :teamroster_options}
{synoptline}
{synopt :{cmd:season(}{it:{help numlist:numlist}}{bf:)}}specify seasons to
 scrape{p_end}
{synopt :{cmd:clear}}replace data in memory{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:nba2stata} web scrapes and loads sorted data into Stata
 datasets. {cmd:nba2stata} parses NBA web data into Stata to allow you to use
 NBA statistics and data for personal use. The data is fetched at the time you
 execute the command, and is throttled to only load one new web url per second.

{pstd}
The scraping process is done by pulling data from json files on NBA stat pages.
 If the NBA makes structural changes to the way they store the data, it will
 likely result in the command not working.

{marker options}
{title:Options}

{phang}
{cmd:stat(game|season|career)} specifies what statistics to fetch. The
 {cmd:game} option gets data on a game-by-game basis. This is the only of the
 three options that allow {cmd:season(}numlist{cmd:)} to be specified.
 {cmd:season} gets data over a team's franchise, or player's career on a
 season-by-season basis. {cmd:career} gets only player's career data as summary
 data separated by regular season and playoffs.

{phang}
{break}
Important note: You may use the {cmd:seasontype(}reg|post{cmd:)} with all
 {cmdab:players:tats} and {cmdab:teams:tats} commands except for
 {cmd:nba2stata teamstats {it:"team"}, stat(season)},
 which is the default stat for the {cmd:teamstats} command. This is purely
 because the NBA data stored on their website does not provide accurate playoff
 data for each team.


{phang}
{cmd:season(}{it:numlist}{cmd:)} searches any season from 1945 and returns a
 dataset accordingly. If no data is found after the search,
 {help r(2000):r(2000)} will be returned.{p_end}

{phang}
{cmd:seasontype(}{it:reg|playoffs}{cmd:)} filters based on the season given.
 They are not case sensitive, and excluding the option will default to both
 season types being scraped. {cmd:reg} specifies all regular season games, and
 {cmd:playoffs} specifies all playoff games.{p_end}

{phang}
{cmd:matchall} requires that all strings provided in {it:{help nba2stata##name_pattern_help:name_pattern}}
 be present for the name to pass the filter.{p_end}

{phang}
{cmd:matchany} requires that only one of the strings provided in
 {it:{help nba2stata##name_pattern_help:name_pattern}} be present for the name to pass
 the filter. This is the default option if none are specified.{p_end}

{phang}
{cmd:clear} clears the current dataset in memory.{p_end}

{marker examples}{...}
{title:Remarks/Examples}

    {title:Notes}

{p 8 8 2}
{marker name_pattern_ex}
{it:name_pattern} is used to filter player names. To use it correctly, you
 must separate each quoted entry with a space, and denote any options with a
 comma followed by the option name. An example of a name pattern is as follows:

{p 8 8 2}
"James Harden" "LeBron James" "Russell Westbrook"

{p 8 8 2}
You may also use "_all" to denote all available players.
 This will be an expensive command, as it typically takes one web request per
 person, and due to having to throttle the connection speed to half of a second
 per connection, you may notice that runtime increases quickly.


    {title:Simple sorting example}

{p 8 8 2}
To begin, we will create a sorted list of all recorded NBA league champions and
 save it in a new dataset. The commands are as follows:

{p 12 12 2}
 {cmd:. nba2stata teamstats "_all"}{break}
 {cmd:. gsort +season}{break}
 {cmd:. keep if nbafinalsappearance == "LEAGUE CHAMPION"}{break}
 {cmd:. save nba_champions.dta}{p_end}

{p 8 8 2}
The commands are broken into four steps. First, the actual {cmd:nba2stata}
 command. This must go and visit webpages to scrape the data at runtime. It
 will take the longest of the commands. Second, we will want to resort the data
 by season, as it's currently sorted by team name. Third, we only want to keep
 teams that were NBA champions that season. And finally, we want to save the
 resulting dataset.

    {title:Simple filter example}

{p 8 8 2}
Next, we will create a dataset of the three most convincing MVP candidates for
 the 2017-18 season so that we may compare seasonal stats. The commands are as
 follows:

{p 12 12 2}
 {cmd:. nba2stata playerstats "James Harden" "Lebron James" "Russell Westbrook", matchany stat(season)}{break}
 {cmd:. keep if season == "2017-18" & seasontype == "Regular"}{break}
 {cmd:. save nba_mvpcandidates2017-18.dta}{p_end}

{p 8 8 2}
This example of a filter provides full player names, however, you may use
 substrings of player names and it will get all players containing the pattern.
 For example, "James Hard" will result in two (or more) players. Specifically,
 James Harden and James Hardy. The {cmd:matchany} option provided in the
 command simply says that the command is to look for any of the separated
 names, and not require the person to have all of the patterns in their name.

{marker appendix}{...}
{title:Appendix}

    {title:Team abbrevations}

        {hline 16}
	 {it:{cmd:_all} - this will effectively put all teams}
	 {cmd:atl}
         {cmd:bos}
         {cmd:bkn}
         {cmd:cha}
         {cmd:chi}
         {cmd:cle}
         {cmd:dal}
         {cmd:den}
         {cmd:det}
         {cmd:gsw}
         {cmd:hou}
         {cmd:ind}
         {cmd:lac}
         {cmd:lal}
         {cmd:mem}
         {cmd:mia}
         {cmd:mil}
         {cmd:min}
         {cmd:nop}
         {cmd:nyk}
         {cmd:okc}
         {cmd:orl}
         {cmd:phi}
         {cmd:phx}
         {cmd:por}
         {cmd:sac}
         {cmd:sas}
         {cmd:tor}
         {cmd:uta}
         {cmd:was}
        {hline 16}


