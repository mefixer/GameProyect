---
name: revisar-ux-hud
description: Revisar legibilidad y feedback del HUD/menús (vida, estamina, indicadores de jefe) sin depender solo del color. Usar tras tocar scripts/ui, scenes/ui o agregar un indicador de estado nuevo.
---

# UX del HUD y menús

`scripts/ui/` y `scenes/ui/` — `debug_hud`, `boss_health_bar`, `main_menu`,
`pause_menu`, `options_menu`, `inventory_menu`, `touch_controls`.

## 1. Indicadores que dependen del color

```bash
grep -n 'modulate\|self_modulate\|Color(' scripts/ui/*.gd
```

Vida/estamina/estado crítico que solo cambian de color (verde→rojo) son
invisibles para quien no distingue esos colores. Confirmar que también hay
un cambio de forma, tamaño, texto o parpadeo — no solo tono.

## 2. Escena del HUD/menú tocado

```bash
grep -n '^\[node' scenes/ui/<escena>.tscn | sed 's/ index=[0-9]*//'
```

- Texto legible: fuente y tamaño consistentes con el resto del HUD (no un
  tamaño nuevo por escena).
- Botones de menú: confirmar que `touch_controls.gd` sigue cubriendo
  cualquier acción nueva si el juego soporta táctil.

## 3. Feedback de combate

`boss_health_bar.gd` y el HUD de vida/estamina del jugador deben reaccionar
a las señales ya establecidas (`health_changed`, `stamina_changed`,
`hit_received`/`hit_landed`) — un indicador nuevo debe conectarse a esas
señales, no leer el valor por polling.

## Qué no se puede verificar sin ventana

Legibilidad real a la distancia de juego, timing del parpadeo/feedback, y
consistencia visual con el resto de la UI requieren F5. Decir explícitamente
si no se probó así.
