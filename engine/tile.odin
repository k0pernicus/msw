package engine

Tile :: struct {
	id:        string,
	textureId: string,
	position:  Coordinate2D,
}

newTile :: proc(id: string, textureId: string, position: Coordinate2D = [2]f32{}) -> Tile {
	return Tile{id, textureId, position}
}

deleteTile :: proc(self: ^Tile) {
	delete(self.id)
	delete(self.textureId)
	self.position = [2]f32{}
}
