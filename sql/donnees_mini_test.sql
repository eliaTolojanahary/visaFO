

INSERT INTO situation_famille (libelle) VALUES
('Celibataire'),
('MARIE'),
('DIVORCE'),
('VEUF');

INSERT INTO nationalite (libelle) VALUES
('Malagasy'),
('Francaise'),
('Indienne'),
('Chinoise');

INSERT INTO type_demande (libelle) VALUES
('Nouveau titre'),
('Duplicata'),
('Transfert visa');

INSERT INTO type_titre (libelle) VALUES
('Commun'),
('Investisseur'),
('Travailleur');

INSERT INTO statut_demande (libelle) VALUES
('demande creee'),
('Scan termine');

INSERT INTO piece_justificative_ref (libelle, id_type_titre) VALUES

('02 photos d''identite', NULL),
('Notice de renseignement', NULL),
('Demande adressee au Ministere de l''Interieur et de la Decentralisation', NULL),
('Photocopie certifiee du visa en cours de validite', NULL),
('Photocopie certifiee de la premiere page du passeport', NULL),
('Photocopie certifiee de la carte de resident en cours de validite', NULL),
('Certificat de residence a Madagascar', NULL),
('Extrait de casier judiciaire de moins de 3 mois', NULL),
('Statut de la societe', 2),
('Extrait d''inscription au registre du commerce', 2),
('Carte fiscale', 2),
('Autorisation d''emploi delivree a Madagascar', 3),
('Attestation d''emploi delivree par l''employeur (original)', 3);
