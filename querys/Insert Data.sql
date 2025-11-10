/* ============================================================
   AUWIN - SEED DE DATOS DE PRUEBA (ring de 4 nodos)
   ============================================================ */

USE AUWIN;
GO

BEGIN TRAN;

-- Limpieza suave (sólo para entorno demo)
DELETE FROM dbo.odf_port_fiber;
DELETE FROM dbo.splice;
DELETE FROM dbo.mufa;
DELETE FROM dbo.odf_route_segment;
DELETE FROM dbo.odf_route;
DELETE FROM dbo.cable_span;
DELETE FROM dbo.odf_cable_end;
DELETE FROM dbo.fiber_filament;
DELETE FROM dbo.cable;
DELETE FROM dbo.link_router_odf;
DELETE FROM dbo.odf_port;
DELETE FROM dbo.router_port;
DELETE FROM dbo.router;
DELETE FROM dbo.odf;
DELETE FROM dbo.pole;
DELETE FROM dbo.nodo;
DELETE FROM dbo.graph_node_position;

-- NODOS
INSERT INTO dbo.nodo(id, code, name, reference) VALUES
 (N'NODO-001', N'POP-NORTE',  N'NODO NORTE', N'Azotea NORTE'),
 (N'NODO-002', N'POP-ESTE',   N'NODO ESTE',  N'Azotea ESTE'),
 (N'NODO-003', N'POP-SUR',    N'NODO SUR',   N'Azotea SUR'),
 (N'NODO-004', N'POP-OESTE',  N'NODO OESTE', N'Azotea OESTE');

-- ROUTERS
INSERT INTO dbo.router (id, nodo_id, name, model, mgmt_ip, total_ports) VALUES
 (N'RTR-001', N'NODO-001', N'RTR-NORTE-1', N'ASR1001', N'10.0.1.1', 24),
 (N'RTR-002', N'NODO-002', N'RTR-ESTE-1',  N'ASR1001', N'10.0.2.1', 24),
 (N'RTR-003', N'NODO-003', N'RTR-SUR-1',   N'ASR1001', N'10.0.3.1', 24),
 (N'RTR-004', N'NODO-004', N'RTR-OESTE-1', N'ASR1001', N'10.0.4.1', 24);

-- PUERTOS DE ROUTER (2 por router)
INSERT INTO dbo.router_port (id, router_id, port_no, status, type_port, speed) VALUES
 (N'RP-001-01', N'RTR-001', 1, N'UP',   N'10G', 10.0),
 (N'RP-001-02', N'RTR-001', 2, N'DOWN', N'10G', 10.0),
 (N'RP-002-01', N'RTR-002', 1, N'UP',   N'10G', 10.0),
 (N'RP-002-02', N'RTR-002', 2, N'DOWN', N'10G', 10.0),
 (N'RP-003-01', N'RTR-003', 1, N'UP',   N'10G', 10.0),
 (N'RP-003-02', N'RTR-003', 2, N'DOWN', N'10G', 10.0),
 (N'RP-004-01', N'RTR-004', 1, N'UP',   N'10G', 10.0),
 (N'RP-004-02', N'RTR-004', 2, N'DOWN', N'10G', 10.0);

-- ODFs
INSERT INTO dbo.odf (id, nodo_id, name, code, total_ports) VALUES
 (N'ODF-001', N'NODO-001', N'ODF NORTE 1', N'ODF-NOR-01', 24),
 (N'ODF-002', N'NODO-002', N'ODF ESTE 1' , N'ODF-EST-01', 24),
 (N'ODF-003', N'NODO-003', N'ODF SUR 1'  , N'ODF-SUR-01', 24),
 (N'ODF-004', N'NODO-004', N'ODF OESTE 1', N'ODF-OES-01', 24);

-- PUERTOS ODF (4 por ODF)
INSERT INTO dbo.odf_port (id, odf_id, port_no, status, connector_type) VALUES
 (N'OP-001-01', N'ODF-001', 1, N'UP', N'SC'),
 (N'OP-001-02', N'ODF-001', 2, N'UP', N'SC'),
 (N'OP-001-03', N'ODF-001', 3, N'DOWN', N'SC'),
 (N'OP-001-04', N'ODF-001', 4, N'DOWN', N'SC'),

 (N'OP-002-01', N'ODF-002', 1, N'UP', N'SC'),
 (N'OP-002-02', N'ODF-002', 2, N'UP', N'SC'),
 (N'OP-002-03', N'ODF-002', 3, N'DOWN', N'SC'),
 (N'OP-002-04', N'ODF-002', 4, N'DOWN', N'SC'),

 (N'OP-003-01', N'ODF-003', 1, N'UP', N'SC'),
 (N'OP-003-02', N'ODF-003', 2, N'UP', N'SC'),
 (N'OP-003-03', N'ODF-003', 3, N'DOWN', N'SC'),
 (N'OP-003-04', N'ODF-003', 4, N'DOWN', N'SC'),

 (N'OP-004-01', N'ODF-004', 1, N'UP', N'SC'),
 (N'OP-004-02', N'ODF-004', 2, N'UP', N'SC'),
 (N'OP-004-03', N'ODF-004', 3, N'DOWN', N'SC'),
 (N'OP-004-04', N'ODF-004', 4, N'DOWN', N'SC');

-- PATCH router<->odf
INSERT INTO dbo.link_router_odf (id, router_port_id, odf_port_id) VALUES
 (N'LNK-001-A', N'RP-001-01', N'OP-001-01'),
 (N'LNK-002-A', N'RP-002-01', N'OP-002-01'),
 (N'LNK-003-A', N'RP-003-01', N'OP-003-01'),
 (N'LNK-004-A', N'RP-004-01', N'OP-004-01');

-- POSTES (mínimos entre NODO-001 y NODO-002 y así sucesivamente)
INSERT INTO dbo.pole (id, code, pole_type, owner, district, has_reserve, has_cruceta) VALUES
 (N'PL-001', N'P-001', N'MADERA', N'UTIL', N'NORTE', 0, 1),
 (N'PL-002', N'P-002', N'MADERA', N'UTIL', N'NORTE', 1, 1),
 (N'PL-003', N'P-003', N'MADERA', N'UTIL', N'ESTE',  0, 1),
 (N'PL-004', N'P-004', N'MADERA', N'UTIL', N'ESTE',  0, 1),

 (N'PL-101', N'P-101', N'MADERA', N'UTIL', N'ESTE',  0, 1),
 (N'PL-102', N'P-102', N'MADERA', N'UTIL', N'ESTE',  1, 1),
 (N'PL-103', N'P-103', N'MADERA', N'UTIL', N'SUR',   0, 1),
 (N'PL-104', N'P-104', N'MADERA', N'UTIL', N'SUR',   0, 1);

-- CABLES
INSERT INTO dbo.cable (id, code, material_type, jacket_type, fiber_count) VALUES
 (N'CBL-001', N'CBL-NOR-EST', N'G657', N'PE', 12),
 (N'CBL-002', N'CBL-EST-SUR', N'G657', N'PE', 12);

-- FILAMENTOS (12 fibras por cable)
;WITH nums AS (
  SELECT TOP (12) ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS n
  FROM sys.objects
)
INSERT INTO dbo.fiber_filament(id, cable_id, filament_no, color_code, owner)
SELECT 
  CONCAT('F-', 'CBL-001', '-', RIGHT('00'+CAST(n AS NVARCHAR(2)),2)),
  N'CBL-001',
  n,
  CASE n
    WHEN 1 THEN 'AZUL' WHEN 2 THEN 'NARANJA' WHEN 3 THEN 'VERDE' WHEN 4 THEN 'MARRON'
    WHEN 5 THEN 'GRIS' WHEN 6 THEN 'BLANCO'  WHEN 7 THEN 'ROJO'  WHEN 8 THEN 'NEGRO'
    WHEN 9 THEN 'AMARILLO' WHEN 10 THEN 'VIOLETA' WHEN 11 THEN 'ROSA' WHEN 12 THEN 'TURQUESA'
  END,
  N'CORE'
FROM nums
UNION ALL
SELECT 
  CONCAT('F-', 'CBL-002', '-', RIGHT('00'+CAST(n AS NVARCHAR(2)),2)),
  N'CBL-002',
  n,
  CASE n
    WHEN 1 THEN 'AZUL' WHEN 2 THEN 'NARANJA' WHEN 3 THEN 'VERDE' WHEN 4 THEN 'MARRON'
    WHEN 5 THEN 'GRIS' WHEN 6 THEN 'BLANCO'  WHEN 7 THEN 'ROJO'  WHEN 8 THEN 'NEGRO'
    WHEN 9 THEN 'AMARILLO' WHEN 10 THEN 'VIOLETA' WHEN 11 THEN 'ROSA' WHEN 12 THEN 'TURQUESA'
  END,
  N'CORE'
FROM nums;

-- SPANS DEL CABLE CBL-001 (NORTE->ESTE)
INSERT INTO dbo.cable_span (id, cable_id, seq, from_pole_id, to_pole_id, length_m) VALUES
 (N'SPN-001-01', N'CBL-001', 1, N'PL-001', N'PL-002', 120.0),
 (N'SPN-001-02', N'CBL-001', 2, N'PL-002', N'PL-003', 180.0),
 (N'SPN-001-03', N'CBL-001', 3, N'PL-003', N'PL-004', 160.0);

-- SPANS DEL CABLE CBL-002 (ESTE->SUR)
INSERT INTO dbo.cable_span (id, cable_id, seq, from_pole_id, to_pole_id, length_m) VALUES
 (N'SPN-002-01', N'CBL-002', 1, N'PL-101', N'PL-102', 110.0),
 (N'SPN-002-02', N'CBL-002', 2, N'PL-102', N'PL-103', 170.0),
 (N'SPN-002-03', N'CBL-002', 3, N'PL-103', N'PL-104', 150.0);

-- ODF ROUTES (lógicas)
INSERT INTO dbo.odf_route (id, from_odf_id, to_odf_id, path_text) VALUES
 (N'RTE-001', N'ODF-001', N'ODF-002', N'NORTE → ESTE'),
 (N'RTE-002', N'ODF-002', N'ODF-003', N'ESTE → SUR');

-- EXPANSIÓN DE RTE-001 (secuencias sobre CBL-001)
INSERT INTO dbo.odf_route_segment (id, segmento_code, odf_route_id, cable_span_id, seq) VALUES
 (N'RTE-001-S1', N'TRAMO-1', N'RTE-001', N'SPN-001-01', 1),
 (N'RTE-001-S2', N'TRAMO-2', N'RTE-001', N'SPN-001-02', 2),
 (N'RTE-001-S3', N'TRAMO-3', N'RTE-001', N'SPN-001-03', 3);

-- EXPANSIÓN DE RTE-002 (secuencias sobre CBL-002)
INSERT INTO dbo.odf_route_segment (id, segmento_code, odf_route_id, cable_span_id, seq) VALUES
 (N'RTE-002-S1', N'TRAMO-1', N'RTE-002', N'SPN-002-01', 1),
 (N'RTE-002-S2', N'TRAMO-2', N'RTE-002', N'SPN-002-02', 2),
 (N'RTE-002-S3', N'TRAMO-3', N'RTE-002', N'SPN-002-03', 3);

-- MUFAS (una en un poste intermedio de cada cable)
INSERT INTO dbo.mufa (id, code, pole_id, mufa_type) VALUES
 (N'MF-001', N'MF-CBL001-PL002', N'PL-002', N'CAJA-96'),
 (N'MF-002', N'MF-CBL002-PL102', N'PL-102', N'CAJA-96');

-- EMPALMES (ejemplo simple: empalme fibra 1 con fibra 1 dentro del cable)
INSERT INTO dbo.splice (id, mufa_id, a_fiber_filament_id, b_fiber_filament_id) VALUES
 (N'SP-001', N'MF-001', N'F-CBL-001-01', N'F-CBL-001-02'),
 (N'SP-002', N'MF-002', N'F-CBL-002-01', N'F-CBL-002-02');

-- CABLE <-> ODF (extremos del cable en ODFs)
INSERT INTO dbo.odf_cable_end (id, cable_id, odf_id) VALUES
 (N'OCE-001-A', N'CBL-001', N'ODF-001'),
 (N'OCE-001-B', N'CBL-001', N'ODF-002'),
 (N'OCE-002-A', N'CBL-002', N'ODF-002'),
 (N'OCE-002-B', N'CBL-002', N'ODF-003');

-- MAPEO PUERTO ODF <-> FIBRA (para llegar a puerto exacto)
INSERT INTO dbo.odf_port_fiber (id, odf_port_id, fiber_filament_id, direction, note) VALUES
 (N'OPF-001-01', N'OP-001-01', N'F-CBL-001-01', N'OUT', N'Fibra 1 del CBL-001'),
 (N'OPF-002-01', N'OP-002-01', N'F-CBL-001-01', N'IN',  N'Fibra 1 del CBL-001'),

 (N'OPF-002-02', N'OP-002-02', N'F-CBL-002-01', N'OUT', N'Fibra 1 del CBL-002'),
 (N'OPF-003-01', N'OP-003-01', N'F-CBL-002-01', N'IN',  N'Fibra 1 del CBL-002');

COMMIT TRAN;
GO

-- (Opcional) si quieres posiciones base para los NODOs:
EXEC dbo.sp_seed_default_positions @cols = 2;
GO
