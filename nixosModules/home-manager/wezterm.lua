local wezterm = require("wezterm")

local mouse_bindings = {
	{
		event = { Down = { streak = 1, button = "Left" } },
		mods = "CTRL|SHIFT",
		action = wezterm.action.SelectTextAtMouseCursor("Block"),
	},
	{
		event = { Drag = { streak = 1, button = "Left" } },
		mods = "CTRL|SHIFT",
		action = wezterm.action.ExtendSelectionToMouseCursor("Block"),
	},
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL|SHIFT",
		action = wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"),
	},
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
}

for streak in ipairs({ 1, 2, 3 }) do
	table.insert(mouse_bindings, {
		event = { Up = { streak = streak, button = "Left" } },
		mods = "NONE",
		action = wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"),
	})
end

return {
	adjust_window_size_when_changing_font_size = false,
	audible_bell = "Disabled",
	automatically_reload_config = false,
	font = wezterm.font("JetBrains Mono"),
	font_size = 16.0,
	force_reverse_video_cursor = true,
	hide_tab_bar_if_only_one_tab = true,
	mouse_bindings = mouse_bindings,
	use_fancy_tab_bar = false,
	window_padding = { left = 0, right = 0, top = 0, bottom = 0 },
	colors = {
		foreground = "#ffffff",
		background = "#000000",
		selection_bg = "#fafad2",
		selection_fg = "#000000",
		ansi = { "#000000", "#ff8059", "#44bc44", "#d0bc00", "#2fafff", "#feacd0", "#00d3d0", "#bfbfbf" },
		brights = { "#595959", "#ef8b50", "#70b900", "#c0c530", "#79a8ff", "#b6a0ff", "#6ae4b9", "#ffffff" },
	},
}
