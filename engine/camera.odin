package engine

import rl "vendor:raylib"

Camera2D :: struct {
	object: rl.Camera2D,
}

initCamera2D :: proc(position: [2]f32, target: [2]f32) -> Camera2D {
	return Camera2D {
		object = rl.Camera2D{offset = position, target = target, rotation = 0.0, zoom = 1.0},
	}
}

// Move the camera by `movement`
// This function does not erase the current position by `movement`!
moveCamera2D :: proc(self: ^Camera2D, movement: Coordinate2D) {
	self.object.target += movement
}

beginCamera2D :: proc(self: ^Camera2D) {
	rl.BeginMode2D(self.object)
}

endCamera2D :: proc(self: ^Camera2D) {
	rl.EndMode2D()
}

// Overload: This creates a single identifier that chooses the
// correct function based on the type you pass in.
moveCamera :: proc {
	moveCamera2D,
}

beginCamera :: proc {
	beginCamera2D,
}

endCamera :: proc {
	endCamera2D,
}
