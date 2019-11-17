#delim ;
program define marglmean_p;
version 12.0;
/*
 Predict program for marglmean
 (warning the user that predict should not be used
 after marglmean)
*! Author: Roger Newson
*! Date: 15 November 2011
*/

syntax [newvarlist] [, *];

disp as error
 "predict should not be used after marglmean";
error 498;

end;
