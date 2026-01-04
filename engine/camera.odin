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
drawDynamicGrid :: proc(camera: ^Camera2D, gridSize: f32) {
	// Get screen dimensions
	screenW := f32(rl.GetScreenWidth())
	screenH := f32(rl.GetScreenHeight())

	// Determine world boundaries visible to the camera
	// We convert (0,0) and (screen_w, screen_h) from screen space to world space
	topLeft := rl.GetScreenToWorld2D({0, 0}, camera.object)
	bottomRight := rl.GetScreenToWorld2D({screenW, screenH}, camera.object)

	zoom := camera.object.zoom

	// Calculate the starting and ending indices for the lines
	// math.floor(top_left.x / grid_size) tells us which grid column is just off-screen to the left
	startX := f32(math.floor(topLeft.x / gridSize)) * gridSize
	endX := f32(math.ceil(bottomRight.x / gridSize)) * gridSize

	startY := f32(math.floor(topLeft.y / gridSize)) * gridSize
	endY := f32(math.ceil(bottomRight.y / gridSize)) * gridSize

	gridColor := rl.Color{200, 200, 200, 40}
	textColor := rl.Color{255, 255, 255, 80}
	fontSize := i32(8.0 / zoom)

	// Draw Vertical Lines & X-axis labels
	for x := startX; x <= endX; x += gridSize {
		rl.DrawLineEx({x, startY}, {x, endY}, 1.0 / zoom, gridColor)

		// Only draw text if zoom is high enough to read it
		if zoom > 0.2 {
			// Label along the top edge of the view
			label := fmt.ctprintf("%.0f", x)
			rl.DrawText(label, i32(x + 5), i32(topLeft.y + 5), fontSize, textColor)
			rl.DrawText(label, i32(x + 5), i32(bottomRight.y - 20), fontSize, textColor)
		}
	}

	// Draw Horizontal Lines & Y-axis labels
	for y := startY; y <= endY; y += gridSize {
		rl.DrawLineEx({startX, y}, {endX, y}, 1.0 / zoom, gridColor)

		if zoom > 0.2 {
			// Label along the left edge of the view
			label := fmt.ctprintf("%.0f", y)
			rl.DrawText(label, i32(topLeft.x + 5), i32(y + 5), fontSize, textColor)
			rl.DrawText(label, i32(bottomRight.x - 25), i32(y + 5), fontSize, textColor)
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
