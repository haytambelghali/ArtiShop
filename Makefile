PORT ?= 3000
NPM := npm
NODE := node
URL := http://localhost:$(PORT)

APP := artishop
VERSION := $(shell $(NODE) -p "require('./package.json').version")
DIST := dist
ARCHIVE := $(DIST)/$(APP)-$(VERSION).tar.gz
SRC := $(wildcard src/*.js src/data/*.js public/*)

ifeq ($(CI),true)
INSTALL_CMD := $(NPM) ci
else
INSTALL_CMD := $(NPM) install
endif

.PHONY: help install start dev test clean health package start-bg stop status restart ci

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*## "}; {printf "  make %-10s %s\n", $$1, $$2}'

node_modules: package.json package-lock.json
	$(INSTALL_CMD)
	@touch $@

install: node_modules ## Installe les dépendances

start: node_modules ## Démarre le serveur
	PORT=$(PORT) $(NPM) start

dev: node_modules ## Démarre le serveur en mode développement
	PORT=$(PORT) $(NPM) run dev

test: node_modules ## Lance les tests
	$(NPM) test

clean: ## Supprime les artefacts générés
	rm -rf dist *.log

health: ## Vérifie que le serveur répond
	@curl -fsS $(URL)/health || (echo ArtiShop ne répond pas sur $(URL) && exit 1)

$(DIST):
	mkdir -p $@

$(ARCHIVE): $(SRC) package.json package-lock.json README.md | $(DIST)
	tar -czf $@ src public package.json package-lock.json README.md

package: $(ARCHIVE) ## Crée l'archive de livraison

start-bg: node_modules ## Démarre le serveur en arrière-plan
	@if test -f .artishop.pid && kill -0 $$(cat .artishop.pid) 2>/dev/null; then \
		echo "ArtiShop tourne déjà (PID $$(cat .artishop.pid))"; \
		exit 1; \
	fi
	PORT=$(PORT) $(NODE) src/server.js > artishop.log 2>&1 & echo $$! > .artishop.pid

stop: ## Arrête le serveur
	@if test -f .artishop.pid; then \
		kill $$(cat .artishop.pid) 2>/dev/null || true; \
		rm -f .artishop.pid; \
		echo "ArtiShop arrêté"; \
	else \
		echo "ArtiShop n'est pas lancé"; \
	fi

status: ## Indique l'état du serveur
	@if test -f .artishop.pid && kill -0 $$(cat .artishop.pid) 2>/dev/null; then \
		echo "ArtiShop tourne (PID $$(cat .artishop.pid))"; \
	else \
		echo "ArtiShop est arrêté"; \
	fi

restart: ## Redémarre le serveur
	$(MAKE) stop
	$(MAKE) start-bg PORT=$(PORT)

ci: ## Lance l'installation CI, les tests et le packaging
	$(MAKE) CI=true install test package