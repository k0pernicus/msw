package editor

MIN_GRID_SIZE :: 16.0
MAX_GRID_SIZE :: 500.0
GRID_SIZE_STEP :: 2.0
DEFAULT_GRID_SIZE :: 64.0

EntitiesContext :: struct {
	enabled: bool,
}

GridContext :: struct {
	enabled: bool,
	size:    f32,
}

DebugMode :: struct {
	grid:     GridContext,
	entities: EntitiesContext,
	enabled:  bool,
}

EditorContext :: struct {
	debugMode: DebugMode,
}

initEditorContext :: proc() -> EditorContext {
	return EditorContext {
		debugMode = DebugMode {
			grid = GridContext{enabled = false, size = DEFAULT_GRID_SIZE},
			entities = EntitiesContext{enabled = false},
			enabled = false,
		},
	}
}

deleteEditorContext :: proc(_: ^EditorContext) {}

gridMode :: proc(self: ^EditorContext) -> bool {
	return self.debugMode.grid.enabled
}

entitiesMode :: proc(self: ^EditorContext) -> bool {
	return self.debugMode.entities.enabled
}

informationsMode :: proc(self: ^EditorContext) -> bool {
	return self.debugMode.enabled
}

toggleGridDebugMode :: proc(self: ^EditorContext) {
	self.debugMode.grid.enabled = !self.debugMode.grid.enabled
}

toggleEntitiesDebugMode :: proc(self: ^EditorContext) {
	self.debugMode.entities.enabled = !self.debugMode.entities.enabled
}

toggleInformationsDebugMode :: proc(self: ^EditorContext) {
	self.debugMode.enabled = !self.debugMode.enabled
}
