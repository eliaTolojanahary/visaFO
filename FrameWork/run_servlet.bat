@echo off
rem --- Configuration des chemins (ne pas inclure de guillemets dans la valeur) ---
set "PROJECT_PATH=%~dp0"
set "BUILD_PATH=%PROJECT_PATH%build"
set "WEBAPP_PATH=%PROJECT_PATH%src\main\webapp"
set "CATALINA_HOME=C:\xampp\tomcat"
set "LIB_PATH=%PROJECT_PATH%lib"

rem Vérifier si le dossier "build" existe et le supprimer
if exist "%BUILD_PATH%" (
    echo Suppression du dossier build...
    rmdir /s /q "%BUILD_PATH%"
)

rem Créer la structure de dossiers
echo Création de la structure des dossiers...
mkdir "%BUILD_PATH%"
mkdir "%BUILD_PATH%\WEB-INF"
mkdir "%BUILD_PATH%\WEB-INF\classes"

rem Compilation des fichiers .java et sortie dans le répertoire classes
echo Compilation des fichiers Java...

rem Générer la liste des sources dans un fichier temporaire
set "SOURCES=%TEMP%\sources.txt"
if exist "%SOURCES%" del /f /q "%SOURCES%"
for /R "%PROJECT_PATH%src\main\java" %%F in (*.java) do @echo %%~fF>>"%SOURCES%"

rem Compiler en utilisant la liste de sources (gère les sous-dossiers et packages)
rem Ajout de -parameters pour préserver les noms des paramètres (requis pour le binding automatique)
javac -parameters -d "%BUILD_PATH%\WEB-INF\classes" -classpath "%CATALINA_HOME%\lib\servlet-api.jar;%LIB_PATH%\*" @"%SOURCES%"

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
