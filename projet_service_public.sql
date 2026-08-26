-- ============================================================
-- SIMULATION DONNÉES SERVICE PUBLIC : ADEME
-- ============================================================
-- Auteur : Mor Talla DIENG — Data Analyst RH/Finance
--
-- INTRODUCTION
-- ------------
-- Ce projet est une SIMULATION à but pédagogique, construite pour
-- pratiquer SQL/PostgreSQL sur un cas proche du fonctionnement réel
-- d'un organisme public de type ADEME (Agence de la transition
-- écologique) : instruction et suivi financier de dossiers d'aides
-- publiques (subventions énergie, bâtiment, etc.).
--
-- ⚠️ TOUTES les données de ce projet sont FICTIVES et ont été
-- entièrement inventées pour l'exercice : noms d'organismes, agents
-- instructeurs, montants, dates, SIRET et emails ne correspondent à
-- aucune donnée réelle ni à aucun organisme ou individu existant.
-- "ADEME" est utilisé ici uniquement comme contexte inspirant un
-- schéma de base de données réaliste, pas comme source de données.
--
-- OBJECTIF DU PROJET
-- -------------------
-- Synthétiser, sur un cas concret à deux volets, l'ensemble des
-- notions SQL/PostgreSQL travaillées jusqu'ici :
--   Partie 1 : gestion des dossiers - hiérarchie récursive des
--              catégories d'aides, fonctions de fenêtrage,
--              sous-requêtes, JSONB/ARRAY, index, transactions, vues
--   Partie 2 : pilotage financier - budget, versements, indicateurs
--              d'engagement et de reste à verser
-- ============================================================


-- ============================================================
-- 1. CRÉATION DES TABLES
-- ============================================================

CREATE TABLE categories_aides (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    categorie_parent_id INT REFERENCES categories_aides(id)
                                       -- auto-référence : NULL = catégorie racine
);

CREATE TABLE organismes (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(150) NOT NULL,
    siret VARCHAR(14) UNIQUE NOT NULL,
    secteur VARCHAR(100),
    region VARCHAR(100),
    taille_effectif INT CHECK (taille_effectif > 0)
);

CREATE TABLE agents_instructeurs (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE dossiers_aide (
    id SERIAL PRIMARY KEY,
    organisme_id INT REFERENCES organismes(id),
    categorie_id INT REFERENCES categories_aides(id),
    agent_id INT REFERENCES agents_instructeurs(id),
    montant_demande NUMERIC(12,2) CHECK (montant_demande > 0),
    montant_accorde NUMERIC(12,2) CHECK (montant_accorde >= 0),
    statut VARCHAR(20) DEFAULT 'déposé'
        CHECK (statut IN ('déposé', 'en instruction', 'accepté', 'refusé')),
    date_depot DATE DEFAULT CURRENT_DATE,
    date_decision DATE,
    details JSONB,
    tags TEXT[]
);


-- ============================================================
-- 2. INSERTION DES DONNÉES DE TEST
-- ============================================================

INSERT INTO categories_aides (nom, categorie_parent_id) VALUES
('Énergie', NULL),
('Bâtiment', NULL),
('Énergies renouvelables', 1),
('Efficacité énergétique', 1),
('Isolation', 2),
('Solaire photovoltaïque', 3),
('Éolien', 3);

INSERT INTO organismes (nom, siret, secteur, region, taille_effectif) VALUES
('EcoBât Solutions', '12345678900011', 'BTP', 'Bretagne', 45),
('SolarTech Industries', '23456789000122', 'Énergie', 'Occitanie', 120),
('Ville de Rennes', '34567890000133', 'Collectivité', 'Bretagne', 3200),
('Ferme Éolienne du Nord', '45678901000144', 'Énergie', 'Hauts-de-France', 12),
('Coopérative AgriVert', '56789012000155', 'Agriculture', 'Nouvelle-Aquitaine', 28);

INSERT INTO agents_instructeurs (nom, email) VALUES
('Élise Fontaine', 'elise.fontaine@ademe-fictif.fr'),
('Hugo Lambert', 'hugo.lambert@ademe-fictif.fr'),
('Camille Roy', 'camille.roy@ademe-fictif.fr');

INSERT INTO dossiers_aide (organisme_id, categorie_id, agent_id, montant_demande, montant_accorde, statut, date_depot, date_decision, details, tags) VALUES
(1, 5, 1, 45000.00, 38000.00, 'accepté', '2026-01-15', '2026-03-01',
    '{"technologie": "isolation extérieure", "surface_m2": 850}', ARRAY['bâtiment', 'rénovation']),
(2, 6, 2, 120000.00, NULL, 'en instruction', '2026-02-20', NULL,
    '{"technologie": "panneaux photovoltaïques", "puissance_kwc": 250}', ARRAY['solaire', 'production']),
(3, 4, 1, 78000.00, 78000.00, 'accepté', '2026-01-05', '2026-02-10',
    '{"technologie": "rénovation éclairage public", "nb_points_lumineux": 1200}', ARRAY['collectivité', 'éclairage']),
(4, 7, 3, 350000.00, NULL, 'déposé', '2026-04-10', NULL,
    '{"technologie": "éoliennes terrestres", "nb_machines": 3}', ARRAY['éolien', 'production']),
(5, 3, 2, 62000.00, 0.00, 'refusé', '2026-02-01', '2026-03-20',
    '{"technologie": "méthanisation", "motif_refus": "dossier incomplet"}', ARRAY['agriculture', 'biogaz']),
(1, 6, 1, 30000.00, NULL, 'en instruction', '2026-05-01', NULL,
    '{"technologie": "panneaux photovoltaïques", "puissance_kwc": 80}', ARRAY['solaire', 'bâtiment']);


-- ============================================================
-- EXERCICE 1 - CTE RÉCURSIVE : hiérarchie complète des catégories d'aides
-- ============================================================
-- 🎯 OBJECTIF : Afficher toutes les catégories d'aides avec leur niveau de profondeur, en descendant automatiquement dans la hiérarchie parent/enfant, quel que soit le nombre de niveaux.

WITH RECURSIVE arbre_categories AS (
    SELECT id, nom, categorie_parent_id, 1 AS niveau
    FROM categories_aides
    WHERE categorie_parent_id IS NULL

    UNION ALL

    SELECT c.id, c.nom, c.categorie_parent_id, ac.niveau + 1
    FROM categories_aides c
    JOIN arbre_categories ac ON c.categorie_parent_id = ac.id
    WHERE ac.niveau < 10
)
SELECT * FROM arbre_categories
ORDER BY niveau, nom;
-- ------------------------------------------------------------
-- Résultat attendu :
-- id | nom                      | categorie_parent_id | niveau
-- 2  | Bâtiment                 | NULL                 | 1
-- 1  | Énergie                  | NULL                 | 1
-- 4  | Efficacité énergétique   | 1                    | 2
-- 3  | Énergies renouvelables   | 1                    | 2
-- 5  | Isolation                | 2                    | 2
-- 7  | Éolien                   | 3                    | 3
-- 6  | Solaire photovoltaïque   | 3                    | 3
-- ------------------------------------------------------------


-- ============================================================
-- EXERCICE 2 - FONCTIONS DE FENÊTRAGE : classement des montants par région
-- ============================================================
-- 🎯 OBJECTIF : Classer chaque dossier par montant demandé au sein de sa région, tout en gardant chaque ligne individuelle visible (contrairement à un simple GROUP BY).

SELECT o.region, o.nom AS organisme, d.montant_demande,
       RANK() OVER (PARTITION BY o.region ORDER BY d.montant_demande DESC) AS rang_region,
       ROUND(AVG(d.montant_demande) OVER (PARTITION BY o.region), 2) AS moyenne_region
FROM dossiers_aide d
JOIN organismes o ON d.organisme_id = o.id
ORDER BY o.region, rang_region;
-- ------------------------------------------------------------
-- Résultat attendu (extrait) :
-- Bretagne : Ville de Rennes (78000, rang 1) puis EcoBât Solutions x2 (45000 rang 2, 30000 rang 3)
-- Occitanie : SolarTech Industries (120000, rang 1)
-- Hauts-de-France : Ferme Éolienne du Nord (350000, rang 1)
-- Nouvelle-Aquitaine : Coopérative AgriVert (62000, rang 1)
-- ------------------------------------------------------------


-- ============================================================
-- EXERCICE 3 - CASE WHEN : taux de traitement par statut
-- ============================================================
-- 🎯 OBJECTIF : Transformer les codes de statut bruts en libellés compréhensibles pour un rapport destiné à des non-techniciens.

SELECT nom,
    CASE statut
        WHEN 'accepté' THEN 'Financement validé'
        WHEN 'refusé' THEN 'Financement rejeté'
        WHEN 'en instruction' THEN 'En cours d''analyse'
        ELSE 'Dossier récent, non traité'
    END AS statut_lisible
FROM dossiers_aide d
JOIN organismes o ON d.organisme_id = o.id;
-- Résultat attendu : chaque organisme avec un libellé humain au lieu du code statut brut


-- ============================================================
-- EXERCICE 4 - COALESCE : afficher un montant accordé par défaut
-- ============================================================
-- 🎯 OBJECTIF : Éviter d'afficher des valeurs vides (NULL) pour les dossiers pas encore décidés, en les remplaçant par une valeur ou un texte par défaut.

SELECT o.nom, d.montant_demande,
       COALESCE(d.montant_accorde, 0) AS montant_accorde_affiche,
       COALESCE(d.date_decision::TEXT, 'Décision en attente') AS decision
FROM dossiers_aide d
JOIN organismes o ON d.organisme_id = o.id;
-- Résultat attendu : les dossiers "en instruction"/"déposé" affichent 0 au lieu de NULL,
-- et "Décision en attente" au lieu d'une date vide


-- ============================================================
-- EXERCICE 5 - SOUS-REQUÊTES : organismes sans aucun dossier accepté
-- ============================================================
-- 🎯 OBJECTIF : Identifier les organismes qui n'ont encore reçu aucune validation, pour un suivi ciblé de leur dossier.

SELECT o.nom
FROM organismes o
WHERE NOT EXISTS (
    SELECT 1 FROM dossiers_aide d
    WHERE d.organisme_id = o.id AND d.statut = 'accepté'
);
-- Résultat attendu : SolarTech Industries, Ferme Éolienne du Nord, Coopérative AgriVert


-- ============================================================
-- EXERCICE 6 - JSONB : extraire la puissance des projets solaires
-- ============================================================
-- 🎯 OBJECTIF : Extraire une donnée technique précise (puissance en kWc) stockée dans un champ JSON à structure variable, sans avoir besoin d'une colonne dédiée dans la table.

SELECT o.nom, d.details ->> 'technologie' AS technologie,
       (d.details ->> 'puissance_kwc')::NUMERIC AS puissance_kwc
FROM dossiers_aide d
JOIN organismes o ON d.organisme_id = o.id
WHERE d.details ? 'puissance_kwc'
ORDER BY puissance_kwc DESC;
-- Résultat attendu : SolarTech Industries (250 kWc), EcoBât Solutions (80 kWc)


-- ============================================================
-- EXERCICE 7 - ARRAY : dossiers tagués "production"
-- ============================================================
-- 🎯 OBJECTIF : Retrouver rapidement tous les dossiers liés à une thématique donnée grâce à leurs tags, sans jointure supplémentaire.

SELECT o.nom, d.tags
FROM dossiers_aide d
JOIN organismes o ON d.organisme_id = o.id
WHERE 'production' = ANY(d.tags);
-- Résultat attendu : SolarTech Industries, Ferme Éolienne du Nord


-- ============================================================
-- EXERCICE 8 - INDEX : accélérer la recherche par SIRET
-- ============================================================
-- 🎯 OBJECTIF : Vérifier que les recherches fréquentes (par SIRET, par organisme, par statut) s'appuient bien sur un index plutôt que sur un parcours complet de la table.

-- siret déjà indexé automatiquement grâce à UNIQUE
CREATE INDEX idx_dossiers_organisme ON dossiers_aide (organisme_id);
CREATE INDEX idx_dossiers_agent ON dossiers_aide (agent_id);
CREATE INDEX idx_dossiers_statut ON dossiers_aide (statut);

EXPLAIN SELECT * FROM organismes WHERE siret = '23456789000122';
-- Résultat attendu : "Index Scan using organismes_siret_key"


-- ============================================================
-- EXERCICE 9 - TRANSACTION : valider un dossier en instruction
-- ============================================================
-- 🎯 OBJECTIF : Faire passer un dossier de "en instruction" à "accepté" en garantissant que le changement de statut ET le montant accordé soient appliqués ensemble, ou pas du tout en cas d'erreur.

BEGIN;

UPDATE dossiers_aide
SET statut = 'accepté',
    montant_accorde = 100000.00,
    date_decision = CURRENT_DATE
WHERE organisme_id = (SELECT id FROM organismes WHERE nom = 'SolarTech Industries')
  AND statut = 'en instruction';

SELECT * FROM dossiers_aide
WHERE organisme_id = (SELECT id FROM organismes WHERE nom = 'SolarTech Industries');
-- Résultat attendu : le dossier SolarTech passe à "accepté", montant_accorde = 100000.00

COMMIT;


-- ============================================================
-- EXERCICE 10 - VUE : tableau de bord des dossiers par catégorie
-- ============================================================
-- 🎯 OBJECTIF : Créer un rapport réutilisable donnant en un coup d'œil le nombre de dossiers et les montants totaux par catégorie d'aide, sans avoir à réécrire la requête à chaque consultation.

CREATE VIEW bilan_categories AS
SELECT c.nom AS categorie,
       COUNT(d.id) AS nombre_dossiers,
       COALESCE(SUM(d.montant_demande), 0) AS total_demande,
       COALESCE(SUM(d.montant_accorde), 0) AS total_accorde
FROM categories_aides c
LEFT JOIN dossiers_aide d ON d.categorie_id = c.id
GROUP BY c.nom;

SELECT * FROM bilan_categories ORDER BY total_demande DESC;
-- Résultat attendu : une ligne par catégorie, y compris celles sans dossier (0 partout)


-- ============================================================
-- PARTIE 2 - DONNÉES FINANCIÈRES : ENVELOPPES, VERSEMENTS, INDICATEURS
-- ============================================================
-- Objectif : suivre le pilotage financier des aides -
-- budget alloué par catégorie/année, paiements réels effectués,
-- et indicateurs globaux (taux d'engagement, reste à verser, prévisionnel)


-- ------------------------------------------------------------
-- 14. NOUVELLES TABLES
-- ------------------------------------------------------------

CREATE TABLE enveloppes_budgetaires (
    id SERIAL PRIMARY KEY,
    categorie_id INT REFERENCES categories_aides(id),
    annee INT NOT NULL,
    budget_alloue NUMERIC(14,2) CHECK (budget_alloue > 0),
    UNIQUE (categorie_id, annee)          -- une seule enveloppe par catégorie et par année
);

CREATE TABLE versements (
    id SERIAL PRIMARY KEY,
    dossier_id INT REFERENCES dossiers_aide(id),
    montant NUMERIC(12,2) CHECK (montant > 0),
    date_versement DATE DEFAULT CURRENT_DATE
);


-- ------------------------------------------------------------
-- 15. DONNÉES DE TEST FINANCIÈRES
-- ------------------------------------------------------------

INSERT INTO enveloppes_budgetaires (categorie_id, annee, budget_alloue) VALUES
(3, 2026, 500000.00),   -- Énergies renouvelables
(4, 2026, 200000.00),   -- Efficacité énergétique
(5, 2026, 150000.00),   -- Isolation
(6, 2026, 400000.00),   -- Solaire photovoltaïque
(7, 2026, 600000.00);   -- Éolien

-- Versements échelonnés pour les dossiers déjà acceptés (id=1, id=3, et id=2 après validation)
INSERT INTO versements (dossier_id, montant, date_versement) VALUES
(1, 19000.00, '2026-03-15'),   -- EcoBât : 1er versement (50% de 38000)
(1, 19000.00, '2026-06-15'),   -- EcoBât : solde
(3, 78000.00, '2026-02-20'),   -- Ville de Rennes : versement unique
(2, 50000.00, '2026-06-10');   -- SolarTech : 1er acompte (sur les 100000 validés en transaction)


-- ------------------------------------------------------------
-- EXERCICE 11 - TAUX D'ENGAGEMENT par catégorie et par année
-- ------------------------------------------------------------
-- 🎯 OBJECTIF : mesurer, pour chaque catégorie d'aide, quelle proportion du
-- budget alloué a déjà été engagée par des décisions favorables.
-- Rapport entre le montant déjà accordé (engagé) et le budget alloué

SELECT c.nom AS categorie, e.annee, e.budget_alloue,
       COALESCE(SUM(d.montant_accorde), 0) AS montant_engage,
       ROUND(COALESCE(SUM(d.montant_accorde), 0) / e.budget_alloue * 100, 2) AS taux_engagement_pct
FROM enveloppes_budgetaires e
JOIN categories_aides c ON e.categorie_id = c.id
LEFT JOIN dossiers_aide d ON d.categorie_id = e.categorie_id AND d.statut = 'accepté'
GROUP BY c.nom, e.annee, e.budget_alloue
ORDER BY taux_engagement_pct DESC;
-- ------------------------------------------------------------
-- Résultat attendu (extrait) :
-- Isolation              | 150000 | 38000  | 25.33 %
-- Efficacité énergétique | 200000 | 78000  | 39.00 %
-- Solaire photovoltaïque | 400000 | 100000 | 25.00 % (après validation du dossier SolarTech)
-- Énergies renouvelables | 500000 | 0      | 0.00 %
-- Éolien                 | 600000 | 0      | 0.00 %
-- ------------------------------------------------------------


-- ------------------------------------------------------------
-- EXERCICE 12 - RESTE À VERSER par dossier accepté
-- ------------------------------------------------------------
-- 🎯 OBJECTIF : suivre, pour chaque dossier validé, le montant qu'il reste
-- concrètement à payer à l'organisme bénéficiaire.
-- Différence entre ce qui a été accordé et ce qui a déjà été payé

SELECT o.nom AS organisme, d.montant_accorde,
       COALESCE(SUM(v.montant), 0) AS deja_verse,
       d.montant_accorde - COALESCE(SUM(v.montant), 0) AS reste_a_verser
FROM dossiers_aide d
JOIN organismes o ON d.organisme_id = o.id
LEFT JOIN versements v ON v.dossier_id = d.id
WHERE d.statut = 'accepté'
GROUP BY o.nom, d.montant_accorde
ORDER BY reste_a_verser DESC;
-- ------------------------------------------------------------
-- Résultat attendu :
-- SolarTech Industries | 100000.00 | 50000.00 | 50000.00   (reste à verser)
-- Ville de Rennes      | 78000.00  | 78000.00 | 0.00       (soldé)
-- EcoBât Solutions     | 38000.00  | 38000.00 | 0.00       (soldé)
-- ------------------------------------------------------------


-- ------------------------------------------------------------
-- EXERCICE 13 - CUMUL PROGRESSIF DES VERSEMENTS (fonction de fenêtrage)
-- ------------------------------------------------------------
-- 🎯 OBJECTIF : visualiser l'évolution de la trésorerie réellement décaissée
-- au fil du temps, tous dossiers confondus.
-- Suivi du budget effectivement décaissé au fil du temps, tous dossiers confondus

SELECT v.date_versement, o.nom AS organisme, v.montant,
       SUM(v.montant) OVER (ORDER BY v.date_versement) AS montant_cumule_verse
FROM versements v
JOIN dossiers_aide d ON v.dossier_id = d.id
JOIN organismes o ON d.organisme_id = o.id
ORDER BY v.date_versement;
-- ------------------------------------------------------------
-- Résultat attendu :
-- 2026-02-20 | Ville de Rennes  | 78000.00 | 78000.00
-- 2026-03-15 | EcoBât Solutions | 19000.00 | 97000.00
-- 2026-06-10 | SolarTech Ind.   | 50000.00 | 147000.00
-- 2026-06-15 | EcoBât Solutions | 19000.00 | 166000.00
-- ------------------------------------------------------------


-- ------------------------------------------------------------
-- EXERCICE 14 - PRÉVISIONNEL : projection simple du reste à engager
-- ------------------------------------------------------------
-- 🎯 OBJECTIF : anticiper le risque de dépassement budgétaire en classant
-- chaque catégorie selon son niveau d'engagement actuel.
-- Estimation du budget encore disponible par catégorie, avec un indicateur
-- CASE WHEN pour signaler le niveau d'alerte budgétaire

SELECT c.nom AS categorie, e.budget_alloue,
       COALESCE(SUM(d.montant_accorde), 0) AS engage,
       e.budget_alloue - COALESCE(SUM(d.montant_accorde), 0) AS budget_restant,
    CASE
        WHEN COALESCE(SUM(d.montant_accorde), 0) / e.budget_alloue >= 0.8 THEN 'Alerte - budget bientôt épuisé'
        WHEN COALESCE(SUM(d.montant_accorde), 0) / e.budget_alloue >= 0.4 THEN 'Vigilance - engagement modéré'
        ELSE 'Marge disponible confortable'
    END AS niveau_alerte
FROM enveloppes_budgetaires e
JOIN categories_aides c ON e.categorie_id = c.id
LEFT JOIN dossiers_aide d ON d.categorie_id = e.categorie_id AND d.statut = 'accepté'
GROUP BY c.nom, e.budget_alloue
ORDER BY budget_restant ASC;
-- Résultat attendu : aucune catégorie n'atteint 80% ici -> toutes en "Marge disponible confortable"
-- ou "Vigilance" pour Efficacité énergétique (39%)


-- ------------------------------------------------------------
-- EXERCICE 15 - VUE : tableau de bord financier global
-- ------------------------------------------------------------
-- 🎯 OBJECTIF : regrouper en une seule vue réutilisable les indicateurs clés
-- (budget, engagé, versé, taux) pour un reporting financier régulier.

CREATE VIEW tableau_bord_financier AS
SELECT c.nom AS categorie, e.annee, e.budget_alloue,
       COALESCE(SUM(DISTINCT d.montant_accorde), 0) AS montant_engage,
       COALESCE((SELECT SUM(v.montant) FROM versements v
                 JOIN dossiers_aide d2 ON v.dossier_id = d2.id
                 WHERE d2.categorie_id = e.categorie_id), 0) AS montant_verse,
       ROUND(COALESCE(SUM(DISTINCT d.montant_accorde), 0) / e.budget_alloue * 100, 2) AS taux_engagement_pct
FROM enveloppes_budgetaires e
JOIN categories_aides c ON e.categorie_id = c.id
LEFT JOIN dossiers_aide d ON d.categorie_id = e.categorie_id AND d.statut = 'accepté'
GROUP BY c.nom, e.annee, e.budget_alloue, e.categorie_id;

SELECT * FROM tableau_bord_financier ORDER BY taux_engagement_pct DESC;
-- Résultat attendu : synthèse réutilisable combinant budget, engagé, versé et taux, par catégorie


-- ============================================================
-- RÉCAPITULATIF PARTIE 2 - NOTIONS FINANCIÈRES ILLUSTRÉES
-- ============================================================
-- - Nouvelles contraintes : UNIQUE composite (categorie_id, annee)
-- - COALESCE pour neutraliser les catégories sans dossier accepté
-- - Calculs dérivés (taux, reste à verser) directement en SQL
-- - Fonction de fenêtrage SUM() OVER pour un cumul chronologique de trésorerie
-- - CASE WHEN pour classer un niveau d'alerte budgétaire
-- - Sous-requête corrélée dans le SELECT d'une vue (montant_verse)
-- - Vue de synthèse combinant plusieurs sources (enveloppes + dossiers + versements)


-- ============================================================
-- RÉCAPITULATIF DES NOTIONS ILLUSTRÉES
-- ============================================================
-- WITH RECURSIVE, fonctions de fenêtrage (RANK, AVG OVER), CASE WHEN,
-- COALESCE, EXISTS/NOT EXISTS, JSONB, ARRAY, INDEX + EXPLAIN,
-- TRANSACTIONS (BEGIN/COMMIT), VUES (CREATE VIEW)


-- ============================================================
-- PERSPECTIVES - KPI DE PILOTAGE BUDGÉTAIRE
-- ============================================================
-- Ce projet peut être enrichi pour établir tous les KPI de pilotage
-- budgétaire pertinents, permettant de prendre des décisions
-- optimales, notamment :
--   1. Taux d'engagement budgétaire par catégorie/région/année
--   2. Délai moyen d'instruction (dépôt -> décision)
--   3. Taux d'acceptation des dossiers (accepté / total traité)
--   4. Reste à verser global et par échéance (prévision de trésorerie)
--   5. Montant moyen accordé par dossier, par secteur d'activité
--
-- Cependant, pour l'exploitation et la visualisation de ces
-- indicateurs, nous privilégions Power BI plutôt que des requêtes
-- SQL de reporting : tableaux de bord interactifs, filtres dynamiques
-- et partage facilité auprès de décideurs non techniques.


-- ============================================================
-- LIEN POUR REPRENDRE LA SÉANCE (DB Fiddle)
-- ============================================================
-- https://www.db-fiddle.com/f/n7Vqz25KhTNvxMEN8pXuiG/0
