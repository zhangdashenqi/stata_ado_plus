#delim ;
program define somers_p;
version 9.0;
/*
 Predict program for somersd
 (warning the user that predict should not be used
 after somersd)
*! Author: Roger Newson
*! Date: 19 July 2005
*/

syntax [newvarlist] [,*];

disp as error
 "predict should not be used after somersd";
error 498;

end;
