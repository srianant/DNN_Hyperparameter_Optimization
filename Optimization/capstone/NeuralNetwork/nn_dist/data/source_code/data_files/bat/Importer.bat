@ECHO off
TITLE SADB's Installation Tool
color 0B

REM ===========================================================================
:USER_CONFIG
CLS
ECHO.
ECHO		 =======================================================
ECHO		 ==    {{{{{{  Sandshroud Database Development 	}}}}}}==
ECHO		 ==             Suported game versions: 3.3.5         ==
ECHO		 =======================================================
ECHO.
ECHO		Enter MySql server details below...
ECHO. 
ECHO.
ECHO.
REM ===========================================================================
SET /p server= Server address: 
ECHO.
SET /p port= Server port: 
ECHO.
SET /p user= Server username: 
ECHO.
SET /p pass= Server user password: 
ECHO.
SET /p world= World database name: 
REM ===========================================================================
REM =
REM =		DO NOT MODIFY THESE SETTINGS!
REM ===========================================================================
SET mysqlpath=Mysql
SET changesets=Changesets
SET backup=Backups
SET world_path=database
SET dev_path=development
SET custom=extras\custom\
REM ===========================================================================
ECHO.
ECHO [Importer] Testing connection to database...
%mysqlpath%\mysql -h %server% --user=%user% --password=%pass% --port=%port% %world% < %mysqlpath%\test.sql
IF ERRORLEVEL 1 GOTO errorConnection


:menu
cls
ECHO.
ECHO		 =======================================================
ECHO		 ==    {{{{{{  Sandshroud Database Development 	}}}}}}==
ECHO		 ==             Suported game versions: 3.3.5         ==
ECHO		 =======================================================
ECHO.
ECHO		Please type the letter for the option:
ECHO.
ECHO		==============================
ECHO		  I = Import SADB database
ECHO		  C = Import changesets
ECHO		  D = Import development changes
ECHO		  X = Exit
ECHO		==============================
ECHO		 BW = Backup World database
ECHO		==============================
ECHO.
SET /p Letter= Enter Letter:


IF %Letter%==* GOTO errorOccurance

REM World Import
IF %Letter%==i GOTO world_import
IF %Letter%==I GOTO world_import

REM QUIT
IF %Letter%==x GOTO quit_window
IF %Letter%==X GOTO quit_window

REM changesets
IF %Letter%==c GOTO changeset_import
IF %Letter%==C GOTO changeset_import

REM changesets
IF %Letter%==d GOTO development_import
IF %Letter%==D GOTO development_import

REM world db backup
IF %Letter%==BW GOTO backup_world
IF %Letter%==bW GOTO backup_world
IF %Letter%==bw GOTO backup_world
IF %Letter%==Bw GOTO backup_world

GOTO errorOccurance

:world_import
CLS
ECHO [Importing] Started...
ECHO [Importing] SADB database...
for %%C in (%world_path%\*.sql) do (
	ECHO [Importing] %%~nxC
	%mysqlpath%\mysql -h %server% --user=%user% --password=%pass% --port=%port% %world% < "%%~fC"
	IF ERRORLEVEL 1 GOTO errorOccurance
)
IF NOT ERRORLEVEL 1 ECHO [Importing] Database import was successful
ECHO.
PAUSE
GOTO menu

:changeset_import
CLS
ECHO   Please Write down number of changeset (not the number of rev!!!)
ECHO   Or type in "a" to import all changesets
ECHO.
ECHO.
set /p ch=      Number: 
ECHO.
IF %ch%==a GOTO all_changesets
ECHO      Importing...
IF NOT EXIST "%changesets%\changeset_%ch%.sql" GOTO errorNoChanges
ECHO.
%mysqlpath%\mysql -h %server% --user=%user% --password=%pass% --port=%port% %world% < %changesets%\changeset_%ch%.sql
ECHO.
IF NOT ERRORLEVEL 1 ECHO File changeset_%ch%.sql import completed
ECHO.
PAUSE
GOTO menu

:development_import
CLS
ECHO Importing development changes now...
for %%C in (%dev_path%\*.sql) do (
	ECHO [Importing] %%~nxC
	%mysqlpath%\mysql -h %server% --user=%user% --password=%pass% --port=%port% %world% < "%%~fC"
	IF ERRORLEVEL 1 GOTO errorOccurance
)
IF NOT ERRORLEVEL 1 ECHO Development changes imported successfully
ECHO.
PAUSE
GOTO menu

:all_changesets
CLS
ECHO.
ECHO [Importing] Changesets
for %%C in (%changesets%\*.sql) do (
	ECHO [Importing] %%~nxC
	%mysqlpath%\mysql -h %server% --user=%user% --password=%pass% --port=%port% %world% < "%%~fC"
	IF ERRORLEVEL 1 GOTO changeset_failed
)
ECHO.
IF NOT ERRORLEVEL 1 ECHO Changesets import completed!
ECHO.
PAUSE   
GOTO menu

:backup_world
CLS
ECHO .
ECHO Creating world database backup
%mysqlpath%\mysqldump -h %server% --user=%user% --password=%pass% --port=%port% %world% --max_allowed_packet=1M >%backup%\world_backup.sql
ECHO Done
ECHO Your world database backup was saved in backups folder
ECHO.
PAUSE
GOTO menu

:changeset_failed
ECHO Changesets import failed!
ECHO.
PAUSE
GOTO menu

:errorConnection
CLS
ECHO.
ECHO.
ECHO [ERROR] You entered wrong mysql server informaton, try again
PAUSE
GOTO USER_CONFIG

:errorOccurance
CLS
ECHO.
ECHO.
ECHO [ERROR] An error has occured, you will be directed back to the
ECHO [ERROR] main menu.
PAUSE
GOTO menu

:errorNoChanges
CLS
ECHO.
ECHO.
ECHO [ERROR] No changesets exist to apply
PAUSE
GOTO menu

:window_quit
exit