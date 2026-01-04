package engine

import "../editor"
import "../game"
import "core:fmt"
import "core:log"
import rl "vendor:raylib"

MAX_DRAW_COMMANDS :: 1024
cDrawCommandIdx := 0

RENDER_WIDTH: u32 : 1920
RENDER_HEIGHT: u32 : 1920

getInputs :: proc(ctx: ^GameContext) {
	// Check for "Modifier" key (Ctrl or Command)
	if rl.IsKeyDown(DEBUG_CMD_KEY) {
		// Debug menu
		if rl.IsKeyPressed(EDITOR_MENU_KEY) do editor.toggleEditorMode(&ctx.editorContext)
	}
}

cameraMovement :: proc(ctx: ^GameContext) {
	STEP :: 5

	if !ctx.editorContext.enabled do return

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
getMouseWorldPosition :: proc(camera: ^Camera2D) -> [2]f32 {
	mouseScreenPos := rl.GetMousePosition()
	worldPos := rl.GetScreenToWorld2D(mouseScreenPos, camera.object)
	return worldPos
}

// Handles all the information for a frame of the game
GameContext :: struct {
	world:         World,
	assets:        ^AssetContext,
	quit:          bool,
	editorContext: editor.EditorContext,
	drawCommands:  [MAX_DRAW_COMMANDS]Maybe(DrawCommand),
	currentLevel:  ^game.Level,
}

deleteGameContext :: proc(self: ^GameContext) {
	deleteAssetContext(self.assets)
	deleteWorld(&self.world)
	free(self.assets)
	editor.deleteEditorContext(&self.editorContext)
}

submitDrawCommand :: proc(self: ^GameContext, cmd: DrawCommand) {
	assert(cDrawCommandIdx < MAX_DRAW_COMMANDS)
	self.drawCommands[cDrawCommandIdx] = cmd
	switch c in cmd {
	case DrawTextCommand:
		log.debugf("submitting draw text command: %v", c)
	case DrawCursorCommand:
		log.debugf("submitting draw cursor command: %v", c)
	}
	cDrawCommandIdx += 1
}

// Update physics, inputs, etc.
updateGame :: proc(self: ^GameContext) {
	getInputs(self)
	cameraMovement(self)
	self.world.cursor.position = getMouseWorldPosition(&self.world.camera)
	// This boolean is used to change the cursor (TODO : check if )
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
			displayText :=
				rl.IsMouseButtonDown(rl.MouseButton.LEFT) ? fmt.ctprintf("%s", entity.onClick()) : fmt.ctprintf("%s", entity.onHover())
			submitDrawCommand(
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
	registerEntitiesInGrid(&self.world.grid, self.world.entities[:])
	// TODO : add the entities in the world grid
	// Submit change of cursor
	cursorStyle := pointingToEntity ? CursorStyle.Pointing : CursorStyle.Default
	submitDrawCommand(self, DrawCursorCommand{cursorStyle})
}

drawCommand :: proc(self: ^GameContext, cmd: ^DrawCommand) {
	switch c in cmd {
	case DrawCursorCommand:
		changeCursorStyle(&self.world.cursor, c.newStyle)
	case DrawTextCommand:
		assert(c.text != nil)
		rl.DrawText(c.text.(cstring), c.position.x, c.position.y, c.size.y, c.color)
	case:
		log.fatalf("unknown command with type %v", c)
	}
}

// Render all entities of the game
renderGame :: proc(self: ^GameContext) {
	for cmdIdx in 0 ..< cDrawCommandIdx {
		cmd := self.drawCommands[cmdIdx].(DrawCommand)
		#partial switch c in cmd {
		case DrawCursorCommand:
			drawCommand(self, &cmd)
		}
	}

	beginCamera(&self.world.camera)
	rl.DrawRectangleRec(
		{0, 0, f32(self.currentLevel.dimensions.x), f32(self.currentLevel.dimensions.y)},
		rl.RAYWHITE,
	)

	for &entity in self.world.entities {
		rTexture := getTexture(self.assets, entity.textureId)
		if rTexture == nil do continue
		texture := rTexture.(rl.Texture)
		rl.DrawTextureV(texture, entity.position, rl.WHITE)
	}

	// Draw the cursor with its latest associated style
	drawCursor(&self.world.cursor)

	// As we are in the camera, we only draw in the World space
	for cmdIdx in 0 ..< cDrawCommandIdx {
		cmd := self.drawCommands[cmdIdx].(DrawCommand)
		#partial switch c in cmd {
		case DrawTextCommand:
			if c.space != .World do continue
			drawCommand(self, &cmd)
		}
	}
	endCamera(&self.world.camera)

	// Now, draw in other spaces
	for cmdIdx in 0 ..< cDrawCommandIdx {
		cmd := self.drawCommands[cmdIdx].(DrawCommand)
		#partial switch c in cmd {
		case DrawTextCommand:
			if c.space == .World do continue
			drawCommand(self, &cmd)
		}
	}

	// Don't forget to clean the drawCommand dynamic array at the end
	for cmdIdx in 0 ..< cDrawCommandIdx {
		cmd := &(self.drawCommands[cmdIdx].(DrawCommand))
		deleteDrawCommand(cmd)
		self.drawCommands[cmdIdx] = nil
	}
	cDrawCommandIdx = 0
}

renderUI :: proc(self: ^GameContext) {
	if !editor.editorMode(&self.editorContext) do return

	beginCamera(&self.world.camera)

	drawDynamicGrid(&self.world.camera, CELL_SIZE, self.currentLevel.dimensions)
	drawCollisionGrid(self)

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

	endCamera(&self.world.camera)


	// Define a panel area for our debug info
	debugPanelRect := rl.Rectangle{0, 0, 300, f32(rl.GetScreenHeight())}

	currYTop: f32 = 46
	currYBottom: f32 = f32(rl.GetScreenHeight()) - currYTop

	getDebugRectFromTop :: proc(currY: ^f32, spacing: f32 = 24) -> rl.Rectangle {
		r: rl.Rectangle = {10, currY^, 280, 20}
		currY^ += spacing
		return r
	}
	getDebugRectFromBottom :: proc(currY: ^f32, spacing: f32 = 24) -> rl.Rectangle {
		r: rl.Rectangle = {10, currY^, 280, 20}
		currY^ -= spacing
		return r
	}

	rl.GuiWindowBox(debugPanelRect, "Editor")

	rl.GuiLabel(getDebugRectFromTop(&currYTop), fmt.ctprintf("FPS: %d", rl.GetFPS()))

	rl.GuiLabel(getDebugRectFromTop(&currYTop), fmt.ctprint("Project: msw project"))

	rl.GuiLabel(getDebugRectFromTop(&currYTop), fmt.ctprintf("Level '%s'", self.currentLevel.name))

	cam_str := fmt.ctprintf(
		"Cam target: %.1f, %.1f (z: %.2f)",
		self.world.camera.object.target.x,
		self.world.camera.object.target.y,
		self.world.camera.object.zoom,
	)
	rl.GuiLabel(getDebugRectFromTop(&currYTop), cam_str)

	// Example Toggle button to show how RayGui handles input
	if rl.GuiButton(getDebugRectFromBottom(&currYBottom), "RESET CAMERA") {
		self.world.camera.object.offset = {
			f32(rl.GetScreenWidth()) / 2,
			f32(rl.GetScreenHeight()) / 2,
		}
		self.world.camera.object.target = {
			f32(self.currentLevel.dimensions.x) / 2.0,
			f32(self.currentLevel.dimensions.y) / 2.0,
		}
		self.world.camera.object.zoom = 1.0
	}
}
