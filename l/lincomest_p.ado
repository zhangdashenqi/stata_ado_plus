#delim ;
program define lincomest_p;
version 7.0;
/*
 Predict program for lincomest
 (warning the user that predict should not be used
 after lincomest)
*! Author: Roger Newson
*! Date: 21 January 2003
*/

syntax [newvarlist] [,*];

disp in red
 "predict should not be used after lincomest";
error 498;

end;
