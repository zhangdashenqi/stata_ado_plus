*! version 1.5 SB 05May2006.

program define fintmenu
version 8
if "`1'"!="off" & "`1'"!="on" {
	display in red "invalid syntax, enter fintmenu on or fintmenu off"
	exit 198
}
if "`1'"=="off" {
	window menu clear
	global S_FINTMENU
	display in gr "Fintplot menu off.  The menubar has been changed."
	exit
}
if "$S_FINTMENU"=="on" {
	di in gr "Fintplot menu already on.  Type fintmenu off to turn off." 
	exit
}
global S_FINTMENU "on"
window menu append submenu "stUser" "fintplot"
window menu append item "fintplot" "fintplot - overview" "db fintkdlg"
window menu append item "fintplot" "fintplot - detail" "db fintdlg"
window menu set "sysmenu"
display in gr "fintmenu version 1.5, 05 May 2006."
display in gr "Written by Friederike Barthel and Patrick Royston,"
di in gr "MRC Clinical Trials Unit, London."
display _n in gr "fintplot menu on.  The menubar has been changed."
end


