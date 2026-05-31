/**
 * Manta: Travesía por Jocay — núcleo + 4 minijuegos distintos
 */

const canvas = document.getElementById("game-canvas");
const ctx = canvas.getContext("2d");
const GW = () => (window.Mobile?.GAME_WIDTH ?? 390);
const GH = () => (window.Mobile?.GAME_HEIGHT ?? 700);

canvas.width = GW();
canvas.height = GH();

const hud = {
  level: document.getElementById("hud-level"),
  score: document.getElementById("hud-score"),
  lives: document.getElementById("hud-lives"),
  goal: document.getElementById("hud-goal"),
  progress: document.getElementById("progress-bar"),
};

const guide = {
  avatar: document.getElementById("guide-avatar"),
  name: document.getElementById("guide-name"),
  role: document.getElementById("guide-role"),
  text: document.getElementById("guide-text"),
};

const LEVELS = [
  {
    id: 1,
    name: "Umiña",
    role: "Diosa de la sanación",
    color: "#2a9d8f",
    mode: "catcher",
    target: 15,
    timeLimit: 100,
    playerSpeed: 2.8,
    briefing:
      "Minijuego: **Lluvia de esmeraldas**. Las joyas sagradas caen del cielo sobre tu balsa. " +
      "Muévete solo a izquierda y derecha para atraparlas. ¡No toques las tormentas!",
  },
  {
    id: 2,
    name: "Lligua Tohallí",
    role: "Señor de las aguas",
    color: "#e9c46a",
    mode: "channel",
    target: 1,
    timeLimit: 70,
    playerSpeed: 2.5,
    briefing:
      "Minijuego: **Canales de arrecife**. Los arrecifes forman paredes con un paso estrecho. " +
      "Sube y baja con el joystick para cruzar cada canal sin chocar. Llega al puerto de Manta.",
  },
  {
    id: 3,
    name: "Navegante Manteño",
    role: "Mercader de la Liga",
    color: "#f4a261",
    mode: "lanes",
    target: 12,
    timeLimit: 55,
    playerSpeed: 2.4,
    briefing:
      "Minijuego: **Ruta comercial**. Hay 3 carriles en el mar. Usa los botones ◀ ▶ (o desliza) " +
      "para cambiar de carril y recoger conchas Spondylus. ¡Evita a los piratas!",
  },
  {
    id: 4,
    name: "Guardián de Jocay",
    role: "Casa de los peces",
    color: "#48cae4",
    mode: "rescue",
    target: 12,
    timeLimit: 60,
    playerSpeed: 2.3,
    briefing:
      "Minijuego: **Red de rescate**. Los peces cruzan la bahía. Colócate cerca y pulsa **LANZAR RED** " +
      "para atraparlos. La basura rompe tu red si la atrapas. ¡Salva a los peces de Jocay!",
  },
];

const GAME_PACE = 0.82;
const TARGET_FPS = 60;

const KEYS = {};
let state = "menu";
let currentLevel = 0;
let score = 0;
let lives = 3;
let collected = 0;
let timeLeft = 0;
let wavePhase = 0;
let animationId = null;
let lastFrameTime = 0;
let levelStarted = false;
let levelElapsed = 0;
let particles = [];
let modeState = null;
let currentMode = null;

const player = { x: 80, y: 260, w: 56, h: 32, speed: 2.6, invincible: 0 };

document.addEventListener("keydown", (e) => {
  KEYS[e.code] = true;
  if (["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "Space"].includes(e.code)) e.preventDefault();
});
document.addEventListener("keyup", (e) => {
  KEYS[e.code] = false;
});

document.getElementById("btn-play").addEventListener("click", startGame);
document.getElementById("btn-start-level").addEventListener("click", beginLevelPlay);
document.getElementById("btn-restart").addEventListener("click", () => {
  document.getElementById("overlay-end").classList.add("hidden");
  startGame();
});

function getMode() {
  return LevelModes[LEVELS[currentLevel].mode];
}

function buildModeState() {
  return {
    player,
    collected: 0,
    addScore: (n) => {
      score += n;
    },
    laneTapLeft: false,
    laneTapRight: false,
    netTap: false,
    onWin: levelComplete,
    onHit: hitPlayer,
    setControlMode: window.setControlMode,
  };
}

function startGame() {
  document.getElementById("overlay-start").classList.add("hidden");
  currentLevel = 0;
  score = 0;
  lives = 3;
  showLevelBriefing();
}

function showLevelBriefing() {
  const lvl = LEVELS[currentLevel];
  state = "briefing";
  levelStarted = false;
  currentMode = getMode();
  if (currentMode?.onEnd && modeState) currentMode.onEnd(modeState);

  guide.name.textContent = lvl.name;
  guide.role.textContent = lvl.role;
  guide.text.textContent = lvl.briefing.replace(/\*\*/g, "");
  guide.avatar.style.background = `linear-gradient(145deg, ${lvl.color}, #0a3d62)`;
  drawGuideAvatar(lvl.id);

  hud.level.textContent = `${lvl.id} / 4`;
  hud.score.textContent = score;
  hud.lives.textContent = lives;
  hud.goal.textContent = currentMode?.hudGoal?.(lvl) ?? lvl.goalText ?? "—";
  hud.progress.style.width = "0%";

  document.getElementById("btn-start-level").textContent = "Comenzar nivel";
  document.getElementById("btn-start-level").disabled = false;

  if (window.setGuideModalVisible) setGuideModalVisible(true);
  if (window.setTouchControlsVisible) setTouchControlsVisible(false);

  modeState = buildModeState();
  player.w = 56;
  player.h = 32;
  currentMode.init(modeState);
  updateHUD();
}

function beginLevelPlay() {
  if (state !== "briefing") return;
  const lvl = LEVELS[currentLevel];
  state = "playing";
  levelStarted = true;
  collected = 0;
  timeLeft = lvl.timeLimit ?? 9999;
  player.speed = lvl.playerSpeed ?? 2.6;
  player.invincible = 0.9;
  levelElapsed = 0;
  particles = [];

  modeState = buildModeState();
  modeState.collected = 0;
  currentMode = getMode();
  currentMode.init(modeState);

  document.getElementById("btn-start-level").textContent = "Jugando...";
  document.getElementById("btn-start-level").disabled = true;
  if (window.setGuideModalVisible) setGuideModalVisible(false);
  if (window.setTouchControlsVisible) setTouchControlsVisible(true);
  if (window.setControlMode) window.setControlMode(lvl.mode === "catcher" ? "catcher" : lvl.mode);
}

function updateHUD() {
  const lvl = LEVELS[currentLevel];
  hud.score.textContent = score;
  hud.lives.textContent = lives;
  collected = modeState?.collected ?? collected;

  let progress = 0;
  if (currentMode?.progress) {
    progress = currentMode.progress(modeState);
  } else if (lvl.target > 1) {
    progress = ((modeState?.collected ?? collected) / lvl.target) * 100;
  } else {
    progress = modeState?.distance ? (modeState.distance / modeState.goalDistance) * 100 : 0;
  }
  hud.progress.style.width = `${Math.min(100, progress)}%`;
}

function getInputAxes() {
  let dx = 0;
  let dy = 0;
  if (KEYS["ArrowLeft"] || KEYS["KeyA"]) dx -= 1;
  if (KEYS["ArrowRight"] || KEYS["KeyD"]) dx += 1;
  if (KEYS["ArrowUp"] || KEYS["KeyW"]) dy -= 1;
  if (KEYS["ArrowDown"] || KEYS["KeyS"]) dy += 1;
  const touch = window.Mobile?.touch;
  if (touch?.active) {
    dx = touch.x;
    dy = touch.y;
  }
  if (dx !== 0 && dy !== 0 && !touch?.active) {
    dx *= 0.707;
    dy *= 0.707;
  }
  return { dx, dy };
}

function updatePlaying(dt) {
  const lvl = LEVELS[currentLevel];
  levelElapsed += dt;

  if (lvl.timeLimit) {
    timeLeft -= dt;
    if (timeLeft <= 0) {
      gameOver(false);
      return;
    }
  }

  if (player.invincible > 0) player.invincible -= dt;

  const { dx, dy } = getInputAxes();
  const inputDx = modeState?.laneOnlyX ? dx : dx;
  const inputDy = modeState?.laneOnlyX ? 0 : dy;
  currentMode.handleInput(modeState, dt, inputDx, inputDy);
  currentMode.update(modeState, dt, lvl);

  collected = modeState.collected;

  for (let i = particles.length - 1; i >= 0; i--) {
    const p = particles[i];
    p.x += p.vx * dt * TARGET_FPS;
    p.y += p.vy * dt * TARGET_FPS;
    p.life -= dt * TARGET_FPS;
    if (p.life <= 0) particles.splice(i, 1);
  }

  updateHUD();
}

function rectOverlap(a, b) {
  return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
}

function circleRectOverlap(cx, cy, r, rect) {
  const closestX = Math.max(rect.x, Math.min(cx, rect.x + rect.w));
  const closestY = Math.max(rect.y, Math.min(cy, rect.y + rect.h));
  const dx = cx - closestX;
  const dy = cy - closestY;
  return dx * dx + dy * dy < r * r;
}

function hitPlayer() {
  if (player.invincible > 0) return;
  lives--;
  player.invincible = 0.85;
  spawnSplash(player.x + player.w / 2, player.y + player.h / 2);
  updateHUD();
  if (lives <= 0) gameOver(false);
}

function spawnSplash(x, y, color = "#48cae4") {
  for (let i = 0; i < 8; i++) {
    particles.push({
      x,
      y,
      vx: (Math.random() - 0.5) * 4,
      vy: (Math.random() - 0.5) * 4,
      life: 20 + Math.random() * 15,
      color,
      r: 2 + Math.random() * 3,
    });
  }
}

function levelComplete() {
  state = "levelComplete";
  score += 200 + currentLevel * 50 + (modeState?.collected ?? 0) * 10;
  const mode = getMode();
  if (mode?.onEnd && modeState) mode.onEnd(modeState);
  currentLevel++;
  if (currentLevel >= LEVELS.length) {
    gameOver(true);
  } else {
    setTimeout(showLevelBriefing, 600);
  }
}

function gameOver(won) {
  state = won ? "win" : "lose";
  if (getMode()?.onEnd && modeState) getMode().onEnd(modeState);
  if (window.setTouchControlsVisible) setTouchControlsVisible(false);
  if (window.setControlMode) window.setControlMode("joystick");

  const overlay = document.getElementById("overlay-end");
  document.getElementById("end-title").textContent = won ? "¡Travesía completada!" : "El mar fue fuerte hoy";
  document.getElementById("end-message").textContent = won
    ? "Completaste los 4 juegos de la bahía: esmeraldas, canales, comercio y rescate en Jocay."
    : "Cada minijuego es distinto. Practica y vuelve a zarpar.";
  document.getElementById("end-score").textContent = score;
  overlay.classList.remove("hidden");
}

function drawOcean(dt = 1 / 60) {
  wavePhase += dt * 1.2;
  const grd = ctx.createLinearGradient(0, 0, 0, GH());
  grd.addColorStop(0, "#1a8fb5");
  grd.addColorStop(0.5, "#147a9e");
  grd.addColorStop(1, "#0d5f7a");
  ctx.fillStyle = grd;
  ctx.fillRect(0, 0, GW(), GH());

  const lvl = LEVELS[currentLevel];
  if (lvl?.mode === "catcher") {
    ctx.fillStyle = "rgba(42,157,143,0.15)";
    ctx.fillRect(0, 0, GW(), GH() * 0.55);
  }
  if (lvl?.mode === "lanes") {
    ctx.fillStyle = "rgba(244,162,97,0.08)";
    ctx.fillRect(0, GH() - 140, GW(), 140);
  }
}

function drawBalsa(x, y, w, h, invincible) {
  if (invincible > 0 && Math.floor(invincible * 12) % 2 === 0) ctx.globalAlpha = 0.5;
  ctx.fillStyle = "#8B5A2B";
  ctx.beginPath();
  ctx.ellipse(x + w / 2, y + h * 0.7, w / 2, h / 3, 0, 0, Math.PI * 2);
  ctx.fill();
  ctx.strokeStyle = "#5c3d1e";
  ctx.lineWidth = 2;
  ctx.stroke();
  ctx.fillStyle = "#f4e4bc";
  ctx.fillRect(x + w * 0.35, y + 2, 4, h * 0.55);
  ctx.fillStyle = "#e76f51";
  ctx.beginPath();
  ctx.moveTo(x + w * 0.4, y + 4);
  ctx.lineTo(x + w * 0.4, y - h * 0.9);
  ctx.lineTo(x + w * 0.55, y + 8);
  ctx.closePath();
  ctx.fill();
  ctx.fillStyle = "#2d6a4f";
  ctx.fillRect(x + w * 0.1, y + h * 0.35, w * 0.8, 6);
  ctx.globalAlpha = 1;
}

function drawTimer() {
  const lvl = LEVELS[currentLevel];
  if (!lvl?.timeLimit || state !== "playing") return;
  ctx.fillStyle = "rgba(0,0,0,0.4)";
  ctx.fillRect(GW() / 2 - 50, 48, 100, 26);
  ctx.fillStyle = timeLeft < 15 ? "#e76f51" : "#fff";
  ctx.font = "bold 15px sans-serif";
  ctx.textAlign = "center";
  ctx.fillText(`${Math.ceil(timeLeft)}s`, GW() / 2, 66);
  ctx.textAlign = "left";
}

function drawModeLabel() {
  if (state !== "playing") return;
  const labels = {
    catcher: "⬇ Atrapa esmeraldas",
    channel: "⬆⬇ Cruza el canal",
    lanes: "◀ ▶ Cambia carril",
    rescue: "🕸 Lanzar red",
  };
  const m = LEVELS[currentLevel].mode;
  ctx.fillStyle = "rgba(0,0,0,0.35)";
  ctx.fillRect(GW() / 2 - 75, 72, 150, 22);
  ctx.fillStyle = "#f4e4bc";
  ctx.font = "600 11px sans-serif";
  ctx.textAlign = "center";
  ctx.fillText(labels[m] || "", GW() / 2, 87);
  ctx.textAlign = "left";
}

function drawBriefingOverlay() {
  if (state !== "briefing" || levelStarted) return;
  ctx.fillStyle = "rgba(5, 25, 40, 0.45)";
  ctx.fillRect(0, 0, GW(), GH());
}

function drawGuideAvatar(levelId) {
  const avCanvas = document.createElement("canvas");
  avCanvas.width = 88;
  avCanvas.height = 88;
  const ac = avCanvas.getContext("2d");
  const cx = 44;
  const cy = 44;
  const icons = [drawUminaIcon, drawTohalliIcon, drawNavigatorIcon, drawJocayIcon];
  icons[levelId - 1]?.(ac, cx, cy);
  guide.avatar.style.backgroundImage = `url(${avCanvas.toDataURL()})`;
  guide.avatar.style.backgroundSize = "cover";
}

function drawUminaIcon(c, cx, cy) {
  c.fillStyle = "#2a9d8f";
  c.beginPath();
  c.arc(cx, cy, 20, 0, Math.PI * 2);
  c.fill();
}

function drawTohalliIcon(c, cx, cy) {
  c.fillStyle = "#6c757d";
  c.fillRect(cx - 18, cy, 36, 20);
  c.fillStyle = "#e9c46a";
  c.fillRect(cx - 20, cy - 4, 40, 6);
}

function drawNavigatorIcon(c, cx, cy) {
  c.fillStyle = "#e76f51";
  c.fillRect(cx - 2, cy - 18, 4, 36);
  c.beginPath();
  c.arc(cx, cy - 6, 10, 0, Math.PI * 2);
  c.fillStyle = "#f4e4bc";
  c.fill();
}

function drawJocayIcon(c, cx, cy) {
  c.fillStyle = "#48cae4";
  c.beginPath();
  c.arc(cx, cy, 18, 0, Math.PI * 2);
  c.fill();
}

function render(now) {
  if (!lastFrameTime) lastFrameTime = now;
  let dt = (now - lastFrameTime) / 1000;
  lastFrameTime = now;
  dt = Math.min(dt, 0.05);

  drawOcean(dt);

  if (modeState && currentMode && (state === "playing" || state === "briefing")) {
    currentMode.draw(ctx, modeState);
  }

  for (const p of particles) {
    ctx.globalAlpha = Math.max(0, p.life / 35);
    ctx.fillStyle = p.color;
    ctx.beginPath();
    ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalAlpha = 1;
  }

  if (state === "playing" || state === "briefing") {
    drawBalsa(player.x, player.y, player.w, player.h, player.invincible);
  }

  drawTimer();
  drawModeLabel();
  drawBriefingOverlay();

  if (state === "playing") updatePlaying(dt);

  animationId = requestAnimationFrame(render);
}

function startRenderLoop() {
  if (window.resizeCanvas) window.resizeCanvas();
  lastFrameTime = 0;
  animationId = requestAnimationFrame(render);
}

window.gameModeState = () => modeState;

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", startRenderLoop);
} else {
  startRenderLoop();
}
