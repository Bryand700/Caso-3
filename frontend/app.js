const icon = (name, className = "") =>
  `<svg class="icon ${className}" aria-hidden="true"><use href="#i-${name}"></use></svg>`;

const API_TOKEN_KEY = "gathel-api-token";

const state = {
  authenticated: Boolean(sessionStorage.getItem(API_TOKEN_KEY)),
  route: location.hash.replace("#/", "") || "inicio",
  filter: "todas",
  modal: null,
  prediction: { answer: "yes", currency: "POINT", amount: "1" },
  propositionTarget: "other",
  mobileMenu: false,
  toast: null,
  search: "",
  error: "",
  loading: false,
};

let currentUser = {
  id: 1,
  name: "Daniela Mora",
  username: "@danimora",
  initials: "DM",
  points: 184,
  money: 72.45,
  currency: "USD",
  activePredictions: 8,
};

let propositions = [
  {
    id: 1402,
    title: "Sofía terminará la media maratón en menos de 2 horas",
    target: "Sofía Rojas",
    username: "@sofiaruns",
    initials: "SR",
    creator: "Luis Mora",
    deadline: "Hoy, 8:30 p. m.",
    relative: "Cierra en 6 h",
    status: "active",
    statusLabel: "Activa",
    stakes: ["POINT", "USD"],
    predictions: 126,
    resourceType: "Publicación",
    resourceUrl: "https://social.example/post/sofia-10k",
    colors: ["#f1c98b", "#d98d79"],
  },
  {
    id: 1437,
    title: "Andrés publicará su primera canción antes del viernes",
    target: "Andrés Solís",
    username: "@andresolis",
    initials: "AS",
    creator: "Camila Núñez",
    deadline: "Mañana, 5:00 p. m.",
    relative: "Cierra en 27 h",
    status: "active",
    statusLabel: "Activa",
    stakes: ["POINT"],
    predictions: 84,
    resourceType: "Video",
    resourceUrl: "https://social.example/video/andres-demo",
    colors: ["#a9c8dd", "#738ab9"],
  },
  {
    id: 1451,
    title: "Valeria llegará a la cima del Cerro Chirripó este fin de semana",
    target: "Valeria Castro",
    username: "@valecastro",
    initials: "VC",
    creator: "Pablo Vargas",
    deadline: "Sáb, 10:00 a. m.",
    relative: "Cierra en 3 días",
    status: "active",
    statusLabel: "Activa",
    stakes: ["POINT", "USD"],
    predictions: 211,
    resourceType: "Historia",
    resourceUrl: "https://social.example/story/vale-chirripo",
    colors: ["#b8d7b1", "#6d9d77"],
  },
  {
    id: 1460,
    title: "Mateo completará 30 días consecutivos de entrenamiento",
    target: "Mateo Herrera",
    username: "@mateoh",
    initials: "MH",
    creator: "Mateo Herrera",
    deadline: "Dom, 7:00 p. m.",
    relative: "Cierra en 4 días",
    status: "active",
    statusLabel: "Activa",
    stakes: ["POINT"],
    predictions: 59,
    resourceType: "Reel",
    resourceUrl: "https://social.example/reel/mateo-day-26",
    colors: ["#c7b5dc", "#8c72ae"],
  },
  {
    id: 1478,
    title: "Laura presentará su nuevo emprendimiento durante junio",
    target: "Laura Jiménez",
    username: "@lauraj",
    initials: "LJ",
    creator: "José Brenes",
    deadline: "25 jun, 12:00 p. m.",
    relative: "Cierra en 7 días",
    status: "active",
    statusLabel: "Activa",
    stakes: ["USD"],
    predictions: 43,
    resourceType: "Publicación",
    resourceUrl: "https://social.example/post/laura-project",
    colors: ["#efd2a7", "#d09a64"],
  },
  {
    id: 1490,
    title: "Diego cocinará una receta completa en transmisión en vivo",
    target: "Diego Chaves",
    username: "@diegococina",
    initials: "DC",
    creator: "Natalia Salas",
    deadline: "28 jun, 6:00 p. m.",
    relative: "Cierra en 10 días",
    status: "active",
    statusLabel: "Activa",
    stakes: ["POINT", "USD"],
    predictions: 95,
    resourceType: "Video",
    resourceUrl: "https://social.example/video/diego-kitchen",
    colors: ["#eda98d", "#c87168"],
  },
];

let results = [
  { id: 1321, title: "Camila completará su primera carrera de 10 km", result: true, answer: true, stake: "1 pt", gain: "+2.4 pts", date: "16 jun 2026" },
  { id: 1304, title: "Javier publicará el episodio 20 de su podcast", result: false, answer: true, stake: "$8.00", gain: "-$8.00", date: "14 jun 2026" },
  { id: 1288, title: "María alcanzará 5 000 seguidores durante mayo", result: true, answer: true, stake: "$12.00", gain: "+$21.60", date: "2 jun 2026" },
  { id: 1271, title: "Fernando viajará fuera del país antes de junio", result: false, answer: false, stake: "1 pt", gain: "+1.8 pts", date: "30 may 2026" },
  { id: 1259, title: "Lucía presentará una nueva colección el viernes", result: true, answer: false, stake: "1 pt", gain: "-1 pt", date: "24 may 2026" },
];

let activities = [
  { icon: "trophy", title: "Pronóstico acertado", detail: "Ganaste 2.4 pts en la proposición de Camila.", time: "Hace 2 horas" },
  { icon: "clock", title: "Cierre próximo", detail: "Tu pronóstico sobre Sofía cierra hoy.", time: "Hace 4 horas" },
  { icon: "spark", title: "Proposición activa", detail: "La proposición #1391 ya acepta pronósticos.", time: "Ayer" },
  { icon: "wallet", title: "Saldo actualizado", detail: "Se acreditaron $18.50 a tu balance.", time: "Ayer" },
];

const routeMeta = {
  inicio: "Inicio",
  proposiciones: "Proposiciones activas",
  crear: "Crear proposición",
  resultados: "Resultados",
};

let availablePlayers = [];

async function apiRequest(path, options = {}) {
  const token = sessionStorage.getItem(API_TOKEN_KEY);
  const response = await fetch(path, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(options.headers || {}),
    },
  });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok) {
    const error = new Error(payload.error || "No fue posible completar la solicitud.");
    error.status = response.status;
    throw error;
  }
  return payload;
}

function formatDeadline(value) {
  const date = new Date(value);
  return new Intl.DateTimeFormat("es-CR", {
    day: "numeric",
    month: "short",
    hour: "numeric",
    minute: "2-digit",
  }).format(date);
}

function relativeDeadline(value) {
  const hours = Math.max(0, Math.round((new Date(value).getTime() - Date.now()) / 3600000));
  if (hours < 24) return `Cierra en ${hours} h`;
  return `Cierra en ${Math.round(hours / 24)} días`;
}

function colorsFor(id) {
  const palettes = [
    ["#f1c98b", "#d98d79"],
    ["#a9c8dd", "#738ab9"],
    ["#b8d7b1", "#6d9d77"],
    ["#c7b5dc", "#8c72ae"],
    ["#efd2a7", "#d09a64"],
    ["#eda98d", "#c87168"],
  ];
  return palettes[Number(id) % palettes.length];
}

function mapProposition(item) {
  return {
    id: item.id,
    title: item.title,
    target: item.target.name,
    username: item.target.username,
    initials: item.target.initials,
    creator: item.creator.name,
    deadline: formatDeadline(item.deadline),
    relative: relativeDeadline(item.deadline),
    status: "active",
    statusLabel: "Activa",
    stakes: item.currencies,
    predictions: item.predictionCount,
    resourceType: item.resource.type,
    resourceUrl: item.resource.url,
    colors: colorsFor(item.id),
  };
}

function mapResult(item) {
  const won = Boolean(item.didWin);
  const stake = Number(item.stake);
  const symbol = item.currency === "POINT" ? "" : "$";
  const unit = item.currency === "POINT" ? " pt" : "";
  return {
    id: item.id,
    title: item.title,
    result: Boolean(item.fulfilled),
    answer: item.prediction === "si",
    stake: `${symbol}${stake.toFixed(item.currency === "POINT" ? 0 : 2)}${unit}`,
    gain: won
      ? `+${symbol}${(stake * 1.8).toFixed(item.currency === "POINT" ? 1 : 2)}${item.currency === "POINT" ? " pts" : ""}`
      : `-${symbol}${stake.toFixed(item.currency === "POINT" ? 0 : 2)}${unit}`,
    date: new Intl.DateTimeFormat("es-CR", {
      day: "numeric",
      month: "short",
      year: "numeric",
    }).format(new Date(item.determinedAt)),
  };
}

async function loadApplicationData() {
  const [dashboard, propositionData, resultData, players] = await Promise.all([
    apiRequest("/api/me/dashboard"),
    apiRequest("/api/propositions"),
    apiRequest("/api/propositions/results"),
    apiRequest("/api/players"),
  ]);
  currentUser = {
    ...dashboard.player,
    points: dashboard.balances.points,
    money: dashboard.balances.money,
    currency: dashboard.balances.moneyCurrency,
    activePredictions: dashboard.activePredictions,
  };
  propositions = propositionData.map(mapProposition);
  results = resultData.map(mapResult);
  availablePlayers = players.filter(player => player.id !== currentUser.id);
  activities = dashboard.activity.length
    ? dashboard.activity.map((item, index) => ({
        icon: index === 0 ? "trophy" : "wallet",
        title: item.title,
        detail: item.detail,
        time: new Intl.DateTimeFormat("es-CR", {
          day: "numeric",
          month: "short",
          hour: "numeric",
          minute: "2-digit",
        }).format(new Date(item.occurredAt)),
      }))
    : [{
        icon: "spark",
        title: "Cuenta preparada",
        detail: "Todavía no hay movimientos recientes.",
        time: "Ahora",
      }];
}

function appLayout(content) {
  return `
    <div class="app-shell">
      <aside class="sidebar ${state.mobileMenu ? "open" : ""}">
        <div class="brand"><span class="brand-mark">G</span> Gathel</div>
        <nav class="nav" aria-label="Navegación principal">
          ${navButton("inicio", "grid", "Inicio")}
          ${navButton("proposiciones", "spark", "Proposiciones")}
          ${navButton("crear", "plus", "Crear proposición")}
          ${navButton("resultados", "trophy", "Resultados")}
        </nav>
        <div class="sidebar-bottom">
          <div class="profile-chip">
            <span class="avatar">${currentUser.initials}</span>
            <span class="profile-copy">
              <strong>${currentUser.name}</strong>
              <span>${currentUser.username}</span>
            </span>
            <button class="icon-btn" data-action="logout" aria-label="Cerrar sesión">${icon("logout")}</button>
          </div>
        </div>
      </aside>
      <main class="main">
        <header class="topbar">
          <div class="topbar-left">
            <button class="icon-btn mobile-menu" data-action="toggle-menu" aria-label="Abrir menú">${icon("menu")}</button>
            <span class="topbar-title">${routeMeta[state.route] || "Gathel"}</span>
          </div>
          <div class="topbar-actions">
            <label class="search">
              ${icon("search")}
              <input class="input" id="global-search" placeholder="Buscar proposiciones" value="${escapeHtml(state.search)}">
            </label>
            <button class="icon-btn notification-dot" aria-label="Notificaciones">${icon("bell")}</button>
          </div>
        </header>
        ${content}
      </main>
      ${state.modal ? predictionModal(state.modal) : ""}
      ${state.toast ? toastTemplate(state.toast) : ""}
    </div>
  `;
}

function navButton(route, iconName, label) {
  return `<button class="nav-btn ${state.route === route ? "active" : ""}" data-route="${route}">${icon(iconName)} ${label}</button>`;
}

function loginPage() {
  return `
    <section class="login-shell">
      <div class="login-panel">
        <div class="brand"><span class="brand-mark">G</span> Gathel</div>
        <form class="login-card" id="login-form">
          <span class="eyebrow">Gaming the life</span>
          <h1>La vida real.<br>Tu próximo juego.</h1>
          <p class="login-copy">Entra para descubrir proposiciones, hacer pronósticos y seguir tus resultados.</p>
          <div class="field">
            <label for="email">Correo electrónico</label>
            <div class="input-wrap">
              ${icon("user")}
              <input class="input" id="email" name="email" type="text" placeholder="usuario@correo.com" required autocomplete="username">
            </div>
          </div>
          <div class="field">
            <label for="password">Contraseña</label>
            <div class="input-wrap">
              ${icon("link")}
              <input class="input" id="password" name="password" type="password" required autocomplete="current-password">
            </div>
          </div>
          <div class="helper-row">
            <label class="check-label"><input type="checkbox" checked> Recordarme</label>
            <button type="button" class="text-link">¿Olvidaste tu contraseña?</button>
          </div>
          <button class="btn btn-primary btn-block" type="submit">Entrar a Gathel ${icon("arrow")}</button>
          ${state.error ? `<p class="form-note" style="color:var(--red)">${escapeHtml(state.error)}</p>` : ""}
          <p class="form-note">Ingresa con un jugador existente en la base de datos Gathel.</p>
        </form>
      </div>
      <div class="login-art" aria-hidden="true">
        <div class="art-content">
          <span class="eyebrow" style="color:var(--lime)">Predice · participa · gana</span>
          <h2>Convierte los momentos en <em>posibilidades.</em></h2>
          <div class="floating-card">
            <div class="floating-head">
              <div class="floating-profile">
                <span class="mini-avatar">SR</span>
                <div><strong>Sofía Rojas</strong><div style="font-size:11px;color:#9baba6;margin-top:3px">@sofiaruns</div></div>
              </div>
              <span class="live-pill">ACTIVA</span>
            </div>
            <div class="floating-question">¿Sofía terminará la media maratón en menos de 2 horas?</div>
            <div class="floating-actions">
              <div class="choice-preview active">Sí, se cumplirá</div>
              <div class="choice-preview">No se cumplirá</div>
            </div>
          </div>
        </div>
      </div>
    </section>
  `;
}

function dashboardPage() {
  const filtered = filterPropositions(propositions).slice(0, 4);
  return appLayout(`
    <div class="page">
      <div class="page-head">
        <div>
          <span class="eyebrow">Jueves, 18 de junio</span>
          <h1 class="page-title">Hola, ${escapeHtml(currentUser.name.split(" ")[0])} 👋</h1>
          <p class="page-subtitle">Esto es lo que está pasando en tu juego hoy.</p>
        </div>
        <button class="btn btn-dark" data-route="crear">${icon("plus")} Crear proposición</button>
      </div>

      <section class="summary-grid" aria-label="Resumen de cuenta">
        ${summaryCard("Puntos disponibles", `${currentUser.points} pts`, "+12 esta semana", "spark", "dark")}
        ${summaryCard("Balance de dinero", `$${currentUser.money.toFixed(2)}`, "USD disponible", "wallet", "lime")}
        ${summaryCard("Pronósticos activos", currentUser.activePredictions, "3 cierran pronto", "clock", "")}
      </section>

      <div class="content-grid">
        <section class="panel">
          <div class="panel-head">
            <div><h2 class="panel-title">Oportunidades para ti</h2><p class="panel-subtitle">Proposiciones activas que podrían interesarte</p></div>
            <button class="view-all" data-route="proposiciones">Ver todas ${icon("chevron")}</button>
          </div>
          <div class="proposition-list">
            ${filtered.map(propositionRow).join("")}
          </div>
        </section>
        <section class="panel">
          <div class="panel-head">
            <div><h2 class="panel-title">Actividad reciente</h2><p class="panel-subtitle">Movimientos de tu cuenta</p></div>
          </div>
          <div class="activity-list">
            ${activities.map(activityItem).join("")}
          </div>
        </section>
      </div>
    </div>
  `);
}

function summaryCard(label, value, note, iconName, variant) {
  return `
    <article class="summary-card ${variant}">
      <div class="summary-label"><span>${label}</span>${icon(iconName)}</div>
      <div class="summary-value">${value}</div>
      <div class="summary-note"><span class="trend">${note}</span></div>
    </article>
  `;
}

function propositionRow(prop) {
  return `
    <article class="proposition-row">
      <span class="prop-avatar" style="background:${prop.colors[0]};color:#24332e">${prop.initials}</span>
      <div class="prop-main">
        <h4>${prop.title}</h4>
        <div class="prop-meta">
          <span>${prop.target}</span>
          <span class="meta-item">${icon("clock")} ${prop.relative}</span>
          <span class="status active">${prop.statusLabel}</span>
        </div>
      </div>
      <button class="btn btn-soft prop-action" data-predict="${prop.id}">Pronosticar</button>
    </article>
  `;
}

function activityItem(item) {
  return `
    <div class="activity-item">
      <span class="activity-icon">${icon(item.icon)}</span>
      <span class="activity-copy"><strong>${item.title}</strong><span>${item.detail}</span><span style="margin-top:4px;color:#a0aaa6">${item.time}</span></span>
    </div>
  `;
}

function propositionsPage() {
  const filtered = filterPropositions(propositions);
  return appLayout(`
    <div class="page">
      <div class="page-head">
        <div>
          <span class="eyebrow">Explorar</span>
          <h1 class="page-title">Proposiciones activas</h1>
          <p class="page-subtitle">Elige una posibilidad y haz tu pronóstico antes del cierre.</p>
        </div>
        <button class="btn btn-dark" data-route="crear">${icon("plus")} Crear proposición</button>
      </div>
      <div class="toolbar">
        <div class="filters">
          ${filterButton("todas", "Todas")}
          ${filterButton("POINT", "Con puntos")}
          ${filterButton("USD", "Con dinero")}
          ${filterButton("pronto", "Cierran pronto")}
        </div>
        <span style="color:var(--muted);font-size:12px">${filtered.length} resultados</span>
      </div>
      ${filtered.length ? `<div class="cards-grid">${filtered.map(gameCard).join("")}</div>` : emptyState()}
    </div>
  `);
}

function filterButton(value, label) {
  return `<button class="filter-btn ${state.filter === value ? "active" : ""}" data-filter="${value}">${label}</button>`;
}

function gameCard(prop) {
  return `
    <article class="game-card">
      <div class="game-cover" style="--cover-a:${prop.colors[0]};--cover-b:${prop.colors[1]}">
        <div class="cover-top">
          <div class="cover-person">
            <span class="mini-avatar">${prop.initials}</span>
            <span><strong>${prop.target}</strong><span>${prop.username}</span></span>
          </div>
          <span class="cover-resource" title="${prop.resourceType}">${icon("image")}</span>
        </div>
      </div>
      <div class="game-body">
        <span class="status active">Activa</span>
        <h3>${prop.title}</h3>
        <div class="game-info">
          <div class="info-block"><span>Cierre</span><strong>${prop.deadline}</strong></div>
          <div class="info-block"><span>Participantes</span><strong>${prop.predictions}</strong></div>
        </div>
        <div class="game-footer">
          <div class="stake-types">${prop.stakes.map(s => `<span class="stake-tag">${s === "POINT" ? "PTS" : s}</span>`).join("")}</div>
          <button class="btn btn-dark prop-action" data-predict="${prop.id}">Pronosticar</button>
        </div>
      </div>
    </article>
  `;
}

function createPage() {
  return appLayout(`
    <div class="page">
      <div class="page-head">
        <div>
          <span class="eyebrow">Nueva posibilidad</span>
          <h1 class="page-title">Crear una proposición</h1>
          <p class="page-subtitle">Describe claramente algo observable que podría ocurrir.</p>
        </div>
      </div>
      <div class="form-layout">
        <form class="panel form-card" id="create-form">
          <h2 class="section-title">¿Sobre quién es?</h2>
          <p class="section-copy">Puedes crearla sobre otro jugador o sobre ti.</p>
          <div class="choice-grid">
            <button type="button" class="choice-card ${state.propositionTarget === "other" ? "active" : ""}" data-target-choice="other">
              <strong>Otro jugador</strong><span>Selecciona una persona de Gathel</span>
            </button>
            <button type="button" class="choice-card ${state.propositionTarget === "self" ? "active" : ""}" data-target-choice="self">
              <strong>Sobre mí</strong><span>Tú serás la persona asociada</span>
            </button>
          </div>
          ${state.propositionTarget === "other" ? `
            <div class="field">
              <label for="target">Jugador asociado</label>
              <select class="select" id="target" required>
                <option value="">Selecciona un jugador</option>
                ${availablePlayers.map(player => `<option value="${player.id}">${escapeHtml(player.name)} — ${escapeHtml(player.username)}</option>`).join("")}
              </select>
            </div>` : `
            <div class="resource-box" style="margin-bottom:18px">
              <span class="avatar">${currentUser.initials}</span>
              <span class="resource-copy"><strong>${currentUser.name}</strong><span>${currentUser.username}</span></span>
              ${icon("check")}
            </div>`}
          <div class="field">
            <label for="proposition">Proposición</label>
            <textarea class="textarea" id="proposition" maxlength="500" placeholder="Ej. Sofía terminará la media maratón en menos de 2 horas" required></textarea>
            <small style="color:var(--muted)">Debe ser específica y tener un resultado verificable.</small>
          </div>
          <div class="form-divider"></div>
          <h2 class="section-title">Contenido relacionado</h2>
          <p class="section-copy">Registra una referencia pública o autorizada. Gathel almacena el recurso de forma genérica.</p>
          <div class="field-row">
            <div class="field">
              <label for="resource-type">Tipo de recurso</label>
              <select class="select" id="resource-type" required>
                <option value="post">Publicación</option>
                <option value="story">Historia</option>
                <option value="reel">Reel</option>
                <option value="video">Video</option>
              </select>
            </div>
            <div class="field">
              <label for="stake-mode">Pronósticos permitidos</label>
              <select class="select" id="stake-mode" required>
                <option value="BOTH">Puntos y dinero</option>
                <option value="POINT">Solo puntos</option>
                <option value="USD">Solo dinero</option>
              </select>
            </div>
          </div>
          <div class="field">
            <label for="resource-url">URL del contenido</label>
            <div class="input-wrap">
              ${icon("link")}
              <input class="input" id="resource-url" type="url" placeholder="https://..." required>
            </div>
          </div>
          <div class="resource-box">
            <span class="activity-icon">${icon("info")}</span>
            <span class="resource-copy">
              <strong>El resultado se procesará fuera del MVP</strong>
              <span>La aplicación recibirá únicamente el estado final del workflow.</span>
            </span>
          </div>
          <div class="form-divider"></div>
          <button class="btn btn-primary btn-block" type="submit">${icon("plus")} Crear proposición</button>
        </form>
        <aside class="panel rules-card dark">
          <span class="eyebrow" style="color:var(--lime)">Antes de publicar</span>
          <h2 class="section-title" style="margin-top:10px">Una buena proposición</h2>
          <div class="rules-list">
            <div class="rule"><span class="rule-num">1</span><span>Describe una acción o resultado concreto y observable.</span></div>
            <div class="rule"><span class="rule-num">2</span><span>Incluye una referencia de contenido público o autorizado.</span></div>
            <div class="rule"><span class="rule-num">3</span><span>Evita afirmaciones ambiguas que no puedan resolverse claramente.</span></div>
            <div class="rule"><span class="rule-num">4</span><span>La persona asociada podrá aceptar o rechazar la proposición mediante procesos externos al MVP.</span></div>
          </div>
        </aside>
      </div>
    </div>
  `);
}

function resultsPage() {
  return appLayout(`
    <div class="page">
      <div class="page-head">
        <div>
          <span class="eyebrow">Historial</span>
          <h1 class="page-title">Resultados</h1>
          <p class="page-subtitle">Consulta las proposiciones finalizadas y el resultado de tus pronósticos.</p>
        </div>
      </div>
      <section class="panel results-table">
        <div class="table-row table-head">
          <span>Proposición</span><span>Resultado</span><span>Tu pronóstico</span><span>Apuesta</span><span>Balance</span>
        </div>
        ${results.map(resultRow).join("")}
      </section>
    </div>
  `);
}

function resultRow(result) {
  const won = result.result === result.answer;
  return `
    <div class="table-row">
      <div class="table-prop">
        <span class="prop-avatar" style="width:37px;height:37px;background:${won ? "#e5f4d1" : "#f8ded9"}">${won ? icon("check") : icon("x")}</span>
        <span><strong>${result.title}</strong><small style="display:block;color:var(--muted);margin-top:4px">${result.date} · #${result.id}</small></span>
      </div>
      <span class="result-badge ${result.result ? "yes" : "no"}">${result.result ? "Sí se cumplió" : "No se cumplió"}</span>
      <span>${result.answer ? "Sí" : "No"}</span>
      <strong>${result.stake}</strong>
      <strong class="${result.gain.startsWith("+") ? "gain" : "loss"}">${result.gain}</strong>
    </div>
  `;
}

function predictionModal(propId) {
  const prop = propositions.find(p => p.id === Number(propId));
  if (!prop) return "";
  const acceptsPoint = prop.stakes.includes("POINT");
  const acceptsUsd = prop.stakes.includes("USD");
  if (!prop.stakes.includes(state.prediction.currency)) {
    state.prediction.currency = acceptsPoint ? "POINT" : "USD";
    state.prediction.amount = acceptsPoint ? "1" : "5";
  }
  return `
    <div class="modal-backdrop" data-action="close-modal">
      <section class="modal" role="dialog" aria-modal="true" aria-labelledby="prediction-title">
        <div class="modal-head">
          <div><span class="eyebrow">Nuevo pronóstico</span><h2 id="prediction-title">Elige tu resultado</h2><p>${prop.relative}</p></div>
          <button class="icon-btn" data-action="close-modal" aria-label="Cerrar">${icon("x")}</button>
        </div>
        <form class="modal-body" id="prediction-form">
          <div class="prediction-summary">${prop.title}</div>
          <div class="prediction-options">
            <button type="button" class="prediction-choice yes ${state.prediction.answer === "yes" ? "active" : ""}" data-answer="yes">${icon("check")} Sí se cumplirá</button>
            <button type="button" class="prediction-choice no ${state.prediction.answer === "no" ? "active" : ""}" data-answer="no">${icon("x")} No se cumplirá</button>
          </div>
          ${acceptsPoint && acceptsUsd ? `
            <div class="stake-switch">
              <button type="button" class="${state.prediction.currency === "POINT" ? "active" : ""}" data-currency="POINT">Puntos</button>
              <button type="button" class="${state.prediction.currency === "USD" ? "active" : ""}" data-currency="USD">Dinero real</button>
            </div>` : ""}
          <div class="field">
            <label for="amount">Monto a pronosticar</label>
            <div class="amount-box">
              <span class="currency-prefix">${state.prediction.currency === "POINT" ? "PTS" : "$"}</span>
              <input class="input" id="amount" type="number" min="${state.prediction.currency === "POINT" ? "1" : "0.01"}" max="${state.prediction.currency === "POINT" ? "1" : currentUser.money}" step="${state.prediction.currency === "POINT" ? "1" : "0.01"}" value="${state.prediction.amount}" required>
            </div>
            <div class="amount-help">
              <span>${state.prediction.currency === "POINT" ? "Máximo permitido: 1 punto" : `Disponible: $${currentUser.money.toFixed(2)}`}</span>
              <span>Comisiones según configuración vigente</span>
            </div>
          </div>
          <div class="modal-actions">
            <button type="button" class="btn btn-ghost" data-action="close-modal">Cancelar</button>
            <button type="submit" class="btn btn-primary">Confirmar pronóstico ${icon("arrow")}</button>
          </div>
        </form>
      </section>
    </div>
  `;
}

function toastTemplate(toast) {
  return `<div class="toast"><span class="activity-icon">${icon("check")}</span><span><strong>${toast.title}</strong><span>${toast.message}</span></span></div>`;
}

function emptyState() {
  return `<div class="panel empty-state"><span class="activity-icon">${icon("search")}</span><h3>Sin coincidencias</h3><p>Prueba con otra búsqueda o filtro.</p></div>`;
}

function filterPropositions(items) {
  const query = state.search.trim().toLowerCase();
  return items.filter(prop => {
    const matchesSearch = !query || `${prop.title} ${prop.target} ${prop.username}`.toLowerCase().includes(query);
    const matchesFilter =
      state.filter === "todas" ||
      prop.stakes.includes(state.filter) ||
      (state.filter === "pronto" && ["Hoy, 8:30 p. m.", "Mañana, 5:00 p. m."].includes(prop.deadline));
    return matchesSearch && matchesFilter;
  });
}

function escapeHtml(text) {
  return String(text).replace(/[&<>"']/g, char => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;" })[char]);
}

function showToast(title, message) {
  state.toast = { title, message };
  render();
  window.setTimeout(() => {
    state.toast = null;
    render();
  }, 3200);
}

function navigate(route) {
  state.route = route;
  state.mobileMenu = false;
  location.hash = `/${route}`;
  render();
  window.scrollTo({ top: 0, behavior: "smooth" });
}

function render() {
  const root = document.querySelector("#app");
  if (!state.authenticated) {
    root.innerHTML = loginPage();
    bindEvents();
    return;
  }
  const pages = {
    inicio: dashboardPage,
    proposiciones: propositionsPage,
    crear: createPage,
    resultados: resultsPage,
  };
  root.innerHTML = (pages[state.route] || dashboardPage)();
  bindEvents();
}

function bindEvents() {
  document.querySelectorAll("[data-route]").forEach(button => {
    button.addEventListener("click", () => navigate(button.dataset.route));
  });

  document.querySelector("#login-form")?.addEventListener("submit", async event => {
    event.preventDefault();
    state.error = "";
    const form = event.currentTarget;
    const submit = form.querySelector("button[type='submit']");
    submit.disabled = true;
    try {
      const response = await apiRequest("/api/auth/login", {
        method: "POST",
        body: JSON.stringify({
          identifier: form.querySelector("#email").value,
          password: form.querySelector("#password").value,
        }),
      });
      sessionStorage.setItem(API_TOKEN_KEY, response.token);
      state.authenticated = true;
      await loadApplicationData();
      navigate("inicio");
    } catch (error) {
      state.error = error.message;
      render();
    } finally {
      submit.disabled = false;
    }
  });

  document.querySelectorAll("[data-filter]").forEach(button => {
    button.addEventListener("click", () => {
      state.filter = button.dataset.filter;
      render();
    });
  });

  document.querySelectorAll("[data-predict]").forEach(button => {
    button.addEventListener("click", () => {
      state.modal = Number(button.dataset.predict);
      state.prediction = { answer: "yes", currency: "POINT", amount: "1" };
      render();
    });
  });

  document.querySelectorAll("[data-answer]").forEach(button => {
    button.addEventListener("click", () => {
      state.prediction.answer = button.dataset.answer;
      render();
    });
  });

  document.querySelectorAll("[data-currency]").forEach(button => {
    button.addEventListener("click", () => {
      state.prediction.currency = button.dataset.currency;
      state.prediction.amount = state.prediction.currency === "POINT" ? "1" : "5";
      render();
    });
  });

  document.querySelectorAll("[data-target-choice]").forEach(button => {
    button.addEventListener("click", () => {
      state.propositionTarget = button.dataset.targetChoice;
      render();
    });
  });

  document.querySelectorAll("[data-action='close-modal']").forEach(element => {
    element.addEventListener("click", event => {
      if (element.classList.contains("modal-backdrop") && event.target !== element) return;
      state.modal = null;
      render();
    });
  });

  document.querySelector("[data-action='toggle-menu']")?.addEventListener("click", () => {
    state.mobileMenu = !state.mobileMenu;
    render();
  });

  document.querySelector("[data-action='logout']")?.addEventListener("click", async () => {
    try {
      await apiRequest("/api/auth/logout", { method: "POST", body: "{}" });
    } catch {
      // La sesión local se elimina aunque el API ya no esté disponible.
    }
    sessionStorage.removeItem(API_TOKEN_KEY);
    state.authenticated = false;
    state.route = "inicio";
    render();
  });

  document.querySelector("#global-search")?.addEventListener("input", event => {
    state.search = event.target.value;
    if (state.route === "proposiciones") render();
  });

  document.querySelector("#prediction-form")?.addEventListener("submit", async event => {
    event.preventDefault();
    const amount = event.currentTarget.querySelector("#amount").value;
    try {
      await apiRequest("/api/predictions", {
        method: "POST",
        body: JSON.stringify({
          propositionId: state.modal,
          answer: state.prediction.answer,
          currencyCode: state.prediction.currency,
          amount,
        }),
      });
      state.modal = null;
      await loadApplicationData();
      showToast("Pronóstico registrado", `${amount} ${state.prediction.currency === "POINT" ? "punto" : "USD"} reservado correctamente.`);
    } catch (error) {
      state.modal = null;
      showToast("No se pudo registrar", error.message);
    }
  });

  document.querySelector("#create-form")?.addEventListener("submit", async event => {
    event.preventDefault();
    const form = event.currentTarget;
    const proposition = form.querySelector("#proposition").value.trim();
    const targetPlayerId = state.propositionTarget === "self"
      ? currentUser.id
      : Number(form.querySelector("#target").value);
    try {
      await apiRequest("/api/propositions", {
        method: "POST",
        body: JSON.stringify({
          targetPlayerId,
          text: proposition,
          resourceType: form.querySelector("#resource-type").value,
          resourceUrl: form.querySelector("#resource-url").value,
          predictionMode: form.querySelector("#stake-mode").value,
        }),
      });
      showToast("Proposición creada", `"${proposition.slice(0, 55)}${proposition.length > 55 ? "…" : ""}" quedó registrada como pendiente.`);
      form.reset();
    } catch (error) {
      showToast("No se pudo crear", error.message);
    }
  });
}

window.addEventListener("hashchange", () => {
  state.route = location.hash.replace("#/", "") || "inicio";
  render();
});

async function initialize() {
  if (state.authenticated) {
    try {
      await loadApplicationData();
    } catch {
      sessionStorage.removeItem(API_TOKEN_KEY);
      state.authenticated = false;
    }
  }
  render();
}

initialize();
