#delim ;
program define dotex;
version 7.0;
*
 Execute a do-file `1', outputting to `1'.tex,
 written in the SJ LaTeX version of TeX,
 with the option of passing parameters.
 Adapted from dolog (which creates text log files).
*! Author: Roger Newson
*! Date: 26 June 2007
*;
 capture log close;
 tempfile tmplog;
 qui log using `tmplog',smcl replace;
 display "Temporary log file opened on $S_DATE at $S_TIME";
 capture noisily do `0';
 local retcod = _rc;
 display "Temporary log file completed on $S_DATE at $S_TIME";
 qui log close;
 * Copy temporary file to TeX file *;
 log texman `tmplog' `"`1'.tex"',replace; 
 exit `retcod';
end;
