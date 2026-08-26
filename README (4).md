# 🐘 Apprentissage SQL & PostgreSQL

> Mon parcours d'apprentissage de SQL sur PostgreSQL, construit à travers des mini-projets pratiques et documentés — de la création de tables aux CTE récursives et fonctions de fenêtrage.

**Mor Talla DIENG** — Data Analyst RH/Finance

![SQL](https://img.shields.io/badge/SQL-PostgreSQL-336791?style=flat-square&logo=postgresql&logoColor=white)
![Status](https://img.shields.io/badge/status-en%20cours-brightgreen?style=flat-square)
![Niveau](https://img.shields.io/badge/niveau-interm%C3%A9diaire%20%E2%86%92%20avanc%C3%A9-blue?style=flat-square)

---

## 👋 À propos

Je découvre SQL et PostgreSQL, et j'ai choisi d'apprendre en construisant — pas en accumulant de la théorie sans jamais la mettre en pratique. Chaque notion abordée ici (jointures, agrégations, CTE, fenêtrage, hiérarchies récursives...) est immédiatement testée sur un jeu de données concret, avec des commentaires détaillés qui expliquent **le raisonnement**, pas seulement la syntaxe — et, pour le projet le plus avancé, le **résultat attendu** de chaque requête.

Ce dépôt n'est pas figé : il grandit au fur et à mesure de mes séances d'apprentissage. Parti des bases début du parcours, j'ai depuis couvert l'ensemble des notions intermédiaires et avancées de PostgreSQL (CTE récursives, fonctions de fenêtrage, transactions, types JSON/tableaux, vues) à travers quatre projets de complexité croissante, dont un projet de synthèse livré en plusieurs formats (SQL, HTML, JSON, PDF).

---

## 🎯 Objectif

Ce dépôt regroupe mes exercices et mini-projets réalisés pour maîtriser SQL sous PostgreSQL — chaque script est **commenté ligne par ligne**, pensé pour être relu et compris facilement, pas juste exécuté.

L'ambition : partir des bases (`SELECT`, `JOIN`, contraintes) jusqu'à des notions plus avancées (CTE, fonctions de fenêtrage, transactions) à travers des cas concrets plutôt que des exemples abstraits.

---

## 📂 Projets

### 🛒 Boutique en ligne
Un schéma classique e-commerce pour pratiquer les fondamentaux relationnels.

**Tables** : `clients`, `produits`, `commandes`

**Notions couvertes** :
- Création de tables, types de données, contraintes (`PRIMARY KEY`, `REFERENCES`, `CHECK`, `UNIQUE`)
- `SELECT`, `WHERE`, `JOIN`, `GROUP BY`, `HAVING`, `ORDER BY`
- `UPDATE`, `DELETE`, `ALTER TABLE`
- `LIKE` / `ILIKE`, `IN`, `BETWEEN`, `DISTINCT`, `LIMIT`
- **CTE** (`WITH ... AS`) — cas d'usage et exemples appliqués

📄 [`boutique/apprentissage_sql_postgresql.sql`](./boutique/apprentissage_sql_postgresql.sql)

---

### 📚 Bibliothèque
Un second schéma pour consolider les mêmes notions dans un contexte différent, avec 11 exercices progressifs.

**Tables** : `auteurs`, `livres`, `membres`, `emprunts`

**Notions couvertes** :
- Jointures à 3 tables
- Agrégation (`COUNT`, `GROUP BY`) et tri
- **CTE** appliquée à un cas réel (membres ayant emprunté plus d'un livre)
- Recherche de valeurs vides (`IS NULL`)
- `UPDATE` ciblé avec sous-requêtes
- Évolution de schéma (`ALTER TABLE ADD COLUMN`)

📄 [`bibliotheque/projet_bibliotheque.sql`](./bibliotheque/projet_bibliotheque.sql)

---

### 🏢 Gestion d'entreprise
Projet de synthèse combinant toutes les notions vues précédemment, sur un schéma avec **deux hiérarchies auto-référencées** (départements imbriqués, employés/managers) — pensé pour aller jusqu'au niveau avancé.

**Tables** : `departements`, `employes`, `projets`, `taches`

**Notions couvertes** :
- **CTE récursive** (`WITH RECURSIVE`) — hiérarchie de départements ET chaîne de management
- Fonctions de fenêtrage (`RANK() OVER (PARTITION BY ...)`, `AVG() OVER`, `SUM() OVER` cumulé)
- Sous-requêtes avancées (`EXISTS`, `NOT EXISTS`, sous-requête scalaire)
- `CASE WHEN` (catégorisation) et `COALESCE()` (valeur de repli sur auto-jointure)
- Fonctions de dates (`AGE()`, soustraction de dates, `DATE_TRUNC()`)
- Types avancés PostgreSQL : `JSONB` (compétences) et `ARRAY` (tags)
- Index sur clés étrangères + vérification avec `EXPLAIN`
- Transactions (`BEGIN` / `COMMIT` / `ROLLBACK`) sur une mise à jour de salaires
- Vues (`CREATE VIEW`) pour un rapport de charge de travail réutilisable

Chaque requête est accompagnée de son **résultat attendu commenté**, pour vérifier sa compréhension sans avoir à ré-exécuter le script.

📄 [`entreprise/projet_entreprise.sql`](./entreprise/projet_entreprise.sql)

---

### 🏛️ Simulation données service public : ADEME
Projet de synthèse le plus complet du dépôt, livré en **4 formats** (SQL, HTML, JSON, PDF), simulant l'instruction et le pilotage financier de dossiers d'aides publiques dans un organisme de type ADEME.

⚠️ **Toutes les données sont fictives** — organismes, agents, montants, dates, SIRET et emails ont été entièrement inventés pour l'exercice. "ADEME" sert uniquement de contexte inspirant un schéma réaliste, pas de source de données réelle.

**Tables** : `categories_aides`, `organismes`, `agents_instructeurs`, `dossiers_aide` (Partie 1) + `enveloppes_budgetaires`, `versements` (Partie 2)

**Notions couvertes (15 exercices, avec objectif explicite pour chacun)** :
- **Partie 1 — gestion des dossiers** : `WITH RECURSIVE` (hiérarchie des catégories d'aides), fonctions de fenêtrage (`RANK`, `AVG OVER`), `CASE WHEN`, `COALESCE`, `EXISTS`/`NOT EXISTS`, `JSONB`/`ARRAY`, index + `EXPLAIN`, transactions (`BEGIN`/`COMMIT`), vue (`CREATE VIEW`)
- **Partie 2 — pilotage financier** : taux d'engagement budgétaire, reste à verser par dossier, cumul progressif des versements (`SUM() OVER`), niveau d'alerte budgétaire (`CASE WHEN` sur ratio), vue de tableau de bord financier (sous-requête corrélée)

Chaque exercice précise son **🎯 objectif** avant la requête, en plus de l'explication et du résultat attendu détaillé.

**Perspectives** : le projet propose 5 KPI de pilotage budgétaire pour aller plus loin (taux d'engagement, délai d'instruction, taux d'acceptation, reste à verser, montant moyen par secteur) — leur exploitation et visualisation étant privilégiée via **Power BI** plutôt que du reporting SQL.

📄 [`service-public-ademe/projet_service_public.sql`](./service-public-ademe/projet_service_public.sql) · [`.json`](./service-public-ademe/projet_service_public.json) · [`.pdf`](./service-public-ademe/projet_service_public.pdf)

---

## 🛠️ Comment tester ces scripts

Aucune installation nécessaire — tout est testable en ligne :

1. Ouvre [DB Fiddle](https://www.db-fiddle.com/)
2. Sélectionne **PostgreSQL** dans le menu déroulant
3. Colle le contenu d'un des scripts `.sql` de ce dépôt
4. Clique sur **Run**

---

## 🗺️ Feuille de route

- [x] Création de tables, types de données, contraintes
- [x] Requêtes de base (`SELECT`, `WHERE`, `JOIN`)
- [x] Agrégation (`GROUP BY`, `HAVING`)
- [x] CTE (`WITH ... AS`)
- [x] Fonctions de fenêtrage (`OVER`, `PARTITION BY`, `RANK`, `ROW_NUMBER`)
- [x] Sous-requêtes avancées (`EXISTS`, `NOT EXISTS`, `IN`)
- [x] Index et performance (`EXPLAIN`)
- [x] Transactions (`BEGIN`, `COMMIT`, `ROLLBACK`)
- [x] Types avancés PostgreSQL (`JSONB`, `ARRAY`)
- [x] Vues (`CREATE VIEW`)
- [x] `CASE WHEN`, `COALESCE`, fonctions de dates
- [x] CTE récursive (`WITH RECURSIVE`)
- [x] Indicateurs financiers dérivés (taux d'engagement, reste à verser, cumul de trésorerie)
- [ ] Fonctions stockées (`CREATE FUNCTION`)
- [ ] Triggers (`CREATE TRIGGER`)
- [ ] `UNION` / `INTERSECT` / `EXCEPT`
- [ ] Vues matérialisées (`MATERIALIZED VIEW`)
- [ ] Gestion des droits (`GRANT` / `REVOKE`)

---

## 📌 Note

Ces scripts sont écrits dans un but pédagogique : chaque commande est accompagnée d'un commentaire expliquant **ce qu'elle fait** et **pourquoi** elle est utilisée à cet endroit. L'objectif n'est pas la performance, mais la compréhension pas à pas des mécanismes SQL.

---

<div align="center">
  <i>🚧 Dépôt mis à jour au fil de l'apprentissage 🚧</i>
</div>
