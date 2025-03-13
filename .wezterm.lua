-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

config.default_domain = "WSL:Arch"
config.front_end = "WebGpu"
config.window_close_confirmation = "NeverPrompt"

config.window_padding = {
	left = 2,
	right = 2,
	top = 2,
	bottom = 0,
}

config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.85

config.font = wezterm.font_with_fallback({
	-- { family = "Victor Mono", weight = "DemiBold" },
	"Fira Code Retina",
	-- "Cascadia Code",
	-- "JetBrains Mono",
	{ family = "Symbols Nerd Font Mono", scale = 0.75 },
	"Noto Color Emoji",
	"FiraCode NFM",
})
config.font_size = 10

-- For example, changing the color scheme:
config.color_scheme = "Catppuccin Macchiato"

config.show_update_window = true
-- and finally, return the configuration to wezterm
return config
