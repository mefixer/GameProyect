# Créditos y assets de terceros

Registro obligatorio: **todo asset externo que entre al proyecto se anota aquí**
con su origen y licencia.

| Asset | Autor | Origen | Licencia | Ruta en el proyecto |
| --- | --- | --- | --- | --- |
| Ultimate Stylized Nature (selección: pinos, árboles muertos, rocas, arbustos, hierba) | [Quaternius](https://quaternius.com) | vía [mirror Godot de W. Palladino](https://github.com/walterpalladino/godot-quaternius-ultimate-stylized-nature) | **CC0** (modelos originales) | `assets/models/quaternius_nature/` |
| Wooden Shield (escudo de madera, placeholder de arma) | Jarlan Perez | [poly.pizza](https://poly.pizza/m/0uun1lQOHmj) | **CC-BY** — requiere atribución | `assets/models/props_cc/escudo_madera.glb` |
| Axe (hacha, placeholder de arma) | Daniel López Lacalle | [poly.pizza](https://poly.pizza/m/2hgRrLeI45k) | **CC-BY** — requiere atribución | `assets/models/props_cc/hacha.glb` |

> Nota: las texturas del pack Quaternius se redujeron de 4K a 512px para mantener el repo ligero.

## Pendientes de descarga manual (requieren cuenta de Sketchfab)

Sketchfab exige inicio de sesión incluso para modelos CC-BY gratuitos, así que estos no
se pudieron automatizar. Son los más valiosos para la identidad visual del juego —
escaneos reales de piezas mapuche del FabLab de la Universidad Católica de Temuco:

| Modelo | Autor | Licencia | Enlace | Uso previsto |
| --- | --- | --- | --- | --- |
| Chemamüll (figura antropomorfa funeraria) | fablab.uct | CC-BY | [Sketchfab](https://sketchfab.com/3d-models/figura-antropomorfa-mapuche-chemamull-e9592c7cf1784072bd08befac951745b) | Decoración/hito visual en el bosque o cerca del rewe |
| Chemamüll (tótem funerario, variante) | fablab.uct | CC-BY | [Sketchfab](https://sketchfab.com/3d-models/totem-mapuche-para-ritos-funerarios-chemamull-68f82ac47d774f408073003c091b8a9f) | Alternativa a la anterior |
| Rehue (figura ceremonial de la machi) | fablab.uct | CC-BY | [Sketchfab](https://sketchfab.com/3d-models/figura-ceremonial-mapuche-rehue-630557d7d28b46919e79247179b2f371) | Base para el modelo real del **rewe** del juego (ver [[Nivel 1 - Bosque de Araucarias]]) |
| Kultrün (tambor ceremonial) | cidvictoria | CC-BY (verificar en la página) | [Sketchfab](https://sketchfab.com/3d-models/kultrun-3c96296996274f76b256203efcdfc702) | Prop de la machi / mecánica de trance del GDD |

**Cómo descargarlos** (gratis, ~2 min cada uno):

1. Crear cuenta gratuita en [sketchfab.com](https://sketchfab.com) (o iniciar sesión con Google).
2. Abrir cada enlace de arriba → botón **Download 3D Model** → formato **glTF** (o
   Original) → se descarga un `.zip`.
3. Descomprimir en `assets/models/mapuche_sketchfab/<nombre>/` dentro del proyecto.
4. Abrir el `.glb`/`.gltf` en **Blender** para revisar escala, orientación y
   decimar el mesh (el chemamüll trae 66k triángulos — sobra para un prop de fondo,
   conviene bajarlo a 2–5k con el modificador Decimate antes de traerlo a Godot).
5. Anotar aquí la ruta final una vez integrados.

## Herramientas

- [Godot Engine](https://godotengine.org) — MIT
- [Blender](https://www.blender.org) — GPL
