*! version 1.0.0 2014-02-20 | long | spost13 release

//  plot marginal effects computed by mchange

program define mchangeplot

    version 11.2
    capture drop _orme
    qui gen byte _orme = .
    label var _orme "Temporarily hold orplot and meplot information"
    char _orme[Cplottype] "meplot"
    _orme_syntax `0'

end
exit
