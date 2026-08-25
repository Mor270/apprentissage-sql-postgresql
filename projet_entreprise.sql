-- ============================================================
-- PROJET GESTION D'ENTREPRISE - RÉCAPITULATIF COMPLET
-- Synthèse de toutes les notions vues : bases, contraintes, CTE,
-- fonctions de fenêtrage, sous-requêtes, index, transactions,
-- types avancés (JSONB/ARRAY), vues, CASE WHEN, dates, CTE récursive
-- ============================================================


-- ============================================================
-- 1. CRÉATION DES TABLES
-- ============================================================
-- Choix du domaine "entreprise" pour illustrer une VRAIE hiérarchie
-- à deux niveaux : départements imbriqués ET employés avec managers.
-- Ordre de création : départements et employés d'abord (avec leur
-- propre auto-référence), puis projets, puis tâches qui dépendent
-- des deux précédents.

-- Table DÉPARTEMENTS (auto-référencée : un département peut avoir un parent)
CREATE TABLE departements (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    departement_parent_id INT REFERENCES departements(id)
                                       -- pointe vers un AUTRE id de la MÊME table
                                       -- NULL = département racine (pas de parent)
);

-- Table EMPLOYÉS (auto-référencée : un employé a un manager, lui-même employé)
CREATE TABLE employes (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    departement_id INT REFERENCES departements(id),
    manager_id INT REFERENCES employes(id),
                                       -- pointe vers un AUTRE id de la MÊME table
                                       -- NULL = pas de manager (le plus haut niveau)
    salaire NUMERIC(10,2) CHECK (salaire > 0),
    date_embauche DATE DEFAULT CURRENT_DATE,
    competences JSONB,                -- type avancé : structure variable selon l'employé
    tags TEXT[]                       -- type avancé : liste simple de mots-clés
);

-- Table PROJETS
CREATE TABLE projets (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(150) NOT NULL,
    date_debut DATE NOT NULL,
    date_fin DATE,                    -- NULL si le projet est encore en cours
    budget NUMERIC(12,2) CHECK (budget > 0)
);

-- Table TÂCHES (table de liaison, dépend de projets ET d'employés)
CREATE TABLE taches (
    id SERIAL PRIMARY KEY,
    projet_id INT REFERENCES projets(id),
    employe_id INT REFERENCES employes(id),
    titre VARCHAR(200) NOT NULL,
    statut VARCHAR(20) DEFAULT 'à faire' CHECK (statut IN ('à faire', 'en cours', 'terminée')),
                                       -- CHECK avec IN : limite les valeurs possibles
    date_creation DATE DEFAULT CURRENT_DATE,
    date_echeance DATE
);


-- ============================================================
-- 2. INSERTION DES DONNÉES DE TEST
-- ============================================================

-- Départements : Direction > Tech > (Développement, Data)
INSERT INTO departements (nom, departement_parent_id) VALUES
('Direction', NULL),               -- id=1, racine
('Tech', 1),                       -- id=2, sous-département de Direction
('Développement', 2),              -- id=3, sous-département de Tech
('Data', 2),                       -- id=4, sous-département de Tech
('Commercial', 1);                 -- id=5, sous-département de Direction

-- Employés avec hiérarchie de management + JSONB + ARRAY
INSERT INTO employes (nom, email, departement_id, manager_id, salaire, date_embauche, competences, tags) VALUES
('Claire Dubois', 'claire.dubois@entreprise.com', 1, NULL, 7500.00, '2018-01-15',
    '{"role": "Directrice", "anciennete_management": 8}', ARRAY['direction', 'stratégie']),
('Marc Lefèvre', 'marc.lefevre@entreprise.com', 2, 1, 6200.00, '2019-03-10',
    '{"role": "Directeur Tech", "langages": ["Python", "SQL"]}', ARRAY['tech', 'management']),
('Julie Moreau', 'julie.moreau@entreprise.com', 3, 2, 4800.00, '2020-06-01',
    '{"role": "Développeuse Senior", "langages": ["JavaScript", "SQL", "Python"], "niveau": "senior"}',
    ARRAY['dev', 'frontend', 'backend']),
('Thomas Petit', 'thomas.petit@entreprise.com', 3, 2, 3900.00, '2022-09-12',
    '{"role": "Développeur", "langages": ["JavaScript"], "niveau": "junior"}', ARRAY['dev', 'frontend']),
('Nadia Rousseau', 'nadia.rousseau@entreprise.com', 4, 2, 5100.00, '2021-02-20',
    '{"role": "Data Analyst", "langages": ["SQL", "Python"], "niveau": "confirmé"}', ARRAY['data', 'analyse']),
('Karim Benali', 'karim.benali@entreprise.com', 5, 1, 4300.00, '2020-11-05',
    '{"role": "Commercial", "secteur": "grands comptes"}', ARRAY['vente', 'terrain']);

-- Projets
INSERT INTO projets (nom, date_debut, date_fin, budget) VALUES
('Refonte site vitrine', '2026-01-10', '2026-04-30', 25000.00),
('Migration base de données', '2026-03-01', NULL, 40000.00),          -- toujours en cours
('Tableau de bord analytique', '2026-05-15', NULL, 18000.00);         -- toujours en cours

-- Tâches
INSERT INTO taches (projet_id, employe_id, titre, statut, date_creation, date_echeance) VALUES
(1, 3, 'Intégration maquettes', 'terminée', '2026-01-12', '2026-02-01'),
(1, 4, 'Développement formulaire contact', 'terminée', '2026-01-20', '2026-02-10'),
(2, 2, 'Audit de l''architecture actuelle', 'terminée', '2026-03-02', '2026-03-15'),
(2, 3, 'Écriture des scripts de migration', 'en cours', '2026-03-16', '2026-05-30'),
(3, 5, 'Modélisation des indicateurs', 'en cours', '2026-05-16', '2026-06-15'),
(3, 5, 'Connexion aux sources de données', 'à faire', '2026-05-20', '2026-07-01');


-- ============================================================
-- 3. CTE RÉCURSIVE - parcourir la hiérarchie des départements
-- ============================================================
-- Rappel : une CTE récursive s'appelle elle-même jusqu'à épuisement
-- des lignes trouvées. Indispensable ici car on ignore à l'avance
-- combien de niveaux de sous-départements existent.

WITH RECURSIVE arbre_departements AS (
    -- ANCRAGE : on part du département racine "Direction"
    SELECT id, nom, departement_parent_id, 1 AS niveau
    FROM departements
    WHERE departement_parent_id IS NULL

    UNION ALL

    -- RÉCURSION : on cherche les départements dont le parent est déjà dans le résultat
    SELECT d.id, d.nom, d.departement_parent_id, ad.niveau + 1
    FROM departements d
    JOIN arbre_departements ad ON d.departement_parent_id = ad.id
    WHERE ad.niveau < 10                    -- sécurité anti-boucle infinie
)
SELECT * FROM arbre_departements
ORDER BY niveau, nom;
-- ------------------------------------------------------------
-- Résultat attendu :
-- id | nom            | departement_parent_id | niveau
-- 1  | Direction      | NULL                   | 1
-- 5  | Commercial     | 1                      | 2
-- 2  | Tech           | 1                      | 2
-- 4  | Data           | 2                      | 3
-- 3  | Développement  | 2                      | 3
-- ------------------------------------------------------------


-- ============================================================
-- 4. CTE RÉCURSIVE - remonter la chaîne hiérarchique d'un employé
-- ============================================================
-- Variante utile : afficher tous les managers successifs d'un employé,
-- jusqu'au sommet de l'organisation (manager_id IS NULL)

WITH RECURSIVE chaine_management AS (
    -- ANCRAGE : on part de l'employé recherché
    SELECT id, nom, manager_id, 1 AS niveau
    FROM employes
    WHERE nom = 'Thomas Petit'

    UNION ALL

    -- RÉCURSION : on remonte vers le manager de la ligne précédente
    SELECT e.id, e.nom, e.manager_id, cm.niveau + 1
    FROM employes e
    JOIN chaine_management cm ON e.id = cm.manager_id
)
SELECT * FROM chaine_management
ORDER BY niveau;
-- Résultat attendu : Thomas Petit -> Marc Lefèvre -> Claire Dubois
-- ------------------------------------------------------------
-- id | nom            | manager_id | niveau
-- 4  | Thomas Petit   | 2          | 1
-- 2  | Marc Lefèvre   | 1          | 2
-- 1  | Claire Dubois  | NULL       | 3
-- ------------------------------------------------------------


-- ============================================================
-- 5. CTE CLASSIQUE + FONCTIONS DE FENÊTRAGE
-- ============================================================
-- Classement des salaires par département, sans fusionner les lignes

SELECT nom, departement_id, salaire,
       RANK() OVER (PARTITION BY departement_id ORDER BY salaire DESC) AS rang_departement,
                                        -- classement indépendant pour chaque département
       ROUND(AVG(salaire) OVER (PARTITION BY departement_id), 2) AS moyenne_departement
                                        -- moyenne du département, affichée sur CHAQUE ligne
                                        -- (contrairement à GROUP BY qui fusionnerait les lignes)
FROM employes
ORDER BY departement_id, rang_departement;
-- ------------------------------------------------------------
-- Résultat attendu (extrait) :
-- nom            | departement_id | salaire | rang_departement | moyenne_departement
-- Claire Dubois  | 1              | 7500.00 | 1                | 7500.00
-- Marc Lefèvre   | 2              | 6200.00 | 1                | 6200.00
-- Julie Moreau   | 3              | 4800.00 | 1                | 4350.00
-- Thomas Petit   | 3              | 3900.00 | 2                | 4350.00
-- Nadia Rousseau | 4              | 5100.00 | 1                | 5100.00
-- Karim Benali   | 5              | 4300.00 | 1                | 4300.00
-- -> chaque ligne individuelle est conservée (contrairement à GROUP BY)
-- ------------------------------------------------------------


-- Cumul progressif du budget des projets, triés par date de début
SELECT nom, date_debut, budget,
       SUM(budget) OVER (ORDER BY date_debut) AS budget_cumule
FROM projets
ORDER BY date_debut;
-- ------------------------------------------------------------
-- Résultat attendu :
-- nom                          | date_debut | budget   | budget_cumule
-- Refonte site vitrine         | 2026-01-10 | 25000.00 | 25000.00
-- Migration base de données    | 2026-03-01 | 40000.00 | 65000.00
-- Tableau de bord analytique   | 2026-05-15 | 18000.00 | 83000.00
-- ------------------------------------------------------------


-- ============================================================
-- 6. SOUS-REQUÊTES AVANCÉES
-- ============================================================

-- EXISTS : employés ayant au moins une tâche assignée
SELECT nom
FROM employes e
WHERE EXISTS (
    SELECT 1 FROM taches t WHERE t.employe_id = e.id
);
-- Résultat attendu : Julie Moreau, Thomas Petit, Marc Lefèvre, Nadia Rousseau

-- NOT EXISTS : employés sans AUCUNE tâche assignée
SELECT nom
FROM employes e
WHERE NOT EXISTS (
    SELECT 1 FROM taches t WHERE t.employe_id = e.id
);
-- Résultat attendu : Claire Dubois, Karim Benali

-- Sous-requête scalaire dans WHERE : employés payés au-dessus de la moyenne générale
SELECT nom, salaire
FROM employes
WHERE salaire > (SELECT AVG(salaire) FROM employes);
-- Moyenne générale ≈ 5300.00 -> Résultat attendu : Claire Dubois (7500), Marc Lefèvre (6200)


-- ============================================================
-- 7. CASE WHEN - catégoriser les salaires
-- ============================================================

SELECT nom, salaire,
    CASE
        WHEN salaire < 4000 THEN 'Junior'
        WHEN salaire BETWEEN 4000 AND 6000 THEN 'Confirmé'
        ELSE 'Senior / Management'
    END AS tranche_salariale
FROM employes
ORDER BY salaire DESC;
-- ------------------------------------------------------------
-- Résultat attendu :
-- Claire Dubois  (7500.00) -> Senior / Management
-- Marc Lefèvre   (6200.00) -> Senior / Management
-- Nadia Rousseau (5100.00) -> Confirmé
-- Julie Moreau   (4800.00) -> Confirmé
-- Karim Benali   (4300.00) -> Confirmé
-- Thomas Petit   (3900.00) -> Junior
-- ------------------------------------------------------------


-- ============================================================
-- 8. COALESCE - afficher un manager par défaut
-- ============================================================

SELECT e.nom AS employe,
       COALESCE(m.nom, 'Aucun manager (sommet de la hiérarchie)') AS manager
FROM employes e
LEFT JOIN employes m ON e.manager_id = m.id;
                                        -- LEFT JOIN nécessaire pour garder Claire Dubois
                                        -- (sans manager) dans le résultat
-- ------------------------------------------------------------
-- Résultat attendu (extrait) :
-- Claire Dubois  -> Aucun manager (sommet de la hiérarchie)
-- Marc Lefèvre   -> Claire Dubois
-- Julie Moreau   -> Marc Lefèvre
-- Thomas Petit   -> Marc Lefèvre
-- ------------------------------------------------------------


-- ============================================================
-- 9. FONCTIONS DE DATES
-- ============================================================

-- Ancienneté de chaque employé, calculée depuis sa date d'embauche
SELECT nom, date_embauche,
       AGE(CURRENT_DATE, date_embauche) AS anciennete
FROM employes
ORDER BY date_embauche;
-- Résultat attendu (durées approximatives, calculées depuis aujourd'hui) :
-- Claire Dubois  (2018-01-15) -> environ 8 ans
-- Marc Lefèvre   (2019-03-10) -> environ 7 ans
-- Julie Moreau   (2020-06-01) -> environ 6 ans
-- Karim Benali   (2020-11-05) -> environ 5-6 ans
-- Nadia Rousseau (2021-02-20) -> environ 5 ans
-- Thomas Petit   (2022-09-12) -> environ 4 ans

-- Durée des projets déjà terminés
SELECT nom, date_debut, date_fin,
       (date_fin - date_debut) AS duree_en_jours
FROM projets
WHERE date_fin IS NOT NULL;
-- Résultat attendu :
-- Refonte site vitrine | 2026-01-10 | 2026-04-30 | 110 jours
-- (les 2 autres projets ont date_fin = NULL, donc exclus par le WHERE)

-- Tâches créées par mois (regroupement avec DATE_TRUNC)
SELECT DATE_TRUNC('month', date_creation) AS mois,
       COUNT(*) AS nombre_taches
FROM taches
GROUP BY DATE_TRUNC('month', date_creation)
ORDER BY mois;
-- Résultat attendu :
-- 2026-01-01 -> 2 tâches
-- 2026-03-01 -> 2 tâches
-- 2026-05-01 -> 2 tâches


-- ============================================================
-- 10. TYPES AVANCÉS - JSONB et ARRAY
-- ============================================================

-- Extraire le niveau d'expérience stocké en JSONB
SELECT nom, competences ->> 'role' AS role,
       competences ->> 'niveau' AS niveau
FROM employes
WHERE competences ? 'niveau';           -- uniquement les employés ayant ce champ renseigné
-- Résultat attendu : Julie Moreau (senior), Thomas Petit (junior), Nadia Rousseau (confirmé)

-- Filtrer les employés qui maîtrisent SQL (recherche dans un tableau JSON imbriqué)
SELECT nom
FROM employes
WHERE competences -> 'langages' @> '["SQL"]';
                                        -- @> vérifie que le tableau JSON contient "SQL"
-- Résultat attendu : Marc Lefèvre, Julie Moreau, Nadia Rousseau

-- Filtrer sur un ARRAY : employés tagués "dev"
SELECT nom, tags
FROM employes
WHERE 'dev' = ANY(tags);
-- Résultat attendu : Julie Moreau, Thomas Petit


-- ============================================================
-- 11. INDEX - accélérer les recherches fréquentes
-- ============================================================

-- email déjà indexé automatiquement grâce à UNIQUE
-- Indexer manuellement les clés étrangères souvent utilisées en jointure
CREATE INDEX idx_employes_manager ON employes (manager_id);
CREATE INDEX idx_employes_departement ON employes (departement_id);
CREATE INDEX idx_taches_employe ON taches (employe_id);

-- Vérifier l'utilisation de l'index
EXPLAIN SELECT * FROM employes WHERE email = 'julie.moreau@entreprise.com';
-- Résultat attendu : "Index Scan using employes_email_key" (email est UNIQUE -> index automatique)
-- Sur une aussi petite table, PostgreSQL peut aussi choisir "Seq Scan" malgré l'index -
-- ce comportement devient significatif à partir de centaines/milliers de lignes


-- ============================================================
-- 12. TRANSACTION - augmenter les salaires d'un département en toute sécurité
-- ============================================================
-- Toutes les lignes doivent être modifiées ensemble, ou aucune
-- (ex: éviter une augmentation partielle en cas d'erreur en cours de route)

BEGIN;

UPDATE employes
SET salaire = salaire * 1.05          -- augmentation de 5%
WHERE departement_id = (SELECT id FROM departements WHERE nom = 'Développement');

-- Vérification avant validation définitive
SELECT nom, salaire FROM employes
WHERE departement_id = (SELECT id FROM departements WHERE nom = 'Développement');
-- Résultat attendu :
-- Julie Moreau  | 5040.00   (4800.00 x 1.05)
-- Thomas Petit  | 4095.00   (3900.00 x 1.05)

COMMIT;                                -- si tout est correct, on valide définitivement
-- ROLLBACK;                           -- (utiliser à la place de COMMIT pour annuler le test)


-- ============================================================
-- 13. VUES - requêtes réutilisables
-- ============================================================

-- Vue : charge de travail actuelle par employé
CREATE VIEW charge_travail AS
SELECT e.nom,
       COUNT(t.id) AS nombre_taches,
       COUNT(CASE WHEN t.statut = 'terminée' THEN 1 END) AS taches_terminees,
       COUNT(CASE WHEN t.statut != 'terminée' THEN 1 END) AS taches_en_attente
FROM employes e
LEFT JOIN taches t ON t.employe_id = e.id
GROUP BY e.nom;

SELECT * FROM charge_travail ORDER BY taches_en_attente DESC;
-- ------------------------------------------------------------
-- Résultat attendu (extrait) :
-- Nadia Rousseau -> 2 tâches (0 terminée, 2 en attente)
-- Julie Moreau   -> 2 tâches (1 terminée, 1 en attente)
-- Thomas Petit   -> 1 tâche  (1 terminée, 0 en attente)
-- Marc Lefèvre   -> 1 tâche  (1 terminée, 0 en attente)
-- Claire Dubois  -> 0 tâche
-- Karim Benali   -> 0 tâche
-- ------------------------------------------------------------

-- Vue : projets actifs (non terminés)
CREATE VIEW projets_actifs AS
SELECT nom, date_debut, budget
FROM projets
WHERE date_fin IS NULL;

SELECT * FROM projets_actifs;


-- ============================================================
-- RÉCAPITULATIF GÉNÉRAL DES NOTIONS ILLUSTRÉES DANS CE PROJET
-- ============================================================
-- - Contraintes avancées : CHECK avec IN, auto-référence (REFERENCES sur soi-même)
-- - WITH RECURSIVE : hiérarchie de départements ET chaîne de management
-- - Fonctions de fenêtrage : RANK, AVG OVER, SUM OVER (cumul)
-- - Sous-requêtes : EXISTS, NOT EXISTS, scalaire dans WHERE
-- - CASE WHEN : catégorisation conditionnelle
-- - COALESCE : valeur de repli sur une auto-jointure (management)
-- - Fonctions de dates : AGE, soustraction de dates, DATE_TRUNC
-- - JSONB : structure variable (compétences), opérateurs ->>, ?, @>
-- - ARRAY : tags, opérateur ANY
-- - Index : sur clés étrangères, vérification avec EXPLAIN
-- - Transactions : BEGIN/COMMIT/ROLLBACK sur une mise à jour groupée
-- - Vues : CREATE VIEW pour des rapports réutilisables


-- ============================================================
-- LIEN POUR REPRENDRE LA SÉANCE (DB Fiddle)
-- ============================================================
-- https://www.db-fiddle.com/f/8UpxFabMH7TY55TbX2h36w/0
