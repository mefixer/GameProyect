# Créditos y assets de terceros

Registro obligatorio: **todo asset externo que entre al proyecto se anota aquí**
con su origen y licencia.

| Asset | Autor | Origen | Licencia | Ruta en el proyecto |
| --- | --- | --- | --- | --- |
| Ultimate Stylized Nature (selección: pinos, árboles muertos, rocas, arbustos, hierba) | [Quaternius](https://quaternius.com) | vía [mirror Godot de W. Palladino](https://github.com/walterpalladino/godot-quaternius-ultimate-stylized-nature) | **CC0** (modelos originales) | `assets/models/quaternius_nature/` |
| Wooden Shield (escudo de madera, placeholder de arma) | Jarlan Perez | [poly.pizza](https://poly.pizza/m/0uun1lQOHmj) | **CC-BY** — requiere atribución | `assets/models/props_cc/escudo_madera.glb` |
| Axe (hacha, placeholder de arma) | Daniel López Lacalle | [poly.pizza](https://poly.pizza/m/2hgRrLeI45k) | **CC-BY** — requiere atribución | `assets/models/props_cc/hacha.glb` |
| Low poly deer (placeholder de **huemul**, fauna ambiental) | Fotobudka EventTeam | [poly.pizza](https://poly.pizza/m/3d1y5pKrfRa) | **CC-BY** — requiere atribución | `assets/models/props_cc/huemul.glb` — `scenes/wildlife/huemul.tscn` |
| Figura Ceremonial mapuche (Rehue) | fablab.uct (U. Católica de Temuco) | [Sketchfab](https://sketchfab.com/3d-models/figura-ceremonial-mapuche-rehue-630557d7d28b46919e79247179b2f371) | **CC-BY 4.0** | `assets/models/mapuche_sketchfab/rehue/` — usado como el **rewe** real del juego (`scenes/props/rehue.tscn`, integrado en `scenes/world/rewe.tscn`) |
| Figura antropomorfa mapuche (Chemamull) | fablab.uct (U. Católica de Temuco) | [Sketchfab](https://sketchfab.com/3d-models/figura-antropomorfa-mapuche-chemamull-e9592c7cf1784072bd08befac951745b) | **CC-BY 4.0** | `assets/models/mapuche_sketchfab/chemamull_1/` — decoración en el sendero (`scenes/props/chemamull_1.tscn`) |
| Tótem mapuche para ritos funerarios (Chemamull) | fablab.uct (U. Católica de Temuco) | [Sketchfab](https://sketchfab.com/3d-models/totem-mapuche-para-ritos-funerarios-chemamull-68f82ac47d774f408073003c091b8a9f) | **CC-BY 4.0** | `assets/models/mapuche_sketchfab/chemamull_2/` — decoración junto a la emboscada (`scenes/props/chemamull_2.tscn`) |
| Mascara Antropomorfa Mapuche (Kollon) | fablab.uct (U. Católica de Temuco) | [Sketchfab](https://sketchfab.com/3d-models/mascara-antropomorfa-mapuche-kollon-db6fcd0d07d142e196be20df1c344b39) | **CC-BY 4.0** | `assets/models/mapuche_sketchfab/mascara_kollon/` — guardián cerca de la meseta (`scenes/props/mascara_kollon.tscn`) |
| RUCA MAPUCHE | borisquezadaa | [Sketchfab](https://sketchfab.com/3d-models/ruca-mapuche-cd2de259ba4941ecb1818b2259dd65dc) | **CC-BY 4.0** | `assets/models/mapuche_sketchfab/ruca/` — choza junto al rewe (`scenes/props/ruca.tscn`) |
| Ruka, ruca mapuche con estructura interior | borisquezadaa | [Sketchfab](https://sketchfab.com/3d-models/ruka-ruca-mapuche-con-estructura-interior-ee090c403bd14aa5b80b49ed36fe4263) | **CC-BY 4.0** | `assets/models/mapuche_sketchfab/ruka_interior/` — descargado pero **sin usar aún** (alternativa a la ruca de arriba, tiene interior habitable) |
| Totems Colectivo Originario | EternalEchoesVR | [Sketchfab](https://sketchfab.com/3d-models/totems-colectivo-originario-9c5bd6c472e34a6a9cff47ca2dd9c6b1) | **CC-BY 4.0** | `assets/models/mapuche_sketchfab/totems_colectivo/` — hito visual hacia la zona norte corrupta (`scenes/props/totems_colectivo.tscn`) |
| Escultura Pueblos Originarios - Plaza Baquedano | Luis Cuevas Quiroga | [Sketchfab](https://sketchfab.com/3d-models/escultura-pueblos-originarios-plaza-baquedano-9377fdfc40994c3bb5212b6e90f895a0) | **CC-BY 4.0** | `assets/models/mapuche_sketchfab/escultura_pueblos/` — bienvenida cerca del rewe (`scenes/props/escultura_pueblos.tscn`) |
| Demon Sword (arma, placeholder) | kyrylyushkov | [Sketchfab](https://sketchfab.com/3d-models/demon-sword-9b385527820545a39bacf4410297767c) | **CC-BY 4.0** — requiere atribución | `assets/models/sketchfab_cc/demon_sword/` |
| The Parade Armour of King Erik XIV of Sweden (armadura, placeholder) | The Royal Armoury (Livrustkammaren) | [Sketchfab](https://sketchfab.com/3d-models/the-parade-armour-of-king-erik-xiv-of-sweden-bd189bba7d9e4924b12826a6d68200d9) | **CC-BY 4.0** — requiere atribución | `assets/models/sketchfab_cc/parade_armour_erik_xiv/` |
| Retro Textures Fantasy (pack de texturas: puertas, muros, suelos, techos, ventanas) | [Kenney](https://kenney.nl) | [kenney.nl](https://kenney.nl/assets/retro-textures-fantasy) | **CC0** | `assets/textures/kenney_retro_fantasy/` |

> Notas técnicas:
>
> - Las texturas del pack Quaternius se redujeron de 4K a 512px; las de los escaneos
>   mapuche, de hasta 4K a 1024px máximo. Motivo: mantener el repositorio ligero
>   (Git LFS gestiona estos binarios, pero el tamaño en disco sigue importando).
> - Los escaneos de Sketchfab vienen en **unidades arbitrarias del escáner**, no metros.
>   Cada `scenes/props/*.tscn` aplica una escala y desplazamiento aproximados para
>   llevarlos a un tamaño realista (p. ej. un chemamüll de ~1.8 m). Son aproximaciones
>   de greybox — conviene refinarlas a ojo en Blender más adelante (escala exacta,
>   orientación/rotación de "frente", y opcionalmente decimar mallas muy pesadas).

## Assets excluidos por licencia (NO usar en el juego)

Estos dos también son escaneos reales y de gran calidad, pero su licencia
**CC-BY-NC-SA** (No Comercial) es incompatible con la posibilidad de vender el
juego o monetizar assets en el futuro. **Decisión del autor: no integrarlos.**
Se dejan documentados aquí solo como referencia de investigación — no hay
archivos de estos en el repositorio.

| Modelo | Autor | Licencia | Enlace |
| --- | --- | --- | --- |
| Kollón Mapuche (máscara ritual) | Museo Nacional de Historia Natural de Chile | CC-BY-NC-SA 4.0 | [Sketchfab](https://sketchfab.com/3d-models/kollon-mapuche-ef800332bbaf49e8a7ba51b28e86a4ad) |
| Pipa antropomorfa de piedra | Museo Nacional de Historia Natural de Chile | CC-BY-NC-SA 4.0 | [Sketchfab](https://sketchfab.com/3d-models/pipa-antropomorfa-de-piedra-d1f74b3e4aad42268b4c381a0f10a03f) |

## Herramientas

- [Godot Engine](https://godotengine.org) — MIT
- [Blender](https://www.blender.org) — GPL
