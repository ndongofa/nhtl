-- Migration V3 : Création des tables pour le module e-commerce
-- Tables : achats, produits, commandes_ecommerce, commande_ecommerce_items, panier_items

CREATE TABLE IF NOT EXISTS achats (
    id                  BIGSERIAL PRIMARY KEY,
    user_id             VARCHAR(255) NOT NULL,
    nom                 VARCHAR(255),
    prenom              VARCHAR(255),
    numero_telephone    VARCHAR(255),
    email               VARCHAR(255),
    pays_livraison      VARCHAR(255),
    ville_livraison     VARCHAR(255),
    adresse_livraison   VARCHAR(255),
    marche              VARCHAR(255),
    type_produit        VARCHAR(255),
    description_achat   VARCHAR(255),
    quantite            INTEGER,
    prix_estime         NUMERIC(19, 2),
    prix_total          NUMERIC(19, 2),
    devise              VARCHAR(255),
    notes_speciales     VARCHAR(255),
    statut              VARCHAR(255) DEFAULT 'EN_ATTENTE',
    statut_suivi_achat  VARCHAR(255) NOT NULL DEFAULT 'EN_ATTENTE',
    archived            BOOLEAN      NOT NULL DEFAULT FALSE,
    gp_id               BIGINT,
    gp_prenom           VARCHAR(255),
    gp_nom              VARCHAR(255),
    gp_phone_number     VARCHAR(255),
    date_creation       TIMESTAMP,
    date_modification   TIMESTAMP,
    photo_colis_url     VARCHAR(255),
    photo_bordereau_url VARCHAR(255),
    numero_bordereau    VARCHAR(100),
    depose_poste_at     TIMESTAMP
);

CREATE TABLE IF NOT EXISTS produits (
    id                BIGSERIAL PRIMARY KEY,
    service_type      VARCHAR(255) NOT NULL,
    nom               VARCHAR(255) NOT NULL,
    description       TEXT,
    prix              NUMERIC(12, 2) NOT NULL,
    devise            VARCHAR(255) DEFAULT 'EUR',
    categorie         VARCHAR(255),
    image_url         TEXT,
    stock             INTEGER      NOT NULL DEFAULT 0,
    unite             VARCHAR(255),
    actif             BOOLEAN      NOT NULL DEFAULT TRUE,
    date_ajout        TIMESTAMP,
    date_modification TIMESTAMP
);

CREATE TABLE IF NOT EXISTS commandes_ecommerce (
    id                BIGSERIAL PRIMARY KEY,
    user_id           VARCHAR(255) NOT NULL,
    nom               VARCHAR(255),
    prenom            VARCHAR(255),
    numero_telephone  VARCHAR(255),
    email             VARCHAR(255),
    pays_livraison    VARCHAR(255),
    ville_livraison   VARCHAR(255),
    adresse_livraison VARCHAR(255),
    service_type      VARCHAR(255) NOT NULL,
    prix_total        NUMERIC(12, 2) NOT NULL DEFAULT 0,
    devise            VARCHAR(255) DEFAULT 'EUR',
    statut            VARCHAR(255) NOT NULL DEFAULT 'EN_ATTENTE',
    archived          BOOLEAN      NOT NULL DEFAULT FALSE,
    notes_speciales   VARCHAR(255),
    date_commande     TIMESTAMP,
    date_modification TIMESTAMP
);

CREATE TABLE IF NOT EXISTS commande_ecommerce_items (
    id                    BIGSERIAL PRIMARY KEY,
    commande_ecommerce_id BIGINT         NOT NULL REFERENCES commandes_ecommerce (id),
    produit_id            BIGINT         NOT NULL,
    produit_nom           VARCHAR(255),
    quantite              INTEGER        NOT NULL,
    prix_unitaire         NUMERIC(12, 2) NOT NULL,
    sous_total            NUMERIC(12, 2) NOT NULL,
    devise                VARCHAR(255) DEFAULT 'EUR'
);

CREATE TABLE IF NOT EXISTS panier_items (
    id            BIGSERIAL PRIMARY KEY,
    user_id       VARCHAR(255)   NOT NULL,
    produit_id    BIGINT         NOT NULL,
    service_type  VARCHAR(255)   NOT NULL,
    quantite      INTEGER        NOT NULL DEFAULT 1,
    prix_unitaire NUMERIC(12, 2) NOT NULL,
    devise        VARCHAR(255) DEFAULT 'EUR',
    date_ajout    TIMESTAMP,
    CONSTRAINT uq_panier_user_produit UNIQUE (user_id, produit_id)
);
