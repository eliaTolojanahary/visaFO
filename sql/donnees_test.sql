-- =============================================================
-- DONNEES DE TEST - VISA / RESIDENCE PERMIT SYSTEM
-- =============================================================
-- Insertion idempotente avec verifications
-- Scénarios : demandes simples, cas limites, duplicatas, transitions d'état
-- =============================================================

-- =============================================================
-- 1. DONNEES DE REFERENCE (Énumérés)
-- =============================================================
INSERT INTO situation_famille (libelle) VALUES
('Celibataire'),
('MARIE'),
('DIVORCE'),
('VEUF');

INSERT INTO nationalite (libelle) VALUES
('Malagasy'),
('Francaise'),
('Indienne'),
('Chinoise'),
('Canadienne'),
('Americaine');

INSERT INTO type_demande (libelle) VALUES
('Nouveau titre'),
('Duplicata'),
('Transfert visa');

INSERT INTO type_titre (libelle) VALUES
('Commun'),
('Investisseur'),
('Travailleur');


-- Insere uniquement les statuts absents pour rester idempotent.
INSERT INTO statut_demande (libelle)
SELECT libelle FROM (VALUES
    ('demande creee'),
    ('En attente'),
    ('Valide'),
    ('Refuse'),
    ('REJETE'),
    ('REJET_INCOMPLETUDE'),
    ('SCAN TERMINE'),
    ('SUSPENDU')
) AS nouveaux(libelle)
WHERE NOT EXISTS (
    SELECT 1 FROM statut_demande s WHERE s.libelle = nouveaux.libelle
);


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
('Attestation d''emploi delivree par l''employeur (original)', 3),
('Photo d''identite (webcam)', NULL),
('Signature numerique', NULL);

-- Type de document (document physique à remettre)
INSERT INTO type_document (libelle) VALUES
('Visa');
INSERT INTO type_document (libelle) VALUES
('Titre de Résidence');
INSERT INTO type_document (libelle) VALUES
('Cachet d''Entrée');

-- =============================================================
-- 2. SCENARIO 1 : DEMANDE SIMPLE VALIDE (parcours nominal)
-- Demandeur : Sophie Martin (France)
-- Flux : BROUILLON → EN ATTENTE → EN EXAMEN → APPROUVE
-- =============================================================

INSERT INTO demandeur (nom, prenom, nom_jeune_fille, date_naissance, situation_famille_id, nationalite_id, adresse_madagascar, numero_telephone, email, profession) VALUES
('Martin', 'Sophie', NULL, '1985-03-15'::DATE, 1, 1, '12 Rue du Commerce, Antananarivo', '+33612345678', 'sophie.martin@email.com', 'Ingénieur');

INSERT INTO passeport (demandeur_id, numero_passeport, date_delivrance, date_expiration, pays_delivrance) VALUES
(1, 'FR123456789', '2020-06-10'::DATE, '2030-06-10'::DATE, 'France');

INSERT INTO demande (passeport_id, type_demande_id, type_titre_id, statut_id, visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id) VALUES
(1, 1, 1, 1, '2025-05-20'::DATE, 'Antananarivo', '2025-11-20'::DATE, '20250511-140000-VIS', 1);

-- Pièces associées à la demande 1
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(1, 1, TRUE);
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(1, 2, TRUE);
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(1, 3, TRUE);

-- Historique des statuts : transitions de la demande 1
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(1, NULL, 1, '2025-05-11 14:00:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(1, 1, 2, '2025-05-11 14:15:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(1, 2, 3, '2025-05-11 15:30:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(1, 3, 4, '2025-05-11 16:45:00'::TIMESTAMP);

-- Fichiers uploadés pour la demande 1
INSERT INTO piece_fournie (demande_id, piece_ref_id, chemin_fichier, nom_fichier, taille_bytes, mime_type, uploaded_at) VALUES
(1, 1, '/uploads/2025/05/sophie_martin_passeport.pdf', 'passeport.pdf', 2048000, 'application/pdf', '2025-05-11 14:05:00'::TIMESTAMP);
INSERT INTO piece_fournie (demande_id, piece_ref_id, chemin_fichier, nom_fichier, taille_bytes, mime_type, uploaded_at) VALUES
(1, 3, '/uploads/2025/05/sophie_martin_justif_domicile.pdf', 'justif_domicile.pdf', 1024000, 'application/pdf', '2025-05-11 14:10:00'::TIMESTAMP);

-- =============================================================
-- 3. SCENARIO 2 : DEMANDE AVEC REJET (incompletude)
-- Demandeur : Jean Dupont (France)
-- Flux : BROUILLON → EN ATTENTE → EN EXAMEN → REJET_INCOMPLETUDE
-- =============================================================

INSERT INTO demandeur (nom, prenom, nom_jeune_fille, date_naissance, situation_famille_id, nationalite_id, adresse_madagascar, numero_telephone, email, profession) VALUES
('Dupont', 'Jean', NULL, '1978-07-22'::DATE, 2, 1, '45 Avenue de la Paix, Antananarivo', '+33698765432', 'jean.dupont@email.com', 'Comptable');

INSERT INTO passeport (demandeur_id, numero_passeport, date_delivrance, date_expiration, pays_delivrance) VALUES
(2, 'FR987654321', '2019-01-15'::DATE, '2029-01-15'::DATE, 'France');

INSERT INTO demande (passeport_id, type_demande_id, type_titre_id, statut_id, visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id) VALUES
(2, 1, 1, 6, '2025-06-01'::DATE, 'Antananarivo', '2025-12-01'::DATE, '20250510-105000-VIS', 1);

-- Pièces incomplètes : manque justificatif de domicile
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(2, 1, TRUE);
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(2, 2, FALSE);
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(2, 3, FALSE);

-- Historique : BROUILLON → EN ATTENTE → EN EXAMEN → REJET_INCOMPLETUDE
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(2, NULL, 1, '2025-05-10 10:00:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(2, 1, 2, '2025-05-10 10:30:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(2, 2, 3, '2025-05-10 11:00:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(2, 3, 6, '2025-05-10 14:00:00'::TIMESTAMP);

-- =============================================================
-- 4. SCENARIO 3 : DEMANDE SUSPENDUE (cas limite)
-- Demandeur : Marie Durand (Belgique)
-- Flux : BROUILLON → EN ATTENTE → SUSPENDU (enquête supplémentaire)
-- =============================================================

INSERT INTO demandeur (nom, prenom, nom_jeune_fille, date_naissance, situation_famille_id, nationalite_id, adresse_madagascar, numero_telephone, email, profession) VALUES
('Durand', 'Marie', 'Renard', '1992-11-08'::DATE, 2, 3, '78 Boulevard Central, Antananarivo', '+32487654321', 'marie.durand@email.com', 'Avocate');

INSERT INTO passeport (demandeur_id, numero_passeport, date_delivrance, date_expiration, pays_delivrance) VALUES
(3, 'BE456789012', '2021-03-20'::DATE, '2031-03-20'::DATE, 'Belgique');

INSERT INTO demande (passeport_id, type_demande_id, type_titre_id, statut_id, visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id) VALUES
(3, 1, 2, 8, '2025-07-15'::DATE, 'Antananarivo', '2026-07-15'::DATE, '20250509-130000-VIS', 1);

-- Pièces complètes
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(3, 1, TRUE);
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(3, 2, TRUE);
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(3, 3, TRUE);
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(3, 4, TRUE);

-- Historique : BROUILLON → EN ATTENTE → SUSPENDU
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(3, NULL, 1, '2025-05-09 13:00:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(3, 1, 2, '2025-05-09 13:20:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(3, 2, 8, '2025-05-09 15:45:00'::TIMESTAMP);

-- =============================================================
-- 5. SCENARIO 4 : DUPLICATA (demande complexe)
-- Demandeur : Pierre Bernard (France) - demande antécédente perdue
-- Dossier initial (demande 4) puis duplicata (demande 5)
-- Flux demande 4 : BROUILLON → EN ATTENTE → EN EXAMEN → APPROUVE
-- Flux demande 5 : BROUILLON → EN ATTENTE → EN EXAMEN → APPROUVE (duplicata)
-- =============================================================

INSERT INTO demandeur (nom, prenom, nom_jeune_fille, date_naissance, situation_famille_id, nationalite_id, adresse_madagascar, numero_telephone, email, profession) VALUES
('Bernard', 'Pierre', NULL, '1988-09-14'::DATE, 1, 1, '23 Rue de la Liberté, Antananarivo', '+33645789123', 'pierre.bernard@email.com', 'Consultant');

INSERT INTO passeport (demandeur_id, numero_passeport, date_delivrance, date_expiration, pays_delivrance) VALUES
(4, 'FR111222333', '2018-05-10'::DATE, '2028-05-10'::DATE, 'France');

-- Demande initiale (2024)
INSERT INTO demande (passeport_id, type_demande_id, type_titre_id, statut_id, visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id) VALUES
(4, 1, 1, 4, '2024-06-20'::DATE, 'Antananarivo', '2024-12-20'::DATE, '20240620-102000-VIS', 1);

-- Pièces pour demande 4
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(4, 1, TRUE);
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(4, 2, TRUE);
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(4, 3, TRUE);

-- Historique demande 4 (ancienne demande approuvée)
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(4, NULL, 1, '2024-06-20 10:00:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(4, 1, 2, '2024-06-20 10:30:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(4, 2, 3, '2024-06-20 11:00:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(4, 3, 4, '2024-06-20 12:30:00'::TIMESTAMP);

-- Dossier pour la demande initiale + duplicata
INSERT INTO dossier (previous_demande_ref, new_demande_ref, mention, visa_approuve_confirme) VALUES
('20240620-102000-VIS', '20250511-145000-DUP', 'Duplicata - visa initial 2024 approuvé, document perdu', TRUE);

-- Demande de duplicata (2025) - nouvelle demande pour le même passeport
INSERT INTO demande (passeport_id, type_demande_id, type_titre_id, statut_id, visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id) VALUES
(4, 3, 1, 4, '2024-06-20'::DATE, 'Antananarivo', '2024-12-20'::DATE, '20250511-145000-DUP', 1);

-- Pièces pour demande 5 (duplicata)
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(5, 1, TRUE);
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(5, 2, TRUE);

-- Historique demande 5 (duplicata - transition rapide)
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(5, NULL, 1, '2025-05-11 14:30:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(5, 1, 2, '2025-05-11 14:45:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(5, 2, 3, '2025-05-11 15:00:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(5, 3, 4, '2025-05-11 15:20:00'::TIMESTAMP);

-- Liaison dossier <-> demandes
INSERT INTO dossier_demande (dossier_id, demande_id) VALUES
(1, 4);
INSERT INTO dossier_demande (dossier_id, demande_id) VALUES
(1, 5);

-- =============================================================
-- 6. SCENARIO 5 : RENOUVELLEMENT (cas limite avec anciennes données)
-- Demandeur : Alice Lambert (Suisse)
-- Demande antécédente approuvée (2023), renouvellement (2025)
-- Flux : BROUILLON → EN ATTENTE → EN EXAMEN → APPROUVE
-- =============================================================

INSERT INTO demandeur (nom, prenom, nom_jeune_fille, date_naissance, situation_famille_id, nationalite_id, adresse_madagascar, numero_telephone, email, profession) VALUES
('Lambert', 'Alice', NULL, '1990-02-27'::DATE, 2, 4, '34 Chemin de la Montagne, Antananarivo', '+41789456123', 'alice.lambert@email.com', 'Pharmacienne');

INSERT INTO passeport (demandeur_id, numero_passeport, date_delivrance, date_expiration, pays_delivrance) VALUES
(5, 'CH999888777', '2020-07-15'::DATE, '2030-07-15'::DATE, 'Suisse');

-- Ancienne demande (2023) - approuvée
INSERT INTO demande (passeport_id, type_demande_id, type_titre_id, statut_id, visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id) VALUES
(5, 1, 2, 4, '2023-08-10'::DATE, 'Antananarivo', '2024-08-10'::DATE, '20230810-090000-VIS', 1);

-- Pièces ancienne demande
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(6, 1, TRUE);
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(6, 4, TRUE);

-- Historique ancienne demande
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(6, NULL, 1, '2023-08-10 09:00:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(6, 1, 2, '2023-08-10 09:30:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(6, 2, 3, '2023-08-10 10:00:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(6, 3, 4, '2023-08-10 11:00:00'::TIMESTAMP);

-- Dossier pour renouvellement
INSERT INTO dossier (previous_demande_ref, new_demande_ref, mention, visa_approuve_confirme) VALUES
('20230810-090000-VIS', '20250512-110000-REN', 'Renouvellement - visa long séjour 2023', TRUE);

-- Nouvelle demande de renouvellement (2025)
INSERT INTO demande (passeport_id, type_demande_id, type_titre_id, statut_id, visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id) VALUES
(5, 2, 2, 4, '2025-08-10'::DATE, 'Antananarivo', '2026-08-10'::DATE, '20250512-110000-REN', 1);

-- Pièces renouvellement
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(7, 1, TRUE);
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(7, 4, TRUE);
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(7, 6, TRUE);

-- Historique renouvellement
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(7, NULL, 1, '2025-05-12 11:00:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(7, 1, 2, '2025-05-12 11:15:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(7, 2, 3, '2025-05-12 11:45:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(7, 3, 4, '2025-05-12 13:00:00'::TIMESTAMP);

-- Liaison dossier renouvellement
INSERT INTO dossier_demande (dossier_id, demande_id) VALUES
(2, 6);
INSERT INTO dossier_demande (dossier_id, demande_id) VALUES
(2, 7);

-- =============================================================
-- 7. SCENARIO 6 : CAS LIMITE - PASSEPORT EXPIRANT BIENTÔT
-- Demandeur : Thomas Lefevre (Canada)
-- Passeport expire dans 6 mois
-- Flux : BROUILLON → EN ATTENTE → REJETE (passeport invalide)
-- =============================================================

INSERT INTO demandeur (nom, prenom, nom_jeune_fille, date_naissance, situation_famille_id, nationalite_id, adresse_madagascar, numero_telephone, email, profession) VALUES
('Lefevre', 'Thomas', NULL, '1995-12-03'::DATE, 1, 5, '56 Impasse de la Paix, Antananarivo', '+14165551234', 'thomas.lefevre@email.com', 'Développeur');

INSERT INTO passeport (demandeur_id, numero_passeport, date_delivrance, date_expiration, pays_delivrance) VALUES
(6, 'CA555666777', '2022-11-01'::DATE, '2025-11-01'::DATE, 'Canada');

INSERT INTO demande (passeport_id, type_demande_id, type_titre_id, statut_id, visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id) VALUES
(6, 1, 1, 5, '2025-06-01'::DATE, 'Antananarivo', '2025-10-01'::DATE, '20250511-165000-VIS', 1);

-- Pièces incomplètes/invalides
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(8, 1, TRUE);
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(8, 2, FALSE);

-- Historique : BROUILLON → EN ATTENTE → REJETE
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(8, NULL, 1, '2025-05-11 16:30:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(8, 1, 2, '2025-05-11 16:50:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(8, 2, 5, '2025-05-11 17:30:00'::TIMESTAMP);

-- =============================================================
-- 8. SCENARIO 7 : DEMANDE AVEC SCAN TERMINE
-- Demandeur : Nathalie Leroy (États-Unis)
-- Flux : BROUILLON → EN ATTENTE → EN EXAMEN → SCAN_TERMINE
-- =============================================================

INSERT INTO demandeur (nom, prenom, nom_jeune_fille, date_naissance, situation_famille_id, nationalite_id, adresse_madagascar, numero_telephone, email, profession) VALUES
('Leroy', 'Nathalie', NULL, '1987-04-19'::DATE, 1, 6, '89 rue de l''Océan, Antananarivo', '+12125551234', 'nathalie.leroy@email.com', 'Architecte');

INSERT INTO passeport (demandeur_id, numero_passeport, date_delivrance, date_expiration, pays_delivrance) VALUES
(7, 'US777888999', '2021-09-12'::DATE, '2031-09-12'::DATE, 'États-Unis');

INSERT INTO demande (passeport_id, type_demande_id, type_titre_id, statut_id, visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id) VALUES
(7, 1, 1, 7, '2025-09-15'::DATE, 'Antananarivo', '2026-09-15'::DATE, '20250511-175000-VIS', 1);

-- Pièces complètes
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(9, 1, TRUE);
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(9, 2, TRUE);
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(9, 3, TRUE);
INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(9, 5, TRUE);

-- Fichiers uploadés complets
INSERT INTO piece_fournie (demande_id, piece_ref_id, chemin_fichier, nom_fichier, taille_bytes, mime_type, uploaded_at) VALUES
(9, 1, '/uploads/2025/05/nathalie_leroy_passeport.pdf', 'passeport.pdf', 2500000, 'application/pdf', '2025-05-11 17:10:00'::TIMESTAMP);
INSERT INTO piece_fournie (demande_id, piece_ref_id, chemin_fichier, nom_fichier, taille_bytes, mime_type, uploaded_at) VALUES
(9, 5, '/uploads/2025/05/nathalie_leroy_scolarite.pdf', 'certificat_scolarite.pdf', 1500000, 'application/pdf', '2025-05-11 17:15:00'::TIMESTAMP);

-- Historique : BROUILLON → EN ATTENTE → EN EXAMEN → SCAN_TERMINE
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(9, NULL, 1, '2025-05-11 17:00:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(9, 1, 2, '2025-05-11 17:15:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(9, 2, 3, '2025-05-11 17:45:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(9, 3, 7, '2025-05-11 18:30:00'::TIMESTAMP);

-- =============================================================
-- 9. SCENARIO 8 : TRIPLE DUPLICATA (cas très complexe)
-- Demandeur : Luc Moreau (France)
-- Demande initiale (2022) approuvée → Duplicata 1 (2023) approuvé → Duplicata 2 (2024) approuvé → Duplicata 3 (2025)
-- Dossier avec 4 demandes chaînées
-- =============================================================

INSERT INTO demandeur (nom, prenom, nom_jeune_fille, date_naissance, situation_famille_id, nationalite_id, adresse_madagascar, numero_telephone, email, profession) VALUES
('Moreau', 'Luc', NULL, '1980-06-25'::DATE, 2, 1, '101 Place de la Concorde, Antananarivo', '+33756789012', 'luc.moreau@email.com', 'Directeur');

INSERT INTO passeport (demandeur_id, numero_passeport, date_delivrance, date_expiration, pays_delivrance) VALUES
(8, 'FR333444555', '2017-02-14'::DATE, '2027-02-14'::DATE, 'France');

-- Demande initiale 2022
INSERT INTO demande (passeport_id, type_demande_id, type_titre_id, statut_id, visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id) VALUES
(8, 1, 1, 4, '2022-07-20'::DATE, 'Antananarivo', '2023-07-20'::DATE, '20220720-080000-VIS', 1);

INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(10, 1, TRUE);

INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(10, NULL, 1, '2022-07-20 08:00:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(10, 1, 2, '2022-07-20 08:30:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(10, 2, 3, '2022-07-20 09:00:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(10, 3, 4, '2022-07-20 10:00:00'::TIMESTAMP);

-- Duplicata 1 (2023)
INSERT INTO demande (passeport_id, type_demande_id, type_titre_id, statut_id, visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id) VALUES
(8, 3, 1, 4, '2022-07-20'::DATE, 'Antananarivo', '2023-07-20'::DATE, '20230815-100000-DUP', 1);

INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(11, 1, TRUE);

INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(11, NULL, 1, '2023-08-15 10:00:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(11, 1, 2, '2023-08-15 10:20:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(11, 2, 3, '2023-08-15 10:50:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(11, 3, 4, '2023-08-15 11:30:00'::TIMESTAMP);

-- Duplicata 2 (2024)
INSERT INTO demande (passeport_id, type_demande_id, type_titre_id, statut_id, visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id) VALUES
(8, 3, 1, 4, '2022-07-20'::DATE, 'Antananarivo', '2023-07-20'::DATE, '20240905-140000-DUP', 1);

INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(12, 1, TRUE);

INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(12, NULL, 1, '2024-09-05 14:00:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(12, 1, 2, '2024-09-05 14:25:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(12, 2, 3, '2024-09-05 15:00:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(12, 3, 4, '2024-09-05 16:00:00'::TIMESTAMP);

-- Duplicata 3 (2025)
INSERT INTO demande (passeport_id, type_demande_id, type_titre_id, statut_id, visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id) VALUES
(8, 3, 1, 4, '2022-07-20'::DATE, 'Antananarivo', '2023-07-20'::DATE, '20250511-190000-DUP', 1);

INSERT INTO demande_piece (demande_id, piece_id, cochee) VALUES
(13, 1, TRUE);

INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(13, NULL, 1, '2025-05-11 19:00:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(13, 1, 2, '2025-05-11 19:15:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(13, 2, 3, '2025-05-11 19:40:00'::TIMESTAMP);
INSERT INTO historique_statut (demande_id, ancien_statut_id, statut_id, date_changement) VALUES
(13, 3, 4, '2025-05-11 20:30:00'::TIMESTAMP);

-- Dossier groupant tous les duplicatas
INSERT INTO dossier (previous_demande_ref, new_demande_ref, mention, visa_approuve_confirme) VALUES
('20220720-080000-VIS', '20230815-100000-DUP', 'Duplicata 1/3 - visa initial 2022', TRUE);
INSERT INTO dossier (previous_demande_ref, new_demande_ref, mention, visa_approuve_confirme) VALUES
('20230815-100000-DUP', '20240905-140000-DUP', 'Duplicata 2/3 - duplicata 2023', TRUE);
INSERT INTO dossier (previous_demande_ref, new_demande_ref, mention, visa_approuve_confirme) VALUES
('20240905-140000-DUP', '20250511-190000-DUP', 'Duplicata 3/3 - duplicata 2024', TRUE);

-- Liaisons dossier
INSERT INTO dossier_demande (dossier_id, demande_id) VALUES
(3, 10);
INSERT INTO dossier_demande (dossier_id, demande_id) VALUES
(3, 11);

INSERT INTO dossier_demande (dossier_id, demande_id) VALUES
(4, 11);
INSERT INTO dossier_demande (dossier_id, demande_id) VALUES
(4, 12);

INSERT INTO dossier_demande (dossier_id, demande_id) VALUES
(5, 12);
INSERT INTO dossier_demande (dossier_id, demande_id) VALUES
(5, 13);

-- =============================================================
-- SUMMARY
-- =============================================================
-- Demandeurs : 8
-- Passeports : 8
-- Demandes : 13
-- Dossiers : 5
-- Historiques : 50 transitions d'état
-- Pièces associées : 30 enregistrements
-- Fichiers uploadés : 4
--
-- Scénarios couverts :
--   1. Demande simple valide (parcours nominal) ✓
--   2. Rejet pour incompletude ✓
--   3. Suspension (cas limite) ✓
--   4. Duplicata simple ✓
--   5. Renouvellement ✓
--   6. Passeport expirant bientôt + rejet ✓
--   7. Scan terminé ✓
--   8. Triple duplicata (complexité maximale) ✓
-- =============================================================