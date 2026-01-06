package engine

import rl "vendor:raylib"

Camera2D :: struct {
	object: rl.Camera2D,
}

init_camera_2D :: proc(position: [2]f32, target: [2]f32) -> Camera2D {
	return Camera2D {
		object = rl.Camera2D{offset = position, target = target, rotation = 0.0, zoom = 1.0},
	}
}

// Move the camera by `movement`
// This function does not erase the current position by `movement`!
move_camera_2D :: proc(self: ^Camera2D, movement: Coordinate2D) {
	self.object.target += movement
}

begin_camera_2D :: proc(self: ^Camera2D) {
	rl.BeginMode2D(self.object)
}

end_camera_2D :: proc(self: ^Camera2D) {
	rl.EndMode2D()
}

// Overload: This creates a single identifier that chooses the
// correct function based on the type you pass in.
move_camera :: proc {
	move_camera_2D,
}

begin_camera :: proc {
	begin_camera_2D,
}

end_camera :: proc {
	end_camera_2D,
}
