package engine

Tile :: struct {
	id:         string,
	texture_id: string,
	position:   Coordinate2D,
}

new_tile :: proc(id: string, texture_id: string, position: Coordinate2D = [2]f32{}) -> Tile {
	return Tile{id, texture_id, position}
}

delete_tile :: proc(self: ^Tile) {
	delete(self.id)
	delete(self.texture_id)
	self.position = [2]f32{}
}
