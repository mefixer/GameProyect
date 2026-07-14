# Cómo ejecutar el proyecto

Guía paso a paso para levantar el proyecto desde cero, jugarlo y probarlo.

## 1. Requisitos

| Herramienta | Versión mínima | Para qué |
| --- | --- | --- |
| [Godot Engine](https://godotengine.org) | 4.7 (edición estándar, no .NET) | Motor del juego |
| Git | 2.x | Clonar el repositorio |
| [Git LFS](https://git-lfs.com) | 3.x | Descargar los assets binarios |

### Instalar en Arch / Garuda / Manjaro

```bash
sudo pacman -Syu godot git git-lfs
```

> ⚠️ Usa siempre `-Syu` (no `-S` a secas): en una rolling release, instalar con la
> base de datos desactualizada produce errores 404 en los mirrors.

### Instalar en otras distros / sin root

- **Flatpak**: `flatpak install flathub org.godotengine.Godot`
- **Descarga directa**: binario oficial en [godotengine.org/download](https://godotengine.org/download)
  (es un ejecutable autocontenido, no necesita instalación)
- **Ubuntu/Debian**: `sudo apt install godot4 git git-lfs` (verifica que sea 4.7+)

## 2. Clonar el repositorio

```bash
# Solo la primera vez en cada máquina: activa Git LFS para tu usuario
git lfs install

git clone https://github.com/mefixer/GameProyect.git
cd GameProyect
```

Si ya habías clonado sin LFS y ves archivos binarios "rotos" (son punteros de texto):

```bash
git lfs pull
```

## 3. Abrir el proyecto en el editor

**Opción A — desde la terminal** (dentro de la carpeta del proyecto):

```bash
godot -e
```

**Opción B — desde el gestor de proyectos**: abre Godot, pulsa **Importar**,
navega hasta la carpeta y selecciona `project.godot`.

> La primera apertura tarda un poco más: Godot genera la carpeta `.godot/` con
> los recursos importados. Es normal y esa carpeta no se sube al repositorio.

## 4. Jugar

### Desde el editor

Pulsa **F5** (o el botón ▶ arriba a la derecha). Se lanza la escena principal:
el greybox de pruebas con el jugador, los maniquís y el HUD.

- **F6** ejecuta la escena que tengas abierta en el editor (útil para probar
  una escena suelta).
- **F8** o cerrar la ventana termina la partida.

### Sin editor (directo a jugar)

```bash
godot --path /ruta/a/GameProyect        # desde cualquier carpeta
# o simplemente, estando dentro del proyecto:
godot --path .
```

### Controles

| Acción | Teclado/Ratón | Mando |
| --- | --- | --- |
| Mover | WASD | Stick izquierdo |
| Cámara | Ratón | Stick derecho |
| Sprint (mantener) / Esquiva (toque corto) | Shift | B / Círculo |
| Salto | Espacio | A / Cruz |
| Ataque ligero | Clic izquierdo | RB / R1 |
| Ataque fuerte | Q | Gatillo derecho |
| Bloquear (mantener) | Clic derecho | LB / L1 |
| Parry (bloquear justo antes del impacto) | Clic derecho | LB / L1 |
| Lock-on / soltar lock-on | Tab o clic central | R3 |
| Cambiar objetivo fijado | Rueda del ratón | — |
| Soltar/recapturar el ratón | Esc / clic | — |

## 5. Probar y depurar

### Verificación rápida sin abrir ventana (estilo CI)

```bash
# Reimporta recursos y compila scripts; si algo está roto, lo imprime
godot --headless --import

# Ejecuta el juego 8 segundos sin ventana para cazar errores de runtime
timeout 8 godot --headless --path .
```

Si ninguno de los dos imprime errores, el proyecto está sano.

### Herramientas del editor útiles

- **Depuración → Formas de colisión visibles**: dibuja hitboxes, hurtboxes y
  colisiones mientras juegas — imprescindible para ajustar combate.
- **Panel Salida** (abajo): ahí aparecen los `print()` y errores en ejecución.
- **Escena Remota**: con el juego corriendo, pestaña *Remoto* en el árbol de
  escenas para inspeccionar y editar nodos en vivo.
- **Depurador → Perfilador**: si algo va lento, muestra qué función come frames.

### Ajustar el game feel sin tocar código

Todos los parámetros de combate y cámara son `@export`:

1. Abre `scenes/player/player.tscn`.
2. Selecciona el nodo `Player` (velocidades, costes de estamina, i-frames…)
   o `CameraRig` (sensibilidad, distancia de lock-on, shake…).
3. Cambia valores en el Inspector y vuelve a ejecutar con F5.

Los tiempos y daños de los ataques están en la constante `ATTACKS` de
`scripts/player/player.gd`.

## 6. Problemas comunes

| Síntoma | Causa / solución |
| --- | --- |
| El ratón "desaparece" al jugar | Está capturado (es lo esperado). **Esc** lo libera, clic lo recaptura |
| Texturas/modelos rotos tras clonar | Faltó Git LFS → `git lfs install && git lfs pull` |
| `pacman` da 404 al instalar | Base de datos vieja → `sudo pacman -Syu` |
| La primera apertura "se cuelga" | Es la importación inicial de `.godot/`; espera a que termine |
| Errores de UID al abrir escenas | Borra la carpeta `.godot/` y reabre (se regenera sola) |

## 7. Estructura para orientarse

La escena principal es `scenes/levels/greybox.tscn` (definida en
`project.godot` → `run/main_scene`). La arquitectura completa del código está
en [arquitectura.md](arquitectura.md).
