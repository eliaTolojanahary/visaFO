-- PostgreSQL:
-- 1) Creer la base (voir create_database.sql)
-- 2) Executer ce script en etant connecte a la base visa
CREATE DATABASE visa;
\c visa 

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
