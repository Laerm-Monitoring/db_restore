
create database laermmonitoring;

-- Setze aktive Datenbank laermmonitoring
\c laermmonitoring

-- Für Umlaute: Unter Windows verwendet psql client Codepage 1252, diese Datei verwendet jedoch UTF8 
\encoding UTF8

CREATE TABLE public."location" (
	id smallserial NOT NULL, -- fest interne id der Messstelle
	name text , -- Name der Messstelle
	dirtrack1 text , -- Fahrtrichtung Gleis 1
	dirtrack2 text , -- Fahrtrichtuing Gleis 2
	CONSTRAINT "PK_location" PRIMARY KEY (id)
);

INSERT INTO public."location" (id, "name", dirtrack1, dirtrack2) VALUES(1, 'Elmshorn', 'Kiel', 'Hamburg');
INSERT INTO public."location" (id, "name", dirtrack1, dirtrack2) VALUES(2, 'Schwarzenbek', 'Hamburg', 'Berlin');
INSERT INTO public."location" (id, "name", dirtrack1, dirtrack2) VALUES(3, 'Celle', 'Hamburg', 'Lehrte');
INSERT INTO public."location" (id, "name", dirtrack1, dirtrack2) VALUES(4, 'Nienburg', 'Bremen', 'Wunstorf');
INSERT INTO public."location" (id, "name", dirtrack1, dirtrack2) VALUES(5, 'Stadthagen', 'Minden', 'Hannover');
INSERT INTO public."location" (id, "name", dirtrack1, dirtrack2) VALUES(6, 'Eilsleben', 'Braunschweig', 'Magdeburg');
INSERT INTO public."location" (id, "name", dirtrack1, dirtrack2) VALUES(7, 'Emmerich', 'Emmerich (Grenze)', 'Oberhausen');
INSERT INTO public."location" (id, "name", dirtrack1, dirtrack2) VALUES(8, 'Andernach', 'Bingen', 'Köln');
INSERT INTO public."location" (id, "name", dirtrack1, dirtrack2) VALUES(9, 'Lahnstein', 'Wiesbaden', 'Koblenz');
INSERT INTO public."location" (id, "name", dirtrack1, dirtrack2) VALUES(10, 'Bad Hersfeld', 'Bebra', 'Fulda');
INSERT INTO public."location" (id, "name", dirtrack1, dirtrack2) VALUES(11, 'Saalfeld', 'Saalfeld', 'Großheringen');
INSERT INTO public."location" (id, "name", dirtrack1, dirtrack2) VALUES(12, 'Radebeul', 'Berlin ', 'Dresden');
INSERT INTO public."location" (id, "name", dirtrack1, dirtrack2) VALUES(13, 'Karlstadt', 'Aschaffenburg', 'Würzburg');
INSERT INTO public."location" (id, "name", dirtrack1, dirtrack2) VALUES(14, 'Göppingen', 'Ulm', 'Stuttgart');
INSERT INTO public."location" (id, "name", dirtrack1, dirtrack2) VALUES(15, 'Osterhofen', 'Regensburg', 'Passau');
INSERT INTO public."location" (id, "name", dirtrack1, dirtrack2) VALUES(16, 'Emmendingen', 'Basel', 'Mannheim');
INSERT INTO public."location" (id, "name", dirtrack1, dirtrack2) VALUES(17, 'Rosenheim', 'München', 'Rosenheim');
INSERT INTO public."location" (id, "name", dirtrack1, dirtrack2) VALUES(18, 'Fürstenwalde', 'Frankfurt/Oder', 'Berlin');
INSERT INTO public."location" (id, "name", dirtrack1, dirtrack2) VALUES(19, 'Telgte', 'Osnabrück', 'Münster');



CREATE TABLE public.train (
	location_id int2 NOT NULL, -- id Messstelle aus Tabelle location
	track int2 NOT NULL, -- Gleis Nummer ( 1 oder 2)
	entry_time timestamptz NOT NULL, -- Einfahrtszeit
	directionok bool NOT NULL, -- Wenn Wahr, dann ist Fahrtrichtung = location.dirtrack1, sonst dirtrack2
	category text, -- PZ: Personenzug, GZ: Güterzug, DZ: Dienstzug, NZ: - (unbekannt)
	duration_ds int2 NOT NULL, -- Expositionsdauer TTEL in ds (0,1s) ist die Zeitdauer über die die Schallenergie zur Bestimmung des Vorbeifahrtexpositionspegels TEL berücksichtigt wird
	len_dm int2 NOT NULL, --Länge des Zugs in dm berechnet aus Geschwindigkeit und Vorbeifahrtdauer
	speed_km_h int2 NOT NULL, -- Mittlere Geschwindigkeit des Zugs in km/h
	lafmax10_cb int2 NOT NULL, -- Der Maximalpegel in cB (0,1 dB) ist der höchste gemessene Schalldruckpegel während der Zugvorbeifahrt
	laeq10_cb int2 NOT NULL, -- Der Vorbeifahrtexpositionspegel  in cB (0,1 dB) ist der energetisch gemittelter Schalldruckpegel über die Expositionsdauer TTEL
	info bpchar(1), -- Leer: Messung war gültig, R: ungültige Messung wurde ersetzt, I: Bei Ausfall über längerem Zeitraum eingefügte Messung.
	ds_before_entry int2 NULL, -- Zeit in ds vor entry_time der 100-ms-Pegel laf10_ds
	laf10_ds int2[]  -- Array der Pegel LAF in cB (0,1 dB) im 100 ms Abstand
);

CREATE INDEX train_location_id_idx ON public.train USING btree (location_id);
CREATE INDEX train_entry_time_idx ON public.train USING btree (entry_time);

CREATE VIEW public.zugvorbeifahrten
AS SELECT 
	l.name AS Ort,
	t.entry_time AS Einfahrtzeit,
	t.track as Gleis,
	CASE
		WHEN t.track = 1
		THEN 
			CASE WHEN t.directionok THEN l.dirtrack1 ELSE l.dirtrack2 END
		ELSE 
			CASE WHEN t.directionok THEN l.dirtrack2 ELSE l.dirtrack1 END
	END AS Richtung,
	CASE 
		WHEN t.category = 'PZ' THEN 'Personenzug' 
		WHEN t.category = 'GZ' THEN 'Güterzug'
		WHEN t.category = 'DZ' THEN 'Dienstzug'
		WHEN t.category = 'NZ' THEN '-'
	END as Zugkategorie,
   
	t.duration_ds * 0.1 as Vorbeifahrtdauer,
	t.len_dm  * 0.1 as Zuglänge,
	t.speed_km_h as Geschwindigkeit,
	t.lafmax10_cb * 0.1 as Maximalpegel,
	t.laeq10_cb * 0.1 as Vorbeifahrtpegel,

	CASE 
		WHEN t.info = 'R' THEN 'Ersetzt' 
		WHEN t.info = 'I' THEN 'Eingefügt'
	END as Info
	
	FROM train t JOIN location l ON t.location_id = l.id