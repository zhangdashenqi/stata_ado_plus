program define urnmodel
version 2.1
    mac def _varlist "req ex min(3)"
    mac def _if "opt"
    mac def _in "opt"
    parse "%_*"
    parse "%_varlist", parse(" ")
    mac def _gvar "%_1"
         qui su %_gvar %_if %_in
         if _result(6)~=1 | _result(5)~=0 {
                di in red "invalid syntax -- see help urnmodel"
                exit 198
        }
    mac shift
    mac def _lhs "%_1"
    mac shift
    mac def _rhs "%_*"
    reg %_lhs %_rhs %_if %_in
* Note that the rhs variables should not include a dummy for the group
* comparison of interest (say, female v. male).
         predict double _res %_if %_in, res
         if "%_if"~="" {
              mac def _if2="%_if & %_gvar==0"
         }
         else {
              mac def _if2="if %_gvar==0"
         }
* This is set up so that the comparison group is a 0-1 dummy variable;
* for different coding and/or for a different
* comparison group variable change the preceding statement.
di ""
di "Summary of Residuals for Group=0"
         sum _res %_if2 %_in
         mac def _mres=_result(3)
         mac def _mnum=_result(1)
         if "%_if"~="" {
              mac def _if2="%_if & %_gvar==1"
         }
         else {
              mac def _if2="if %_gvar==1"
         }
di ""
di "Summary of Residuals for Group=1"
         sum _res %_if2 %_in
         mac def _fres=_result(3)
         mac def _fnum=_result(1)
         mac def _numtot=%_mnum+%_fnum
         gen _res2=_res*_res
         gen _ssqrd=sum(_res2)/(%_numtot-1)
         mac def _diffr=%_mres-%_fres
    mac def _z=%_diffr/sqrt(_ssqrd[_N]*(%_numtot/(%_mnum*%_fnum)))
di ""
di "The test statistic is z= "%_z " and its p-value is "%5.4f 1-normprob(%_z)
drop _res _res2 _ssqrd
end
