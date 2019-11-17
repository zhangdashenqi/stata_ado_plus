*!  Version 1.0    (STB-54: sbe32)
version 5.0 

cap program drop obvset
program define obvset
local varlist "opt ex none max(5)"
parse "`*'"
if "`1'"=="" {
	if "$casos"=="" {
		di in red "No variables have been set"
	}
	else {
		di "Reports count is:"  upper("$casos")
		di "Week identifier is:"  upper("$semana")
		di "Year identifier is:"  upper("$ano")
		di "Hospitals count is:"  upper("$nhosp")
		di "Organism identifier is:"  upper("$texto")
	}
	exit
}
global casos="`1'"
global semana="`2'"
global ano="`3'"
global nhosp="`4'"
global texto="`5'"
end


