*! Date    : 2 November 2015
*! Version : 1.08
*! Author  : Adrian Mander
*! Email   : adrian.mander@mrc-bsu.cam.ac.uk

*! Make help files

/*
27Mar07 v1.5  The old version of makehlp for Stata9
 3Jul12 v1.06 Update this very old program
11Dec12 v1.07 Changed message on the replace, allow /// to define end of line, sorted out real and integer
 2Nov15 v1.08 BUG: need to handle quotes in comments before syntax line
 */

program define makehlp
version 12.0
syntax [varlist], File(string) [ Replace DEBUG ME]
cap log close

/*****************************************
 * Read in file 
 *  Go line by line until syntax is found
 *  Then stop reading lines once we 
 *  haven't got an end comment
 *****************************************/
tempname fh
file open `fh' using `"`file'.ado"',read
file read `fh' line
local i 1
while index(`"`line'"', "syntax")==0 {
  file read `fh' line 
}
local line`i++' "`line'"
while (index(`"`line'"', "/*")~=0) | (index(`"`line'"', "///")~=0) {
  file read `fh' line
  local line`i++' "`line'"
}
forv j=1/`=`--i''{
  di "`line`j''"
}
local nlines `i'
/*********************************************************************
 * Put all the lines together into synt, hopefully it isn't too long! 
 * I also strip out the comments before creating the syntax macro
 *********************************************************************/
local synt ""
forv ii=1/`nlines' {
  local line`ii' =subinstr("`line`ii''", "/*", "",.)
  local line`ii' =subinstr("`line`ii''", "///", "",.)
  local line`ii' =subinstr("`line`ii''", "*/", "",.)
  local synt "`synt'`line`ii''"
}

/*******************************************************************
 * Split the syntax line into components Create the options list 
 * opts has the position of the ,
 * opt has the options 
 * preopt has everything up to the comma
 *******************************************************************/
local opts = index("`synt'",",")
if "`opts'"=="0" di as error "WARNING: There are NO options"
local opt = substr("`synt'",index("`synt'",",")+1,.)
local preopt = substr("`synt'",1,index("`synt'",",")-1)

/*****************************************************************
 * Strip out the trailing bracket ] 
 *****************************************************************/
if index("`opt'","]")~=0 local opt = substr("`opt'", 1, index("`opt'","]")-1)



/*****************************************************************
 * an in loop later on requires that the list in preopt doesn't end in an open bracket...
 * A leading [ bracket occurs when every option is optional
 *****************************************************************/
if index(reverse("`preopt'"),"[")>index(reverse("`preopt'"),"]") & index(reverse("`preopt'"),"]")==0 {
  di "{error}Warning: Stripping out a trailing [ bracket prior to comma"
  local preopt = substr("`preopt'",1,index("`preopt'","[")-1)+substr("`preopt'",index("`preopt'","[")+1,.) 
}
if index(reverse("`preopt'"),"[")<index(reverse("`preopt'"),"]") & index(reverse("`preopt'"),"]")>0 {
  di as error "Warning: Stripping out a trailing [ bracket prior to comma"
  local preopt = substr("`preopt'",1,index("`preopt'","[")-1)+substr("`preopt'",index("`preopt'","[")+1,.) 
}


/*****************************************************************
 * Probably need to strip out the other leading bracket in `opt' 
 *****************************************************************/
if index("`opt'","[")~=0 {
  local newopt = substr("`opt'",1,index("`opt'","[")-1)+substr("`opt'",index("`opt'","[")+1,.) 
  if index("`newopt'","[")~=0 di "{error} there are too many [ brackets in the options"
  local opt `"`newopt'"'
}

/***************************************************************************************
 * The options could have  opt(string asis)  and need to join the words 
 * by using quotes
 ***************************************************************************************/

local oopt ""
foreach word in `opt' {
  if index("`word'","(")~=0 & index("`word'",")")~=0 local oopt `"`oopt' `word'"'
  else if index("`word'","(")~=0 local oopt `"`oopt' "`word'"'
  else if index("`word'",")")~=0 local oopt `"`oopt' `word'""'
  else local oopt `"`oopt' `word' "'
}

/****************************
 * CREATING the help file
 ****************************/
tempname fhw
local comm "`file'"
local hfile "`comm'.sthlp"
cap confirm file `hfile'
if _rc==0 {
  di as error "WARNING: File `hfile' already exists"
  if "`replace'"~=""  {
    di " About to replace this file..."
    qui file open `fhw' using `hfile',replace write
  }
  else exit(198)
}
else {
  di as text "Creating file `hfile'..."
  qui file open `fhw' using `hfile', write
}


file  write `fhw' "{smcl}" _n
file  write `fhw' "{* *! version 1.0 `c(current_date)'}{...}" _n
file  write `fhw' `"{vieweralsosee "" "--"}{...}"' _n
file  write `fhw' `"{vieweralsosee "Install command2" "ssc install command2"}{...}"' _n
file  write `fhw' `"{vieweralsosee "Help command2 (if installed)" "help command2"}{...}"' _n
file  write `fhw' `"{viewerjumpto "Syntax" "`comm'##syntax"}{...}"' _n
file  write `fhw' `"{viewerjumpto "Description" "`comm'##description"}{...}"' _n
file  write `fhw' `"{viewerjumpto "Options" "`comm'##options"}{...}"' _n
file  write `fhw' `"{viewerjumpto "Remarks" "`comm'##remarks"}{...}"' _n
file  write `fhw' `"{viewerjumpto "Examples" "`comm'##examples"}{...}"' _n
file  write `fhw' "{title:Title}" _n
file  write `fhw' "{phang}" _n
file  write `fhw' "{bf:`comm'} {hline 2} <insert title here>" _n _n
file  write `fhw' "{marker syntax}{...}" _n
file  write `fhw' "{title:Syntax}" _n

file  write `fhw' "{p 8 17 2}" _n
file  write `fhw' "{cmdab:`comm'}" _n

foreach pre in `preopt' {
 if index("`pre'","syntax")~=0 continue
 else if index("`pre'","[in]")~=0 file  write `fhw' "[{help in}]" _n
 else file  write `fhw' "`pre'" _n
}

file write `fhw' "[{cmd:,}" _n
file write `fhw' "{it:options}]" _n _n
file write `fhw' "{synoptset 20 tabbed}{...}" _n
file write `fhw' "{synopthdr}" _n
file write `fhw' "{synoptline}" _n
file write `fhw' "{syntab:Main}" _n

/* Processing the options for the syntax options table */
foreach option in `oopt' {
  local dd ""
  if index("`option'","(")~=0 {
    local name = substr("`option'",1,index("`option'","(")-1)
    local inse = substr("`option'",index("`option'","(")+1,.) 
    local inse = substr("`inse'",1,index("`inse'",")")-1)
    /* handle the integer and real options properly */
    if index("`inse'","real")~=0 {
      if trim(substr("`inse'",index("`inse'","real")+4,.))~="" local dd ="Default value is"+substr("`inse'",index("`inse'","real")+4,.) 
      local inse "#"
    }    
    if ((index("`inse'","integer")~=0 ) & (index("`inse'","numlist")==0)) {
      if trim(substr("`inse'",index("`inse'","integer")+7,.))~="" local dd ="Default value is"+substr("`inse'",index("`inse'","integer")+7,.) 
      local inse "#"
    }    
    local xx "(`inse')"
  }
  else {
   local name `"`option'"'
   local xx ""
  }
  /* Now split the name into lower and upper */
  if "`name'"~=lower("`name'") {
    local newname ""
    local split 0
    forv i=1/`=length("`name'")' {
      if lower(substr("`name'",`i',1))~=substr("`name'",`i',1) & !`split' local newname="`newname'"+lower(substr("`name'",`i',1))
      else if lower(substr("`name'",`i',1))==substr("`name'",`i',1) & !`split' {
        local split 1
        local newname="`newname':"+substr("`name'",`i',1)
      }
      else local newname="`newname'"+substr("`name'",`i',1)
    }
  }
  else local newname `"`name'"'
  file  write `fhw' "{synopt:{opt `newname'`xx'}} `dd'.{p_end}" _n
}

file  write `fhw' "{synoptline}" _n
file  write `fhw' "{p2colreset}{...}" _n
file  write `fhw' "{p 4 6 2}" _n

file  write `fhw' _n "{marker description}{...}" _n
file  write `fhw' "{title:Description}" _n 
file  write `fhw' "{pstd}" _n
file  write `fhw' "{cmd:`comm'} does ... <insert description>" _n
file  write `fhw' _n "{marker options}{...}" _n
file  write `fhw' "{title:Options}" _n
file  write `fhw' "{dlgtab:Main}" _n


foreach option in `oopt' {
  local dd ""
  if index("`option'","(")~=0 {
    local name = substr("`option'",1,index("`option'","(")-1)
    local inse = substr("`option'",index("`option'","(")+1,.) 
    local inse = substr("`inse'",1,index("`inse'",")")-1)
    /* handle the integer and real options properly */
    if index("`inse'","real")~=0 {
      if trim(substr("`inse'",index("`inse'","real")+4,.))~="" local dd ="Default value is"+substr("`inse'",index("`inse'","real")+4,.) 
      local inse "#"
    }    
    if ((index("`inse'","integer")~=0 ) & (index("`inse'","numlist")==0)) {
      if trim(substr("`inse'",index("`inse'","integer")+7,.))~="" local dd ="Default value is"+substr("`inse'",index("`inse'","integer")+7,.) 
      local inse "#"
    }    
    local xx "(`inse')"
  }
  else {
    local name "`option'"
    local xx ""
  }
  /* Now split the name into lower and upper */
  if "`name'"~=lower("`name'") {
    local newname ""
    local split 0
    forv i=1/`=length("`name'")' {
      if lower(substr("`name'",`i',1))~=substr("`name'",`i',1) & !`split' local newname="`newname'"+lower(substr("`name'",`i',1))
      else if lower(substr("`name'",`i',1))==substr("`name'",`i',1) & !`split' {
        local split 1
        local newname="`newname':"+substr("`name'",`i',1)
      }
      else local newname="`newname'"+substr("`name'",`i',1)
    }
  }
  else local newname "`name'"

  file  write `fhw' "{phang}" _n
  file  write `fhw' "{opt `newname'`xx'}  `dd'" _n _n
}

file write `fhw' _n "{marker examples}{...}" _n
file write `fhw' "{title:Examples}" _n
file write `fhw' _n "{phang} <insert example command>" _n




file write `fhw' _n "{title:Author}" _n

file write `fhw' "{p}" _n
if "`me'"~="" {
  file write `fhw' "{p_end}" _n
  file write `fhw' "{pstd}" _n
  file write `fhw' "Adrian Mander, MRC Biostatistics Unit, Cambridge, UK." _n
  file write `fhw' _n "{pstd}" _n
  file write `fhw' `"Email {browse "mailto:adrian.mander@mrc-bsu.cam.ac.uk":adrian.mander@mrc-bsu.cam.ac.uk}"' _n
}
else {
  file write `fhw' _n "<insert name>, <insert institution>." _n
  file write `fhw' _n `"Email {browse "mailto:firstname.givenname@domain":firstname.givenname@domain}"' _n
}

file write `fhw' _n "{title:See Also}" _n
file write `fhw' _n "NOTE: this part of the help file is old style! delete if you don't like" _n
file write `fhw' _n "Related commands:" _n
file write `fhw' _n
file write `fhw' "{help command1} (if installed)" _n
file write `fhw' "{help command2} (if installed)   {stata ssc install command2} (to install this command)" _n

file close `fhw'
end
