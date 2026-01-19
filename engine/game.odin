package engine

import "../editor"
import "../game"
import "core:fmt"
import "core:log"
import "core:math"
import rl "vendor:raylib"

MAX_DRAW_COMMANDS :: 1024
c_draw_command_idx := 0

RENDER_WIDTH: u32 : 1920
RENDER_HEIGHT: u32 : 1920

get_inputs :: proc(ctx: ^GameContext) {
	// Check for "Modifier" key (Ctrl or Command)
	if rl.IsKeyDown(DEBUG_CMD_KEY) {
		// Debug menu
		if rl.IsKeyPressed(EDITOR_MENU_KEY) do editor.toggleEditorMode(&ctx.editor_context)
	}
}

camera_movement :: proc(ctx: ^GameContext) {
	STEP :: 5

	if !ctx.editor_context.enabled do return

	if rl.IsKeyDown(MODIFIER_KEY) {
		if rl.IsKeyDown(UP_KEY) {
			if ctx.world.camera.object.zoom >= 5.0 {return}
			ctx.world.camera.object.zoom += 0.01
		} else if rl.IsKeyDown(DOWN_KEY) {
			if ctx.world.camera.object.zoom <= 0.2 {return}
			ctx.world.camera.object.zoom -= 0.01
		}
		return
	}

	if rl.IsKeyDown(LEFT_KEY) {
		ctx.world.camera.object.target.x -= STEP
	} else if rl.IsKeyDown(RIGHT_KEY) {
		ctx.world.camera.object.target.x += STEP
	}

	if rl.IsKeyDown(UP_KEY) {
		ctx.world.camera.object.target.y -= STEP
	} else if rl.IsKeyDown(DOWN_KEY) {
		ctx.world.camera.object.target.y += STEP
	}
}

// Returns the world coordinates where the mouse is pointing
get_mouse_world_position :: proc(camera: ^Camera2D) -> [2]f32 {
	mouse_screen_pos := rl.GetMousePosition()
	world_pos := rl.GetScreenToWorld2D(mouse_screen_pos, camera.object)
	return world_pos
}

// Handles all the information for a frame of the game
GameContext :: struct {
	world:           World,
	assets:          ^AssetContext,
	quit:            bool,
	editor_context:  editor.EditorContext,
	draw_commands:   [MAX_DRAW_COMMANDS]Maybe(DrawCommand),
	current_level:   ^game.Level,
	frame_count:     i64,
	animation_speed: f32,
}

delete_game_context :: proc(self: ^GameContext) {
	delete_asset_context(self.assets)
	delete_world(&self.world)
	free(self.assets)
	editor.delete_editor_context(&self.editor_context)
}

submit_draw_command :: proc(self: ^GameContext, cmd: DrawCommand) {
	assert(c_draw_command_idx < MAX_DRAW_COMMANDS)
	self.draw_commands[c_draw_command_idx] = cmd
	// switch c in cmd {
	// case DrawTextCommand:
	// 	log.debugf("submitting draw text command: %v", c)
	// case new_style:
	// 	log.debugf("submitting draw cursor command: %v", c)
	// }
	c_draw_command_idx += 1
}

// Update physics, inputs, etc.
update_game :: proc(self: ^GameContext) {
	get_inputs(self)
	camera_movement(self)
	self.world.cursor.position = get_mouse_world_position(&self.world.camera)
	// Remove the entities to put in the grid
	update_entities(&self.world.entities)
	// This boolean is used to change the cursor (TODO)
	register_entities_in_grid(&self.world.grid, self.world.entities[:])
	// Submit change of cursor
	// pointing_to_entity: bool = false
	// cursorStyle := pointing_to_entity ? CursorStyle.Pointing : CursorStyle.Default
	// submit_draw_command(self, new_style{cursorStyle})

	if self.editor_context.enabled {
		update_editor_logic(self)
	}

	if (self.frame_count % i64(self.animation_speed)) == 0 {
		for _, &entity in self.assets.assets {
			switch t in entity.content {
			case AnimationContext:
				animation := &entity.content.(AnimationContext)
				animation.current_frame = (animation.current_frame + 1) % animation.nb_frames

				frame_data_ptr := cast([^]u8)animation.image.data
				pixel_size := animation.image.width * animation.image.height * 4
				offset := animation.current_frame * pixel_size

				rl.UpdateTexture(animation.texture, &frame_data_ptr[offset])
			case rl.Font:
				continue
			case rl.Texture:
				continue
			}}
	}
}

draw_command :: proc(self: ^GameContext, cmd: ^DrawCommand) {
	switch c in cmd {
	case new_style:
		change_cursor_style(&self.world.cursor, c.new_style)
	case DrawTextCommand:
		assert(c.text != nil)
		rl.DrawText(c.text.(cstring), c.position.x, c.position.y, c.size.y, c.color)
	case:
		log.fatalf("unknown command with type %v", c)
	}
}

// Render all entities of the game
render_game :: proc(self: ^GameContext) {
	for cmd_idx in 0 ..< c_draw_command_idx {
		cmd := self.draw_commands[cmd_idx].(DrawCommand)
		#partial switch c in cmd {
		case new_style:
			draw_command(self, &cmd)
		}
	}

	begin_camera(&self.world.camera)
	rl.DrawRectangleRec(
		{0, 0, f32(self.current_level.dimensions.x), f32(self.current_level.dimensions.y)},
		rl.RAYWHITE,
	)

	for &entity in self.world.entities {
		r_asset := get_asset(self.assets, entity.texture_id)
		if r_asset == nil do continue
		switch t in r_asset {
		case rl.Texture:
			texture := r_asset.(rl.Texture)
			rl.DrawTextureV(texture, entity.position, rl.WHITE)
		case AnimationContext:
			texture := r_asset.(AnimationContext).texture
			rl.DrawTextureV(texture, entity.position, rl.WHITE)
		case rl.Font:
			unimplemented("implement draw function for rl.Font")
		}
	}

	// Draw the cursor with its latest associated style
	draw_cursor(&self.world.cursor)

	// As we are in the camera, we only draw in the World space
	for cmd_idx in 0 ..< c_draw_command_idx {
		cmd := self.draw_commands[cmd_idx].(DrawCommand)
		#partial switch c in cmd {
		case DrawTextCommand:
			if c.space != .World do continue
			draw_command(self, &cmd)
		}
	}

	if self.editor_context.enabled && self.editor_context.state.active_texture_id != "" {
		mouse_world := get_mouse_world_position(&self.world.camera)

		snap_x := f32(i32(mouse_world.x / CELL_SIZE) * CELL_SIZE)
		snap_y := f32(i32(mouse_world.y / CELL_SIZE) * CELL_SIZE)

		asset := self.assets.assets[self.editor_context.state.active_texture_id]
		switch t in asset.content {
		case rl.Texture:
			texture := asset.content.(rl.Texture)
			rl.DrawTextureV(texture, {snap_x, snap_y}, rl.Fade(rl.WHITE, 0.5))
		case AnimationContext:
			texture := asset.content.(AnimationContext).texture
			rl.DrawTextureV(texture, {snap_x, snap_y}, rl.Fade(rl.WHITE, 0.5))
		case rl.Font:
			unimplemented("implement draw function for rl.Font")
		}
	}

	end_camera(&self.world.camera)

	// Now, draw in other spaces
	for cmd_idx in 0 ..< c_draw_command_idx {
		cmd := self.draw_commands[cmd_idx].(DrawCommand)
		#partial switch c in cmd {
		case DrawTextCommand:
			if c.space == .World do continue
			draw_command(self, &cmd)
		}
	}

	// Don't forget to clean the drawCommand dynamic array at the end
	for cmd_idx in 0 ..< c_draw_command_idx {
		cmd := &(self.draw_commands[cmd_idx].(DrawCommand))
		delete_draw_command(cmd)
		self.draw_commands[cmd_idx] = nil
	}
	c_draw_command_idx = 0
}

tile_exists_at :: proc(self: ^GameContext, x, y: f32) -> bool {
	// For now, a simple loop is fine.
	// Later, you can use your Spatial Grid here for instant lookups!
	for e in self.world.entities {
		if e.position.x == x && e.position.y == y {
			return true
		}
	}
	return false
}

update_editor_logic :: proc(self: ^GameContext) {
	if self.editor_context.state.is_hovering do return

	if self.editor_context.state.active_texture_id == "" do return

	mouse_world := get_mouse_world_position(&self.world.camera)
	snap_x := f32(i32(mouse_world.x / CELL_SIZE) * CELL_SIZE)
	snap_y := f32(i32(mouse_world.y / CELL_SIZE) * CELL_SIZE)

	if rl.IsMouseButtonDown(.LEFT) {
		// Check if something is already there to avoid stacking 100 tiles
		if !tile_exists_at(self, snap_x, snap_y) {
			asset := self.assets.assets[self.editor_context.state.active_texture_id]
			switch t in asset.content {
			case rl.Font:
				return
			case rl.Texture:
				new_tile := Entity {
					id           = fmt.aprintf("entity_%d", len(self.world.entities)),
					// TODO : random id ??
					position     = {snap_x, snap_y},
					texture_id   = self.editor_context.state.active_texture_id,
					size         = {
						asset.content.(rl.Texture).width,
						asset.content.(rl.Texture).height,
					},
					active       = true,
					on_collision = do_nothing_on_collision,
					on_input     = do_nothing_on_input,
				}
				append(&self.world.entities, new_tile)

				new_entity_desc := game.EntityDesc {
					id         = new_tile.id,
					texture_id = new_tile.texture_id,
					position   = new_tile.position,
				}
				append(&self.current_level.entities, new_entity_desc)
			case AnimationContext:
				texture := asset.content.(AnimationContext).texture
				new_tile := Entity {
					id           = fmt.aprintf("entity_%d", len(self.world.entities)),
					// TODO : random id ??
					position     = {snap_x, snap_y},
					texture_id   = self.editor_context.state.active_texture_id,
					size         = {texture.width, texture.height},
					active       = true,
					on_collision = do_nothing_on_collision,
					on_input     = do_nothing_on_input,
				}
				append(&self.world.entities, new_tile)

				new_entity_desc := game.EntityDesc {
					id         = new_tile.id,
					texture_id = new_tile.texture_id,
					position   = new_tile.position,
				}
				append(&self.current_level.entities, new_entity_desc)
			}
		}
	}

	if rl.IsMouseButtonDown(.RIGHT) {
		for &e, idx in self.world.entities {
			if e.position.x == snap_x && e.position.y == snap_y {
				unordered_remove(&self.world.entities, idx)
				unordered_remove(&self.current_level.entities, idx)
				break
			}
		}
	}
}

render_editor :: proc(self: ^GameContext) {
	if !editor.editor_mode(&self.editor_context) do return

	// Reset the hovering state
	self.editor_context.state.is_hovering = false

	begin_camera(&self.world.camera)

	draw_dynamic_grid(&self.world.camera, CELL_SIZE, self.current_level.dimensions)
	draw_collision_grid(self)

	for &entity in self.world.entities {
		// Draw Entity ID and Box in world space
		rl.GuiLabel(
			{entity.position.x, entity.position.y - 15, 120, 10},
			fmt.ctprintf("%s", entity.id),
		)
		rl.DrawRectangleLinesEx(
			{entity.position.x, entity.position.y, f32(entity.size.x), f32(entity.size.y)},
			1.0 / self.world.camera.object.zoom, // Keep lines thin regardless of zoom
			rl.BLACK,
		)
	}

	end_camera(&self.world.camera)

	draw_sidebar(self)
	draw_tile_selector(self)
}

draw_sidebar :: proc(self: ^GameContext) {
	// Define a panel area for our debug info
	debug_panel_rect := rl.Rectangle{0, 0, 300, f32(rl.GetScreenHeight())}

	mouse_pos := rl.GetMousePosition()
	self.editor_context.state.is_hovering |= rl.CheckCollisionPointRec(mouse_pos, debug_panel_rect)

	curr_y_top: f32 = 46
	curr_y_bottom: f32 = f32(rl.GetScreenHeight()) - curr_y_top

	get_debug_rect_from_top :: proc(curr_y: ^f32, spacing: f32 = 24) -> rl.Rectangle {
		r: rl.Rectangle = {10, curr_y^, 280, 20}
		curr_y^ += spacing
		return r
	}
	getDebug_rect_from_bottom :: proc(curr_y: ^f32, spacing: f32 = 24) -> rl.Rectangle {
		r: rl.Rectangle = {10, curr_y^, 280, 20}
		curr_y^ -= spacing
		return r
	}

	rl.GuiWindowBox(debug_panel_rect, "Editor")

	rl.GuiLabel(get_debug_rect_from_top(&curr_y_top), fmt.ctprintf("FPS: %d", rl.GetFPS()))

	rl.GuiLabel(get_debug_rect_from_top(&curr_y_top), fmt.ctprint("Project: msw project"))

	rl.GuiLabel(
		get_debug_rect_from_top(&curr_y_top),
		fmt.ctprintf("Level '%s'", self.current_level.name),
	)

	cam_str := fmt.ctprintf(
		"Cam target: %.1f, %.1f (z: %.2f)",
		self.world.camera.object.target.x,
		self.world.camera.object.target.y,
		self.world.camera.object.zoom,
	)
	rl.GuiLabel(get_debug_rect_from_top(&curr_y_top), cam_str)

	animation_slider_bounds := get_debug_rect_from_top(&curr_y_top)
	rl.GuiSlider(
		{
			animation_slider_bounds.x + 80,
			animation_slider_bounds.y,
			animation_slider_bounds.width - 100,
			animation_slider_bounds.height,
		},
		"Frame delay",
		fmt.ctprintf("%d", i32(self.animation_speed)),
		&self.animation_speed,
		3,
		15,
	)

	// Save the current level
	if rl.GuiButton(getDebug_rect_from_bottom(&curr_y_bottom), "SAVE LEVEL") {
		game.save_level(&self.assets.levels, self.current_level^, game.LEVELS_DESCRIPTION)
		free_all(context.temp_allocator)
	}

	// Reset the camera position
	if rl.GuiButton(getDebug_rect_from_bottom(&curr_y_bottom), "RESET CAMERA") {
		self.world.camera.object.offset = {
			f32(rl.GetScreenWidth()) / 2,
			f32(rl.GetScreenHeight()) / 2,
		}
		self.world.camera.object.target = {
			f32(self.current_level.dimensions.x) / 2.0,
			f32(self.current_level.dimensions.y) / 2.0,
		}
		self.world.camera.object.zoom = 1.0
	}
}

draw_tile_selector :: proc(self: ^GameContext) {
	sidebar_w: f32 = 300
	sidebar := rl.Rectangle {
		f32(rl.GetScreenWidth()) - sidebar_w,
		0,
		sidebar_w,
		f32(rl.GetScreenHeight()) / 3,
	}
	rl.GuiWindowBox(sidebar, "Textures")

	tooltip_to_draw: string = ""
	mouse_pos := rl.GetMousePosition()
	self.editor_context.state.is_hovering |= rl.CheckCollisionPointRec(mouse_pos, sidebar)

	padding: f32 = 10
	cell_size: f32 = 32 // Size of the texture preview
	text_height: f32 = 8 // Space for the ID text
	vertical_spacing: f32 = 10 // Space between rows

	// Calculate how many columns fit in the sidebar
	available_width := sidebar.width - (padding * 2)
	cols := i32(math.floor(available_width / (cell_size + padding)))
	if cols < 1 do cols = 1

	i: i32 = 0
	for asset_id, asset in self.assets.assets {
		if type_of(asset.content) == rl.Font do continue

		texture: rl.Texture
		switch t in asset.content {
		case rl.Texture:
			texture = asset.content.(rl.Texture)
		case AnimationContext:
			texture = asset.content.(AnimationContext).texture
		case rl.Font:
			continue
		}

		row := i / cols
		col := i % cols

		grid_x := sidebar.x + padding + (f32(col) * (cell_size + padding))
		grid_y := sidebar.y + 40 + (f32(row) * (cell_size + text_height + vertical_spacing))

		preview_rect := rl.Rectangle{grid_x, grid_y, cell_size, cell_size}
		src := rl.Rectangle{0, 0, f32(texture.width), f32(texture.height)}

		// Draw the Texture
		rl.DrawTexturePro(texture, src, preview_rect, {0, 0}, 0, rl.WHITE)

		// Hover/Selection Logic
		is_texture_hovered := rl.CheckCollisionPointRec(mouse_pos, preview_rect)
		if self.editor_context.state.active_texture_id == asset_id {
			rl.DrawRectangleLinesEx(preview_rect, 2, rl.YELLOW)
		} else if is_texture_hovered {
			rl.DrawRectangleLinesEx(preview_rect, 1, rl.RAYWHITE)
			tooltip_to_draw = asset_id
		}

		// Draw Label (Truncated if necessary)
		short_id := asset_id
		if len(short_id) > 8 do short_id = short_id[:8]
		rl.DrawText(fmt.ctprint(short_id), i32(grid_x), i32(grid_y + cell_size + 2), 10, rl.GRAY)

		if is_texture_hovered && rl.IsMouseButtonPressed(.LEFT) {
			self.editor_context.state.active_texture_id = asset_id
		}

		i += 1
	}

	if tooltip_to_draw != "" {
		text_w := rl.MeasureText(fmt.ctprint(tooltip_to_draw), 10)
		tip_rect := rl.Rectangle{mouse_pos.x + 15, mouse_pos.y, f32(text_w + 10), 20}

		rl.DrawRectangleRec(tip_rect, rl.BLACK)
		rl.DrawRectangleLinesEx(tip_rect, 1, rl.GRAY)
		rl.DrawText(
			fmt.ctprint(tooltip_to_draw),
			i32(tip_rect.x + 5),
			i32(tip_rect.y + 5),
			10,
			rl.WHITE,
		)
	}
}
