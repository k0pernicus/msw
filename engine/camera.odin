package engine

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

Camera2D :: struct {
	object: rl.Camera2D,
}

Camera3D :: struct {
	object: rl.Camera3D,
}

initCamera2D :: proc(position: [2]f32, target: [2]f32) -> Camera2D {
	return Camera2D {
		object = rl.Camera2D{offset = position, target = target, rotation = 0.0, zoom = 1.0},
	}
}

initCamera3D :: proc(position: [3]f32, target: [3]f32) -> Camera3D {
	return Camera3D{object = rl.Camera3D{position = position, target = target}}
}

// TODO : replace with better code
drawDynamicGrid :: proc(camera: ^Camera2D) {
	// 1. Get screen dimensions
	screen_w := f32(rl.GetScreenWidth())
	screen_h := f32(rl.GetScreenHeight())

	// 2. Determine world boundaries visible to the camera
	// We convert (0,0) and (screen_w, screen_h) from screen space to world space
	top_left := rl.GetScreenToWorld2D({0, 0}, camera.object)
	bottom_right := rl.GetScreenToWorld2D({screen_w, screen_h}, camera.object)

	grid_size: f32 = 100.0
	zoom := camera.object.zoom

	// 3. Calculate the starting and ending indices for the lines
	// math.floor(top_left.x / grid_size) tells us which grid column is just off-screen to the left
	start_x := f32(math.floor(top_left.x / grid_size)) * grid_size
	end_x := f32(math.ceil(bottom_right.x / grid_size)) * grid_size

	start_y := f32(math.floor(top_left.y / grid_size)) * grid_size
	end_y := f32(math.ceil(bottom_right.y / grid_size)) * grid_size

	grid_color := rl.Color{200, 200, 200, 40}
	text_color := rl.Color{255, 255, 255, 80}
	font_size := i32(12.0 / zoom)

	// 4. Draw Vertical Lines & X-axis labels
	for x := start_x; x <= end_x; x += grid_size {
		rl.DrawLineEx({x, start_y}, {x, end_y}, 1.0 / zoom, grid_color)

		// Only draw text if zoom is high enough to read it
		if zoom > 0.2 {
			// Label along the top edge of the view
			label := fmt.ctprintf("%.0f", x)
			rl.DrawText(label, i32(x + 5), i32(top_left.y + 5), font_size, text_color)
		}
	}

	// 5. Draw Horizontal Lines & Y-axis labels
	for y := start_y; y <= end_y; y += grid_size {
		rl.DrawLineEx({start_x, y}, {end_x, y}, 1.0 / zoom, grid_color)

		if zoom > 0.2 {
			// Label along the left edge of the view
			label := fmt.ctprintf("%.0f", y)
			rl.DrawText(label, i32(top_left.x + 5), i32(y + 5), font_size, text_color)
		}
	}
}

// Move the camera by `movement`
// This function does not erase the current position by `movement`!
moveCamera2D :: proc(self: ^Camera2D, movement: Coordinate2D) {
	self.object.target += movement
}

// Move the camera by `movement`
// This function does not erase the current position by `movement`!
moveCamera3D :: proc(self: ^Camera3D, movement: Coordinate3D) {
	self.object.target += movement
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
