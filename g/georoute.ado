******************************************
**    Sylvain Weber & Martin Péclat     **
**        University of Neuchâtel       **
**    Institute of Economic Research    **
**   This version: September 20, 2017   **
******************************************

*! version 2.1 Sylvain Weber & Martin Péclat 20sep2017
/*
Revision history:
- version 1.1 (2nov2016):
	- Single loop over i to calculate both coordinates and distance instead of two loops in version 1.0.
	  Advantage: if the program fails before the end, what has already been geocoded is saved while
	  it was lost with previous version. 
	  Other advantage: there is now a single timer instead of three separate (startaddress, endaddress, 
	  distance) in previous version. The help file has been adapted accordingly.
	- Other minor changes: miles obtained as 1.609344*km instead of 1.6093, unused temporary variables 
	  dropped, url links created outside the loop and renamed.
- version 2.0 (24feb2017):
	- Check if HERE account is valid.
	- cit in route_url if !herepaid
	- Create a variable containing diagnostic codes (useful if distances cannot be computed).
- version 2.1 (20sep2017)
	- Option -pause- added
*/

program georoute
version 10.0

*** Syntax ***
#d ;
syntax [if] [in], 
	hereid(string) herecode(string) 
	[
		STARTADdress(string) startxy(string) 
		ENDADdress(string) endxy(string) 
		km
		DIstance(string) TIme(string) COordinates(string)
		DIAGnostic(string) 
		replace
		herepaid
		timer pause 
	]
;
#d cr


*** Mark sample to be used ***
marksample touse
cap: count if `touse'
local N = r(N)


*** Checks ***
*insheetjson.ado and libjson.mlib must be installed
cap: which insheetjson.ado
if _rc==111 {
	di as error "insheetjson required; type {stata ssc install insheetjson}"
	exit 111
}
cap: which libjson.mlib
if _rc==111 {
	di as error "libjson required; type {stata ssc install libjson}"
	exit 111
}

*HERE API must be active (valid credentials)
local here_check = "http://geocoder.cit.api.here.com/6.2/geocode.json?searchtext=outofearth&app_id=`hereid'&app_code=`herecode'"
if ("`herepaid'"=="herepaid") local here_check = "http://geocoder.api.here.com/6.2/geocode.json?searchtext=outofearth&app_id=`hereid'&app_code=`herecode'"
tempvar checkok 
qui: gen str240 `checkok' = ""
qui: insheetjson `checkok' using "`here_check'", columns("Response:MetaInfo:Timestamp") flatten replace
if `checkok'[1]=="" {
	di as error `"There seem to be an issue with your HERE account: {browse "https://developer.here.com"}."'
	exit 198
}

*One of start_address or start_coord and one of end_address or end_coord must be specified (one of each and only one)
foreach p in start end {
	if "``p'address'"=="" & "``p'xy'"=="" {
		di as error "`p'address() or `p'xy() is required."
		error 198
	}
	if "``p'address'"!="" & "``p'xy'"!="" {
		di as error "`p'address() and `p'xy() may not be combined."
		error 184
	}
}

*Addresses can be specified in a single or in several variables
foreach p in start end {
	if "``p'address'"!="" {
		tokenize ``p'address'
		tempvar `p'_address
		qui: gen ``p'_address' = `1'
		cap: tostring ``p'_address', replace
		local i 2
		while `"``i''"'!="" {
			tempvar str
			cap: confirm string variable ``i''
			if _rc qui: tostring ``i'', gen(`str')
			if !_rc qui: gen `str' = ``i''
			qui: replace ``p'_address' = ``p'_address' + ", " + `str'
			local ++i
		}
	}
}

*Coordinates of starting and ending points must be specified in two variables
foreach p in start end {
	if "``p'xy'"!="" {
		tokenize ``p'xy'
		if `"`2'"'=="" | `"`3'"'!="" {
			di as error "option `p'xy() incorrectly specified"
			error 198
		}
		confirm numeric variable `1'
		confirm numeric variable `2'
		cap: assert inrange(`1',-90,90) | mi(`1') if `touse'
		if _rc {
			di as error "`1' (latitude) must be between -90 and 90"
			error 198
		}
		cap: assert inrange(`2',-180,180) | mi(`2') if `touse'
		if _rc {
			di as error "`2' (longitude) must be between -180 and 180"
			error 198
		}
		tempvar `p'_xy
		qui: gen ``p'_xy' = string(`1') + "," + string(`2')
	}
}
*If specified, distance, time, coordinates, and diagnostic must be new variables (unless replace is also specified)
if "`distance'"=="" local distance = "travel_distance"
if "`distance'"!="" {
	tokenize `distance'
	if `"`2'"'!="" {
		di as error "option distance() incorrectly specified"
		error 198
	}
}

if "`time'"=="" local time = "travel_time"
if "`time'"!="" {
	tokenize `time'
	if `"`2'"'!="" {
		di as error "option time() incorrectly specified"
		error 198
	}
}

if "`diagnostic'"=="" local diagnostic = "georoute_diagnostic"
if "`diagnostic'"!="" {
	tokenize `diagnostic'
	if `"`2'"'!="" {
		di as error "option diagnostic() incorrectly specified"
		error 198
	}
}

if `"`replace'"'=="replace" {
	cap: drop `distance'
	cap: drop `time'
	cap: drop `diagnostic'
}
confirm new var `distance'
confirm new var `time'
confirm new var `diagnostic'
cap: gen `distance' = .
cap: gen `time' = .
cap: gen `diagnostic' = .

if "`coordinates'"!="" {
	tokenize `coordinates'
	if `"`2'"'=="" | `"`3'"'!="" {
		di as error "option coordinates() incorrectly specified"
		error 198
	}
	local start `1'
	local end `2'
	if `"`replace'"'=="replace" {
		if "`startxy'"=="" {
			cap: drop `start'_x
			cap: drop `start'_y
			cap: drop `start'_match
			confirm new var `start'_x `start'_y `start'_match
		}
		if "`endxy'"=="" {
			cap: drop `end'_x
			cap: drop `end'_y
			cap: drop `end'_match
			confirm new var `end'_x `end'_y `end'_match
		}
	}
	if "`startxy'"=="" {
		cap: gen `start'_x = ""
		cap: gen `start'_y = ""
		cap: gen `start'_match = ""
	}
	if "`endxy'"=="" {
		cap: gen `end'_x = ""
		cap: gen `end'_y = ""
		cap: gen `end'_match = ""
	}
}


*** Calculate travel distance and time ***
*Prepare url links
local xy_url = "http://geocoder.cit.api.here.com/6.2/geocode.json?responseattributes=matchCode&searchtext="
if ("`herepaid'"=="herepaid") local xy_url = "http://geocoder.api.here.com/6.2/geocode.json?responseattributes=matchCode&searchtext="
local here_key = "&app_id=" + "`hereid'" + "&app_code=" + "`herecode'"
local route_url = "http://route.cit.api.here.com/routing/7.2/calculateroute.json?app_id=" + "`hereid'" + "&app_code=" + "`herecode'"
if ("`herepaid'"=="herepaid") local route_url = "http://route.api.here.com/routing/7.2/calculateroute.json?app_id=" + "`hereid'" + "&app_code=" + "`herecode'"

local t 0
forv i = 1/`=_N' {
	if `touse'[`i'] {
		*Add an optional timer
		if "`timer'"=="timer" {
			local ++t
			*Pause for 30 seconds every 100th geocoded observation
			if "`pause'"=="pause" & mod(`t',100)==0 sleep 30000
			if `t'==1 {
				di _n(1) _dup(9) as txt "-"
				di as txt "Geocoding"
				di _dup(9) as txt "-"
			}
			if int(`t'/(`N'/10))>int((`t'-1)/(`N'/10)) di _continue as res " `=int(`t'/(`N'/10))*10'% "
			if int(`t'/(`N'/100))>int((`t'-1)/(`N'/100)) & int(`t'/(`N'/10))==int((`t'-1)/(`N'/10)) di _continue as res "."
			if `=int(`t'/(`N'/10))*10'==100 di ""
		}
		*Addresses to xy-coordinates (only if addresses are provided, skipped if xy-coordinates are provided)
		foreach p in start end {
			if "``p'address'"!="" & !mi(``p'_address'[`i']) {
				tempvar temp_x temp_y temp_matchlevel
				qui: gen str240 `temp_x' = ""
				qui: gen str240 `temp_y' = ""
				qui: gen str240 `temp_matchlevel' = ""
				local coords = ``p'_address'[`i']
				local coords = subinstr("`coords'", ".", "", .)
				local xy_request = "`xy_url'" + "`coords'" + "`here_key'"
				local xy_request = subinstr("`xy_request'", " ", "%20", .)

				#d ;
				qui: insheetjson `temp_x' `temp_y' `temp_matchlevel' using "`xy_request'", 
					columns("Response:View:1:Result:1:Location:DisplayPosition:Latitude" 
							"Response:View:1:Result:1:Location:DisplayPosition:Longitude" 
							"Response:View:1:Result:1:MatchCode"
							) 
					flatten replace
				;
				#d cr

				local `p'_coord = `temp_x'[1] + "," + `temp_y'[1]
				if "`coordinates'"!="" & "``p'xy'"=="" {
					qui: replace ``p''_x = `temp_x'[1] in `i'
					qui: replace ``p''_y = `temp_y'[1] in `i'
					qui: replace ``p''_match = `temp_matchlevel'[1] in `i'
				}
			}
			if "``p'xy'"!="" {
				local `p'_coord = ``p'_xy'[`i']
			}
		}
		*xy-coordinates to distance
		if "`start_coord'"!="," & "`end_coord'"!="," {
			tempvar temp_time temp_distance
			qui: gen str240 `temp_distance' = ""
			qui: gen str240 `temp_time' = ""
			local s = "`start_coord'"
			local e = "`end_coord'"
			local route_request = "`route_url'" + "&waypoint0=geo!" + "`s'" + "&waypoint1=geo!" + "`e'" + "&mode=fastest;car;&representation=overview"

			#d ;
			qui: insheetjson `temp_distance' `temp_time' using "`route_request'", 
				columns("response:route:1:summary:distance" 
						"response:route:1:summary:travelTime"
				) 
				flatten replace
			;
			#d cr

			if "`km'"=="" {
				qui: replace `distance' = real(`temp_distance'[1])/1609.344 in `i'
			}
			if "`km'"=="km" {
				qui: replace `distance' = real(`temp_distance'[1])/1000 in `i'
			}
			qui: replace `time' = (1/60)*real(`temp_time'[1]) in `i'
		}
	}
}


*** Label the variables ***
la var `distance' "Travel distance (`=cond("`km'"=="km","km","mi")')"
la var `time' "Travel time (minutes)"
if "`coordinates'"!="" {
	foreach p in start end {
		if "``p'address'"!="" {
			qui: destring ``p''_x, replace
			la var ``p''_x "x-coordinate of `=cond("`p'"=="start","starting","ending")' address"
			qui: destring ``p''_y, replace
			la var ``p''_y "y-coordinate of `=cond("`p'"=="start","starting","ending")' address"
			la var ``p''_match "Match code for `=cond("`p'"=="start","starting","ending")' address"
			qui: replace ``p''_match = "1" if ``p''_match=="exact"
			qui: replace ``p''_match = "2" if ``p''_match=="ambiguous"
			qui: replace ``p''_match = "3" if ``p''_match=="upHierarchy"
			qui: replace ``p''_match = "4" if ``p''_match=="ambiguousUpHierarchy"
			qui: destring ``p''_match, replace
			cap: la drop matchcode
			la def matchcode 1 "exact" 2 "ambiguous" 3 "upHierarchy" 4 "ambiguousUpHierarchy"
			la val ``p''_match matchcode
		}
	}
}
la var `diagnostic' "Diagnostic code (georoute)"
qui: replace `diagnostic' = 0 if !mi(`distance')
if "`startaddress'"!="" & "`endaddress'"!="" {
	qui: replace `diagnostic' = 1 if mi(`distance') & !mi(`start'_match) & !mi(`end'_match)
	qui: replace `diagnostic' = 2 if mi(`distance') & (mi(`start'_match) | mi(`end'_match))
}
if "`startxy'"!="" & "`endaddress'"!="" {
	qui: replace `diagnostic' = 1 if mi(`distance') & (substr(`start_xy',1,2)!=".," | substr(`start_xy',-2,2)!=",.") & !mi(`end'_match)
	qui: replace `diagnostic' = 2 if mi(`distance') & mi(`end'_match)
}
if "`startaddress'"!="" & "`endxy'"!="" {
	qui: replace `diagnostic' = 1 if mi(`distance') & !mi(`start'_match) & (substr(`end_xy',1,2)!=".," | substr(`end_xy',-2,2)!=",.")
	qui: replace `diagnostic' = 2 if mi(`distance') & mi(`start'_match)
}
if "`startxy'"!="" & "`endxy'"!="" {
	qui: replace `diagnostic' = 1 if mi(`distance') & substr(`start_xy',1,2)!=".," & substr(`start_xy',-2,2)!=",."  & substr(`end_xy',1,2)!=".," & substr(`end_xy',-2,2)!=",." 
	qui: replace `diagnostic' = 3 if mi(`distance') & (substr(`start_xy',1,2)==".," | substr(`start_xy',-2,2)==",."  | substr(`end_xy',1,2)==".," | substr(`end_xy',-2,2)==",.")
}
cap: la drop diagnosticlab
la def diagnosticlab 0 "OK" 1 "No route found" 2 "Start and/or end not geocoded" 3 "Start and/or end coordinates missing"
la val `diagnostic' diagnosticlab

end
