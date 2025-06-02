-- Pull in the wezterm API
local wezterm = require("wezterm")

local function file_exists(path)
	local f = io.open(path, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- Tmux-like
config.inactive_pane_hsb = {
	hue = 1.0,
	saturation = 1.0,
	brightness = 1.0,
}

config.leader = { key = "F8" }
config.disable_default_key_bindings = true
config.keys = {
	{ key = "F8", mods = "LEADER", action = wezterm.action.ShowLauncher },
	{ key = "-", mods = "LEADER", action = wezterm.action({ SplitVertical = { domain = "CurrentPaneDomain" } }) },
	{ key = "|", mods = "LEADER", action = wezterm.action({ SplitHorizontal = { domain = "CurrentPaneDomain" } }) },
	{ key = "v", mods = "LEADER", action = wezterm.action.ActivateCopyMode },
	{ key = "z", mods = "LEADER", action = "TogglePaneZoomState" },
	{ key = "c", mods = "LEADER", action = wezterm.action({ SpawnTab = "CurrentPaneDomain" }) },
	{ key = "h", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Left" }) },
	{ key = "j", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Down" }) },
	{ key = "k", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Up" }) },
	{ key = "l", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Right" }) },
	{ key = "H", mods = "LEADER|SHIFT", action = wezterm.action({ AdjustPaneSize = { "Left", 5 } }) },
	{ key = "J", mods = "LEADER|SHIFT", action = wezterm.action({ AdjustPaneSize = { "Down", 5 } }) },
	{ key = "K", mods = "LEADER|SHIFT", action = wezterm.action({ AdjustPaneSize = { "Up", 5 } }) },
	{ key = "L", mods = "LEADER|SHIFT", action = wezterm.action({ AdjustPaneSize = { "Right", 5 } }) },
	{ key = "1", mods = "LEADER", action = wezterm.action({ ActivateTab = 0 }) },
	{ key = "2", mods = "LEADER", action = wezterm.action({ ActivateTab = 1 }) },
	{ key = "3", mods = "LEADER", action = wezterm.action({ ActivateTab = 2 }) },
	{ key = "4", mods = "LEADER", action = wezterm.action({ ActivateTab = 3 }) },
	{ key = "5", mods = "LEADER", action = wezterm.action({ ActivateTab = 4 }) },
	{ key = "6", mods = "LEADER", action = wezterm.action({ ActivateTab = 5 }) },
	{ key = "7", mods = "LEADER", action = wezterm.action({ ActivateTab = 6 }) },
	{ key = "8", mods = "LEADER", action = wezterm.action({ ActivateTab = 7 }) },
	{ key = "9", mods = "LEADER", action = wezterm.action({ ActivateTab = 8 }) },
	{ key = "&", mods = "LEADER|SHIFT", action = wezterm.action({ CloseCurrentTab = { confirm = true } }) },
	{ key = "x", mods = "LEADER", action = wezterm.action({ CloseCurrentPane = { confirm = true } }) },

	{ key = "n", mods = "SHIFT|CTRL", action = "ToggleFullScreen" },
	{ key = "v", mods = "SHIFT|CTRL", action = wezterm.action.PasteFrom("Clipboard") },
	{ key = "c", mods = "SHIFT|CTRL", action = wezterm.action.CopyTo("Clipboard") },
	{ key = "+", mods = "SHIFT|CTRL", action = "IncreaseFontSize" },
	{ key = "-", mods = "SHIFT|CTRL", action = "DecreaseFontSize" },
	{ key = "0", mods = "SHIFT|CTRL", action = "ResetFontSize" },

	-- For forcing ctrl+space work on powershell
	{ key = " ", mods = "CTRL", action = wezterm.action.SendKey({ key = " ", mods = "CTRL" }) },
	-- Attach to muxer
	{ key = "a", mods = "LEADER", action = wezterm.action.AttachDomain("unix") },
	-- Detach from muxer
	{ key = "d", mods = "LEADER", action = wezterm.action.DetachDomain({ DomainName = "unix" }) },
}
config.set_environment_variables = {}

-- Sessions
config.unix_domains = {
	{
		name = "unix",
	},
}
-- This is where you actually apply your config choices
config.launch_menu = {}
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	-- config.term = "" -- Set to empty so FZF works on windows
	config.default_prog = { "pwsh.exe", "-NoLogo" }
	table.insert(config.launch_menu, { label = "Pwsh", args = { "pwsh.exe", "-NoLogo" } })
	table.insert(config.launch_menu, { label = "PowerShell", args = { "powershell.exe", "-NoLogo" } })

	-- Find installed visual studio version(s) and add their compilation
	-- environment command prompts to the menu
	for _, vsvers in ipairs(wezterm.glob("Microsoft Visual Studio/20*", "C:/Program Files (x86)")) do
		local year = vsvers:gsub("Microsoft Visual Studio/", "")
		table.insert(config.launch_menu, {
			label = "x64 Native Tools VS " .. year,
			args = {
				"cmd.exe",
				"/k",
				"C:/Program Files (x86)/" .. vsvers .. "/BuildTools/VC/Auxiliary/Build/vcvars64.bat",
			},
		})
	end
end
config.front_end = "WebGpu"
config.window_close_confirmation = "NeverPrompt"

config.window_padding = {
	left = 2,
	right = 2,
	top = 2,
	bottom = 0,
}

config.default_workspace = "~"
config.window_decorations = "RESIZE"
-- config.window_background_opacity = 0.97

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
config.color_scheme = "Catppuccin Macchiato (Gogh)"

config.show_update_window = true

-- Pluguins =================
wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm").apply_to_config(config)

-- Tab bar
wezterm.plugin.require("https://github.com/adriankarlen/bar.wezterm").apply_to_config(config, { position = "top" })
-- hide new tab button
config.colors.tab_bar.new_tab = { bg_color = "transparent", fg_color = config.colors.background }
config.colors.tab_bar.new_tab_hover = config.colors.tab_bar.new_tab
-- End Pluguins =============
-- and finally, return the configuration to wezterm
return config
