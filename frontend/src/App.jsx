import {
  Routes,
  Route,
  Navigate,
  useNavigate,
  useLocation,
} from "react-router-dom";
import { Suspense, lazy, useEffect, useState } from "react";

import Toolbar from "./components/Toolbar.jsx";
import RouteList from "./components/RouteList.jsx";
import DetailsPanel from "./components/DetailsPanel.jsx";
import api from "./api/client.js";

const GraphOverview = lazy(() => import("./components/GraphOverview.jsx"));
const RouteDetailGraph = lazy(() =>
  import("./components/RouteDetailGraph.jsx")
);

const LAST_ROUTE_KEY = "auwin:lastRouteId";

function useViewFromLocation() {
  const { pathname } = useLocation();
  return pathname.startsWith("/routes") ? "route" : "overview";
}

export default function App() {
  const navigate = useNavigate();
  const view = useViewFromLocation();

  const [routes, setRoutes] = useState([]);
  const [loadingRoutes, setLoadingRoutes] = useState(false);

  const [selected, setSelected] = useState(null);

  useEffect(() => {
    let alive = true;
    (async () => {
      setLoadingRoutes(true);
      try {
        const r = await api.get("/topology/routes");
        if (!alive) return;
        setRoutes(Array.isArray(r.data) ? r.data : []);
      } catch (e) {
        console.error("GET /topology/routes error:", e);
        if (!alive) return;
        setRoutes([]);
      } finally {
        if (alive) setLoadingRoutes(false);
      }
    })();
    return () => {
      alive = false;
    };
  }, []);

  const onChangeView = (v) => {
    if (v === "overview") {
      navigate("/overview");
      return;
    }
    if (v === "route") {
      const last = sessionStorage.getItem(LAST_ROUTE_KEY);
      if (last) navigate(`/routes/${encodeURIComponent(last)}`);
    }
  };
  const onBack = () => navigate("/overview");

  const openRoute = (r) => {
    if (!r?.id) return;
    sessionStorage.setItem(LAST_ROUTE_KEY, r.id);
    navigate(`/routes/${encodeURIComponent(r.id)}`);
  };

  const SidebarBlock = ({ showHeader = true }) => (
    <>
      {showHeader && (
        <div className="card">
          <h3 style={{ marginTop: 0 }}>Rutas Lógicas</h3>
          <p style={{ opacity: 0.7, marginTop: 4 }}>
            Selecciona una para ver su planta externa.
          </p>
          <div style={{ fontSize: 12, opacity: 0.7, marginTop: 6 }}>
            {loadingRoutes ? "Cargando…" : `Total: ${routes.length}`}
          </div>
        </div>
      )}

      <DetailsPanel selected={selected} />

      <RouteList routes={routes} onOpenRoute={openRoute} />
    </>
  );

  return (
    <div
      className="app"
      style={{ minHeight: "100vh", display: "flex", flexDirection: "column" }}
    >
      <Toolbar view={view} onChangeView={onChangeView} onBack={onBack} />

      <div style={{ flex: 1, minHeight: 0 }}>
        <Suspense fallback={<div className="card">Cargando…</div>}>
          <Routes>
            <Route path="/" element={<Navigate to="/overview" replace />} />

            {/* OVERVIEW */}
            <Route
              path="/overview"
              element={
                <div
                  style={{
                    display: "grid",
                    gridTemplateColumns: "340px 1fr",
                    gap: 12,
                    padding: 12,
                    height: "100%",
                    minHeight: 0,
                  }}
                >
                  <div className="sidebar" style={{ overflowY: "auto" }}>
                    <SidebarBlock showHeader />
                  </div>

                  <div
                    className="main"
                    style={{
                      position: "relative",
                      minHeight: 0,
                      height: "100%",
                    }}
                  >
                    <GraphOverview
                      onSelect={(s) => setSelected(s)}
                      onOpenRoute={(routeId) => {
                        if (!routeId) return;
                        sessionStorage.setItem(LAST_ROUTE_KEY, routeId);
                        navigate(`/routes/${encodeURIComponent(routeId)}`);
                      }}
                    />
                  </div>
                </div>
              }
            />

            {/* ROUTE DETAIL */}
            <Route
              path="/routes/:routeId"
              element={
                <div
                  style={{
                    display: "grid",
                    gridTemplateColumns: "340px 1fr",
                    gap: 12,
                    padding: 12,
                    height: "100%",
                    minHeight: 0,
                  }}
                >
                  <div className="sidebar" style={{ overflowY: "auto" }}>
                    <SidebarBlock showHeader={false} />
                  </div>

                  <div
                    className="main"
                    style={{
                      position: "relative",
                      minHeight: 0,
                      height: "100%",
                    }}
                  >
                    <RouteDetailGraph
                      route={{ id: window.location.pathname.split("/").pop() }}
                      onSelect={(s) => setSelected(s)}
                    />
                  </div>
                </div>
              }
            />

            <Route path="*" element={<Navigate to="/overview" replace />} />
          </Routes>
        </Suspense>
      </div>
    </div>
  );
}
