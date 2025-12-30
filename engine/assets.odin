package engine

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

ASSETS_FOLDER := "assets/"

AssetContext :: struct {
	textures: map[string]rl.Texture,
	fonts:    map[string]rl.Font,
}

initAssets :: proc(assetCtx: ^AssetContext) {
	if assetCtx == nil {
		return
	}
	assetCtx^ = AssetContext{}
}

loadTexture :: proc(self: ^AssetContext, assetName: string) -> Maybe(rl.Texture) {
	if texture, exists := self.textures[assetName]; exists do return texture

	assetPath := strings.concatenate([]string{ASSETS_FOLDER, assetName})
	defer delete(assetPath)
	texture := rl.LoadTexture(strings.clone_to_cstring(assetPath, context.temp_allocator))

	if texture.id == 0 do return nil // texture does not exists
	self.textures[assetName] = texture

	return texture
}

getTexture :: proc(self: ^AssetContext, textureId: string) -> Maybe(rl.Texture) {
	if texture, exists := self.textures[textureId]; exists do return texture
	return nil
}

unloadTexture :: proc(self: ^AssetContext, textureId: string) {
	texture, exists := self.textures[textureId]
	if !exists do return

	fmt.printfln("> unloading texture '%s' (id %d)...", textureId, texture.id)
	rl.UnloadTexture(texture)
	delete_key(&self.textures, textureId)
}

deleteAssetContext :: proc(self: ^AssetContext) {
	unloadTextures(self)
	unloadFonts(self)
}

unloadTextures :: proc(self: ^AssetContext) {
	for textureName, texture in self.textures {
		fmt.printfln("> unloading texture '%s' (id %d)...", textureName, texture.id)
		rl.UnloadTexture(texture)
		delete_key(&self.textures, textureName)
	}
	// Force clear the textures
	delete_map(self.textures)
	self.textures = nil
}

unloadFonts :: proc(self: ^AssetContext) {
	for fontName, font in self.fonts {
		fmt.printfln("> unloading font '%s'...", fontName)
		rl.UnloadFont(font)
		delete_key(&self.fonts, fontName)
	}
	// Force clear the fonts
	delete_map(self.fonts)
	self.fonts = nil
}
