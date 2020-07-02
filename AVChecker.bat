@echo off

REM Note 1: Delete line 94 and run from command line with “AVChecker > AVChecker_LOG.txt 2>&1” (without quotes) to generate a log file in the working directory.
REM Note 2: If AV service is not named SepMasterService (i.e. not Symantec), perform a "Find and Replace" on all 'SepMasterService' strings in this script, replacing with the name of the AV service you wish to check.

REM initialize counter for nodesWithoutAVRunning list
SET n=0

REM initialize counter for uncheckable nodes list
SET m=0

REM initialize counter for nodesWithAVRunning list
SET o=0

ECHO.
ECHO 		*!*!* AV Checker *!*!*

SETLOCAL ENABLEDELAYEDEXPANSION

for %%x in (PASTE COMMA SEPARATED NODE NAMES HERE) do (
	ECHO.
	
	REM Test sc command, save errorlevel
	sc \\%%x query SepMasterService > NUL
	SET el=!errorlevel!
	
	REM save state of AV service if no error
	IF !el!==0 (
		FOR /f "tokens=4" %%y in ('sc \\%%x query SepMasterService ^| find /I "STATE"') do set serviceState=%%y
		IF NOT "!serviceState!"=="RUNNING" (
			ECHO %%x: SepMasterService not running on %%x. Current state: !serviceState!
			SET nodesWithoutAVRunning[!n!]=%%x
			SET nodesWithoutAVRunningStatus[!n!]=!serviceState!
			SET /a n+=1
		)
		IF "!serviceState!"=="RUNNING" (
			ECHO %%x: SepMasterService is running on %%x.
			SET nodesWithAVRunning[!o!]=%%x
			SET /a o+=1
		)
	)
	
	REM print error and save error code if error
	IF NOT !el!==0 (
		ECHO %%x: Service not checked. Check node. Error Code: !el!
		REM add node to list of nodes for which service status check failed
		SET serviceStatusCheckFailed[!m!]=%%x
		SET serviceStatusCheckFailedErrorCodes[!m!]=!el!
		SET /a m+=1
	)
	
	ECHO. && ECHO * * * * * * * * * * * && ECHO.
)

REM print list of uncheckable nodes with error codes
IF !m! GTR 0 (
	ECHO. && ECHO NODES THAT COULD NOT BE CHECKED - CHECK NODES
	ECHO ---------------------------------------------
	FOR /L %%a IN (0, 1, !m!) DO (
		IF NOT %%a==!m! ECHO !serviceStatusCheckFailed[%%a]! -- ERROR CODE: !serviceStatusCheckFailedErrorCodes[%%a]!
	)
	ECHO. && ECHO TOTAL UNCHECKABLE: !m! && ECHO.
)

IF !m!==0 ECHO. && ECHO TOTAL UNCHECKABLE NODES: 0 && ECHO.


REM print list of nodes with SepMasterService queryable but not RUNNING 
IF !n! GTR 0 (	
	ECHO. && ECHO NODES WITHOUT SepMasterService IN RUNNING STATE
	ECHO -----------------------------------------------
	FOR /L %%a IN (0, 1, !n!) DO (
		IF NOT %%a==!n! ECHO !nodesWithoutAVRunning[%%a]! -- CURRENT STATUS: !nodesWithoutAVRunningStatus[%%a]!
	)
	ECHO. && ECHO TOTAL NOT RUNNING: !n! && ECHO.
)

IF !n!==0 ECHO. && ECHO TOTAL NODES WITHOUT SepMasterService IN RUNNING STATE: 0 && ECHO.

REM print list of nodes with SepMasterService RUNNING
IF !o! GTR 0 (		
	ECHO. && ECHO NODES WITH SepMasterService IN RUNNING STATE
	ECHO --------------------------------------------
	FOR /L %%a IN (0, 1, !o!) DO (
		IF NOT %%a==!o! ECHO !nodesWithAVRunning[%%a]!
	)
	ECHO. && ECHO TOTAL RUNNING: !o! && ECHO.
)

IF !o!==0 ECHO. && ECHO TOTAL NODES WITH SepMasterService IN RUNNING STATE: 0 && ECHO.

ECHO.

PAUSE

REM Resource 1: https://stackoverflow.com/questions/130193/is-it-possible-to-modify-a-registry-entry-via-a-bat-cmd-script
REM Resource 2: https://stackoverflow.com/questions/2591758/batch-script-loop
REM Resource 3: https://stackoverflow.com/questions/20484151/redirecting-output-from-within-batch-file