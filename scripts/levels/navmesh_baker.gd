extends NavigationRegion3D
## Hornea el navmesh en runtime a partir de los colisionadores estáticos
## hijos, así el greybox se puede editar sin rehornear a mano en el editor.


func _ready() -> void:
	bake_navigation_mesh()
