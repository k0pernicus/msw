package engine

import rl "vendor:raylib"

// Stored all objects related to a World
World :: struct {
	player:       ^Entity,
	entities:     [dynamic]Entity,
	assets:       ^AssetContext,
	camera:       Camera2D,
	cursor:       Cursor,
	screen_size:  [2]u32, // width, height
	grid:         SpatialGrid, // Lookup table of entities
	// Level streaming
	scroll_speed: f32,
	distance_run: f32,
	// Physics
	gravity:      f32,
}

init_world :: proc(self: ^World, asset_ctx: ^AssetContext, screen_width, screen_height: u32) {
	if self == nil {
		return
	}
	self.assets = asset_ctx
	self.camera = init_camera_2D({0, 0}, {0, 0})
	self.screen_size = [2]u32{screen_width, screen_height}
	self.cursor = Cursor {
		position = get_mouse_world_position(&self.camera),
	}
	self.grid = initSpatialGrid()
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
	content := get_asset(self.assets, e.texture_id)
	if content == nil do return

	// Append the texture
	em := e

	switch t in content {
	case rl.Font:
		return
	case rl.Texture:
		set_entity_size(&em, {content.(rl.Texture).width, content.(rl.Texture).height})
		append(&self.entities, em)
	case AnimationContext:
		set_entity_size(
			&em,
			{content.(AnimationContext).image.width, content.(AnimationContext).image.height},
		)
		append(&self.entities, em)
	}

}
