
powershell -Command "(gc %1\ftp.params.txt) -replace 'LOCAL-FOLDER', '%1' | Out-File -encoding ASCII %1\ftp.params.txt.1"

ftp -i -s:%1\ftp.params.txt.1

del %1\ftp.params.txt.1

move %1\%2 %1\bak\