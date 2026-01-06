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

init_world :: proc(self: ^World, asset_ctx: ^AssetContext, screen_width, screen_height: u32) {
	if self == nil {
		return
	}
	self.assets = asset_ctx
	// self.camera = initCamera2D({f32(screenWidth) / 2, f32(screenHeight) / 2}, {0, 0})
	self.camera = init_camera_2D({0, 0}, {0, 0})
	self.size = [2]u32{screen_width, screen_height}
	self.cursor = Cursor {
		position = get_mouse_world_position(&self.camera),
	}
}

// Delete all items stored in the World object
delete_world :: proc(self: ^World) {
	delete_spatial_grid(&self.grid)
	delete_asset_context(self.assets)
	for &entity in self.entities {
		delete_entity(&entity)
	}
	delete_dynamic_array(self.entities)
}

// Append an entity (copy) in the current dynamic array of entities
// of the current World object
add_entity :: proc(self: ^World, e: Entity) {
	// Append the texture
	texture, err := load_texture(self.assets, e.texture_id)
	if err != nil {
		log.errorf("cannot create entity with name '%s' : invalid textureId", e.id)
		return
	}
	em := e
	set_entity_size(&em, {texture.width, texture.height})
	append(&self.entities, em)
}
