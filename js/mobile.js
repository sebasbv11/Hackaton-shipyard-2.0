/**
 * Configuración móvil: canvas responsive y joystick táctil
 */
const Mobile = {
  GAME_WIDTH: 390,
  GAME_HEIGHT: 700,
  touch: { x: 0, y: 0, active: false },
  scale: 1,
  joystickSensitivity: 0.88,
};

window.Mobile = Mobile;

function resizeCanvas() {
  const canvas = document.getElementById("game-canvas");
  const screen = document.getElementById("game-screen");
  if (!canvas || !screen) return;

  const rect = screen.getBoundingClientRect();
  const dpr = Math.min(window.devicePixelRatio || 1, 2);

  canvas.width = Mobile.GAME_WIDTH;
  canvas.height = Mobile.GAME_HEIGHT;

  const scaleX = rect.width / Mobile.GAME_WIDTH;
  const scaleY = rect.height / Mobile.GAME_HEIGHT;
  Mobile.scale = Math.min(scaleX, scaleY);

  canvas.style.width = `${Mobile.GAME_WIDTH * Mobile.scale}px`;
  canvas.style.height = `${Mobile.GAME_HEIGHT * Mobile.scale}px`;
  canvas.style.margin = "0 auto";
}

function initJoystick() {
  const zone = document.getElementById("joystick");
  const knob = document.getElementById("joystick-knob");
  if (!zone || !knob) return;

  const radius = 36;
  let centerX = 0;
  let centerY = 0;
  let pointerId = null;

  function resetKnob() {
    knob.style.transform = "translate(0px, 0px)";
    Mobile.touch.x = 0;
    Mobile.touch.y = 0;
    Mobile.touch.active = false;
    pointerId = null;
  }

  function moveKnob(clientX, clientY) {
    let dx = clientX - centerX;
    let dy = clientY - centerY;
    const dist = Math.hypot(dx, dy);
    if (dist > radius) {
      dx = (dx / dist) * radius;
      dy = (dy / dist) * radius;
    }
    knob.style.transform = `translate(${dx}px, ${dy}px)`;
    Mobile.touch.x = (dx / radius) * Mobile.joystickSensitivity;
    Mobile.touch.y = (dy / radius) * Mobile.joystickSensitivity;
    Mobile.touch.active = dist > 8;
  }

  zone.addEventListener(
    "pointerdown",
    (e) => {
      e.preventDefault();
      const r = zone.getBoundingClientRect();
      centerX = r.left + r.width / 2;
      centerY = r.top + r.height / 2;
      pointerId = e.pointerId;
      zone.setPointerCapture(e.pointerId);
      moveKnob(e.clientX, e.clientY);
    },
    { passive: false }
  );

  zone.addEventListener(
    "pointermove",
    (e) => {
      if (pointerId !== e.pointerId) return;
      e.preventDefault();
      moveKnob(e.clientX, e.clientY);
    },
    { passive: false }
  );

  function endPointer(e) {
    if (pointerId !== null && e.pointerId !== pointerId) return;
    resetKnob();
  }

  zone.addEventListener("pointerup", endPointer);
  zone.addEventListener("pointercancel", endPointer);
  zone.addEventListener("lostpointercapture", resetKnob);
}

function setTouchControlsVisible(visible) {
  const el = document.getElementById("touch-controls");
  if (el) el.hidden = !visible;
}

function setGuideModalVisible(visible) {
  const el = document.getElementById("guide-modal");
  if (el) el.classList.toggle("hidden", !visible);
}

window.setTouchControlsVisible = setTouchControlsVisible;
window.setGuideModalVisible = setGuideModalVisible;
window.resizeCanvas = resizeCanvas;

const HINTS = {
  joystick: "Arrastra el joystick",
  catcher: "Solo izquierda / derecha",
  channel: "Sube y baja por el canal",
  lanes: "◀ ▶ para cambiar carril",
  rescue: "Acércate y lanza la red",
};

function setControlMode(mode) {
  const lanes = document.getElementById("control-lanes");
  const net = document.getElementById("btn-net");
  const joyWrap = document.getElementById("joystick-wrap");
  const hint = document.getElementById("touch-hint");

  if (lanes) lanes.hidden = mode !== "lanes";
  if (net) net.hidden = mode !== "rescue";
  if (joyWrap) joyWrap.hidden = mode === "lanes";

  if (hint) hint.textContent = HINTS[mode] || HINTS.joystick;
}

window.setControlMode = setControlMode;

function initExtraButtons() {
  const left = document.getElementById("btn-lane-left");
  const right = document.getElementById("btn-lane-right");
  const net = document.getElementById("btn-net");

  const tap = (fn) => (e) => {
    e.preventDefault();
    fn();
  };

  if (left) {
    left.addEventListener("pointerdown", tap(() => {
      const s = window.gameModeState?.();
      if (s) s.laneTapLeft = true;
    }));
  }
  if (right) {
    right.addEventListener("pointerdown", tap(() => {
      const s = window.gameModeState?.();
      if (s) s.laneTapRight = true;
    }));
  }
  if (net) {
    net.addEventListener("pointerdown", tap(() => {
      const s = window.gameModeState?.();
      if (s) s.netTap = true;
    }));
  }
}

document.addEventListener("DOMContentLoaded", () => {
  resizeCanvas();
  initJoystick();
  initExtraButtons();
  window.addEventListener("resize", resizeCanvas);
  window.addEventListener("orientationchange", () => setTimeout(resizeCanvas, 150));

  document.body.addEventListener(
    "touchmove",
    (e) => {
      if (e.target.closest("#guide-modal .guide-speech")) return;
      e.preventDefault();
    },
    { passive: false }
  );
});
