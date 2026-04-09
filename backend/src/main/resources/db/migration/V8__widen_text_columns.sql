-- Migration V8 : Élargissement des colonnes texte long (VARCHAR(255) → TEXT)
-- Fixes: "value too long for type character varying(255)" lors de la création de commandes/transports

-- commandes
ALTER TABLE commandes ALTER COLUMN lien_produit            TYPE TEXT;
ALTER TABLE commandes ALTER COLUMN description_commande    TYPE TEXT;
ALTER TABLE commandes ALTER COLUMN notes_speciales         TYPE TEXT;
ALTER TABLE commandes ALTER COLUMN adresse_livraison       TYPE TEXT;

-- transports
ALTER TABLE transports ALTER COLUMN description            TYPE TEXT;
ALTER TABLE transports ALTER COLUMN adresse_expediteur     TYPE TEXT;
ALTER TABLE transports ALTER COLUMN adresse_destinataire   TYPE TEXT;
ALTER TABLE transports ALTER COLUMN types_marchandise      TYPE TEXT;
