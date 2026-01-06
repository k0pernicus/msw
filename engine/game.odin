package engine

import "../editor"
import "../game"
import "core:fmt"
import "core:log"
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
	world:          World,
	assets:         ^AssetContext,
	quit:           bool,
	editor_context: editor.EditorContext,
	draw_commands:  [MAX_DRAW_COMMANDS]Maybe(DrawCommand),
	current_level:  ^game.Level,
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
	switch c in cmd {
	case DrawTextCommand:
		log.debugf("submitting draw text command: %v", c)
	case new_style:
		log.debugf("submitting draw cursor command: %v", c)
	}
	c_draw_command_idx += 1
}

// Update physics, inputs, etc.
update_game :: proc(self: ^GameContext) {
	get_inputs(self)
	camera_movement(self)
	self.world.cursor.position = get_mouse_world_position(&self.world.camera)
	// This boolean is used to change the cursor (TODO : check if )
	pointing_to_entity: bool = false
	for &entity in self.world.entities {
		if rl.CheckCollisionPointRec(
			self.world.cursor.position,
			rl.Rectangle {
				x = entity.position.x,
				y = entity.position.y,
				width = f32(self.world.assets.textures[entity.texture_id].width),
				height = f32(self.world.assets.textures[entity.texture_id].height),
			},
		) {
			pointing_to_entity = true
			displayText :=
				rl.IsMouseButtonDown(rl.MouseButton.LEFT) ? fmt.ctprintf("%s", entity.on_click()) : fmt.ctprintf("%s", entity.on_hover())
			submit_draw_command(
				self,
				DrawTextCommand {
					position = {i32(entity.position.x) + 20, i32(entity.position.y) - 20},
					size     = {0, 15}, // font size of 15 pixels
					color    = rl.RED,
					text     = displayText,
					space    = .World,
				},
			)
		}
	}
	register_entities_in_grid(&self.world.grid, self.world.entities[:])
	// TODO : add the entities in the world grid
	// Submit change of cursor
	cursorStyle := pointing_to_entity ? CursorStyle.Pointing : CursorStyle.Default
	submit_draw_command(self, new_style{cursorStyle})
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
		r_texture := get_texture(self.assets, entity.texture_id)
		if r_texture == nil do continue
		texture := r_texture.(rl.Texture)
		rl.DrawTextureV(texture, entity.position, rl.WHITE)
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

render_editor :: proc(self: ^GameContext) {
	if !editor.editor_mode(&self.editor_context) do return

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


	// Define a panel area for our debug info
	debug_panel_rect := rl.Rectangle{0, 0, 300, f32(rl.GetScreenHeight())}

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

	// Example Toggle button to show how RayGui handles input
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
