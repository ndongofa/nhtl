-- Migration V1 : Schéma initial
-- Tables de base : commandes, transports, notifications, gp_agents, departures

CREATE TABLE IF NOT EXISTS commandes (
    id                      BIGSERIAL    PRIMARY KEY,
    user_id                 VARCHAR(255) NOT NULL,
    nom                     VARCHAR(255),
    prenom                  VARCHAR(255),
    numero_telephone        VARCHAR(255),
    email                   VARCHAR(255),
    pays_livraison          VARCHAR(255),
    ville_livraison         VARCHAR(255),
    adresse_livraison       VARCHAR(255),
    plateforme              VARCHAR(255),
    lien_produit            VARCHAR(255),
    liens_produits          TEXT,
    photos_produits         TEXT,
    articles_json           TEXT,
    description_commande    VARCHAR(255),
    quantite                INTEGER,
    prix_unitaire           NUMERIC(19, 2),
    prix_total              NUMERIC(19, 2),
    devise                  VARCHAR(255),
    notes_speciales         VARCHAR(255),
    statut                  VARCHAR(255) DEFAULT 'EN_ATTENTE',
    statut_suivi_commande   VARCHAR(255) NOT NULL DEFAULT 'EN_ATTENTE',
    archived                BOOLEAN      NOT NULL DEFAULT FALSE,
    gp_id                   BIGINT,
    gp_prenom               VARCHAR(255),
    gp_nom                  VARCHAR(255),
    gp_phone_number         VARCHAR(255),
    date_creation           TIMESTAMP,
    date_modification       TIMESTAMP,
    photo_colis_url         VARCHAR(255),
    photo_bordereau_url     VARCHAR(255),
    numero_bordereau        VARCHAR(100),
    depose_poste_at         TIMESTAMP
);

CREATE TABLE IF NOT EXISTS transports (
    id                   BIGSERIAL    PRIMARY KEY,
    user_id              VARCHAR(255) NOT NULL,
    nom                  VARCHAR(255),
    prenom               VARCHAR(255),
    numero_telephone     VARCHAR(255),
    email                VARCHAR(255),
    point_depart         VARCHAR(255),
    point_arrivee        VARCHAR(255),
    pays_expediteur      VARCHAR(255),
    ville_expediteur     VARCHAR(255),
    adresse_expediteur   VARCHAR(255),
    pays_destinataire    VARCHAR(255),
    ville_destinataire   VARCHAR(255),
    adresse_destinataire VARCHAR(255),
    types_marchandise    VARCHAR(255),
    description          VARCHAR(255),
    poids                NUMERIC(19, 2),
    valeur_estimee       NUMERIC(19, 2),
    devise               VARCHAR(255),
    statut               VARCHAR(255),
    statut_suivi         VARCHAR(255) NOT NULL DEFAULT 'EN_ATTENTE',
    type_transport       VARCHAR(255),
    gp_id                BIGINT,
    gp_prenom            VARCHAR(255),
    gp_nom               VARCHAR(255),
    gp_phone_number      VARCHAR(255),
    archived             BOOLEAN      NOT NULL DEFAULT FALSE,
    date_creation        TIMESTAMP,
    date_modification    TIMESTAMP,
    photo_colis_url      VARCHAR(255),
    photo_bordereau_url  VARCHAR(255),
    numero_bordereau     VARCHAR(100),
    depose_poste_at      TIMESTAMP
);

CREATE TABLE IF NOT EXISTS notifications (
    id         BIGSERIAL    PRIMARY KEY,
    user_id    VARCHAR(255) NOT NULL,
    type       VARCHAR(255) NOT NULL,
    title      VARCHAR(255) NOT NULL,
    message    TEXT,
    is_read    BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS gp_agents (
    id           BIGSERIAL    PRIMARY KEY,
    prenom       VARCHAR(255) NOT NULL,
    nom          VARCHAR(255) NOT NULL,
    phone_number VARCHAR(255),
    email        VARCHAR(255),
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP,
    updated_at   TIMESTAMP
);

CREATE TABLE IF NOT EXISTS departures (
    id                    BIGSERIAL    PRIMARY KEY,
    route                 VARCHAR(255) NOT NULL,
    point_depart          VARCHAR(255) NOT NULL,
    point_arrivee         VARCHAR(255) NOT NULL,
    flag_emoji            VARCHAR(255) NOT NULL,
    departure_date_time   TIMESTAMP    NOT NULL,
    status                VARCHAR(255) NOT NULL DEFAULT 'DRAFT',
    created_at            TIMESTAMP,
    updated_at            TIMESTAMP
);
