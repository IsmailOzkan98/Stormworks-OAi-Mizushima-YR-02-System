
/* ==========================================================
   RESIDENT EVIL — S.T.A.R.S. CHARACTER & CONDITION SYSTEM
   Independiente del HTML original.
   No necesita dat.GUI ni librerías adicionales.
   ========================================================== */

(() => {
  "use strict";

  // Evita crear el panel dos veces.
  if (document.getElementById("stars-control-panel")) return;

  const characters = {
    jill: {
      name: "Jill",
      fullname: "Jill Valentine",
      date: "October 1st 1998",
      quote: '"You want S.T.A.R.S.? I\'ll give you S.T.A.R.S."',
      state: "Virus!",
      initials: "JV"
    },
    leon: {
      name: "Leon",
      fullname: "Leon S. Kennedy",
      date: "September 29th 1998",
      quote: '"Claire, wait! Man, why doesn\'t anyone ever listen to me?"',
      state: "Fine",
      initials: "LK"
    },
    claire: {
      name: "Claire",
      fullname: "Claire Redfield",
      date: "September 29th 1998",
      quote: '"I\'m looking for my brother, Chris."',
      state: "Danger",
      initials: "CR"
    }
  };

  const states = {
    "Fine": {
      color: "#2F863A",
      description: "CONDITION STABLE",
      pulse: 72
    },
    "Caution": {
      color: "#F0AD29",
      description: "CAUTION DETECTED",
      pulse: 105
    },
    "Danger": {
      color: "#D90D1E",
      description: "CRITICAL CONDITION",
      pulse: 145
    },
    "Poison": {
      color: "#870DD9",
      description: "TOXIC CONTAMINATION",
      pulse: 118
    },
    "Virus!": {
      color: "#F602FD",
      description: "VIRAL INFECTION",
      pulse: 160
    }
  };

  let currentCharacter = "jill";

  // ----------------------------------------------------------
  // ESTILOS DEL PANEL
  // ----------------------------------------------------------

  const style = document.createElement("style");

  style.textContent = `
    #stars-control-panel {
      --stars-color: #2F863A;
      position: fixed;
      right: 22px;
      bottom: 22px;
      z-index: 99999;
      width: min(340px, calc(100vw - 32px));
      padding: 16px;
      color: #e5e9e7;
      background:
        linear-gradient(145deg, rgba(58,64,69,.98), rgba(27,31,56,.98));
      border: 2px solid #636B79;
      outline: 1px solid #2C3035;
      box-shadow:
        inset 0 1px rgba(255,255,255,.12),
        0 7px 0 rgba(0,0,0,.4),
        0 12px 30px rgba(0,0,0,.55);
      font-family: 'Share Tech Mono', monospace;
      box-sizing: border-box;
    }

    #stars-control-panel *,
    #stars-control-panel *::before,
    #stars-control-panel *::after {
      box-sizing: border-box;
    }

    #stars-control-panel .stars-heading {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 10px;
      padding-bottom: 10px;
      margin-bottom: 12px;
      border-bottom: 2px solid #636B79;
      color: #AEDCE1;
      font-size: 13px;
      letter-spacing: 2px;
    }

    #stars-control-panel .stars-indicator {
      color: var(--stars-color);
      text-shadow: 0 0 8px var(--stars-color);
      animation: stars-blink 1.5s infinite;
    }

    #stars-control-panel .stars-character {
      display: flex;
      align-items: center;
      gap: 12px;
      margin-bottom: 13px;
    }

    #stars-control-panel .stars-avatar {
      width: 55px;
      height: 55px;
      flex: 0 0 55px;
      display: grid;
      place-items: center;
      color: #AEDCE1;
      background: #111;
      border: 3px solid #636B79;
      outline: 2px solid #2C3035;
      font-family: 'VT323', monospace;
      font-size: 25px;
    }

    #stars-control-panel .stars-name {
      color: #f7f7f0;
      font-family: 'Rajdhani', sans-serif;
      font-size: 21px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1px;
    }

    #stars-control-panel .stars-date {
      margin-top: 3px;
      color: #9da9b8;
      font-size: 10px;
    }

    #stars-control-panel .stars-quote {
      min-height: 38px;
      padding: 9px;
      margin-bottom: 12px;
      color: #AEDCE1;
      background: rgba(0,0,0,.35);
      border-left: 3px solid #636B79;
      font-size: 11px;
      line-height: 1.5;
    }

    #stars-control-panel .stars-label {
      display: block;
      margin: 10px 0 5px;
      color: #aab6c1;
      font-size: 10px;
      letter-spacing: 1.5px;
      text-transform: uppercase;
    }

    #stars-control-panel select {
      width: 100%;
      min-height: 36px;
      padding: 7px 10px;
      color: #e5e9e7;
      background: #171b26;
      border: 2px solid #636B79;
      border-radius: 0;
      font: 13px 'Share Tech Mono', monospace;
      cursor: pointer;
    }

    #stars-control-panel select:focus {
      outline: 1px solid #AEDCE1;
      border-color: #AEDCE1;
    }

    #stars-control-panel .stars-state {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
      margin-top: 12px;
      padding: 9px;
      background: #111;
      border: 2px solid #636B79;
      box-shadow: inset 0 0 8px rgba(0,0,0,.7);
    }

    #stars-control-panel .stars-state-name {
      color: var(--stars-color);
      font-family: 'VT323', monospace;
      font-size: 25px;
      text-shadow: 0 0 8px var(--stars-color);
    }

    #stars-control-panel .stars-state-description {
      color: #aab6c1;
      font-size: 9px;
      text-align: right;
    }

    #stars-control-panel .stars-monitor {
      margin-top: 12px;
      padding: 8px;
      background: #080d0d;
      border: 2px solid #2C3035;
      outline: 1px solid #636B79;
      overflow: hidden;
    }

    #stars-control-panel .stars-monitor-label {
      margin-bottom: 5px;
      color: #718b7b;
      font-size: 9px;
      letter-spacing: 2px;
    }

    #stars-control-panel .stars-heartbeat {
      display: block;
      width: 100%;
      height: 42px;
      overflow: visible;
    }

    #stars-control-panel .stars-heartbeat path {
      fill: none;
      stroke: var(--stars-color);
      stroke-width: 2.5;
      stroke-linejoin: bevel;
      stroke-linecap: square;
      stroke-dasharray: 500;
      stroke-dashoffset: 500;
      filter: drop-shadow(0 0 4px var(--stars-color));
      animation: stars-heartbeat 2s linear infinite;
    }

    #stars-control-panel .stars-footer {
      display: flex;
      justify-content: space-between;
      margin-top: 10px;
      color: #758292;
      font-size: 9px;
      letter-spacing: 1px;
    }

    #stars-control-panel .stars-close {
      padding: 2px 6px;
      color: #aab6c1;
      background: transparent;
      border: 1px solid #636B79;
      font: inherit;
      cursor: pointer;
    }

    #stars-control-panel .stars-close:hover {
      color: white;
      border-color: #AEDCE1;
    }

    @keyframes stars-heartbeat {
      to { stroke-dashoffset: 0; }
    }

    @keyframes stars-blink {
      0%, 100% { opacity: 1; }
      50% { opacity: .35; }
    }

    @media (max-width: 600px) {
      #stars-control-panel {
        right: 10px;
        bottom: 10px;
        width: min(310px, calc(100vw - 20px));
      }
    }

    @media (prefers-reduced-motion: reduce) {
      #stars-control-panel *,
      #stars-control-panel *::before,
      #stars-control-panel *::after {
        animation: none !important;
      }

      #stars-control-panel .stars-heartbeat path {
        stroke-dashoffset: 0;
      }
    }
  `;

  document.head.appendChild(style);

  // ----------------------------------------------------------
  // CREAR PANEL
  // ----------------------------------------------------------

  const panel = document.createElement("section");
  panel.id = "stars-control-panel";
  panel.setAttribute("aria-label", "S.T.A.R.S. character control");

  panel.innerHTML = `
    <div class="stars-heading">
      <span>S.T.A.R.S. // PERSONNEL FILE</span>
      <button class="stars-close" type="button" aria-label="Close panel">×</button>
    </div>

    <div class="stars-character">
      <div class="stars-avatar" id="stars-avatar">JV</div>
      <div>
        <div class="stars-name" id="stars-fullname">Jill Valentine</div>
        <div class="stars-date" id="stars-date">October 1st 1998</div>
      </div>
    </div>

    <div class="stars-quote" id="stars-quote"></div>

    <label class="stars-label" for="stars-character-select">
      Select character
    </label>
    <select id="stars-character-select">
      <option value="jill">Jill Valentine</option>
      <option value="leon">Leon S. Kennedy</option>
      <option value="claire">Claire Redfield</option>
    </select>

    <label class="stars-label" for="stars-state-select">
      Condition state
    </label>
    <select id="stars-state-select">
      <option>Fine</option>
      <option>Caution</option>
      <option>Danger</option>
      <option>Poison</option>
      <option>Virus!</option>
    </select>

    <div class="stars-state">
      <div class="stars-state-name" id="stars-state-name">Virus!</div>
      <div class="stars-state-description" id="stars-state-description">
        VIRAL INFECTION
      </div>
    </div>

    <div class="stars-monitor">
      <div class="stars-monitor-label">BIOLOGICAL MONITOR // LIVE</div>
      <svg class="stars-heartbeat" viewBox="0 0 300 45"
           preserveAspectRatio="none" aria-hidden="true">
        <path id="stars-heartbeat-path"
          d="M0 23 H65 L78 21 H91 L101 23 H112 L121 19
             L132 3 L143 40 L153 15 L163 23 H185
             L195 21 H205 L215 23 H300"/>
      </svg>
    </div>

    <div class="stars-footer">
      <span>RACCOON CITY // 1998</span>
      <span id="stars-pulse">72 BPM</span>
    </div>
  `;

  document.body.appendChild(panel);

  // ----------------------------------------------------------
  // REFERENCIAS Y ESTADO
  // ----------------------------------------------------------

  const $ = (id) => panel.querySelector("#" + id);

  const characterSelect = $("stars-character-select");
  const stateSelect = $("stars-state-select");

  const savedStates = {};

  Object.entries(characters).forEach(([key, character]) => {
    savedStates[key] = character.state;
  });

  // ----------------------------------------------------------
  // ACTUALIZAR ESTADO BIOMÉTRICO
  // ----------------------------------------------------------

  function updateCondition(state) {
    const condition = states[state];
    if (!condition) return;

    const color = condition.color;

    panel.style.setProperty("--stars-color", color);

    $("stars-state-name").textContent = state;
    $("stars-state-description").textContent = condition.description;
    $("stars-pulse").textContent = condition.pulse + " BPM";

    // Sincronizar también los indicadores existentes
    // sin sustituir el texto ni la lógica de la aplicación.

    document.querySelectorAll(".indicator.active").forEach((indicator) => {
      indicator.style.boxShadow =
        `0 0 10px ${color}, inset 0 0 4px ${color}`;
    });

    document.querySelectorAll(".booster.pulse").forEach((booster) => {
      booster.style.setProperty("--stars-alert-color", color);
    });
  }

  // ----------------------------------------------------------
  // CAMBIAR PERSONAJE
  // ----------------------------------------------------------

  function updateCharacter(key) {
    const character = characters[key];
    if (!character) return;

    currentCharacter = key;

    $("stars-avatar").textContent = character.initials;
    $("stars-fullname").textContent = character.fullname;
    $("stars-date").textContent = character.date;
    $("stars-quote").textContent = character.quote;

    const characterState = savedStates[key];

    stateSelect.value = characterState;
    updateCondition(characterState);
  }

  // ----------------------------------------------------------
  // EVENTOS
  // ----------------------------------------------------------

  characterSelect.addEventListener("change", (event) => {
    updateCharacter(event.target.value);
  });

  stateSelect.addEventListener("change", (event) => {
    const selectedState = event.target.value;

    savedStates[currentCharacter] = selectedState;
    updateCondition(selectedState);
  });

  $("stars-close").addEventListener("click", () => {
    panel.remove();
    style.remove();
  });

  // ----------------------------------------------------------
  // INICIALIZACIÓN
  // ----------------------------------------------------------

  updateCharacter(currentCharacter);

})();
