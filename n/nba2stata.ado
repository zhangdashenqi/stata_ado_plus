program define nba2stata
	version 15.0
	
	gettoken sub 0 : 0, parse(" ,")
	
	if "`sub'" == "players" 		playerstats `0'
	else if "`sub'" == "playerst"		playerstats `0'
	else if "`sub'" == "playersta"		playerstats `0'
	else if "`sub'" == "playerstat"		playerstats `0'
	else if "`sub'" == "playerstats"	playerstats `0'
	else if "`sub'" == "playerp"		playerprofile `0'
	else if "`sub'" == "playerpr"		playerprofile `0'
	else if "`sub'" == "playerpro"		playerprofile `0'
	else if "`sub'" == "playerprof"		playerprofile `0'
	else if "`sub'" == "playerprofi"	playerprofile `0'
	else if "`sub'" == "playerprofil"	playerprofile `0'
	else if "`sub'" == "playerprofile"	playerprofile `0'
	else if "`sub'" == "teams"		teamstats `0'
	else if "`sub'" == "teamst"		teamstats `0'
	else if "`sub'" == "teamsta"		teamstats `0'
	else if "`sub'" == "teamstat"		teamstats `0'
	else if "`sub'" == "teamstats"		teamstats `0'
	else if "`sub'" == "teamr"		teamroster `0'
	else if "`sub'" == "teamro"		teamroster `0'
	else if "`sub'" == "teamros"		teamroster `0'
	else if "`sub'" == "teamrost"		teamroster `0'
	else if "`sub'" == "teamroste"		teamroster `0'
	else if "`sub'" == "teamroster"		teamroster `0'
	else if "`sub'" == "setsleep"		setsleep `0'
	else {
		* Error out, no recognized subcommand
		di as error "subcommand not recognized"
		exit 198
	}
end

program define checkclear
	args clear
	
	if "`clear'" != "" {
		clear
	}
	else {
		if `c(changed)' != 0 {
			error 4
		}
		else {
			clear
		}
	}
end

program define parsePName, sclass
	syntax anything [, matchall matchany]
	local anything = strlower(`"`anything'"')
	
	if `"`anything'"' == `""""' {
		di as text "    You must specify a playername"
		error 198
	}
	
	local match = "matchany"
	if "`matchall'" != "" & "`matchany'" != "" {
		*throw error, can't have both options selected.
		di as error "you can't select both match options"
		exit 198
	}
	else if "`matchall'" != "" {
		local match = "matchall"
	}
	
	gettoken sub anything : anything
	while `"`sub'"' != "" {
		if `"`pArgs'"' == "" {
			local pArgs = `"`sub'"'
		}
		else {
			local pArgs = `"`pArgs':"`sub'""'
		}
		gettoken sub anything : anything
	}
	local pArgs = `"`pArgs':`match'"'
	
	sreturn local pArgs = `"`pArgs'"'	
end

program define validateSeasonType, sclass
	args seasontype
	if "`seasontype'" != "" {
		local _st = strlower(`"`seasontype'"')
		if "`_st'" != "reg" & "`_st'" != "playoffs" & "`_st'" != "" {
			di as error "seasontype must either be {cmd:reg} or {cmd:playoffs}"
			error 198
		}
		if "`_st'" == "reg" {
			sreturn local st = "Regular"
		}
		else if "`_st'" == "playoffs" {
			sreturn local st = "Playoffs"
		}
	}
end

program define keepNumlist
	args season
	if "`season'" != "" {
		foreach i of local season {
			if "`arg'" == "" {
				local arg = `"regexm(season,"`i'") == 1"'
			}
			else {
				local arg = `"`arg' | regexm(season,"`i'") == 1"'
			}
		}
	qui keep if `arg'
	}
	// Else just drop out
end

program define playerstats
	syntax anything [, stat(string) season(numlist integer >=1945 min=1) seasontype(string) matchany matchall clear]
	
	if `"`anything'"' == "" {
		di as text "    You must include a name pattern to search for"
		error 198
	}
	if "`matchany'" == "" & "`matchall'" == "" {
		local match = ", matchany"
	}
	else if "`matchany'" != "" & "`matchall'" == "" {
		local match = ", matchany"
	}
	else if "`matchany'" == "" & "`matchall'" != "" {
		local match = ", matchall"
	}
	else {
		di as error "you cannot specify more than one match option"
		error 198
	}
	
	checkclear "`clear'"
	
	if "`stat'" == "" {
		local cmdType = "career"
	}
	else {
		local cmdType = "`stat'"
	}
	
	if "`cmdType'" == "career" {
		// Parse player name args using a : as a delimiter in Java.
		// Cannot do season in this branch because it returns career data as a whole.
		if "`season'" != "" {
			di as text "    The season option matched with {cmd:career} will not change the scraped data"
			di as text "    because a summary of all of the player's seasons are scraped."
		}
		
		local anything = `"`anything'`match'"' 
		parsePName `anything'
		local pArgs = `"`s(pArgs)'"'
		validateSeasonType "`seasontype'"
		local seasontype = "`s(st)'"
		
		javacall com.stata.chassell.NBA2Stata doCommand, jars(nba2stata.jar) args("playerstats_career" `"`pArgs'"')
	
		if "`seasontype'" != "" {
			qui keep if seasontype == "`seasontype'"
		}
		
		local N = _N
		if `N' == 0 {
			di as error "no observations"
			exit 2000
		}
		else {
			qui compress
			gsort +playername -seasontype
			di "`N' observation(s) loaded"
		}
	}
	else if "`cmdType'" == "season" {
		// Parse player name args using a : as a delimiter in Java.
		local anything = `"`anything'`match'"' 
		parsePName `anything'
		local pArgs = `"`s(pArgs)'"'
		validateSeasonType "`seasontype'"
		local seasontype = "`s(st)'"
		
		javacall com.stata.chassell.NBA2Stata doCommand, jars(nba2stata.jar) args("playerstats_byseason" `"`pArgs'"' "`season'")
		
		/*
			This call should be redundant since I'm passing in season, 
			but I left it in just to ensure that nothing faulty made 
			it through the Java predicate(filter).
		*/
		keepNumlist "`season'"
		if "`seasontype'" != "" {
			qui keep if seasontype == "`seasontype'"
		}
		
		local N = _N
		if `N' == 0 {
			di as error "no observations"
			exit 2000
		}
		else {
			qui compress
			gsort +playername +season -seasontype
			di "`N' observation(s) loaded"
		}
	}
	else if "`cmdType'" == "game" {
		// Parse player name args using a : as a delimiter in Java.
		local anything = `"`anything'`match'"' 
		parsePName `anything'
		local pArgs = `"`s(pArgs)'"'
		validateSeasonType "`seasontype'"
		
		javacall com.stata.chassell.NBA2Stata doCommand, jars(nba2stata.jar) args("playerstats_bygame" `"`pArgs'"' "`season'" "`seasontype'")
	}
	else {
		di as text "    If including the stat option, you must enter career, season, or game"
		error 198
	}
end

program define playerprofile
	syntax anything [, matchany matchall clear]

	checkclear "`clear'"
	
	if `"`anything'"' == "" {
		di as text "    You must include a name pattern to search for"
		error 198
	}
	if "`matchany'" == "" & "`matchall'" == "" {
		local match = ", matchany"
	}
	else if "`matchany'" != "" & "`matchall'" == "" {
		local match = ", matchany"
	}
	else if "`matchany'" == "" & "`matchall'" != "" {
		local match = ", matchall"
	}
	else {
		di as error "you cannot specify more than one match option"
		error 198
	}
	
	local anything = `"`anything'`match'"' 
	parsePName `anything'
	local pArgs = `"`s(pArgs)'"'
	
	javacall com.stata.chassell.NBA2Stata doCommand, jars(nba2stata.jar) args("playerprofile" `"`pArgs'"')
end

program define teamstats
	syntax anything [, stat(string) season(numlist integer >=1945 min=1) seasontype(string) clear]
	
	if `"`anything'"' == "" {
		di as text `"    Team_abv cannot be empty. Include something like `"atl"' `"hou"'"'
		error 198
	}
	
	checkclear "`clear'"
	
	if "`stat'" == "" {
		local cmdType = "season"
	}
	else {
		local cmdType = "`stat'"
	}
	
	if "`cmdType'" == "season" {
		if "`seasontype'" != "" {
			di as text "    You cannot specify the seasontype option with {cmd:stat(season)}, (which is"
			di as text "    the default), due to data inaccuracies of team playoff data."
			error 198
		}
		javacall com.stata.chassell.NBA2Stata doCommand, jars(nba2stata.jar) args("teamstats_byseason" `"`anything'"')
	
		keepNumlist "`season'"
		
		local N = _N
		if `N' == 0 {
			di as error "no observations"
			exit 2000
		}
		else {
			qui compress
			gsort +teamname +season
			di "`N' observation(s) loaded"
		}
	}
	else if "`cmdType'" == "game" {
		validateSeasonType "`seasontype'"
		javacall com.stata.chassell.NBA2Stata doCommand, jars(nba2stata.jar) args("teamstats_bygame" `"`anything'"' "`season'" "`seasontype'")
	}
	else {
		di as text "    If including the stat option, you must enter season or game"
		error 198
	}
end

program define teamroster
	syntax anything [, season(numlist integer >=1945 min=1) clear]
	
	if `"`anything'"' == "" {
		di as text `"    Team_abv cannot be empty. Include something like `"atl"' `"hou"'"'
		error 198
	}
	
	checkclear "`clear'"
	
	javacall com.stata.chassell.NBA2Stata doCommand, jars(nba2stata.jar) args("teamroster" `"`anything'"' "`season'")
end

program define setsleep
	syntax anything
	
	javacall com.stata.chassell.NBA2Stata setSleepTime, jars(nba2stata.jar) args("`anything'")
end
