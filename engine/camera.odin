package engine

import "core:fmt"
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

// TODO : replace with better code
drawCameraDebug :: proc(camera: ^Camera2D) {
	// Unpack data from your custom struct
	zoom := camera.object.zoom
	target := camera.object.target

	rl.DrawLineEx({-10000, 0}, {10000, 0}, 2.0 / zoom, rl.RED) // X-Axis
	rl.DrawLineEx({0, -10000}, {0, 10000}, 2.0 / zoom, rl.GREEN) // Y-Axis

	// Draw Grid and Coordinates
	grid_size: f32 = 100.0
	grid_color := rl.Color{200, 200, 200, 80}
	text_color := rl.Color{255, 255, 255, 200}

	// Determine the range to draw (e.g., -10 to 10 grid cells)
	for x: f32 = -10; x <= 10; x += 1 {
		for y: f32 = -10; y <= 10; y += 1 {
			world_x := x * grid_size
			world_y := y * grid_size

			// Draw the grid lines (only once per axis)
			if y == -10 do rl.DrawLineEx({world_x, -1000}, {world_x, 1000}, 1.0 / zoom, grid_color)
			if x == -10 do rl.DrawLineEx({-1000, world_y}, {1000, world_y}, 1.0 / zoom, grid_color)

			// Draw the coordinate text at the intersection
			coord_text := fmt.ctprintf("(%.0f, %.0f)", world_x, world_y)

			// Adjust font size based on zoom so it stays readable
			font_size := i32(10.0 / zoom)
			if font_size < 5 do font_size = 5

			rl.DrawText(coord_text, i32(world_x + 5), i32(world_y + 5), font_size, text_color)
		}
	}

	// Draw Target Crosshair
	rl.DrawCircleV(target, 5.0 / zoom, rl.YELLOW)
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
