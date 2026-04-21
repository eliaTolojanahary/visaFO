@echo off
rem --- Configuration des chemins (ne pas inclure de guillemets dans la valeur) ---
set "PROJECT_PATH=%~dp0"
set "BUILD_PATH=%PROJECT_PATH%build"
set "WEBAPP_PATH=%PROJECT_PATH%src\main\webapp"
set "CATALINA_HOME=C:\xampp\tomcat"
set "LIB_PATH=%PROJECT_PATH%lib"
set "APP_WAR=reservation.war"
set "COMMON_CLASSPATH=%BUILD_PATH%\WEB-INF\classes;%CATALINA_HOME%\lib\servlet-api.jar;%LIB_PATH%\*"

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
echo Création de la structure des dossiers...
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
echo Copie des bibliothèques JAR...
mkdir "%BUILD_PATH%\WEB-INF\lib"
if exist "%LIB_PATH%\*.jar" (
    xcopy "%LIB_PATH%\*.jar" "%BUILD_PATH%\WEB-INF\lib\" /Y
    echo   - Librairies copiees depuis %LIB_PATH%
) else (
    echo   - Aucune librairie trouvee dans %LIB_PATH%
)

rem Copier le contenu de webapp dans build de manière récursive
echo Copie récursive des fichiers webapp...
xcopy "%WEBAPP_PATH%\*" "%BUILD_PATH%\" /E /Y

rem Créer le fichier .war de ce qui se trouve dans build
echo Création du fichier WAR...
pushd "%BUILD_PATH%"
jar -cvf reservation.war *
popd

rem Déplacer le fichier .war dans le répertoire webapps de Tomcat
echo Déploiement du fichier WAR dans Tomcat...
move /Y "%BUILD_PATH%\reservation.war" "%CATALINA_HOME%\webapps\"

echo Projet Servlet déployé et Tomcat prêt à démarrer.
pause
goto :eof

:compile_failed
echo.
echo Compilation interrompue. Le WAR n'a pas été généré.
pause
exit /b 1
