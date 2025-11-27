import React, { useEffect, useState, useRef, useMemo } from "react";
import { Network } from "vis-network";
import "vis-network/styles/vis-network.css";
import api from "../api/client.js";

function buildOptions() {
  return {
    physics: { enabled: false },
    interaction: {
      hover: true,
      tooltipDelay: 120,
      multiselect: true,
      navigationButtons: true,
      keyboard: true,
      zoomView: true,
      dragView: true,
      dragNodes: true,
    },
    nodes: { shape: "box", size: 16, font: { size: 12 } },
    edges: { smooth: false, arrows: { to: false }, width: 2 },
  };
}

export default function GraphOverview({ onSelect, onOpenRoute }) {
  const containerRef = useRef(null);
  const networkRef = useRef(null);
  const [loading, setLoading] = useState(false);
  const [graph, setGraph] = useState({ nodes: [], edges: [], meta: {} });
  const [locked, setLocked] = useState(false);

  // Cargar grafo: SOLO nodos físicos + enlaces (route_id como id de arista)
  useEffect(() => {
    setLoading(true);
    api
      .get("/graph/overview")
      .then((r) => setGraph(r.data))
      .catch((e) => console.error("GET /graph/overview error:", e))
      .finally(() => setLoading(false));
  }, []);

  const data = useMemo(() => {
    const nodes = (graph.nodes || []).map((n) => {
      const kind = n.kind || "NODO";
      const group = n.group || "nodo";

      if (kind === "MUFA_SPLIT" || group === "mufa_split") {
        return {
          id: n.id,
          label: n.label ?? "",
          x: n.x,
          y: n.y,
          fixed: n.fixed ?? { x: true, y: true },
          group: "mufa_split",
          kind,
          color: { background: "#68e0f5", border: "#111" },
          font: { color: "#111", size: 8 },
          shape: "triangle",
          size: 5,
          meta: n.meta || null,
          layer: n.layer ?? null,
          status: n.status ?? null,
        };
      }
      // Nodo Físico
      return {
        id: n.id,
        label: n.label ?? n.id,
        x: n.x,
        y: n.y,
        fixed: n.fixed ?? { x: true, y: true },
        group: "nodo",
        kind: "NODO",
        color: { background: "#FFEDD5", border: "#FF6A00" },
        font: { color: "#111" },
        shape: "box",
        margin: 10,
        meta: n.meta || null,
        layer: n.layer ?? null,
        status: n.status ?? null,
      };
    });

    const edges = (graph.edges || []).map((e) => ({
      id: e.id, // route_id
      from: e.from,
      to: e.to,
      title: e.title ?? "",
      color: "#94a3b8",
      dashes: true,
      width: 2,
      group: "NODO_LINK",
      meta: e.meta || null,
    }));
    return { nodes, edges };
  }, [graph]);

  useEffect(() => {
    if (!containerRef.current) return;
    const options = buildOptions();

    if (!networkRef.current) {
      networkRef.current = new Network(containerRef.current, data, options);

      networkRef.current.once("afterDrawing", () => {
        try {
          networkRef.current.fit({ animation: { duration: 400 } });
        } catch (e) {
          console.error(e);
        }
      });

      // CLICK -> manda info a DetailsPanel
      networkRef.current.on("click", (params) => {
        const dsNodes = networkRef.current.body.data.nodes;
        const dsEdges = networkRef.current.body.data.edges;

        if (params?.nodes?.length) {
          const n = dsNodes.get(params.nodes[0]);
          onSelect?.({
            node: {
              id: n.id,
              kind: n.kind || "NODO",
              label: n.label,
              layer: n.layer ?? null,
              status: n.status ?? null,
              group: n.group,
              meta: n.meta || null,
            },
          });
          return;
        }

        if (params?.edges?.length) {
          const e = dsEdges.get(params.edges[0]);
          onSelect?.({
            edge: {
              id: e.id,
              edge_kind: e.group || "NODO_LINK",
              from: e.from,
              to: e.to,
              title: e.title ?? "",
              meta: e.meta || null,
            },
          });
          return;
        }

        onSelect?.(null);
      });

      // DOBLE CLICK EN ENLACE -> abrir detalle de ruta
      networkRef.current.on("doubleClick", (params) => {
        const edgeId = params?.edges?.[0];
        if (!edgeId || typeof onOpenRoute !== "function") return;

        const dsEdges = networkRef.current.body.data.edges;
        const e = dsEdges.get(edgeId);

        // Si la arista tiene meta.route_id, usarlo (MUFA_TO_NODO),
        // si no, usar el id de la arista (para enlaces directos NODO_LINK)
        const routeId =
          e?.meta?.route_id && typeof e.meta.route_id === "string"
            ? e.meta.route_id
            : e.id;

        if (routeId) {
          onOpenRoute(routeId);
        }
      });
    } else {
      networkRef.current.setData(data);
    }
  }, [data, onSelect, onOpenRoute]);

  // Drag temporal: desbloquear en dragStart y re-fijar + guardar en dragEnd
  useEffect(() => {
    const net = networkRef.current;
    if (!net) return;

    const onDragStart = (params) => {
      if (locked) return;
      const ids = params?.nodes ?? [];
      if (!ids.length) return;
      net.body.data.nodes.update(
        ids.map((id) => ({ id, fixed: { x: false, y: false } }))
      );
    };

    const onDragEnd = async (params) => {
      const ids = params?.nodes ?? [];
      if (!ids.length) return;
      try {
        const posMap = net.getPositions(ids);
        const items = Object.entries(posMap).map(([node_id, p]) => ({
          node_id,
          x: p.x,
          y: p.y,
        }));
        await api.post("/graph/positions", items);
        net.body.data.nodes.update(
          ids.map((id) => ({ id, fixed: { x: true, y: true } }))
        );
      } catch (e) {
        console.error("persist positions error:", e);
      }
    };

    net.on("dragStart", onDragStart);
    net.on("dragEnd", onDragEnd);
    return () => {
      net.off("dragStart", onDragStart);
      net.off("dragEnd", onDragEnd);
    };
  }, [locked]);

  return (
    <div
      style={{
        display: "grid",
        gridTemplateRows: "44px 1fr",
        gap: 8,
        height: "100%",
      }}
    >
      <div
        className="card"
        style={{ display: "flex", alignItems: "center", gap: 8 }}
      >
        <button
          className={`btn ${locked ? "accent" : ""}`}
          onClick={() => setLocked((v) => !v)}
          title={locked ? "Desbloquear arrastre" : "Bloquear arrastre"}
        >
          {locked ? "🔒 Bloqueado" : "🔓 Desbloqueado"}
        </button>
        <div style={{ fontSize: 12, opacity: 0.7, marginLeft: 8 }}>
          {loading
            ? "Cargando…"
            : `Nodos: ${data.nodes.length} | Enlaces: ${data.edges.length}`}
        </div>
      </div>

      <section style={{ border: "1px solid #ddd", borderRadius: 8 }}>
        <div ref={containerRef} style={{ width: "100%", height: "80vh" }} />
      </section>
    </div>
  );
}
