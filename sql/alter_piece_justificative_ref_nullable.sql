-- Migration: allow common documents by making id_type_titre nullable
-- Logic:
--   id_type_titre IS NULL  -> piece commune
--   id_type_titre = investisseur/travailleur -> piece specifique

ALTER TABLE IF EXISTS visa.piece_justificative_ref
    ALTER COLUMN id_type_titre DROP NOT NULL;
