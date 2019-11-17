#delim ;
program define margprev_p;
version 12.0;
/*
 Predict program for margprev
 (warning the user that predict should not be used
 after margprev)
*! Author: Roger Newson
*! Date: 14 November 2011
*/

syntax [newvarlist] [, *];

disp as error
 "predict should not be used after margprev";
error 498;

end;
