@echo off
rem ============================================================
rem  run_servlet.bat — Build et déploiement du projet visa
rem ============================================================
rem  CONFIGURATION REQUISE :
rem  Définir la variable d'environnement CATALINA_HOME avant de
rem  lancer ce script, ou l'exporter dans votre profil système.
rem
rem  Exemple (PowerShell) :
rem    $env:CATALINA_HOME = "D:\PERS\MIOTY\s6\apache-tomcat-9.0.117"
rem
rem  Exemple (cmd, permanent via sysdm.cpl > Variables d'env.) :
rem    setx CATALINA_HOME "D:\PERS\MIOTY\s6\apache-tomcat-9.0.117"
rem
rem  Les credentials DB sont lus par l'application via DB_URL,
rem  DB_USER, DB_PASSWORD (voir .env.example à la racine).
rem ============================================================

rem --- Vérification de CATALINA_HOME ---
if "%CATALINA_HOME%"=="" (
    echo.
    echo [ERREUR] La variable d'environnement CATALINA_HOME n'est pas definie.
    echo          Definissez-la avant de lancer ce script :
    echo          set CATALINA_HOME=C:\chemin\vers\apache-tomcat-X.X.XXX
    echo.
    pause
    exit /b 1
)

rem --- Configuration des chemins ---
set "PROJECT_PATH=%~dp0"
set "BUILD_PATH=%PROJECT_PATH%build"
set "WEBAPP_PATH=%PROJECT_PATH%src\main\webapp"
set "LIB_PATH=%PROJECT_PATH%lib"
set "COMMON_CLASSPATH=%BUILD_PATH%\WEB-INF\classes;%CATALINA_HOME%\lib\servlet-api.jar;%LIB_PATH%\*"
set "APP_WAR=visa.war"

rem Vérifier si le dossier "build" existe et le supprimer
if exist "%BUILD_PATH%" (
    echo Suppression du dossier build...
    rmdir /s /q "%BUILD_PATH%"
)

rem Nettoyer les artefacts de déploiement mal nommés (espaces accidentels)
if exist "%CATALINA_HOME%\webapps\ visa.war" del /f /q "%CATALINA_HOME%\webapps\ visa.war"
if exist "%CATALINA_HOME%\webapps\ war" del /f /q "%CATALINA_HOME%\webapps\ war"
if exist "%CATALINA_HOME%\webapps\ visa" rmdir /s /q "%CATALINA_HOME%\webapps\ visa"

rem Supprimer l'ancienne version pour forcer un redéploiement propre
if exist "%CATALINA_HOME%\webapps\%APP_WAR%" del /f /q "%CATALINA_HOME%\webapps\%APP_WAR%"

rem Créer la structure de dossiers
echo Creation de la structure des dossiers...
mkdir "%BUILD_PATH%"
mkdir "%BUILD_PATH%\WEB-INF"
mkdir "%BUILD_PATH%\WEB-INF\classes"

rem Compilation des fichiers .java par couches de dépendances
echo Compilation des fichiers Java...

set "SOURCES=%TEMP%\sources.txt"
if exist "%SOURCES%" del /f /q "%SOURCES%"

echo   - couche 1: annotation, util, modelview
for /R "%PROJECT_PATH%src\main\java\annotation" %%F in (*.java) do @echo %%~fF>>"%SOURCES%"
for /R "%PROJECT_PATH%src\main\java\util" %%F in (*.java) do @echo %%~fF>>"%SOURCES%"
for /R "%PROJECT_PATH%src\main\java\modelview" %%F in (*.java) do @echo %%~fF>>"%SOURCES%"
javac -parameters -d "%BUILD_PATH%\WEB-INF\classes" -classpath "%COMMON_CLASSPATH%" @"%SOURCES%"
if errorlevel 1 goto :compile_failed

echo   - couche 2: models
if exist "%SOURCES%" del /f /q "%SOURCES%"
for /R "%PROJECT_PATH%src\main\java\models" %%F in (*.java) do @echo %%~fF>>"%SOURCES%"
javac -parameters -d "%BUILD_PATH%\WEB-INF\classes" -classpath "%COMMON_CLASSPATH%" @"%SOURCES%"
if errorlevel 1 goto :compile_failed

echo   - couche 3: dao et repo
if exist "%SOURCES%" del /f /q "%SOURCES%"
for /R "%PROJECT_PATH%src\main\java\dao" %%F in (*.java) do @echo %%~fF>>"%SOURCES%"
for /R "%PROJECT_PATH%src\main\java\repo" %%F in (*.java) do @echo %%~fF>>"%SOURCES%"
javac -parameters -d "%BUILD_PATH%\WEB-INF\classes" -classpath "%COMMON_CLASSPATH%" @"%SOURCES%"
if errorlevel 1 goto :compile_failed

echo   - couche 4: services
if exist "%SOURCES%" del /f /q "%SOURCES%"
for /R "%PROJECT_PATH%src\main\java\services" %%F in (*.java) do @echo %%~fF>>"%SOURCES%"
javac -parameters -d "%BUILD_PATH%\WEB-INF\classes" -classpath "%COMMON_CLASSPATH%" @"%SOURCES%"
if errorlevel 1 goto :compile_failed

echo   - couche 5: controllers, servlet, scan, main
if exist "%SOURCES%" del /f /q "%SOURCES%"
for /R "%PROJECT_PATH%src\main\java\controllers" %%F in (*.java) do @echo %%~fF>>"%SOURCES%"
for /R "%PROJECT_PATH%src\main\java\servlet" %%F in (*.java) do @echo %%~fF>>"%SOURCES%"
for /R "%PROJECT_PATH%src\main\java\scan" %%F in (*.java) do @echo %%~fF>>"%SOURCES%"
for /R "%PROJECT_PATH%src\main\java\main" %%F in (*.java) do @echo %%~fF>>"%SOURCES%"
javac -parameters -d "%BUILD_PATH%\WEB-INF\classes" -classpath "%COMMON_CLASSPATH%" @"%SOURCES%"
if errorlevel 1 goto :compile_failed

rem Copier les bibliothèques (JARs) dans WEB-INF\lib
echo Copie des bibliotheques JAR...
mkdir "%BUILD_PATH%\WEB-INF\lib"
if exist "%LIB_PATH%\*.jar" (
    xcopy "%LIB_PATH%\*.jar" "%BUILD_PATH%\WEB-INF\lib\" /Y
    echo   - Librairies copiees depuis %LIB_PATH%
) else (
    echo   - Aucune librairie trouvee dans %LIB_PATH%
)

rem Copier le contenu de webapp dans build de manière récursive
echo Copie recursive des fichiers webapp...
xcopy "%WEBAPP_PATH%\*" "%BUILD_PATH%\" /E /Y

rem Créer le fichier .war
echo Creation du fichier WAR...
pushd "%BUILD_PATH%"
jar -cvf "%APP_WAR%" *
popd

rem Déplacer le fichier .war dans le répertoire webapps de Tomcat
echo Deploiement du fichier WAR dans Tomcat...
move /Y "%BUILD_PATH%\%APP_WAR%" "%CATALINA_HOME%\webapps\"

echo Projet Servlet deploye et Tomcat pret a demarrer.
pause
goto :eof

:compile_failed
echo.
echo Compilation interrompue. Le WAR n'a pas ete genere.
pause
exit /b 1