# Guía para contribuir

¡Gracias por tu interés en este proyecto! Es un juego 3D tipo *soulslike*
ambientado en la cultura mapuche, hecho solo con herramientas libres.
Toda ayuda es bienvenida: código, arte, audio, documentación, playtesting
o correcciones culturales/lingüísticas.

## Antes de empezar

1. Lee el [README](README.md) para entender qué es el juego y cómo abrirlo.
2. Revisa la [arquitectura del código](docs/arquitectura.md) — explica la
   máquina de estados, el sistema de combate y las convenciones del proyecto.
3. Busca en los [issues abiertos](https://github.com/mefixer/GameProyect/issues)
   si alguien ya está trabajando en lo mismo.

## Requisitos

- [Godot 4.7+](https://godotengine.org/download)
- [Git LFS](https://git-lfs.com) (los assets binarios viven en LFS)
- Para editar modelos: [Blender](https://www.blender.org) (los `.blend`
  fuente están en `assets/models/*/blender_source/`)

Guía de instalación y ejecución completa: [docs/como-ejecutar.md](docs/como-ejecutar.md).

## Flujo de trabajo

1. Haz *fork* del repositorio y crea una rama descriptiva
   (`fix/parry-window`, `art/textura-rewe`).
2. Commits pequeños y frecuentes, con mensajes en español y en presente:
   `Fix: la ventana de parry no respetaba el hitstop`.
3. Verifica que el proyecto abre sin errores antes del PR:

   ```bash
   godot --headless --quit    # no debe imprimir errores
   ```

4. Abre un *pull request* explicando **qué** cambia y **por qué**.
   Si es visual (arte, VFX, UI), incluye una captura o video corto.

## Convenciones de código

- **GDScript** con tipado estático donde sea posible (`var x := 0.0`).
- Nombres y comentarios **en español**; identificadores del motor en inglés.
- Componentes reutilizables antes que herencia profunda — mira
  `scripts/components/` (health, stamina, hitbox, hurtbox).
- Los valores de gameplay (velocidades, daños, tiempos) van en `@export`
  para poder ajustarlos desde el inspector sin tocar código.
- Nada de assets con licencias **NC** (No Comercial) — ver política en
  [LICENSE-ASSETS.md](LICENSE-ASSETS.md). Todo asset externo se registra
  en [CREDITS.md](CREDITS.md) con origen y licencia.

## Representación cultural

Este juego trata la cultura mapuche con respeto y como protagonista
(ver el compromiso en el GDD). Si eres mapuche o conoces la cultura y ves
algo mal representado — un término mal usado, una práctica distorsionada,
un estereotipo — **ese issue es de los más valiosos que puedes abrir**.
Márcalo con la etiqueta `cultura`.

## Etiquetas de issues

| Etiqueta | Uso |
| --- | --- |
| `bug` | Algo no funciona como debería |
| `mejora` | Nueva funcionalidad o mejora de una existente |
| `arte` | Modelos, texturas, animaciones, VFX |
| `audio` | SFX, música, mezcla |
| `cultura` | Representación cultural / mapudungun |
| `docs` | Documentación |
| `buen-primer-issue` | Acotado y sin dependencias — ideal para empezar |
| `ayuda-buscada` | El autor no puede resolverlo solo (p. ej. arte 3D avanzado) |

## Licencias de las contribuciones

Al contribuir aceptas que tu aporte se publique bajo las licencias del
proyecto: [MIT](LICENSE) para código y [CC-BY 4.0](LICENSE-ASSETS.md) para
assets originales. Los assets de terceros que traigas deben ser CC0 o
CC-BY (nunca NC/ND) y quedar registrados en [CREDITS.md](CREDITS.md).
