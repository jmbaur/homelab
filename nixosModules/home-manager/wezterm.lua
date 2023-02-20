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

for _, streak in ipairs({ 1, 2, 3 }) do
	table.insert(mouse_bindings, {
		event = { Up = { streak = streak, button = "Left" } },
		mods = "NONE",
		action = wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"),
	})
end

local keys = {
	{ key = "l", mods = "SHIFT|CTRL", action = wezterm.action.ShowLauncher },
}

local ssh_domains = {
	{ name = "kale", remote_address = "kale.mgmt.home.arpa" },
	{ name = "okra", remote_address = "okra.trusted.home.arpa" },
	{ name = "work", remote_address = "dev.work.home.arpa", username = "jbaur" },
}

return {
	adjust_window_size_when_changing_font_size = false,
	audible_bell = "Disabled",
	automatically_reload_config = false,
	check_for_updates = false,
	color_scheme = "modus-vivendi",
	font = wezterm.font("JetBrains Mono"),
	font_size = 16.0,
	force_reverse_video_cursor = true,
	hide_tab_bar_if_only_one_tab = true,
	keys = keys,
	mouse_bindings = mouse_bindings,
	ssh_domains = ssh_domains,
	tab_bar_at_bottom = true,
	term = "wezterm",
	use_fancy_tab_bar = false,
	window_padding = { left = 0, right = 0, top = 0, bottom = 0 },
}
