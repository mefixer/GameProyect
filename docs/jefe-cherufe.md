# Jefe 1 — El Cherufe

Diseño del primer jefe (Fase 6). Escena: `scenes/bosses/boss_cherufe.tscn`.
Guion: [[GDD - Documento de Diseño]] — ser de roca y magma que habita los volcanes,
exigía sacrificios humanos en el mito original.

## Máquina de estados

```mermaid
stateDiagram-v2
    [*] --> DORMANT
    DORMANT --> AWAKEN : jugador cruza la niebla<br/>(boss_trigger.gd)
    AWAKEN --> CHASE : 0.9s (rugido, se activa la hurtbox)
    CHASE --> ATTACK : en melee_range<br/>y cooldown listo
    ATTACK --> CHASE : fin de recovery<br/>(inicia cooldown)
    CHASE --> HIT : recibe daño
    ATTACK --> HIT : recibe daño
    HIT --> CHASE : fin aturdimiento (0.3s)
    CHASE --> DEAD : vida 0
    ATTACK --> DEAD : vida 0
    DEAD --> [*] : GameState.defeat_boss("cherufe")
```

- **DORMANT**: invisible a efectos de combate (hurtbox `monitorable = false`);
  espera a que el disparador de niebla llame a `awaken(player)`.
- **Sin estado RETURN**: a diferencia de los enemigos comunes, el Cherufe no
  tiene "casa" — una vez despierto, persigue hasta morir. La arena está
  amurallada, así que no hay a dónde huir.
- **Transición de fase** (dentro de `_on_hit_received`): al primer golpe que
  deja la vida ≤ 50%, pasa a Fase 2 de forma permanente (no puede revertir).

## Ataques

| Ataque | Fase | Alcance | Windup | Activo | Recovery | Daño | Notas |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Golpe de roca** (slam) | 1 y 2 | cuerpo a cuerpo (≤3.2 m) | 0.9 s | 0.35 s | 0.8 s | 34 | Embiste hacia delante al golpear |
| **Lanzamiento de roca** (throw) | 1 y 2 | distancia | 0.8 s | — | 0.7 s | 20 | Reutiliza `projectile.tscn` a ×2.2 de escala |
| **Erupción** (AoE) | **solo Fase 2** | bajo el jugador | 1.2 s (telegrafiado) | instantáneo | — | 28 | Anillo de aviso naranja que crece; detona donde estaba el jugador al invocarse — esquivable moviéndose |

- **Selección de ataque**: si la distancia al jugador es ≤ `melee_range` → slam;
  si no → throw. En Fase 2, cada `eruption_every` (3) ataques normales se
  intercala una erupción en su lugar, obligando a no quedarse quieto.
- **Fase 2** también sube la velocidad de persecución (×1.35) y reduce el
  cooldown entre ataques (×0.7) — el jefe se siente genuinamente más peligroso,
  no solo con más vida.

## Arena y flujo de entrada

- La **niebla** (`FogGate`, ahora un `Area3D` con `boss_trigger.gd`) ya no
  bloquea el paso: al cruzarla, despierta al jefe, conecta la barra de vida
  y se desvanece para siempre (no vuelve a activarse en esa partida).
- Suelo con grietas de lava emisivas como primer pase de arte de la arena.
- **Sin sello de niebla** (a diferencia de otros souls): el jugador puede
  retirarse de la pelea si lo necesita. Se documenta como simplificación
  consciente de este vertical slice; un sello real (con `gate.gd`) es
  candidato de pulido en la Fase 9.

## Recompensa y persistencia

- Al morir: **300 de newen** y `GameState.defeat_boss("cherufe")` — el jefe
  no vuelve a aparecer nunca más en esa partida (ni siquiera al descansar en
  el rewe, que recarga la escena y respawnea al resto de enemigos).
- La niebla, si el jefe ya está vencido, aparece desvanecida desde el `_ready()`
  del propio disparador — no hace falta re-cruzar la arena para notarlo.

## UI

- `scenes/ui/boss_health_bar.tscn`: oculta hasta que `track(boss, nombre)` es
  llamado por el disparador; muestra nombre, barra roja y una etiqueta de
  fase que aparece solo al entrar en Fase 2. Se desvanece 1s después de la muerte.

## Pendiente / fuera de alcance de la demo

- [ ] Playtest de dificultad y ritmo del combate
- [ ] Modelo 3D propio del Cherufe (hoy es geometría primitiva con grietas emisivas)
- [ ] Sello real de niebla (impedir retirada)
- [ ] Música de jefe (Fase 8)
- [ ] Cinemática de entrada / cámara dedicada
