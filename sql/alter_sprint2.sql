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