export default function Toolbar({
  view = "overview",
  onChangeView = () => {},
  onBack,
}) {
  const isOverview = view === "overview";
  const isRoute = view === "route";

  const activeStyle = {
    borderColor: "#22d3ee",
    boxShadow: "0 0 0 2px rgba(34,211,238,0.25)",
  };

  return (
    <div
      className="toolbar"
      style={{ display: "flex", alignItems: "center", gap: 8 }}
    >
      <strong style={{ letterSpacing: 0.5 }}>AUWIN</strong>

      <div style={{ flex: 1 }} />

      {isRoute && typeof onBack === "function" && (
        <button className="btn" onClick={onBack} title="Volver">
          Volver
        </button>
      )}

      <button
        className="btn"
        onClick={() => onChangeView("overview")}
        style={isOverview ? activeStyle : undefined}
        aria-pressed={isOverview}
        disabled={isOverview}
        title="Overview"
      >
        Overview
      </button>

      <button
        className="btn"
        onClick={() => onChangeView("route")}
        style={isRoute ? activeStyle : undefined}
        aria-pressed={isRoute}
        disabled={isRoute}
        title="Ruta"
      >
        Ruta
      </button>
    </div>
  );
}
