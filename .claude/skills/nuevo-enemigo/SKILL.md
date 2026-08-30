---
name: nuevo-enemigo
description: Crear un enemigo nuevo en este proyecto siguiendo las convenciones existentes (enemy_base, componentes de vida/estamina, hitbox/hurtbox, capas de física, grupos). Usar cuando pidan agregar un enemigo, variante o jefe.
---

# Enemigo nuevo

## Antes de escribir nada

```bash
sed -n '1,60p' scripts/enemies/enemy_base.gd
sed -n '1,40p' scripts/enemies/ranged_enemy.gd   # el ejemplo de variante más limpio
grep -n '^\[node' scenes/enemies/enemy.tscn
```

Con eso alcanza. No hace falta leer todos los enemigos ni `docs/arquitectura.md`
entero; si se necesita el diseño de IA: `grep -n '^##' docs/arquitectura.md` y
leer solo la sección "IA de enemigos" con `sed -n`.

## Reglas que no se negocian

- `extends EnemyBase`, nunca copiar su lógica. Lo que varía se expone con
  `@export` (velocidad, alcance, daño, cooldowns), no se incrusta.
- Vida y estamina son nodos `HealthComponent` / `StaminaComponent` hijos, no
  variables sueltas.
- Golpea con `Hitbox` (layer 0, mask 8), recibe con `Hurtbox` (layer 8).
  Cuerpo del enemigo: layer 4.
- Grupos: `enemies` (fuego amigo) y `lock_target` (fijable). Salir de
  `lock_target` al morir.
- Conectar `died` para la animación/limpieza; no consultar vida desde fuera.
- Ataques como datos: diccionario con `windup / active / recovery / damage`,
  igual que `ATTACKS` en `player.gd`.

## Cerrar

1. `godot --headless --check-only --script scripts/enemies/<nuevo>.gd`
2. `godot --headless --import` si se creó la escena.
3. Anotar en `docs/arquitectura.md`, sección "Variantes actuales", una línea.
