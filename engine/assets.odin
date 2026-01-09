package engine

import "../game"
import "core:encoding/json"
import "core:log"
import "core:os"
import "core:strings"
import rl "vendor:raylib"

ASSETS_FOLDER := "assets/"
ASSETS_DESCRIPTION := "assets.json"

AnimationContext :: struct {
	image:         rl.Image,
	texture:       rl.Texture,
	current_frame: i32,
	nb_frames:     i32,
}

AssetContent :: union {
	AnimationContext,
	rl.Texture,
	rl.Font,
}

Asset :: struct {
	filename: string,
	content:  AssetContent,
}

AssetContext :: struct {
	assets: map[string]Asset,
	levels: []game.Level,
}

init_assets :: proc(asset_ctx: ^AssetContext) {
	if asset_ctx == nil {
		return
	}
	asset_ctx^ = AssetContext{}
}

AssetDescription :: struct {
	id:           string `json:"id"`,
	// image, animation
	type:         string `json:"type"`,
	texture_file: string `json:"texture_file"`,
}

AssetError :: enum {
	OpenFileErr,
	GetFileSizeErr,
	ReadFileErr,
	UnmarshalErr,
	TextureLoadErr,
}

load_assets :: proc() -> (^AssetContext, AssetError) {
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
	// TODO : check for the memory introduced in json.unmarshal call
	// If I put this in a
	if err := json.unmarshal(file_content, &description); err != nil {
		log.errorf("error unmarshalling assets description file: %s", err)
		return nil, .UnmarshalErr
	}

	asset_ctx := new(AssetContext)
	for asset_desc in description {
		switch asset_desc.type {
		case "texture":
			if texture, err := load_texture(asset_desc); err == nil {
				asset_ctx.assets[asset_desc.id] = {
					filename = asset_desc.texture_file,
					content  = texture,
				}
			}
		case "animation":
			if animation, err := load_animation(asset_desc); err == nil {
				asset_ctx.assets[asset_desc.id] = {
					filename = asset_desc.texture_file,
					content  = animation,
				}
			}
		case:
			unimplemented("asset description with unknown type")
		}
	}
	return asset_ctx, nil
}

load_texture :: proc(asset_desc: AssetDescription) -> (rl.Texture, AssetError) {
	asset_path := strings.concatenate([]string{ASSETS_FOLDER, asset_desc.texture_file})
	defer delete(asset_path)

	texture := rl.LoadTexture(strings.clone_to_cstring(asset_path, context.temp_allocator))

	if texture.id == 0 do return rl.Texture{}, .TextureLoadErr // texture does not exists
	return texture, nil
}

load_animation :: proc(asset_desc: AssetDescription) -> (AnimationContext, AssetError) {
	asset_path := strings.concatenate([]string{ASSETS_FOLDER, asset_desc.texture_file})
	defer delete(asset_path)

	nb_frames: i32 = 0
	animation := rl.LoadImageAnim(
		strings.clone_to_cstring(asset_path, context.temp_allocator),
		&nb_frames,
	)
	texture := rl.LoadTextureFromImage(animation)
	return {image = animation, texture = texture, current_frame = 0, nb_frames = nb_frames}, nil
}

get_asset :: proc(self: ^AssetContext, asset_id: string) -> AssetContent {
	if asset, exists := self.assets[asset_id]; exists do return asset.content
	return nil
}

unload_asset :: proc(self: ^AssetContext, asset_id: string) {
	asset, exists := self.assets[asset_id]
	if !exists do return

	switch e in asset.content {
	case rl.Texture:
		log.debugf("unloading texture '%s' (id %d)...", asset_id, e.id)
		rl.UnloadTexture(e)
	case AnimationContext:
		log.debugf("unloading animation '%s'...", asset_id)
		rl.UnloadImage(e.image)
		rl.UnloadTexture(e.texture)
	case rl.Font:
		log.debugf("unloading font '%s'...", asset_id)
		rl.UnloadFont(e)
	}

	delete_key(&self.assets, asset_id)
}

delete_asset_context :: proc(self: ^AssetContext) {
	for asset in self.assets {
		unload_asset(self, asset)
		delete_string(asset)
	}
	// Force clear the animations
	delete_map(self.assets)
	self.assets = nil
}
