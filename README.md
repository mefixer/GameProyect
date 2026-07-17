# Soulslike 3D *(título provisional)*

Juego 3D de acción tipo *soulslike*, **de código abierto**, desarrollado con
[Godot Engine 4](https://godotengine.org) y herramientas 100% libres.

> Open source 3D soulslike action game made with Godot 4 and free/libre tools only.

## Estado

🚧 **En desarrollo temprano** — Fase 9: pulido y demo pública — partículas de combate (chispas, trail de arma, polvo de esquiva), brasas en el rewe, presets de exportación Linux/Windows y [guía para colaboradores](CONTRIBUTING.md). Audio y UI completos (Fases 7-8; falta música).

¿Quieres ayudar? Lee la [guía para contribuir](CONTRIBUTING.md) — se busca
ayuda especialmente en arte 3D, música y revisión cultural mapuche.

## Controles (prototipo)

| Acción | Teclado/Ratón | Mando |
| --- | --- | --- |
| Mover | WASD | Stick izquierdo |
| Cámara | Ratón | Stick derecho |
| Sprint (mantener) | Shift | B / Círculo |
| Esquiva (toque corto) | Shift | B / Círculo |
| Salto | Espacio | A / Cruz |
| Ataque ligero | Clic izquierdo | RB / R1 |
| Ataque fuerte | Q | Gatillo derecho |
| Bloquear (mantener) / Parry (justo antes del impacto) | Clic derecho | LB / L1 |
| Lock-on | Tab o clic central | R3 |
| Interactuar (rewe) | E | Y / Triángulo |
| Frasco de lawen | R | Cruceta arriba |
| Cambiar objetivo | Rueda del ratón | — |
| Pausa | Esc | Start |
| Inventario / estado del personaje | I | X / Cuadrado |
| Soltar/capturar ratón | Clic (fuera de menús) | — |

Teclado remapeable desde **Opciones** (menú principal o pausa), salvo los
controles de ratón (ataque, bloqueo, lock-on) y el mando.

## Cómo abrir el proyecto

1. Instala [Godot 4.7+](https://godotengine.org/download) (o vía Flatpak:
   `flatpak install flathub org.godotengine.Godot`)
2. Clona el repositorio (requiere [Git LFS](https://git-lfs.com)):

   ```bash
   git lfs install
   git clone https://github.com/mefixer/GameProyect.git
   ```

3. Abre `project.godot` con el editor de Godot y pulsa **F5** para jugar.

Guía completa (instalación por distro, ejecución sin editor, depuración y
problemas comunes): [docs/como-ejecutar.md](docs/como-ejecutar.md).

## Estructura del proyecto

```text
scenes/     Escenas de Godot (player, enemies, levels, ui, main)
scripts/    GDScript (componentes reutilizables, autoloads, lógica)
assets/     Modelos, texturas, materiales, audio, fuentes (vía Git LFS)
addons/     Plugins del editor
docs/       Documentación pública del proyecto
```

La arquitectura del código, con diagramas de la máquina de estados y el sistema
de combate, está documentada en [docs/arquitectura.md](docs/arquitectura.md).

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
