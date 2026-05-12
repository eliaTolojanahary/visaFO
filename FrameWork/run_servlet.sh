#!/bin/bash

# --- Chargement des variables d'environnement depuis .env ---
ENV_FILE="$(dirname "$0")/.env"

if [ -f "$ENV_FILE" ]; then
    echo "Chargement des variables d'environnement depuis .env..."

    while IFS='=' read -r key value; do
        # Ignorer les commentaires et lignes vides
        [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue

        export "$key=$value"
        echo "  - $key defini"
    done < "$ENV_FILE"

else
    echo "Avertissement: Fichier .env non trouve. Utilisation des valeurs par defaut."
fi

# --- Configuration des chemins ---
PROJECT_PATH="$(cd "$(dirname "$0")" && pwd)"
BUILD_PATH="$PROJECT_PATH/build"
WEBAPP_PATH="$PROJECT_PATH/src/main/webapp"

if [ -z "$CATALINA_HOME" ]; then
    CATALINA_HOME="/home/itu/apache-tomcat-9.0.82/apache-tomcat-9.0.82"
fi

LIB_PATH="$PROJECT_PATH/lib"
COMMON_CLASSPATH="$BUILD_PATH/WEB-INF/classes:$CATALINA_HOME/lib/servlet-api.jar:$LIB_PATH/*"
APP_WAR="visa.war"

# --- Copier le .env dans Tomcat bin ---
if [ -f "$ENV_FILE" ]; then
    echo "Copie du .env dans Tomcat bin..."
    cp -f "$ENV_FILE" "$CATALINA_HOME/bin/.env"
    echo "  - .env copie dans $CATALINA_HOME/bin/"
else
    echo "Avertissement: pas de .env a copier dans Tomcat."
fi

# Vérifier si le dossier build existe et le supprimer
if [ -d "$BUILD_PATH" ]; then
    echo "Suppression du dossier build..."
    rm -rf "$BUILD_PATH"
fi

# Nettoyer les artefacts de déploiement
rm -f "$CATALINA_HOME/webapps/ visa.war"
rm -f "$CATALINA_HOME/webapps/ war"
rm -rf "$CATALINA_HOME/webapps/ visa"

# Supprimer l'ancienne version
rm -f "$CATALINA_HOME/webapps/$APP_WAR"

# Créer la structure des dossiers
echo "Création de la structure des dossiers..."
mkdir -p "$BUILD_PATH/WEB-INF/classes"

# Compilation des fichiers Java
echo "Compilation des fichiers Java..."

SOURCES="/tmp/sources.txt"
rm -f "$SOURCES"

compile_layer() {
    echo "  - $1"
    shift

    rm -f "$SOURCES"

    for dir in "$@"; do
        if [ -d "$PROJECT_PATH/src/main/java/$dir" ]; then
            find "$PROJECT_PATH/src/main/java/$dir" -name "*.java" >> "$SOURCES"
        fi
    done

    if [ -s "$SOURCES" ]; then
        javac -parameters \
            -d "$BUILD_PATH/WEB-INF/classes" \
            -classpath "$COMMON_CLASSPATH" \
            @"$SOURCES"

        if [ $? -ne 0 ]; then
            echo
            echo "Compilation interrompue. Le WAR n'a pas été généré."
            exit 1
        fi
    fi
}

compile_layer "couche 1: annotation, util, modelview" \
    annotation util modelview

compile_layer "couche 2: models" \
    models

compile_layer "couche 3: dao et repo" \
    dao repo

compile_layer "couche 4: services" \
    services

compile_layer "couche 5: controllers, servlet, scan, main" \
    controllers servlet scan main

# Copier les bibliothèques JAR
echo "Copie des bibliothèques JAR..."
mkdir -p "$BUILD_PATH/WEB-INF/lib"

if compgen -G "$LIB_PATH/*.jar" > /dev/null; then
    cp "$LIB_PATH"/*.jar "$BUILD_PATH/WEB-INF/lib/"
    echo "  - Librairies copiees depuis $LIB_PATH"
else
    echo "  - Aucune librairie trouvee dans $LIB_PATH"
fi

# Copier les fichiers webapp
echo "Copie recursive des fichiers webapp..."
cp -r "$WEBAPP_PATH/"* "$BUILD_PATH/"

# Créer le fichier WAR
echo "Création du fichier WAR..."

cd "$BUILD_PATH" || exit 1
jar -cvf "$APP_WAR" .

# Déployer le WAR
echo "Déploiement du fichier WAR dans Tomcat..."
mv -f "$BUILD_PATH/$APP_WAR" "$CATALINA_HOME/webapps/"

echo
echo "Projet Servlet déployé et Tomcat prêt à démarrer."