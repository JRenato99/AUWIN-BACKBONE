/*============================================================
AUWIN - DDL COMPLETO
Crea BD, tablas, índices, vistas y stored procedures
============================================================*/

-- 0) Crear base de datos si no existe
IF DB_ID('AUWIN') IS NULL
BEGIN
  CREATE DATABASE AUWIN;
END
GO

USE AUWIN;
GO

/*=========================
1) TABLAS
=========================*/

-- NODO
CREATE TABLE dbo.nodo (
    id NVARCHAR(64) NOT NULL PRIMARY KEY,
    code NVARCHAR(128) NOT NULL,
    type NVARCHAR(200) NOT NULL,
    name NVARCHAR(200) NOT NULL,
    reference NVARCHAR(400) NULL,
    gps_lat FLOAT NULL,
    gps_lon FLOAT NULL
);
GO

-- ROUTER
CREATE TABLE dbo.router (
  id NVARCHAR(64) NOT NULL PRIMARY KEY,
  nodo_id NVARCHAR(64) NOT NULL,
  name NVARCHAR(200) NOT NULL,
  model NVARCHAR(100) NULL,
  mgmt_ip NVARCHAR(50) NULL,
  total_ports INT NOT NULL,
  -- status NVARCHAR(100) NULL,
  CONSTRAINT FK_Nodo_Router FOREIGN KEY (nodo_id) REFERENCES dbo.nodo(id)
);
GO

-- ROUTER PORT
CREATE TABLE dbo.router_port (
  id NVARCHAR(64) NOT NULL PRIMARY KEY,
  router_id NVARCHAR(64) NOT NULL,
  port_no INT NULL,
  status  NVARCHAR(100) NULL,
  type_port NVARCHAR(100) NOT NULL,
  speed FLOAT NULL,
  CONSTRAINT FK_Router_Puerto FOREIGN KEY (router_id) REFERENCES dbo.router(id)
);
GO

-- ODF
CREATE TABLE dbo.odf (
  id NVARCHAR(64) NOT NULL PRIMARY KEY,
  nodo_id NVARCHAR(64) NOT NULL,
  name NVARCHAR(200) NOT NULL,
  code NVARCHAR(128) NOT NULL,
  total_ports INT NULL,
  CONSTRAINT FK_Nodo_ODF FOREIGN KEY (nodo_id) REFERENCES dbo.nodo(id)
);
GO

-- ODF PORT
CREATE TABLE dbo.odf_port (
  id NVARCHAR(64) NOT NULL PRIMARY KEY,
  odf_id NVARCHAR(64) NOT NULL,
  port_no INT NOT NULL,
  status NVARCHAR(100) NULL,
  connector_type NVARCHAR(100) NULL,
  CONSTRAINT FK_ODF_Port FOREIGN KEY (odf_id) REFERENCES dbo.odf(id)
);
GO

-- LINK ROUTER <-> ODF (patch cord interno)
CREATE TABLE dbo.link_router_odf (
  id NVARCHAR(64) NOT NULL PRIMARY KEY,
  router_port_id NVARCHAR(64) NOT NULL,
  odf_port_id NVARCHAR(64) NOT NULL,
  CONSTRAINT FK_Port_Router_Link FOREIGN KEY (router_port_id) REFERENCES dbo.router_port(id),
  CONSTRAINT FK_Port_ODF_Link FOREIGN KEY (odf_port_id) REFERENCES dbo.odf_port(id)
);
GO

-- POLE (POSTE)
CREATE TABLE dbo.pole (
  id NVARCHAR(64) NOT NULL PRIMARY KEY,
  code NVARCHAR(128) NOT NULL,
  pole_type NVARCHAR(32) NOT NULL,
  owner NVARCHAR(100) NULL,
  high FLOAT NULL,  
  district NVARCHAR(100) NULL,
  address_ref NVARCHAR(400) NULL,
  gps_lat FLOAT NULL,
  gps_lon FLOAT NULL,
  status NVARCHAR(100) NULL,
  has_reserve BIT NOT NULL,
  reserve_length_m FLOAT NULL,
  has_cruceta  BIT NOT NULL,
  has_elem_retencion  BIT NOT NULL,
  has_elem_suspension  BIT NOT NULL,
  declared BIT NULL,
);
GO

-- CABLE
CREATE TABLE dbo.cable (
  id NVARCHAR(64) NOT NULL PRIMARY KEY,
  code NVARCHAR(128) NOT NULL,
  material_type NVARCHAR(32) NULL,
  jacket_type NVARCHAR(32) NULL,
  fiber_count INT null
);
GO
    

-- EXTREMO CABLE <-> ODF 
CREATE TABLE dbo.odf_cable_end (
  id            NVARCHAR(64)  NOT NULL PRIMARY KEY,
  cable_id      NVARCHAR(64)  NOT NULL,
  odf_id        NVARCHAR(64)  NOT NULL,            
  CONSTRAINT FK_OCE_Cable   FOREIGN KEY (cable_id)    REFERENCES dbo.cable(id),
  CONSTRAINT FK_OCE_ODF     FOREIGN KEY (odf_id)      REFERENCES dbo.odf(id),
);
GO

-- FIBRA DENTRO DEL CABLE (FILAMENTO)
CREATE TABLE dbo.fiber_filament (
  id NVARCHAR(64) NOT NULL PRIMARY KEY,
  cable_id NVARCHAR(64) NOT NULL,
  filament_no INT NOT NULL,
  color_code NVARCHAR(32) NULL,
  -- owner 
  CONSTRAINT FK_Cable_FiberFilament FOREIGN KEY (cable_id) REFERENCES dbo.cable(id)
);
GO

-- MUFA
CREATE TABLE dbo.mufa (
  id NVARCHAR(64) NOT NULL PRIMARY KEY,
  code NVARCHAR(128) NOT NULL,
  pole_id NVARCHAR(64) NOT NULL,  
  mufa_type NVARCHAR(32) NOT NULL,
  gps_lat FLOAT NULL,
  gps_lon FLOAT NULL,
  CONSTRAINT FK_Pole_Mufa FOREIGN KEY (pole_id) REFERENCES dbo.pole(id)
);
GO

-- EMPALME (SPLICE)
CREATE TABLE dbo.splice (
  id NVARCHAR(64) NOT NULL PRIMARY KEY,
  mufa_id NVARCHAR(64) NOT NULL,
  a_fiber_filament_id NVARCHAR(64) NOT NULL,
  b_fiber_filament_id NVARCHAR(64) NOT NULL,
  CONSTRAINT FK_Mufa_Empalme FOREIGN KEY (mufa_id) REFERENCES dbo.mufa(id),
  CONSTRAINT FK_A_FiberFilament_Splice FOREIGN KEY (a_fiber_filament_id) REFERENCES dbo.fiber_filament(id),
  CONSTRAINT FK_B_FiberFilament_Splice FOREIGN KEY (b_fiber_filament_id) REFERENCES dbo.fiber_filament(id),
  CONSTRAINT CK_Empalme_FilamentosDistintos CHECK (a_fiber_filament_id <> b_fiber_filament_id)
);
GO

-- RUTA LÓGICA ODF -> ODF
CREATE TABLE dbo.odf_route (
  id NVARCHAR(64) NOT NULL PRIMARY KEY,
  from_odf_id NVARCHAR(64) NOT NULL,
  to_odf_id NVARCHAR(64) NOT NULL, 
  path_text NVARCHAR(2000) NULL, -- resumen textual
  FOREIGN KEY (from_odf_id) REFERENCES dbo.odf(id),
  FOREIGN KEY (to_odf_id) REFERENCES dbo.odf(id),
  CONSTRAINT UQ_ODFRoute_FromTo UNIQUE (from_odf_id, to_odf_id)
);
GO

-- TRAMO FÍSICO DEL CABLE ENTRE POSTES
CREATE TABLE dbo.cable_span (
  id NVARCHAR(64) NOT NULL PRIMARY KEY,
  cable_id NVARCHAR(64) NOT NULL,
  seq INT NOT NULL, -- orden físico dentro del cable
  from_pole_id NVARCHAR(64) NOT NULL,
  to_pole_id NVARCHAR(64) NOT NULL,
  length_m FLOAT NULL, 
  capacity_fibers FLOAT NULL,
  length_span FLOAT NULL,
  FOREIGN KEY (cable_id) REFERENCES dbo.cable(id),
  FOREIGN KEY (from_pole_id) REFERENCES dbo.pole(id), 
  FOREIGN KEY (to_pole_id) REFERENCES dbo.pole(id),
  CONSTRAINT CK_CableSpan_Endpoints CHECK (from_pole_id <> to_pole_id),
  CONSTRAINT UQ_CableSpan_CableSeq UNIQUE (cable_id, seq)
);
GO

-- SEGMENTO DE RUTA (MAPEA RUTA LÓGICA A SPANS FÍSICOS)
CREATE TABLE dbo.odf_route_segment (
  id NVARCHAR(64) NOT NULL PRIMARY KEY,
  segmento_code NVARCHAR(128) NULL, -- etiqueta del tramo
  odf_route_id NVARCHAR(64) NOT NULL, -- ruta logica
  cable_span_id NVARCHAR(64) NOT NULL, -- ruta física
  seq INT NOT NULL, -- Orden del recorrido 
  CONSTRAINT FK_ODFRoute_ODFSegment FOREIGN KEY (odf_route_id) REFERENCES dbo.odf_route(id),
  CONSTRAINT FK_CableSpan_ODFSegment FOREIGN KEY (cable_span_id) REFERENCES dbo.cable_span(id),
  CONSTRAINT UQ_ODFRouteSegment_Order UNIQUE (odf_route_id, seq)
);

-- RELACIÓN FIBRA <-> PUERTO ODF (para llegar al puerto exacto)
CREATE TABLE dbo.odf_port_fiber (
  id NVARCHAR(64) NOT NULL PRIMARY KEY,
  odf_port_id NVARCHAR(64) NOT NULL,
  fiber_filament_id NVARCHAR(64) NOT NULL,
  direction NVARCHAR(16) NULL,    -- A/B, IN/OUT, opcional
  note NVARCHAR(200) NULL,
  CONSTRAINT FK_OPF_Port  FOREIGN KEY (odf_port_id) REFERENCES dbo.odf_port(id),
  CONSTRAINT FK_OPF_Fiber FOREIGN KEY (fiber_filament_id) REFERENCES dbo.fiber_filament(id),
  CONSTRAINT UQ_OPF UNIQUE (odf_port_id, fiber_filament_id)
);

-- Posiciones del layout (vis-network)
IF OBJECT_ID('dbo.graph_node_position') IS NULL
BEGIN
  CREATE TABLE dbo.graph_node_position (
    node_id NVARCHAR(64) NOT NULL PRIMARY KEY,
    x FLOAT NOT NULL,
    y FLOAT NOT NULL,
    updated_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
  );
END
GO

/*=========================
2) ÍNDICES 
=========================*/
-- Rutas físicas por ruta lógica
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_odf_route_segment_route' AND object_id=OBJECT_ID('dbo.odf_route_segment'))
  CREATE INDEX IX_odf_route_segment_route ON dbo.odf_route_segment(odf_route_id, seq);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_odf_route_segment_span' AND object_id=OBJECT_ID('dbo.odf_route_segment'))
  CREATE INDEX IX_odf_route_segment_span ON dbo.odf_route_segment(cable_span_id);
GO
-- Spans por endpoints
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_cable_span_endpoints' AND object_id=OBJECT_ID('dbo.cable_span'))
  CREATE INDEX IX_cable_span_endpoints ON dbo.cable_span(cable_id, from_pole_id, to_pole_id);
GO
-- Mufas por poste
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_mufa_pole' AND object_id=OBJECT_ID('dbo.mufa'))
  CREATE INDEX IX_mufa_pole ON dbo.mufa(pole_id);
GO
-- Splice navegación por fibras
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_splice_a' AND object_id=OBJECT_ID('dbo.splice'))
  CREATE INDEX IX_splice_a ON dbo.splice(a_fiber_filament_id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_splice_b' AND object_id=OBJECT_ID('dbo.splice'))
  CREATE INDEX IX_splice_b ON dbo.splice(b_fiber_filament_id);
GO
-- Endpoints de fibra
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_odf_port_fiber_port' AND object_id=OBJECT_ID('dbo.odf_port_fiber'))
  CREATE INDEX IX_odf_port_fiber_port ON dbo.odf_port_fiber(odf_port_id);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_odf_port_fiber_fiber' AND object_id=OBJECT_ID('dbo.odf_port_fiber'))
  CREATE INDEX IX_odf_port_fiber_fiber ON dbo.odf_port_fiber(fiber_filament_id);
GO

-- Segmentos de ruta
CREATE INDEX IX_odf_route_segment_route_seq
  ON dbo.odf_route_segment(odf_route_id, seq);

CREATE INDEX IX_odf_route_segment_span
  ON dbo.odf_route_segment(cable_span_id);

-- Cable spans (consultas por poste)
CREATE INDEX IX_cable_span_from_to
  ON dbo.cable_span(from_pole_id, to_pole_id);

-- ODF y Router por nodo (para joins rápidos a coordenadas)
CREATE INDEX IX_odf_nodo ON dbo.odf(nodo_id);
CREATE INDEX IX_router_nodo ON dbo.router(nodo_id);
