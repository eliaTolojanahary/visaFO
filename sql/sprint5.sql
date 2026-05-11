  ALTER TABLE dossier ADD COLUMN IF NOT EXISTS scan_termine BOOLEAN DEFAULT FALSE;
  ALTER TABLE dossier ADD COLUMN IF NOT EXISTS date_scan_complete TIMESTAMP;
  
INSERT INTO piece_justificative_ref (libelle, id_type_titre) 
VALUES ('Photo d''identité (webcam)', NULL);

INSERT INTO piece_justificative_ref (libelle, id_type_titre) 
VALUES ('Signature numérique', NULL);