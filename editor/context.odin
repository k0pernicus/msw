package editor

EditorState :: struct {
	active_texture_id: string,
	is_hovering:       bool,
}

EditorContext :: struct {
	enabled: bool,
	state:   EditorState,
}

initEditorContext :: proc() -> EditorContext {
	return EditorContext{enabled = false}
}

delete_editor_context :: proc(_: ^EditorContext) {}

editor_mode :: proc(self: ^EditorContext) -> bool {
	return self.enabled
}

toggleEditorMode :: proc(self: ^EditorContext) {
	self.enabled = !self.enabled
}
