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