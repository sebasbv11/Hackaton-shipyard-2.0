/**
 * Móvil landscape: canvas responsive, joystick y detección de orientación
 */
const Mobile = {
  GAME_WIDTH: 800,
  GAME_HEIGHT: 360,
  touch: { x: 0, y: 0, active: false },
  scale: 1,
  joystickSensitivity: 0.88,
};

window.Mobile = Mobile;

function isCoarsePointer() {
  return window.matchMedia("(hover: none) and (pointer: coarse)").matches;
}

function isPortraitMode() {
  if (window.screen?.orientation?.type) {
    return window.screen.orientation.type.startsWith("portrait");
  }
  return window.matchMedia("(orientation: portrait)").matches;
}

function shouldShowRotateOverlay() {
  return isCoarsePointer() && isPortraitMode();
}

function updateOrientationUI() {
  const overlay = document.getElementById("rotate-overlay");
  const blocked = shouldShowRotateOverlay();
  document.body.classList.toggle("portrait-blocked", blocked);
  if (overlay) overlay.hidden = !blocked;
  if (!blocked) resizeCanvas();
}

function resizeCanvas() {
  const canvas = document.getElementById("game-canvas");
  const viewport = document.getElementById("game-viewport");
  if (!canvas || !viewport || shouldShowRotateOverlay()) return;

  const rect = viewport.getBoundingClientRect();
  if (rect.width < 8 || rect.height < 8) return;

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

  const radius = 34;
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
  const screen = document.getElementById("game-screen");
  if (el) el.hidden = !visible;
  if (screen) screen.classList.toggle("controls-active", visible);
}

function setGuideModalVisible(visible) {
  const el = document.getElementById("guide-modal");
  if (el) el.classList.toggle("hidden", !visible);
}

window.setTouchControlsVisible = setTouchControlsVisible;
window.setGuideModalVisible = setGuideModalVisible;
window.resizeCanvas = resizeCanvas;
window.updateOrientationUI = updateOrientationUI;

const HINTS = {
  joystick: "Joystick: mueve la balsa",
  catcher: "Solo ◀ ▶",
  channel: "Sube y baja",
  lanes: "Botones ◀ ▶",
  rescue: "Acércate y lanza red",
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
    left.addEventListener(
      "pointerdown",
      tap(() => {
        const s = window.gameModeState?.();
        if (s) s.laneTapLeft = true;
      })
    );
  }
  if (right) {
    right.addEventListener(
      "pointerdown",
      tap(() => {
        const s = window.gameModeState?.();
        if (s) s.laneTapRight = true;
      })
    );
  }
  if (net) {
    net.addEventListener(
      "pointerdown",
      tap(() => {
        const s = window.gameModeState?.();
        if (s) s.netTap = true;
      })
    );
  }
}

function bindOrientationListeners() {
  window.addEventListener("resize", () => {
    updateOrientationUI();
    resizeCanvas();
  });
  window.addEventListener("orientationchange", () => {
    setTimeout(() => {
      updateOrientationUI();
      resizeCanvas();
    }, 120);
  });
  if (window.screen?.orientation?.addEventListener) {
    window.screen.orientation.addEventListener("change", () => {
      updateOrientationUI();
      resizeCanvas();
    });
  }
  window.matchMedia("(orientation: portrait)").addEventListener("change", () => {
    updateOrientationUI();
    resizeCanvas();
  });
}

document.addEventListener("DOMContentLoaded", () => {
  updateOrientationUI();
  resizeCanvas();
  initJoystick();
  initExtraButtons();
  bindOrientationListeners();

  document.body.addEventListener(
    "touchmove",
    (e) => {
      if (e.target.closest("#guide-modal .guide-speech")) return;
      e.preventDefault();
    },
    { passive: false }
  );
});

if (document.visibilityState !== undefined) {
  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "visible") {
      updateOrientationUI();
      resizeCanvas();
    }
  });
}
