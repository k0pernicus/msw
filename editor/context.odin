package editor

EditorContext :: struct {
	enabled: bool,
}

initEditorContext :: proc() -> EditorContext {
	return EditorContext{enabled = false}
}

deleteEditorContext :: proc(_: ^EditorContext) {}

editorMode :: proc(self: ^EditorContext) -> bool {
	return self.enabled
}

toggleEditorMode :: proc(self: ^EditorContext) {
	self.enabled = !self.enabled
}
