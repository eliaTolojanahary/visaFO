-- =============================================================
-- DONNEES DE TEST - VISA / RESIDENCE PERMIT SYSTEM
-- =============================================================
-- Insertion idempotente avec verifications
-- Scénarios : demandes simples, cas limites, duplicatas, transitions d'état
-- =============================================================

-- =============================================================
-- 1. DONNEES DE REFERENCE (Énumérés)
-- =============================================================

-- Situation familiale
INSERT INTO situation_famille (id, libelle) VALUES (1, 'Célibataire') ON CONFLICT (id) DO NOTHING;
INSERT INTO situation_famille (id, libelle) VALUES (2, 'Marié(e)') ON CONFLICT (id) DO NOTHING;
INSERT INTO situation_famille (id, libelle) VALUES (3, 'Divorcé(e)') ON CONFLICT (id) DO NOTHING;
INSERT INTO situation_famille (id, libelle) VALUES (4, 'Veuf(ve)') ON CONFLICT (id) DO NOTHING;
INSERT INTO situation_famille (id, libelle) VALUES (5, 'Pacsé(e)') ON CONFLICT (id) DO NOTHING;

-- Nationalité
INSERT INTO nationalite (id, libelle) VALUES (1, 'France') ON CONFLICT (id) DO NOTHING;
INSERT INTO nationalite (id, libelle) VALUES (2, 'Madagascar') ON CONFLICT (id) DO NOTHING;
INSERT INTO nationalite (id, libelle) VALUES (3, 'Belgique') ON CONFLICT (id) DO NOTHING;
INSERT INTO nationalite (id, libelle) VALUES (4, 'Suisse') ON CONFLICT (id) DO NOTHING;
INSERT INTO nationalite (id, libelle) VALUES (5, 'Canada') ON CONFLICT (id) DO NOTHING;
INSERT INTO nationalite (id, libelle) VALUES (6, 'États-Unis') ON CONFLICT (id) DO NOTHING;

-- Type de demande
INSERT INTO type_demande (id, libelle) VALUES (1, 'Visa Initial') ON CONFLICT (id) DO NOTHING;
INSERT INTO type_demande (id, libelle) VALUES (2, 'Renouvellement') ON CONFLICT (id) DO NOTHING;
INSERT INTO type_demande (id, libelle) VALUES (3, 'Duplicata') ON CONFLICT (id) DO NOTHING;
INSERT INTO type_demande (id, libelle) VALUES (4, 'Titre de Résidence') ON CONFLICT (id) DO NOTHING;
INSERT INTO type_demande (id, libelle) VALUES (5, 'Prolongation') ON CONFLICT (id) DO NOTHING;

-- Type de titre (document délivré)
INSERT INTO type_titre (id, libelle) VALUES (1, 'Visa Court Séjour') ON CONFLICT (id) DO NOTHING;
INSERT INTO type_titre (id, libelle) VALUES (2, 'Visa Long Séjour') ON CONFLICT (id) DO NOTHING;
INSERT INTO type_titre (id, libelle) VALUES (3, 'Titre de Résidence') ON CONFLICT (id) DO NOTHING;
INSERT INTO type_titre (id, libelle) VALUES (4, 'Autorisation de Séjour') ON CONFLICT (id) DO NOTHING;

-- Statut de demande
INSERT INTO statut_demande (id, libelle) VALUES (1, 'BROUILLON') ON CONFLICT (id) DO NOTHING;
INSERT INTO statut_demande (id, libelle) VALUES (2, 'EN ATTENTE') ON CONFLICT (id) DO NOTHING;
INSERT INTO statut_demande (id, libelle) VALUES (3, 'EN EXAMEN') ON CONFLICT (id) DO NOTHING;
INSERT INTO statut_demande (id, libelle) VALUES (4, 'APPROUVE') ON CONFLICT (id) DO NOTHING;
INSERT INTO statut_demande (id, libelle) VALUES (5, 'REJETE') ON CONFLICT (id) DO NOTHING;
INSERT INTO statut_demande (id, libelle) VALUES (6, 'REJET_INCOMPLETUDE') ON CONFLICT (id) DO NOTHING;
INSERT INTO statut_demande (id, libelle) VALUES (7, 'SCAN_TERMINE') ON CONFLICT (id) DO NOTHING;
INSERT INTO statut_demande (id, libelle) VALUES (8, 'SUSPENDU') ON CONFLICT (id) DO NOTHING;

-- Type de document (document physique à remettre)
INSERT INTO type_document (id, libelle) VALUES (1, 'Visa') ON CONFLICT (id) DO NOTHING;
INSERT INTO type_document (id, libelle) VALUES (2, 'Titre de Résidence') ON CONFLICT (id) DO NOTHING;
INSERT INTO type_document (id, libelle) VALUES (3, 'Cachet d''Entrée') ON CONFLICT (id) DO NOTHING;

-- Pièces justificatives de référence
INSERT INTO piece_justificative_ref (id, libelle, id_type_titre) VALUES 
  (1, 'Passeport valide', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO piece_justificative_ref (id, libelle, id_type_titre) VALUES 
  (2, 'Copie d''identité', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO piece_justificative_ref (id, libelle, id_type_titre) VALUES 
  (3, 'Justificatif de domicile', 1) ON CONFLICT (id) DO NOTHING;
INSERT INTO piece_justificative_ref (id, libelle, id_type_titre) VALUES 
  (4, 'Attestation d''emploi', 2) ON CONFLICT (id) DO NOTHING;
INSERT INTO piece_justificative_ref (id, libelle, id_type_titre) VALUES 
  (5, 'Certificat de scolarité', 2) ON CONFLICT (id) DO NOTHING;
INSERT INTO piece_justificative_ref (id, libelle, id_type_titre) VALUES 
  (6, 'Bulletin de salaire', 2) ON CONFLICT (id) DO NOTHING;
INSERT INTO piece_justificative_ref (id, libelle, id_type_titre) VALUES 
  (7, 'Preuve de solvabilité', 3) ON CONFLICT (id) DO NOTHING;
INSERT INTO piece_justificative_ref (id, libelle, id_type_titre) VALUES 
  (8, 'Acte de mariage', 3) ON CONFLICT (id) DO NOTHING;

-- =============================================================
-- 2. SCENARIO 1 : DEMANDE SIMPLE VALIDE (parcours nominal)
-- Demandeur : Sophie Martin (France)
-- Flux : BROUILLON → EN ATTENTE → EN EXAMEN → APPROUVE
-- =============================================================

INSERT INTO demandeur (id, nom, prenom, nom_jeune_fille, date_naissance, 
                       situation_famille_id, nationalite_id, adresse_madagascar, 
                       numero_telephone, email, profession)
VALUES (1, 'Martin', 'Sophie', NULL, '1985-03-15'::DATE, 1, 1, 
        '12 Rue du Commerce, Antananarivo', '+33612345678', 'sophie.martin@email.com', 'Ingénieur')
ON CONFLICT (id) DO NOTHING;

INSERT INTO passeport (id, demandeur_id, numero_passeport, date_delivrance, date_expiration, pays_delivrance)
VALUES (1, 1, 'FR123456789', '2020-06-10'::DATE, '2030-06-10'::DATE, 'France')
ON CONFLICT (id) DO NOTHING;

INSERT INTO demande (id, passeport_id, type_demande_id, type_titre_id, statut_id, 
                     visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id)
VALUES (1, 1, 1, 1, 1, '2025-05-20'::DATE, 'Antananarivo', '2025-11-20'::DATE, 
        '20250511-140000-VIS', 1)
ON CONFLICT (id) DO NOTHING;

-- Pièces associées à la demande 1
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (1, 1, 1, TRUE) ON CONFLICT (id) DO NOTHING;
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (2, 1, 2, TRUE) ON CONFLICT (id) DO NOTHING;
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (3, 1, 3, TRUE) ON CONFLICT (id) DO NOTHING;

-- Historique des statuts : transitions de la demande 1
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (1, 1, NULL, 1, '2025-05-11 14:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (2, 1, 1, 2, '2025-05-11 14:15:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (3, 1, 2, 3, '2025-05-11 15:30:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (4, 1, 3, 4, '2025-05-11 16:45:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;

-- Fichiers uploadés pour la demande 1
INSERT INTO piece_fournie (id, demande_id, piece_ref_id, chemin_fichier, nom_fichier, taille_bytes, mime_type, uploaded_at)
VALUES (1, 1, 1, '/uploads/2025/05/sophie_martin_passeport.pdf', 'passeport.pdf', 2048000, 'application/pdf', '2025-05-11 14:05:00'::TIMESTAMP)
ON CONFLICT (id) DO NOTHING;
INSERT INTO piece_fournie (id, demande_id, piece_ref_id, chemin_fichier, nom_fichier, taille_bytes, mime_type, uploaded_at)
VALUES (2, 1, 3, '/uploads/2025/05/sophie_martin_justif_domicile.pdf', 'justif_domicile.pdf', 1024000, 'application/pdf', '2025-05-11 14:10:00'::TIMESTAMP)
ON CONFLICT (id) DO NOTHING;

-- =============================================================
-- 3. SCENARIO 2 : DEMANDE AVEC REJET (incompletude)
-- Demandeur : Jean Dupont (France)
-- Flux : BROUILLON → EN ATTENTE → EN EXAMEN → REJET_INCOMPLETUDE
-- =============================================================

INSERT INTO demandeur (id, nom, prenom, nom_jeune_fille, date_naissance, 
                       situation_famille_id, nationalite_id, adresse_madagascar, 
                       numero_telephone, email, profession)
VALUES (2, 'Dupont', 'Jean', NULL, '1978-07-22'::DATE, 2, 1, 
        '45 Avenue de la Paix, Antananarivo', '+33698765432', 'jean.dupont@email.com', 'Comptable')
ON CONFLICT (id) DO NOTHING;

INSERT INTO passeport (id, demandeur_id, numero_passeport, date_delivrance, date_expiration, pays_delivrance)
VALUES (2, 2, 'FR987654321', '2019-01-15'::DATE, '2029-01-15'::DATE, 'France')
ON CONFLICT (id) DO NOTHING;

INSERT INTO demande (id, passeport_id, type_demande_id, type_titre_id, statut_id, 
                     visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id)
VALUES (2, 2, 1, 1, 6, '2025-06-01'::DATE, 'Antananarivo', '2025-12-01'::DATE, 
        '20250510-105000-VIS', 1)
ON CONFLICT (id) DO NOTHING;

-- Pièces incomplètes : manque justificatif de domicile
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (4, 2, 1, TRUE) ON CONFLICT (id) DO NOTHING;
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (5, 2, 2, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (6, 2, 3, FALSE) ON CONFLICT (id) DO NOTHING;

-- Historique : BROUILLON → EN ATTENTE → EN EXAMEN → REJET_INCOMPLETUDE
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (5, 2, NULL, 1, '2025-05-10 10:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (6, 2, 1, 2, '2025-05-10 10:30:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (7, 2, 2, 3, '2025-05-10 11:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (8, 2, 3, 6, '2025-05-10 14:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;

-- =============================================================
-- 4. SCENARIO 3 : DEMANDE SUSPENDUE (cas limite)
-- Demandeur : Marie Durand (Belgique)
-- Flux : BROUILLON → EN ATTENTE → SUSPENDU (enquête supplémentaire)
-- =============================================================

INSERT INTO demandeur (id, nom, prenom, nom_jeune_fille, date_naissance, 
                       situation_famille_id, nationalite_id, adresse_madagascar, 
                       numero_telephone, email, profession)
VALUES (3, 'Durand', 'Marie', 'Renard', '1992-11-08'::DATE, 2, 3, 
        '78 Boulevard Central, Antananarivo', '+32487654321', 'marie.durand@email.com', 'Avocate')
ON CONFLICT (id) DO NOTHING;

INSERT INTO passeport (id, demandeur_id, numero_passeport, date_delivrance, date_expiration, pays_delivrance)
VALUES (3, 3, 'BE456789012', '2021-03-20'::DATE, '2031-03-20'::DATE, 'Belgique')
ON CONFLICT (id) DO NOTHING;

INSERT INTO demande (id, passeport_id, type_demande_id, type_titre_id, statut_id, 
                     visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id)
VALUES (3, 3, 1, 2, 8, '2025-07-15'::DATE, 'Antananarivo', '2026-07-15'::DATE, 
        '20250509-130000-VIS', 1)
ON CONFLICT (id) DO NOTHING;

-- Pièces complètes
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (7, 3, 1, TRUE) ON CONFLICT (id) DO NOTHING;
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (8, 3, 2, TRUE) ON CONFLICT (id) DO NOTHING;
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (9, 3, 3, TRUE) ON CONFLICT (id) DO NOTHING;
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (10, 3, 4, TRUE) ON CONFLICT (id) DO NOTHING;

-- Historique : BROUILLON → EN ATTENTE → SUSPENDU
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (9, 3, NULL, 1, '2025-05-09 13:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (10, 3, 1, 2, '2025-05-09 13:20:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (11, 3, 2, 8, '2025-05-09 15:45:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;

-- =============================================================
-- 5. SCENARIO 4 : DUPLICATA (demande complexe)
-- Demandeur : Pierre Bernard (France) - demande antécédente perdue
-- Dossier initial (demande 4) puis duplicata (demande 5)
-- Flux demande 4 : BROUILLON → EN ATTENTE → EN EXAMEN → APPROUVE
-- Flux demande 5 : BROUILLON → EN ATTENTE → EN EXAMEN → APPROUVE (duplicata)
-- =============================================================

INSERT INTO demandeur (id, nom, prenom, nom_jeune_fille, date_naissance, 
                       situation_famille_id, nationalite_id, adresse_madagascar, 
                       numero_telephone, email, profession)
VALUES (4, 'Bernard', 'Pierre', NULL, '1988-09-14'::DATE, 1, 1, 
        '23 Rue de la Liberté, Antananarivo', '+33645789123', 'pierre.bernard@email.com', 'Consultant')
ON CONFLICT (id) DO NOTHING;

INSERT INTO passeport (id, demandeur_id, numero_passeport, date_delivrance, date_expiration, pays_delivrance)
VALUES (4, 4, 'FR111222333', '2018-05-10'::DATE, '2028-05-10'::DATE, 'France')
ON CONFLICT (id) DO NOTHING;

-- Demande initiale (2024)
INSERT INTO demande (id, passeport_id, type_demande_id, type_titre_id, statut_id, 
                     visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id)
VALUES (4, 4, 1, 1, 4, '2024-06-20'::DATE, 'Antananarivo', '2024-12-20'::DATE, 
        '20240620-102000-VIS', 1)
ON CONFLICT (id) DO NOTHING;

-- Pièces pour demande 4
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (11, 4, 1, TRUE) ON CONFLICT (id) DO NOTHING;
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (12, 4, 2, TRUE) ON CONFLICT (id) DO NOTHING;
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (13, 4, 3, TRUE) ON CONFLICT (id) DO NOTHING;

-- Historique demande 4 (ancienne demande approuvée)
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (12, 4, NULL, 1, '2024-06-20 10:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (13, 4, 1, 2, '2024-06-20 10:30:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (14, 4, 2, 3, '2024-06-20 11:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (15, 4, 3, 4, '2024-06-20 12:30:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;

-- Dossier pour la demande initiale + duplicata
INSERT INTO dossier (id, previous_demande_ref, new_demande_ref, mention, visa_approuve_confirme)
VALUES (1, '20240620-102000-VIS', '20250511-145000-DUP', 'Duplicata - visa initial 2024 approuvé, document perdu', TRUE)
ON CONFLICT (id) DO NOTHING;

-- Demande de duplicata (2025) - nouvelle demande pour le même passeport
INSERT INTO demande (id, passeport_id, type_demande_id, type_titre_id, statut_id, 
                     visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id)
VALUES (5, 4, 3, 1, 4, '2024-06-20'::DATE, 'Antananarivo', '2024-12-20'::DATE, 
        '20250511-145000-DUP', 1)
ON CONFLICT (id) DO NOTHING;

-- Pièces pour demande 5 (duplicata)
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (14, 5, 1, TRUE) ON CONFLICT (id) DO NOTHING;
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (15, 5, 2, TRUE) ON CONFLICT (id) DO NOTHING;

-- Historique demande 5 (duplicata - transition rapide)
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (16, 5, NULL, 1, '2025-05-11 14:30:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (17, 5, 1, 2, '2025-05-11 14:45:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (18, 5, 2, 3, '2025-05-11 15:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (19, 5, 3, 4, '2025-05-11 15:20:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;

-- Liaison dossier <-> demandes
INSERT INTO dossier_demande (id, dossier_id, demande_id)
VALUES (1, 1, 4) ON CONFLICT (id) DO NOTHING;
INSERT INTO dossier_demande (id, dossier_id, demande_id)
VALUES (2, 1, 5) ON CONFLICT (id) DO NOTHING;

-- =============================================================
-- 6. SCENARIO 5 : RENOUVELLEMENT (cas limite avec anciennes données)
-- Demandeur : Alice Lambert (Suisse)
-- Demande antécédente approuvée (2023), renouvellement (2025)
-- Flux : BROUILLON → EN ATTENTE → EN EXAMEN → APPROUVE
-- =============================================================

INSERT INTO demandeur (id, nom, prenom, nom_jeune_fille, date_naissance, 
                       situation_famille_id, nationalite_id, adresse_madagascar, 
                       numero_telephone, email, profession)
VALUES (5, 'Lambert', 'Alice', NULL, '1990-02-27'::DATE, 2, 4, 
        '34 Chemin de la Montagne, Antananarivo', '+41789456123', 'alice.lambert@email.com', 'Pharmacienne')
ON CONFLICT (id) DO NOTHING;

INSERT INTO passeport (id, demandeur_id, numero_passeport, date_delivrance, date_expiration, pays_delivrance)
VALUES (5, 5, 'CH999888777', '2020-07-15'::DATE, '2030-07-15'::DATE, 'Suisse')
ON CONFLICT (id) DO NOTHING;

-- Ancienne demande (2023) - approuvée
INSERT INTO demande (id, passeport_id, type_demande_id, type_titre_id, statut_id, 
                     visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id)
VALUES (6, 5, 1, 2, 4, '2023-08-10'::DATE, 'Antananarivo', '2024-08-10'::DATE, 
        '20230810-090000-VIS', 1)
ON CONFLICT (id) DO NOTHING;

-- Pièces ancienne demande
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (16, 6, 1, TRUE) ON CONFLICT (id) DO NOTHING;
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (17, 6, 4, TRUE) ON CONFLICT (id) DO NOTHING;

-- Historique ancienne demande
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (20, 6, NULL, 1, '2023-08-10 09:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (21, 6, 1, 2, '2023-08-10 09:30:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (22, 6, 2, 3, '2023-08-10 10:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (23, 6, 3, 4, '2023-08-10 11:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;

-- Dossier pour renouvellement
INSERT INTO dossier (id, previous_demande_ref, new_demande_ref, mention, visa_approuve_confirme)
VALUES (2, '20230810-090000-VIS', '20250512-110000-REN', 'Renouvellement - visa long séjour 2023', TRUE)
ON CONFLICT (id) DO NOTHING;

-- Nouvelle demande de renouvellement (2025)
INSERT INTO demande (id, passeport_id, type_demande_id, type_titre_id, statut_id, 
                     visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id)
VALUES (7, 5, 2, 2, 4, '2025-08-10'::DATE, 'Antananarivo', '2026-08-10'::DATE, 
        '20250512-110000-REN', 1)
ON CONFLICT (id) DO NOTHING;

-- Pièces renouvellement
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (18, 7, 1, TRUE) ON CONFLICT (id) DO NOTHING;
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (19, 7, 4, TRUE) ON CONFLICT (id) DO NOTHING;
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (20, 7, 6, TRUE) ON CONFLICT (id) DO NOTHING;

-- Historique renouvellement
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (24, 7, NULL, 1, '2025-05-12 11:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (25, 7, 1, 2, '2025-05-12 11:15:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (26, 7, 2, 3, '2025-05-12 11:45:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (27, 7, 3, 4, '2025-05-12 13:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;

-- Liaison dossier renouvellement
INSERT INTO dossier_demande (id, dossier_id, demande_id)
VALUES (3, 2, 6) ON CONFLICT (id) DO NOTHING;
INSERT INTO dossier_demande (id, dossier_id, demande_id)
VALUES (4, 2, 7) ON CONFLICT (id) DO NOTHING;

-- =============================================================
-- 7. SCENARIO 6 : CAS LIMITE - PASSEPORT EXPIRANT BIENTÔT
-- Demandeur : Thomas Lefevre (Canada)
-- Passeport expire dans 6 mois
-- Flux : BROUILLON → EN ATTENTE → REJETE (passeport invalide)
-- =============================================================

INSERT INTO demandeur (id, nom, prenom, nom_jeune_fille, date_naissance, 
                       situation_famille_id, nationalite_id, adresse_madagascar, 
                       numero_telephone, email, profession)
VALUES (6, 'Lefevre', 'Thomas', NULL, '1995-12-03'::DATE, 1, 5, 
        '56 Impasse de la Paix, Antananarivo', '+14165551234', 'thomas.lefevre@email.com', 'Développeur')
ON CONFLICT (id) DO NOTHING;

INSERT INTO passeport (id, demandeur_id, numero_passeport, date_delivrance, date_expiration, pays_delivrance)
VALUES (6, 6, 'CA555666777', '2022-11-01'::DATE, '2025-11-01'::DATE, 'Canada')
ON CONFLICT (id) DO NOTHING;

INSERT INTO demande (id, passeport_id, type_demande_id, type_titre_id, statut_id, 
                     visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id)
VALUES (8, 6, 1, 1, 5, '2025-06-01'::DATE, 'Antananarivo', '2025-12-01'::DATE, 
        '20250511-165000-VIS', 1)
ON CONFLICT (id) DO NOTHING;

-- Pièces incomplètes/invalides
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (21, 8, 1, TRUE) ON CONFLICT (id) DO NOTHING;
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (22, 8, 2, FALSE) ON CONFLICT (id) DO NOTHING;

-- Historique : BROUILLON → EN ATTENTE → REJETE
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (28, 8, NULL, 1, '2025-05-11 16:30:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (29, 8, 1, 2, '2025-05-11 16:50:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (30, 8, 2, 5, '2025-05-11 17:30:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;

-- =============================================================
-- 8. SCENARIO 7 : DEMANDE AVEC SCAN TERMINE
-- Demandeur : Nathalie Leroy (États-Unis)
-- Flux : BROUILLON → EN ATTENTE → EN EXAMEN → SCAN_TERMINE
-- =============================================================

INSERT INTO demandeur (id, nom, prenom, nom_jeune_fille, date_naissance, 
                       situation_famille_id, nationalite_id, adresse_madagascar, 
                       numero_telephone, email, profession)
VALUES (7, 'Leroy', 'Nathalie', NULL, '1987-04-19'::DATE, 1, 6, 
        '89 rue de l''Océan, Antananarivo', '+12125551234', 'nathalie.leroy@email.com', 'Architecte')
ON CONFLICT (id) DO NOTHING;

INSERT INTO passeport (id, demandeur_id, numero_passeport, date_delivrance, date_expiration, pays_delivrance)
VALUES (7, 7, 'US777888999', '2021-09-12'::DATE, '2031-09-12'::DATE, 'États-Unis')
ON CONFLICT (id) DO NOTHING;

INSERT INTO demande (id, passeport_id, type_demande_id, type_titre_id, statut_id, 
                     visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id)
VALUES (9, 7, 1, 1, 7, '2025-09-15'::DATE, 'Antananarivo', '2026-09-15'::DATE, 
        '20250511-175000-VIS', 1)
ON CONFLICT (id) DO NOTHING;

-- Pièces complètes
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (23, 9, 1, TRUE) ON CONFLICT (id) DO NOTHING;
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (24, 9, 2, TRUE) ON CONFLICT (id) DO NOTHING;
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (25, 9, 3, TRUE) ON CONFLICT (id) DO NOTHING;
INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (26, 9, 5, TRUE) ON CONFLICT (id) DO NOTHING;

-- Fichiers uploadés complets
INSERT INTO piece_fournie (id, demande_id, piece_ref_id, chemin_fichier, nom_fichier, taille_bytes, mime_type, uploaded_at)
VALUES (3, 9, 1, '/uploads/2025/05/nathalie_leroy_passeport.pdf', 'passeport.pdf', 2500000, 'application/pdf', '2025-05-11 17:10:00'::TIMESTAMP)
ON CONFLICT (id) DO NOTHING;
INSERT INTO piece_fournie (id, demande_id, piece_ref_id, chemin_fichier, nom_fichier, taille_bytes, mime_type, uploaded_at)
VALUES (4, 9, 5, '/uploads/2025/05/nathalie_leroy_scolarite.pdf', 'certificat_scolarite.pdf', 1500000, 'application/pdf', '2025-05-11 17:15:00'::TIMESTAMP)
ON CONFLICT (id) DO NOTHING;

-- Historique : BROUILLON → EN ATTENTE → EN EXAMEN → SCAN_TERMINE
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (31, 9, NULL, 1, '2025-05-11 17:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (32, 9, 1, 2, '2025-05-11 17:15:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (33, 9, 2, 3, '2025-05-11 17:45:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (34, 9, 3, 7, '2025-05-11 18:30:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;

-- =============================================================
-- 9. SCENARIO 8 : TRIPLE DUPLICATA (cas très complexe)
-- Demandeur : Luc Moreau (France)
-- Demande initiale (2022) approuvée → Duplicata 1 (2023) approuvé → Duplicata 2 (2024) approuvé → Duplicata 3 (2025)
-- Dossier avec 4 demandes chaînées
-- =============================================================

INSERT INTO demandeur (id, nom, prenom, nom_jeune_fille, date_naissance, 
                       situation_famille_id, nationalite_id, adresse_madagascar, 
                       numero_telephone, email, profession)
VALUES (8, 'Moreau', 'Luc', NULL, '1980-06-25'::DATE, 2, 1, 
        '101 Place de la Concorde, Antananarivo', '+33756789012', 'luc.moreau@email.com', 'Directeur')
ON CONFLICT (id) DO NOTHING;

INSERT INTO passeport (id, demandeur_id, numero_passeport, date_delivrance, date_expiration, pays_delivrance)
VALUES (8, 8, 'FR333444555', '2017-02-14'::DATE, '2027-02-14'::DATE, 'France')
ON CONFLICT (id) DO NOTHING;

-- Demande initiale 2022
INSERT INTO demande (id, passeport_id, type_demande_id, type_titre_id, statut_id, 
                     visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id)
VALUES (10, 8, 1, 1, 4, '2022-07-20'::DATE, 'Antananarivo', '2023-07-20'::DATE, 
        '20220720-080000-VIS', 1)
ON CONFLICT (id) DO NOTHING;

INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (27, 10, 1, TRUE) ON CONFLICT (id) DO NOTHING;

INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (35, 10, NULL, 1, '2022-07-20 08:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (36, 10, 1, 2, '2022-07-20 08:30:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (37, 10, 2, 3, '2022-07-20 09:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (38, 10, 3, 4, '2022-07-20 10:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;

-- Duplicata 1 (2023)
INSERT INTO demande (id, passeport_id, type_demande_id, type_titre_id, statut_id, 
                     visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id)
VALUES (11, 8, 3, 1, 4, '2022-07-20'::DATE, 'Antananarivo', '2023-07-20'::DATE, 
        '20230815-100000-DUP', 1)
ON CONFLICT (id) DO NOTHING;

INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (28, 11, 1, TRUE) ON CONFLICT (id) DO NOTHING;

INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (39, 11, NULL, 1, '2023-08-15 10:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (40, 11, 1, 2, '2023-08-15 10:20:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (41, 11, 2, 3, '2023-08-15 10:50:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (42, 11, 3, 4, '2023-08-15 11:30:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;

-- Duplicata 2 (2024)
INSERT INTO demande (id, passeport_id, type_demande_id, type_titre_id, statut_id, 
                     visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id)
VALUES (12, 8, 3, 1, 4, '2022-07-20'::DATE, 'Antananarivo', '2023-07-20'::DATE, 
        '20240905-140000-DUP', 1)
ON CONFLICT (id) DO NOTHING;

INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (29, 12, 1, TRUE) ON CONFLICT (id) DO NOTHING;

INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (43, 12, NULL, 1, '2024-09-05 14:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (44, 12, 1, 2, '2024-09-05 14:25:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (45, 12, 2, 3, '2024-09-05 15:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (46, 12, 3, 4, '2024-09-05 16:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;

-- Duplicata 3 (2025)
INSERT INTO demande (id, passeport_id, type_demande_id, type_titre_id, statut_id, 
                     visa_date_entree, visa_lieu_entree, visa_date_expiration, ref_demande, type_document_id)
VALUES (13, 8, 3, 1, 4, '2022-07-20'::DATE, 'Antananarivo', '2023-07-20'::DATE, 
        '20250511-190000-DUP', 1)
ON CONFLICT (id) DO NOTHING;

INSERT INTO demande_piece (id, demande_id, piece_id, cochee)
VALUES (30, 13, 1, TRUE) ON CONFLICT (id) DO NOTHING;

INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (47, 13, NULL, 1, '2025-05-11 19:00:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (48, 13, 1, 2, '2025-05-11 19:15:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (49, 13, 2, 3, '2025-05-11 19:40:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;
INSERT INTO historique_statut (id, demande_id, ancien_statut_id, statut_id, date_changement)
VALUES (50, 13, 3, 4, '2025-05-11 20:30:00'::TIMESTAMP) ON CONFLICT (id) DO NOTHING;

-- Dossier groupant tous les duplicatas
INSERT INTO dossier (id, previous_demande_ref, new_demande_ref, mention, visa_approuve_confirme)
VALUES (3, '20220720-080000-VIS', '20230815-100000-DUP', 'Duplicata 1/3 - visa initial 2022', TRUE)
ON CONFLICT (id) DO NOTHING;
INSERT INTO dossier (id, previous_demande_ref, new_demande_ref, mention, visa_approuve_confirme)
VALUES (4, '20230815-100000-DUP', '20240905-140000-DUP', 'Duplicata 2/3 - duplicata 2023', TRUE)
ON CONFLICT (id) DO NOTHING;
INSERT INTO dossier (id, previous_demande_ref, new_demande_ref, mention, visa_approuve_confirme)
VALUES (5, '20240905-140000-DUP', '20250511-190000-DUP', 'Duplicata 3/3 - duplicata 2024', TRUE)
ON CONFLICT (id) DO NOTHING;

-- Liaisons dossier
INSERT INTO dossier_demande (id, dossier_id, demande_id)
VALUES (5, 3, 10) ON CONFLICT (id) DO NOTHING;
INSERT INTO dossier_demande (id, dossier_id, demande_id)
VALUES (6, 3, 11) ON CONFLICT (id) DO NOTHING;

INSERT INTO dossier_demande (id, dossier_id, demande_id)
VALUES (7, 4, 11) ON CONFLICT (id) DO NOTHING;
INSERT INTO dossier_demande (id, dossier_id, demande_id)
VALUES (8, 4, 12) ON CONFLICT (id) DO NOTHING;

INSERT INTO dossier_demande (id, dossier_id, demande_id)
VALUES (9, 5, 12) ON CONFLICT (id) DO NOTHING;
INSERT INTO dossier_demande (id, dossier_id, demande_id)
VALUES (10, 5, 13) ON CONFLICT (id) DO NOTHING;

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