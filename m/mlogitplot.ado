*! version 3.0.0 2014-03-02 | long | spost13 release

//  mlogitplot odds ratios plot version 2

program define mlogitplot

    capture drop _orme
    qui gen byte _orme = .
    label var _orme "Temporarily hold mlogitplot and mchangeplot information"
    char _orme[Cplottype] "orplot"
    _orme_syntax `0'

end
exit
