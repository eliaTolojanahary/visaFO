-- =============================================================
-- INSERT DEMANDES VISA
-- Prerequis : table.sql + alter_sprint2.sql + alter_sprint3.sql
--             + donnees_mini_test.sql deja executes
--
-- Contenu :
--   1. Referentiels complementaires (type_document)
--   2. Demandeurs (5 profils)
--   3. Passeports
--   4. Demandes
--   5. Dossiers et liaisons dossier_demande
--   6. Pieces jointes (demande_piece)
-- =============================================================


-- =============================================================
-- 1. REFERENTIELS COMPLEMENTAIRES
-- =============================================================

-- type_document : documents cibles pour les duplicatas
INSERT INTO type_document (libelle)
SELECT libelle FROM (VALUES
    ('Titre de residence commun'),
    ('Titre de residence investisseur'),
    ('Titre de residence travailleur')
) AS t(libelle)
WHERE NOT EXISTS (
    SELECT 1 FROM type_document d WHERE d.libelle = t.libelle
);


-- =============================================================
-- 2. DEMANDEURS
-- =============================================================
-- IDs situation_famille attendus (donnees_mini_test.sql) :
--   1=Celibataire  2=MARIE  3=DIVORCE  4=VEUF
-- IDs nationalite :
--   1=Malagasy  2=Francaise  3=Indienne  4=Chinoise

INSERT INTO demandeur (
    nom, prenom, nom_jeune_fille,
    date_naissance, situation_famille_id, nationalite_id,
    adresse_madagascar, numero_telephone, email,
    profession
) VALUES
-- Demandeur 1 : investisseur francais marie
(
    'MARTIN', 'Jean-Paul', NULL,
    '1978-03-15', 2, 2,
    'Lot II J 45, Ankadifotsy, Antananarivo 101',
    '+261 34 12 345 67', 'jp.martin@example.fr',
    'Chef d''entreprise'
),
-- Demandeur 2 : travailleuse indienne celibataire
(
    'SHARMA', 'Priya', NULL,
    '1990-07-22', 1, 3,
    'Résidence Les Jacarandas, Apt 12, Ivandry, Antananarivo',
    '+261 33 98 765 43', 'p.sharma@example.in',
    'Ingenieure informatique'
),
-- Demandeur 3 : demandeur chinois marie, duplicata (dossier sans antecedent en base)
(
    'WANG', 'Lei', NULL,
    '1965-11-08', 2, 4,
    'Quartier Tsaralalana, Rue Solombavambahoaka, Antananarivo',
    '+261 32 55 111 22', 'wang.lei@example.cn',
    'Commercant'
),
-- Demandeur 4 : francaise divorcee, renouvellement
(
    'DUPONT', 'Marie', 'LECLERC',
    '1985-04-30', 3, 2,
    'Villa Orchidee, Route d''Ambohidratrimo, Antananarivo',
    '+261 34 77 888 99', 'm.dupont@example.fr',
    'Enseignante'
),
-- Demandeur 5 : travailleur indien veuf
(
    'PATEL', 'Ravi', NULL,
    '1972-09-18', 4, 3,
    'Cité Ampefiloha, Immeuble B, Appartement 5, Antananarivo',
    '+261 33 44 000 11', 'r.patel@example.in',
    'Medecin'
);


-- =============================================================
-- 3. PASSEPORTS
-- =============================================================
-- Utilise les demandeur_id dans l'ordre d'insertion (1..5)
-- On recupere les IDs via sous-requetes pour rester robuste
-- meme si la sequence a deja avance.

INSERT INTO passeport (
    demandeur_id,
    numero_passeport, date_delivrance, date_expiration, pays_delivrance
)
SELECT d.id, t.num, t.del::DATE, t.exp::DATE, t.pays
FROM (VALUES
    ('MARTIN',   'JP', '12FR456789', '2019-06-01', '2029-05-31', 'France'),
    ('SHARMA',   'PR', '34IN789012', '2021-01-15', '2031-01-14', 'Inde'),
    ('WANG',     'WL', '56CN012345', '2018-09-20', '2028-09-19', 'Chine'),
    ('DUPONT',   'MD', '78FR345678', '2020-03-10', '2030-03-09', 'France'),
    ('PATEL',    'RP', '90IN678901', '2022-05-05', '2032-05-04', 'Inde')
) AS t(nom, prenom_code, num, del, exp, pays)
JOIN demandeur d ON d.nom = t.nom;


-- =============================================================
-- 4. DEMANDES
-- =============================================================
-- IDs type_demande (donnees_mini_test.sql) :
--   1=Nouveau titre  2=Duplicata  3=Transfert visa
-- IDs type_titre :
--   1=Commun  2=Investisseur  3=Travailleur
-- IDs statut_demande :
--   1=demande creee  2=Scan termine
--   3=En cours de traitement  4=En attente  5=Valide  6=Refuse
--   (3..6 inseres par alter_sprint2.sql)
-- IDs type_document (inseres ci-dessus, ordre) :
--   1=Titre de residence commun
--   2=Titre de residence investisseur
--   3=Titre de residence travailleur

INSERT INTO demande (
    passeport_id,
    type_demande_id, type_titre_id, statut_id,
    visa_date_entree, visa_lieu_entree, visa_date_expiration,
    ref_demande, type_document_id, verrouille
)
SELECT
    p.id,
    t.type_dem, t.type_tit, t.statut,
    t.v_entree::DATE, t.v_lieu, t.v_exp::DATE,
    t.ref_dem, t.type_doc, t.verr
FROM (VALUES
    -- Martin : nouveau titre investisseur, en cours
    ('MARTIN',  1, 2, 3,
     '2024-02-01', 'Aéroport Ivato', '2024-08-01',
     '20240201-090000-NTI', NULL, FALSE),

    -- Sharma : nouveau titre travailleur, valide
    ('SHARMA',  1, 3, 5,
     '2023-11-15', 'Aéroport Ivato', '2024-05-15',
     '20231115-143000-NTT', NULL, FALSE),

    -- Wang : duplicata titre commun, antecedent absent en base
    --        => dossier sans previous_demande_ref retrouvee
    ('WANG',    2, 1, 4,
     '2022-06-10', 'Aéroport Ivato', '2023-06-09',
     '20240410-100000-DUP', 1, FALSE),

    -- Dupont : nouveau titre commun, scan termine
    ('DUPONT',  1, 1, 2,
     '2024-01-20', 'Port de Toamasina', '2024-07-20',
     '20240120-080000-NTC', NULL, FALSE),

    -- Patel : nouveau titre travailleur, refuse
    ('PATEL',   1, 3, 6,
     '2023-08-01', 'Aéroport Ivato', '2024-01-31',
     '20230801-110000-NTT', NULL, TRUE)

) AS t(nom, type_dem, type_tit, statut,
       v_entree, v_lieu, v_exp,
       ref_dem, type_doc, verr)
JOIN demandeur d ON d.nom = t.nom
JOIN passeport p ON p.demandeur_id = d.id;


-- =============================================================
-- 5. DOSSIERS ET LIAISONS dossier_demande
-- =============================================================

-- Dossier standard pour chaque demande normale (sans antecedent)
-- Wang est le seul cas avec mention "duplicata antecedent non retrouve"

-- Dossier Martin
WITH ins AS (
    INSERT INTO dossier (mention, visa_approuve_confirme)
    VALUES (NULL, FALSE)
    RETURNING id
)
INSERT INTO dossier_demande (dossier_id, demande_id)
SELECT ins.id, dem.id
FROM ins, demande dem
JOIN passeport p ON p.id = dem.passeport_id
JOIN demandeur d ON d.id = p.demandeur_id
WHERE d.nom = 'MARTIN';

-- Dossier Sharma
WITH ins AS (
    INSERT INTO dossier (mention, visa_approuve_confirme)
    VALUES (NULL, TRUE)
    RETURNING id
)
INSERT INTO dossier_demande (dossier_id, demande_id)
SELECT ins.id, dem.id
FROM ins, demande dem
JOIN passeport p ON p.id = dem.passeport_id
JOIN demandeur d ON d.id = p.demandeur_id
WHERE d.nom = 'SHARMA';

-- Dossier Wang : duplicata, antecedent non retrouve en base
-- previous_demande_ref fournie par le demandeur (recepisse papier)
-- new_demande_ref = ref de la demande courante
WITH ins AS (
    INSERT INTO dossier (
        previous_demande_ref,
        new_demande_ref,
        mention,
        visa_approuve_confirme
    )
    SELECT
        '20190610-000000-NTC',          -- ref papier fournie par Wang
        dem.ref_demande,                -- ref generee pour ce dossier
        'Duplicata - antecedent non retrouve en base',
        TRUE
    FROM demande dem
    JOIN passeport p ON p.id = dem.passeport_id
    JOIN demandeur d ON d.id = p.demandeur_id
    WHERE d.nom = 'WANG'
    RETURNING id
)
INSERT INTO dossier_demande (dossier_id, demande_id)
SELECT ins.id, dem.id
FROM ins, demande dem
JOIN passeport p ON p.id = dem.passeport_id
JOIN demandeur d ON d.id = p.demandeur_id
WHERE d.nom = 'WANG';

-- Dossier Dupont
WITH ins AS (
    INSERT INTO dossier (mention, visa_approuve_confirme)
    VALUES (NULL, FALSE)
    RETURNING id
)
INSERT INTO dossier_demande (dossier_id, demande_id)
SELECT ins.id, dem.id
FROM ins, demande dem
JOIN passeport p ON p.id = dem.passeport_id
JOIN demandeur d ON d.id = p.demandeur_id
WHERE d.nom = 'DUPONT';

-- Dossier Patel
WITH ins AS (
    INSERT INTO dossier (mention, visa_approuve_confirme)
    VALUES (NULL, FALSE)
    RETURNING id
)
INSERT INTO dossier_demande (dossier_id, demande_id)
SELECT ins.id, dem.id
FROM ins, demande dem
JOIN passeport p ON p.id = dem.passeport_id
JOIN demandeur d ON d.id = p.demandeur_id
WHERE d.nom = 'PATEL';


-- =============================================================
-- 6. PIECES JOINTES (demande_piece)
-- =============================================================
-- Coche les pieces communes (id_type_titre IS NULL) pour toutes
-- les demandes de type "Nouveau titre".
-- Les pieces specifiques (investisseur / travailleur) sont cochees
-- selon le type_titre de la demande.

-- Pieces communes : cochees pour Martin, Sharma, Dupont, Patel
INSERT INTO demande_piece (demande_id, piece_id, cochee)
SELECT dem.id, pjr.id, TRUE
FROM demande dem
JOIN passeport p  ON p.id = dem.passeport_id
JOIN demandeur d  ON d.id = p.demandeur_id
JOIN piece_justificative_ref pjr ON pjr.id_type_titre IS NULL
WHERE d.nom IN ('MARTIN', 'SHARMA', 'DUPONT', 'PATEL')
  AND dem.type_demande_id = 1   -- Nouveau titre
ON CONFLICT (demande_id, piece_id) DO NOTHING;

-- Pieces investisseur : cochees pour Martin
INSERT INTO demande_piece (demande_id, piece_id, cochee)
SELECT dem.id, pjr.id, TRUE
FROM demande dem
JOIN passeport p  ON p.id = dem.passeport_id
JOIN demandeur d  ON d.id = p.demandeur_id
JOIN piece_justificative_ref pjr ON pjr.id_type_titre = 2
WHERE d.nom = 'MARTIN'
ON CONFLICT (demande_id, piece_id) DO NOTHING;

-- Pieces travailleur : cochees pour Sharma et Patel
INSERT INTO demande_piece (demande_id, piece_id, cochee)
SELECT dem.id, pjr.id, TRUE
FROM demande dem
JOIN passeport p  ON p.id = dem.passeport_id
JOIN demandeur d  ON d.id = p.demandeur_id
JOIN piece_justificative_ref pjr ON pjr.id_type_titre = 3
WHERE d.nom IN ('SHARMA', 'PATEL')
ON CONFLICT (demande_id, piece_id) DO NOTHING;

-- Pieces Wang (duplicata) : uniquement les communes, non cochees
-- (les originaux sont justement manquants)
INSERT INTO demande_piece (demande_id, piece_id, cochee)
SELECT dem.id, pjr.id, FALSE
FROM demande dem
JOIN passeport p  ON p.id = dem.passeport_id
JOIN demandeur d  ON d.id = p.demandeur_id
JOIN piece_justificative_ref pjr ON pjr.id_type_titre IS NULL
WHERE d.nom = 'WANG'
ON CONFLICT (demande_id, piece_id) DO NOTHING;


-- =============================================================
-- VERIFICATION RAPIDE
-- =============================================================
SELECT
    d.nom, d.prenom,
    dem.ref_demande,
    td.libelle  AS type_demande,
    tt.libelle  AS type_titre,
    sd.libelle  AS statut,
    dos.mention AS mention_dossier
FROM demandeur d
JOIN passeport p       ON p.demandeur_id = d.id
JOIN demande dem       ON dem.passeport_id = p.id
JOIN type_demande td   ON td.id = dem.type_demande_id
LEFT JOIN type_titre tt ON tt.id = dem.type_titre_id
JOIN statut_demande sd ON sd.id = dem.statut_id
JOIN dossier_demande dd ON dd.demande_id = dem.id
JOIN dossier dos       ON dos.id = dd.dossier_id
ORDER BY d.nom;