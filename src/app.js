const express = require("express");
const path = require("path");
const products = require("./data/products");
const promoCodes = require("./data/promos");

// Crée une nouvelle application avec un panier vide.
// Une fonction plutôt qu'une variable globale : chaque test part d'un état propre.
function createApp() {
  const app = express();
  const cart = new Map(); // productId -> quantity
  const appliedCodes = []; // codes promo appliqués

  app.use(express.json());
  app.use(express.static(path.join(__dirname, "..", "public")));

  // Vérification de santé (utile plus tard pour Docker et la CI)
  app.get("/health", (req, res) => {
    res.json({ status: "ok" });
  });

	  // Frais de livraison : /api/delivery?city=Rabat
  const deliveryFees = require("./data/delivery");
  app.get("/api/delivery", (req, res) => {
    const fee = deliveryFees[req.query.city];
    if (fee === undefined) {
      return res.status(404).json({ error: "Ville non desservie" });
    }
    res.json({ city: req.query.city, fee });
  });


  // Catalogue, avec filtre optionnel par catégorie : /api/products?category=Poterie
  app.get("/api/products", (req, res) => {
    const { category } = req.query;
    const result = category
      ? products.filter((p) => p.category.toLowerCase() === String(category).toLowerCase())
      : products;
    res.json(result);
  });

  // Fiche produit
  app.get("/api/products/:id", (req, res) => {
    const product = products.find((p) => p.id === Number(req.params.id));
    if (!product) {
      return res.status(404).json({ error: "Produit introuvable" });
    }
    res.json(product);
  });

  // Contenu du panier avec le total
  function cartSummary() {
    const items = [...cart.entries()].map(([productId, quantity]) => {
      const product = products.find((p) => p.id === productId);
      return {
        productId,
        name: product.name,
        unitPrice: product.price,
        quantity,
        subtotal: product.price * quantity
      };
    });
    const subtotal = items.reduce((sum, item) => sum + item.subtotal, 0);
    let total = subtotal;
    for (const code of appliedCodes) total = total * (1 - promoCodes[code]);
    return { items, subtotal, codes: appliedCodes, total: Math.round(total * 100) / 100 };
  }

  app.get("/api/cart", (req, res) => {
    res.json(cartSummary());
  });

  // Ajouter un produit au panier : { "productId": 1, "quantity": 2 }
  app.post("/api/cart", (req, res) => {
    const productId = Number(req.body.productId);
    const quantity = req.body.quantity === undefined ? 1 : Number(req.body.quantity);

    const product = products.find((p) => p.id === productId);
    if (!product) {
      return res.status(404).json({ error: "Produit introuvable" });
    }
    if (!Number.isInteger(quantity) || quantity < 1) {
      return res.status(400).json({ error: "La quantité doit être un entier positif" });
    }

    const newQuantity = (cart.get(productId) || 0) + quantity;
    if (newQuantity > product.stock) {
      return res.status(400).json({ error: "Stock insuffisant" });
    }

    cart.set(productId, newQuantity);
    res.status(201).json(cartSummary());
  });

  // Retirer un produit du panier
  app.delete("/api/cart/:productId", (req, res) => {
    const productId = Number(req.params.productId);
    if (!cart.has(productId)) {
      return res.status(404).json({ error: "Ce produit n'est pas dans le panier" });
    }
    cart.delete(productId);
    res.json(cartSummary());
  });

  // Appliquer un code promo : { "code": "RAMADAN20" }
  app.post("/api/cart/promo", (req, res) => {
    const code = String(req.body.code || "").toUpperCase();
    if (promoCodes[code] === undefined) {
      return res.status(400).json({ error: "Code promo invalide" });
    }
    appliedCodes.push(code);
    res.json(cartSummary());
  });

  return app;
}

module.exports = createApp;