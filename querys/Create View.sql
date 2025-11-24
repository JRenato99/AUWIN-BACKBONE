-- ========= VISTAS PARA GRAFO =========
-- BACKBONE (NODOS)
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('dbo.vw_backbone_nodes') AND type = 'V')
BEGIN 
    exec('CREATE VIEW dbo.vw_backbone_nodes AS
    SELECT n.id AS nodo_id, n.code AS nodo_code, n.name AS nodo_name, n.gps_lat, n.gps_lon
    FROM dbo.nodo n')
END

-- BACKBONE (EDGES)
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('dbo.vw_backbone_edges') AND type = 'V')
BEGIN 
    exec('CREATE VIEW dbo.vw_backbone_edges AS
    SELECT 
      r.id        AS route_id,
      o_from.nodo_id AS from_nodo_id,
      o_to.nodo_id   AS to_nodo_id,
      r.path_text
    FROM dbo.odf_route r
    JOIN dbo.odf o_from ON o_from.id = r.from_odf_id
    JOIN dbo.odf o_to   ON o_to.id   = r.to_odf_id;')
END

-- Router–ODF (para saber qué router/puerto “toca” cada ODF)
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('dbo.vw_router_odf_link') AND type = 'V')
BEGIN 
    exec('CREATE  VIEW dbo.vw_router_odf_link AS
    SELECT 
      l.id               AS link_id,
      rp.id              AS router_port_id,
      r.id               AS router_id,
      r.name             AS router_name,
      r.nodo_id          AS router_nodo_id,
      op.id              AS odf_port_id,
      o.id               AS odf_id,
      o.name             AS odf_name,
      o.nodo_id          AS odf_nodo_id
    FROM dbo.link_router_odf l
    JOIN dbo.router_port rp ON rp.id = l.router_port_id
    JOIN dbo.router r       ON r.id  = rp.router_id
    JOIN dbo.odf_port op    ON op.id = l.odf_port_id
    JOIN dbo.odf o          ON o.id  = op.odf_id;')
END

-- Segmentos de ruta “expandida” (para ver los spans y postes)
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('dbo.vw_route_segments_expanded') AND type = 'V')
BEGIN 
    exec('CREATE VIEW dbo.vw_route_segments_expanded AS
    SELECT 
      ors.odf_route_id,
      ors.seq               AS seg_seq,
      cs.id                 AS cable_span_id,
      cs.cable_id,
      cs.seq                AS cable_seq,
      cs.from_pole_id,
      pf.code               AS from_pole_code,
      cs.to_pole_id,
      pt.code               AS to_pole_code,
      cs.length_m,
      cs.length_span,
      cs.capacity_fibers
    FROM dbo.odf_route_segment ors
    JOIN dbo.cable_span cs ON cs.id = ors.cable_span_id
    LEFT JOIN dbo.pole pf ON pf.id = cs.from_pole_id
    LEFT JOIN dbo.pole pt ON pt.id = cs.to_pole_id;')
END

-- Rutas Logicas con informacion del resumen Fisico
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('dbo.vw_route_physical_summary') AND type = 'V')
BEGIN 
    exec('CREATE VIEW dbo.vw_route_physical_summary AS
    WITH spans AS (
      SELECT odf_route_id,
             STRING_AGG(CONCAT(''['', seg_seq, '']'', cs.cable_id, '':'', 
             cs.from_pole_id, ''&'', cs.to_pole_id, '' ('', cs.length_m, ''m)''), '' | '')
               WITHIN GROUP (ORDER BY seg_seq) AS span_list
      FROM dbo.vw_route_segments_expanded e
      JOIN dbo.cable_span cs ON cs.id = e.cable_span_id
      GROUP BY odf_route_id
    )
    SELECT 
      r.id           AS odf_route_id,
      r.from_odf_id,
      r.to_odf_id,
      s.span_list,
      r.path_text
    FROM dbo.odf_route r
    LEFT JOIN spans s ON s.odf_route_id = r.id;')
END

-- Vistas Empalmes
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('dbo.vw_fiber_splice') AND type = 'V')
BEGIN
    exec('CREATE VIEW dbo.vw_fiber_splice AS
    SELECT 
      sp.id AS splice_id,
      sp.mufa_id,
      m.pole_id,
      sp.a_fiber_filament_id,
      sp.b_fiber_filament_id  
    FROM dbo.splice sp
    JOIN dbo.mufa m ON m.id = sp.mufa_id;')
END

-----------------------------------------------------
-- Resumen Ruta Logica ODF -> ODF
CREATE OR ALTER VIEW dbo.vw_route_summary AS 
WITH seg AS (
    SELECT 
        ors.odf_route_id,
        ors.seq,
        cs.id AS span_id,
        cs.from_pole_id,
        cs.to_pole_id,
        cs.length_m
    FROM dbo.odf_route_segment ors
    JOIN dbo.cable_span cs
        ON cs.id = ors.cable_span_id
),
agg AS (
    SELECT 
        r.id AS route_id,
        r.from_odf_id,
        r.to_odf_id,
        COUNT(*) as span_count,
        SUM(COALESCE(s.length_m, 0.0)) as total_length_m,
        STRING_AGG(CAST(s.span_id AS NVARCHAR(200)), '>')
            WITHIN GROUP (ORDER BY s.seq) AS span_list
    FROM dbo.odf_route r
    JOIN seg s
        ON s.odf_route_id = r.id
    GROUP BY r.id, r.from_odf_id, r.to_odf_id
)
SELECT
    a.route_id,
    a.from_odf_id,
    a.to_odf_id,
    a.span_count,
    a.total_length_m,
    a.span_list
FROM agg a;
   
-----------------------------------------------------
-- Detalle Fisico Ordenado
CREATE OR ALTER VIEW dbo.vw_route_detail AS
SELECT 
    r.id AS route_id,
    r.from_odf_id,
    r.to_odf_id,
    ors.seq,
    cs.id AS span_id,
    cs.cable_id,
    cs.from_pole_id,
    fp.code AS from_pole_code,
    cs.to_pole_id,
    tp.code AS to_pole_code,
    cs.length_m
FROM dbo.odf_route r
JOIN dbo.odf_route_segment ors
    ON ors.odf_route_id = r.id
JOIN dbo.cable_span cs
    ON cs.id = ors.cable_span_id
LEFT JOIN dbo.pole fp
    ON fp.id = cs.from_pole_id
LEFT JOIN dbo.pole tp
    ON tp.id = cs.to_pole_id
-- ORDER BY r.id, ors.seq
    

-----------------------------------------------------
-- Vista unificada de nodos del grafo
CREATE OR ALTER VIEW dbo.vw_graph_nodes AS 
-- ODF
SELECT (o.id)       AS id,
       'ODF'                      AS kind,
       o.name                     AS label,
       n.id                       AS site_id,
       n.gps_lat, n.gps_lon,
       'BACKBONE'                 AS layer,
       NULL                       AS status
FROM dbo.odf o
JOIN dbo.nodo n ON n.id = o.nodo_id

UNION ALL
-- ROUTER
SELECT (r.id),
       'RTR',
       r.name,
       n.id,
       n.gps_lat, n.gps_lon,
       'BACKBONE',
       NULL
FROM dbo.router r
JOIN dbo.nodo n ON n.id = r.nodo_id

UNION ALL
-- POSTE
SELECT (p.id),
       'POSTE',
       p.code,
       NULL,
       p.gps_lat, p.gps_lon,
       'BACKBONE',
       p.status
FROM dbo.pole p

UNION ALL
-- MUFA (usa coordenadas del poste)
SELECT (m.id),
       'MUFA',
       m.code,
       NULL,
       p.gps_lat, p.gps_lon,
       'BACKBONE',
       NULL
FROM dbo.mufa m
JOIN dbo.pole p ON p.id = m.pole_id;


-----------------------------------------------

CREATE OR ALTER VIEW dbo.vw_graph_edges AS
/* -----------------------------------------------------------
   1) Tramos físicos del cable: POSTE ↔ POSTE
----------------------------------------------------------- */
SELECT CONCAT('SPAN:', cs.id)                 AS id,
       CONCAT('POSTE:', cs.from_pole_id)      AS [from],
       CONCAT('POSTE:', cs.to_pole_id)        AS [to],
       'CABLE_SPAN'                           AS edge_kind,
       cs.length_m                            AS length_m,
       'BACKBONE'                             AS layer,
       NULL                                   AS path_text
FROM dbo.cable_span cs

UNION ALL
/* -----------------------------------------------------------
   2) Rutas lógicas ODF ↔ ODF (con texto de soporte)
----------------------------------------------------------- */
SELECT CONCAT('LOG:', rs.route_id)            AS id,
       CONCAT('ODF:', rs.from_odf_id)         AS [from],
       CONCAT('ODF:', rs.to_odf_id)           AS [to],
       'LOGICAL_ROUTE'                        AS edge_kind,
       NULL                                   AS length_m,
       'BACKBONE'                             AS layer,
       rs.span_list                           AS path_text
FROM dbo.vw_route_summary rs

UNION ALL
/* -----------------------------------------------------------
   3) Router ↔ ODF (patch cord interno)
      Usa el vínculo real: link_router_odf (router_port ↔ odf_port)
----------------------------------------------------------- */
SELECT DISTINCT
       CONCAT('RTR2ODF:', r.id, ':', o.id)    AS id,
       CONCAT('RTR:', r.id)                   AS [from],
       CONCAT('ODF:', o.id)                   AS [to],
       'RTR_TO_ODF'                           AS edge_kind,
       NULL                                   AS length_m,
       'BACKBONE'                             AS layer,
       NULL                                   AS path_text
FROM dbo.link_router_odf l
JOIN dbo.router_port rp ON rp.id = l.router_port_id
JOIN dbo.router r       ON r.id  = rp.router_id
JOIN dbo.odf_port op    ON op.id = l.odf_port_id
JOIN dbo.odf o          ON o.id  = op.odf_id

UNION ALL
/* -----------------------------------------------------------
   4) ODF → POSTE a través del cable
      - odf_cable_end enlaza ODF ↔ CABLE
      - tomamos el PRIMER span (MIN(seq)) de ese cable
      - anclamos la ODF a AMBOS postes del primer span (A y B)
----------------------------------------------------------- */
SELECT DISTINCT
       CONCAT('ODF2POSTE_A:', oce.odf_id, ':', cs.from_pole_id) AS id,
       CONCAT('ODF:',  oce.odf_id)                              AS [from],
       CONCAT('POSTE:', cs.from_pole_id)                        AS [to],
       'ODF_TO_POSTE'                                          AS edge_kind,
       NULL                                                     AS length_m,
       'BACKBONE'                                               AS layer,
       NULL                                                     AS path_text
FROM dbo.odf_cable_end oce
CROSS APPLY (
    SELECT TOP (1) cs2.*
    FROM dbo.cable_span cs2
    WHERE cs2.cable_id = oce.cable_id
    ORDER BY cs2.seq ASC
) cs

UNION ALL
SELECT DISTINCT
       CONCAT('ODF2POSTE_B:', oce.odf_id, ':', cs.to_pole_id)   AS id,
       CONCAT('ODF:',  oce.odf_id)                              AS [from],
       CONCAT('POSTE:', cs.to_pole_id)                          AS [to],
       'ODF_TO_POSTE'                                          AS edge_kind,
       NULL                                                     AS length_m,
       'BACKBONE'                                               AS layer,
       NULL                                                     AS path_text
FROM dbo.odf_cable_end oce
CROSS APPLY (
    SELECT TOP (1) cs2.*
    FROM dbo.cable_span cs2
    WHERE cs2.cable_id = oce.cable_id
    ORDER BY cs2.seq ASC
) cs

UNION ALL
/* -----------------------------------------------------------
   5) MUFA ↔ POSTE (siempre directo por FK mufa.pole_id)
----------------------------------------------------------- */
SELECT DISTINCT
       CONCAT('MUFA2POSTE:', m.id)            AS id,
       CONCAT('MUFA:', m.id)                  AS [from],
       CONCAT('POSTE:', p.id)                 AS [to],
       'MUFA_TO_POSTE'                        AS edge_kind,
       NULL                                   AS length_m,
       'BACKBONE'                              AS layer,
       NULL                                   AS path_text
FROM dbo.mufa m
JOIN dbo.pole p ON p.id = m.pole_id;
