BEGIN;

-- 1) Ajouter les statuts si ils n'existent pas
INSERT INTO statut_demande (libelle)
SELECT 'PHOTO PRISE'
WHERE NOT EXISTS (
  SELECT 1 FROM statut_demande WHERE UPPER(libelle) = UPPER('PHOTO PRISE')
);

INSERT INTO statut_demande (libelle)
SELECT 'SCAN TERMINE'
WHERE NOT EXISTS (
  SELECT 1 FROM statut_demande WHERE UPPER(libelle) = UPPER('SCAN TERMINE')
);

-- 2) Ajouter colonnes de suivi dans la table demande
ALTER TABLE demande
  ADD COLUMN IF NOT EXISTS verrouille BOOLEAN DEFAULT FALSE;

ALTER TABLE demande
  ADD COLUMN IF NOT EXISTS photo_prise BOOLEAN DEFAULT FALSE;

ALTER TABLE demande
  ADD COLUMN IF NOT EXISTS scan_termine_at TIMESTAMP;

-- 3) Index utile sur la date de scan termine
CREATE INDEX IF NOT EXISTS idx_demande_scan_termine_at ON demande (scan_termine_at);

COMMIT;

