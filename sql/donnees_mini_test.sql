
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
('Demandec cree'),
('Scan termine');

INSERT INTO piece_justificative_ref (libelle, id_type_titre) VALUES
('02 photos d''identite', 1),
('Notice de renseignement', 1),
('Demande adressee au Ministere de l''Interieur et de la Decentralisation', 1),
('Photocopie certifiee du visa en cours de validite', 1),
('Photocopie certifiee de la premiere page du passeport', 1),
('Photocopie certifiee de la carte de resident en cours de validite', 1),
('Certificat de residence a Madagascar', 1),
('Extrait de casier judiciaire de moins de 3 mois', 1),
('Statut de la societe', 1),
('Extrait d''inscription au registre du commerce', 1),
('Carte fiscale', 1),
('Autorisation d''emploi delivree a Madagascar', 1),
('Attestation d''emploi delivree par l''employeur (original)', 1),
('statut_societe',2),
('registre_commerce_reference',2),
('carte_fiscale_reference',2),
('autorisation_emploi_reference',3),
('attestation_emploi_reference',3);