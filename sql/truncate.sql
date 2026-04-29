-- =============================================================
-- SCRIPT DE RÉINITIALISATION — BASE visa
-- =============================================================

-- 1. Tables de liaison / enfants (dépendances les plus profondes)
DROP TABLE IF EXISTS piece_fournie        CASCADE;
DROP TABLE IF EXISTS demande_piece        CASCADE;
DROP TABLE IF EXISTS dossier_demande      CASCADE;

-- 2. Tables principales
DROP TABLE IF EXISTS demande              CASCADE;
DROP TABLE IF EXISTS passeport            CASCADE;

-- 3. Références liées aux demandes
DROP TABLE IF EXISTS piece_justificative_ref CASCADE;

-- 4. Tables du demandeur
DROP TABLE IF EXISTS demandeur            CASCADE;

-- 5. Tables de référence / lookups
DROP TABLE IF EXISTS statut_demande       CASCADE;
DROP TABLE IF EXISTS type_titre           CASCADE;
DROP TABLE IF EXISTS type_demande         CASCADE;
DROP TABLE IF EXISTS nationalite          CASCADE;
DROP TABLE IF EXISTS situation_famille    CASCADE;