/*==================================================================
SCRIPT DE INSERCIÓN DE DATOS - PROYECTO AUWIN
====================================================================
Escenario:
1.  Anillo Backbone: NODO-SANI <-> NODO-MIRA <-> NODO-SURCO
2.  Split de Distribución: NODO-SURCO -> MUFA-SPLIT -> NODO-LAVIC
                                                |
                                                +-> NODO-BARR
==================================================================*/

USE tempAUWIN;
GO

SET NOCOUNT ON;
GO

-- Envolver todo en una transacción para asegurar que todo se inserte
-- o nada se inserte si hay un error.
BEGIN TRANSACTION;

BEGIN TRY

-- Declarar variables para los bucles de filamentos/empalmes
DECLARE @i INT;
DECLARE @CableID NVARCHAR(64);
DECLARE @FilamentPrefix NVARCHAR(60);
DECLARE @FilamentID NVARCHAR(64);
DECLARE @FilamentNo INT;

/*============================================================
FASE 1: CREAR ACTIVOS PRINCIPALES (NODOS, POSTES, CABLES)
============================================================*/

PRINT 'FASE 1: Insertando Nodos, Postes y Cables...';

-- 1.1) Nodos (5 Nodos: 3 Distribución, 2 Acceso)
INSERT INTO dbo.nodo (id, code, type, name, reference, gps_lat, gps_lon) VALUES
('NODO-SANI', 'LIM-SANI-001', 'Distribucion', 'Nodo San Isidro', 'Av. Javier Prado Este 210', -12.089, -77.050),
('NODO-MIRA', 'LIM-MIRA-001', 'Distribucion', 'Nodo Miraflores', 'Av. Larco 400', -12.122, -77.030),
('NODO-SURCO', 'LIM-SURCO-001', 'Distribucion', 'Nodo Surco', 'Av. Benavides 5000', -12.138, -77.005),
('NODO-LAVIC', 'LIM-LAVIC-001', 'Acceso', 'Nodo La Victoria', 'Av. Iquitos 800', -12.068, -77.026),
('NODO-BARR', 'LIM-BARR-001', 'Acceso', 'Nodo Barranco', 'Av. Grau 300', -12.140, -77.020);

-- 1.2) Postes (10 postes para crear las rutas)
INSERT INTO dbo.pole (id, code, pole_type, owner, high, district, address_ref, gps_lat, gps_lon, status, has_reserve, reserve_length_m, has_cruceta, has_elem_retencion, has_elem_suspension) VALUES
('P-SM-01', 'POLE-1001', 'Concreto', 'Luz del Sur', 12, 'San Isidro', 'Cerca NODO-SANI', -12.090, -77.050, 'Activo', 0, 0, 1, 1, 0),
('P-SM-02', 'POLE-1002', 'Concreto', 'Luz del Sur', 12, 'Miraflores', 'Cerca NODO-MIRA', -12.121, -77.030, 'Activo', 1, 20, 1, 1, 0),
('P-MS-01', 'POLE-2001', 'Concreto', 'Luz del Sur', 12, 'Miraflores', 'Cerca NODO-MIRA', -12.123, -77.030, 'Activo', 0, 0, 1, 1, 0),
('P-MS-02', 'POLE-2002', 'Concreto', 'Luz del Sur', 12, 'Surco', 'Cerca NODO-SURCO', -12.137, -77.005, 'Activo', 1, 20, 1, 1, 0),
('P-SS-01', 'POLE-3001', 'Concreto', 'Luz del Sur', 12, 'Surco', 'Cerca NODO-SURCO', -12.138, -77.004, 'Activo', 0, 0, 1, 1, 0),
('P-SS-02', 'POLE-3002', 'Concreto', 'Luz del Sur', 12, 'San Isidro', 'Cerca NODO-SANI', -12.089, -77.049, 'Activo', 1, 20, 1, 1, 0),
('P-SPLIT-01', 'POLE-4001', 'Concreto', 'Luz del Sur', 12, 'Surco', 'Salida SURCO para Split', -12.139, -77.005, 'Activo', 0, 0, 1, 1, 0),
('P-SPLIT-02', 'POLE-4002', 'Concreto', 'Luz del Sur', 12, 'Surco', 'Poste de la MUFA-SPLIT', -12.140, -77.010, 'Activo', 1, 40, 1, 1, 1),
('P-SL-01', 'POLE-5001', 'Concreto', 'Luz del Sur', 12, 'La Victoria', 'Cerca NODO-LAVIC', -12.069, -77.026, 'Activo', 0, 0, 1, 1, 0),
('P-SB-01', 'POLE-6001', 'Concreto', 'Luz del Sur', 12, 'Barranco', 'Cerca NODO-BARR', -12.140, -77.019, 'Activo', 0, 0, 1, 1, 0);

-- 1.3) Cables (3 de 144 hilos para el anillo, 1 de 96 y 2 de 48 para el split)
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

-- 2.3) Puertos de Router (Crearemos los puertos que conectan al ODF)
-- Puertos para el Anillo
INSERT INTO dbo.router_port (id, router_id, port_no, status, type_port, speed) VALUES
('RP-SANI-01-P1', 'RTR-SANI-01', 1, 'Up', '100GE', 100000),
('RP-MIRA-01-P1', 'RTR-MIRA-01', 1, 'Up', '100GE', 100000),
('RP-MIRA-02-P1', 'RTR-MIRA-02', 1, 'Up', '100GE', 100000),
('RP-SURCO-01-P1', 'RTR-SURCO-01', 1, 'Up', '100GE', 100000),
('RP-SURCO-02-P1', 'RTR-SURCO-02', 1, 'Up', '100GE', 100000),
('RP-SANI-02-P1', 'RTR-SANI-02', 1, 'Up', '100GE', 100000),
-- Puertos para el Split
('RP-SURCO-01-P2', 'RTR-SURCO-01', 2, 'Up', '10GE', 10000), -- Salida a LAVIC
('RP-SURCO-01-P3', 'RTR-SURCO-01', 3, 'Up', '10GE', 10000), -- Salida a BARR
('RP-LAVIC-01-P1', 'RTR-LAVIC-01', 1, 'Up', '10GE', 10000),
('RP-BARR-01-P1', 'RTR-BARR-01', 1, 'Up', '10GE', 10000);

-- 2.4) Puertos de ODF
-- Puertos para el Anillo
INSERT INTO dbo.odf_port (id, odf_id, port_no, status, connector_type) VALUES
('OP-SANI-01-P1', 'ODF-SANI-01', 1, 'Connected', 'LC'),
('OP-MIRA-01-P1', 'ODF-MIRA-01', 1, 'Connected', 'LC'),
('OP-MIRA-02-P1', 'ODF-MIRA-02', 1, 'Connected', 'LC'),
('OP-SURCO-01-P1', 'ODF-SURCO-01', 1, 'Connected', 'LC'),
('OP-SURCO-02-P1', 'ODF-SURCO-02', 1, 'Connected', 'LC'),
('OP-SANI-02-P1', 'ODF-SANI-02', 1, 'Connected', 'LC'),
-- Puertos para el Split
('OP-SURCO-01-P2', 'ODF-SURCO-01', 2, 'Connected', 'LC'), -- Salida a LAVIC
('OP-SURCO-01-P3', 'ODF-SURCO-01', 3, 'Connected', 'LC'), -- Salida a BARR
('OP-LAVIC-01-P1', 'ODF-LAVIC-01', 1, 'Connected', 'LC'),
('OP-BARR-01-P1', 'ODF-BARR-01', 1, 'Connected', 'LC');

-- 2.5) Links Internos (Patch Cords)
INSERT INTO dbo.link_router_odf (id, router_port_id, odf_port_id) VALUES
-- Anillo
('LNK-SANI-01', 'RP-SANI-01-P1', 'OP-SANI-01-P1'),
('LNK-MIRA-01', 'RP-MIRA-01-P1', 'OP-MIRA-01-P1'),
('LNK-MIRA-02', 'RP-MIRA-02-P1', 'OP-MIRA-02-P1'),
('LNK-SURCO-01', 'RP-SURCO-01-P1', 'OP-SURCO-01-P1'),
('LNK-SURCO-02', 'RP-SURCO-02-P1', 'OP-SURCO-02-P1'),
('LNK-SANI-02', 'RP-SANI-02-P1', 'OP-SANI-02-P1'),
-- Split
('LNK-SURCO-LAVIC', 'RP-SURCO-01-P2', 'OP-SURCO-01-P2'),
('LNK-SURCO-BARR', 'RP-SURCO-01-P3', 'OP-SURCO-01-P3'),
('LNK-LAVIC-01', 'RP-LAVIC-01-P1', 'OP-LAVIC-01-P1'),
('LNK-BARR-01', 'RP-BARR-01-P1', 'OP-BARR-01-P1');


/*============================================================
FASE 3: CREAR PLANTA EXTERNA (MUFAS, TRAMOS DE CABLE)
============================================================*/

PRINT 'FASE 3: Insertando Planta Externa (Mufas, Tramos de Cable)...';

-- 3.1) Mufas (1 mufa en cada poste intermedio del anillo + 1 mufa para el split)
INSERT INTO dbo.mufa (id, code, pole_id, mufa_type, gps_lat, gps_lon) VALUES
('MUFA-SM', 'MFA-1002', 'P-SM-02', 'Empalme', -12.121, -77.030),
('MUFA-MS', 'MFA-2002', 'P-MS-02', 'Empalme', -12.137, -77.005),
('MUFA-SS', 'MFA-3002', 'P-SS-02', 'Empalme', -12.089, -77.049),
('MUFA-SPLIT', 'MFA-4002-SPLIT', 'P-SPLIT-02', 'Segregacion', -12.140, -77.010);

-- 3.2) Tramos Físicos de Cable (Cable Spans)
INSERT INTO dbo.cable_span (id, cable_id, seq, from_pole_id, to_pole_id, length_m, capacity_fibers, length_span) VALUES
-- Anillo
('SPAN-SM-01', 'CABLE-SM', 1, 'P-SM-01', 'P-SM-02', 1500, 144, 1500), -- SANI -> MUFA-SM
('SPAN-MS-01', 'CABLE-MS', 1, 'P-MS-01', 'P-MS-02', 1800, 144, 1800), -- MIRA -> MUFA-MS
('SPAN-SS-01', 'CABLE-SS', 1, 'P-SS-01', 'P-SS-02', 1200, 144, 1200), -- SURCO -> MUFA-SS
-- Split
('SPAN-SPLIT-TRONCAL', 'CABLE-TRONCAL-SPLIT', 1, 'P-SPLIT-01', 'P-SPLIT-02', 500, 96, 500), -- SURCO -> MUFA-SPLIT
('SPAN-SPLIT-LAVIC', 'CABLE-RAMAL-LAVIC', 1, 'P-SPLIT-02', 'P-SL-01', 2000, 48, 2000), -- MUFA-SPLIT -> LAVIC
('SPAN-SPLIT-BARR', 'CABLE-RAMAL-BARR', 1, 'P-SPLIT-02', 'P-SB-01', 1000, 48, 1000); -- MUFA-SPLIT -> BARR


/*============================================================
FASE 4: CREAR FILAMENTOS (CON BUCLES)
============================================================*/

PRINT 'FASE 4: Generando filamentos (Esto puede tardar un momento)...';

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
FASE 5: CREAR EMPALMES (SPLICES)
============================================================*/

PRINT 'FASE 5: Creando empalmes...';

-- 5.1) Empalmes del Anillo (Passthrough simple Hilo 1 -> Hilo 1)
-- MUFA-SM (Conecta CABLE-SM Hilo 1 con CABLE-MS Hilo 1)
INSERT INTO dbo.splice (id, mufa_id, a_fiber_filament_id, b_fiber_filament_id)
VALUES ('SPL-SM-001', 'MUFA-SM', 'FF-SM-001', 'FF-MS-001');

-- MUFA-MS (Conecta CABLE-MS Hilo 1 con CABLE-SS Hilo 1)
INSERT INTO dbo.splice (id, mufa_id, a_fiber_filament_id, b_fiber_filament_id)
VALUES ('SPL-MS-001', 'MUFA-MS', 'FF-MS-001', 'FF-SS-001'); -- Aquí hay un error de diseño del anillo, un cable no puede estar en 2 mufas.
-- CORRECCIÓN DE DISEÑO: Un cable va DE ODF A MUFA. El siguiente cable va DE MUFA A ODF.
-- Vamos a re-crear los empalmes del anillo correctamente.
DELETE FROM dbo.splice WHERE id IN ('SPL-SM-001', 'SPL-MS-001');

-- SANI -> MIRA (Usa Hilo 1 de CABLE-SM y Hilo 1 de CABLE-MS, unidos en MUFA-SM)
INSERT INTO dbo.splice (id, mufa_id, a_fiber_filament_id, b_fiber_filament_id)
VALUES ('SPL-RING-SM', 'MUFA-SM', 'FF-SM-001', 'FF-MS-001');

-- MIRA -> SURCO (Usa Hilo 1 de CABLE-MS y Hilo 1 de CABLE-SS, unidos en MUFA-MS)
-- ¡Espera! El CABLE-MS no puede terminar en NODO-MIRA y a la vez en MUFA-MS.
-- ¡Ah! El CABLE-MS debe ir de MUFA-SM a MUFA-MS. Los cables de ODF deben ser otros.

-- =========================================================================
-- RE-PLANIFICACIÓN DE CABLES (Más simple y correcto):
-- Un cable por cada ruta ODF-ODF. Los empalmes se hacen en las mufas.
-- SANI-MIRA: CABLE-SM (pasa por MUFA-SM)
-- MIRA-SURCO: CABLE-MS (pasa por MUFA-MS)
-- SURCO-SANI: CABLE-SS (pasa por MUFA-SS)
-- Esto significa que la MUFA no une cables diferentes, solo es un punto de paso.
-- El SPLICE es para UNIR filamentos. El escenario del anillo es más simple:
-- El Hilo 1 de CABLE-SM conecta ODF-SANI-01 y ODF-MIRA-01.
-- El Hilo 1 de CABLE-MS conecta ODF-MIRA-02 y ODF-SURCO-01.
-- El Hilo 1 de CABLE-SS conecta ODF-SURCO-02 y ODF-SANI-02.
-- Por lo tanto, ¡NO HAY EMPALMES PARA EL ANILLO! (Son rutas directas)
-- =========================================================================

DELETE FROM dbo.splice; -- Limpiamos los empalmes erróneos del anillo.

-- 5.2) Empalmes del SPLIT (¡Este es el escenario importante!)
-- En MUFA-SPLIT, el CABLE-TRONCAL-SPLIT (96) se divide en:
--   -> CABLE-RAMAL-LAVIC (48)
--   -> CABLE-RAMAL-BARR (48)

PRINT 'FASE 5.2: Creando empalmes del SPLIT...';

-- Bucle 1: Conectar Hilos 1-48 del Troncal a LAVIC
SET @i = 1;
WHILE @i <= 48 BEGIN
    DECLARE @SpliceID_A NVARCHAR(64) = 'SPL-LAVIC-' + FORMAT(@i, '000');
    DECLARE @Fiber_A NVARCHAR(64) = 'FF-TRONCAL-' + FORMAT(@i, '000');
    DECLARE @Fiber_B NVARCHAR(64) = 'FF-LAVIC-' + FORMAT(@i, '000');
    
    INSERT INTO dbo.splice (id, mufa_id, a_fiber_filament_id, b_fiber_filament_id)
    VALUES (@SpliceID_A, 'MUFA-SPLIT', @Fiber_A, @Fiber_B);
    
    SET @i = @i + 1;
END;

-- Bucle 2: Conectar Hilos 49-96 del Troncal a BARR
SET @i = 49;
WHILE @i <= 96 BEGIN
    SET @FilamentNo = @i - 48; -- El Hilo 49 del troncal va al Hilo 1 de Barranco
    
    DECLARE @SpliceID_B NVARCHAR(64) = 'SPL-BARR-' + FORMAT(@FilamentNo, '000');
    DECLARE @Fiber_A_B NVARCHAR(64) = 'FF-TRONCAL-' + FORMAT(@i, '000');
    DECLARE @Fiber_B_B NVARCHAR(64) = 'FF-BARR-' + FORMAT(@FilamentNo, '000');
    
    INSERT INTO dbo.splice (id, mufa_id, a_fiber_filament_id, b_fiber_filament_id)
    VALUES (@SpliceID_B, 'MUFA-SPLIT', @Fiber_A_B, @Fiber_B_B);
    
    SET @i = @i + 1;
END;


/*============================================================
FASE 6: CONECTAR CABLES A ODFS (Inicio y Fin de Rutas)
============================================================*/

PRINT 'FASE 6: Conectando cables y filamentos a ODFs...';

-- 6.1) odf_cable_end (Qué cable llega a qué ODF)
INSERT INTO dbo.odf_cable_end (id, cable_id, odf_id) VALUES
-- Anillo
('OCE-SANI-01', 'CABLE-SM', 'ODF-SANI-01'),
('OCE-MIRA-01', 'CABLE-SM', 'ODF-MIRA-01'),
('OCE-MIRA-02', 'CABLE-MS', 'ODF-MIRA-02'),
('OCE-SURCO-01', 'CABLE-MS', 'ODF-SURCO-01'),
('OCE-SURCO-02', 'CABLE-SS', 'ODF-SURCO-02'),
('OCE-SANI-02', 'CABLE-SS', 'ODF-SANI-02'),
-- Split
('OCE-SPLIT-TRONCAL', 'CABLE-TRONCAL-SPLIT', 'ODF-SURCO-01'),
('OCE-SPLIT-LAVIC', 'CABLE-RAMAL-LAVIC', 'ODF-LAVIC-01'),
('OCE-SPLIT-BARR', 'CABLE-RAMAL-BARR', 'ODF-BARR-01');

-- 6.2) odf_port_fiber (Qué puerto ODF usa qué filamento)
INSERT INTO dbo.odf_port_fiber (id, odf_port_id, fiber_filament_id, direction) VALUES
-- Anillo
('OPF-SANI-01', 'OP-SANI-01-P1', 'FF-SM-001', 'A'),
('OPF-MIRA-01', 'OP-MIRA-01-P1', 'FF-SM-001', 'B'),
('OPF-MIRA-02', 'OP-MIRA-02-P1', 'FF-MS-001', 'A'),
('OPF-SURCO-01', 'OP-SURCO-01-P1', 'FF-MS-001', 'B'),
('OPF-SURCO-02', 'OP-SURCO-02-P1', 'FF-SS-001', 'A'),
('OPF-SANI-02', 'OP-SANI-02-P1', 'FF-SS-001', 'B'),
-- Split
('OPF-SURCO-LAVIC', 'OP-SURCO-01-P2', 'FF-TRONCAL-001', 'A'), -- Hilo 1 del troncal
('OPF-LAVIC', 'OP-LAVIC-01-P1', 'FF-LAVIC-001', 'B'), -- Hilo 1 de lavic
('OPF-SURCO-BARR', 'OP-SURCO-01-P3', 'FF-TRONCAL-049', 'A'), -- Hilo 49 del troncal
('OPF-BARR', 'OP-BARR-01-P1', 'FF-BARR-001', 'B'); -- Hilo 1 de barranco


/*============================================================
FASE 7: CREAR RUTAS LÓGICAS (Servicios)
============================================================*/
-- Esto es para el algoritmo de diagnóstico. Mapea las rutas lógicas
-- a los tramos físicos.

PRINT 'FASE 7: Creando rutas lógicas y segmentos...';

-- 7.1) odf_route (Las rutas de servicio)
INSERT INTO dbo.odf_route (id, from_odf_id, to_odf_id, path_text) VALUES
('ROUTE-SANI-MIRA', 'ODF-SANI-01', 'ODF-MIRA-01', 'Ruta Backbone SANI-MIRA'),
('ROUTE-MIRA-SURCO', 'ODF-MIRA-02', 'ODF-SURCO-01', 'Ruta Backbone MIRA-SURCO'),
('ROUTE-SURCO-SANI', 'ODF-SURCO-02', 'ODF-SANI-02', 'Ruta Backbone SURCO-SANI'),
('ROUTE-SURCO-LAVIC', 'ODF-SURCO-01', 'ODF-LAVIC-01', 'Ruta Acceso SURCO-LAVIC'),
('ROUTE-SURCO-BARR', 'ODF-SURCO-01', 'ODF-BARR-01', 'Ruta Acceso SURCO-BARR');

-- 7.2) odf_route_segment (Qué tramos físicos usa cada ruta)
INSERT INTO dbo.odf_route_segment (id, odf_route_id, cable_span_id, seq) VALUES
-- Anillo
('SEG-SM-01', 'ROUTE-SANI-MIRA', 'SPAN-SM-01', 1),
('SEG-MS-01', 'ROUTE-MIRA-SURCO', 'SPAN-MS-01', 1),
('SEG-SS-01', 'ROUTE-SURCO-SANI', 'SPAN-SS-01', 1),
-- Split
('SEG-SL-01', 'ROUTE-SURCO-LAVIC', 'SPAN-SPLIT-TRONCAL', 1),
('SEG-SL-02', 'ROUTE-SURCO-LAVIC', 'SPAN-SPLIT-LAVIC', 2),
('SEG-SB-01', 'ROUTE-SURCO-BARR', 'SPAN-SPLIT-TRONCAL', 1),
('SEG-SB-02', 'ROUTE-SURCO-BARR', 'SPAN-SPLIT-BARR', 2);


PRINT '==================================================';
PRINT 'DATOS INSERTADOS CORRECTAMENTE.';
PRINT 'Escenario Creado: Anillo de 3 Nodos y Split de 1 a 2.';
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