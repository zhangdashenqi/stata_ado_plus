*! 1.0.0 - 28 jun 2006

/*

cmd()    - name of command that should appear in error message  

force    - ignore errors

robust   - error if robust standard errors used
cluster  - error if cluster() specified
weight   - error if pweight, aweight, iweight specified
pweight  - error if pweight specified
aweight  - error if aweight specified
iweight  - error if iweight specified

*/

program define _petrap

    version 9

    syntax [, cmd(string) Robust Cluster Weight PWeight AWeight IWeight SVY FORCE] 

    if "`cmd'" == "" {
        local cmd "program"
    }

    local vcetype = e(vcetype)
    local clustvar = e(clustvar)
    local wtype = e(wtype)
    local ecmd = e(cmd)
    local epredict = e(predict)
    

    * trap svy - possibly overkill for detecting if svy estimation performed but manuals obscure
    * about info provided under version control
    if ("`svyest'" == "svy_est" | substr("`ecmd'", 1, 3) == "svy" | substr("`epredict'", 1, 3) == "svy") ///
         & "`svy'" != "" & "`force'" == "" {
        di as err "`cmd' does not work with svy commands"
    }    

    * trap robust
    if "`vcetype'" == "Robust" & "`robust'" != "" & "`force'" == "" {
        di as err "`cmd' does not work with robust vcetype"
        exit 999
    } 

    * trap cluster
    if ("`clustvar'" != "." & "`clustvar'" != "") & "`cluster'" != "" & "`force'" == "" {
        di as err "`cmd' does not work if cluster() specified"
        exit 999
    } 

    * trap pweight, iweight, aweight
    if ("`wtype'" == "pweight" | "`wtype'" == "aweight" | "`wtype'" == "iweight") & "`weight'" != "" & "`force'" == "" {
        di as err "`cmd' does not work if `wtype' specified"
        exit 999
    } 

    * trap pweight
    if ("`wtype'" == "pweight") & "`pweight'" != "" & "`force'" == "" {
        di as err "`cmd' does not work if `wtype' specified"
        exit 999
    } 

    * trap aweight
    if ("`wtype'" == "aweight") & "`aweight'" != "" & "`force'" == "" {
        di as err "`cmd' does not work if `wtype' specified"
        exit 999
    } 

    * trap iweight
    if ("`wtype'" == "iweight") & "`iweight'" != "" & "`force'" == "" {
        di as err "`cmd' does not work if `wtype' specified"
        exit 999
    } 


end
