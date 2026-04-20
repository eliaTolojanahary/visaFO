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

echo [1/4] Creation de la base de donnees...
psql -U %User% -d postgres -f sql/create_database.sql
if %ERRORLEVEL% neq 0 ( echo ERREUR etape 1 & exit /b 1 )

echo [2/4] Creation des tables...
psql -U %User% -d %DB% -f sql/table.sql
if %ERRORLEVEL% neq 0 ( echo ERREUR etape 2 & exit /b 1 )

echo [3/4] Insertion des donnees de test...
psql -U %User% -d %DB% -f sql/donnees_mini_test.sql
if %ERRORLEVEL% neq 0 ( echo ERREUR etape 3 & exit /b 1 )

echo [4/4] Alteration de la table piece_justificative_ref...
psql -U %User% -d %DB% -f sql/alter_piece_justificative_ref_nullable.sql
if %ERRORLEVEL% neq 0 ( echo ERREUR etape 4 & exit /b 1 )

echo Initialisation terminee avec succes.