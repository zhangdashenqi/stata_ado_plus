prog def multnorm
version 2.1
    mac def _varlist "req ex min(2)"
    mac def _if "opt"
    mac def _in "opt"
    parse "%_*"
    parse "%_varlist", parse(" ")
    mac def _rhs "%_*"
         while "%_1"~="" {
              drop if %_1==.
              mac shift
         }
    gen _lhs=_n
    qui reg _lhs %_rhs %_if %_in
         mac def _NVAR=_result(3)
         mac def _NUMm=_result(1)
         predict double hat, hat
gen MD2=(%_NUMm-1)*(hat-(1/%_NUMm))
sort MD2
gen chi2=_n
    mac def _i=1
while %_i<=_N {
    mac def _j=1-((%_i-.5)/%_NUMm)
    mac def _x=1
    mac def _x0=0
    while abs(%_x-%_x0)>1e-3 {
         mac def _x0=%_x
         mac def _f=chiprob(%_NVAR,%_x0)-%_j
         mac def _fp=(chiprob(%_NVAR,%_x0+.01)-%_j-%_f)/.01
         mac def _x=%_x-%_f/%_fp
    }
    qui replace chi2=%_x if _n==%_i & MD2~=.
    mac def _i=%_i+1
}
li MD2 chi2
#del ;
gr chi2 MD2, b2("Mahanalobis Distance") l2("Chi-Square") xlab ylab l1("")
b1("Plot Check for Multivariate Normality") ;
#del cr
cap drop chi2 MD2 _lhs
end
