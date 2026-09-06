---
name: revisar-balance
description: Comparar los valores de ataque (windup/active/recovery/damage/stamina) entre el jugador y los enemigos/jefes para detectar inconsistencias de balance. Usar tras agregar o ajustar un ataque, enemigo o jefe.
---

# Balance de combate — comparar, no adivinar

Los datos de ataque viven en dos formas, según CLAUDE.md: el diccionario
`ATTACKS` en `player.gd` para el jugador, y campos `@export attack_*` /
`<nombre>_*` (windup/active/recovery/damage) por enemigo o jefe. Compararlos
requiere juntarlos, no mirar un archivo a la vez.

## 1. Reunir los valores

```bash
grep -n -A6 'const ATTACKS' scripts/player/player.gd
grep -nE '@export var (attack|slam|throw|.*_)?(damage|windup|active|recovery|stamina)' \
  scripts/enemies/*.gd scripts/bosses/*.gd
```

## 2. Qué comparar

- **`windup` vs `active`**: un `windup` mucho más largo que el `active` da
  tiempo de sobra para esquivar/lock-on — compararlo contra ataques
  similares ya existentes, no en abstracto.
- **`damage` vs `windup+active+recovery` (tiempo total)**: un ataque con
  mucho daño y poco tiempo total rompe el ritmo riesgo/recompensa que ya
  tienen los demás.
- **`recovery`**: si es menor que en ataques comparables, ese enemigo/jefe
  queda con ventana de punición más corta que el resto — confirmar que es a
  propósito (ej. jefe final) y no un descuido.
- Para jefes: comparar sus propios ataques entre sí (`slam_*` vs `throw_*` en
  `boss_cherufe.gd`) además de contra enemigos comunes.

## 3. Informar

No hay forma de "jugarlo" sin abrir el editor — esto es análisis de datos,
no verificación de feel. Reportar los valores comparados en una tabla corta
y señalar cuáles se alejan del resto, dejando explícito que el ritmo real
(cómo se siente) solo se confirma jugando (F5).
