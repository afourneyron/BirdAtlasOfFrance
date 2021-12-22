-- CREATION D'UNE VM POUR QUE l'API DE ODF PUISSENT GENERER LES GRAPHIQUES
-- dans les preparations plusieurs étapes : 
-- reg_atlas permet de receuillir les territoires nécéssaires a l'atlas
-- prep_tab_general rassemble l'ensemble des données avec les différentes informations de dénombrement rattaché (nombre de jeunes a l'envol, effectifs, ...)
-- tab_value_nb extrait uniquement les informations dénombrement dont la valeur est fixe
-- tab_value_min extrait uniquement les informations dénombrement dont la valeur est un effectif minimum
-- tab_value_max extrait uniquement les informations dénombrement dont la valeur est un effectif maximum
-- tab_unique_nb duplique l'information générale pour chaque unité disctinct associé (Couple, individu, Jeunes, ...)
-- tab_final permet d'assembler pour a tab_unique_nb les valeurs min, max et value sous forme de colonne
-- Enfin sur la selection final de la vue on viens agréger l'ensemble de ses informations par territoire d'atlas pour les graphiques attendues (table src_survey.info_graph) en pensant a bien validé la condition d'unité
create materialized view src_survey.vm_graph_information as (
with reg_atlas 		  as (	select * from ref_geo.l_areas la 
							where la.id_type = 44
							and la.id_area in (87141,87140,87150,87149,87155,87144,87151,87154,87152,87153,87148,87147,87142)), --87145 france metro
							-- possibilité de prendre que certain territoire ?
	 all_info_detail  as (	select * from src_survey.cor_tab_detail ctd 
							inner join src_survey.info_detail id on ctd.id_info_detail = id.id_info_detail),
	 prep_tab_general as (	select ig.*, aid.valeur, aid.type_valeur, aid.unite from src_survey.info_generale ig 
							right join all_info_detail aid on aid.id_info_generale = ig.id_info_generale
							-- where cd_nom = 2844 													-- Selection des milan Royal
							-- and ig.date_debut >= '2018-01-01' and ig.date_fin <= '2018-12-31' 	-- Selection de l'année 2018
							-- and if2.indicateur ilike 'Inconnue'									-- Selcetion uniquement des indicateurs corrects/bon/...
							-- and aid.type_valeur ilike 'Nbr. Oiseaux' 
							-- Possibilité de filter sur certaine entité ?
							),
	tab_value_nb  as ( 	select 	id_info_generale, unite,
								case when type_valeur = 'nombre_unique' then valeur end as val
						from prep_tab_general
						where case when type_valeur = 'nombre_unique' then valeur end is not null),
	tab_value_min as (	select 	id_info_generale, unite,
							 	case when type_valeur = 'min' then valeur end as val_min
						from prep_tab_general
						where case when type_valeur = 'min' then valeur end is not null),
	tab_value_max as (	select 	id_info_generale, unite,
							   	case when type_valeur = 'max' then valeur end as val_max
						from prep_tab_general
						where case when type_valeur = 'max' then valeur end is not null),
	tab_unique_nb as (	select distinct ig.*,aid.unite, la.centroid, la.area_name, if2.* from src_survey.info_generale ig 
							right join all_info_detail aid on aid.id_info_generale = ig.id_info_generale
							inner join ref_geo.l_areas la on la.id_area = ig.id_area 
						inner join src_survey.info_fiabilite if2 on ig.id_fiabilite = if2.id_fiabilite ),														
	tab_final as(		select tun.*, tvn.val, tvmax.val_max , tvmin.val_min
						from tab_unique_nb tun 
						left join tab_value_nb tvn on tvn.id_info_generale = tun.id_info_generale and tvn.unite = tun.unite
						left join tab_value_min tvmin on tvmin.id_info_generale = tun.id_info_generale and tvmin.unite = tun.unite
						left join tab_value_max tvmax on tvmax.id_info_generale = tun.id_info_generale and tvmax.unite = tun.unite
						order by tun.id_info_generale)					
select    tf.source_jdd 
		, ig2.id_jdd 
		, tf.unite as unite_table
		, ig2.unite as unite_graph
		, ig2.type_graph 
		, ra.geom
		, ra.area_name 
		, tf.date_debut
		, tf.date_fin
		--, tf.info_commentaire
		--, ptg.indicateur
		--, ptg.verification
		--, date_part('year', tf.date_debut) as annee 			-- extraction de l'année
		, sum(COALESCE (tf.val,0)) as value						-- sommes des valeurs
		, sum(COALESCE (tf.val_max,0)) as value_min				-- sommes des valeurs
		, sum(COALESCE (tf.val_min,0)) as value_max				-- sommes des valeurs
		, count(*) as nb_data									-- nombre de données
		, count(distinct tf.id_area) as nb_lieux				-- nombre de lieux
		--, string_agg(ptg.area_name, ', ') as list_lieu_obs	-- Liste des lieux recensés
from src_survey.info_graph ig2 
right join tab_final tf on tf.source_jdd = ig2.id_jdd 	
left join reg_atlas ra on ST_Within(tf.centroid, ra.geom) 		-- ajout des références des régions
where ig2.unite =  tf.unite
--and date_part( 'year', tf.date_debut) = 2019
group by tf.source_jdd, ig2.id_jdd , ig2.unite , ig2.type_graph , ra.geom, ra.area_name , tf.unite, tf.date_debut, tf.date_fin );
		

-- pour permettre à la vue de ce fair erequeter par l'API : 
grant select on src_survey.vm_graph_information to odfapp;