-- ============================================================
-- PROJET BIBLIOTHÈQUE - RÉCAPITULATIF COMPLET
-- Exercices d'application : CTE, jointures, agrégation, UPDATE, ALTER TABLE
-- ============================================================


-- ============================================================
-- 1. CRÉATION DES TABLES
-- ============================================================
-- Ordre de création important : les tables "autonomes" d'abord
-- (auteurs, membres), puis "livres" qui dépend d'auteurs,
-- puis "emprunts" qui dépend de membres ET de livres.

-- Table AUTEURS
CREATE TABLE auteurs (
    id SERIAL PRIMARY KEY,            -- identifiant unique auto-incrémenté
    nom VARCHAR(100) NOT NULL,        -- nom de l'auteur, obligatoire
    pays VARCHAR(50)                  -- pays d'origine, optionnel
);

-- Table LIVRES (dépend de auteurs)
CREATE TABLE livres (
    id SERIAL PRIMARY KEY,
    titre VARCHAR(200) NOT NULL,      -- titre du livre, obligatoire
    auteur_id INT REFERENCES auteurs(id),
                                       -- clé étrangère : doit correspondre à un id existant dans "auteurs"
    annee_publication INT,            -- année de publication (nombre entier)
    prix NUMERIC(10,2) CHECK (prix > 0),
                                       -- prix décimal précis, doit être strictement positif
    exemplaires_dispo INT DEFAULT 0 CHECK (exemplaires_dispo >= 0)
                                       -- nombre d'exemplaires disponibles, 0 par défaut, jamais négatif
);

-- Table MEMBRES
CREATE TABLE membres (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,        -- email unique, pas de doublon possible
    ville VARCHAR(50)
);

-- Table EMPRUNTS (table de liaison, dépend de membres ET de livres)
CREATE TABLE emprunts (
    id SERIAL PRIMARY KEY,
    membre_id INT REFERENCES membres(id),
                                       -- clé étrangère vers membres
    livre_id INT REFERENCES livres(id),
                                       -- clé étrangère vers livres
    date_emprunt DATE DEFAULT CURRENT_DATE,
                                       -- date du jour par défaut si non précisée
    date_retour DATE                  -- NULL tant que le livre n'est pas rendu
);


-- ============================================================
-- 2. INSERTION DES DONNÉES DE TEST
-- ============================================================

INSERT INTO auteurs (nom, pays) VALUES
('Victor Hugo', 'France'),
('Jane Austen', 'Royaume-Uni'),
('Haruki Murakami', 'Japon'),
('Gabriel García Márquez', 'Colombie');

INSERT INTO livres (titre, auteur_id, annee_publication, prix, exemplaires_dispo) VALUES
('Les Misérables', 1, 1862, 15.90, 3),
('Notre-Dame de Paris', 1, 1831, 12.50, 0),        -- rupture volontaire pour les tests
('Pride and Prejudice', 2, 1813, 9.99, 5),
('Kafka sur le rivage', 3, 2002, 18.00, 2),
('1Q84', 3, 2009, 22.50, 0),                        -- rupture volontaire pour les tests
('Cent ans de solitude', 4, 1967, 14.00, 4);

INSERT INTO membres (nom, email, ville) VALUES
('Emma Petit', 'emma@mail.com', 'Rennes'),
('Lucas Moreau', 'lucas@mail.com', 'Nantes'),
('Sarah Blanc', 'sarah@mail.com', 'Rennes'),
('Tom Girard', 'tom@mail.com', 'Paris');

INSERT INTO emprunts (membre_id, livre_id, date_emprunt, date_retour) VALUES
(1, 1, '2026-07-01', '2026-07-15'),   -- Emma a emprunté et rendu "Les Misérables"
(1, 4, '2026-07-20', NULL),           -- Emma a emprunté "Kafka sur le rivage", pas encore rendu
(2, 3, '2026-07-05', '2026-07-19'),   -- Lucas a emprunté et rendu "Pride and Prejudice"
(3, 5, '2026-07-10', NULL),           -- Sarah a emprunté "1Q84", pas encore rendu
(3, 1, '2026-08-01', NULL),           -- Sarah a emprunté "Les Misérables", pas encore rendu
(4, 6, '2026-07-25', '2026-08-05');   -- Tom a emprunté et rendu "Cent ans de solitude"


-- ============================================================
-- 3. EXERCICE 1 - Filtrer une table (WHERE simple)
-- ============================================================
-- UTILITÉ : retrouver rapidement un sous-ensemble de lignes
-- Liste tous les membres qui habitent à Rennes

SELECT *                        -- toutes les colonnes (id, nom, email, ville)
FROM membres                    -- source : la table "membres"
WHERE ville = 'Rennes';         -- condition : ne garder que les lignes où ville = 'Rennes'


-- ============================================================
-- 4. EXERCICE 2 - Filtrer avec une condition numérique
-- ============================================================
-- Liste les livres publiés avant 1900

SELECT *                                    -- toutes les colonnes
FROM livres                                 -- source : la table "livres"
WHERE annee_publication < 1900;             -- condition : année strictement inférieure à 1900


-- ============================================================
-- 5. EXERCICE 3 - Identifier les ruptures de stock
-- ============================================================
-- Liste les livres actuellement en rupture

SELECT titre                                -- on affiche seulement le titre
FROM livres                                 -- source : la table "livres"
WHERE exemplaires_dispo = 0;                -- condition : aucun exemplaire disponible


-- ============================================================
-- 6. EXERCICE 4 - Jointure à 3 tables (JOIN)
-- ============================================================
-- UTILITÉ : "emprunts" ne stocke que des ID. Le JOIN permet de
-- traduire ces ID en informations lisibles (nom du membre, titre du livre)
-- Affiche chaque emprunt avec le nom du membre et le titre du livre

SELECT m.nom AS membre,                     -- nom du membre (table membres, alias m)
       l.titre AS livre,                    -- titre du livre (table livres, alias l)
       e.date_emprunt,                      -- date de l'emprunt
       e.date_retour                        -- date de retour (NULL si pas encore rendu)
FROM emprunts e                             -- table de départ : "emprunts", alias "e"
JOIN membres m ON e.membre_id = m.id        -- relie chaque emprunt à son membre via l'id
JOIN livres l ON e.livre_id = l.id;         -- relie chaque emprunt à son livre via l'id


-- ============================================================
-- 7. EXERCICE 5 - Recherche texte insensible à la casse (ILIKE)
-- ============================================================
-- Trouve tous les auteurs dont le nom contient un "a"

SELECT *                                    -- toutes les colonnes
FROM auteurs                                -- source : la table "auteurs"
WHERE nom ILIKE '%a%';                      -- "a" n'importe où dans le nom, insensible à la casse
                                             -- % = n'importe quelle suite de caractères avant/après


-- ============================================================
-- 8. EXERCICE 6 - Intervalle de valeurs (BETWEEN)
-- ============================================================
-- Liste les livres dont le prix est entre 10€ et 20€

SELECT titre, prix                          -- titre et prix uniquement
FROM livres                                 -- source : la table "livres"
WHERE prix BETWEEN 10 AND 20;               -- équivalent à prix >= 10 AND prix <= 20


-- ============================================================
-- 9. EXERCICE 7 - Agrégation avec COUNT et GROUP BY
-- ============================================================
-- UTILITÉ : compter le nombre de lignes liées à chaque groupe
-- Combien de livres a écrit chaque auteur ? (triés du plus prolifique au moins)

SELECT a.nom,                               -- nom de l'auteur
       COUNT(l.id) AS nombre_livres         -- nombre de livres liés à cet auteur
FROM auteurs a                              -- table de départ : "auteurs", alias "a"
JOIN livres l ON l.auteur_id = a.id         -- relie chaque livre à son auteur
GROUP BY a.nom                              -- regroupement obligatoire car on utilise COUNT()
ORDER BY nombre_livres DESC;                -- tri décroissant : le plus prolifique en premier


-- ============================================================
-- 10. EXERCICE 8 - CTE (WITH ... AS) + filtre sur agrégat
-- ============================================================
-- UTILITÉ : isoler le calcul (nombre d'emprunts par membre) dans
-- une table temporaire nommée, puis filtrer dessus normalement,
-- sans avoir à répéter COUNT(...) dans un HAVING
-- Trouve les membres ayant emprunté plus de 1 livre

WITH emprunts_par_membre AS (
    -- ÉTAPE 1 : on calcule le nombre d'emprunts par membre, une seule fois
    SELECT m.nom,                           -- nom du membre
           COUNT(e.id) AS nombre_emprunts   -- nombre d'emprunts associés
    FROM emprunts e                         -- table de départ : "emprunts", alias "e"
    JOIN membres m ON e.membre_id = m.id    -- relie chaque emprunt à son membre
    GROUP BY m.nom                          -- regroupement obligatoire car on utilise COUNT()
)
-- ÉTAPE 2 : on réutilise le résultat de la CTE comme une table normale
SELECT * FROM emprunts_par_membre
WHERE nombre_emprunts > 1                   -- filtre : garder seulement plus d'1 emprunt
ORDER BY nombre_emprunts DESC;              -- tri décroissant


-- ============================================================
-- 11. EXERCICE 9 - Rechercher les valeurs vides (IS NULL)
-- ============================================================
-- ⚠️ NULL ne se compare jamais avec "=", toujours avec IS NULL / IS NOT NULL
-- Livres actuellement empruntés et non rendus

SELECT m.nom AS membre,                     -- nom du membre qui a emprunté
       l.titre AS livre,                    -- titre du livre concerné
       e.date_emprunt                       -- date de l'emprunt
FROM emprunts e
JOIN membres m ON e.membre_id = m.id
JOIN livres l ON e.livre_id = l.id
WHERE e.date_retour IS NULL;                -- condition : aucune date de retour renseignée


-- ============================================================
-- 12. EXERCICE 10 - UPDATE avec sous-requêtes
-- ============================================================
-- UTILITÉ : modifier une ligne précise en la ciblant par son nom/titre
-- plutôt que par un id qu'on ne connaît pas forcément par cœur
-- Marquer "Les Misérables" comme rendu pour Sarah Blanc

UPDATE emprunts                             -- on modifie la table "emprunts"
SET date_retour = '2026-08-10'              -- on renseigne la date de retour
WHERE membre_id = (SELECT id FROM membres WHERE nom = 'Sarah Blanc')
                                             -- sous-requête : récupère l'id de Sarah Blanc
  AND livre_id = (SELECT id FROM livres WHERE titre = 'Les Misérables')
                                             -- sous-requête : récupère l'id du livre ciblé
  AND date_retour IS NULL;                  -- sécurité : ne modifier que l'emprunt pas encore rendu

-- Vérification du résultat
SELECT * FROM emprunts
WHERE membre_id = (SELECT id FROM membres WHERE nom = 'Sarah Blanc');


-- ============================================================
-- 13. EXERCICE 11 - ALTER TABLE (ajouter une colonne)
-- ============================================================
-- UTILITÉ : faire évoluer la structure d'une table existante
-- sans perdre les données déjà présentes
-- Ajouter une colonne "genre" à la table livres

ALTER TABLE livres
ADD COLUMN genre VARCHAR(50);               -- nouvelle colonne texte, vide (NULL) par défaut

-- Vérification : la colonne "genre" doit apparaître, vide pour toutes les lignes
SELECT * FROM livres;

-- Bonus : remplir quelques valeurs de test
UPDATE livres SET genre = 'Roman' WHERE titre = 'Les Misérables';
UPDATE livres SET genre = 'Réalisme magique' WHERE titre = 'Cent ans de solitude';

SELECT titre, genre FROM livres;


-- ============================================================
-- LIEN POUR REPRENDRE LA SÉANCE (DB Fiddle)
-- ============================================================
-- ⚠️ Lien à mettre à jour avec le vrai lien /f/... généré via
-- le bouton "Save" de DB Fiddle sur ce projet Bibliothèque
