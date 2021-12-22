-- Structuration de la base de données ODF 
-- composer en plusieurs tables dans différents schémas : 

--------------------------------------------------
-- SCHEMA src_survey ----------------------------
--------------------------------------------------
CREATE SCHEMA IF NOT EXISTS src_survey;

-- cor_tab_utilisateur
----------------------------------------------------
 CREATE TABLE IF NOT EXISTS src_survey.cor_tab_utilisateur
(
    id_tab_personne INT PRIMARY KEY NOT NULL,
    id_info_generale INT NOT NULL,
    id_utilisateur INT NOT NULL,
    role_personne VARCHAR(255) --  nomenclature 1 : initiateur, 2 : bénévoles, 3 : organisateurs, ... 
);
-- INFO PERSONNE 
---------------------------------------------------
 CREATE TABLE IF NOT EXISTS src_survey.tab_utilisateur
(
    id_utilisateur INT PRIMARY KEY NOT NULL,
    nom VARCHAR(100),
    prenom VARCHAR(100),
    email VARCHAR(255),
    tel VARCHAR(20),
    date_naissance DATE,
    pays VARCHAR(255),
    ville VARCHAR(255),
    code_postal VARCHAR(5)
);

-- TAB OBS 
---------------------------------------------------
 CREATE TABLE IF NOT EXISTS src_survey.cor_tab_detail
(
    id_tab_detail INT PRIMARY KEY NOT NULL,
    id_info_generale INT,
    id_info_detail INT,
    commentaire_speficique VARCHAR(255)  
);

-- INFO OBS 
---------------------------------------------------
 CREATE TABLE IF NOT EXISTS src_survey.info_detail
(
    id_info_detail INT PRIMARY KEY NOT NULL,
    valeur FLOAT NOT NULL,
    type_valeur VARCHAR(100) NOT NULL, -- nomenclature 1 : double, 2 : entier, 3 : pourcentage, ... 
    unite VARCHAR(255) NOT NULL,
    info_commentaire VARCHAR(255)
);

-- DATA SYNTHESE
---------------------------------------------------
 CREATE TABLE IF NOT EXISTS src_survey.info_generale
(
    id_info_generale INT PRIMARY KEY NOT NULL,
    date_debut DATE,
    date_fin DATE,
    cd_nom INT NOT NULL,
    id_area INT NOT NULL,
    id_fiabilite INT NOT NULL,
    protocole VARCHAR(255),
    methode VARCHAR(255),
    source_jdd VARCHAR(255), -- INT NOT NULL
    autre_info TEXT -- format JSON
);

-- FIABILITE
---------------------------------------------------
 CREATE TABLE IF NOT EXISTS src_survey.info_fiabilite
(
    id_fiabilite INT PRIMARY KEY NOT NULL,
    Verification VARCHAR(100),
    Indicateur VARCHAR(100)
);


-- GRAPHIQUE_INFO
---------------------------------------------------
 CREATE TABLE IF NOT EXISTS src_survey.info_graph
(
    id_graph INT PRIMARY KEY NOT NULL,
    id_jdd INT NOT NULL, --id_jdd VARCHAR(255),
    unite VARCHAR(255),
    type_graph VARCHAR(255),
    phenologie PHENOLOGY_PERIOD, 
    information_graph VARCHAR(255),
    description VARCHAR(255)
);

-- AJOUT DES CONTRAINTES ET CLES ETRANGERES
--------------------------------------------------
ALTER TABLE src_survey.info_generale
ADD CONSTRAINT fk_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom);
ALTER TABLE src_survey.info_generale
ADD CONSTRAINT fk_id_area FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area);
ALTER TABLE src_survey.info_generale
ADD CONSTRAINT fk_id_fiabilite FOREIGN KEY (id_fiabilite) REFERENCES src_survey.info_fiabilite(id_fiabilite);
--ALTER TABLE src_survey.info_generale
--CONSTRAINT DATE FIN > DATE DEBUT 

ALTER TABLE src_survey.cor_tab_utilisateur
ADD CONSTRAINT fk_id_personne FOREIGN KEY (id_utilisateur) REFERENCES src_survey.tab_utilisateur(id_utilisateur);
ALTER TABLE src_survey.cor_tab_utilisateur
ADD CONSTRAINT fk_id_info_generale FOREIGN KEY (id_info_generale) REFERENCES src_survey.info_generale(id_info_generale);


ALTER TABLE src_survey.cor_tab_detail
ADD CONSTRAINT fk_id_info_generale FOREIGN KEY (id_info_generale) REFERENCES src_survey.info_generale(id_info_generale);
ALTER TABLE src_survey.cor_tab_detail
ADD CONSTRAINT fk_id_obs FOREIGN KEY (id_info_detail) REFERENCES src_survey.info_detail(id_info_detail);


--------------------------------------------------
-- SCHEMA issue de géonature ---------------------
--------------------------------------------------
-- TAXREF 
-- REF GEO 

