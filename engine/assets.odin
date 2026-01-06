package engine

import "../game"
import "core:encoding/json"
import "core:log"
import "core:os"
import "core:strings"
import rl "vendor:raylib"

ASSETS_FOLDER := "assets/"
ASSETS_DESCRIPTION := "assets.json"

AssetContext :: struct {
	textures: map[string]rl.Texture,
	fonts:    map[string]rl.Font,
	levels:   []game.Level,
}

init_assets :: proc(asset_ctx: ^AssetContext) {
	if asset_ctx == nil {
		return
	}
	asset_ctx^ = AssetContext{}
}

AssetDescription :: struct {
	id:           string `json:"id"`,
	texture_file: string `json:"texture_file"`,
}

AssetError :: enum {
	OpenFileErr,
	GetFileSizeErr,
	ReadFileErr,
	UnmarshalErr,
	TextureLoadErr,
}

load_assets :: proc() -> ([]AssetDescription, AssetError) {
	assets_desc_path := strings.concatenate([]string{ASSETS_FOLDER, ASSETS_DESCRIPTION})
	defer delete(assets_desc_path)
	if !os.exists(assets_desc_path) do return nil, .OpenFileErr
	fd, open_err := os.open(assets_desc_path, os.O_RDONLY)
	if open_err != nil {
		log.errorf("error opening assets description file: %s", open_err)
		return nil, .OpenFileErr
	}
	file_size, size_err := os.file_size(fd)
	if size_err != nil {
		log.errorf("error getting size of assets description file: %s", open_err)
		return nil, .GetFileSizeErr
	}
	file_content: []u8 = make([]u8, file_size)
	defer delete(file_content)
	if read_bytes, err := os.read(fd, file_content); err != nil || read_bytes == 0 {
		log.errorf("error reading assets description file: %s", err)
		return nil, .ReadFileErr
	}
	description: []AssetDescription
	if err := json.unmarshal(file_content, &description, allocator = context.temp_allocator);
	   err != nil {
		log.errorf("error unmarshalling assets description file: %s", err)
		return nil, .UnmarshalErr
	}
	return description, nil
}

load_texture :: proc(self: ^AssetContext, asset_name: string) -> (rl.Texture, AssetError) {
	if texture, exists := self.textures[asset_name]; exists do return texture, nil

	asset_path := strings.concatenate([]string{ASSETS_FOLDER, asset_name})
	defer delete(asset_path)
	texture := rl.LoadTexture(strings.clone_to_cstring(asset_path, context.temp_allocator))

	if texture.id == 0 do return rl.Texture{}, .TextureLoadErr // texture does not exists
	self.textures[asset_name] = texture

	log.debugf("texture '%s' with id '%d' has been added", asset_name, texture.id)
	return texture, nil
}

get_texture :: proc(self: ^AssetContext, texture_id: string) -> Maybe(rl.Texture) {
	if texture, exists := self.textures[texture_id]; exists do return texture
	return nil
}

unload_texture :: proc(self: ^AssetContext, texture_id: string) {
	texture, exists := self.textures[texture_id]
	if !exists do return

	log.debugf("unloading texture '%s' (id %d)...", texture_id, texture.id)
	rl.UnloadTexture(texture)
	delete_key(&self.textures, texture_id)
}

delete_asset_context :: proc(self: ^AssetContext) {
	unload_textures(self)
	unload_fonts(self)
}

unload_textures :: proc(self: ^AssetContext) {
	for texture_name, texture in self.textures {
		log.debugf("unloading texture '%s' (id %d)...", texture_name, texture.id)
		rl.UnloadTexture(texture)
		delete_key(&self.textures, texture_name)
	}
	// Force clear the textures
	delete_map(self.textures)
	self.textures = nil
}

unload_fonts :: proc(self: ^AssetContext) {
	for font_name, font in self.fonts {
		log.debugf("unloading font '%s'...", font_name)
		rl.UnloadFont(font)
		delete_key(&self.fonts, font_name)
	}
	// Force clear the fonts
	delete_map(self.fonts)
	self.fonts = nil
}
