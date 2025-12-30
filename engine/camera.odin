package engine

import rl "vendor:raylib"

Camera2D :: struct {
	position: Coordinate2D,
	object:   rl.Camera2D,
}

Camera3D :: struct {
	position: Coordinate3D,
	object:   rl.Camera3D,
}

initCamera2D :: proc(position: [2]f32, target: [2]f32) -> Camera2D {
	return Camera2D {
		position = position,
		object = rl.Camera2D{offset = position, target = target, rotation = 0.0, zoom = 1.0},
	}
}

initCamera3D :: proc(position: [3]f32, target: [3]f32) -> Camera3D {
	return Camera3D {
		position = [3]f32{0, 0, 0},
		object = rl.Camera3D{position = position, target = target},
	}
}

drawCameraDebug :: proc(camera: ^Camera2D) {
	// 1. Unpack the target and current zoom regardless of 2D or 3D
	target: [2]f32
	zoom: f32 = 1.0

	// 2. Draw World Axes (The "Origin")
	// Red line for X, Green line for Y
	rl.DrawLineEx({-10000, 0}, {10000, 0}, 2.0 / zoom, rl.RED) // X-Axis
	rl.DrawLineEx({0, -10000}, {0, 10000}, 2.0 / zoom, rl.GREEN) // Y-Axis

	// 3. Draw a Grid (Optional but very helpful)
	grid_size: f32 = 100.0
	grid_color := rl.Color{200, 200, 200, 40} // Faint gray
	for i: f32 = -10; i <= 10; i += 1 {
		rl.DrawLineEx({i * grid_size, -1000}, {i * grid_size, 1000}, 1.0 / zoom, grid_color)
		rl.DrawLineEx({-1000, i * grid_size}, {1000, i * grid_size}, 1.0 / zoom, grid_color)
	}

	// 4. Draw a crosshair at the Camera's Target point
	// This helps you see if your "Position" logic is actually moving the camera
	rl.DrawCircleV({target.x, target.y}, 5.0 / zoom, rl.YELLOW)
}

// Move the camera by `movement`
// This function does not erase the current position by `movement`!
moveCamera2D :: proc(self: ^Camera2D, movement: Coordinate2D) {
	self.position += movement
	self.object.target = self.position
}

// Move the camera by `movement`
// This function does not erase the current position by `movement`!
moveCamera3D :: proc(self: ^Camera3D, movement: Coordinate3D) {
	self.position += movement
	self.object.target = self.position
}

beginCamera2D :: proc(self: ^Camera2D) {
	rl.BeginMode2D(self.object)
}

endCamera2D :: proc(self: ^Camera2D) {
	rl.EndMode2D()
}

beginCamera3D :: proc(self: ^Camera3D) {
	rl.BeginMode3D(self.object)
}

endCamera3D :: proc(self: ^Camera3D) {
	rl.EndMode3D()
}

// Overload: This creates a single identifier that chooses the
// correct function based on the type you pass in.
moveCamera :: proc {
	moveCamera2D,
	moveCamera3D,
}

beginCamera :: proc {
	beginCamera2D,
	beginCamera3D,
}

endCamera :: proc {
	endCamera2D,
	endCamera3D,
}
