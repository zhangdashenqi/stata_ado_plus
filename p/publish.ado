program publish , sclass
*! Collecting tables, estimation results and graphs into a single HTML document
*! Version 0.3.0 - 19jan2013
*! Author: Tamas Bartus, Corvinus University of Budapest 

	version 11

	if `"`0'"'=="" {
		di as error "A subcommand must be specified"
		error 198
	}
	gettoken cmd 0 : 0 , parse(" ,")
	local valid open close des sum tab tab1 tab2 table est mat data empty text
	// future additions: local valid `valid' tabstat out graph
	local flag = 0
	foreach v of local valid {
		if substr("`cmd'",1,length("`v'"))=="`v'" {
			local flag = 1
			continue , break
		}
	}
 	if `flag'==0 {
		di as error "Invalid subcommand `cmd'"
		error 198
	}

	if "`cmd'"!="open" & "$publish_file"=="" {
		di as error "No files open; use -publish open- first"
		error 198
	}
	publish_`cmd' `0'
	sret clear
	
end



//	STRUCTURE
//
//	[1] OPENING AND CLOSING THE FILE
//
//	[2] TABLES OF STATISTICS
//
//	[4] UTILITIES 
//
//	[4] COMMON SUBROUTINES 



*----------------------------------------------------------------------------
*
*	[1] OPENING AND CLOSING THE FILE
*
*----------------------------------------------------------------------------


program publish_open , sclass
	version 11
	syntax  [anything(name=file id="filename") ] [  , Append Replace as(string) from(string) LANGuage(string) SECtion(integer 0) Title(string asis) ]
	
// syntax check

	if "`append'"!="" & "`replace'"!=""  {
		di as error "Options append and replace cannot be specified together"
		exit
	}
	if "`append'"!="" & "`from'"!=""  {
		di as error "Options append and from() cannot be specified together"
		exit
	}
	if `"`title'"'==""	local title Untitled document created by -publish-

	// Document format (as option may overwrite file extension)
	if strpos(`"`file'"',".")!=0 {
		local ext = substr(`"`file'"',strpos("`file'",".")+1,.)
		local file = substr(`"`file'"',1,strpos("`file'",".")-1)
	}
	else {
		if "`as'"=="" local ext html
		else local ext `as'
	} 
	if "`as'"=="" local as  `ext'
	if "`as'"=="htm" local as html
	if inlist("`as'","html","doc","tex")==0 {
		di as error "Invalid as() option: `as' not supported"
		error 198
	}


// Inicializing globals used by all subroutines

	global publish_file	   `file'.`ext'
	global publish_doctype `as'
	global publish_section = `section'
	global publish_tabnum = 0

	if "`append'"!="" {
		tempname target
		capture file open `target' using `"`file'"', write text append
		if _rc==0 {
			di as error "An error occured while trying to open `file'"
			di as error "The file does not exist, or is not a text file, or used by another program"
			exit
		}
		if `"`title'"'!=""	di as error "The title() option will be ingored because the append option was also specified"
		file open `target' using `"`file'"', write text append	
		file write `target'  _n
		publish_writer `as' break
		exit
	}

	// Finding the template file
	if "`from'"=="" {
		FindStyle `as' default style
		if `"$publish_style"'=="" {
			di as error "Default template file publish_`as'_default.style not found"
			di as error "Please install the publish package again"
			exit
		}
		local from $publish_style
	}
	else {
		tempname source
		capture file open `source' using `"`from'"', read text
		if _rc!=0 {
			FindStyle `as' `from' style
			if `"$publish_style"'=="" {
				di as error "An error occured while trying to open the template file `from'"
				di as error "The file does not exist or it is not a text file"
				exit
			}
			local from $publish_style
		}
	}

	
// Opening the file using the template	

	publish_writer `as' open , title(`title') from(`from')


// determining the location of language definitions + loading macro definitions	

	if `"`language'"'==""	local language  default
	FindStyle lang  `language' lang

	tempname flang
	local flag = 1
	file open `flang' using $publish_lang , read
	file read `flang' line
	while `flag'==1 {
		if r(eof)==1 	local flag = 0
		else {
			local char = substr(`"`line'"',1,1)
			local pos : list posof "//" in line
			if `pos'>1  {
				local line = substr(`"`line'"',1,index(`"`line'"',"//")-1)
			}
			if "`char'"!="*" & `pos'!=1  {
				local line : subinstr local line "=" "" , all
				gettoken macname line : line
				global publish_`macname' `line'
 			}
		}
		file read `flang' line
	}
	file close `flang'
end

program FindStyle
	args key name macname
	local file publish_`key'_`name'.style
	local adopath  `"$S_ADO"'
	local adopath : subinstr local adopath ";" "  " , all

	foreach w in `adopath' {
		local dir : sysdir `w'
		capture type `"`dir'`file'"'
		if _rc==0 {
			local found `"`dir'`file'"'
			continue , break
		}
		else {
			capture type `"`dir'style/`file'"'
			if _rc==0 {
				local found `"`dir'style/`file'"'
				continue , break
			}
		}			
	}
	if "`found'"=="" {
		di as error `"`file' not found along the adopath"'
	}
	global publish_`macname' `found'
end


program publish_close , sclass
	version 11
	local as $publish_doctype
	publish_writer `as' close `0'
	sret clear
	foreach w in file section doctype tabnum {
		macro drop publish_`w'
	}
end


*----------------------------------------------------------------------------
*
*	[2.1] TABLES OF STATISTICS I. publish des & publish sum
*
*----------------------------------------------------------------------------


program publish_des , sclass
	version 11
	syntax varlist  [, varname title(string asis) VTitle(string asis) * ]

// Handling options
	if "`varlist'"==""	{
		qui ds
		local varlist `r(varlist)'
	}

// Defining s-class macros
	local r = 0
	foreach var in `varlist' {
		local ++r
		GetVarLab `var'
		if `"`varname'"'!="" & `"`var'"'!=`"`s(varlab)'"' sret local r`r' `var' `s(varlab)'
		else sret local r`r' `s(varlab)'
		GetValueLab `var'
		if `"`s(deflist)'"'!=""  {
			local def `s(deflist)'.
			local def : subinstr local def ";." "." , all
		}
		else local def
		GetNotes `var'
		if `s(nnotes)'>0 {
			if `"`def'"'=="" local def `s(notes)'
			else local def `def' `s(notes)'
		}
		local def : subinstr local def ".." "." , all
		sret local r`r'c1  `def'
	}

	local ncol = 1
	// to be modified if notes allowed in separate column
	
	sret local nscol = 1
	sret local ncol  = `ncol'
	sret local ncol1 = 1
	sret local nrow  = `r'
	if `"`vtitle'"'=="" sret local r0c0 $publish_FirstColHead
	else sret local r0c0 `vtitle'
	sret local c1	 $publish_des_def
	// Manual setting of cellwidth
	sret local cw0 = 20
	sret local cw1 = 80
	
	// Writing the table
	CustomizeCols , `options'
 	local as $publish_doctype
	if `"`title'"'!="" 	publish_writer `as' table , title(`title') cellsplit(1)
	else publish_writer `as' table , cellsplit(1)
end



program publish_sum , sclass
	version 11
	syntax [varlist(fv)] [if] [in] [fw aw iw] ///
		[, varname Title(string asis) VTitle(string asis) by(varname) TOTal stats(string asis) STATistics(string asis) ndec(integer 3) asis  * ]
	marksample touse , novarlist
// Handling options

	if "`exp'" != "" {
        tempvar wt
		qui gen `wt' `exp'
		local weight weight([`weight' = `wt'])
	}
	if `"`statistics'"' != "" & `"`stats'"'=="" local stats `statistics'
	if `"`stats'"'=="" {
		if "`by'"==""	local stats N mean sd
		else			local stats mean
	}
	if "`varlist'"==""	{
		qui ds
		local varlist `r(varlist)'
	}
	MakeVarlist `varlist' , `asis' noconstant
	local varlist `s(varlist)'

//	Number of columns and supercolumns

	ParseStats , stats(`stats')
	if "`by'"!="" qui replace `touse' = 0 if `by'>=.
	GetValueLab `by' if `touse'==1	 , `total'
	if `s(ncat)'>1 & `s(nstat)'>1 {		 // Supercols needed
		local nscol = `s(ncat)'
		forval i = 1/`nscol' {
			sret local ncol`i' = `s(nstat)' 
			sret local sc`i'     `s(label`i')' 
		}
	}
	else local nscol = 1
	local ncol = `s(ncat)'*`s(nstat)'
	sret local nscol = `nscol'
	sret local ncol  = `ncol'
	if `"`vtitle'"'=="" sret local r0c0 $publish_FirstColHead
	else sret local r0c0 `vtitle'
	
// Collecting results + defining s macros	

	local nrow : word count `varlist'
	sret local nrow `nrow'
	
	local r = 0
	foreach var of local varlist {
		local ++r
		GetVarLab `var'
		if `"`varname'"'!="" & `"`var'"'!=`"`s(varlab)'"' sret local r`r' `var' `s(varlab)'
		else sret local r`r' `s(varlab)'
		if `s(fvbase)'==0 {
			local c = 0
			forval i = 1/`s(ncat)' {
				if "`by'"!="" local addif & `by'`s(cond`i')'
				qui su `var'  `weight' if `touse'==1 `addif'   , detail
				forval j = 1/`s(nstat)' {
					local ++c
					if `s(nstat)'>1 sret local c`c' `s(slab`j')'
					else sret local c`c' `s(label`i')'
					local num = r(`s(stat`j')')
					FormatNumber `num' `ndec'
					sret local r`r'c`c' `s(text)' 
				}
			}
		}
	}
	// Writing the table
	CustomizeCols , `options'
 	local as $publish_doctype
	if `"`title'"'!="" 	publish_writer `as' table , title(`title')  
	else publish_writer `as' table
end


*----------------------------------------------------------------------------
*
*	[2.2] Tables of statistics II. publish tab & publish table
*
*----------------------------------------------------------------------------

program publish_tab 
	syntax [anything] [, summarize(varname) contents(string) * ]
	if `"`summarize'"'!="" & `"`contents'"'!="" {
		di as error "You cannot specify both the summarize() and the contents() option"
		error 198
	}	
	if `"`summarize'"'!="" {
		publish_table `anything' ,  contents(mean `summarize')  `options'
		exit
	}
	if `"`contents'"'!="" {
		_publish_tab2 `anything' ,  contents(`contents') `options'
		exit
	}
	publish_tab1 `anything' ,  `options'
end


program publish_tab1 , sclass
	syntax varlist [if] [in] [fw aw iw ]  [, by(varlist min=1 max=1) VALue varname title(string asis) VTitle(string asis) ndec(integer 3) * ]
	marksample touse , novarlist
	if "`exp'" != "" {
		local w [`weight'`exp']
	}
	

// doing the job

	local nvar : word count `varlist'
	local tab
	//if `nvar'>1 local tab {TAB}
	local tab {TAB}
	
	local r = 0
	foreach var in `varlist' {
		// Varname
		//if `nvar'>1 {
		local ++r
		local varlab : variable label `var'
		if `"`varlab'"'==`""' local varlab `var'
		else if "`varname'"!="" local varlab `var' `varlab'
		sret local r`r' `varlab'
		//}
		//  Frequncies and percentages 
		qui su `var' `w' if `touse'==1 & `var'!=.
		local total = r(sum_w)
		GetValueLab `var' if `touse'==1	
		forval i = 1/`s(ncat)' {
			local ++r
			if "`value'"!="" & `"`s(label`i')'"'!="`i'" sret local r`r' `tab'`i' - `s(label`i')' 
			else sret local r`r' `tab'`s(label`i')' 
			qui su `var' `w' if `touse'==1 & `var'==`s(value`i')' & `var'!=.
			local n = r(sum_w)
			local p	= 100*`n'/`total'
			FormatNumber `n' `ndec'
			sret local r`r'c1 `s(text)' 
			FormatNumber `p' `ndec'
			sret local r`r'c2 `s(text)' 
		}
		//  Total
		local ++r
		sret local r`r' `tab'$publish_NameForTotal
		FormatNumber `total' `ndec'
		sret local r`r'c1 `s(text)' 
		sret local r`r'c2 100 
		//  Missing 
		qui count if `var'==. & `touse'==1
		local n = r(N)
		if `n'>0 {
			local ++r
			FormatNumber `n' `ndec'
			sret local r`r' `tab'Missing
			sret local r`r'c1 `s(text)'
		}
	}

	sret local nrow = `r'
	sret local nscol = 1
	sret local ncol = 2
	sret local c1 $publish_Frequency
	sret local c2 $publish_Percent
//	sret local c1 $publish_tab_freq
//	sret local c2 $publish_tab_percent
//	sret local c3 $publish_tab_valid
//	sret local c4 $publish_tab_cum
	if `"`vtitle'"'=="" sret local r0c0 $publish_FirstColHead
	else sret local r0c0 `vtitle'

	// Writing the table
	CustomizeCols , `options' 
 	local as $publish_doctype
	if `"`title'"'!="" 	publish_writer `as' table , title(`title') 
	else publish_writer `as' table
end


program publish_tab2 
	syntax [anything] [if] [in] [fw] [ , SUMmarize(string) Contents(string) * ]
	if `"`summarize'"'!="" & `"`contents'"'!="" {
		di as error "You cannot specify both the summarize() and the contents() option"
		error 198
	}	
	if `"`summarize'"'!="" {
		publish_table `anything' ,  contents(mean `summarize')  `options'
		exit
	}
	if `"`contents'"'=="" {
		di as error "The contents() option must be specified"
		error 198
	}
	if `"`weight'`exp'"'!="" local w [`weight'`exp']
	_publish_tab2 `anything' `if' `in' `w' , contents(`contents') `options'
end


program _publish_tab2 , sclass
	syntax varlist [if] [in] [iw] , Contents(string) ///
		[ by(varname) title(string asis) VTitle(string asis) ndec(integer 3)  * ]

	gettoken cell colvar : contents
	if inlist("`cell'","freq","row","col")==0 {
		di as error "First element of contents() option must be freq, row or col"
		error 198
	}
	capt confirm numeric variable `colvar'
	if _rc!=0 {
		di as error "`colvar' specified in the contents() option is not a numeric variable"
		error 198
	}
	if `"`by'"'!="" local by by(`by')

	marksample touse , novarlist
	*mark `touse' `ifinwgt'
	*markout `touse' `by'
	
// Options
	if "`cell'"=="row"  | "`cell'"=="freq"  	local rtot total 
	else if "`cell'"=="col" | "`cell'"=="freq"	local ctot total
	if "`exp'" != "" {
		local weight [`weight'`exp']
	}

// doing the job
	local nvar : word count `varlist'
	local tab
	//if `nvar'>1 local tab {TAB}
	local tab  {TAB}
	tempname mat
	local r = 0
	foreach var in `varlist' {
		local ++r
		// Varname
		if `nvar'>1 {
			sret local r`r' `var'
			local ++r
		}
		//  Contents (freq. or percentages)
		MakeMat_Tab2 `var' `colvar' if `touse'==1 `weight'  , cell(`cell')
		mat `mat' = r(mat)
		Mat2Sres `mat' , r(`r') ndec(`ndec')
		// Corresponding rownames
		GetValueLab `var' if `touse'==1
		forval i = 1/`s(ncat)' {
			sret local r`r' `tab'`s(label`i')' 
			local ++r
		}
		// Total / N
		if "`cell'"=="row"  local --r		// No total if row percentages + r must be decreased
		if "`cell'"=="freq" sret local r`r' `tab'$publish_NameForTotal
		if "`cell'"=="col"  sret local r`r' `tab'N
		
		//  Statistics
		
		//Missing
		/*
		qui count if `var'==. & `touse'==1
		local n = r(N)
		if `n'>0 {
			local ++r
			FormatNumber `n' `ndec'
			sret local r`r' `tab'Missing
			sret local r`r'c1 `s(text)'
		}
		*/
	}
	// Colnames
	GetValueLab `colvar' if `touse'==1 , `rtot'
	forval i = 1/`s(ncat)' {
		sret local c`i' `s(label`i')' 
	}
	// All other s macros
	sret local nrow = `r'
	sret local nscol = 1
	sret local ncol  `s(ncat)'
	
	// Writing the table
	CustomizeCols , `options'
 	local as $publish_doctype
	if `"`title'"'!="" 	publish_writer `as' table , title(`title') 
	else publish_writer `as' table
end



program publish_table , sclass
	version 11
	syntax varlist [if] [in] [fw aw iw] ///
		[ ,  Contents(string asis) by(varname) TOTal  ///
		ndec(integer 3) Title(string asis) VTitle(string asis) * 	 ]

// Options

	if  "`contents'"=="" | "`contents'"=="freq" {
		if "`by'"=="" publish_tab1 `varlist' , title(`title') ndec(`ndec') `ctitle' *
		else publish_tab2 `varlist' , by(`by') title(`title') ndec(`ndec') `ctitle' `col' `row' *
		exit
	}
	if "`exp'" != "" {
		local w [`weight'`exp']
	}
	marksample touse ,  novarlist
	if "`by'"!="" 	markout `touse' `by'
*		local nscol = 1
*	else {
*		local nscol = `s(nccat)'
*	}
	if "`row'"!="" & "`col'"!="" {
		di as error "Options col and row cannot be specified together"
		error 198
	}
	if "`row'"!="" {
		local rtot total
		local opt total(row)
	}
	if "`col'"!="" {
		local ctot total
		local opt total(col)
	}

//	Columns
	ParseContents `contents'
	GetValueLab `by' if `touse' , `ctot'   prefix(c)

	// doing the job
	local nvar : word count `varlist'
	local tab
	if `nvar'>1 local tab {TAB}
	tempname mat
	local r = 0
	foreach var in `varlist' {
		***************  Varname ******************
		if `nvar'>1 {
			local ++r
			sret local r`r' `var'
		}
		***************  Contents (freq. or percentages) ******************
 		***************  Corresponding rownames ******************
		GetValueLab `var' if `touse' , `total'	prefix(r)
		forval i = 1/`s(nrcat)' {
			local ++r
			sret local r`r' `tab'`s(rlabel`i')' 
			local c = 0
			forval j = 1/`s(nccat)' {
				if `s(nccat)'>1 local addif & `by'==`s(cvalue`j')' 
				foreach sv in `s(svarlist)' {
					qui su `sv' `w' if `touse'==1 & `var'==`s(rvalue`i')'  `addif'  , detail
					foreach stat in `s(stats_`sv')'	 {
						local ++c
						local n = r(`stat')
						FormatNumber `n' `ndec'
						sret local r`r'c`c' `s(text)'
					}
				}
			}
		}
		/*
		***************  Total / N ******************
		if "`total'"!="" {
			local ++r
		}local --r		// No total if row percentages + r must be decreased
		if "`cell'"=="freq" sret local r`r' `tab'$publish_NameForTotal
		if "`cell'"=="col"  sret local r`r' `tab'N
		*/
		
		***************  Statistics ******************
		
		***************  Missing ******************
		/*
		qui count if `var'==. & `touse'==1
		local n = r(N)
		if `n'>0 {
			local ++r
			FormatNumber `n' `ndec'
			sret local r`r' `tab'Missing
			sret local r`r'c1 `s(text)'
		}
		*/
	}

 	// All other s macros
	sret local nrow = `r'
	sret local nscol  `s(nccat)'
	local ncol = `s(nccat)'*`s(nstat)'
	sret local ncol	`ncol'
	// Default colnames
	forval i = 1/`s(nstat)' {
		sret local c`i' `s(slab`i')' 
	}
	// N of columns within supercolumns
	if `s(nccat)'>1 {
		forval i = 1/`s(nccat)' {
			sret local ncol`i' `s(nstat)' 
		}
	}

	// Writing the table
	CustomizeCols , `options'
 	local as $publish_doctype
	if `"`vtitle'"'!="" sret local r0c0 `vtitle'

	if `"`title'"'!="" 	publish_writer `as' table , title(`title') 
	else publish_writer `as' table
end


program MakeMat_Table , rclass
	version 11
	syntax varlist [if] [in] [fw aw iw pw] [ , summarize(varname) contents(string) total  * ]
	marksample touse , novarlist
	if "`weight'"=="pw" local weight iw
	if "`exp'"!="" local w [`weight'`exp']
	gettoken var by : varlist
	tempname table 
	
// Determining the dimension of matrix that contains the statistics for summarize var
	local ncol = `s(nccat)'*`s(nstat)'
	mat `table' = J(`s(nrcat)',`ncol',.)
	
	forval r = 1/`s(nrcat)' {
		local j = 0
		forval c = 1/`s(nccat)' {
			if "`by'"!="" local cond & `by'==`s(cvalue`c')'
			forval k=1/`s(nstat)' {
				local ++j
				qui su `s(svar`k')' `w' if `touse' & `var'==`s(rvalue`r')' `cond'
				mat `table'[`r',`j'] = r(`s(stat`k')')
			}
		}
	}
	return mat mat = `table'
end


*----------------------------------------------------------------------------
*
*	[2.3] Tables of statistics III. publish est
*
*----------------------------------------------------------------------------


program publish_est , sclass
	syntax  [anything] [, ///
			VARlist2(string) Cell(string) NOCONStant asis  eq(str asis) ///
			neq(integer 0) noanc STATS(str asis) STATistics(str asis) ///
			wide long  se t p ci ///
			bdec(integer 4)  tdec(integer 3) stdec(integer 3) ///
			STAR(numlist descending min=1 max=3 <1 >0) ///
			LEVel(numlist min=1 max=1 <100 >10)  ///
			TItle(str asis) VTitle(string asis)  * ]

// Taking care of old syntax, where varlist was specified in option varlist,
// and estimates were specified as main arguments

if "`varlist2'"!="" & "`cell'"=="" { // old syntax
	local varlist `varlist2'
	local estlist `anything'
} 
else { // new syntax
	local varlist `anything'
	local estlist `cell'
} 

// handling anything
	capt est dir `estlist'
	if _rc!=0 {
		di as error "Invalid list of estimation results"
		error 198
	}
	local estlist : list uniq estlist

// handling options
	local layout `wide' `long'
	if `"`layout'"'!="" {
		if `: word count `layout'' > 1 {
			di as error "Invalid layout() option: only one specification allowed"
			error 198
		}
		if `"`layout'"'!="long" & `"`layout'"'!="wide"  {
			di as error "Invalid layout specification option: `layout' not allowed"
			error 198
		}
	}
	// se t p ci + significance level
	if `: word count `se' `t' `p'`ci' ' > 1 {
		di as error "Only one of the -se-, -p- and -t- options may be specified"
		exit 198
	}
	if "`se'`t'`p'`ci'" == "" local se t
	else local se `se'`t'`p'`ci'
	if "`level'"==""	local level = c(level)
	if "`star'"=="" local star .05 .01 .001
	
//	Variable list
	if "`asis'"=="" {
		MakeVarlist `varlist' 
		local varlist `s(varlist)'
	}
	if "`constant'"!="noconstant" local varlist `varlist' _cons
	local varlist : list uniq varlist
	
	if `"`statistics'"' != "" & `"`stats'"'=="" local stats `statistics'
	**  if `"`stats'"'=="" local stats N "$publish_n"
	ParseStats  , stats(`stats') 

// Accumulating estimation results into matrices

	// Matrices storing b and V mats for Coefficients and Anc. parameters + est. statistics
	tempname cbmat cvmat csmat abmat avmat asmat stmat starmat 	
	tempname tbmat tvmat tsmat temp	// temporary
	tempname hcurrent esample
	_est hold `hcurrent', restore nullok copy
	
	local anything : list uniq anything
	local anclist		// list of potential anc. parameters
	local scol			// arguments of scol() == # of columns belonging to one scol
	local nscol = 0
	local ncol = 0
	local napeq = 0		// # of anc. 
	
	local loop = 0
	foreach est of local anything {
		local ++loop
		capt estimates restore `est'
		if _rc!=0 {
			di as error "Estimate name `est' not found"
			error 198
		}
		// Matrix of coefficients
		if `"`eq'"'=="" local keq = 0
		else local keq : word `loop' of `neq'
		ReshapeEstMat  `varlist' , est(`est') dim(`keq')  `anc'
		mat `tbmat' = r(b)
		mat `tvmat' = r(v)
		local neq = r(neq)
		local nap = r(nap)
		TransformSE `tvmat' `tbmat' `se' `level' `star'
		mat `temp' = r(mat)
		mat `cbmat' = nullmat(`cbmat') , `tbmat'
		mat `cvmat' = nullmat(`cvmat') , `tvmat'
		mat `csmat' = nullmat(`csmat') , `temp'
		// Incrementing counters, defining locals
		local firstcol = `ncol' + 1
		local ++nscol
		local ncol = `ncol' + `neq'
		local scol `scol' `neq'
		local ctitle `ctitle' `r(enames)'
		
		// Saving info about anc. parameters
		if "`anc'"!="noanc" & `nap'>0 {
			tempname abmat`nscol' avmat`nscol' asmat`nscol' 
			mat `abmat`nscol'' = r(abmat)
			mat `avmat`nscol'' = r(avmat)
			local names = r(anames)
			TransformSE `avmat`nscol'' `abmat`nscol'' `se' `level' `star'
			mat `asmat`nscol'' = r(mat)
			mat rownames `asmat`nscol'' = `names' 
			// List of anc. results
			local anclist `anclist' `r(anames)'
			local anclist : list uniq anclist
			local ablist `ablist' `firstcol' `abmat`nscol''
			local avlist `avlist' `firstcol' `avmat`nscol''
			local aslist `aslist' `firstcol' `asmat`nscol''
		}
		// Optional est stats
		if `s(nstat)'>0 {
			mat `tsmat' = J(`s(nstat)',1,.)
			forval r = 1/`s(nstat)' {
				local x = e(`s(stat`r')')
				mat `tsmat'[`r',1] = `x'
			}
			if `r(neq)'>1 {
				mat `temp' = J(`s(nstat)',`r(neq)'-1,.)
				mat `tsmat' = `tsmat' , `temp'
			}
			mat `stmat' = nullmat(`stmat') , `tsmat'
			local stopt stmat(`stmat')
		}
		// sreturn locals
		sret local ncol`nscol' = `neq'
		sret local sc`nscol' `est'
	}
	
	// Matrix of anc. parameters
	if "`anc'"!="noanc" & `"`anclist'"'!=`""' {
		local anclist : list uniq anclist
		local nrow : list sizeof anclist
		foreach w in b v s {
			mat `a`w'mat' = J(`nrow',`ncol',.)
			mat rownames `a`w'mat ' = `anclist'
			MatMerge `a`w'mat' `a`w'list'
			mat `c`w'mat' = `c`w'mat' \ `a`w'mat'
		}
	}
	
//	Transforming matrices to s-class macros 
	if "`layout'"=="" local layout = cond(`ncol'>2,"long","wide")
	//if "`layout'"=="wide" local ncol = 2*`ncol'
	if `s(nstat)'>0 local stopt `stmat' `stdec'
	EMat2SRes `layout' `cbmat' `bdec'  `cvmat' `tdec' `csmat' `stopt' 
	
//	Finalizing s-macros regarding column numbers and titles
	sret local nscol `nscol'
	sret local ncol `ncol'
	sret local scol `scol'
	local c = 0
	foreach w of local ctitle {
		local ++c
		sret local c`c' `w'
	}	
	
// Writing the table
	CustomizeCols , `options'
	local as $publish_doctype
	if "`layout'"=="wide" local cellsplit cellsplit(4)
	if `"`vtitle'"'!="" sret local r0c0  `vtitle'

	if `"`title'"'!="" 	publish_writer `as' table , title(`title') `cellsplit'
	else publish_writer `as' table , `cellsplit'
//	sret clear

end


capt program drop ReshapeEstMat
program ReshapeEstMat , rclass
	syntax anything [ , est(str) dim(integer 0) noanc ]
	tempname bold vold bnew vnew banc vanc mat vec anc
	tempname bold vold  // old and new estimation results + anc parameters
	tempname tb tv mat vec anc // temporary matrices
	
	// Stripping "redundant" equations (baseline eq., ancillary parameters)
	mat `bold' = e(b)
	mat `vold' = vecdiag(e(V))
	local fnames : coleq `bold' , quoted
	local unames : list uniq fnames
	local size : list sizeof unames
	// Check number of equations / consistency of saved results
	if `dim'==0 {
		local dim = 0
		if "`e(k_eq_model)'"!="" local dim = `e(k_eq_model)'
		else if "`e(k_eq)'"!="" local dim = `e(k_eq)'
		else if "`e(k_aux)'"!="" {
			local dim = `size'-`e(k_aux)'
			if "`e(k_eq)'"!="" local dim = `e(k_eq)'-`e(k_aux)'
		}
		if `dim'==0 {
			di as error "Using e() results, publish failed to determine the number of equations"
			di as error "The number of equation numbers (=`size') will be used..."
			local dim = `size'
		}
	}

	local neq = 0
	local nap = 0
	forval i = 1/`size' {
		local eq : word `i' of `unames'
		mat `tb' = `bold'[1,"`eq':"]
		mat `tv' = `vold'[1,"`eq':"]
		EqStatus `i' `size' `dim'
		local status `s(status)'
		if `status'==1 {
			local ++neq
			ret local eqname`neq' `eq'
			mat `bnew' = nullmat(`bnew') , `tb'
			mat `vnew' = nullmat(`vnew') , `tv'
			local enames `enames' `eq'
		}
		else if `s(status)'==2 {
			local ++nap
			local ncol = colsof(`tb')
			mat `banc' = nullmat(`banc') \ `tb'
			mat `vanc' = nullmat(`vanc') \ `tv'
			local anames `anames' `eq'
		}
	}
	
	// Reshaping estimation results
	mat `bold' = `bnew'
	mat `vold' = `vnew'
	//if `r(nap)'>0  mat `a' = r(a)
	local varnames : colnames `bold'
	local fullenames : coleq `bold' , quoted
	//local ncol : list sizeof equnames
	local nrow : list sizeof anything
	mat `bnew' = J(`nrow',`neq',.)
	mat `vnew' = J(`nrow',`neq',.)
	local pos = 0
	local nanc = 0
	foreach var of local varnames {
		local ++pos
		local eq  : word `pos' of `fullenames'
		local eq  : subinstr local eq  `"""' ""
		local row : list posof "`var'" in anything
		local col : list posof `"`eq'"' in enames
		if `row'!=0 & `col'!=0 {
			local coef = `bold'[1,`pos'] 
			mat `bnew'[`row',`col'] = `coef'
			local coef = `vold'[1,`pos'] 
			mat `vnew'[`row',`col'] = `coef'
		}
	}

	// Delete empty columns
	//DelEmptyCol `mat' `nrow' `ncol' `equnames'

	// Return results
	if "`anc'"!="noanc" & `nap'>0 {
		mat rownames `banc' = `anames'
		mat rownames `vanc' = `anames'
		return local nap `nap'
		return local anames `anames'
		return mat abmat = `banc'
		return mat avmat = `vanc'
	}
	else return local nap = 0
	return local neq = `neq'
	// Return results
	mat rownames `bnew' = `anything'
	mat colnames `bnew' = `enames'
	mat rownames `vnew' = `anything'
	mat colnames `vnew' = `enames'
	***mat list `mat'
	return mat b = `bnew'
	return mat v = `vnew'
	return local enames `enames'
	exit
end



capt program drop EqStatus 
program EqStatus , sclass
	args eq neq keq
	if `keq'>0 {
		if `eq'<=`keq' sret local status 1
		else sret local status 2
		exit
	}
	// EqStatus returns 0 if baseline eq in mlogit/mprobit
	//                  1 if proper equation
	//                  2 if equation containing anc. parameters
	if "`e(k_eq_model)'`e(k_aux)'`e(k_eq_model_skip)'"=="" {
		sret local status 1
		exit
	}
	// Base category in mlogit
	if "`e(k_eq_model_skip)'"!="" {
		local status = cond(`eq'==`e(k_eq_model_skip)',0,1)
	}
	else if "`e(k_eq_model)'`e(k_aux)'"!="" {
		if "`e(k_eq_model)'"=="" local k = `e(k)'-`e(k_aux)'
		else local k = `e(k_eq_model)'
		local status = cond(`eq'<=`k',1,2)
	}
	sreturn local status `status'
	exit
end

program SelectEqNames , sclass
	syntax anything , names(string) use(string)
end

program TransformSE , rclass
	gettoken vmat 0 : 0
	gettoken bmat 0 : 0
	gettoken opt  0 : 0
	gettoken level 0 : 0
	local nrow = rowsof(`vmat')
	local ncol = colsof(`vmat')
	tempname mat
	mat `mat' = J(`nrow',`ncol',0)

	forval r = 1/`nrow' {
		forval c = 1/`ncol' {
			local se = `vmat'[`r',`c']
			local se = sqrt(`se')
			local b = `bmat'[`r',`c']
			if `"`e(df_r)'"'!=""	local p = ttail(`e(df_r)',abs(`b'/`se'))	
			else local p = 2*normprob(-abs(`b'/`se'))
			// Transforming variance
			if "`opt'"=="t" {
				local se = abs(`b'/`se')
			}
			else if "`opt'"=="p" {
				local se = `p'
			}
			else if "`opt'"=="ci" {
				if "`level'"=="" local level = c(level)
				if "`e(df_r)'"!=""	local se = abs(invttail(`e(df_r)',.5-`level'/200))*`se'
				else		local se = abs(invnorm(.5-`level'/200))*`se'
			}
			mat `vmat'[`r',`c'] = `se'
			// Matrix of significance stars
			local k = 0
			foreach w of local 0 {
				if `p'<`w' local ++k
			}
			if `k'>0 mat `mat'[`r',`c'] = `k'
		}
	}
	// Matrix of stars
	return add
	return mat mat = `mat'
end


capt program drop MatMerge
program MatMerge
	gettoken master 0 : 0
	local varlist : rownames `master'
	while "`0'"!="" {
		gettoken col 0 : 0
		gettoken matuse 0 : 0
		local rownames : rownames `matuse'
		local nrow = rowsof(`matuse')
		forval r = 1/`nrow' {
			local name : word `r' of `rownames'
			local row : list posof "`name'" in varlist
			local x = `matuse'[`r',1]
			if `row'>0 mat `master'[`row',`col'] = `x'
		}
	}
end

capt program drop EMat2SRes
program EMat2SRes , sclass
	args layout bmat bdec vmat vdec smat statmat stdec	
	local nrow = rowsof(`bmat')
	local ncol = colsof(`vmat')
	local varlist : rownames `bmat'
	local nbaserow = 0		// Base factor variables
	
	forval i = 1/`nrow' {
		local var : word `i' of `varlist'
		if "`layout'"=="long" local rb = 2*`i'-1-`nbaserow'
		else local rb = `i'
		//IsFactorVar `var'
		GetVarLab `var'
		sret local r`rb' `s(varlab)'
		if "`s(fvstatus)'"=="b" {
			if "`layout'"=="long" local ++nbaserow
			local lastcol = 0
		}
		else local lastcol = `ncol'
		
		forval j = 1/`lastcol' {	
			foreach w in b v {
				local `w' = ``w'mat'[`i',`j']
				FormatNumber ``w'' ``w'dec'
				local `w'text `s(text)'
			}
			local s = `smat'[`i',`j']
			local stars
			if `s'<. & `b'<. {
				forval k = 1/`s' {
					local stars `stars'*
				}
			}
			if `v'<. local vtext (`vtext')
			local r = `rb'
			local c = `j'
			// if wide taken seriously:  local c = cond("`layout'"=="long",`j',2*`j'-1)
			sret local r`r'c`c' `btext'`stars'
			if "`layout'"=="long" local ++r
			// Without increasing c, wide behaves as onecol
			//else local ++c		
			sret local r`r'c`c' `vtext'
			// wide behaves as onecol
			if "`layout'"=="wide" {
				sret local r`r'c`c' `btext'`stars' `vtext'
			}
		}
	}
	sret local nrow `r'
	if "`statmat'"!="" 	EMat2SRes_statmat `layout'  `r' `statmat' `stdec'
end


capt program drop EMat2SRes_statmat
program EMat2SRes_statmat , sclass
	args layout firstrow mat  ndec
	local nrow = rowsof(`mat')
	local ncol = colsof(`mat')
	forval i = 1/`nrow' {
		local r = `firstrow' + `i' 
		sret local r`r' `s(slab`i')'
		forval j = 1/`ncol' {
			local c = cond("`layout'"=="long" , `j' , 2*`j'-1)
			local x = `mat'[`i',`j']
			FormatNumber `x' `ndec'
			local x `s(text)'
			sret local r`r'c`c' `x'
		}
	}
	local nrow = `firstrow'+`nrow'
	sret local nrow `r'
end



*----------------------------------------------------------------------------
*
*	[3.1] UTILITIES I. empty table
*
*----------------------------------------------------------------------------


program publish_empty , sclass
	syntax  [ , ctitle(string asis) ROWnames(string asis) title(string) VTitle(string asis) * ]
	
	if `"`ctitle'"'=="" {
		di as error "The ctitle() option must be specified"
		error 198
	}
	if `"`rownames'"'=="" {
		di as error "The rownames() option must be specified"
		error 198
	}
	local ncol : list sizeof ctitle
	forval c = 1/`ncol' {
		local text : word `c' of `ctitle'
		sret local c`c' `text'
	}
	local nrow : list sizeof rownames
	forval r = 1/`nrow' {
		local text : word `r' of `rownames'
		sret local r`r' `text'
	}

	sret local nrow `nrow'
	sret local ncol `ncol'
	sret local nscol 1
	sret local ncol1 `ncol'
	
	// Set up s macros
	
	// Writing the table
	CustomizeCols , ctitle(`ctitle') `options'
 	local as $publish_doctype
	if `"`vtitle'"'!="" sret local r0c0 `vtitle'
	if `"`title'"'!="" publish_writer `as' table , title(`title') 
	else publish_writer `as' table
end


*----------------------------------------------------------------------------
*
*	[3.2] UTILITIES II. publish data and matrices
*
*----------------------------------------------------------------------------


program publish_data , sclass
	version 11
	syntax [varlist] [if] [in] [ , ROWnames(string asis) title(string asis) VTitle(string asis) ndec(integer 3) * ]

	if `"`rownames'"'=="" {
		di as error "The rownames() option must be specified"
		error 198
	}
	capt confirm var `rownames'
	if _rc==0 local rowtype var
	else local size : list sizeof rownames
	
	tempvar touse
	mark `touse' `if' `in'
	qui count if `touse'==1
	local nrow = r(N)
	if "`rowtype'"==""  {
		if `nrow'!=`size' {
			di as error "Number of items in rownames() option differs from number of observations to be displayed"
			error 198
		}
	}
	preserve
	nobreak {
		keep if `touse'==1
		if "`rowtype'"=="var" qui keep `rownames' `varlist'
		else qui keep `varlist'
		forval r = 1/`nrow' {
			if "`rowtype'"=="var" {
				local v = `rownames'[`r']
				capt confirm numeric var `rownames'
				if _rc==0 {
					local lab : label (`rownames') `v'
					local v `lab'
				}
			}
			else local v : word `r' of `rownames'
			sret local r`r' `v'
			local c = 0
			foreach var of local varlist {
				local  ++c
				local v = `var'[`r']
				FormatNumber `v' `ndec'
				sret local r`r'c`c' `s(text)'
			}
		}
	}
	restore
	
	local ncol : list sizeof varlist
	sret local nrow `nrow'
	sret local ncol `ncol'
	sret local nscol 1
	sret local ncol1 `ncol'
	local c = 0
	foreach var of local varlist {
		local ++c
		sret local c`c' `var'
	}
	
	// Writing the table
	CustomizeCols ,  `options'
 	local as $publish_doctype
	if `"`vtitle'"'!="" sret local r0c0 `vtitle'
	if `"`title'"'!="" publish_writer `as' table , title(`title') 
	else publish_writer `as' table
end



program publish_mat , sclass
	syntax anything [ , ROWnames(string asis) upper lower ndec(integer 3) title(string asis) VTitle(string asis) asis * ]

	tempname mat
	capture mat `mat' = `anything'
	// list of matrices must also be allowed in the future
	if _rc!=0 {
		di as error "Matrix `anything' not found"
		exit
	}
	
// Handling options

	if `"`rtitle'"'!=""		local rtitle rtitle(`rtitle')
	
// Extracting info from matrix
	local nrow = rowsof(`mat')
	local ncol = colsof(`mat')
***	foreach word in colnames coleq rownames roweq colfullnames rowfullnames {
	foreach word in colnames coleq rownames roweq  {
		if substr("`word'",4,5)=="eq"	local `word' : `word' `mat' , quoted
		else 				local `word' : `word' `mat'
	}
	local colequniq  : list uniq coleq
	local nscol : word count `colequniq'
	if `nscol'>1 {
		forval i = 1/`nscol' {
			local word: word `i' of `colequniq'
			local temp : subinstr local coleq "`word'" " "	, word count(local count) all
			local ncol`i' = `count'
			sret local ncol`i' `count'
			sret local sc`i'   `word'
		}
	}


/*
// Reshaping the matrix

	if "`asis'"=="" {
		local roweq  : list uniq roweq
		if `"`roweq'"'!="" {
			foreach word in `roweq' {
				local rowfullnames : subinstr local rowfullnames "`word':" "`word' `word':"
				local rowfullnames : subinstr local rowfullnames "`word':" " " , all
			}
			local I : word count `rowfullnames'
			local J = colsof(`mat')
			local Nroweq : word count `roweq'
			tempname macc row part
			mat `row' = J(1,`J',.z)

			forval r = 1 / `Nroweq' {
				local rowname : word `r' of `roweq'
				mat `part' = `mat'["`rowname':",1..`J']
				if `r'==1	mat `macc' = `row'  \ `part'
				else		mat `macc' = `macc' \ `row'  \ `part'
			}
			mat `mat' = `macc'
			mat roweq `mat' = ":"
			mat rownames `mat' = `rowfullnames'
		}
	}
	
	local nrow  = rowsof(`mat')
	local ncol  = colsof(`mat')
	local nscol : word count `coleq'

	//mat list `mat'
	//exit
	// Writing matrix to table
*/
	Mat2Sres `mat' , ndec(`ndec')
	
  	// All other s macros
	sret local nrow `nrow'
	sret local ncol `ncol'
	sret local nscol = `nscol'
	// Colnames and supercolnames
	if `"`ctitle'"'==""  local ctitle  `colnames'
	if `"`sctitle'"'=="" local sctitle `coleq'
	forval i = 1/`ncol' {
		local text : word `i' of 
		sret local c`i' `text' 
	}
	// Default Rownames
	forval i = 1/`nrow' {
		local text : word `i' of `rownames'
		sret local r`i' `text' 
	}
	// N of columns within supercolumns
	/*
	if `nscol'>1 {
		forval i = 1/`s(nccat)' {
			sret local ncol`i' `s(nstat)' 
		}
	}
	
	sret list
	
	*/
	// Writing the table
	CustomizeCols , ctitle(`ctitle') `options'
 	local as $publish_doctype
	if `"`vtitle'"'!="" sret local r0c0 `vtitle'
	if `"`title'"'!="" publish_writer `as' table , title(`title') 
	else publish_writer `as' table
end
 

program Mat2Sres , sclass
	syntax anything [ , r(integer 1) c(integer 1) ndec(string) ]
	local mat `anything'
	capt mat list `mat'
	if _rc!=0 {
		di as error "`mat' is not a matrix name"
		error 198
	}
	local nr = rowsof(`mat')
	local nc = colsof(`mat')
	forval i = 1/`nr' {
		forval j = 1/`nc' {
			local x = `mat'[`i',`j']
			if "`ndec'"!="" {
				FormatNumber `x' `ndec'
				local x `s(text)'
			}
			local rid = `i'+`r'-1
			local cid = `j'+`c'-1
			sret local r`rid'c`cid' `x'
		}
	}
end


*----------------------------------------------------------------------------
*
*	[3.3] Utilities III. Add text
*
*----------------------------------------------------------------------------

program publish_text , sclass
	version 11
	local as $publish_doctype
	publish_writer `as' text `0'
end





*---------------------------------------------------------------------------
*
* [4] COMMON SUBROUTINES 
*
*---------------------------------------------------------------------------

  
*--------------------------------------------------------------------------------------
*
* Format numbers
*
*--------------------------------------------------------------------------------------


program FormatNumber , sclass
	args num ndec
	***** Is num a number? ******
	capture confirm number `num'
	if _rc!=0 {
		sret local text `num'
		exit
	}
	***** Treatment of missing values ******
	if `num'==.o {
		sret local text (omitted)
		exit
	}
	if `num'==.e {
		sret local text (empty)
		exit
	}
	if `num'==.b {
		sret local text (base)
		exit
	}
	if `num'>=. {
		sret local text
		exit
	}
	***** Integers do not need formatting ******
	capture confirm integer number `num'
	if _rc==0 {
		sret local text `num'
		exit
	}
	***** Format nonintegers ******
	local num = round(`num' , 10^(-`ndec'))
	local int = substr("`num'",1,strpos("`num'", ".")-1)
	if "`int'"=="" | "`int'"=="-" local int `int'0
	local dec = substr("`num'",strpos("`num'", ".")+1,`ndec')
	if length("`dec'")<`ndec' {
		local dec = "`dec'" + substr("000000000000",1,`ndec'-length("`dec'") )
	}
	local text "`int'.`dec'"
	sret local text `text'
end



*--------------------------------------------------------------------------------------
*
* Obtain variable list
*
*--------------------------------------------------------------------------------------


capt program drop MakeVarlist
program MakeVarlist , sclass
	version 11
	syntax varlist(fv) [ , noCONStant asis base ]
	local isfv 
	if "`asis'"!="" {
		sret local varlist `varlist'
		exit
	}
//	Does the varlist containt factor variables?
	if strpos("`0'","#")==0 & strpos("`0'",".")==0 {
		sret local varlist `varlist'
		exit
	}
//	Unabbreviating factor variables
// Rearrange blocks: main effects come first...
	fvunab blocks : `varlist'
	local max = 0
	foreach w of local blocks {
		local t1 : subinstr local w "#" " " , count(local level) all
		local max = max(`max',`level')
		// Squares be treated as normal variables
		local t2 : list uniq t1
		local t3 : subinstr local t2 "c." " " , count(local m) all
		local n1 : list sizeof t1
		local n2 : list sizeof t2
		if `n2'<`n1' & `m'>0 local level = `level'-(`n1'-`n2')
		local block`level' `block`level'' `w'
	}
	local blocks
	forval b = 0/`max' {
		local blocks `blocks' `block`b''
	}
//	Change order for factor vars: baseline comes first
	if `"`base'"'!="" {
		sret local varlist `names'
		exit
	}
	local newlist
	foreach w of local blocks {
		fvexpand `w'
		local term `r(varlist)'
		local termlist
		foreach item of local term {
			local tmp : subinstr local item "#" " " , count(local nhash) all
			local tmp : subinstr local item "b." " " , count(local nbase) all
			if `nbase'==0 local termlist  `termlist' `item'
			else {
				if `nbase'-`nhash'==1 local termlist `item' `termlist'
				ExtractVarnames `item'
				local termlist `s(varnames)' `termlist'
			}
		}
		local termlist : list uniq termlist
		local newlist `newlist' `termlist'
	}
	local newlist : list uniq newlist
	//sret local varlist `newlist'
	local varlist
	foreach v of local newlist {
		if strpos("`v'","o.")==0 /*& strpos("`v'","b.")==0 */ local varlist `varlist' `v'
	}
	sret local varlist `varlist' 
end

capt program drop ExtractVarnames
program ExtractVarnames , sclass
	local list : subinstr local 0 "#" " " , all
	local list : list uniq list
	local varnames
	foreach item of local list {
		local name = substr("`item'",strpos("`item'",".")+1,.)
		local varnames `varnames' `name'
	}
	sret local varnames `varnames'
end

  
*--------------------------------------------------------------------------------------
*
* Obtain (variable and value) labels and notes
*
*--------------------------------------------------------------------------------------


program GetVarLab , sclass
	version 11
	IsFactorVar `0'
	if `s(fvvar)'==0 {
		ReturnVarLab `0'
		exit
	}
	if `s(fvvar)'==1 {
		GetFactorVarLab `0'
		if `s(fvbase)'==0 sret local varlab {TAB}`s(varlab)'
		exit
	}
	// Processing product terms, that is `s(fvvar)'==2
	local new : subinstr local 0 "#" " # " , all
	local label
	foreach word of local new {
		if "`word'"=="#" local label `label' X
		else {
			GetFactorVarLab `word'
			local label `label' `s(varlab)' 
		}
	}
	if `s(fvbase)'==0 sret local varlab {TAB}`label'
	else sret local varlab `label'
end


capt program drop IsFactorVar 
program IsFactorVar , sclass
	args var
	if strpos("`var'",".")==0 {
		sret local fvvar 0
		sret local fvbase 0
		exit
	}
	// Is factor var an interaction term?
	if strpos("`var'","#")==0 local fvvar=1
	else local fvvar=2
	sret local fvvar `fvvar'
	/*
	// Omitted category?
	if strpos("`var'","o.")!=0 {
		sret local fvstatus o
		exit
	}
	// Base category?
	if strpos("`var'","b.")!=0 local fvbase=1
	else local fvbase=0
	sret local fvbase `fvbase'
	*/
end


program GetFactorVarLab , sclass
	local token : subinstr local 0 "." " " , all
	local num : word 1 of `token'
	local var : word 2 of `token'
	// Treatment of base factors
	/*
	if `s(fvbase)'==1 {
		ReturnVarLab `var'
		exit
	}
	*/
	// Treatment of continuous vars
	if "`num'"=="c" {
		ReturnVarLab `var'
		sret local fvbase 0
		exit
	}
	foreach w in b n o {
		local num : subinstr local num "`w'" ""
	}
	local label : label (`var') `num'
	if `"`label'"'=="" local label `value'
	sret local varlab `label'
end



capt program drop ReturnVarLab
program ReturnVarLab , sclass
	capt confirm var `0'
	if _rc!=0 {
		sret local varlab `0'
		exit
	}
	local label : var lab `0'
	if `"`label'"'==`""' sret local varlab `0'
	else sret local varlab `label'
	* Changing case of varname might be added before returning.....
end


program GetValueLab , sclass
	version 11
	syntax [varlist(default=none)] [if] [ , total prefix(string)  ]
	if `"`varlist'"'=="" {
		sret local n`prefix'cat = 1
		exit
	}
	capt confirm numeric var `varlist'
	if _rc!=0 {
		sret local vtype string
		exit
	}
	sret local vtype numeric
	tempname mat 
	qui tab `varlist' `if'  , matrow(`mat')
	local dim = rowsof(`mat')
	forval x = 1/`dim' {
		local value = `mat'[`x',1]
		local label : label (`varlist') `value'
		// Return labels separately
		capt confirm number `label' 
		if _rc!=0	local deflist "`deflist' `value'=`label';"
		sreturn local `prefix'value`x' `value'
		sreturn local `prefix'cond`x'  "==`value'"
		sreturn local `prefix'label`x' `label'
	}
	if "`total'"!="" {
		local dim = `dim'+1
		sret local label`dim' $publish_NameForTotal
		sret local cond`dim'  "!=."
	}
	sreturn local n`prefix'cat = `dim'
	sreturn local deflist   `deflist'
	Return matrix cat = `mat' 
end


program GetNotes , sclass
	version 11
	local nnotes : char `0'[note0]
	if "`nnotes'"=="" {
		sret local nnotes 0
		exit
	}
	forval i = 1/`nnotes' {
		local note : char `0'[note`i']
		local notes `notes' `note'.
	}
	sret local notes `notes'
	sret local nnotes `nnotes'
end


program Return , rclass
	return clear
	return `0'
end




*--------------------------------------------------------------------------------------
*
*	MakeMat__ subroutines
*
*--------------------------------------------------------------------------------------

program MakeMat_Tab1 , rclass
	version 11
	syntax varlist [fw aw iw pw]
	gettoken var touse : varlist
	if "`exp'" != "" 	local w [`weight'`exp']
	tempname table freq mat
	qui tab `var' `w' if `touse' , matcell(`freq')
	local nrow = rowsof(`freq')
	forval r=1/`nrow' {
		local f = `freq'[`r',1]
		local f = round(`f',1)
		mat `freq'[`r',1] = `f'
	}
	qui su  `var' `w'  if `touse'
	local count = r(sum_w)
	local count = round(`count',1)
	mat `table'=100*`freq'/`count'
	mat `table' = `freq' , `table'
	mat `freq' = ( `count' , 100 )
	mat `mat' = `table' \ `freq' 
	return mat mat = `mat'
end

program MakeMat_Tab2 , rclass
	syntax varlist [if] [fw aw iw] [ , cell(string) * ]
	marksample touse
	gettoken var by : varlist
	if "`exp'"!="" {
		local w [`weight'`exp']
	}
	qui su `w' if  `touse'
	local  n =  r(sum_w)
	
	tempname table rowtotal coltotal nobs 
 	
	mat `nobs' = J(1,1,`n')
	qui tab `var' `by' `w' if `touse'==1 , matcell(`table')  
	qui tab `var'      `w' if `touse'==1 , matcell(`coltotal')
	tab       `by' `w' if `touse'==1 , matcell(`rowtotal')
	mat `rowtotal' = `rowtotal''
	if "`cell'"=="row" {
		mat `table' = 100*inv(diag(`coltotal'))*`table'
		mat `table' = `table' , `coltotal'
		if "`total'"!="" {
			mat `rowtotal' = 100*`rowtotal'/`n'
			mat `rowtotal' = `rowtotal' , `nobs'
			mat `table'    = `table'  \ `rowtotal'
		}
	}
	else if "`cell'"=="col" {
		mat `table' = 100*`table'*inv(diag(`rowtotal'))
		mat `table' = `table' \ `rowtotal'
		if "`total'"!="" {
			mat `coltotal' = 100*`coltotal'/`n'
			mat `coltotal' = `coltotal' \ `nobs'
			mat `table'    = `table'  , `coltotal'
		}
	}
	else if "`cell'"=="freq"  {
			mat `table'    = `table'    \ `rowtotal'
			mat `coltotal' = `coltotal' \ `nobs'
			mat `table'    = `table'  , `coltotal'
	}
	return mat mat = `table'
end



*--------------------------------------------------------------------------------------
*
*	Parse____ subroutines
*
*--------------------------------------------------------------------------------------


program ParseCells, sclass
	version 11
	local nstat = 0
	while `"`0'"'!="" & `"`0'"'!=" " {
		// Statistics name and varname
		gettoken stat 0 : 0 
		IsStatName cells `stat'
		gettoken var  0 : 0 
		capture confirm var `var'
		if _rc!=0 {
			di as error "Text - " `"`var'"' " - found where a variable name expected"
			error 198
		}
		local ++nstat
		sret local stat`nstat' `stat'
		sret local svar`nstat'  `var'
		// Label for statname / varname combination
		gettoken text 0 : 0 , qed(flag)
		if `flag'==0 {
			sret local slab`nstat' `stat' `var'
			local 0 `text' `0'
		}
		else {
			// local text : subinstr local text " " "@" , all
			sret local slab`nstat' `text'
		}
	}
	sret local nstat = `nstat'
	sret local stats `statlist'

end


program ParseContents, sclass
	local statlist
	local svarlist
	local nstat = 0
	****  Collecting vars and statnames ***********
	while `"`0'"'!="" & `"`0'"'!=" " {
		// Statistics name and varname
		gettoken stat 0 : 0 
		IsStatName contents `stat'
		local stat `s(stat)'
		gettoken var  0 : 0 
		capture confirm var `var'
		if _rc!=0 {
			di as error "Text - " `"`var'"' " - found where a variable name expected"
			error 198
		}
		local ++nstat
		sret local slab`nstat' `stat'(`var')
		local statlist `statlist' `stat'
		local svarlist `svarlist' `var'
		local `var'_`stat' 1
		
	}
	sret local nstat `nstat'
	****  Lists of statistics for each var ***********

	local vlist : list uniq svarlist
	local slist : list uniq statlist
	foreach v in `vlist' {
		local stats_`v'
		foreach s in `slist' {
			if "``v'_`s''"=="1" {
				local  stats_`v' `stats_`v'' `s'
			}
		}
		sret local stats_`v' `stats_`v''
	}
	sret local svarlist `vlist'

end


program IsStatName , sclass
	args  opt name
	if `"`name'"'=="n" |  `"`name'"'=="count"  local name N
	local allowed N sum_w mean Var sd skewness kurtosis sum min max p1 p5 p10 p25 p50 p75 p90 p95 p99
	local temp : subinstr local allowed "`name'" " " , word count(local c)
	if `c'==0 {
		di as error "`name' is not allowed in the `opt' option"
		error 198
	}
	sret local stat `name'
end



program ParseStats , sclass
	syntax [ , stats(string asis) prefix(string) ]
	if `"`stats'"'=="" {
		sret local n`prefix'stat = 0
		exit
	}
	local nstat = 0
	while `"`stats'"'!="" {
		gettoken stat stats : stats , qed(flag)
		if `flag'==1 {
			di as error "Text - " `"`stat'"' " - found between quotes where a statistic expected"
			error 198
		}
		local ++nstat
		sret local `prefix'stat`nstat' `stat'
		local statlist `statlist' `stat'
		gettoken text stats : stats , qed(flag)
		if `flag'==0 {
			sret local `prefix'slab`nstat' `stat'
			local stats `text' `stats'
		}
		else {
			// local text : subinstr local text " " "@" , all
			sret local `prefix'slab`nstat' `text'
		}
	}
	sret local n`prefix'stat = `nstat'
	sret local `prefix'stats `statlist'

end


*--------------------------------------------------------------------------------------
*
* Customizing column titles and width, supercolumn definitions and titles
*
*--------------------------------------------------------------------------------------


program CustomizeCols , sclass
	syntax [ , TABWidth(integer 90) VARWidth(integer 0) CWidth(numlist) CTitle(string asis)  SCol(numlist) SCTitle(string asis)  * ]
*	local ncol = `s(ncol)'
	// Checks
	if `varwidth'>40 {
		di as error "Width of the column displaying variables cannot exceed 40"
		error 198
	}
	// Width of the table
	sret local tabwidth `tabwidth'
	// Deleting superfluous supercolums
	if `s(nscol)'==`s(ncol)' {
		forval i = 1/`s(ncol)' {
			if "`sc`i''"!="" sret local c`i' `sc`i'' 
		}
		sret local nscol 1
		sret local ncol1 = `s(ncol)'
	}
	// Does the user modify supercolumn structure?
	if "`scol'"!="" {
		local n = 0
		local i = 0
		foreach w of local scol {
			local n = `n'+`w'
			local ++i
			sret local ncol`i' `w'
		}
		if `n'!=`s(ncol)' {
			di as error "Sum of elements in scol() option differs from the number of columns"
			error 198
		}
		local n : list sizeof scol
		sret local nscol `n'
	}
	// Parsing ctitles
	if `"`ctitle'"'!=`""' {
		local n : word count `ctitle'
		if `n'!=`s(ncol)' {
			di as error "Warning:
			di as error "  Number of elements in ctitle() differs from the number of colums"
			di as error "  The first `ncol' elements will be used for labeling the `s(ncol)' colums"
		}
		forval i = 1/`n' {
			local text : word `i' of `ctitle'
			sret local c`i' `text'
		}
	}
	// SuperColumn titles
	if `"`sctitle'"'!=`""' {
		local n : word count `sctitle'
		if `n'!=`s(nscol)' {
			di as error "Warning:
			di as error "  Number of elements in sctitle() differs from the number of supercolums"
			di as error "  The first `s(nscol)' elements will be used for labeling the `s(nscol)' supercolums"
		}
		forval i = 1/`n' {
			local text : word `i' of `sctitle'
			sret local sc`i' `text'
		}
	}

	// Column width
	if `varwidth'>0 sret local cw0 = `varwidth'
	else sret local cw0 = cond(`s(ncol)'<7,40,30)
	if `"`cwidth'"'!=`""' {
		local nc : word count `cwidth'
		if `nc'!=`s(ncol)' {
			di as error "The cwidth() option contains `nc' elements, but the number of columns is `s(ncol)'"
			error 198
		}
		local check = `s(cw0)'
		// local cw0 = $publish_TableWidth
		forval i = 1/`nc' {
			local cw`i' : word `i' of `cwidth'
			sret local cw`i' `cw`i''
			local check = `check'+`cw`i''
		}
		if `check'>100 {
			di as error "You requested a table which is wider than 100 percent"
			di as error "  Sum of elements in cwidth() + `varwidth' specified in varwidth() > 100"
			di as error "  Plese specify other numbers in cwidth() or another number in varwidth()"
			error 198
		}
	}
	//else CalcCellWidth `s(ncol)'
	else {
		local cw = (100-`s(cw0)')/`s(ncol)'
		forval i = 1/`s(ncol)' {
			sret local cw`i' `cw'
		}
	}
	// SuperColumn width
	if `s(nscol)'>1 {
		local c = 0
		forval i = 1/`s(nscol)' {
			local scw`i' = 0
			forval j = 1/`s(ncol`i')' {
				local ++c
				local scw`i' = `scw`i'' + `s(cw`c')'
			}
			sret local scw`i' `scw`i'' 
		}
	}
end


program CalcCellWidth , sclass
	args ncol
	local cw = (100-`s(cw0)')/`ncol'
	forval i = 1/`ncol' {
			sret local cw`i' `cw'
	}
end



