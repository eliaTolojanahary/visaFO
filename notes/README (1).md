# Projet Visa – Mr Naina

## 1. Contexte

Un étranger effectue une demande de visa.  
Les visas sont classés en deux catégories :

### 1.1 Visa transformable
- Permet de changer de statut (ex : étudiant → salarié)
- Nécessite une demande auprès de la préfecture
- Doit être effectué avant l’expiration du visa

Exemples :
- Visa étudiant
- Visa de travail

Processus :
1. Faire une demande de changement de statut
2. Fournir les documents nécessaires
3. Attendre la décision de la préfecture

### 1.2 Visa non transformable
- Ne permet pas de changer de statut
- Oblige à quitter le territoire à expiration
- Nécessite une nouvelle demande pour revenir

---

## 2. Contraintes de l'application

- Cas réel : base de données de visas
- Cas du projet : base fictive (données saisies directement dans l’application)

---

## 3. Fonctionnalités principales

### 3.1 Gestion des visas
- Saisie des données :
  - Type
  - Durée
  - Statut actuel
  - Autres informations

### 3.2 Demande de changement de statut
- Formulaire contenant :
  - État civil
  - Informations du visa actuel
  - Visa demandé
- Informations complémentaires :
  - Documents requis
  - Délais de traitement
- Types concernés :
  - Travailleur
  - Étudiant

### 3.3 Sécurité
- Obligation d’envoyer une demande avant transformation du visa

---

## 4. Types de demande de visa

- Nouveau titre
- Duplicata (carte de résident)
- Transfert de visa
- Renouvellement

Remarques :
- Les données varient selon le type de demande
  - Exemple : numéro de passeport, perte/vol, changement de statut
- Si des données existent déjà : mise à jour (ex : renouvellement)
- Non inclus pour le moment :
  - Duplicata
  - Transfert

---

## 5. Statut des demandes

Chaque demande peut être :
- En cours de traitement
- Acceptée
- Refusée

---

## 6. Processus global

Objectif final :
- Obtenir carte de résident et visa
- Même date de fin de validité

---

## 7. Architecture

- Backoffice : Spring Boot / Spring MVC
- Frontoffice : Framework maison

---
