package engine

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

CELL_SIZE :: 16.0
// TODO : the grid should be computed according to the world size,
// and not the renderer size...
// This works only as the world is not bigger than the screen for now
GRID_WIDTH :: RENDER_WIDTH / CELL_SIZE
GRID_HEIGHT :: RENDER_WIDTH / CELL_SIZE

SpatialGrid :: struct {
	cells: [GRID_WIDTH][GRID_HEIGHT][dynamic]^Entity,
}

deleteSpatialGrid :: proc(self: ^SpatialGrid) {
	for x in 0 ..< GRID_WIDTH {
		for y in 0 ..< GRID_HEIGHT {
			clear(&self.cells[x][y])
			delete_dynamic_array(self.cells[x][y])
		}
	}
}

registerEntitiesInGrid :: proc(self: ^SpatialGrid, entities: []Entity) {
	// Clear previous frame
	for x in 0 ..< GRID_WIDTH {
		for y in 0 ..< GRID_HEIGHT {
			clear(&self.cells[x][y])
		}
	}

	// Populate
	for &e in entities {
		// Get the world-space hitbox
		position: [2]f32 = {e.position.x, e.position.y}
		size: [2]i32 = e.size

		// Find the cell range (Min and Max)
		// We use integer division to find the index
		x_min := i32(position.x) / CELL_SIZE
		y_min := i32(position.y) / CELL_SIZE
		x_max := (i32(position.x) + size.x) / CELL_SIZE
		y_max := (i32(position.y) + size.y) / CELL_SIZE

		// Clamp to grid bounds to prevent crashes at world edges
		x_start := max(0, x_min)
		y_start := max(0, y_min)
		x_end := min(i32(GRID_WIDTH) - 1, x_max)
		y_end := min(i32(GRID_HEIGHT) - 1, y_max)

		for x in x_start ..= x_end {
			for y in y_start ..= y_end {
				append(&self.cells[x][y], &e)
			}
		}
	}
}

// TODO : replace with better code
drawDynamicGrid :: proc(camera: ^Camera2D, gridSize: f32, levelSize: Size2D) {
	// Draw the contours of the level
	rl.DrawRectangleLinesEx(
		{0, 0, f32(levelSize.x), f32(levelSize.y)},
		2.0 / camera.object.zoom,
		rl.RED,
	)

	// Determine world boundaries visible to the camera
	// We convert (0,0) and (screen_w, screen_h) from screen space to world space
	topLeft := rl.GetScreenToWorld2D({0, 0}, camera.object)
	bottomRight := rl.GetScreenToWorld2D(
		{f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())},
		camera.object,
	)

	zoom := camera.object.zoom

	// Calculate the starting and ending indices for the lines
	// math.floor(top_left.x / grid_size) tells us which grid column is just off-screen to the left
	startX := f32(math.floor(topLeft.x / gridSize)) * gridSize
	endX := f32(math.ceil(bottomRight.x / gridSize)) * gridSize

	startY := f32(math.floor(topLeft.y / gridSize)) * gridSize
	endY := f32(math.ceil(bottomRight.y / gridSize)) * gridSize

	gridColor := rl.Color{200, 200, 200, 80}
	textColor := rl.Color{255, 255, 255, 80}
	fontSize := i32(12.0 / zoom)

	// Draw Vertical Lines & X-axis labels
	for x := startX; x <= endX; x += gridSize {
		rl.DrawLineEx({x, startY}, {x, endY}, 1.0 / zoom, gridColor)

		// Only draw text if zoom is high enough to read it
		if zoom > 0.2 {
			// Label along the top edge of the view
			label := fmt.ctprintf("%.0f", x)
			rl.DrawTextPro(
				rl.GetFontDefault(),
				label,
				{f32(x + 5), f32(topLeft.y + 5)},
				rl.Vector2{0, 0}, // Rotation pivot relative to top-left of text
				45.0, // Degrees
				f32(fontSize),
				3.0,
				textColor,
			)
			rl.DrawTextPro(
				rl.GetFontDefault(),
				label,
				{f32(x + 5), f32(bottomRight.y - 20)},
				rl.Vector2{0, 0}, // Rotation pivot relative to top-left of text
				45.0, // Degrees
				f32(fontSize),
				2.0,
				textColor,
			)
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

drawCollisionGrid :: proc(ctx: ^GameContext) {
	g := &ctx.world.grid
	for x in 0 ..< GRID_WIDTH {
		for y in 0 ..< GRID_HEIGHT {
			rect := rl.Rectangle{f32(x * CELL_SIZE), f32(y * CELL_SIZE), CELL_SIZE, CELL_SIZE}

			// If cell is crowded, highlight it red
			count := len(g.cells[x][y])
			if count > 1 {
				rl.DrawRectangle(
					i32(rect.x),
					i32(rect.y),
					i32(rect.width),
					i32(rect.height),
					rl.RED,
				)
			}
		}
	}
}
