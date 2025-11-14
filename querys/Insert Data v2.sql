/*==================================================================
SCRIPT DE INSERCIÓN DE DATOS v2.1 - CORREGIDO
====================================================================
Escenario:
1.  Anillo Backbone: NODO-SANI <-> NODO-MIRA <-> NODO-SURCO
    * CADA RUTA DEL ANILLO TENDRÁ ~15 POSTES Y 2 MUFAS DE PASO.
2.  Split de Distribución: NODO-SURCO -> MUFA-SPLIT -> NODO-LAVIC
                                                |
                                                +-> NODO-BARR
    * CADA RUTA DE DISTRIBUCIÓN TENDRÁ ~10 POSTES.

CORRECCIÓN: Añadida la palabra clave 'SET' en las asignaciones
de variables dentro de los bucles (Fases 3, 4, 6, 8).
==================================================================*/

USE AUWIN;
GO

SET NOCOUNT ON;
GO

-- Envolver todo en una transacción
BEGIN TRANSACTION;

BEGIN TRY

-- Declarar TODAS las variables para los bucles al inicio
DECLARE @i INT, @j INT, @seq INT;
DECLARE @CableID NVARCHAR(64);
DECLARE @FilamentPrefix NVARCHAR(60);
DECLARE @FilamentID NVARCHAR(64);
DECLARE @FilamentNo INT;

-- Variables para bucles de postes/spans
DECLARE @FromPoleID NVARCHAR(64);
DECLARE @ToPoleID NVARCHAR(64);
DECLARE @PolePrefix NVARCHAR(60);
DECLARE @PoleID NVARCHAR(64);
DECLARE @SpanPrefix NVARCHAR(60);
DECLARE @SpanID NVARCHAR(64);
DECLARE @RouteID NVARCHAR(64);
DECLARE @SegID NVARCHAR(64);

-- Variables para bucles de Splice
DECLARE @SpliceID_A NVARCHAR(64), @Fiber_A NVARCHAR(64), @Fiber_B NVARCHAR(64);
DECLARE @SpliceID_B NVARCHAR(64), @Fiber_A_B NVARCHAR(64), @Fiber_B_B NVARCHAR(64);


/*============================================================
FASE 1: CREAR ACTIVOS PRINCIPALES (NODOS, CABLES)
============================================================*/

PRINT 'FASE 1: Insertando Nodos y Cables...';

-- 1.1) Nodos (5 Nodos)
INSERT INTO dbo.nodo (id, code, type, name, reference, gps_lat, gps_lon) VALUES
('NODO-SANI', 'LIM-SANI-001', 'Distribucion', 'Nodo San Isidro', 'Av. Javier Prado Este 210', -12.089, -77.050),
('NODO-MIRA', 'LIM-MIRA-001', 'Distribucion', 'Nodo Miraflores', 'Av. Larco 400', -12.122, -77.030),
('NODO-SURCO', 'LIM-SURCO-001', 'Distribucion', 'Nodo Surco', 'Av. Benavides 5000', -12.138, -77.005),
('NODO-LAVIC', 'LIM-LAVIC-001', 'Acceso', 'Nodo La Victoria', 'Av. Iquitos 800', -12.068, -77.026),
('NODO-BARR', 'LIM-BARR-001', 'Acceso', 'Nodo Barranco', 'Av. Grau 300', -12.140, -77.020);

-- 1.2) Cables (6 Cables principales)
INSERT INTO dbo.cable (id, code, material_type, jacket_type, fiber_count) VALUES
('CABLE-SM', 'TRONCAL-SANI-MIRA', 'ADSS', 'Outdoor', 144),
('CABLE-MS', 'TRONCAL-MIRA-SURCO', 'ADSS', 'Outdoor', 144),
('CABLE-SS', 'TRONCAL-SURCO-SANI', 'ADSS', 'Outdoor', 144),
('CABLE-TRONCAL-SPLIT', 'DIST-SURCO-SPLIT', 'ADSS', 'Outdoor', 96),
('CABLE-RAMAL-LAVIC', 'DIST-SPLIT-LAVIC', 'ADSS', 'Outdoor', 48),
('CABLE-RAMAL-BARR', 'DIST-SPLIT-BARR', 'ADSS', 'Outdoor', 48);

/*============================================================
FASE 2: CREAR PLANTA INTERNA (ROUTERS, ODFS, PUERTOS, LINKS)
============================================================*/

PRINT 'FASE 2: Insertando Planta Interna (Routers, ODFs, Puertos)...';

-- 2.1) Routers (2 por nodo = 10 total)
INSERT INTO dbo.router (id, nodo_id, name, model, mgmt_ip, total_ports) VALUES
('RTR-SANI-01', 'NODO-SANI', 'SANI-RTR-01-BACKBONE', 'ASR9000', '10.10.1.1', 48),
('RTR-SANI-02', 'NODO-SANI', 'SANI-RTR-02-BACKBONE', 'ASR9000', '10.10.1.2', 48),
('RTR-MIRA-01', 'NODO-MIRA', 'MIRA-RTR-01-BACKBONE', 'ASR9000', '10.10.2.1', 48),
('RTR-MIRA-02', 'NODO-MIRA', 'MIRA-RTR-02-BACKBONE', 'ASR9000', '10.10.2.2', 48),
('RTR-SURCO-01', 'NODO-SURCO', 'SURCO-RTR-01-BACKBONE', 'ASR9000', '10.10.3.1', 48),
('RTR-SURCO-02', 'NODO-SURCO', 'SURCO-RTR-02-BACKBONE', 'ASR9000', '10.10.3.2', 48),
('RTR-LAVIC-01', 'NODO-LAVIC', 'LAVIC-RTR-01-ACCESO', 'ASR903', '10.20.1.1', 24),
('RTR-LAVIC-02', 'NODO-LAVIC', 'LAVIC-RTR-02-ACCESO', 'ASR903', '10.20.1.2', 24),
('RTR-BARR-01', 'NODO-BARR', 'BARR-RTR-01-ACCESO', 'ASR903', '10.20.2.1', 24),
('RTR-BARR-02', 'NODO-BARR', 'BARR-RTR-02-ACCESO', 'ASR903', '10.20.2.2', 24);

-- 2.2) ODFs (1 por cada router = 10 total)
INSERT INTO dbo.odf (id, nodo_id, name, code, total_ports) VALUES
('ODF-SANI-01', 'NODO-SANI', 'SANI-ODF-01 (RTR-01)', 'ODF-SANI-A', 144),
('ODF-SANI-02', 'NODO-SANI', 'SANI-ODF-02 (RTR-02)', 'ODF-SANI-B', 144),
('ODF-MIRA-01', 'NODO-MIRA', 'MIRA-ODF-01 (RTR-01)', 'ODF-MIRA-A', 144),
('ODF-MIRA-02', 'NODO-MIRA', 'MIRA-ODF-02 (RTR-02)', 'ODF-MIRA-B', 144),
('ODF-SURCO-01', 'NODO-SURCO', 'SURCO-ODF-01 (RTR-01)', 'ODF-SURCO-A', 144),
('ODF-SURCO-02', 'NODO-SURCO', 'SURCO-ODF-02 (RTR-02)', 'ODF-SURCO-B', 144),
('ODF-LAVIC-01', 'NODO-LAVIC', 'LAVIC-ODF-01 (RTR-01)', 'ODF-LAVIC-A', 48),
('ODF-LAVIC-02', 'NODO-LAVIC', 'LAVIC-ODF-02 (RTR-02)', 'ODF-LAVIC-B', 48),
('ODF-BARR-01', 'NODO-BARR', 'BARR-ODF-01 (RTR-01)', 'ODF-BARR-A', 48),
('ODF-BARR-02', 'NODO-BARR', 'BARR-ODF-02 (RTR-02)', 'ODF-BARR-B', 48);

-- 2.3) Puertos de Router
INSERT INTO dbo.router_port (id, router_id, port_no, status, type_port, speed) VALUES
('RP-SANI-01-P1', 'RTR-SANI-01', 1, 'Up', '100GE', 100000),
('RP-MIRA-01-P1', 'RTR-MIRA-01', 1, 'Up', '100GE', 100000),
('RP-MIRA-02-P1', 'RTR-MIRA-02', 1, 'Up', '100GE', 100000),
('RP-SURCO-01-P1', 'RTR-SURCO-01', 1, 'Up', '100GE', 100000),
('RP-SURCO-02-P1', 'RTR-SURCO-02', 1, 'Up', '100GE', 100000),
('RP-SANI-02-P1', 'RTR-SANI-02', 1, 'Up', '100GE', 100000),
('RP-SURCO-01-P2', 'RTR-SURCO-01', 2, 'Up', '10GE', 10000),
('RP-SURCO-01-P3', 'RTR-SURCO-01', 3, 'Up', '10GE', 10000),
('RP-LAVIC-01-P1', 'RTR-LAVIC-01', 1, 'Up', '10GE', 10000),
('RP-BARR-01-P1', 'RTR-BARR-01', 1, 'Up', '10GE', 10000);

-- 2.4) Puertos de ODF
INSERT INTO dbo.odf_port (id, odf_id, port_no, status, connector_type) VALUES
('OP-SANI-01-P1', 'ODF-SANI-01', 1, 'Connected', 'LC'),
('OP-MIRA-01-P1', 'ODF-MIRA-01', 1, 'Connected', 'LC'),
('OP-MIRA-02-P1', 'ODF-MIRA-02', 1, 'Connected', 'LC'),
('OP-SURCO-01-P1', 'ODF-SURCO-01', 1, 'Connected', 'LC'),
('OP-SURCO-02-P1', 'ODF-SURCO-02', 1, 'Connected', 'LC'),
('OP-SANI-02-P1', 'ODF-SANI-02', 1, 'Connected', 'LC'),
('OP-SURCO-01-P2', 'ODF-SURCO-01', 2, 'Connected', 'LC'),
('OP-SURCO-01-P3', 'ODF-SURCO-01', 3, 'Connected', 'LC'),
('OP-LAVIC-01-P1', 'ODF-LAVIC-01', 1, 'Connected', 'LC'),
('OP-BARR-01-P1', 'ODF-BARR-01', 1, 'Connected', 'LC');

-- 2.5) Links Internos (Patch Cords)
INSERT INTO dbo.link_router_odf (id, router_port_id, odf_port_id) VALUES
('LNK-SANI-01', 'RP-SANI-01-P1', 'OP-SANI-01-P1'),
('LNK-MIRA-01', 'RP-MIRA-01-P1', 'OP-MIRA-01-P1'),
('LNK-MIRA-02', 'RP-MIRA-02-P1', 'OP-MIRA-02-P1'),
('LNK-SURCO-01', 'RP-SURCO-01-P1', 'OP-SURCO-01-P1'),
('LNK-SURCO-02', 'RP-SURCO-02-P1', 'OP-SURCO-02-P1'),
('LNK-SANI-02', 'RP-SANI-02-P1', 'OP-SANI-02-P1'),
('LNK-SURCO-LAVIC', 'RP-SURCO-01-P2', 'OP-SURCO-01-P2'),
('LNK-SURCO-BARR', 'RP-SURCO-01-P3', 'OP-SURCO-01-P3'),
('LNK-LAVIC-01', 'RP-LAVIC-01-P1', 'OP-LAVIC-01-P1'),
('LNK-BARR-01', 'RP-BARR-01-P1', 'OP-BARR-01-P1');


/*============================================================
FASE 3: GENERACIÓN MASIVA DE PLANTA EXTERNA (POSTES, MUFAS)
============================================================*/

PRINT 'FASE 3: Generando POSTES y MUFAS...';

-- 3.1) Postes de inicio y fin de ruta (cerca de los nodos)
INSERT INTO dbo.pole (id, code, pole_type, owner, high, district, address_ref, gps_lat, gps_lon, status, has_reserve, reserve_length_m, has_cruceta, has_elem_retencion, has_elem_suspension) VALUES
('P-SANI-01-START', 'P-SANI-01', 'Concreto', 'Luz del Sur', 12, 'San Isidro', 'Salida NODO-SANI (a MIRA)', -12.090, -77.050, 'Activo', 0, 0, 1, 1, 0),
('P-SANI-02-START', 'P-SANI-02', 'Concreto', 'Luz del Sur', 12, 'San Isidro', 'Llegada NODO-SANI (de SURCO)', -12.089, -77.049, 'Activo', 0, 0, 1, 1, 0),
('P-MIRA-01-END',   'P-MIRA-01', 'Concreto', 'Luz del Sur', 12, 'Miraflores', 'Llegada NODO-MIRA (de SANI)', -12.121, -77.030, 'Activo', 0, 0, 1, 1, 0),
('P-MIRA-02-START', 'P-MIRA-02', 'Concreto', 'Luz del Sur', 12, 'Miraflores', 'Salida NODO-MIRA (a SURCO)', -12.123, -77.030, 'Activo', 0, 0, 1, 1, 0),
('P-SURCO-01-END',  'P-SURCO-01', 'Concreto', 'Luz del Sur', 12, 'Surco', 'Llegada NODO-SURCO (de MIRA)', -12.137, -77.005, 'Activo', 0, 0, 1, 1, 0),
('P-SURCO-02-START','P-SURCO-02', 'Concreto', 'Luz del Sur', 12, 'Surco', 'Salida NODO-SURCO (a SANI)', -12.138, -77.004, 'Activo', 0, 0, 1, 1, 0),
('P-SURCO-03-START','P-SURCO-03', 'Concreto', 'Luz del Sur', 12, 'Surco', 'Salida NODO-SURCO (a SPLIT)', -12.139, -77.005, 'Activo', 0, 0, 1, 1, 0),
('P-LAVIC-01-END',  'P-LAVIC-01', 'Concreto', 'Luz del Sur', 12, 'La Victoria', 'Llegada NODO-LAVIC', -12.069, -77.026, 'Activo', 0, 0, 1, 1, 0),
('P-BARR-01-END',   'P-BARR-01', 'Concreto', 'Luz del Sur', 12, 'Barranco', 'Llegada NODO-BARR', -12.140, -77.019, 'Activo', 0, 0, 1, 1, 0);

-- 3.2) Bucle RUTA SANI -> MIRA (15 postes)
PRINT '... Generando ruta SANI-MIRA (15 postes)';
SET @i = 1;
WHILE @i <= 15 BEGIN
    SET @PoleID = 'P-SM-' + FORMAT(@i, '00'); -- CORREGIDO: Añadido SET
    INSERT INTO dbo.pole (id, code, pole_type, owner, high, district, address_ref, gps_lat, gps_lon, status, has_reserve, reserve_length_m, has_cruceta, has_elem_retencion, has_elem_suspension)
    VALUES (@PoleID, @PoleID, 'Concreto', 'Luz del Sur', 12, 'San Isidro', 'Poste intermedio SANI-MIRA', NULL, NULL, 'Activo', 0, 0, 1, 1, 1);
    SET @i = @i + 1;
END;
INSERT INTO dbo.mufa (id, code, pole_id, mufa_type, gps_lat, gps_lon) VALUES
('MUFA-SM-05', 'MFA-SM-05', 'P-SM-05', 'Paso', NULL, NULL),
('MUFA-SM-10', 'MFA-SM-10', 'P-SM-10', 'Paso', NULL, NULL);

-- 3.3) Bucle RUTA MIRA -> SURCO (15 postes)
PRINT '... Generando ruta MIRA-SURCO (15 postes)';
SET @i = 1;
WHILE @i <= 15 BEGIN
    SET @PoleID = 'P-MS-' + FORMAT(@i, '00'); -- CORREGIDO: Añadido SET
    INSERT INTO dbo.pole (id, code, pole_type, owner, high, district, address_ref, gps_lat, gps_lon, status, has_reserve, reserve_length_m, has_cruceta, has_elem_retencion, has_elem_suspension)
    VALUES (@PoleID, @PoleID, 'Concreto', 'Luz del Sur', 12, 'Miraflores', 'Poste intermedio MIRA-SURCO', NULL, NULL, 'Activo', 0, 0, 1, 1, 1);
    SET @i = @i + 1;
END;
INSERT INTO dbo.mufa (id, code, pole_id, mufa_type, gps_lat, gps_lon) VALUES
('MUFA-MS-05', 'MFA-MS-05', 'P-MS-05', 'Paso', NULL, NULL),
('MUFA-MS-10', 'MFA-MS-10', 'P-MS-10', 'Paso', NULL, NULL);

-- 3.4) Bucle RUTA SURCO -> SANI (15 postes)
PRINT '... Generando ruta SURCO-SANI (15 postes)';
SET @i = 1;
WHILE @i <= 15 BEGIN
    SET @PoleID = 'P-SS-' + FORMAT(@i, '00'); -- CORREGIDO: Añadido SET
    INSERT INTO dbo.pole (id, code, pole_type, owner, high, district, address_ref, gps_lat, gps_lon, status, has_reserve, reserve_length_m, has_cruceta, has_elem_retencion, has_elem_suspension)
    VALUES (@PoleID, @PoleID, 'Concreto', 'Luz del Sur', 12, 'Surco', 'Poste intermedio SURCO-SANI', NULL, NULL, 'Activo', 0, 0, 1, 1, 1);
    SET @i = @i + 1;
END;
INSERT INTO dbo.mufa (id, code, pole_id, mufa_type, gps_lat, gps_lon) VALUES
('MUFA-SS-05', 'MFA-SS-05', 'P-SS-05', 'Paso', NULL, NULL),
('MUFA-SS-10', 'MFA-SS-10', 'P-SS-10', 'Paso', NULL, NULL);

-- 3.5) Bucle RUTA SURCO -> SPLIT (10 postes)
PRINT '... Generando ruta SURCO-SPLIT (10 postes)';
SET @i = 1;
WHILE @i <= 10 BEGIN
    SET @PoleID = 'P-TRONCAL-' + FORMAT(@i, '00'); -- CORREGIDO: Añadido SET
    INSERT INTO dbo.pole (id, code, pole_type, owner, high, district, address_ref, gps_lat, gps_lon, status, has_reserve, reserve_length_m, has_cruceta, has_elem_retencion, has_elem_suspension)
    VALUES (@PoleID, @PoleID, 'Concreto', 'Luz del Sur', 12, 'Surco', 'Poste Troncal Split', NULL, NULL, 'Activo', 0, 0, 1, 1, 1);
    SET @i = @i + 1;
END;
-- La mufa del split va en el último poste de este tramo
INSERT INTO dbo.mufa (id, code, pole_id, mufa_type, gps_lat, gps_lon) VALUES
('MUFA-SPLIT', 'MFA-SPLIT-001', 'P-TRONCAL-10', 'Segregacion', NULL, NULL);

-- 3.6) Bucle RUTA SPLIT -> LAVIC (10 postes)
PRINT '... Generando ruta SPLIT-LAVIC (10 postes)';
SET @i = 1;
WHILE @i <= 10 BEGIN
    SET @PoleID = 'P-LAVIC-' + FORMAT(@i, '00'); -- CORREGIDO: Añadido SET
    INSERT INTO dbo.pole (id, code, pole_type, owner, high, district, address_ref, gps_lat, gps_lon, status, has_reserve, reserve_length_m, has_cruceta, has_elem_retencion, has_elem_suspension)
    VALUES (@PoleID, @PoleID, 'Concreto', 'Luz del Sur', 12, 'La Victoria', 'Poste Ramal La Victoria', NULL, NULL, 'Activo', 0, 0, 1, 1, 1);
    SET @i = @i + 1;
END;

-- 3.7) Bucle RUTA SPLIT -> BARR (10 postes)
PRINT '... Generando ruta SPLIT-BARR (10 postes)';
SET @i = 1;
WHILE @i <= 10 BEGIN
    SET @PoleID = 'P-BARR-' + FORMAT(@i, '00'); -- CORREGIDO: Añadido SET
    INSERT INTO dbo.pole (id, code, pole_type, owner, high, district, address_ref, gps_lat, gps_lon, status, has_reserve, reserve_length_m, has_cruceta, has_elem_retencion, has_elem_suspension)
    VALUES (@PoleID, @PoleID, 'Concreto', 'Luz del Sur', 12, 'Barranco', 'Poste Ramal Barranco', NULL, NULL, 'Activo', 0, 0, 1, 1, 1);
    SET @i = @i + 1;
END;


/*============================================================
FASE 4: GENERACIÓN MASIVA DE TRAMOS DE CABLE (CABLE SPANS)
============================================================*/

PRINT 'FASE 4: Generando CABLE SPANS...';

-- 4.1) RUTA SANI -> MIRA (16 tramos)
SET @i = 1; SET @CableID = 'CABLE-SM'; SET @SpanPrefix = 'SPAN-SM-'; SET @PolePrefix = 'P-SM-'; SET @FromPoleID = 'P-SANI-01-START';
WHILE @i <= 15 BEGIN
    SET @SpanID = @SpanPrefix + FORMAT(@i, '00'); -- CORREGIDO: Añadido SET
    SET @ToPoleID = @PolePrefix + FORMAT(@i, '00'); -- CORREGIDO: Añadido SET
    INSERT INTO dbo.cable_span (id, cable_id, seq, from_pole_id, to_pole_id, length_m, capacity_fibers, length_span)
    VALUES (@SpanID, @CableID, @i, @FromPoleID, @ToPoleID, 100, 144, 100);
    SET @FromPoleID = @ToPoleID;
    SET @i = @i + 1;
END;
-- Tramo final
INSERT INTO dbo.cable_span (id, cable_id, seq, from_pole_id, to_pole_id, length_m, capacity_fibers, length_span)
VALUES ('SPAN-SM-16', @CableID, 16, @FromPoleID, 'P-MIRA-01-END', 100, 144, 100);

-- 4.2) RUTA MIRA -> SURCO (16 tramos)
SET @i = 1; SET @CableID = 'CABLE-MS'; SET @SpanPrefix = 'SPAN-MS-'; SET @PolePrefix = 'P-MS-'; SET @FromPoleID = 'P-MIRA-02-START';
WHILE @i <= 15 BEGIN
    SET @SpanID = @SpanPrefix + FORMAT(@i, '00'); -- CORREGIDO: Añadido SET
    SET @ToPoleID = @PolePrefix + FORMAT(@i, '00'); -- CORREGIDO: Añadido SET
    INSERT INTO dbo.cable_span (id, cable_id, seq, from_pole_id, to_pole_id, length_m, capacity_fibers, length_span)
    VALUES (@SpanID, @CableID, @i, @FromPoleID, @ToPoleID, 100, 144, 100);
    SET @FromPoleID = @ToPoleID;
    SET @i = @i + 1;
END;
INSERT INTO dbo.cable_span (id, cable_id, seq, from_pole_id, to_pole_id, length_m, capacity_fibers, length_span)
VALUES ('SPAN-MS-16', @CableID, 16, @FromPoleID, 'P-SURCO-01-END', 100, 144, 100);

-- 4.3) RUTA SURCO -> SANI (16 tramos)
SET @i = 1; SET @CableID = 'CABLE-SS'; SET @SpanPrefix = 'SPAN-SS-'; SET @PolePrefix = 'P-SS-'; SET @FromPoleID = 'P-SURCO-02-START';
WHILE @i <= 15 BEGIN
    SET @SpanID = @SpanPrefix + FORMAT(@i, '00'); -- CORREGIDO: Añadido SET
    SET @ToPoleID = @PolePrefix + FORMAT(@i, '00'); -- CORREGIDO: Añadido SET
    INSERT INTO dbo.cable_span (id, cable_id, seq, from_pole_id, to_pole_id, length_m, capacity_fibers, length_span)
    VALUES (@SpanID, @CableID, @i, @FromPoleID, @ToPoleID, 100, 144, 100);
    SET @FromPoleID = @ToPoleID;
    SET @i = @i + 1;
END;
INSERT INTO dbo.cable_span (id, cable_id, seq, from_pole_id, to_pole_id, length_m, capacity_fibers, length_span)
VALUES ('SPAN-SS-16', @CableID, 16, @FromPoleID, 'P-SANI-02-START', 100, 144, 100);

-- 4.4) RUTA SURCO -> SPLIT (10 tramos)
SET @i = 1; SET @CableID = 'CABLE-TRONCAL-SPLIT'; SET @SpanPrefix = 'SPAN-TRONCAL-'; SET @PolePrefix = 'P-TRONCAL-'; SET @FromPoleID = 'P-SURCO-03-START';
WHILE @i <= 10 BEGIN
    SET @SpanID = @SpanPrefix + FORMAT(@i, '00'); -- CORREGIDO: Añadido SET
    SET @ToPoleID = @PolePrefix + FORMAT(@i, '00'); -- CORREGIDO: Añadido SET
    INSERT INTO dbo.cable_span (id, cable_id, seq, from_pole_id, to_pole_id, length_m, capacity_fibers, length_span)
    VALUES (@SpanID, @CableID, @i, @FromPoleID, @ToPoleID, 100, 96, 100);
    SET @FromPoleID = @ToPoleID;
    SET @i = @i + 1;
END;

-- 4.5) RUTA SPLIT -> LAVIC (11 tramos)
SET @i = 1; SET @CableID = 'CABLE-RAMAL-LAVIC'; SET @SpanPrefix = 'SPAN-LAVIC-'; SET @PolePrefix = 'P-LAVIC-'; SET @FromPoleID = 'P-TRONCAL-10'; -- Inicia donde terminó el troncal
WHILE @i <= 10 BEGIN
    SET @SpanID = @SpanPrefix + FORMAT(@i, '00'); -- CORREGIDO: Añadido SET
    SET @ToPoleID = @PolePrefix + FORMAT(@i, '00'); -- CORREGIDO: Añadido SET
    INSERT INTO dbo.cable_span (id, cable_id, seq, from_pole_id, to_pole_id, length_m, capacity_fibers, length_span)
    VALUES (@SpanID, @CableID, @i, @FromPoleID, @ToPoleID, 100, 48, 100);
    SET @FromPoleID = @ToPoleID;
    SET @i = @i + 1;
END;
INSERT INTO dbo.cable_span (id, cable_id, seq, from_pole_id, to_pole_id, length_m, capacity_fibers, length_span)
VALUES ('SPAN-LAVIC-11', @CableID, 11, @FromPoleID, 'P-LAVIC-01-END', 100, 48, 100);

-- 4.6) RUTA SPLIT -> BARR (11 tramos)
SET @i = 1; SET @CableID = 'CABLE-RAMAL-BARR'; SET @SpanPrefix = 'SPAN-BARR-'; SET @PolePrefix = 'P-BARR-'; SET @FromPoleID = 'P-TRONCAL-10'; -- Inicia donde terminó el troncal
WHILE @i <= 10 BEGIN
    SET @SpanID = @SpanPrefix + FORMAT(@i, '00'); -- CORREGIDO: Añadido SET
    SET @ToPoleID = @PolePrefix + FORMAT(@i, '00'); -- CORREGIDO: Añadido SET
    INSERT INTO dbo.cable_span (id, cable_id, seq, from_pole_id, to_pole_id, length_m, capacity_fibers, length_span)
    VALUES (@SpanID, @CableID, @i, @FromPoleID, @ToPoleID, 100, 48, 100);
    SET @FromPoleID = @ToPoleID;
    SET @i = @i + 1;
END;
INSERT INTO dbo.cable_span (id, cable_id, seq, from_pole_id, to_pole_id, length_m, capacity_fibers, length_span)
VALUES ('SPAN-BARR-11', @CableID, 11, @FromPoleID, 'P-BARR-01-END', 100, 48, 100);


/*============================================================
FASE 5: GENERAR FILAMENTOS
============================================================*/

PRINT 'FASE 5: Generando filamentos...';

-- Bucle para CABLE-SM (144)
SET @i = 1; SET @CableID = 'CABLE-SM'; SET @FilamentPrefix = 'FF-SM-';
WHILE @i <= 144 BEGIN
    SET @FilamentID = @FilamentPrefix + FORMAT(@i, '000');
    INSERT INTO dbo.fiber_filament (id, cable_id, filament_no) VALUES (@FilamentID, @CableID, @i);
    SET @i = @i + 1;
END;

-- Bucle para CABLE-MS (144)
SET @i = 1; SET @CableID = 'CABLE-MS'; SET @FilamentPrefix = 'FF-MS-';
WHILE @i <= 144 BEGIN
    SET @FilamentID = @FilamentPrefix + FORMAT(@i, '000');
    INSERT INTO dbo.fiber_filament (id, cable_id, filament_no) VALUES (@FilamentID, @CableID, @i);
    SET @i = @i + 1;
END;

-- Bucle para CABLE-SS (144)
SET @i = 1; SET @CableID = 'CABLE-SS'; SET @FilamentPrefix = 'FF-SS-';
WHILE @i <= 144 BEGIN
    SET @FilamentID = @FilamentPrefix + FORMAT(@i, '000');
    INSERT INTO dbo.fiber_filament (id, cable_id, filament_no) VALUES (@FilamentID, @CableID, @i);
    SET @i = @i + 1;
END;

-- Bucle para CABLE-TRONCAL-SPLIT (96)
SET @i = 1; SET @CableID = 'CABLE-TRONCAL-SPLIT'; SET @FilamentPrefix = 'FF-TRONCAL-';
WHILE @i <= 96 BEGIN
    SET @FilamentID = @FilamentPrefix + FORMAT(@i, '000');
    INSERT INTO dbo.fiber_filament (id, cable_id, filament_no) VALUES (@FilamentID, @CableID, @i);
    SET @i = @i + 1;
END;

-- Bucle para CABLE-RAMAL-LAVIC (48)
SET @i = 1; SET @CableID = 'CABLE-RAMAL-LAVIC'; SET @FilamentPrefix = 'FF-LAVIC-';
WHILE @i <= 48 BEGIN
    SET @FilamentID = @FilamentPrefix + FORMAT(@i, '000');
    INSERT INTO dbo.fiber_filament (id, cable_id, filament_no) VALUES (@FilamentID, @CableID, @i);
    SET @i = @i + 1;
END;

-- Bucle para CABLE-RAMAL-BARR (48)
SET @i = 1; SET @CableID = 'CABLE-RAMAL-BARR'; SET @FilamentPrefix = 'FF-BARR-';
WHILE @i <= 48 BEGIN
    SET @FilamentID = @FilamentPrefix + FORMAT(@i, '000');
    INSERT INTO dbo.fiber_filament (id, cable_id, filament_no) VALUES (@FilamentID, @CableID, @i);
    SET @i = @i + 1;
END;

/*============================================================
FASE 6: CREAR EMPALMES (SPLICES)
============================================================*/

PRINT 'FASE 6: Creando empalmes del SPLIT...';
-- NOTA: No creamos empalmes para las mufas de paso del anillo,
-- asumimos que los filamentos pasan directo (pass-through).
-- Solo creamos empalmes para la MUFA-SPLIT, donde los cables cambian.

-- Bucle 1: Conectar Hilos 1-48 del Troncal a LAVIC
SET @i = 1;
WHILE @i <= 48 BEGIN
    SET @SpliceID_A = 'SPL-LAVIC-' + FORMAT(@i, '000'); -- CORREGIDO: Añadido SET y quitado DECLARE
    SET @Fiber_A = 'FF-TRONCAL-' + FORMAT(@i, '000'); -- CORREGIDO
    SET @Fiber_B = 'FF-LAVIC-' + FORMAT(@i, '000'); -- CORREGIDO
    
    INSERT INTO dbo.splice (id, mufa_id, a_fiber_filament_id, b_fiber_filament_id)
    VALUES (@SpliceID_A, 'MUFA-SPLIT', @Fiber_A, @Fiber_B);
    
    SET @i = @i + 1;
END;

-- Bucle 2: Conectar Hilos 49-96 del Troncal a BARR
SET @i = 49;
WHILE @i <= 96 BEGIN
    SET @FilamentNo = @i - 48; -- El Hilo 49 del troncal va al Hilo 1 de Barranco
    
    SET @SpliceID_B = 'SPL-BARR-' + FORMAT(@FilamentNo, '000'); -- CORREGIDO
    SET @Fiber_A_B = 'FF-TRONCAL-' + FORMAT(@i, '000'); -- CORREGIDO
    SET @Fiber_B_B = 'FF-BARR-' + FORMAT(@FilamentNo, '000'); -- CORREGIDO
    
    INSERT INTO dbo.splice (id, mufa_id, a_fiber_filament_id, b_fiber_filament_id)
    VALUES (@SpliceID_B, 'MUFA-SPLIT', @Fiber_A_B, @Fiber_B_B);
    
    SET @i = @i + 1;
END;

/*============================================================
FASE 7: CONECTAR CABLES A ODFS
============================================================*/

PRINT 'FASE 7: Conectando cables y filamentos a ODFs...';

-- 7.1) odf_cable_end
INSERT INTO dbo.odf_cable_end (id, cable_id, odf_id) VALUES
('OCE-SANI-01', 'CABLE-SM', 'ODF-SANI-01'),
('OCE-MIRA-01', 'CABLE-SM', 'ODF-MIRA-01'),
('OCE-MIRA-02', 'CABLE-MS', 'ODF-MIRA-02'),
('OCE-SURCO-01', 'CABLE-MS', 'ODF-SURCO-01'),
('OCE-SURCO-02', 'CABLE-SS', 'ODF-SURCO-02'),
('OCE-SANI-02', 'CABLE-SS', 'ODF-SANI-02'),
('OCE-SPLIT-TRONCAL', 'CABLE-TRONCAL-SPLIT', 'ODF-SURCO-01'),
('OCE-SPLIT-LAVIC', 'CABLE-RAMAL-LAVIC', 'ODF-LAVIC-01'),
('OCE-SPLIT-BARR', 'CABLE-RAMAL-BARR', 'ODF-BARR-01');

-- 7.2) odf_port_fiber
INSERT INTO dbo.odf_port_fiber (id, odf_port_id, fiber_filament_id, direction) VALUES
('OPF-SANI-01', 'OP-SANI-01-P1', 'FF-SM-001', 'A'),
('OPF-MIRA-01', 'OP-MIRA-01-P1', 'FF-SM-001', 'B'),
('OPF-MIRA-02', 'OP-MIRA-02-P1', 'FF-MS-001', 'A'),
('OPF-SURCO-01', 'OP-SURCO-01-P1', 'FF-MS-001', 'B'),
('OPF-SURCO-02', 'OP-SURCO-02-P1', 'FF-SS-001', 'A'),
('OPF-SANI-02', 'OP-SANI-02-P1', 'FF-SS-001', 'B'),
('OPF-SURCO-LAVIC', 'OP-SURCO-01-P2', 'FF-TRONCAL-001', 'A'),
('OPF-LAVIC', 'OP-LAVIC-01-P1', 'FF-LAVIC-001', 'B'),
('OPF-SURCO-BARR', 'OP-SURCO-01-P3', 'FF-TRONCAL-049', 'A'),
('OPF-BARR', 'OP-BARR-01-P1', 'FF-BARR-001', 'B');

/*============================================================
FASE 8: GENERACIÓN MASIVA DE RUTAS LÓGICAS (SEGMENTOS)
============================================================*/

PRINT 'FASE 8: Creando rutas lógicas y segmentos...';

-- 8.1) odf_route (Las rutas de servicio)
INSERT INTO dbo.odf_route (id, from_odf_id, to_odf_id, path_text) VALUES
('ROUTE-SANI-MIRA', 'ODF-SANI-01', 'ODF-MIRA-01', 'Ruta Backbone SANI-MIRA'),
('ROUTE-MIRA-SURCO', 'ODF-MIRA-02', 'ODF-SURCO-01', 'Ruta Backbone MIRA-SURCO'),
('ROUTE-SURCO-SANI', 'ODF-SURCO-02', 'ODF-SANI-02', 'Ruta Backbone SURCO-SANI'),
('ROUTE-SURCO-LAVIC', 'ODF-SURCO-01', 'ODF-LAVIC-01', 'Ruta Acceso SURCO-LAVIC'),
('ROUTE-SURCO-BARR', 'ODF-SURCO-01', 'ODF-BARR-01', 'Ruta Acceso SURCO-BARR');

-- 8.2) odf_route_segment (Bucle para mapear spans a rutas)

-- Ruta SANI -> MIRA (16 segmentos)
PRINT '... Mapeando segmentos SANI-MIRA';
SET @i = 1; SET @RouteID = 'ROUTE-SANI-MIRA'; SET @SpanPrefix = 'SPAN-SM-';
WHILE @i <= 16 BEGIN
    SET @SegID = 'SEG-SM-' + FORMAT(@i, '00'); -- CORREGIDO
    SET @SpanID = @SpanPrefix + FORMAT(@i, '00'); -- CORREGIDO
    INSERT INTO dbo.odf_route_segment (id, odf_route_id, cable_span_id, seq)
    VALUES (@SegID, @RouteID, @SpanID, @i);
    SET @i = @i + 1;
END;

-- Ruta MIRA -> SURCO (16 segmentos)
PRINT '... Mapeando segmentos MIRA-SURCO';
SET @i = 1; SET @RouteID = 'ROUTE-MIRA-SURCO'; SET @SpanPrefix = 'SPAN-MS-';
WHILE @i <= 16 BEGIN
    SET @SegID = 'SEG-MS-' + FORMAT(@i, '00'); -- CORREGIDO
    SET @SpanID = @SpanPrefix + FORMAT(@i, '00'); -- CORREGIDO
    INSERT INTO dbo.odf_route_segment (id, odf_route_id, cable_span_id, seq)
    VALUES (@SegID, @RouteID, @SpanID, @i);
    SET @i = @i + 1;
END;

-- Ruta SURCO -> SANI (16 segmentos)
PRINT '... Mapeando segmentos SURCO-SANI';
SET @i = 1; SET @RouteID = 'ROUTE-SURCO-SANI'; SET @SpanPrefix = 'SPAN-SS-';
WHILE @i <= 16 BEGIN
    SET @SegID = 'SEG-SS-' + FORMAT(@i, '00'); -- CORREGIDO
    SET @SpanID = @SpanPrefix + FORMAT(@i, '00'); -- CORREGIDO
    INSERT INTO dbo.odf_route_segment (id, odf_route_id, cable_span_id, seq)
    VALUES (@SegID, @RouteID, @SpanID, @i);
    SET @i = @i + 1;
END;

-- Ruta SURCO -> LAVIC (10 troncales + 11 ramales = 21 segmentos)
PRINT '... Mapeando segmentos SURCO-LAVIC';
SET @seq = 1;
-- Parte Troncal
SET @i = 1; SET @RouteID = 'ROUTE-SURCO-LAVIC'; SET @SpanPrefix = 'SPAN-TRONCAL-';
WHILE @i <= 10 BEGIN
    SET @SegID = 'SEG-SL-T-' + FORMAT(@i, '00'); -- CORREGIDO
    SET @SpanID = @SpanPrefix + FORMAT(@i, '00'); -- CORREGIDO
    INSERT INTO dbo.odf_route_segment (id, odf_route_id, cable_span_id, seq)
    VALUES (@SegID, @RouteID, @SpanID, @seq);
    SET @i = @i + 1; SET @seq = @seq + 1;
END;
-- Parte Ramal
SET @i = 1; SET @SpanPrefix = 'SPAN-LAVIC-';
WHILE @i <= 11 BEGIN
    SET @SegID = 'SEG-SL-R-' + FORMAT(@i, '00'); -- CORREGIDO
    SET @SpanID = @SpanPrefix + FORMAT(@i, '00'); -- CORREGIDO
    INSERT INTO dbo.odf_route_segment (id, odf_route_id, cable_span_id, seq)
    VALUES (@SegID, @RouteID, @SpanID, @seq);
    SET @i = @i + 1; SET @seq = @seq + 1;
END;

-- Ruta SURCO -> BARR (10 troncales + 11 ramales = 21 segmentos)
PRINT '... Mapeando segmentos SURCO-BARR';
SET @seq = 1;
-- Parte Troncal
SET @i = 1; SET @RouteID = 'ROUTE-SURCO-BARR'; SET @SpanPrefix = 'SPAN-TRONCAL-';
WHILE @i <= 10 BEGIN
    SET @SegID = 'SEG-SB-T-' + FORMAT(@i, '00'); -- CORREGIDO
    SET @SpanID = @SpanPrefix + FORMAT(@i, '00'); -- CORREGIDO
    -- Nota: Múltiples rutas (LAVIC y BARR) usan los mismos spans troncales
    INSERT INTO dbo.odf_route_segment (id, odf_route_id, cable_span_id, seq)
    VALUES (@SegID, @RouteID, @SpanID, @seq);
    SET @i = @i + 1; SET @seq = @seq + 1;
END;
-- Parte Ramal
SET @i = 1; SET @SpanPrefix = 'SPAN-BARR-';
WHILE @i <= 11 BEGIN
    SET @SegID = 'SEG-SB-R-' + FORMAT(@i, '00'); -- CORREGIDO
    SET @SpanID = @SpanPrefix + FORMAT(@i, '00'); -- CORREGIDO
    INSERT INTO dbo.odf_route_segment (id, odf_route_id, cable_span_id, seq)
    VALUES (@SegID, @RouteID, @SpanID, @seq);
    SET @i = @i + 1; SET @seq = @seq + 1;
END;


PRINT '==================================================';
PRINT 'DATOS MASIVOS INSERTADOS CORRECTAMENTE.';
PRINT 'Total de postes insertados: ~90+';
PRINT 'Total de tramos (spans) insertados: ~96';
PRINT '==================================================';

-- Si todo salió bien, confirma la transacción
COMMIT TRANSACTION;

END TRY
BEGIN CATCH
    -- Si algo falló, revierte todo
    PRINT '¡¡¡ERROR!!! Ocurrió un error al insertar los datos.';
    PRINT 'Mensaje: ' + ERROR_MESSAGE();
    PRINT 'Revisando la transacción (ROLLBACK)...';
    ROLLBACK TRANSACTION;
END CATCH;

GO
SET NOCOUNT OFF;
GO