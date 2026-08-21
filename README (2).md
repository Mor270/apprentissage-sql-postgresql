# 🐘 Apprentissage SQL & PostgreSQL

> Mon parcours d'apprentissage de SQL sur PostgreSQL, construit à travers des mini-projets pratiques et documentés — de la création de tables aux CTE et fonctions de fenêtrage.

![SQL](https://img.shields.io/badge/SQL-PostgreSQL-336791?style=flat-square&logo=postgresql&logoColor=white)
![Status](https://img.shields.io/badge/status-en%20cours-brightgreen?style=flat-square)
![Niveau](https://img.shields.io/badge/niveau-d%C3%A9butant%20%E2%86%92%20interm%C3%A9diaire-blue?style=flat-square)

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
- [ ] Fonctions de fenêtrage (`OVER`, `PARTITION BY`, `RANK`)
- [ ] Sous-requêtes avancées
- [ ] Index et performance
- [ ] Transactions (`BEGIN`, `COMMIT`, `ROLLBACK`)
- [ ] Types avancés PostgreSQL (`JSONB`, `ARRAY`)
- [ ] Vues (`CREATE VIEW`)

---

## 📌 Note

Ces scripts sont écrits dans un but pédagogique : chaque commande est accompagnée d'un commentaire expliquant **ce qu'elle fait** et **pourquoi** elle est utilisée à cet endroit. L'objectif n'est pas la performance, mais la compréhension pas à pas des mécanismes SQL.

---

<div align="center">
  <i>🚧 Dépôt mis à jour au fil de l'apprentissage 🚧</i>
</div>
