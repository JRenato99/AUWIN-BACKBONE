from fastapi import APIRouter, HTTPException
from core.db import fetch_all
from math import cos, sin, tau
from datetime import datetime
from typing import Dict, Tuple
from core.util import _angle_from_id

router = APIRouter(prefix="/graph", tags=["graph"])

USE_UNIFIED_VIEWS_FOR_FULL = True


def _load_positions_map() -> Dict[str, Tuple[float, float]]:
    try:
        rows = fetch_all(
            """
            SELECT node_id, x, y FROM dbo.graph_node_position
        """
        )
        out: Dict[str, Tuple[float, float]] = {}
        for r in rows:
            nid = r.get("node_id")
            x = r.get("x")
            y = r.get("y")
            if nid is not None and x is not None and y is not None:
                out[str(nid)] = (float(x), float(y))
        return out
    except Exception:
        return {}


# ENDPOINTS
# ---------------------------------- NO SE ESTA USANDO ACTUALMENTE ---------------------------------------- LEGACY
@router.get("/nodes")
def get_nodes():
    sql = """
        SELECT nodo_id AS id, nodo_code, nodo_name, gps_lat, gps_lon
        FROM vw_backbone_nodes
        """
    try:
        return fetch_all(sql)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"DB_ERROR_NODES: {e}")


# ---------------------------------- NO SE ESTA USANDO ACTUALMENTE ---------------------------------------- LEGACY
@router.get("/edges")
def get_edges():
    sql = """
        SELECT route_id AS id, from_nodo_id as source, to_nodo_id as target, path_text
        FROM vw_backbone_edges
        """
    try:
        return fetch_all(sql)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"DB_ERROR_EDGES: {e}")


# ---------------------------------- NO SE ESTA USANDO ACTUALMENTE ---------------------------------------- LEGACY
@router.get("/full")
def get_full():
    try:
        if USE_UNIFIED_VIEWS_FOR_FULL:
            # ---------- NODOS (unificados) ----------
            nodes_rows = fetch_all(
                """
                SELECT id, kind, label, site_id, gps_lat, gps_lon, layer
                FROM dbo.vw_graph_nodes;
            """
            )
            # ---------- ARISTAS (unificadas) ----------
            edges_rows = fetch_all(
                """
                SELECT id, [from], [to], edge_kind, length_m, layer, path_text
                FROM dbo.vw_graph_edges;
            """
            )
        else:
            nodes_rows = fetch_all(
                """
                SELECT
                  CAST(nodo_id AS NVARCHAR(200)) AS id,
                  COALESCE(nodo_code, nodo_name, CAST(nodo_id AS NVARCHAR(200))) AS label
                FROM dbo.vw_backbone_nodes;
            """
            )
            edges_rows = fetch_all(
                """
                SELECT
                  route_id AS id,
                  CAST(from_nodo_id AS NVARCHAR(200)) AS [from],
                  CAST(to_nodo_id   AS NVARCHAR(200)) AS [to],
                  path_text
                FROM dbo.vw_backbone_edges;
            """
            )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"DB_ERROR_LOADING_GRAPH: {e}")

    pos_map = _load_positions_map()

    vis_nodes = []
    R = 500.0 if not USE_UNIFIED_VIEWS_FOR_FULL else 250.0

    if USE_UNIFIED_VIEWS_FOR_FULL:
        for n in nodes_rows:
            nid = n["id"]
            if nid in pos_map:
                x, y = pos_map[nid]
                fixed_xy = True
            else:
                a = _angle_from_id(nid)
                x, y = R * cos(a), R * sin(a)
                fixed_xy = False

            vis_nodes.append(
                {
                    "id": nid,
                    "label": n.get("label") or nid,
                    "kind": n.get("kind"),
                    "layer": n.get("layer"),
                    "group": (n.get("kind") or "BACKBONE").lower(),
                    "x": float(x),
                    "y": float(y),
                    "fixed": {"x": fixed_xy, "y": fixed_xy},
                }
            )
    else:
        for n in nodes_rows:
            nid = n["id"]
            if nid in pos_map:
                x, y = pos_map[nid]
                fixed_xy = True
            else:
                a = _angle_from_id(nid)
                x, y = R * cos(a), R * sin(a)
                fixed_xy = False

            vis_nodes.append(
                {
                    "id": nid,
                    "label": n.get("label") or nid,
                    "group": "backbone",
                    "x": float(x),
                    "y": float(y),
                    "fixed": {"x": fixed_xy, "y": fixed_xy},
                }
            )

    vis_edges = []
    if USE_UNIFIED_VIEWS_FOR_FULL:
        for e in edges_rows:
            vis_edges.append(
                {
                    "id": e["id"],
                    "from": e["from"],
                    "to": e["to"],
                    "edge_kind": e.get("edge_kind"),
                    "length_m": e.get("length_m"),
                    "layer": e.get("layer"),
                    "title": e.get("path_text"),
                }
            )
    else:
        for e in edges_rows:
            vis_edges.append(
                {
                    "id": e["id"],
                    "from": e["from"],
                    "to": e["to"],
                    "title": e.get("path_text"),
                }
            )

    return {
        "nodes": vis_nodes,
        "edges": vis_edges,
        "meta": {
            "generated_at": datetime.utcnow().isoformat() + "Z",
            "source": "unified" if USE_UNIFIED_VIEWS_FOR_FULL else "legacy",
        },
    }


@router.get("/overview")
def get_nodes_overview():
    try:
        nodes_rows = fetch_all(
            """
            SELECT
                CAST(id AS NVARCHAR(200)) AS id,
                name AS label,
                code,
                reference,
                gps_lat,
                gps_lon
            FROM dbo.nodo;
        """
        )
        edges_rows = fetch_all(
            """
            SELECT
                route_id AS id,
                CAST (from_nodo_id AS NVARCHAR(200)) AS [from],
                CAST (to_nodo_id   AS NVARCHAR(200)) AS [to],
                path_text
            FROM dbo.vw_backbone_edges;
        """
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"BD_ERROR_OVERVIEW: {e}")

    pos_map = _load_positions_map()

    vis_nodes = []
    R = 350.0
    for n in nodes_rows:
        nid = n["id"]
        if nid in pos_map:
            x, y = pos_map[nid]
            fixed_xy = True
        else:
            a = _angle_from_id(nid)
            x, y = R * cos(a), R * sin(a)
            fixed_xy = True

        ref = n.get("reference") or n.get("nodo_reference")
        gps_lat = n.get("gps_lat")
        gps_lon = n.get("gps_lon")

        vis_nodes.append(
            {
                "id": nid,
                "label": n.get("label") or nid,
                "group": "nodo",
                "kind": "NODO",
                "reference": ref,
                "gps_lat": gps_lat,
                "gps_lon": gps_lon,
                "meta": {
                    "reference": ref,
                    "gps_lat": gps_lat,
                    "gps_lon": gps_lon,
                    "nodo_code": n.get("code"),
                },
                "x": float(x),
                "y": float(y),
                "fixed": {"x": fixed_xy, "y": fixed_xy},
            }
        )

    vis_edges = []
    for e in edges_rows:
        vis_edges.append(
            {
                "id": e["id"],
                "from": e["from"],
                "to": e["to"],
                "title": e.get("path_text"),
                "edge_kind": "NODO_LINK",
            }
        )

    return {
        "nodes": vis_nodes,
        "edges": vis_edges,
        "meta": {
            "generated_at": datetime.utcnow().isoformat() + "Z",
            "source": "overview:nodos+backbone",
        },
    }
