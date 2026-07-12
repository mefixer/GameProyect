# Soulslike 3D *(título provisional)*

Juego 3D de acción tipo *soulslike*, **de código abierto**, desarrollado con
[Godot Engine 4](https://godotengine.org) y herramientas 100% libres.

> Open source 3D soulslike action game made with Godot 4 and free/libre tools only.

## Estado

🚧 **En desarrollo temprano** — Fase 1: prototipo de movimiento, cámara y lock-on en greybox.

## Controles (prototipo)

| Acción | Teclado/Ratón | Mando |
| --- | --- | --- |
| Mover | WASD | Stick izquierdo |
| Cámara | Ratón | Stick derecho |
| Sprint | Shift | B / Círculo |
| Salto | Espacio | A / Cruz |
| Lock-on | Tab o clic central | R3 |
| Cambiar objetivo | Rueda del ratón | — |
| Soltar/capturar ratón | Esc / clic | — |

## Cómo abrir el proyecto

1. Instala [Godot 4.7+](https://godotengine.org/download) (o vía Flatpak:
   `flatpak install flathub org.godotengine.Godot`)
2. Clona el repositorio (requiere [Git LFS](https://git-lfs.com)):

   ```bash
   git lfs install
   git clone https://github.com/mefixer/GameProyect.git
   ```

3. Abre `project.godot` con el editor de Godot.

## Estructura del proyecto

```text
scenes/     Escenas de Godot (player, enemies, levels, ui, main)
scripts/    GDScript (componentes reutilizables, autoloads, lógica)
assets/     Modelos, texturas, materiales, audio, fuentes (vía Git LFS)
addons/     Plugins del editor
docs/       Documentación pública del proyecto
```

## Herramientas usadas

| Área | Herramienta |
| --- | --- |
| Motor | Godot 4.7 |
| Modelado y animación | Blender |
| Texturas | Krita / Material Maker |
| Audio | Audacity / LMMS |

## Licencias

- **Código**: [MIT](LICENSE)
- **Assets originales**: [CC-BY 4.0](LICENSE-ASSETS.md)
- **Assets de terceros**: ver [CREDITS.md](CREDITS.md)
