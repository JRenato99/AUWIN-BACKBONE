from fastapi import APIRouter
from pydantic import BaseModel
from core.db import execute, fetch_all
import hashlib
from math import cos, sin, tau
from core.util import _angle_from_id

router = APIRouter(prefix="/graph/positions", tags=["positions"])


class NodePos(BaseModel):
    node_id: str
    x: float
    y: float


# ENDPOINTS
@router.post("/")
def upsert_positions(items: list[NodePos]):  # Guarda posiciones manuales
    sql = """
      MERGE dbo.graph_node_position AS tgt
      USING (SELECT :node_id AS node_id, :x AS x, :y AS y) AS src
      ON (tgt.node_id = src.node_id)
      WHEN MATCHED THEN UPDATE SET x=src.x, y=src.y, updated_at=SYSUTCDATETIME()
      WHEN NOT MATCHED THEN INSERT (node_id, x, y) VALUES (src.node_id, src.x, src.y);
    """
    for it in items:
        execute(sql, node_id=it.node_id, x=it.x, y=it.y)
    return {"ok": True, "count": len(items)}


@router.delete("/")
def clear_positions():
    execute("DELETE FROM dbo.graph_node_position;")
    return {"ok": True}


@router.post("/seed-defaults")
def seed_defaults(radius: float = 250.0):
    nodes = fetch_all("SELECT id FROM dbo.nodo")
    existing = fetch_all("SELECT node_id FROM dbo.graph_node_position")
    have = {r["node_id"] for r in existing}
    sql_merge = """
      MERGE dbo.graph_node_position AS tgt
      USING (SELECT :node_id AS node_id, :x AS x, :y AS y) AS src
      ON (tgt.node_id = src.node_id)
      WHEN NOT MATCHED THEN INSERT (node_id, x, y) VALUES (src.node_id, src.x, src.y);
    """
    inserted = 0
    for n in nodes:
        if n["id"] in have:
            continue
        a = _angle_from_id(n["id"])
        x, y = radius * cos(a), radius * sin(a)
        execute(sql_merge, node_id=n["id"], x=x, y=y)
        inserted += 1
    return {"ok": True, "inserted": inserted}
