package engine

import "core:log"

// Stored all objects related to a World
World :: struct {
	// To be freed with `deleteWorld` function
	// when the world is not used anymore
	// entities: [dynamic]Entity,
	entities: [dynamic]Entity,
	assets:   ^AssetContext,
	camera:   Camera2D,
	cursor:   Cursor,
	size:     [2]u32, // width, height
	grid:     SpatialGrid, // Lookup table of entities
}

initWorld :: proc(self: ^World, assetCtx: ^AssetContext, screenWidth, screenHeight: u32) {
	if self == nil {
		return
	}
	self.assets = assetCtx
	// self.camera = initCamera2D({f32(screenWidth) / 2, f32(screenHeight) / 2}, {0, 0})
	self.camera = initCamera2D({0, 0}, {0, 0})
	self.size = [2]u32{screenWidth, screenHeight}
	self.cursor = Cursor {
		position = getMouseWorldPosition(&self.camera),
	}
}

// Delete all items stored in the World object
deleteWorld :: proc(self: ^World) {
	deleteSpatialGrid(&self.grid)
	deleteAssetContext(self.assets)
	for &entity in self.entities {
		deleteEntity(&entity)
	}
	delete_dynamic_array(self.entities)
}

// Append an entity (copy) in the current dynamic array of entities
// of the current World object
addEntity :: proc(self: ^World, e: Entity) {
	// Append the texture
	texture, err := loadTexture(self.assets, e.textureId)
	if err != nil {
		log.errorf("cannot create entity with name '%s' : invalid textureId", e.id)
		return
	}
	em := e
	setEntitySize(&em, {texture.width, texture.height})
	append(&self.entities, em)
}
