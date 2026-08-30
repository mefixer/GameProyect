---
name: inspeccionar-escena
description: Leer la estructura de una escena .tscn de Godot (árbol de nodos, scripts, señales, recursos) sin volcar el archivo entero al contexto. Usar siempre antes de editar una escena o de razonar sobre su jerarquía.
---

# Inspeccionar una escena sin quemar contexto

Un `.tscn` es texto plano lleno de transformadas y UIDs que no aportan nada.
`bosque.tscn` son 29 KB; su árbol de nodos, 30 líneas.

## Árbol de nodos

```bash
grep -n '^\[node' "$ESCENA" | sed 's/ index=[0-9]*//'
```

## Qué scripts y recursos usa

```bash
grep -nE '^\[ext_resource|^script = ' "$ESCENA"
```

## Señales conectadas

```bash
grep -n '^\[connection' "$ESCENA"
```

## Propiedades de UN nodo concreto

```bash
awk '/^\[node name="Hitbox"/,/^$/' "$ESCENA"
```

## Reglas

- `cat` de un `.tscn` completo solo si es menor a ~2 KB.
- Nunca abrir `.import`, `.uid`, `.glb`, `.blend`, ni nada bajo `.godot/`.
- Para editar: `sed`/`Edit` sobre la línea exacta que devolvió el grep. Godot
  reescribe el archivo al guardar desde el editor, así que los cambios a mano
  deben ser mínimos y en propiedades, no en la estructura de nodos.
