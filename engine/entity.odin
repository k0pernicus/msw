package engine

OnCollisionCallback :: proc(self: ^Entity, other: ^Entity, ctx: ^World)
OnInputCallback :: proc(self: ^Entity, ctx: ^World)

// Object to store a texture and
// its current coordinates
Entity :: struct {
	id:           string,
	texture_id:   string,
	position:     Coordinate2D,
	size:         Size2D,
	active:       bool,
	on_collision: OnCollisionCallback,
	on_input:     OnInputCallback,
}

init_entity :: proc(
	id: string,
	texture_id: string,
	position: Coordinate2D,
	active: bool = false,
	on_collision: OnCollisionCallback = do_nothing_on_collision,
	on_input: OnInputCallback = do_nothing_on_input,
) -> Entity {
	return Entity{id, texture_id, position, [2]i32{}, active, on_collision, on_input}
}

delete_entity :: proc(self: ^Entity) {
	self.position = [2]f32{}
	self.size = [2]i32{}
	self.active = false
	self.on_collision = nil
	self.on_input = nil
	// TODO : check why it crash on new entities
	// Seems like a memory issue (is the string still exists ???)
	delete(self.id)
	delete(self.texture_id)
}

set_entity_size :: proc(self: ^Entity, size: [2]i32) {
	self.size = size
}

set_entity_activity :: proc(self: ^Entity, activity: bool) {
	self.active = activity
}

// Move the entity by `movement`
// This function does not erase the current position by `movement`!
move_entity :: proc(self: ^Entity, movement: Coordinate2D, game_ctx: ^GameContext) {
	new_position := self.position + movement
	if new_position.x < 0 ||
	   new_position.x > f32(game_ctx.world.screen_size.x) ||
	   new_position.y < 0 ||
	   new_position.y > f32(game_ctx.world.screen_size.y) {
		return
	}
	self.position = new_position
}

set_entity_position :: proc(self: ^Entity, new_position: Coordinate2D, game_ctx: ^GameContext) {
	self.position = new_position
}

do_nothing_on_collision :: proc(self: ^Entity, other: ^Entity, ctx: ^World) {}

do_nothing_on_input :: proc(self: ^Entity, ctx: ^World) {}
