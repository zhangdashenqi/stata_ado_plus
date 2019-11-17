*! version 0.4.2 2012-09-04 | long freese | added exit

** dc plot

program define dcplot

    version 11.2

    //  version statement intentionally omitted
    capture qui gen _ordc = .
    label var _ordc "Variable to hold orplot and dcplot information"
    char _ordc[_plot_type_] "dcplot"
    _ordcplot_syntax `0'

end

exit

* version 0.3.0 2012-08-03 scott long
* version 0.4.1 2012-09-04 jsl | dcp ocp work | posted
