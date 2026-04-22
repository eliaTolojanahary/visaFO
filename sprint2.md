# Sprint 2 : duplicata titre residence (pas d'antecedent en base)
## NB : Lancer le script `alter_sprint2.sql` apres `table.sql` pour ajouter les nouvelles tables et colonnes necessaires 

## Contexte

Un demandeur arrive au guichet, il dit qu'il a perdu son titre de residence.
Sauf que dans la base on retrouve rien (ancienne demande introuvable).

## Objectif
* on ouvre un nouveau dossier
* on met une mention **"duplicata — antecedent non retrouvé"**
* l'agent confirme a la main que le visa etait deja approuvé
* et on lance le duplicata normal

1. Database - Jemima (TL) Branche: dev
- Ajout des table document et type_document
- Changement dans la table `demande` : 
    + type_document_id
    + ref_demande
- Ajout des tables dossier et dossier_demande : 
    + dossier : id,previous_demande_ref,new_demande_ref,mention,visa_approuve_confirme,created_at,updated_at,
    + dossier_demande : id,dossier_id,demande_id (suivi des dossier rajouter a la demande)
- Ajout statuts manquants dans statut_demande :
    + En cours de traitement, En attente, Valide, Refuse
- script de migration : `alter_sprint2.sql`
    + a ajouter dans `start.bat` apres `table.sql`

2. Back-end - Mioty : Branche: sprint/2/feature/recherche-dossier
**Module Recheche:** 
Pour voir si la demande est presente ou pas dans la base de donnée 
- Classe: DemandeDAO 
    => prototype: findBy(colonne, valeur)
- Classe: DemandeRepository 
    => fonction: findBy(colonne, valeur) => retourne une demande ou null
- Classe: DemandeService
    => classe fonction: searchBy(colonne, valeur) => appel repository.findBy(colonne, valeur)
chercher demandeur avec : 
* nom  
* prenom 
* date naissance

Pour voir si le passeport est presente ou pas dans la base de donnée
- Classe: PasseportDAO 
    => prototype: findByNum(numero_passeport)
- Classe: PasseportRepository 
    => fonction: findByNum(colonne, valeur) => retourne un passeport ou null
- Classe: PasseportService
    => classe fonction: getByNum(colonne, valeur) => appel repository.findByNum(colonne, valeur)
chercher passeport avec :
* numero_passeport


Si trouvé
* on reutilise demandeur + passeport
* flow normal

Si pas trouvé
* on cree :
  * nouveau demandeur
  * nouveau passeport
* Statut de la demande de visa : Valide
* Statut de la demande de titre de residence / duplicata ou autre : En cours de traitement

**Module Dossier:**
Pour creer et suivre un dossier

- Classe: DossierDAO
    => prototype: create(dossier)
    => prototype: findByDemande(demande_id)

- Classe: DossierRepository
    => fonction: create(dossier) => retourne le dossier cree
    => fonction: findByDemande(demande_id) => retourne un dossier ou null

- Classe: DossierService
    => fonction: ouvrirDossierDuplicata(demandeur, passeport, previous_demande_ref) 
        - cree la demande avec type_demande = Duplicata, type_document = Titre de residence
        - statut = En cours de traitement
        - genere ref_demande format : YYYYMMDD-HHMMSS-DUP
        - cree le dossier avec :
            + mention = "Duplicata — antecedent non retrouve"
            + visa_approuve_confirme = true
            + previous_demande_ref = ref fournie par le demandeur (nullable)
            + new_demande_ref = ref_demande generee
        - insere dans dossier_demande
    => fonction: attacherDemande(dossier_id, demande_id)
        - insere dans dossier_demande si pas deja present

**Regles metier a enforcer cote application :**
* type_document_id obligatoire si type_demande = Duplicata
* previous_demande_ref renseigne => new_demande_ref obligatoire (contrainte deja en base, verifier aussi cote service)
* un passeport ne peut pas etre rattache a deux demandeurs differents


3. Front-end - Elia - Branche :  sprint/2/feature/refact-flow-demande

### Recherche

Avant le formulaire :

* champ recherche :
  nom / prenom / date naissance

si trouvé :
- On affiche les infos du demandeur (nom, prenom, date naissance, nationalité, adresse, tel, email, profession) + infos du passeport (numero, dates, pays) 
    + Action de la page : 
        - Mettre a jour 
        - Nouvelle demande pour ce demandeur => choix du type de demande (visa, titre de residence, duplicata, etc)
    
si pas trouvé :
→ Message : "Aucun demandeur trouvé, veuillez remplir le formulaire pour créer une nouvelle demande" 
→ Invite d'action avec type de demande (visa, titre de residence, duplicata, etc) 
    - Si visa => nouveau titre flux normal
    - Autre => On remplit le formulaire pour creer un nouveau dossier (status visa valide) apres avoir remplit les info manquant du demandeur on est rediriger vers le formulaire pour le type de demande choisi (titre de residence, duplicata, etc)
→ on continue normal (mention deja remplie)

---

### etape 2 : formulaire

2 blocs

---

#### Bloc A (normal) cf sprint 1

* nom, prenom, date naissance
* nationalité, situation familiale
* adresse, tel, email, profession
* passeport (numero, dates, pays)

---

#### Bloc B (nouveau duplicata)

* checkbox :
  ☐ "le demandeur confirme qu'il avait deja un visa approuvé"

* champ texte (optionnel) :
  ancienne reference → `previous_demande_ref`

* pieces justificatives (checkbox) → `demande_piece`
    + pieces affichees : communes (id_type_titre NULL) + specifiques selon type_titre du demandeur
    + au moins une piece cochee obligatoire avant soumission

* mention affichée (read only) :
  "Duplicata — antecedent non retrouvé"

---

### etape 3 : soumission

* validation avant envoi :
    - Bloc A complet (tous champs obligatoires remplis)
    - checkbox visa approuve cochee
    - au moins une piece justificative cochee
    - type_document renseigne (Titre de residence)
* si validation ok => appel DossierService.ouvrirDossierDuplicata()
* redirect vers suivi dossier avec ref_demande generee

---

### suivi dossier

Afficher :

* mention (badge couleur genre orange)
* statut (historique simple)
* indicateur si visa confirmé

**Donnees a afficher :**
* ref_demande
* type_demande + type_document (ex : Duplicata — Titre de residence)
* nom complet demandeur
* statut courant (badge couleur selon statut)
    + En cours de traitement => bleu
    + En attente => orange
    + Valide => vert
    + Refuse => rouge
* liste des pieces justificatives (cochee / non cochee)
* mention dossier si presente (badge orange)
* indicateur visa_approuve_confirme si true : "Visa approuvé confirmé par agent"