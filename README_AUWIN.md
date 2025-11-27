# AUWIN BACKBONE

Visualizador de topología de **backbone de fibra óptica (tipo AUTIN)**, construido con:

- **SQL Server** para el modelo de red (nodos, ODF, postes, cables, mufas, fibras, rutas, etc.).
- **FastAPI (Python)** como backend de APIs.
- **React + Vite + vis-network** como frontend para graficar la red y explorar el inventario.

El objetivo es tener una herramienta para:

- Ver el **overview del backbone** (nodos, routers, ODF, postes, mufas).
- Navegar **rutas ODF–ODF** y su detalle físico (postes, spans, mufas, cables).
- Consultar **inventario y KPIs** de una ruta.
- Hacer **trazado de fibra** desde un `fiber_id` o desde un **puerto ODF**.
- Guardar y reutilizar **posiciones de nodos** en el grafo.

---

## Tecnologías principales

### Backend

- Python 3.x
- FastAPI
- SQLAlchemy 2.x
- pyodbc (conexión a SQL Server)
- pydantic-settings
- Uvicorn (ASGI server)

### Frontend

- React 18
- Vite 5
- React Router DOM 6
- vis-network (grafo interactivo)
- Axios

### Base de datos

- Microsoft **SQL Server**
- Scripts T-SQL en carpeta `querys/`:
  - Creación de BD y tablas.
  - Creación de vistas.
  - Datos de ejemplo.
  - Stored procedures para posiciones y trazado de fibra.

---

## Arquitectura de alto nivel

```text
                ┌────────────────────────┐
                │        Frontend        │
                │   React + Vite +       │
                │   vis-network          │
                └─────────▲──────────────┘
                          │ HTTP (JSON)
                          │
                ┌─────────┴──────────────┐
                │        Backend         │
                │   FastAPI + SQLAlchemy │
                │   /graph /topology     │
                │   /fibers /health      │
                └─────────▲──────────────┘
                          │ pyodbc
                          │
                ┌─────────┴──────────────┐
                │      SQL Server        │
                │  Tablas + Vistas + SP  │
                └────────────────────────┘
```

---

## Estructura del repositorio

```text
AUWIN-BACKBONE-main/
├── backend/          # API FastAPI (Python)
│   ├── main.py
│   ├── requeriments.txt
│   ├── .env          # Configuración local (ejemplo incluido)
│   ├── core/
│   │   ├── config.py # Lectura de variables de entorno
│   │   ├── db.py     # Conexión a SQL Server (pyodbc + SQLAlchemy)
│   │   └── util.py   # Utilidades para posiciones de nodos
│   └── api/
│       ├── routes_graph.py      # Endpoints /graph (overview)
│       ├── routes_positions.py  # Endpoints /graph/positions
│       ├── routes_topology.py   # Endpoints /topology (rutas, nodos, postes, mufas)
│       └── routes_fibers.py     # Endpoints /fibers (trazado de fibra)
│
├── frontend/         # SPA React + Vite
│   ├── .env          # VITE_API_BASE=...
│   ├── package.json
│   ├── vite.config.js
│   └── src/
│       ├── main.jsx
│       ├── App.jsx
│       ├── api/client.js        # Axios configurado con VITE_API_BASE
│       ├── components/          # Componentes UI y grafos
│       │   ├── GraphOverview.jsx
│       │   ├── RouteDetailGraph.jsx
│       │   ├── RouteList.jsx
│       │   ├── DetailsPanel.jsx
│       │   ├── FiberTracePanel.jsx
│       │   ├── LayerControls.jsx
│       │   └── Toolbar.jsx
│       ├── pages/
│       │   ├── OverviewPage.jsx
│       │   └── RoutePage.jsx
│       └── styles/app.css       # Estilos generales (tema naranja)
│
└── querys/          # Scripts T-SQL
    ├── Create BD.sql
    ├── Create View.sql
    ├── Insert Data v2.sql
    ├── Insert Data.sql
    ├── sp_seed_default_positions.sql
    └── sp_trace_filament.sql
```

---

## Puesta en marcha rápida

### 1. Preparar la base de datos (SQL Server)

1. Abrir **SQL Server Management Studio** (SSMS) u otra herramienta.
2. Ejecutar en este orden los scripts de la carpeta `querys/`:

   1. `Create BD.sql`  
      - Crea la base de datos `AUWIN` (si no existe) y **todas las tablas** y constraints.
   2. `Create View.sql`  
      - Crea las **vistas** necesarias para el grafo y la topología:
        - `vw_backbone_nodes`, `vw_backbone_edges`
        - `vw_graph_nodes`, `vw_graph_edges`
        - `vw_route_segments_expanded`, `vw_route_physical_summary`
        - `vw_route_summary`, `vw_route_detail`
        - `vw_fiber_splice`, `vw_router_odf_link`, etc.
   3. `Insert Data v2.sql`  
      - Inserta **datos de ejemplo** para nodos, ODF, postes, cables, mufas, rutas, etc.
      - `Insert Data.sql` es una versión anterior de ejemplo (opcional).
   4. `sp_seed_default_positions.sql`  
      - Crea/actualiza el **stored procedure** `dbo.sp_seed_default_positions`, que genera posiciones por defecto para ciertos nodos en `graph_node_position`.
      - Puedes llamarlo manualmente si quieres sembrar posiciones de prueba:
        ```sql
        EXEC dbo.sp_seed_default_positions @col_sep = 240.0, @row_sep = 180.0, @cols = 6;
        ```
   5. `sp_trace_filament.sql`  
      - Crea/actualiza el **stored procedure** `dbo.sp_trace_filament` que hace un **trazado recursivo de fibra** a partir de un `fiber_filament_id`.  
      - Es utilizado por los endpoints `/fibers/*` del backend.

> ⚠️ Importante: la BD creada por defecto se llama `AUWIN`. Asegúrate de que el valor de `DB_NAME` en el `.env` del backend coincida con el nombre de tu base de datos (puedes usar `AUWIN` o un nombre alterno, pero deben coincidir).

---

### 2. Configurar y levantar el backend (FastAPI)

Ir a la carpeta `backend/`:

```bash
cd backend
```

#### 2.1. Crear entorno virtual (opcional pero recomendado)

```bash
python -m venv .venv
# En Windows:
.venv\Scriptsctivate
# En Linux/Mac:
source .venv/bin/activate
```

#### 2.2. Instalar dependencias

```bash
pip install -r requeriments.txt
```

Dependencias principales:

- fastapi
- uvicorn[standard]
- SQLAlchemy
- pyodbc
- pydantic-settings
- python-dotenv

#### 2.3. Configurar variables de entorno (.env)

En `backend/.env`:

```env
DB_SERVER=MI_SERVIDOR_SQL          # Ej: localhost, MIHOST\SQLEXPRESS, etc.
DB_NAME=AUWIN                      # Debe coincidir con la BD creada con los scripts
CORS_ORIGINS=http://localhost:5173 # URL del frontend (Vite dev server)
```

> El backend usa **Windows Authentication** (`Trusted_Connection=yes`).  
> El usuario de Windows con el que se ejecuta el backend debe tener permisos sobre la BD.

#### 2.4. Ejecutar el backend

Desde `backend/`:

```bash
uvicorn main:app --reload --port 8000
```

El backend quedará expuesto por defecto en:

- `http://127.0.0.1:8000`

Prueba rápida de salud de la BD:

- `GET http://127.0.0.1:8000/health/db`  
  → debería responder algo como: `{"ok": true}`

---

### 3. Configurar y levantar el frontend (React + Vite)

Ir a la carpeta `frontend/`:

```bash
cd frontend
```

#### 3.1. Configurar `.env` del frontend

En `frontend/.env`:

```env
VITE_API_BASE=http://127.0.0.1:8000
```

Ese valor debe apuntar a la URL donde corre el backend.

#### 3.2. Instalar dependencias

```bash
npm install
```

#### 3.3. Ejecutar en modo desarrollo

```bash
npm run dev
```

Por defecto Vite expone la app en:

- `http://localhost:5173`

---

## Funcionalidades principales

### 1. Overview del backbone

Página: **`/overview`**

- Carga datos desde `GET /graph/overview`.
- Muestra un grafo con:
  - **Nodos** (sites físicos).
  - **ODFs**.
  - **Postes**.
  - **Mufas**.
  - Otros elementos según la vista (`vw_graph_nodes` + `vw_graph_edges`).
- Usa **vis-network** para:
  - Zoom, drag, selección, tooltips y navegación.
- Incluye controles para activar/desactivar capas (`LayerControls`).

### 2. Lista de rutas ODF–ODF

En el sidebar (componente `RouteList.jsx`):

- Carga `GET /topology/routes`.
- Muestra las rutas definidas en la BD (`odf_route`) con resumen de:
  - ODF origen y destino.
  - Nodos involucrados.
  - Texto descriptivo del camino (`path_text`).
- Permite ir al detalle de una ruta (`/routes/:routeId`).

### 3. Detalle de ruta (grafo físico y KPIs)

Página: **`/routes/:routeId`**  
Componente principal: `RouteDetailGraph.jsx`.

Consume:

- `GET /topology/routes/{route_id}/graph`
  - Genera un grafo con:
    - ODF origen/destino.
    - Postes intermedios en orden.
    - Mufas asociadas a los postes.
    - Spans de cable (`cable_span`).
- `GET /topology/routes/{route_id}/inventory`
  - KPIs de la ruta:
    - Lista de spans.
    - Longitud total en metros.
    - Cantidad de postes.
    - Cantidad de mufas.
    - Cables involucrados.
- `GET /topology/routes/{route_id}/graph-with-access`
  - Extiende el grafo añadiendo:
    - Routers de acceso (en los nodos de extremo).
    - Enlaces router ↔ ODF (`link_router_odf`).

### 4. Detalles de nodo, poste y mufa

Endpoints disponibles:

- `GET /topology/nodes/{nodo_id}/details`
  - Información del nodo:
    - Datos básicos (nombre, código, referencia, GPS).
    - Routers que pertenecen al nodo.
    - ODFs del nodo.
    - Rutas que pasan por esos ODF.

- `GET /topology/poles/{pole_id}/details`
  - Información del poste:
    - Spans que lo usan.
    - Mufas relacionadas.
    - Postes vecinos (conectividad).

- `GET /topology/mufas/{mufa_id}/splices`
  - Información de la mufa:
    - Empalmes (`splice`) a nivel de fibra.
    - Para cada empalme, cables y filamentos conectados.
    - Grupos de empalmes por par de cables (`pair`, `count`).

### 5. Trazado de fibra

Componente: `FiberTracePanel.jsx`  
Endpoints:

- `GET /fibers/{fiber_id}/trace`
  - Ejecuta `sp_trace_filament` en la BD.
  - Devuelve una secuencia de **hops** con la traza desde el filamento inicial.

- `GET /fibers/odf-ports/{port_id}/trace`
  - Busca el `fiber_filament_id` asociado a un **puerto ODF** (`odf_port_fiber`).
  - Llama internamente a `/fibers/{fiber_id}/trace`.

- `GET /fibers/{fiber_id}/endpoints`
  - Devuelve los **puertos ODF** donde termina esa fibra:
    - `odf_port_id`, `odf_id`, `odf_name`, `odf_code`, `port_no`.

### 6. Posiciones de nodos en el grafo

La tabla `dbo.graph_node_position` guarda posiciones **(x, y)** para IDs de nodos del grafo.

Endpoints:

- `POST /graph/positions`
  - Recibe una lista de objetos `{ node_id, x, y }`.
  - Hace un **MERGE** (UPSERT) en la tabla `graph_node_position`.

- `DELETE /graph/positions`
  - Borra todas las posiciones guardadas.

- `POST /graph/positions/seed-defaults?radius=...`
  - Asigna posiciones por defecto a nodos que no tengan registro en `graph_node_position`, usando un layout circular y un radio configurable.

El frontend (`GraphOverview.jsx`) utiliza estos endpoints para **persistir el layout** que el usuario acomoda manualmente.

---

## Resumen de endpoints principales

| Módulo         | Endpoint                             | Método | Descripción rápida                              |
|----------------|--------------------------------------|--------|-------------------------------------------------|
| Health         | `/health/db`                         | GET    | Verifica conexión a la BD                       |
| Graph          | `/graph/nodes`                       | GET    | Nodos del backbone (vista simplificada)        |
| Graph          | `/graph/edges`                       | GET    | Enlaces del backbone (vista simplificada)      |
| Graph          | `/graph/full`                        | GET    | Grafo completo (vista unificada)               |
| Graph          | `/graph/overview`                    | GET    | Grafo preparado para overview (usado por UI)   |
| Positions      | `/graph/positions`                   | POST   | Guarda/actualiza posiciones de nodos           |
| Positions      | `/graph/positions`                   | DELETE | Limpia todas las posiciones                    |
| Positions      | `/graph/positions/seed-defaults`     | POST   | Genera posiciones por defecto                  |
| Topology       | `/topology/routes`                   | GET    | Lista de rutas ODF–ODF                         |
| Topology       | `/topology/routes/{id}/graph`        | GET    | Grafo físico de la ruta                        |
| Topology       | `/topology/routes/{id}/inventory`    | GET    | KPIs e inventario de la ruta                   |
| Topology       | `/topology/routes/{id}/graph-with-access` | GET | Grafo de ruta + routers de acceso              |
| Topology       | `/topology/nodes/{nodo_id}/details`  | GET    | Detalle de un nodo                             |
| Topology       | `/topology/poles/{pole_id}/details`  | GET    | Detalle de un poste                            |
| Topology       | `/topology/mufas/{mufa_id}/splices`  | GET    | Detalle de empalmes de una mufa                |
| Fibers         | `/fibers/{fiber_id}/trace`           | GET    | Traza recursiva de una fibra                   |
| Fibers         | `/fibers/odf-ports/{port_id}/trace`  | GET    | Traza fibra partiendo de un puerto ODF         |
| Fibers         | `/fibers/{fiber_id}/endpoints`       | GET    | Puertos ODF asociados a una fibra              |

---

## Notas y posibles extensiones

- El modelo de datos está pensado para **FTTH/backbone** pero puede extenderse a otros escenarios añadiendo tablas/vistas.
- El stored `sp_trace_filament` se puede ajustar según la lógica real de empalmes.
- La UI actual se enfoca en:
  - **Overview** del backbone.
  - **Detalle** de rutas.
  - **Trazado** de fibra.
- Futuras mejoras posibles:
  - Filtros por estado, tipo de elemento, zona geográfica.
  - Integración con sistemas externos (TR-069/ACS, NMS, etc.).
  - Vista geográfica usando coordenadas GPS y mapas.

---

## Licencia

Este proyecto se distribuye para uso interno / académico.  
Adapta esta sección según las necesidades (MIT, propietario, etc.).
