PORT ?= 3000
NPM ?= npm
NODE ?= node
URL ?= http://localhost:$(PORT)
APP := artishop
VERSION := $(shell $(NODE) -p "require('./package.json').version")
DIST := dist
ARCHIVE := $(DIST)/$(APP)-$(VERSION).tar.gz
SRC := $(wildcard src/*.js src/data/*.js public/*)

ifeq ($(CI), true)
    INSTALL_CMD := $(NPM) ci
else
    INSTALL_CMD := $(NPM) install
endif

.PHONY: help install start dev test clean health package start-bg stop status restart ci

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*## "}; {printf " make %-10s %s\n", $$1, $$2}'

node_modules: package.json package-lock.json
	$(INSTALL_CMD)
	@touch $@

install: node_modules ## Installe les dépendances

start: node_modules ## Lance le serveur en mode normal
	PORT=$(PORT) $(NPM) start

dev: node_modules ## Lance le serveur en mode développement
	PORT=$(PORT) $(NPM) run dev

test: node_modules ## Lance les tests automatiques
	$(NPM) test

clean: ## Supprime le dossier dist et les logs
	rm -rf dist *.log

health: ## Vérifie que le site répond
	@curl -fsS $(URL)/health || (echo "ArtiShop ne répond pas sur $(PORT)" && exit 1)

$(DIST):
	mkdir -p $@

$(ARCHIVE): $(SRC) package.json package-lock.json README.md | $(DIST)
	tar -czf $@ src public package.json package-lock.json README.md

package: $(ARCHIVE) ## Crée l'archive de livraison

start-bg: node_modules ## Lance le serveur en arrière-plan
	@kill -0 $$(cat .artishop.pid 2>/dev/null) 2>/dev/null && echo "Serveur deja lance" || (PORT=$(PORT) $(NODE) src/server.js > artishop.log 2>&1 & echo $$! > .artishop.pid)

stop: ## Arrête le serveur en arrière-plan
	@kill $$(cat .artishop.pid 2>/dev/null) 2>/dev/null && rm -f .artishop.pid || echo "Serveur deja arrete"

status: ## Indique si le serveur tourne
	@kill -0 $$(cat .artishop.pid 2>/dev/null) 2>/dev/null && echo "Serveur en cours" || echo "Serveur arrete"

restart: ## Redémarre le serveur
	$(MAKE) stop
	$(MAKE) start-bg

ci: ## Cible pour l'intégration continue
	$(MAKE) CI=true install test package