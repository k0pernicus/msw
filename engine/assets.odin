package engine

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import rl "vendor:raylib"

ASSETS_FOLDER := "assets/"
ASSETS_DESCRIPTION := "desc.json"

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

AssetDescription :: struct {
	id:          string `json:"id"`,
	textureFile: string `json:"texture_file"`,
}

AssetError :: enum {
	OpenFileErr,
	GetFileSizeErr,
	ReadFileErr,
	UnmarshalErr,
	TextureLoadErr,
}

loadAssets :: proc() -> ([]AssetDescription, AssetError) {
	assetsDescPath := strings.concatenate([]string{ASSETS_FOLDER, ASSETS_DESCRIPTION})
	defer delete(assetsDescPath)
	if !os.exists(assetsDescPath) do return nil, .OpenFileErr
	fd, openErr := os.open(assetsDescPath, os.O_RDONLY)
	if openErr != nil {
		fmt.eprintfln("[ERROR] error opening assets description file: %s", openErr)
		return nil, .OpenFileErr
	}
	fileSize, sizeErr := os.file_size(fd)
	if sizeErr != nil {
		fmt.eprintfln("[ERROR] error getting size of assets description file: %s", openErr)
		return nil, .GetFileSizeErr
	}
	fileContent: []u8 = make([]u8, fileSize)
	defer delete(fileContent)
	if readBytes, err := os.read(fd, fileContent); err != nil || readBytes == 0 {
		fmt.eprintfln("[ERROR] error reading assets description file: %s", err)
		return nil, .ReadFileErr
	}
	description: []AssetDescription
	if err := json.unmarshal(fileContent, &description, allocator = context.temp_allocator);
	   err != nil {
		fmt.eprintfln("[ERROR] error unmarshalling assets description file: %s", err)
		return nil, .UnmarshalErr
	}
	return description, nil
}

loadTexture :: proc(self: ^AssetContext, assetName: string) -> (rl.Texture, AssetError) {
	if texture, exists := self.textures[assetName]; exists do return texture, nil

	assetPath := strings.concatenate([]string{ASSETS_FOLDER, assetName})
	defer delete(assetPath)
	texture := rl.LoadTexture(strings.clone_to_cstring(assetPath, context.temp_allocator))

	if texture.id == 0 do return rl.Texture{}, .TextureLoadErr // texture does not exists
	self.textures[assetName] = texture

	return texture, nil
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
