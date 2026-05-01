-- =============================================================
-- SCRIPT DE RÉINITIALISATION — BASE visa
-- =============================================================
DROP TABLE IF EXISTS piece_fournie        CASCADE;
DROP TABLE IF EXISTS demande_piece        CASCADE;
DROP TABLE IF EXISTS dossier_demande      CASCADE;
DROP TABLE IF EXISTS demande              CASCADE;
DROP TABLE IF EXISTS passeport            CASCADE;
DROP TABLE IF EXISTS demandeur            CASCADE;
DROP TABLE IF EXISTS statut_demande       CASCADE;
DROP TABLE IF EXISTS type_titre           CASCADE;
DROP TABLE IF EXISTS type_demande         CASCADE;
DROP TABLE IF EXISTS nationalite          CASCADE;
DROP TABLE IF EXISTS situation_famille    CASCADE;

DROP TABLE IF EXISTS piece_justificative_ref CASCADE;


-- =============================================================
-- SCRIPT DE RÉINITIALISATION DES DONNÉES — BASE visa
-- =============================================================

TRUNCATE TABLE piece_fournie        RESTART IDENTITY CASCADE;
TRUNCATE TABLE demande_piece        RESTART IDENTITY CASCADE;
TRUNCATE TABLE dossier_demande      RESTART IDENTITY CASCADE;
TRUNCATE TABLE demande              RESTART IDENTITY CASCADE;
TRUNCATE TABLE passeport            RESTART IDENTITY CASCADE;
TRUNCATE TABLE demandeur            RESTART IDENTITY CASCADE;
TRUNCATE TABLE statut_demande       RESTART IDENTITY CASCADE;
TRUNCATE TABLE type_titre           RESTART IDENTITY CASCADE;
TRUNCATE TABLE type_demande         RESTART IDENTITY CASCADE;
TRUNCATE TABLE nationalite          RESTART IDENTITY CASCADE;
TRUNCATE TABLE situation_famille    RESTART IDENTITY CASCADE;

TRUNCATE TABLE piece_justificative_ref RESTART IDENTITY CASCADE;
