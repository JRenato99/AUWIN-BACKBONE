import React, { useEffect, useRef, useState, useMemo } from "react";
import { Network } from "vis-network";
import "vis-network/styles/vis-network.css";
import api from "../api/client.js";

const nf = new Intl.NumberFormat();

export default function RouteDetailGraph({ route, onSelect }) {
  const containerRef = useRef(null);
  const networkRef = useRef(null);

  const [graph, setGraph] = useState({ nodes: [], edges: [] });
  const [inventory, setInventory] = useState(null);
  const [loading, setLoading] = useState(false);
  const [errMsg, setErrMsg] = useState("");
  const [locked, setLocked] = useState(false);

  const [selectedNodeId, setSelectedNodeId] = useState(null);
  const [selectedEdgeId, setSelectedEdgeId] = useState(null);

  useEffect(() => {
    if (!route?.id) return;
    setLoading(true);
    setErrMsg("");
    setSelectedEdgeId(null);
    setSelectedNodeId(null);
    Promise.all([
      api.get(`/topology/routes/${route.id}/graph-with-access`),
      api.get(`/topology/routes/${route.id}/inventory`),
    ])
      .then(([g, inv]) => {
        setGraph(g.data || { nodes: [], edges: [] });
        setInventory(inv.data || null);
      })
      .catch((e) => {
        console.error("RouteDetailGraph load error:", e);
        setErrMsg(
          e?.response?.data?.detail ||
            e?.message ||
            "No se pudo cargar la ruta."
        );
      })
      .finally(() => setLoading(false));
  }, [route]);

  const options = useMemo(
    () => ({
      physics: { enabled: false },
      nodes: { font: { color: "#e5e7eb" } },
      edges: { smooth: { type: "continuous" }, color: "#94a3b8", width: 2 },
      groups: {
        odf: { shape: "box", color: "#22d3ee" },
        pole: { shape: "dot", color: "#a5b4fc" },
        mufa: { shape: "diamond", color: "#f472b6" },
        router: { shape: "box", color: "#111111" },
        span: { color: "#94a3b8" },
        odf_link: { dashes: true, color: "#22d3ee" },
        pole_mufa: { dashes: true, color: "#f472b6" },
        patch: { color: "#111111" },
      },
      interaction: {
        hover: true,
        dragNodes: true,
        dragView: true,
        zoomView: true,
      },
    }),
    []
  );

  const colorForEdgeGroup = (g) =>
    g === "odf_link"
      ? "#22d3ee"
      : g === "pole_mufa"
      ? "#f472b6"
      : g === "patch"
      ? "#111111"
      : "#94a3b8";
  const dashesForEdgeGroup = (g) => g === "odf_link" || g === "pole_mufa";

  const styledData = useMemo(() => {
    const SEL_RED = "#ff3b30";
    const SEL_BORDER = "#b91c1c";

    const nodes = (graph.nodes || []).map((n) => {
      const base = {
        id: n.id,
        label: n.label ?? n.id,
        x: n.x,
        y: n.y,
        fixed: n.fixed ?? { x: true, y: true },
        group: n.group,
        meta: n.meta || null,
      };
      if (n.id === selectedNodeId) {
        return {
          ...base,
          color: { background: SEL_RED, border: SEL_BORDER },
        };
      }
      return base;
    });

    const edges = (graph.edges || []).map((e) => {
      const isSel = e.id === selectedEdgeId;

      return {
        id: e.id,
        from: e.from,
        to: e.to,
        title: e.title ?? "",
        color: isSel ? SEL_RED : colorForEdgeGroup(e.group),
        dashes: isSel ? false : dashesForEdgeGroup(e.group),
        width: isSel ? 3 : 2,
        group: e.group || "edge",
        meta: e.meta || null,
      };
    });
    return { nodes, edges };
  }, [graph, selectedEdgeId, selectedNodeId]);

  useEffect(() => {
    if (!containerRef.current) return;

    if (!networkRef.current) {
      networkRef.current = new Network(
        containerRef.current,
        styledData,
        options
      );
      networkRef.current.once("afterDrawing", () => {
        try {
          networkRef.current.fit({ animation: { duration: 400 } });
        } catch {
          //noop
        }
      });

      // CLICK -> manda info a DetailsPanel
      networkRef.current.on("doubleClick", (params) => {
        const n = params?.nodes?.[0];
        const e = params?.edges?.[0];

        if (n) {
          setSelectedNodeId(n);
          setSelectedEdgeId(null);
          if (typeof onSelect === "function") {
            const nodeData = graph.nodes?.find((x) => x.id === n) || null;
            onSelect({ node: nodeData, edge: null });
          }
          return;
        }
        if (e) {
          setSelectedEdgeId(e);
          setSelectedNodeId(null);
          if (typeof onSelect === "function") {
            const edgeData = graph.edges?.find((x) => x.id === e) || null;
            onSelect({ node: null, edge: edgeData });
          }
          return;
        }
      });

      networkRef.current.on("click", (params) => {
        const dsNodes = networkRef.current.body.data.nodes;
        const dsEdges = networkRef.current.body.data.edges;

        if (params?.nodes?.length) {
          const n = dsNodes.get(params.nodes[0]);
          onSelect?.({
            node: {
              id: n.id,
              kind: n.group?.toUpperCase() || "NODE",
              label: n.label,
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
              edge_kind: e.group || "EDGE",
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
    } else {
      networkRef.current.setData(styledData);
      try {
        networkRef.current.redraw();
      } catch {
        // noop
      }
    }
  }, [styledData, options, onSelect, graph.nodes, graph.edges]);

  // Drag temporal: desbloquear y re-fijar + guardar
  useEffect(() => {
    const net = networkRef.current;
    if (!net) return;

    const onDragStart = (params) => {
      if (locked) return;
      const ids = params?.nodes ?? [];
      if (!ids.length) return;
      try {
        net.body.data.nodes.update(
          ids.map((id) => ({ id, fixed: { x: false, y: false } }))
        );
      } catch (e) {
        console.error("onDragStart update error:", e);
      }
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
        console.error("onDragEnd persist/fix error:", e);
      }
    };

    net.on("dragStart", onDragStart);
    net.on("dragEnd", onDragEnd);
    return () => {
      net.off("dragStart", onDragStart);
      net.off("dragEnd", onDragEnd);
    };
  }, [locked]);

  const saveAllPositions = async () => {
    const net = networkRef.current;
    if (!net) return;
    try {
      const pos = net.getPositions();
      const items = Object.entries(pos).map(([node_id, p]) => ({
        node_id,
        x: p.x,
        y: p.y,
      }));
      await api.post("/graph/positions", items);
      alert("Posiciones de la ruta guardadas.");
    } catch (e) {
      console.error("Guardar posiciones error:", e);
      alert("No se pudo guardar posiciones.");
    }
  };

  const clearSelection = () => {
    selectedEdgeId(null);
    selectedNodeId(null);
    if (typeof onSelect === "function") onSelect(null);
  };

  return (
    <>
      <div
        className="graph-container"
        ref={containerRef}
        style={{
          width: "100%",
          height: "70vh",
          borderRadius: 8,
          border: "1px solid #1f2937",
        }}
      />

      {!!errMsg && (
        <div
          style={{
            position: "absolute",
            left: 16,
            top: 16,
            padding: 8,
            borderRadius: 8,
            background: "#2a0f10",
            color: "#ffb4b4",
            border: "1px solid #5f1e21",
            whiteSpace: "pre-wrap",
            maxWidth: 480,
          }}
        >
          {String(errMsg)}
        </div>
      )}

      <div style={{ position: "absolute", left: 16, bottom: 16 }}>
        <div className="card" style={{ minWidth: 320 }}>
          <b>Ruta:</b> {route?.id ?? "-"}
          <br />
          <small>
            {route?.from_odf_id ?? "?"} → {route?.to_odf_id ?? "?"}
          </small>
          {inventory && (
            <>
              <hr style={{ borderColor: "#374151", margin: "10px 0" }} />
              <div
                style={{
                  display: "grid",
                  gridTemplateColumns: "1fr 1fr",
                  gap: 8,
                }}
              >
                <div>
                  <b>Spans</b>
                  <div>{inventory.span_count}</div>
                </div>
                <div>
                  <b>Longitud</b>
                  <div>
                    {nf.format(Math.round(inventory.total_length_m || 0))} m
                  </div>
                </div>
                <div>
                  <b>Postes</b>
                  <div>{inventory.pole_count}</div>
                </div>
                <div>
                  <b>Mufas</b>
                  <div>{inventory.mufa_count}</div>
                </div>
              </div>

              {inventory.cables?.length ? (
                <div style={{ marginTop: 8 }}>
                  <b>Cables:</b> {inventory.cables.join(", ")}
                </div>
              ) : null}
            </>
          )}
          {loading && (
            <div style={{ marginTop: 8, opacity: 0.75, fontSize: 12 }}>
              Cargando…
            </div>
          )}
        </div>
      </div>

      <div
        style={{
          position: "absolute",
          right: 16,
          bottom: 16,
          display: "flex",
          gap: 8,
          flexWrap: "wrap",
        }}
      >
        <button
          className={`btn ${locked ? "accent" : ""}`}
          onClick={() => setLocked((v) => !v)}
          title={
            locked
              ? "Desbloquear para permitir arrastre"
              : "Bloquear para impedir arrastre"
          }
        >
          {locked ? "🔒 Bloqueado" : "🔓 Desbloqueado"}
        </button>

        <button className="btn" onClick={() => networkRef.current?.fit()}>
          Centrar
        </button>
        <button className="btn" onClick={saveAllPositions} disabled={loading}>
          Guardar posiciones (todo)
        </button>

        {/* Quitar seleccion */}
        <button className="btn" onClick={clearSelection}>
          Limpiar Selección
        </button>
      </div>
    </>
  );
}
