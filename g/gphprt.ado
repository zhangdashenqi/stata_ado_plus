program define gphprt
version 2.1
       if "%_1"=="" { 
             di in red "invalid syntax -- see help gphprt"
             exit 198
       }
       if "%_2"=="" {
             mac def scale=150
       }
       else {
             mac def scale=int(%_2*1.5)
       }
! gphpen %_1 /n /ogphprt.ps /r%scale
! copy c:\stat\stata\gphprt.ps lpt2
! erase c:\stat\stata\gphprt.ps
end
