package editor

MIN_GRID_SIZE :: 16.0
MAX_GRID_SIZE :: 500.0
GRID_SIZE_STEP :: 2.0
DEFAULT_GRID_SIZE :: 64.0

CameraContext :: struct {
	enabled: bool,
}

EntitiesContext :: struct {
	enabled: bool,
}

DebugMode :: struct {
	camera:   CameraContext,
	entities: EntitiesContext,
	enabled:  bool,
}

GridContext :: struct {
	size: f32,
}

EditorContext :: struct {
	debugMode:   DebugMode,
	gridContext: GridContext,
}

initEditorContext :: proc() -> EditorContext {
	return EditorContext {
		debugMode = DebugMode {
			camera = CameraContext{enabled = false},
			entities = EntitiesContext{enabled = false},
			enabled = false,
		},
		gridContext = GridContext{size = DEFAULT_GRID_SIZE},
	}
}

deleteEditorContext :: proc(_: ^EditorContext) {}

cameraMode :: proc(self: ^EditorContext) -> bool {
	return self.debugMode.camera.enabled
}

entitiesMode :: proc(self: ^EditorContext) -> bool {
	return self.debugMode.entities.enabled
}

informationsMode :: proc(self: ^EditorContext) -> bool {
	return self.debugMode.enabled
}

toggleCameraDebugMode :: proc(self: ^EditorContext) {
	self.debugMode.camera.enabled = !self.debugMode.camera.enabled
}

toggleEntitiesDebugMode :: proc(self: ^EditorContext) {
	self.debugMode.entities.enabled = !self.debugMode.entities.enabled
}

toggleInformationsDebugMode :: proc(self: ^EditorContext) {
	self.debugMode.enabled = !self.debugMode.enabled
}
