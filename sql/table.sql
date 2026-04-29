-- PostgreSQL:
-- 1) Creer la base (voir create_database.sql)
-- 2) Executer ce script en etant connecte a la base visa
DROP DATABASE  visa;
CREATE DATABASE  visa;
\c visa 


DROP TABLE IF EXISTS demande_piece;
DROP TABLE IF EXISTS demande;
DROP TABLE IF EXISTS passeport;
DROP TABLE IF EXISTS piece_justificative_ref;
DROP TABLE IF EXISTS demandeur;
DROP TABLE IF EXISTS statut_demande;
DROP TABLE IF EXISTS type_titre;
DROP TABLE IF EXISTS type_demande;
DROP TABLE IF EXISTS nationalite;
DROP TABLE IF EXISTS situation_famille;


CREATE TABLE IF NOT EXISTS situation_famille (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS nationalite (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS type_demande (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS type_titre (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS statut_demande (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS piece_justificative_ref (
    id SERIAL PRIMARY KEY,
    libelle VARCHAR(255) NOT NULL,
    id_type_titre BIGINT REFERENCES type_titre(id)
);

CREATE TABLE IF NOT EXISTS demandeur (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(120) NOT NULL,
    prenom VARCHAR(120),
    nom_jeune_fille VARCHAR(120),
    date_naissance DATE NOT NULL,
    situation_famille_id BIGINT NOT NULL REFERENCES situation_famille(id),
    nationalite_id BIGINT NOT NULL REFERENCES nationalite(id),
    adresse_madagascar TEXT NOT NULL,
    numero_telephone VARCHAR(30) NOT NULL,
    email VARCHAR(255),
    profession VARCHAR(150) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS passeport (
    id SERIAL PRIMARY KEY,
    demandeur_id BIGINT NOT NULL REFERENCES demandeur(id) ON DELETE CASCADE,
    numero_passeport VARCHAR(50) NOT NULL UNIQUE,
    date_delivrance DATE NOT NULL,
    date_expiration DATE NOT NULL,
    pays_delivrance VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_passeport_dates CHECK (date_expiration > date_delivrance)
);

CREATE TABLE IF NOT EXISTS demande (
    id SERIAL PRIMARY KEY,
    passeport_id BIGINT NOT NULL REFERENCES passeport(id),
    type_demande_id BIGINT NOT NULL REFERENCES type_demande(id),
    type_titre_id BIGINT REFERENCES type_titre(id),
    statut_id BIGINT NOT NULL REFERENCES statut_demande(id),
    visa_date_entree DATE NOT NULL,
    visa_lieu_entree VARCHAR(150) NOT NULL,
    visa_date_expiration DATE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_visa_date_expiration CHECK (visa_date_expiration >= visa_date_entree)
);

CREATE TABLE IF NOT EXISTS demande_piece (
    id SERIAL PRIMARY KEY,
    demande_id BIGINT NOT NULL REFERENCES demande(id) ON DELETE CASCADE,
    piece_id BIGINT NOT NULL REFERENCES piece_justificative_ref(id),
    cochee BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (demande_id, piece_id)
);


CREATE INDEX IF NOT EXISTS idx_demande_demandeur ON demande(id);
CREATE INDEX IF NOT EXISTS idx_demande_statut ON demande(statut_id);
CREATE INDEX IF NOT EXISTS idx_demande_type ON demande(type_demande_id, type_titre_id);
CREATE INDEX IF NOT EXISTS idx_demande_piece_demande ON demande_piece(demande_id);
CREATE INDEX IF NOT EXISTS idx_demande_piece_cochee ON demande_piece(demande_id, cochee);

ALTER TABLE piece_justificative_ref
ALTER COLUMN id_type_titre DROP NOT NULL;
-- =============================================================
-- MIGRATION SPRINT 2 : delta table.sql -> schema.sql
-- A executer apres table.sql dans start.bat
--
-- Contenu :
--   1. Nouvelles tables de reference (type_document)
--   2. Alterations sur demande (type_document_id, ref_demande)
--   3. Nouvelles tables dossier et dossier_demande
--   4. Nouveaux statuts manquants
--   5. Nouveaux index
-- =============================================================


-- =============================================================
-- 1. NOUVELLES TABLES DE REFERENCE
-- =============================================================

-- Document vise par la demande (ex: visa, titre de residence).
-- Utilise principalement pour les duplicatas afin de preciser
-- quel document physique est a reemettre.
-- Extensible a tout type de demande futur.
CREATE TABLE IF NOT EXISTS type_document (
    id      SERIAL PRIMARY KEY,
    libelle VARCHAR(100) NOT NULL
);


-- =============================================================
-- 2. ALTERATIONS SUR LA TABLE demande
-- =============================================================

-- Identifiant metier lisible, genere par l'application.
-- Format : YYYYMMDD-HHMMSS-<code_type_demande>
-- ex: 20250422-143012-DUP
ALTER TABLE demande
    ADD COLUMN IF NOT EXISTS ref_demande      VARCHAR(100),
    ADD COLUMN IF NOT EXISTS type_document_id BIGINT REFERENCES type_document(id);

-- ref_demande doit etre unique une fois renseignee.
-- On cree l'index conditionnel pour eviter les conflits sur les lignes existantes NULL.
CREATE UNIQUE INDEX IF NOT EXISTS idx_demande_ref
    ON demande(ref_demande)
    WHERE ref_demande IS NOT NULL;


-- =============================================================
-- 3. NOUVELLES TABLES DOSSIER
-- =============================================================

-- Un dossier regroupe une ou plusieurs demandes successives
-- d'un meme demandeur (demande initiale, duplicata, etc.).
--
-- previous_demande_ref : ref fournie par le demandeur comme justificatif
--   (ex: numero sur un recepisse papier). NULL si aucun antecedent.
-- new_demande_ref : ref generee pour ce dossier si reprise d'un
--   dossier anterieur. NULL pour un dossier sans antecedent.
-- mention : qualification libre posee par l'agent.
--   ex : "Duplicata - antecedent non retrouve"
-- visa_approuve_confirme : TRUE si l'agent a confirme manuellement
--   que le visa du demandeur etait approuve lors d'une demande anterieure.
--
-- Contrainte : si previous_demande_ref est renseigne,
--   new_demande_ref est obligatoire.
CREATE TABLE IF NOT EXISTS dossier (
    id                     SERIAL PRIMARY KEY,
    previous_demande_ref   VARCHAR(100),
    new_demande_ref        VARCHAR(100) UNIQUE,
    mention                VARCHAR(255),
    visa_approuve_confirme BOOLEAN   NOT NULL DEFAULT FALSE,
    created_at             TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_refs_coherentes CHECK (
        previous_demande_ref IS NULL
        OR new_demande_ref IS NOT NULL
    )
);

-- Table de liaison dossier <-> demande.
-- Permet de rattacher N demandes a un meme dossier.
-- La premiere demande inseree (created_at ASC) est consideree
-- comme la demande initiale du dossier.
CREATE TABLE IF NOT EXISTS dossier_demande (
    id         SERIAL PRIMARY KEY,
    dossier_id BIGINT    NOT NULL REFERENCES dossier(id) ON DELETE CASCADE,
    demande_id BIGINT    NOT NULL REFERENCES demande(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (dossier_id, demande_id)
);


-- =============================================================
-- 4. STATUTS MANQUANTS
-- =============================================================

-- Insere uniquement les statuts absents pour rester idempotent.
INSERT INTO statut_demande (libelle)
SELECT libelle FROM (VALUES
    ('En cours de traitement'),
    ('En attente'),
    ('Valide'),
    ('Refuse')
) AS nouveaux(libelle)
WHERE NOT EXISTS (
    SELECT 1 FROM statut_demande s WHERE s.libelle = nouveaux.libelle
);


-- =============================================================
-- 5. NOUVEAUX INDEX
-- =============================================================

CREATE INDEX IF NOT EXISTS idx_demande_document     ON demande(type_document_id);
CREATE INDEX IF NOT EXISTS idx_dossier_demande_lien ON dossier_demande(dossier_id, demande_id);
CREATE INDEX IF NOT EXISTS idx_demandeur_identite   ON demandeur(nom, prenom, date_naissance);
CREATE INDEX IF NOT EXISTS idx_passeport_demandeur  ON passeport(demandeur_id);

CREATE TABLE IF NOT EXISTS piece_fournie (
    id            SERIAL PRIMARY KEY,
    demande_id    BIGINT NOT NULL REFERENCES demande(id) ON DELETE CASCADE,
    piece_ref_id  BIGINT NOT NULL REFERENCES piece_justificative_ref(id),
    chemin_fichier VARCHAR(512) NOT NULL,
    nom_fichier   VARCHAR(255) NOT NULL,
    taille_bytes  BIGINT,
    mime_type     VARCHAR(100),
    uploaded_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(demande_id, piece_ref_id)
);

-- Ajout du statut SCAN TERMINÉ
INSERT INTO statut_demande (libelle)
SELECT 'SCAN TERMINÉ'
WHERE NOT EXISTS (SELECT 1 FROM statut_demande WHERE libelle = 'SCAN TERMINÉ');

-- Colonne verrouille
ALTER TABLE demande ADD COLUMN IF NOT EXISTS verrouille BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_piece_fournie_demande ON piece_fournie(demande_id);
CREATE INDEX IF NOT EXISTS idx_piece_fournie_piece   ON piece_fournie(piece_ref_id);