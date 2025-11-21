import React, { useMemo } from "react";

function EmptyState() {
  return <div className="card">No hay rutas disponibles</div>;
}

function Row({ label, value }) {
  if (!value) return null;
  return (
    <div style={{ fontSize: 12, opacity: 0.85 }}>
      <b>{label}:</b> {value}
    </div>
  );
}

function CopyBtn({ text, title = "Copiar" }) {
  if (!text) return null;
  const copy = () =>
    navigator.clipboard?.writeText(String(text)).catch(() => {});
  return (
    <button
      className="btn"
      onClick={copy}
      title={title}
      style={{ marginLeft: 8 }}
    >
      Copiar
    </button>
  );
}

export default function RouteList({ routes = [], onOpenRoute = () => {} }) {
  const count = routes?.length || 0;
  const canOpen = typeof onOpenRoute === "function";

  const items = useMemo(() => (Array.isArray(routes) ? routes : []), [routes]);

  if (!count) return <EmptyState />;

  return (
    <>
      {items.map((r) => {
        const id = r?.id ?? "(sin id)";
        const from = r?.from_odf_id ?? "-";
        const to = r?.to_odf_id ?? "-";
        const subtitle = `${from} → ${to}`;

        const summaryText = r?.path_text || r?.span_list || "";

        return (
          <div key={id} className="card">
            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                gap: 12,
              }}
            >
              <div style={{ minWidth: 0 }}>
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    flexWrap: "wrap",
                  }}
                >
                  <b
                    style={{
                      overflow: "hidden",
                      textOverflow: "ellipsis",
                      whiteSpace: "nowrap",
                    }}
                  >
                    {id}
                  </b>
                  {/*<CopyBtn text={id} title="Copiar Route ID" />*/}
                </div>
                <div
                  style={{
                    opacity: 0.85,
                    fontSize: 12,
                    marginTop: 2,
                    overflow: "hidden",
                    textOverflow: "ellipsis",
                    whiteSpace: "nowrap",
                  }}
                  title={subtitle}
                >
                  {from} → {to}
                </div>
              </div>
              <button
                className="btn"
                onClick={() => canOpen && onOpenRoute(r)}
                disabled={!canOpen}
                title="Abrir detalle de ruta"
              >
                Abrir
              </button>
            </div>

            {!!summaryText && (
              <div
                style={{
                  marginTop: 6,
                  fontSize: 12,
                  opacity: 0.85,
                  whiteSpace: "pre-wrap",
                  wordBreak: "break-word",
                }}
              ></div>
            )}
          </div>
        );
      })}
    </>
  );
}
