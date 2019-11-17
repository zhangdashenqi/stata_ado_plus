*! STB-6: srd12
*! This is version 1.1 24 December 1991
program define amemiya
/* no version marker intentional */
version 8.0
qui predict double _resid, res
qui gen double _ressq=_resid^2
qui predict double _hat, hat
qui gen _presid=_resid/(1-_hat)
qui gen _pressq=_presid^2
qui gen _Press=sum(_pressq)
    mac def _T=_result(1)
    mac def _K1=_result(3)
    mac def _rsq=_result(7)
    mac def _RSS=_result(4)
qui gen double _sig=_ressq/(%_T-%_K1-1)
qui gen double _sigsq=sum(_sig)
di "Amemiya's PC criterion R-squared is " _col(50) %20.4f /*
 */ 1-(((%_T+%_K1)/(%_T-%_K1))*(1-%_rsq))
di "Hocking's Sp criterion is " _col(50) %20.4f /*
 */ ((%_T-%_K1-1)*_sigsq[_N])/((%_T-%_K1)*(%_T-%_K1-2))
    mac def _aic=log(%_RSS/%_T)+(2*(%_K1+1))/%_T
di "Akaike's Information Criterion (AIC) is " _col(50) %20.4f %_aic
di "     or, unlogged, " _col(50) %20.4f exp(%_aic)
    mac def _sbc=log(%_RSS/%_T)+((%_K1+1)*log(%_T))/%_T
di "Schwarz's Bayesian Criterion (SBC) is " _col(50) %20.4f %_sbc
di "     or, unlogged, " _col(50) %20.4f exp(%_sbc)
di "Prediction Sum of Squares (PRESS) is " _col(50) %20.4f _Press[_N]
drop _resid _hat _presid _pressq _Press _ressq _sig _sigsq
end
