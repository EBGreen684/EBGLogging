# EBGLogging

Module Level Methods
  Get-EBGLog - Returns a log object
  
EBGLog Object
  Methods
    .Write([MESSAGE]) - Writes to the current log file (.LogFile property).
    .GetLogSize() - Returns the size of the current log file in MB.
    .GetLogDays() - Returns the number of total days from the beginning of the current log file until now.
    .RotateLogFileSize([SIZE]) - Creates a copy of the existing log file if the size of the log file (in MB) is greater than the
                                 Specified size. The copy is name the same as the logfile with .bu appended to the name. If there
                                 is already a file with that name then the file will be deleted. After the copy is created then the
                                 existing log file will be deleted then recreated with the first line indicating that the file was
                                 rotated.
     .RotateLogFileSize() - Rotates the log file as described above. Uses the .RotateSize property to determine when to rotate.
     .RotateLogFileDays([DAYS]) - Creates a copy of the existing log file if the total days since the first entry and now is greater
                                  than [DAYS]. The copy is name the same as the logfile with .bu appended to the name. If there
                                  is already a file with that name then the file will be deleted. After the copy is created then the
                                  existing log file will be deleted then recreated with the first line indicating that the file was
                                  rotated.
     .RotateLogFileDays() - Rotates the log file as described above. Uses the .RotateDays property to determine when to rotate.
     .RemoveLogFile() - Removes the current log file.
   Properties
    .LogFile - Specifies the path and name of the file to work with (No default value)
    .RotateSize - The size limit for the file to be rotated if the 0 parameter overload is used for the .RotateLogFileSize method.
                  The default value is 1MB.
    .AutoRotateSize - If this value is set then the log file will automatically be rotated whenever the size is over the .RotateSize
                      Value.
    .RotateDays - The time limit in days for the file to be rotated if the 0 parameter overload is used for the .RotateLogFileDays
                  method. The default value is 7 days.
