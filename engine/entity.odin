package engine

// TODO : change to any function (interface ?)
OnClickAction :: proc() -> string
// TODO : change to any function (interface ?)
OnHoverAction :: proc() -> string

// Object to store a texture and
// its current coordinates
Entity :: struct {
	id:         string,
	texture_id: string,
	position:   Coordinate2D,
	size:       Size2D,
	active:     bool,
	on_click:   OnClickAction,
	on_hover:   OnHoverAction,
}

init_entity :: proc(
	id: string,
	texture_id: string,
	position: Coordinate2D,
	active: bool = false,
	on_click: OnClickAction = no_action,
	on_hover: OnHoverAction = no_action,
) -> Entity {
	return Entity{id, texture_id, position, [2]i32{}, active, on_click, on_hover}
}

delete_entity :: proc(self: ^Entity) {
	self.position = [2]f32{}
	self.size = [2]i32{}
	self.active = false
	self.on_click = nil
	self.on_hover = nil
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
	   new_position.x > f32(game_ctx.world.size.x) ||
	   new_position.y < 0 ||
	   new_position.y > f32(game_ctx.world.size.y) {
		return
	}
	self.position = new_position
}

set_entity_position :: proc(self: ^Entity, new_position: Coordinate2D, game_ctx: ^GameContext) {
	self.position = new_position
}

no_action :: proc() -> string {
	return "..."
}

action_say_miaouh :: proc() -> string {
	return "Miaouh!"
}

action_say_grrh :: proc() -> string {
	return "Grrrrh..."
}
