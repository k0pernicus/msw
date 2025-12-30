package engine

import "core:fmt"
import rl "vendor:raylib"

// Stored all objects related to a World
World :: struct {
	// To be freed with `deleteWorld` function
	// when the world is not used anymore
	entities: [dynamic]Entity,
	assets:   ^AssetContext,
	camera:   Camera2D,
	cursor:   Cursor,
	size:     [2]i32, // width, height
}

initWorld :: proc(self: ^World, assetCtx: ^AssetContext, screenWidth, screenHeight: i32) {
	if self == nil {
		return
	}
	self.assets = assetCtx
	// self.camera = initCamera2D({f32(screenWidth) / 2, f32(screenHeight) / 2}, {0, 0})
	self.camera = initCamera2D({0, 0}, {0, 0})
	self.size = [2]i32{screenWidth, screenHeight}
	self.cursor = Cursor {
		position = rl.GetMousePosition(),
	}
}

// Delete all items stored in the World object
deleteWorld :: proc(self: ^World) {
	deleteAssetContext(self.assets)
	delete_dynamic_array(self.entities)
}

// Append an entity (copy) in the current dynamic array of entities
// of the current World object
addEntity :: proc(self: ^World, e: Entity) {
	// Append the texture
	if loadTexture(self.assets, e.textureId) == nil {
		fmt.eprintfln("[ERROR] cannot create entity with name '%s' : invalid textureId", e.id)
		return
	}
	append(&self.entities, e)
}
