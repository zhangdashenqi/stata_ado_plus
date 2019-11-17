* Program to determine the number of data points, or a sum across them,
* within an r-kilometer or r-mile circular radius of each.  See the
* help file for more options.
* Version 3 (Jan. 2010).
program define circnum, rclass byable(onecall) sortpreserve
	version 9.0
	syntax newvarname [if] [in] , Radius(real) [LATVar(string) LONVar(string) Sum(string) Miles BY(varlist) Extralatlons(integer 0) Wholeextras Othersonly WORLDRADius(string)]

	global cn_data = ""

	* 1. Check parameters.
	* 1A. Check that the radius option is ok.
	capture confirm number `radius'
	if _rc>0 {
		di as error "Error: The circnum command requires that option radius be a number (greater than zero)."
		exit 999
	}
	if `radius' <= 0 {
		display as error "Error: The circnum command requires a positive radius."
		exit 999
	}
	else if `radius' <= 0.1 {
		display as error "Warning: The circnum command has not been tested for small radii (under say 100 meters).  Computing anyway...."
	}
	* 1B. Determine the lat and lon variables to use, and check that they exist.
	if "`latvar'" == "" {
		local latvar = "lat"
	}
	if "`lonvar'" == "" {
		local lonvar = "lon"
	}
	capture confirm numeric variable `latvar' `lonvar'
	if _rc != 0 {
		display as error "Error: At least one of the following variables does not exist or is not numeric: `latvar', `lonvar'."
		exit _rc
	}
	* 1C. Check the extralatlons option is ok, and exlat1 exlon1 etc. exist.
	if `extralatlons' != 0 {
		if `extralatlons' < 0 {
			display as error "Error: The extralatlons option to circnum must be a nonnegative integer."
			exit 999
		}
		/* The user asked to take into account not just one latitude &
		   longitude per data point, but extras.  The first must be stored
		   in lat and lon (or in other variables as specified by the user).
		   Additional ones must be stored in exlat1, exlon1; exlat2, exlon2;
		   etc.  They are assumed each to have an equal share of the overall
		   weight for the data point. */
		forvalues i = 1/`extralatlons' {
			capture confirm numeric variable exlat`i' exlon`i'
			if _rc != 0 {
				if `i' == `extralatlons' {
					display as error "Error: The circnum command with the extralatlons option requires that variables exlat`i' and exlon`i' exist, but exlat`i' and exlon`i' do not exist or are not numeric variables."
				}
				else {
					display as error "Error: The circnum command with the extralatlons option requires that variables exlat`i' and exlon`i' up to exlat`extralatlons' and exlon`extralatlons' exist, but exlat`i' and exlon`i' do not exist or are not numeric variables."
				}
				exit _rc
			}
		}
	}
	* 1D. Check that the sum option is okay.
	local sumLen : length local sum
	if `sumLen' {
		local thisSumToUse : subinstr local sum "[i]" "[_n]", all
		local thisSumToUse : subinstr local thisSumToUse "[j]" "[_n]", all
		capture chkexpr =`thisSumToUse'
		if _rc != 0 {
			display as error "Error: The expression in the sum option to circnum is invalid"
			exit _rc
		}
	}
	* 1E. Save the formula for the sum.
	if `sumLen'==0 {
		local sumoriginal = "1"
	}
	else {
		local sumoriginal `sum'
		local sum : subinstr local sum "[j]" "", all
	}
	* 1F. Check that by options were not entered both before the command (new style) and in the by option (old style for backward compatability).
	*     Also, put the by-varlist into local variable by.
	local byStartLen : length local _byvars
	local byOptLen : length local by
	if `byStartLen'>0 & `byOptLen'>0 {
		display as error "Error: By-varnames were given both before the command and as an option."
		exit 999
	}
	if `byStartLen'>0 {
		local by `_byvars'
	}
	
	* 2. Prepare to use if and in conditions, if any.  This will let us deal only with an if condition, without handling in conditions, in the computations below.
	local ifLen : length local if
	local inLen : length local in
	if `ifLen' | `inLen' {
		tempvar touse
		mark `touse' `if' `in'
		local andif = "& `touse'"
		local andifi = "& `touse'[\`i\']"  // This creates a string "& varname[`i']", where the `i' part will be replaced with the value of i when looping.
		local if = "if `touse'"
	}
	else {
		local andif = ""
		local andifi = ""
		local if = ""
	}
	
	* 3. Set computational parameters.
	* 3A. Number of radians per degree.
	tempname deg2rad
	scalar `deg2rad' = _pi / 180
	* 3B. Determine the world-radius to use, in kilometers.  Earlier versions of this program used 6365 km.  Convert to miles if requested.
	tempname R
	if inlist(`"`worldradius'"',"auto","") {
		* Use Earth's radius to sea level at the mean latitude among the data points used.
		tempname latmean a b
		su `latvar' `if', meanonly
		scalar `latmean' = r(mean) * scalar(`deg2rad')  // Mean latitude in radians.
		scalar `a' = 6378.135  // Km from center of Earth to equator
		scalar `b' = 6356.750  // Km from center of Earth to north or south pole
		scalar `R' = sqrt( ( (scalar(`a')^2*cos(scalar(`latmean')))^2 + (scalar(`b')^2*sin(scalar(`latmean')))^2 ) / ( (scalar(`a')*cos(scalar(`latmean')))^2 + (scalar(`b')*sin(scalar(`latmean')))^2 ) )
	}
	else {
		* Use a radius provided by the user.  This must be in kilometers.
		capture confirm number `worldradius'
		if _rc>0 {
			di as error `"Parameter worldradius for globdist must be either a number (in kilometers) or "auto", but is neither."'
			exit 999
		}
		scalar `R' = `worldradius'
		if "`miles'"!="" {
			di as text "  Using planetary radius of `worldradius' km.  NB., this is in kilometers, not miles."
		}
	}
	if "`miles'"!="" {
		scalar `R' = scalar(`R') * (15625/25146)  // There are 15625 miles per 25146 kilometers.
	}
	* 3C. Sines and cosines of latitudes.
	tempvar sinlat coslat
	quietly gen double `sinlat' = sin(`latvar'*scalar(`deg2rad')) `if'
	quietly gen double `coslat' = cos(`latvar'*scalar(`deg2rad')) `if'
	
	* 4. Prepare to deal with by-groups.
	if "`by'" == "" {
		local byexpr = ""  // Create null expression to use in egen commands.
	}
	else {
		local byexpr = "by(`by')"  // Create expression to use in egen commands.
		sort `by'  // Sort by group.
	}

	* 5. If using extra lats & lons, temporarily expand dataset to deal with them.
	if `extralatlons'>0 {
		display as text "  (Warning: If the circnum command terminates prematurely, data in memory will be altered.  Display \$cn_data if you need to check whether the data have been altered.)"
		tempvar exlocnum origline nexlocs weightL
		global cn_data = "Data have been altered."
		exlocs `if', n(`extralatlons') exlocnum(`exlocnum') origline(`origline') nexlocs(`nexlocs') latvar(`latvar') lonvar(`lonvar')
		if "`wholeextras'"=="" {
			* Weight cases with extra locations by 1/total_locations each, so the (original) data points are weighted equally no matter how many locations they have.
			quietly gen double `weightL' = 1 / (`nexlocs' + 1)  /* Weight for each location. */
			if `sumLen' {
				local sum `weightL' * (`sum')
			}
			else {
				local sum `weightL'
			}
		} 
	}

	* 6. If no sum variable, use 1.
	if `sumLen'==0 {
		local sum = "1"
		local sumIs1 = 1  // This is not the same as `sumLen'==0, because of weights for extra lats & lons.
	}
	else {
		local sum (`sum')
		local sumIs1 = 0
	}

	* 7. Generate the variable.   COULD SPEED THIS UP WHEN USING BY-GROUPS (no need to compute distances between by-groups; fastest might be to reset a view in Mata for each by-group).
	local countsDataType = cond(_N<=100, "byte", cond(_N<=32740, "int", "long"))
	tempvar resultvar
	quietly gen `resultvar' = -1 `if'  // Create the new variable with -1 everywhere.
	quietly replace `resultvar' = . if `latvar'==. | `lonvar'==.
	tempname lat0 lon0 sinlat0 coslat0
	tempvar distance inradius
	local nObs = _N
	forvalues i=1/`nObs' {
		if `resultvar'[`i'] == -1 `andifi' {
			* Process all data points with this lat & lon.
			scalar `lat0' = `latvar'[`i']
			scalar `lon0' = `lonvar'[`i']
			scalar `sinlat0' = `sinlat'[`i']  // Sine of latitude parameter.
			scalar `coslat0' = `coslat'[`i']  // Cosine of latitude parameter.
			quietly gen `distance' = cond(`latvar'>=.|`lonvar'>=., ., cond(`latvar'==scalar(`lat0')&`lonvar'==scalar(`lon0'), 0, scalar(`R') * acos(scalar(`sinlat0') * `sinlat' + scalar(`coslat0') * `coslat' * cos(scalar(`deg2rad') * min( abs(scalar(`lon0')-`lonvar'), 360-abs(scalar(`lon0')-`lonvar') )) ) ) ) `if'
			if `sumIs1' {  // Note that below, `distance'<=`radius' indicates whether each datum is within r km/mi of the location given by thislat and thislon.
				quietly egen `countsDataType' `inradius' = total(`distance'<=`radius') `if', `byexpr'
			}
			else {
				local thisSumToUse : subinstr local sum "[i]" "[`i']", all
				quietly egen double `inradius' = total(cond(`distance'<=`radius', `thisSumToUse', 0)) `if', `byexpr'
			}
			quietly replace `resultvar' = `inradius' if `latvar'==scalar(`lat0') & `lonvar'==scalar(`lon0') `andif'
			drop `distance' `inradius'
		}
	}
	if "`othersonly'" == "othersonly" {
		* Do not count a given data point in computing the sum within the radius; only count other data points.
		local thisSumToUse : subinstr local sum "[i]" "", all
		quietly replace `resultvar' = `resultvar' - `thisSumToUse' `if'
	}

	* 8. Drop added data points, if any had to be added to deal with extra lats & lons.
	if `extralatlons'>0 {
		* Free some memory if weightL variable can be dropped.
		if "`wholeextras'" == "" {
			drop `weightL'
		}
		* Sum across locations for cases with multiple locations.  Note that if location X is within radius r of both locations A0 and A1, where A1 is an extra location along with A1, then X is counted twice.  Also note that if A0 and A1 are within the radius of each other, then they are included in the counts.
		tempvar totsum
		quietly egen double `totsum' = total(`resultvar' / (`nexlocs' + 1)) `if', by(`origline')
		quietly replace `resultvar' = `totsum' `if'
		* Drop the added data points.
		quietly drop if `exlocnum' > 0
		global cn_data = "Data remain unaltered."
		display as text "  (The command terminated fine.  Data remain unaltered, except for creation of the new variable.)"
	}
	rename `resultvar' `varlist'
	
	* 9. Return results.
	* Return the world-radius used (in miles or km as specified), and the units of measurement.
	return scalar worldRadius = scalar(`R')
	if "`by'"=="" {
		return local by " "
	}
	else {
		return local by "`by'"
	}
	return local sum `"`sumoriginal'"'
	return scalar othersonly = "`othersonly'"=="othersonly"
	return local units = cond("`miles'"!="","miles","kilometers")
	return scalar radius = scalar(`radius')
end


* The chkexpr command takes an expression, checks that it is okay (to the extent that Stata does error checking on expressions in command-line syntax), and generates an error if there is a problem.
program define chkexpr
	version 6.0
	syntax =/exp
end


* Subroutine to add observations for extra locations.  Parameters are not checked for errors.
* This is a simple and low-memory kind of data reshaping to long form (low-memory because rows are added only where needed, simple because of the looping used).
program define exlocs
	version 9.0
	syntax [if/], n(integer) [EXLocnum(string) Origline(string) NEXlocs(string) latvar(string) lonvar(string)]
	
	* Prepare to use if condition, which may be only a single dummy variable.
	if "`if'"!="" {
		local andif = "& `if'"
		local if = "if `if'"
	}
	
	* What data types to use to store extra-location numbers.
	if `n'<=100 {
		local type = "byte"
	}
	else if `n'<=32740 {
		local type = "int"
	}
	else {
		local type = "long"
	}
	
	* Generate variable exlocnum, zero for original data points.
	quietly gen `type' `exlocnum' = 0
	
	* Check that nonmissing extra locations values are stored in the lowest-numbered extra locations.
	capture assert (`latvar'!=999 & `latvar'<. & `lonvar'!=999 & `lonvar'<.) | (exlat1==999 | exlat1>=. | exlon1==999 | exlon1>=.)
	if _rc>0 {
		di as error "Error: Extra locations must be missing if main location is missing."
	}
	forvalues i = 2/`nexlocs' {
		local iLess1 = `i'-1
		capture assert (exlat`iLess1'!=999 & exlat`iLess1'<. & exlon`iLess1'!=999 & exlon`iLess1'<.) | (exlat`i'==999 | exlat`i'>=. | exlon`i'==999 | exlon`i'>=.)
		if _rc>0 {
			di as error "Error: Higher-numbered extra locations must be missing if lower-numbered extra locations are missing."
		}
	}
	
	* Determine number of extra locations for each line of data.
	quietly gen `type' `nexlocs' = cond(exlat`n'==999 | exlat`n'>=., `n'-1, `n') `if'
	quietly replace `nexlocs' = 0 if `nexlocs'==.  // Cases not satisfying the if/in conditions.
	local i = `n' - 1
	while `i' > 0 {
		quietly replace `nexlocs' = `i'-1 if (exlat`i'==999 | exlat`i'>=. | exlon`i'==999 | exlon`i'>=.) `andif'
		local i = `i' - 1
	}
	
	* What data type to use to store original-line numbers.
	if _N<=100 {
		local type = "byte"
	}
	else if _N<=32740 {
		local type = "int"
	}
	else {
		local type = "long"
	}
	
	* Expand the data.
	gen `type' `origline' = _n
	quietly expand `nexlocs' + 1 `if'
	sort `origline'
	quietly by `origline': replace `exlocnum' = _n - 1
	forvalues i=1/`n' {
		* Replace latitudes & longitudes w/ extra location lats & lons, for added lines.
		quietly replace `latvar' = exlat`i' if `exlocnum'==`i'
		quietly replace `lonvar' = exlon`i' if `exlocnum'==`i'
	}
end
