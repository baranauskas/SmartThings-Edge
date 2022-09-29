set edgeDriver=%1
smartthings edge:drivers:package %edgeDriver%
smartthings edge:channels:assign
smartthings edge:channels:enroll
smartthings edge:drivers:install
pause
smartthings edge:drivers:logcat --hub-address=192.168.1.210
