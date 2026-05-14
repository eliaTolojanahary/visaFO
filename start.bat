@echo off
REM -- Configuration de la base de donnees
set User=postgres
set DB=visa

REM -- Verification que les variables sont renseignees
if "%User%"=="" (
    echo ERREUR : La variable User est vide.
    exit /b 1
)
if "%DB%"=="" (
    echo ERREUR : La variable DB est vide.
    exit /b 1
)

echo [1/2] Creation/reset du schema...
psql -v ON_ERROR_STOP=1 -U %User% -d postgres -f sql/table.sql
if %ERRORLEVEL% neq 0 ( echo ERREUR etape 1 & exit /b 1 )

echo [2/2] Insertion des donnees de test...
psql -v ON_ERROR_STOP=1 -U %User% -d %DB% -f sql/donnees_test.sql
if %ERRORLEVEL% neq 0 ( echo ERREUR etape 4 & exit /b 1 )

echo Initialisation terminee avec succes.