/*
AREA KNOWLEDGE LIST TAXA
------------------------
Evaluate for each area and each season  knowledge level comparing old taxa count with new taxa count

ACTUAL TIME : 24minutes to create, too long...
 */
DO $$
BEGIN
    RAISE NOTICE 'INFO: (RE)CREATE MV atlas mv_area_knowledge_list_taxa';

    /* function to retrieve nomenclature value and hierarchy */
    CREATE OR REPLACE FUNCTION ref_nomenclatures.fct_c_nomenclature_value_from_hierarchy (_hierarchy varchar, _type_mnemonique text, _column text )
        RETURNS text AS $func$
DECLARE
    the_value text;
BEGIN
    EXECUTE format('SELECT  tn.%I  FROM ref_nomenclatures.t_nomenclatures tn ' || 'join ref_nomenclatures.bib_nomenclatures_types bnt on tn.id_type = bnt.id_type ' || 'where bnt.mnemonique like $1 and tn.hierarchy=$2', _column)
    USING _type_mnemonique, _hierarchy INTO the_value;
    RETURN the_value;
END $func$
LANGUAGE plpgsql;
    CREATE INDEX IF NOT EXISTS i_synthese_datemin_newatlas ON gn_synthese.synthese (date_min DESC NULLS LAST)
    WHERE
        synthese.date_min > '2019-01-31'::date;
    CREATE INDEX IF NOT EXISTS i_synthese_datemin_oldatlas ON gn_synthese.synthese (date_min DESC NULLS LAST)
    WHERE
        synthese.date_min <= '2019-01-31'::date;
    DROP MATERIALIZED VIEW IF EXISTS atlas.mv_area_knowledge_list_taxa;
    -- some minimum date
    /* Materialized view to list all taxa in area */
    CREATE MATERIALIZED VIEW atlas.mv_area_knowledge_list_taxa AS
    WITH atlas_code AS (
        /* Liste des codes nidif VisioNature */
        SELECT
            cd_nomenclature::int,
            hierarchy::int
        FROM
            ref_nomenclatures.t_nomenclatures n
            JOIN ref_nomenclatures.bib_nomenclatures_types t ON n.id_type = t.id_type
        WHERE
            t.mnemonique LIKE 'VN_ATLAS_CODE'
),
names AS (
    SELECT
        t_taxa.cd_nom,
        max(
            CASE WHEN (bib_attributs.nom_attribut = 'odf_common_name_fr') THEN
                cor_taxon_attribut.valeur_attribut
            ELSE
                split_part(taxref.nom_vern, ',', 1)
            END) AS common_name_fr,
        max(
            CASE WHEN (bib_attributs.nom_attribut = 'odf_common_name_en') THEN
                cor_taxon_attribut.valeur_attribut
            ELSE
                split_part(taxref.nom_vern_eng, ',', 1)
            END) AS common_name_en,
        max(
            CASE WHEN (bib_attributs.nom_attribut = 'odf_sci_name') THEN
                cor_taxon_attribut.valeur_attribut
            ELSE
                taxref.lb_nom
            END) AS sci_name
    FROM
        atlas.t_taxa
        JOIN taxonomie.taxref ON t_taxa.cd_nom = taxref.cd_nom
        LEFT JOIN taxonomie.cor_taxon_attribut ON taxref.cd_ref = cor_taxon_attribut.cd_ref
        LEFT JOIN taxonomie.bib_attributs ON cor_taxon_attribut.id_attribut = bib_attributs.id_attribut
    GROUP BY
        t_taxa.cd_nom
)
SELECT
    data.id_area,
    CASE WHEN t_taxa.has_subsp THEN
        t_taxa.cd_sp
    ELSE
        t_taxa.cd_nom
    END AS cd_nom,
    names.common_name_fr,
    names.common_name_en,
    names.sci_name,
    count(id_data) FILTER (WHERE old_data_all_period) AS all_period_count_data_old,
    count(id_data) FILTER (WHERE new_data_all_period) AS all_period_count_data_new,
    extract(YEAR FROM max(data.date_min)) AS all_period_last_obs,
    count(id_data) FILTER (WHERE new_data_breeding) AS breeding_count_data_new,
    ref_nomenclatures.fct_c_nomenclature_value_from_hierarchy ((max(ac.hierarchy) FILTER (WHERE new_data_breeding))::text, 'VN_ATLAS_CODE', 'label_default') AS breeding_status_new,
    count(id_data) FILTER (WHERE old_data_breeding) AS breeding_count_data_old,
    extract(YEAR FROM (max(data.date_min) FILTER (WHERE bird_breed_code IS NOT NULL))) AS breeding_last_obs,
    ref_nomenclatures.fct_c_nomenclature_value_from_hierarchy ((max(ac.hierarchy) FILTER (WHERE old_data_breeding))::text, 'VN_ATLAS_CODE', 'label_default') AS breeding_status_old,
    count(id_data) FILTER (WHERE old_data_wintering) AS wintering_count_data_old,
    count(id_data) FILTER (WHERE new_data_wintering) AS wintering_count_data_new,
    extract(YEAR FROM (max(data.date_min) FILTER (WHERE old_data_breeding
    OR new_data_wintering))) AS wintering_last_obs
FROM
    atlas.mv_data_for_atlas data
    JOIN atlas.t_taxa ON t_taxa.cd_nom = data.cd_nom
    JOIN names ON t_taxa.cd_nom = names.cd_nom
    LEFT JOIN atlas_code ac ON ac.cd_nomenclature = data.bird_breed_code
GROUP BY
    data.id_area,
    CASE WHEN t_taxa.has_subsp THEN
        t_taxa.cd_sp
    ELSE
        t_taxa.cd_nom
    END,
    names.common_name_fr,
    names.common_name_en,
    names.sci_name;
    COMMENT ON MATERIALIZED VIEW atlas.mv_area_knowledge_list_taxa IS 'Synthèse de l''état des prospection par mailles comparativement à l''atlas précédent';
    CREATE UNIQUE INDEX i_area_knowledge_list_taxa_id_area_cd_nom ON atlas.mv_area_knowledge_list_taxa (id_area, cd_nom);
COMMIT;
END
$$;

