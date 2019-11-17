*Outliers and summary statistics for simple normality check.
program define iqr
version 2.1
capture drop tempvar
mac def _varlist "required existing max(1)"
mac def _if "optional"
mac def _in "optional"
parse "%_*"
quietly generate tempvar=%_1 %_if %_in
quietly summ tempvar, detail
macro define NN=_result(1)
display
#delimit ;
di in gr "   mean= " in ye %6.0g _result(3) in gr _col(20)
      "       std.dev.= " in ye %6.0g sqrt(_result(4))
      in gr _col(50) "   (n= " in ye _result(1) in gr ")";
di in gr " median= " in ye %6.0g _result(10)
      in gr _col(20) "pseudo std.dev.= "
      in ye %6.0g (_result(11)-_result(9))/1.349
      in gr _col(50) " (IQR= " in ye %6.0g _result(11)-_result(9)
      in gr ")";
mac define _lowfen1=_result(9)-1.5*(_result(11)-_result(9));
mac define _hifen1=_result(11)+1.5*(_result(11)-_result(9));
mac define _lowfen2=_result(9)-3*(_result(11)-_result(9));
mac define _hifen2= _result(11)+3*(_result(11)-_result(9));
quietly summ tempvar if tempvar>_result(8) & tempvar<_result(12);
di in gr "10 trim= " in ye %6.0g _result(3);
di in gr _col(48) "low " _col(60) "high";
di in gr _col(48) "-------------------";
di in gr _col(28) "     inner fences " in ye _col(48) %6.0g %_lowfen1
      _col(60) %6.0g %_hifen1;
quietly count if tempvar<%_lowfen1 & tempvar>=%_lowfen2 & tempvar~=.;
macro define _loout1=_result(1);
quietly count if tempvar>%_hifen1 & tempvar<=%_hifen2 & tempvar~=.;
macro define _hiout1=_result(1);
di in gr _col(28) "# mild outliers   " in ye _col(48) %_loout1
      _col(60) %_hiout1;
di in gr _col(28) "% mild outliers   "
      in ye _col(48) %4.2f 100*%_loout1/%NN in gr "%"
      in ye _col(60) %4.2f 100*%_hiout1/%NN in gr "%";
display;
di in gr _col(28) "     outer fences " in ye _col(48) %6.0g %_lowfen2
      _col(60) %6.0g %_hifen2;
quietly count if tempvar<%_lowfen2 & tempvar~=.;
macro define _loout2=_result(1);
quietly count if tempvar>%_hifen2 & tempvar~=.;
macro define _hiout2=_result(1);
di in gr _col(28) "# severe outliers " in ye _col(48) %_loout2
      _col(60) %_hiout2;
di in gr _col(28) "% severe outliers "
      in ye _col(48) %4.2f 100*%_loout2/%NN in gr "%"
      in ye _col(60) %4.2f 100*%_hiout2/%NN in gr "%";
display;
capture drop tempvar;
#delimit cr
end
