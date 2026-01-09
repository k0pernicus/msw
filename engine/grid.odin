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
	cells: ^[GRID_WIDTH][GRID_HEIGHT][dynamic]^Entity,
}

initSpatialGrid :: proc() -> SpatialGrid {
	return SpatialGrid{cells = new([GRID_WIDTH][GRID_HEIGHT][dynamic]^Entity)}
}

delete_spatial_grid :: proc(self: ^SpatialGrid) {
	for x in 0 ..< GRID_WIDTH {
		for y in 0 ..< GRID_HEIGHT {
			clear(&self.cells[x][y])
			delete_dynamic_array(self.cells[x][y])
		}
	}
	free(self.cells)
	self.cells = nil
}

register_entities_in_grid :: proc(self: ^SpatialGrid, entities: []Entity) {
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
draw_dynamic_grid :: proc(camera: ^Camera2D, grid_size: f32, level_size: Size2D) {
	// Draw the contours of the level
	rl.DrawRectangleLinesEx(
		{0, 0, f32(level_size.x), f32(level_size.y)},
		2.0 / camera.object.zoom,
		rl.RED,
	)

	// Determine world boundaries visible to the camera
	// We convert (0,0) and (screen_w, screen_h) from screen space to world space
	top_left := rl.GetScreenToWorld2D({0, 0}, camera.object)
	bottom_right := rl.GetScreenToWorld2D(
		{f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())},
		camera.object,
	)

	zoom := camera.object.zoom

	// Calculate the starting and ending indices for the lines
	// math.floor(top_left.x / grid_size) tells us which grid column is just off-screen to the left
	start_x := f32(math.floor(top_left.x / grid_size)) * grid_size
	end_x := f32(math.ceil(bottom_right.x / grid_size)) * grid_size

	start_y := f32(math.floor(top_left.y / grid_size)) * grid_size
	end_y := f32(math.ceil(bottom_right.y / grid_size)) * grid_size

	grid_color := rl.Color{200, 200, 200, 80}
	text_color := rl.Color{255, 255, 255, 80}
	font_size := i32(12.0 / zoom)

	// Draw Vertical Lines & X-axis labels
	for x := start_x; x <= end_x; x += grid_size {
		rl.DrawLineEx({x, start_y}, {x, end_y}, 1.0 / zoom, grid_color)

		// Only draw text if zoom is high enough to read it
		if zoom > 0.2 {
			// Label along the top edge of the view
			label := fmt.ctprintf("%.0f", x)
			rl.DrawTextPro(
				rl.GetFontDefault(),
				label,
				{f32(x + 5), f32(top_left.y + 5)},
				rl.Vector2{0, 0}, // Rotation pivot relative to top-left of text
				45.0, // Degrees
				f32(font_size),
				3.0,
				text_color,
			)
			rl.DrawTextPro(
				rl.GetFontDefault(),
				label,
				{f32(x + 5), f32(bottom_right.y - 20)},
				rl.Vector2{0, 0}, // Rotation pivot relative to top-left of text
				45.0, // Degrees
				f32(font_size),
				2.0,
				text_color,
			)
		}
	}

	// Draw Horizontal Lines & Y-axis labels
	for y := start_y; y <= end_y; y += grid_size {
		rl.DrawLineEx({start_x, y}, {end_x, y}, 1.0 / zoom, grid_color)

		if zoom > 0.2 {
			// Label along the left edge of the view
			label := fmt.ctprintf("%.0f", y)
			rl.DrawText(label, i32(top_left.x + 5), i32(y + 5), font_size, text_color)
			rl.DrawText(label, i32(bottom_right.x - 25), i32(y + 5), font_size, text_color)
		}
	}
}

draw_collision_grid :: proc(ctx: ^GameContext) {
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
