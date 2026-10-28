# ArtiShop

Boutique en ligne de produits artisanaux marocains. Projet fil rouge du cours DevOps.

## Fonctionnalités

- Catalogue de produits, avec filtre par catégorie
- Fiche produit
- Panier : ajout, suppression, calcul du total, contrôle du stock.

## Prérequis

- Node.js 18 ou plus récent
- Git

## Installation et lancement

```bash
npm install
npm start
```

Puis ouvrir http://localhost:3000 dans le navigateur.

Le port peut être changé avec la variable d'environnement `PORT`.

## Tests

```bash
npm test
```

## API

| Méthode | Route | Description |
|---|---|---|
| GET | `/health` | Vérifie que l'application répond |
| GET | `/api/products` | Liste des produits (`?category=Poterie` pour filtrer) |
| GET | `/api/products/:id` | Détail d'un produit |
| GET | `/api/cart` | Contenu du panier et total |
| GET | /api/delivery?city=Rabat | Frais de livraison pour une ville |
| POST | `/api/cart` | Ajoute un produit : `{ "productId": 1, "quantity": 2 }` |
| DELETE | `/api/cart/:productId` | Retire un produit du panier |

## Structure du projet

```
artishop/
├── public/            # Front : HTML, CSS, JavaScript
├── src/
│   ├── app.js         # Routes de l'API
│   ├── server.js      # Démarrage du serveur
│   └── data/
│       └── products.js
├── test/
│   └── app.test.js
├── .gitignore
├── package.json
└── README.md
```

Le panier est gardé en mémoire : il est vidé à chaque redémarrage du serveur.
Recette QA
Recette(QA)