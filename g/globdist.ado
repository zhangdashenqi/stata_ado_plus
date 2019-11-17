* The globdist program requires that you have variables (usually lat and lon)
* specifying a latitude and longitude for each data point.  It requires as
* parameters the name of a variable to be created, a reference latitude and a
* longitude, and an optional miles (versus kilometers) indicator.  The newly-created
* variable will contain the great circle distance on the Earth's surface
* between the given latitude and longitude and the lat and lon specified for
* each data point.  The answer is approximate, because the Earth (or other
* planet for which you specify a radius) is treated as a perfect sphere.
* Use a plus sign for northern latitudes and a minus sign for southern
* latitudes.  Longitudes in North America are negative.  All latitudes and
* longitudes are assumed to be measured in degrees (_not_ degrees and
* seconds; decimal fractions must be out of 100 rather than out of 60).
program define globdist, rclass
	version 9.0
	syntax newvarname [if] [in], LAT0str(string) LON0str(string) [Miles LATVar(string) LONVar(string) WORLDRADius(string)]
	
	* Determine the lat and lon variables to use, and check that they exist.
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
	
	* If lat0 and lon0 are numbers, put them into scalars (which are double precision).
	* Record whether they are variables versus scalars (including from numbers).
	foreach latOrLon in lat0 lon0 {
		capture confirm numeric variable ``latOrLon'str'
		local `latOrLon'IsVar = _rc==0
		if _rc==0 {
			* Variable.
			local `latOrLon' ``latOrLon'str'
		}
		else {
			* Not a variable, so should be "scalar(name)" or number.
			capture confirm number ``latOrLon'str'
			if _rc==0 | "``latOrLon'str'"=="." {
				* Number.
				tempname `latOrLon'
				scalar ``latOrLon'' = ``latOrLon'str'
			}
			else {
				* Not a variable nor a number, so should be "scalar(name)".
				local varlistSaved `varlist'
				local ifSaved `"`if'"'
				local inSaved `"`in'"'
				local 0 ", ``latOrLon'str'"
				capture syntax , scalar(string)
				if _rc>0 {
					di as error "Parameters lat0 and lon0 for globdist must be either variable names or numbers or 'scalar(name)'; `latOrLon' is misspecified."
					exit 999
				}
				local varlist `varlistSaved'
				local if `ifSaved'
				local in `inSaved'
				capture confirm scalar `scalar'
				if _rc>0 {
					di as error "Parameter `latOrLon' refers to a scalar that does not exist."
					exit 999
				}
				* Scalar.
				local `latOrLon' `scalar'
			}
		}
	}
	
	* Sine and cosine of lat0, precomputed in case of a scalar lat0.
	tempname deg2rad
	scalar `deg2rad' = _pi / 180  // Number of radians per degree.
	if `lat0IsVar' {
		* Formula for sine and cosine of reference latitude.
		local sinlat0 = "sin(`lat0' * scalar(`deg2rad'))"
		local coslat0 = "cos(`lat0' * scalar(`deg2rad'))"
	}
	else {
		* Precompute sine and cosine of scalar reference latitude.
		tempname lat0rad sinlat0 coslat0
		scalar `lat0rad' = scalar(`lat0') * scalar(`deg2rad')  // Latitude of point 0 in radians.
		scalar `sinlat0' = sin(scalar(`lat0rad'))  // Sine of latitude parameter.
		scalar `coslat0' = cos(scalar(`lat0rad'))  // Cosine of latitude parameter.
		local sinlat0 = "scalar(`sinlat0')"
		local coslat0 = "scalar(`coslat0')"
	}
	
	* Refer to lat0 and lon0 from now on as scalar(...) if they are scalars, UNLESS they are missing, in which case refer to them as ".".
	if !`lat0IsVar' {
		local lat0 = "scalar(`lat0')"
		if `lat0'>=. {
			local lat0 = "."
		}
	}
	if !`lon0IsVar' {
		local lon0 = "scalar(`lon0')"
		if `lon0'>=. {
			local lon0 = "."
		}
	}
	
	* Determine the world-radius to use, in kilometers.  Earlier versions of this program used 6365 km.  Convert to miles if requested.
	tempname R
	if inlist(`"`worldradius'"',"auto","") {
		* Use Earth's radius to sea level at the weighted mean latitude (50% weighted based on lat0 [its mean if non-constant], and 50% based on the mean of latvar).
		tempname lat0mean latmean a b
		if `lat0IsVar' {
			su `lat0' `if' `in', meanonly
			scalar `lat0mean' = r(mean)
		}
		else {
			scalar `lat0mean' = `lat0'
		}
		su `latvar' `if' `in', meanonly
		scalar `latmean' = (r(mean)/2 + scalar(`lat0mean')/2) * scalar(`deg2rad')  // Mean latitude in radians.
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
	}
	if "`miles'"!="" {
		scalar `R' = scalar(`R') * (15625/25146)  // There are 15625 miles per 25146 kilometers.
	}
	
	* Compute the answer.
	if "`lat0'"=="." | "`lon0'"=="." {
		gen `varlist' = .
	}
	else {
		local orLat0Missing = cond(`lat0IsVar',"|`lat0'>=.","")
		local orLon0Missing = cond(`lon0IsVar',"|`lon0'>=.","")
		gen `varlist' = cond(`latvar'>=.|`lonvar'>=.`orLat0Missing'`orLon0Missing', ., cond(`latvar'==`lat0'&`lonvar'==`lon0', 0, scalar(`R') * acos(`sinlat0' * sin(`latvar'*scalar(`deg2rad')) + `coslat0' * cos(`latvar'*scalar(`deg2rad')) * cos(scalar(`deg2rad') * min( abs(`lon0'-`lonvar'), 360-abs(`lon0'-`lonvar') )) ) ) ) `if' `in'
	}
	
	* Also return the world-radius used (in miles or km as specified), and the units of measurement.
	return scalar worldRadius = scalar(`R')
	return local units = cond("`miles'"!="","miles","kilometers")
end
