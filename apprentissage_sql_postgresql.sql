-- ============================================================
-- APPRENTISSAGE SQL / POSTGRESQL - RÉCAPITULATIF
-- Mini-projet : Boutique en ligne (clients, produits, commandes)
-- ============================================================


-- ============================================================
-- 1. CRÉATION DES TABLES
-- ============================================================
-- Règle importante : on crée d'abord les tables "autonomes"
-- (clients, produits), puis la table "de liaison" (commandes)
-- qui dépend des deux autres via des clés étrangères.

-- Table CLIENTS
CREATE TABLE clients (
    id SERIAL PRIMARY KEY,        -- identifiant unique, généré automatiquement
    nom VARCHAR(100) NOT NULL,    -- texte obligatoire (100 caractères max)
    email VARCHAR(100) UNIQUE,    -- texte unique : pas de doublon possible
    ville VARCHAR(50)             -- texte simple, aucune contrainte
);

-- Table PRODUITS
CREATE TABLE produits (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prix NUMERIC(10,2) NOT NULL CHECK (prix > 0),
        -- NUMERIC(10,2) = nombre décimal précis (idéal pour l'argent)
        -- CHECK (prix > 0) = interdit un prix négatif ou nul
    stock INT DEFAULT 0 CHECK (stock >= 0)
        -- DEFAULT 0 = valeur par défaut si non précisée
        -- CHECK (stock >= 0) = interdit un stock négatif
);

-- Table COMMANDES (table de liaison)
CREATE TABLE commandes (
    id SERIAL PRIMARY KEY,
    client_id INT REFERENCES clients(id),
        -- clé étrangère : doit correspondre à un id existant dans "clients"
    produit_id INT REFERENCES produits(id),
        -- clé étrangère : doit correspondre à un id existant dans "produits"
    quantite INT NOT NULL,
    date_commande DATE DEFAULT CURRENT_DATE
        -- si non précisée, prend automatiquement la date du jour
);


-- ============================================================
-- 2. INSERTION DES DONNÉES DE TEST
-- ============================================================

INSERT INTO clients (nom, email, ville) VALUES
('Alice Martin', 'alice@mail.com', 'Nantes'),
('Bob Dupont', 'bob@mail.com', 'Paris'),
('Chloé Bernard', 'chloe@mail.com', 'Lyon'),
('David Roux', 'david@mail.com', 'Nantes');

INSERT INTO produits (nom, prix, stock) VALUES
('Clavier mécanique', 79.90, 15),
('Souris sans fil', 29.50, 30),
('Écran 27 pouces', 249.00, 8),
('Casque audio', 59.99, 20),
('Webcam HD', 45.00, 0);   -- rupture de stock volontaire pour les tests

INSERT INTO commandes (client_id, produit_id, quantite, date_commande) VALUES
(1, 1, 1, '2026-06-01'),   -- Alice commande le Clavier mécanique
(1, 3, 1, '2026-06-01'),   -- Alice commande l'Écran 27 pouces
(2, 2, 2, '2026-06-05'),   -- Bob commande 2x Souris sans fil
(3, 4, 1, '2026-06-10'),   -- Chloé commande le Casque audio
(4, 1, 1, '2026-06-15'),   -- David commande le Clavier mécanique
(2, 4, 1, '2026-06-20');   -- Bob commande le Casque audio


-- ============================================================
-- 3. REQUÊTES DE BASE (SELECT + WHERE)
-- ============================================================

-- UTILITÉ : filtrer une table selon une condition simple
-- Liste tous les clients de Nantes
SELECT * FROM clients WHERE ville = 'Nantes';

-- UTILITÉ : choisir des colonnes précises + condition numérique
-- Liste les produits de moins de 50€
SELECT nom, prix FROM produits WHERE prix < 50;

-- UTILITÉ : identifier les produits à réapprovisionner
-- Produits en rupture de stock
SELECT nom FROM produits WHERE stock = 0;


-- ============================================================
-- 4. JOINTURES (JOIN) - relier plusieurs tables
-- ============================================================
-- UTILITÉ : la table "commandes" ne stocke que des ID.
-- Le JOIN permet de "traduire" ces ID en informations lisibles
-- (nom du client, nom du produit) en les reliant aux autres tables.

SELECT c.nom AS client, p.nom AS produit, co.quantite
FROM commandes co
JOIN clients c ON co.client_id = c.id
JOIN produits p ON co.produit_id = p.id;


-- ============================================================
-- 5. AGRÉGATION (SUM, GROUP BY, ORDER BY)
-- ============================================================
-- UTILITÉ : calculer des statistiques par groupe
-- (ex : montant total dépensé par client) - typique d'un tableau de bord

SELECT c.nom, SUM(p.prix * co.quantite) AS total_depense
FROM commandes co
JOIN clients c ON co.client_id = c.id
JOIN produits p ON co.produit_id = p.id
GROUP BY c.nom
ORDER BY total_depense DESC;


-- ============================================================
-- 6. TESTER LES CONTRAINTES CHECK
-- ============================================================
-- UTILITÉ : vérifier que PostgreSQL empêche bien les données
-- incohérentes (prix négatif, stock négatif)

-- Insertion valide (doit fonctionner)
INSERT INTO produits (nom, prix, stock) VALUES
('Tapis de souris', 12.90, 25);

SELECT * FROM produits;

-- Insertion invalide : prix négatif (doit ÉCHOUER à cause du CHECK)
-- INSERT INTO produits (nom, prix, stock) VALUES
-- ('Produit invalide', -10.00, 5);

-- Insertion invalide : stock négatif (doit ÉCHOUER à cause du CHECK)
-- INSERT INTO produits (nom, prix, stock) VALUES
-- ('Autre produit', 15.00, -3);


-- ============================================================
-- 7. UPDATE - modifier des données existantes
-- ============================================================
-- ⚠️ Toujours utiliser WHERE, sinon TOUTES les lignes sont modifiées

UPDATE produits
SET stock = 50
WHERE nom = 'Tapis de souris';

SELECT * FROM produits;


-- ============================================================
-- 8. DELETE - supprimer des données
-- ============================================================
-- ⚠️ Toujours utiliser WHERE, sinon TOUTE la table est vidée

-- DELETE FROM produits
-- WHERE nom = 'Produit invalide';


-- ============================================================
-- 9. DISTINCT - éliminer les doublons
-- ============================================================
-- UTILITÉ : voir les valeurs uniques d'une colonne

SELECT DISTINCT ville FROM clients;


-- ============================================================
-- 10. LIKE / ILIKE - recherche approximative sur du texte
-- ============================================================
-- % = n'importe quelle suite de caractères
-- LIKE est sensible à la casse, ILIKE ne l'est pas

-- Clients dont le nom commence par "A"
SELECT * FROM clients WHERE nom LIKE 'A%';

-- Même recherche, insensible à la casse (majuscule/minuscule)
SELECT * FROM clients WHERE nom ILIKE 'a%';

-- Emails qui finissent par "mail.com"
SELECT * FROM clients WHERE email LIKE '%mail.com';


-- ============================================================
-- 11. IN et BETWEEN - simplifier plusieurs conditions
-- ============================================================

-- Clients de Nantes OU Paris
SELECT * FROM clients WHERE ville IN ('Nantes', 'Paris');

-- Produits entre 20€ et 60€
SELECT * FROM produits WHERE prix BETWEEN 20 AND 60;


-- ============================================================
-- 12. LIMIT - limiter le nombre de résultats
-- ============================================================

-- Les 3 produits les plus chers
SELECT * FROM produits ORDER BY prix DESC LIMIT 3;


-- ============================================================
-- 13. LEFT JOIN - inclure les lignes sans correspondance
-- ============================================================
-- UTILITÉ : contrairement à JOIN, affiche TOUS les clients,
-- même ceux qui n'ont jamais passé de commande (NULL sinon)

SELECT c.nom, co.id AS commande_id
FROM clients c
LEFT JOIN commandes co ON c.id = co.client_id;


-- ============================================================
-- 14. HAVING - filtrer après un GROUP BY
-- ============================================================
-- UTILITÉ : WHERE filtre AVANT le regroupement,
-- HAVING filtre APRÈS (sur le résultat d'une fonction comme SUM)

SELECT c.nom, SUM(p.prix * co.quantite) AS total_depense
FROM commandes co
JOIN clients c ON co.client_id = c.id
JOIN produits p ON co.produit_id = p.id
GROUP BY c.nom
HAVING SUM(p.prix * co.quantite) > 50;


-- ============================================================
-- 15. ALTER TABLE - modifier la structure d'une table existante
-- ============================================================
-- UTILITÉ : ajouter une colonne après coup, sans tout recréer

ALTER TABLE clients ADD COLUMN telephone VARCHAR(20);

SELECT * FROM clients;
