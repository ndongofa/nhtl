-- Migration V9 : Élargissement des colonnes texte long dans achats (VARCHAR(255) → TEXT)
-- Fixes: "value too long for type character varying(255)" lors de la création d'achats

-- achats
ALTER TABLE achats ALTER COLUMN adresse_livraison   TYPE TEXT;
ALTER TABLE achats ALTER COLUMN description_achat   TYPE TEXT;
ALTER TABLE achats ALTER COLUMN notes_speciales     TYPE TEXT;
