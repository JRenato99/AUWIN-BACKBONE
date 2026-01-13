import {
  Routes,
  Route,
  Navigate,
  useNavigate,
  useLocation,
  useParams,
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

const SidebarBlock = ({
  showHeader = true,
  loadingRoutes,
  routes,
  selected,
  onOpenRoute,
}) => (
  <>
    {showHeader && (
      <div className="card">
        <div className="card-header">
          <h3 className="card-title">Rutas Lógicas</h3>
          <span className="badge">{loadingRoutes ? "Cargando..." : "Activas"}</span>
        </div>
        <p className="card-subtitle">
          Selecciona una para ver su planta externa.
        </p>
        <div className="muted" style={{ fontSize: 12, marginTop: 6}}>
          {loadingRoutes ? "Actualizando rutas..." : `Total: ${routes.length}`}
        </div>        
      </div>
    )}

    <DetailsPanel selected={selected} />

    <RouteList routes={routes} onOpenRoute={onOpenRoute} />
  </>
);

const RouteDetailWrapper = ({ onSelect }) => {
  const { routeId } = useParams();
  return <RouteDetailGraph route={{ id: routeId }} onSelect={onSelect} />;
};

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

  return (
    //<div
    //  className="app"
    //  style={{ minHeight: "100vh", display: "flex", flexDirection: "column" }}
    //>
    <div className="app app-shell">
      <Toolbar view={view} onChangeView={onChangeView} onBack={onBack} />

      <div className="app-content">
        <Suspense fallback={<div className="card">Cargando…</div>}>
          <Routes>
            <Route path="/" element={<Navigate to="/overview" replace />} />

            {/* OVERVIEW */}
            <Route
              path="/overview"
              element={
                <div className="app-grid">
                  <div className="app-sidebar">
                    <SidebarBlock
                      showHeader={true}
                      loadingRoutes={loadingRoutes}
                      routes={routes}
                      selected={selected}
                      onOpenRoute={openRoute}
                    />
                  </div>

                  <div
                    className="app-main">
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
                <div className="app-grid">
                  <div className="app-sidebar">
                    <SidebarBlock
                      showHeader={false}
                      loadingRoutes={loadingRoutes}
                      routes={routes}
                      selected={selected}
                      onOpenRoute={openRoute}
                    />
                  </div>

                  <div className="app-main">
                    <RouteDetailWrapper onSelect={(s) => setSelected(s)} />
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
