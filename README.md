# VISA FO

Application pour la gestion d'une demande de visa transformable.

## Ce qui a ete fait

- Reorganisation du module Visa pour un flux plus clair.
- Ajout des ecrans principaux Visa:
  - formulaire de demande
  - page d'erreur de validation
  - page de resultat
- Reprise de l'accueil pour garder le parcours Visa.
- Mise en place du schema PostgreSQL `visa` et des scripts SQL associes.
- Ajout de donnees de test pour initialiser l'environnement local.
- Gestion des pieces justificatives selon la logique:
  - `type_titre IS NULL` = pieces communes
  - `type_titre = investisseur / travailleur` = pieces specifiques

## Fonctionnalites actuellement couvertes

- Parcours "Nouveau titre" disponible.
- Profils geres: investisseur et travailleur.
- Validation des informations obligatoires avant enregistrement.
- Enregistrement d'une nouvelle demande avec le statut "demande creee".
- Possibilite de modifier une demande existante.
- Affichage des pieces communes et des pieces specifiques selon le profil.

## Structure utile

- `start.bat`: script d'initialisation de l'environnement local.
- `sql/create_database.sql`: cree la base `visa` si elle n'existe pas.
- `sql/table.sql`: cree le schema et les tables.
- `sql/donnees_mini_test.sql`: insere les donnees minimales.
- `sql/alter_piece_justificative_ref_nullable.sql`: migration pour autoriser les pieces communes.
- `FrameWork/`: projet Java/Tomcat.

## Utilisation de `start.bat`

Depuis la racine du projet:

```bat
start.bat
```

Ce script execute le flux complet de mise en place locale:

1. creation de la base `visa`
2. creation des tables dans le schema `visa`
3. insertion des donnees de test
4. application des migrations complementaires

## Regle pour les nouveaux scripts

Chaque nouveau script SQL doit etre ajoute dans `start.bat` dans l'ordre du flux.

Principe de base:

- si le script cree une structure, il va avant les donnees
- si le script modifie une colonne ou un comportement, il va apres `table.sql`
- si le script ajoute des donnees de reference, il va avant les donnees de test finales

Objectif: `start.bat` reste la commande unique pour reconstruire et mettre a jour la base locale.

## Execution locale

- Copier .env.example → .env
- Remplir ses propres valeurs (DB_USER, DB_PASSWORD, CATALINA_HOME)
- Configurer PostgreSQL et verifier l'utilisateur `postgres`.
- Lancer `start.bat`.
- Lancer ensuite l'application via `FrameWork/run_servlet.bat`.



