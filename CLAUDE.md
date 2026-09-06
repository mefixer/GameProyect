# CLAUDE.md — Soulslike 3D (Godot 4.7)

Juego 3D soulslike, GDScript, Godot 4.7.2 nativo (`/usr/bin/godot`).

## Comandos (verificados)

```bash
godot --headless --check-only --script scripts/player/player.gd   # valida 1 script, ~2 s
timeout 180 godot --headless --import                             # reimporta assets
timeout 30 godot --headless scenes/levels/bosque.tscn 2>&1 | grep -vE '^Godot Engine|^$'
timeout 500 godot --headless --export-debug "Linux" build/soulslike3d.x86_64
```

**Después de tocar cualquier `.gd`: `--check-only` sobre ese archivo.** Es el
bucle de validación. No arranques el juego para verificar sintaxis ni tipos.

## Mapa (ir directo, no buscar)

```
scripts/autoload/    AudioManager Fx GameFeel GameState Settings UiState OllamaClient
scripts/components/  health_component  stamina_component  hitbox  hurtbox
scripts/player/      player.gd (FSM+combate)  camera_rig.gd (lock-on)
scripts/enemies/     enemy_base.gd → ranged_enemy, spinner_arm, training_dummy
scripts/bosses/      Cherufe
scripts/ui/  scripts/world/  scripts/levels/  scripts/wildlife/
scenes/<misma división>/   *.tscn
docs/arquitectura.md       la fuente de verdad del diseño (28 KB — no leer entero)
```

## Reglas de arquitectura

- **Composición sobre herencia**: vida, estamina y colisiones son nodos
  (`HealthComponent`, `StaminaComponent`, `Hitbox`, `Hurtbox`), no código copiado.
- **Comunicación por señales y grupos**, no por rutas de nodo. Grupos: `player`,
  `enemies`, `lock_target`. Señales: `health_changed`, `died`, `stamina_changed`,
  `hit_received(hitbox)`, `hit_landed(hurtbox)`.
- **Capas de física**: 1 mundo · 2 jugador · 3 enemigos · 4 combate.
  Hurtbox vive en layer 8, Hitbox solo escanea (layer 0, mask 8).
- **Ataques = datos**, no ramas: diccionario `ATTACKS` en `player.gd` con
  `windup / active / recovery / damage / stamina`. Un ataque nuevo es una entrada.
- Toda constante de gameplay va en `const` o `@export`, nunca incrustada.

## Convenciones GDScript

- Tabs. `class_name` + `extends` arriba, luego `##` describiendo el archivo.
- **Tipado estático siempre**: `var x := 0.0`, `func f(a: float) -> void:`.
  Sin tipos, `--check-only` no detecta casi nada.
- Orden: `class_name`/`extends` → `signal` → `enum` → `const` → `@export` →
  `var` → `@onready` → `_ready` → `_process`/`_physics_process` → públicas → `_privadas`.
- Nombres en español para el dominio (`rewe`, `lawen`, `weichafe`, `newen`);
  API de Godot en inglés.

## Coste — específico de este repo

- **Pesos reales**: `.godot/` 591 MB, `assets/` 297 MB, `build/` 233 MB. Nunca leerlos.
- **`docs/arquitectura.md` por secciones**: `grep -n '^##' docs/arquitectura.md`
  y después `sed -n 'A,Bp'`. Leerlo entero cuesta ~8k tokens.
- **`.tscn` por grep, no `cat`**: `grep -n '^\[node' scenes/levels/bosque.tscn`
  da el árbol; el archivo entero son 29 KB.
- Validar con `--check-only` (2 s, 3 líneas) antes que arrancar escenas.
  El hook `PostToolUse` ya lo corre solo al editar un `.gd`.

## Seguridad — `ollama_client.gd`

Llama a `http://127.0.0.1:11434` (Ollama local, sin auth por diseño). Si
algún día se apunta a un servidor remoto, esa URL necesitaría autenticación —
no hardcodear una API key en el `.gd` si eso pasa; usar variable de entorno
leída en runtime.

## Antes de dar algo por hecho

1. `--check-only` sobre cada `.gd` tocado.
2. Si cambió una escena o un recurso: `godot --headless --import`.
3. Si cambió gameplay: decir explícitamente qué falta probar a mano en F5.
   No afirmar que "funciona" sin haberlo corrido.
