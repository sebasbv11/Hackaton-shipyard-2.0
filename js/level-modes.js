/**
 * Cuatro minijuegos distintos — optimizados para canvas horizontal (800×360)
 */
const GW = () => window.Mobile?.GAME_WIDTH ?? 800;
const GH = () => window.Mobile?.GAME_HEIGHT ?? 360;
const GAME_PACE = 0.82;
const TARGET_FPS = 60;

function spawnSplash(x, y, color) {
  window.spawnSplash?.(x, y, color);
}

function rectOverlap(a, b) {
  return window.rectOverlap?.(a, b) ?? false;
}

function circleRectOverlap(cx, cy, r, rect) {
  return window.circleRectOverlap?.(cx, cy, r, rect) ?? false;
}

const LevelModes = {
  catcher: {
    init(state) {
      state.falling = [];
      state.spawnCd = 0;
      state.playerY = GH() - 72;
      state.player.x = GW() / 2 - state.player.w / 2;
      state.player.y = state.playerY;
      state.laneOnlyX = true;
    },
    update(state, dt, lvl) {
      const step = dt * TARGET_FPS * GAME_PACE;
      state.spawnCd -= dt;
      if (state.spawnCd <= 0) {
        state.spawnCd = 0.55 + Math.random() * 0.45;
        const isBad = Math.random() < 0.32;
        state.falling.push({
          x: 40 + Math.random() * (GW() - 80),
          y: -20,
          vy: (1.4 + Math.random() * 0.9) * GAME_PACE,
          r: isBad ? 22 : 14,
          type: isBad ? "storm" : "esmeralda",
        });
      }
      for (let i = state.falling.length - 1; i >= 0; i--) {
        const f = state.falling[i];
        f.y += f.vy * step;
        const pr = { x: state.player.x, y: state.player.y, w: state.player.w, h: state.player.h };
        if (circleRectOverlap(f.x, f.y, f.r, pr)) {
          if (f.type === "esmeralda") {
            state.collected++;
            state.addScore(50);
            spawnSplash(f.x, f.y, "#2a9d8f");
            if (state.collected >= lvl.target) state.onWin();
          } else {
            state.onHit();
          }
          state.falling.splice(i, 1);
        } else if (f.y > GH() + 30) {
          state.falling.splice(i, 1);
        }
      }
      state.player.y = state.playerY;
    },
    draw(ctx, state) {
      for (const f of state.falling) {
        if (f.type === "esmeralda") drawEmerald(ctx, f.x, f.y);
        else drawStorm(ctx, f.x - 20, f.y - 15, 52, 38);
      }
      ctx.fillStyle = "rgba(42,157,143,0.2)";
      ctx.fillRect(0, state.playerY - 8, GW(), 4);
    },
    handleInput(state, dt, dx, dy) {
      const move = state.player.speed * GAME_PACE * dt * TARGET_FPS;
      state.player.x += dx * move;
      state.player.x = Math.max(12, Math.min(GW() - state.player.w - 12, state.player.x));
    },
    hudGoal: (lvl) => `Atrapa ${lvl.target} esmeraldas`,
  },

  channel: {
    init(state) {
      state.walls = [];
      state.distance = 0;
      state.goalDistance = 1200;
      state.wallCd = 0;
      state.player.x = 55;
      state.player.y = GH() / 2 - state.player.h / 2;
      state.laneOnlyX = false;
    },
    update(state, dt, lvl) {
      const step = dt * TARGET_FPS * GAME_PACE;
      state.wallCd -= dt;
      if (state.wallCd <= 0) {
        state.wallCd = 1.1;
        const gapH = 88 + Math.random() * 36;
        const gapY = 48 + Math.random() * (GH() - gapH - 96);
        state.walls.push({
          x: GW() + 20,
          gapY,
          gapH,
          w: 36,
          passed: false,
        });
      }
      for (let i = state.walls.length - 1; i >= 0; i--) {
        const w = state.walls[i];
        w.x -= 2.2 * step;
        const top = { x: w.x, y: 0, w: w.w, h: w.gapY };
        const bot = { x: w.x, y: w.gapY + w.gapH, w: w.w, h: GH() - w.gapY - w.gapH };
        const pr = state.player;
        if (rectOverlap(pr, top) || rectOverlap(pr, bot)) state.onHit();
        if (!w.passed && w.x + w.w < state.player.x) {
          w.passed = true;
          state.distance += 120;
          state.addScore(25);
        }
        if (w.x < -60) state.walls.splice(i, 1);
      }
      state.distance += 0.8 * step;
      if (state.distance >= state.goalDistance) state.onWin();
    },
    draw(ctx, state) {
      for (const w of state.walls) {
        ctx.fillStyle = "#5c6b73";
        ctx.fillRect(w.x, 0, w.w, w.gapY);
        ctx.fillRect(w.x, w.gapY + w.gapH, w.w, GH() - w.gapY - w.gapH);
        ctx.fillStyle = "rgba(255,255,255,0.12)";
        ctx.fillRect(w.x + 6, 0, 8, w.gapY);
      }
      const prog = state.distance / state.goalDistance;
      const barY = GH() - 18;
      ctx.fillStyle = "rgba(0,0,0,0.35)";
      ctx.fillRect(12, barY, GW() - 24, 8);
      ctx.fillStyle = "#e9c46a";
      ctx.fillRect(12, barY, (GW() - 24) * Math.min(1, prog), 8);
      ctx.fillStyle = "#fff";
      ctx.font = "bold 10px sans-serif";
      ctx.fillText("Puerto de Manta", GW() - 98, barY - 6);
      drawPortIcon(ctx, GW() - 38, barY - 28);
    },
    handleInput(state, dt, dx, dy) {
      const move = state.player.speed * GAME_PACE * dt * TARGET_FPS;
      state.player.x += dx * move;
      state.player.y += dy * move;
      state.player.x = Math.max(20, Math.min(GW() - state.player.w - 20, state.player.x));
      state.player.y = Math.max(36, Math.min(GH() - state.player.h - 36, state.player.y));
    },
    hudGoal: () => "Cruza los canales al puerto",
    progress: (state) => (state.distance / state.goalDistance) * 100,
  },

  lanes: {
    init(state) {
      state.lane = 1;
      state.laneCount = 3;
      state.laneW = GW() / 3;
      state.items = [];
      state.itemCd = 0;
      state.playerY = GH() - 76;
      state.player.w = 48;
      state.player.h = 36;
      state.laneOnlyX = false;
      state.setControlMode?.("lanes");
    },
    update(state, dt, lvl) {
      const step = dt * TARGET_FPS * GAME_PACE;
      const lx = state.lane * state.laneW + state.laneW / 2;
      state.player.x = lx - state.player.w / 2;
      state.player.y = state.playerY;

      state.itemCd -= dt;
      if (state.itemCd <= 0) {
        state.itemCd = 0.7 + Math.random() * 0.5;
        const lane = Math.floor(Math.random() * 3);
        const isPirate = Math.random() < 0.38;
        state.items.push({
          lane,
          y: -40,
          vy: (1.6 + Math.random() * 0.6) * GAME_PACE,
          type: isPirate ? "pirate" : "concha",
        });
      }
      for (let i = state.items.length - 1; i >= 0; i--) {
        const it = state.items[i];
        it.y += it.vy * step;
        if (it.lane === state.lane && it.y + 20 >= state.playerY && it.y <= state.playerY + state.player.h) {
          if (it.type === "concha") {
            state.collected++;
            state.addScore(100);
            spawnSplash(state.player.x + 24, state.player.y, "#e76f51");
            if (state.collected >= lvl.target) state.onWin();
          } else {
            state.onHit();
          }
          state.items.splice(i, 1);
        } else if (it.y > GH() + 30) {
          state.items.splice(i, 1);
        }
      }
    },
    draw(ctx, state) {
      for (let i = 0; i < 3; i++) {
        ctx.strokeStyle = i === state.lane ? "rgba(244,162,97,0.5)" : "rgba(255,255,255,0.08)";
        ctx.lineWidth = i === state.lane ? 3 : 1;
        ctx.strokeRect(i * state.laneW + 4, 28, state.laneW - 8, GH() - 100);
      }
      for (const it of state.items) {
        const cx = it.lane * state.laneW + state.laneW / 2;
        if (it.type === "concha") drawConcha(ctx, cx, it.y);
        else drawPirateSmall(ctx, cx - 22, it.y, 44, 40);
      }
    },
    handleInput(state, dt, dx, dy) {
      if (state.laneTapLeft) {
        state.lane = Math.max(0, state.lane - 1);
        state.laneTapLeft = false;
      }
      if (state.laneTapRight) {
        state.lane = Math.min(2, state.lane + 1);
        state.laneTapRight = false;
      }
      if (dx < -0.45 && !state._laneLock) {
        state.lane = Math.max(0, state.lane - 1);
        state._laneLock = true;
      } else if (dx > 0.45 && !state._laneLock) {
        state.lane = Math.min(2, state.lane + 1);
        state._laneLock = true;
      } else if (Math.abs(dx) < 0.3) {
        state._laneLock = false;
      }
    },
    onEnd(state) {
      state.setControlMode?.("joystick");
    },
    hudGoal: (lvl) => `${lvl.target} conchas · cambia carril`,
  },

  rescue: {
    init(state) {
      state.swimmers = [];
      state.spawnCd = 0;
      state.netActive = 0;
      state.netRadius = 72;
      state.laneOnlyX = false;
      state.setControlMode?.("rescue");
    },
    update(state, dt, lvl) {
      const step = dt * TARGET_FPS * GAME_PACE;
      if (state.netActive > 0) state.netActive -= dt;

      state.spawnCd -= dt;
      if (state.spawnCd <= 0) {
        state.spawnCd = 0.65 + Math.random() * 0.4;
        const fromLeft = Math.random() < 0.5;
        state.swimmers.push({
          x: fromLeft ? -30 : GW() + 30,
          y: 48 + Math.random() * (GH() - 140),
          vx: (fromLeft ? 1 : -1) * (1.1 + Math.random() * 0.7) * GAME_PACE,
          type: Math.random() < 0.55 ? "pez" : "trash",
        });
      }

      const netX = state.player.x + state.player.w / 2;
      const netY = state.player.y + state.player.h / 2;
      const netOn = state.netActive > 0;

      for (let i = state.swimmers.length - 1; i >= 0; i--) {
        const s = state.swimmers[i];
        s.x += s.vx * step;
        if (netOn) {
          const d = Math.hypot(s.x - netX, s.y - netY);
          if (d < state.netRadius) {
            if (s.type === "pez") {
              state.collected++;
              state.addScore(60);
              spawnSplash(s.x, s.y, "#48cae4");
              if (state.collected >= lvl.target) state.onWin();
            } else {
              state.onHit();
            }
            state.swimmers.splice(i, 1);
            continue;
          }
        }
        if (s.x < -50 || s.x > GW() + 50) state.swimmers.splice(i, 1);
        else if (!netOn && circleRectOverlap(s.x, s.y, 16, state.player)) {
          if (s.type === "trash") state.onHit();
          state.swimmers.splice(i, 1);
        }
      }
    },
    draw(ctx, state) {
      for (const s of state.swimmers) {
        if (s.type === "pez") drawFish(ctx, s.x, s.y);
        else drawTrash(ctx, s.x - 14, s.y - 14, 28, 28);
      }
      if (state.netActive > 0) {
        const cx = state.player.x + state.player.w / 2;
        const cy = state.player.y + state.player.h / 2;
        ctx.strokeStyle = "rgba(72, 202, 228, 0.75)";
        ctx.lineWidth = 3;
        ctx.beginPath();
        ctx.arc(cx, cy, state.netRadius * (state.netActive / 0.55), 0, Math.PI * 2);
        ctx.stroke();
        ctx.fillStyle = "rgba(72, 202, 228, 0.12)";
        ctx.fill();
      }
    },
    handleInput(state, dt, dx, dy) {
      const move = state.player.speed * GAME_PACE * dt * TARGET_FPS;
      state.player.x += dx * move;
      state.player.y += dy * move;
      state.player.x = Math.max(12, Math.min(GW() - state.player.w - 12, state.player.x));
      state.player.y = Math.max(40, Math.min(GH() - state.player.h - 70, state.player.y));
      if (state.netTap && state.netActive <= 0) {
        state.netActive = 0.55;
        state.netTap = false;
      }
    },
    onEnd(state) {
      state.setControlMode?.("joystick");
    },
    hudGoal: (lvl) => `Red: rescata ${lvl.target} peces`,
  },
};

function drawEmerald(ctx, x, y) {
  ctx.fillStyle = "#2a9d8f";
  ctx.beginPath();
  ctx.moveTo(x, y - 12);
  ctx.lineTo(x + 10, y);
  ctx.lineTo(x, y + 12);
  ctx.lineTo(x - 10, y);
  ctx.closePath();
  ctx.fill();
}

function drawStorm(ctx, x, y, w, h) {
  ctx.fillStyle = "rgba(60,60,80,0.85)";
  ctx.beginPath();
  ctx.arc(x + 20, y + 15, 18, 0, Math.PI * 2);
  ctx.arc(x + 38, y + 12, 14, 0, Math.PI * 2);
  ctx.fill();
  ctx.strokeStyle = "#ffd60a";
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.moveTo(x + 28, y + 32);
  ctx.lineTo(x + 22, y + 48);
  ctx.lineTo(x + 34, y + 40);
  ctx.stroke();
}

function drawConcha(ctx, x, y) {
  ctx.fillStyle = "#e76f51";
  ctx.beginPath();
  ctx.ellipse(x, y, 14, 10, 0, 0.2, Math.PI - 0.2);
  ctx.fill();
}

function drawPirateSmall(ctx, x, y, w, h) {
  ctx.fillStyle = "#212529";
  ctx.fillRect(x, y + 12, w, h - 12);
  ctx.fillStyle = "#000";
  ctx.beginPath();
  ctx.arc(x + w / 2, y + 8, 10, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = "#e63946";
  ctx.fillRect(x + 4, y, w - 8, 5);
}

function drawFish(ctx, x, y) {
  ctx.fillStyle = "#48cae4";
  ctx.beginPath();
  ctx.ellipse(x, y, 16, 8, 0, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = "#023e8a";
  ctx.beginPath();
  ctx.moveTo(x - 18, y);
  ctx.lineTo(x - 28, y - 8);
  ctx.lineTo(x - 28, y + 8);
  ctx.closePath();
  ctx.fill();
}

function drawTrash(ctx, x, y, w, h) {
  ctx.fillStyle = "#495057";
  ctx.fillRect(x, y, w, h * 0.7);
  ctx.fillStyle = "#dc3545";
  ctx.font = "12px sans-serif";
  ctx.fillText("✕", x + 8, y + 16);
}

function drawPortIcon(ctx, x, y) {
  ctx.fillStyle = "#f4a261";
  ctx.fillRect(x, y, 28, 34);
  ctx.fillStyle = "#264653";
  ctx.fillRect(x + 5, y + 10, 5, 20);
  ctx.fillRect(x + 16, y + 10, 5, 20);
}
