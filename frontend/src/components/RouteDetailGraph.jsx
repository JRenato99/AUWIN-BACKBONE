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

  // Selección (persistente)
  const [selectedNodeId, setSelectedNodeId] = useState(null);
  const [selectedEdgeId, setSelectedEdgeId] = useState(null);

  // Modo selección manual
  const [selectMode, setSelectMode] = useState(false);

  // Para restaurar estilos del seleccionado previo sin redibujar todo
  const prevNodeRef = useRef(null);
  const prevEdgeRef = useRef(null);

  // ===== Carga de datos =====
  useEffect(() => {
    if (!route?.id) return;
    setLoading(true);
    setErrMsg("");
    setSelectedEdgeId(null);
    setSelectedNodeId(null);
    prevNodeRef.current = null;
    prevEdgeRef.current = null;

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

  // ===== Opciones de vis-network (sin color global para no pisar updates) =====
  const options = useMemo(
    () => ({
      physics: { enabled: false },
      nodes: { font: { color: "#e5e7eb" } },
      edges: { smooth: { type: "continuous" }, width: 2 },
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
        multiselect: false,
      },
    }),
    []
  );

  // ===== Estilo base para aristas según grupo =====
  const baseEdgeColor = (g) =>
    g === "odf_link"
      ? "#22d3ee"
      : g === "pole_mufa"
      ? "#f472b6"
      : g === "patch"
      ? "#111111"
      : "#94a3b8";
  const baseEdgeDashes = (g) => g === "odf_link" || g === "pole_mufa";

  // ===== Data base (sin pintar selección aquí) =====
  const baseData = useMemo(() => {
    const nodes = (graph.nodes || []).map((n) => ({
      id: n.id,
      label: n.label ?? n.id,
      x: n.x,
      y: n.y,
      fixed: n.fixed ?? { x: true, y: true },
      group: n.group, // color/forma base por grupo
      meta: n.meta || null,
    }));

    const edges = (graph.edges || []).map((e) => ({
      id: e.id,
      from: e.from,
      to: e.to,
      title: e.title ?? "",
      group: e.group || "edge",
      color: { color: baseEdgeColor(e.group) },
      dashes: baseEdgeDashes(e.group),
      width: 2,
      meta: e.meta || null,
    }));

    return { nodes, edges };
  }, [graph]);

  // ===== Crear/actualizar network SOLO cuando cambia la data base =====
  useEffect(() => {
    if (!containerRef.current) return;

    if (!networkRef.current) {
      networkRef.current = new Network(containerRef.current, baseData, options);
      networkRef.current.once("afterDrawing", () => {
        try {
          networkRef.current.fit({ animation: { duration: 400 } });
        } catch {
          /* noop */
        }
      });
    } else {
      networkRef.current.setData(baseData);
      try {
        networkRef.current.redraw();
      } catch {
        /* noop */
      }
    }
  }, [baseData, options]);

  // ===== Click: notificar DetailsPanel y, si selectMode, fijar selección =====
  useEffect(() => {
    const net = networkRef.current;
    if (!net) return;

    const handlerClick = (params) => {
      const dsNodes = net.body.data.nodes;
      const dsEdges = net.body.data.edges;

      const nodeId = params?.nodes?.[0] || null;
      const edgeId = params?.edges?.[0] || null;

      // Notificar
      if (nodeId) {
        const n = dsNodes.get(nodeId);
        onSelect?.({
          node: {
            id: n.id,
            kind: n.group?.toUpperCase() || "NODE",
            label: n.label,
            meta: n.meta || null,
          },
          edge: null,
        });
      } else if (edgeId) {
        const e = dsEdges.get(edgeId);
        onSelect?.({
          node: null,
          edge: {
            id: e.id,
            edge_kind: e.group || "EDGE",
            from: e.from,
            to: e.to,
            title: e.title ?? "",
            meta: e.meta || null,
          },
        });
      } else {
        // clic en vacío: no tocar selección para que permanezca
        return;
      }

      // Fijar selección solo en modo selección
      if (selectMode) {
        if (nodeId) {
          setSelectedNodeId(nodeId);
          setSelectedEdgeId(null);
        } else if (edgeId) {
          setSelectedEdgeId(edgeId);
          setSelectedNodeId(null);
        }
        // Si prefieres que el modo se desactive tras elegir, descomenta:
        // setSelectMode(false);
      }
    };

    net.on("click", handlerClick);
    return () => {
      net.off("click", handlerClick);
    };
  }, [selectMode, onSelect]);

  // ===== Pintar/restaurar SOLO el elemento seleccionado (sin setData) =====
  useEffect(() => {
    const net = networkRef.current;
    if (!net) return;

    const nodesDS = net.body.data.nodes;
    const edgesDS = net.body.data.edges;

    const SEL_NODE = { background: "#ff3b30", border: "#b91c1c" };
    const SEL_EDGE_COLOR = "#ff3b30";

    // Restaurar nodo previo
    if (prevNodeRef.current && prevNodeRef.current !== selectedNodeId) {
      const prevId = prevNodeRef.current;
      const n = nodesDS.get(prevId);
      if (n) {
        nodesDS.update({ id: prevId, color: undefined });
      }
      prevNodeRef.current = null;
    }

    // Restaurar arista previa
    if (prevEdgeRef.current && prevEdgeRef.current !== selectedEdgeId) {
      const prevEid = prevEdgeRef.current;
      const e = edgesDS.get(prevEid);
      if (e) {
        edgesDS.update({
          id: prevEid,
          color: { color: baseEdgeColor(e.group) },
          dashes: baseEdgeDashes(e.group),
          width: 2,
        });
      }
      prevEdgeRef.current = null;
    }

    // Pintar nuevo nodo seleccionado
    if (selectedNodeId) {
      const n = nodesDS.get(selectedNodeId);
      if (n) {
        nodesDS.update({
          id: selectedNodeId,
          color: { background: SEL_NODE.background, border: SEL_NODE.border },
        });
        prevNodeRef.current = selectedNodeId;
      }
    }

    // Pintar nueva arista seleccionada
    if (selectedEdgeId) {
      const e = edgesDS.get(selectedEdgeId);
      if (e) {
        edgesDS.update({
          id: selectedEdgeId,
          color: { color: SEL_EDGE_COLOR },
          dashes: false,
          width: 3,
        });
        prevEdgeRef.current = selectedEdgeId;
      }
    }
  }, [selectedNodeId, selectedEdgeId]); // <- NO depende de baseData

  // ===== Drag temporal: desbloquear/guardar/re-fijar =====
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

  // ===== Guardar TODO =====
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

  // ===== Limpiar selección =====
  const clearSelection = () => {
    setSelectedEdgeId(null);
    setSelectedNodeId(null);
    onSelect?.(null);
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
          className={`btn ${selectMode ? "accent" : ""}`}
          onClick={() => setSelectMode((v) => !v)}
          title={
            selectMode
              ? "Modo selección ACTIVO: clic en un elemento para resaltarlo"
              : "Activar modo selección para resaltar"
          }
        >
          {selectMode ? "🎯 Selección ON" : "Seleccionar elemento"}
        </button>

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
        <button className="btn" onClick={clearSelection}>
          Limpiar selección
        </button>
      </div>
    </>
  );
}
