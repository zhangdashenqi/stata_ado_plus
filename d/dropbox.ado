program define dropbox , rclass
syntax [, NOCD]

if "`c(os)'" == "Windows" {
local _db "/users/`c(username)'"
}
if "`c(os)'"~= "Windows" {
local _db "~"
}

capture local dropbox : dir "`_db'" dir "*Dropbox*" , respectcase
if _rc==0 & `"`dropbox'"'~="" {
local dropbox : subinstr local dropbox `"""' "" , all
if "`nocd'"=="" {
cd "`_db'/`dropbox'/"
}
return local db "`_db'/`dropbox'/"
exit
}
if _rc~=0 & "`c(os)'" == "Windows" {
capture cd c:/
if _rc~=0 {
nois di in red "Cannot find dropbox folder"
exit
}
capture local dropbox : dir "`_db'" dir "*Dropbox*" , respectcase
if _rc==0 & `"`dropbox'"'~="" {
local dropbox : subinstr local dropbox `"""' "" , all
if "`nocd'"=="" {
cd "`_db'/`dropbox'/"
}
return local db "`_db'/`dropbox'/"
exit
}
capture local dropbox : dir "/documents and settings/`c(username)'/my documents/" dir "*dropbox*" , 
if _rc==0 &  `"`dropbox'"'~=""{
local dropbox : subinstr local dropbox `"""' "" , all
if "`nocd'"=="" {
cd "c:/documents and settings/`c(username)'/my documents/`dropbox'"
}
return local db "c:/documents and settings/`c(username)'/my documents/`dropbox'"
exit
}

capture local dropbox : dir "/documents and settings/`c(username)'/documents/" dir "*dropbox*" , 
if _rc==0 &  `"`dropbox'"'~=""{
local dropbox : subinstr local dropbox `"""' "" , all
if "`nocd'"=="" {
cd "c:/documents and settings/`c(username)'/documents/`dropbox'"
}
return local db "c:/documents and settings/`c(username)'/documents/`dropbox'"
exit
}
}
if _rc~=0 & "`c(os)'" ~= "Windows" {
nois di in red "Cannot find dropbox folder"
exit
}
if _rc==0 & `"`dropbox'"'=="" {
capture local dropbox : dir "`_db'/Documents" dir "*Dropbox*" , respectcase
if _rc==0 {
local doc "Documents"
}
if `"`dropbox'"'=="" {
capture local dropbox : dir "`_db'/My Documents" dir "*Dropbox*" , respectcase
if _rc==0 {
local doc "My Documents"
}
}
if `"`dropbox'"'~="" {
local dropbox : subinstr local dropbox `"""' "" , all
if "`nocd'"=="" {
cd "`_db'/`doc'/`dropbox'/"
}
return local db "`_db'/`doc'/`dropbox'/"
exit
}

if `"`dropbox'"'=="" & "`c(os)'" == "Windows" {
local dropbox : dir "C:/" dir "*Dropbox*" , respectcase
local dropbox : subinstr local dropbox `"""' "" , all
if "`nocd'"=="" {
cd "/`dropbox'"
}
return local db "/`dropbox'"
exit
}
if `"`dropbox'"'=="" & "`c(os)'" ~= "Windows" {
nois di in red "Cannot find dropbox folder"
exit
}
}
end
