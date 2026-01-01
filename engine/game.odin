package engine

import "core:fmt"
import rl "vendor:raylib"

getInputs :: proc(ctx: ^GameContext) {
	// Check for "Modifier" key (Ctrl or Command)
	if rl.IsKeyDown(.LEFT_CONTROL) || rl.IsKeyDown(.LEFT_SUPER) {
		// Debug camera
		if rl.IsKeyPressed(.C) do ctx.debugMode.camera = !ctx.debugMode.camera
		// Debug informations
		if rl.IsKeyPressed(.I) do ctx.debugMode.informations = !ctx.debugMode.informations
		// Debug entities
		if rl.IsKeyPressed(.E) do ctx.debugMode.entities = !ctx.debugMode.entities
	}
}

cameraMovement :: proc(ctx: ^GameContext) {
	STEP :: 5
	if rl.IsKeyDown(.LEFT) {
		ctx.world.camera.object.offset.x -= STEP
	} else if rl.IsKeyDown(.RIGHT) {
		ctx.world.camera.object.offset.x += STEP
	}

	if rl.IsKeyDown(.UP) {
		ctx.world.camera.object.offset.y -= STEP
	} else if rl.IsKeyDown(.DOWN) {
		ctx.world.camera.object.offset.y += STEP
	}

}

DebugMode :: struct {
	camera:       bool,
	entities:     bool,
	informations: bool,
}

// Handles all the information to run the game
GameContext :: struct {
	world:     World,
	assets:    ^AssetContext,
	quit:      bool,
	debugMode: DebugMode,
}

deleteGameContext :: proc(self: ^GameContext) {
	deleteAssetContext(self.assets)
	deleteWorld(&self.world)
	free(self.assets)
}

// Update physics, inputs, etc.
update_game :: proc(self: ^GameContext) {
	getInputs(self)
	cameraMovement(self)
	self.world.cursor.position = rl.GetMousePosition()
	pointingToEntity: bool = false
	for &entity in self.world.entities {
		if rl.CheckCollisionPointRec(
			self.world.cursor.position,
			rl.Rectangle {
				x = entity.position.x,
				y = entity.position.y,
				width = f32(self.world.assets.textures[entity.textureId].width),
				height = f32(self.world.assets.textures[entity.textureId].height),
			},
		) {
			pointingToEntity = true
			if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
				rl.DrawText(
					fmt.ctprintf("%s", entity.onClick()),
					20,
					self.world.size.y - 40,
					15,
					rl.RED,
				)
			} else {
				rl.DrawText(
					fmt.ctprintf("%s", entity.onHover()),
					20,
					self.world.size.y - 40,
					15,
					rl.RED,
				)
			}
		}
		// moveEntity(&entity, movement, self)
	}
	if pointingToEntity do changeCursorStyle(&self.world.cursor, CursorStyle.Pointing)
	else do changeCursorStyle(&self.world.cursor, CursorStyle.Default)
}

// Render all entities of the game
render_game :: proc(self: ^GameContext) {
	beginCamera(&self.world.camera)
	for &entity in self.world.entities {
		rTexture := getTexture(self.assets, entity.textureId)
		if rTexture == nil do continue
		texture := rTexture.(rl.Texture)
		rl.DrawTextureV(texture, entity.position, rl.WHITE)
	}
	// Draw the cursor with its latest associated style
	drawCursor(&self.world.cursor)
	endCamera(&self.world.camera)
}

// Render the UI (mainly for debug)
render_ui :: proc(self: ^GameContext) {
	beginCamera(&self.world.camera)
	fontSize: i32 = 18
	defaultX: i32 = 10
	if self.debugMode.informations {
		rl.DrawFPS(defaultX, 10)
		msw_pos_str := fmt.ctprint("msw project")
		rl.DrawText(msw_pos_str, defaultX, 35, fontSize, rl.YELLOW)
		// Display actual camera coordinates for debugging
		cam_pos_str := fmt.ctprintf(
			"Cam Target: %.2f, %.2f",
			self.world.camera.object.offset.x,
			self.world.camera.object.offset.y,
		)
		rl.DrawText(cam_pos_str, defaultX, 55, fontSize, rl.YELLOW)
		// Display cursor position
		cursor_pos_str := fmt.ctprintf(
			"Cursor: %.2f, %.2f",
			self.world.cursor.position.x,
			self.world.cursor.position.y,
		)
		rl.DrawText(cursor_pos_str, defaultX, 75, fontSize, rl.YELLOW)
	}


	if self.debugMode.camera {
		drawDynamicGrid(&self.world.camera)
	}

	if self.debugMode.entities {
		for &entity in self.world.entities {
			rTexture := getTexture(self.assets, entity.textureId)
			if rTexture == nil do continue
			texture := rTexture.(rl.Texture)
			rl.DrawText(
				fmt.ctprintf("%s", entity.id),
				i32(entity.position.x) - 10.0,
				i32(entity.position.y) - 18.0,
				10,
				rl.BLACK,
			)
			rl.DrawRectangleLinesEx(
				rl.Rectangle {
					x = entity.position.x - 5.0,
					y = entity.position.y - 5.0,
					width = f32(texture.width) + 5.0,
					height = f32(texture.height) + 5.0,
				},
				2.0,
				rl.BLACK,
			)
		}
	}
	endCamera(&self.world.camera)
}
