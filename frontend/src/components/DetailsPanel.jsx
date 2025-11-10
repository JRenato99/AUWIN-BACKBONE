import React from "react";

export default function DetailsPanel({ selected }) {
  if (!selected) return null;
  const isNode = !!selected?.node;
  const isEdge = !!selected?.edge;

  return (
    <div className="card">
      <b>Detalle</b>

      {isNode && (
        <>
          <div style={{ marginTop: 8 }}>
            <div>
              <b>ID:</b> {selected.node?.id ?? "-"}
            </div>
            <div>
              <b>Tipo:</b> {selected.node?.kind ?? "-"}
            </div>
            <div>
              <b>Layer:</b> {selected.node?.layer ?? "-"}
            </div>
            <div>
              <b>Status:</b> {selected.node?.status ?? "-"}
            </div>
            {selected.node?.label && (
              <div>
                <b>Label:</b> {selected.node.label}
              </div>
            )}
          </div>

          {selected.node?.meta?.gps_lat != null && (
            <div>
              <b>GPS:</b> {selected.node.meta.gps_lat},{" "}
              {selected.node.meta.gps_lon}
            </div>
          )}

          {selected.node?.meta?.reference && (
            <div>
              <b>Referencia:</b> {selected.node.meta.reference}
            </div>
          )}
          {!!selected.node?.meta && (
            <pre className="code-block" style={{ marginTop: 8 }}>
              {JSON.stringify(selected.node.meta, null, 2)}
            </pre>
          )}
        </>
      )}

      {isEdge && (
        <>
          <div style={{ marginTop: 8 }}>
            <div>
              <b>ID:</b> {selected.edge?.id ?? "-"}
            </div>
            <div>
              <b>Tipo de arista:</b> {selected.edge?.edge_kind ?? "-"}
            </div>
            <div>
              <b>Desde:</b> {selected.edge?.from ?? "-"}
            </div>
            <div>
              <b>Hacia:</b> {selected.edge?.to ?? "-"}
            </div>
            {selected.edge?.title && (
              <div>
                <b>Detalle:</b> {selected.edge.title}
              </div>
            )}
          </div>

          {!!selected.edge?.meta && (
            <pre className="code-block" style={{ marginTop: 8 }}>
              {JSON.stringify(selected.edge.meta, null, 2)}
            </pre>
          )}
        </>
      )}
    </div>
  );
}
