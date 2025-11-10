import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./styles/app.css";
import App from "./App.jsx";
import { BrowserRouter } from "react-router-dom";

function ensureRootElement(id = "root") {
  let el = document.getElementById(id);
  if (!el) {
    console.warn(`[main] No existe #${id}. Creando uno dinámicamente.`);
    el = document.createElement("div");
    el.id = id;
    document.body.appendChild(el);
  }
  return el;
}

const rootEl = ensureRootElement("root");
const root = createRoot(rootEl);

root.render(
  <StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </StrictMode>
);
