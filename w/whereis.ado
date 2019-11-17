program whereis, rclass
*! v1.2 mantains a directory of external files 10sep2016 rev 6feb2017
	version 14
	args name location
	mata whereis(`"`name'"', `"`location'"') // updates location macro
	if `"`name'"' != "" {
		display as text `"`location'"' 
		return local `name' `location'
	}
end

mata:
	void whereis(string scalar name, string scalar location) {		
		real scalar pos, col, fh, retrieve, i
		string scalar dirpath, adopath, entry
		string vector dir	
		dir = J(0, 1, "")
		
		// get or create whereis directory
		dirpath = findfile("whereis.dir")
		if(dirpath != "") {
			dir = cat(dirpath)
		}
		else {
			adopath = findfile("whereis.ado")
			dirpath = usubinstr(adopath, ".ado", ".dir", 1)
		}			
		
		// list all resources
		if (name == "") {
			if (length(dir) < 1) {
				printf("{text}No file locations have been stored with {bf}whereis{sf}\n")
			}
			else {
				//printf("{text}File locations saved with with {bf}whereis{sf}:\n")
				listf(dirpath)
			}
			return
		}
		
		// retrieve location
		pos = lsearch(dir, name)
		retrieve = location == ""
		if(retrieve) { 
			if(pos < 1) {
				errprintf("{txt}location of %s has not been stored with {cmd:whereis}\n", name)
				errprintf("{txt}type {cmd:help whereis} or click {help whereis} for instructions\n")
				exit(601)
			}
			col = ustrpos(dir[pos], " ")
			location = usubstr(dir[pos], col + 1, .)
		}
		
		// check location
		if(!fileexists(location)) {
			errprintf(`"file "%s" not found\n"', location)
			exit(601)
		}
		st_local("location", location)

		// store location
		if(!retrieve) {
			entry = name + " " + location
			if(pos < 0) {
				dir = dir \ entry
			}
			else {
				dir[pos] = entry
			}
			if(fileexists(dirpath)) unlink(dirpath)
			fh = fopen(dirpath, "w")
			for(i = 1; i <= length(dir); i++) {
				fput(fh, dir[i])
			}
			fclose(fh)
		}
	}
	// linear search in whereis directory
	real scalar lsearch(string vector lines, string scalar stem) {
		real scalar m, i
		m = ustrlen(stem)
		for(i = 1; i <= length(lines); i++) {
			if(usubstr(lines[i], 1, m) == stem) return(i)
		}
		return(-1)
	}
	// list contents of text file
	void listf(string scalar filename) {
		string vector lines
		real scalar i
		lines = cat(filename)
		for(i = 1; i <= length(lines); i++) {
			printf("{text}%s\n", lines[i])
		}	
	}
end     
       
exit
