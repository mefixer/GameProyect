---
name: validar
description: Valida los cambios de GDScript de este proyecto Godot sin arrancar el juego — check-only por archivo, reimport si tocaste escenas o assets, y arranque headless de una escena solo si hace falta. Usar tras editar cualquier .gd o .tscn, y antes de decir que algo funciona.
---

# Validar cambios (Godot 4.7)

Bucle barato → caro. Parar en el primer nivel que baste.

## 1. Sintaxis y tipos — siempre, ~2 s por archivo

```bash
for f in $(git diff --name-only; git diff --cached --name-only); do
  case "$f" in *.gd)
    echo "--- $f"
    timeout 60 godot --headless --check-only --script "$f" 2>&1 | grep -E 'SCRIPT ERROR|Parse Error|at:' ;;
  esac
done
```

Salida vacía = pasa. Un `Parse Error` trae archivo y línea: corregir y repetir
solo ese archivo, sin releer el resto.

Solo detecta lo que el tipado permite detectar. Si el archivo tocado tiene
`var x =` sin tipo, tiparlo es parte del arreglo.

## 2. Recursos — solo si cambió un `.tscn`, `.tres` o algo en `assets/`

```bash
timeout 180 godot --headless --import 2>&1 | grep -E 'ERROR|WARNING' | head -20
```

## 3. Arranque real — solo si cambió lógica de escena o autoloads

```bash
timeout 30 godot --headless scenes/levels/bosque.tscn 2>&1 \
  | grep -vE '^Godot Engine|^$' | head -30
```

Sale por timeout: es lo esperado, el juego no termina solo. Lo que importa son
los `ERROR`/`SCRIPT ERROR` de los primeros segundos.

## 4. Informar

- Qué pasó y qué no, con la salida real. Nada de "debería funcionar".
- Lo que no se puede verificar sin ventana (feel del combate, cámara,
  animaciones, audio) se lista explícito como "probar a mano con F5".
