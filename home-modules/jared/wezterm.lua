-- partially inspired by https://mwop.net/blog/2024-07-04-how-i-use-wezterm.html

local wezterm = require('wezterm')
local action = wezterm.action

local config = wezterm.config_builder()

config.automatically_reload_config = false
config.check_for_updates = false
config.color_scheme = 'Modus-Vivendi'
config.default_domain = 'local'
config.default_workspace = 'default'
config.enable_scroll_bar = true
config.font = wezterm.font('monospace')
config.front_end = 'WebGpu'
config.inactive_pane_hsb = { saturation = 0.7, brightness = 0.7 }
config.leader = { key = 's', mods = 'CTRL' }
config.switch_to_last_active_tab_when_closing_tab = true
config.tab_bar_at_bottom = true
config.unix_domains = { { name = 'unix' } }
config.use_dead_keys = false
config.use_fancy_tab_bar = false
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.disable_default_key_bindings = true

local last_active_workspace = { config.default_workspace, config.default_workspace }

wezterm.on('update-status', function(window, _)
  local status = {}
  if window:leader_is_active() then table.insert(status, { Text = '\xc2\xb7' .. ' ' }) end

  local active_key_table = window:active_key_table()
  if active_key_table ~= nil then table.insert(status, { Text = '[' .. active_key_table .. '] ' }) end

  local active_workspace = window:active_workspace()
  table.insert(status, { Text = active_workspace })
  window:set_right_status(wezterm.format(status))

  if last_active_workspace[1] ~= active_workspace then
    last_active_workspace[2] = last_active_workspace[1]
    last_active_workspace[1] = active_workspace
  end
end)

local switch_to_last_active_workspace = wezterm.action_callback(function(window, pane)
  _, _ = window, pane

  local current_workspace = wezterm.mux.get_active_workspace()

  local last_active_found = false
  for _, workspace in ipairs(wezterm.mux.get_workspace_names()) do
    if workspace == last_active_workspace[2] then
      last_active_found = true
      break
    end
  end

  if not last_active_found then
    wezterm.log_warn(string.format('workspace "%s" not found', last_active_workspace[2]))
    return
  end

  if last_active_workspace[2] == current_workspace then
    wezterm.log_info(string.format('workspace "%s" already active', current_workspace))
    return
  end

  wezterm.mux.set_active_workspace(last_active_workspace[2])

  last_active_workspace[2] = last_active_workspace[1]
  last_active_workspace[1] = current_workspace
end)

local rename_tab = action.PromptInputLine({
  description = 'Rename tab',
  action = wezterm.action_callback(function(window, _, line)
    if line then -- line is nil if user input is cancelled
      window:active_tab():set_title(line)
    end
  end),
})

local rename_workspace = action.PromptInputLine({
  description = 'Rename workspace',
  action = wezterm.action_callback(function(window, pane, line)
    _, _ = window, pane
    if line then -- line is nil if user input is cancelled
      wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
    end
  end),
})

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
local basename = function(s) return string.gsub(s, '(.*[/\\])(.*)', '%2') end

local select_project = wezterm.action_callback(function(outer_window, outer_pane)
  local choices = {}

  local projects_dir = (os.getenv('XDG_STATE_HOME') or (os.getenv('HOME') .. '/.local/state')) .. '/projects'
  for _, entry in ipairs(wezterm.glob(projects_dir .. '/*')) do
    table.insert(choices, { id = entry, label = basename(entry) })
  end

  outer_window:perform_action(
    action.InputSelector({
      action = wezterm.action_callback(function(window, pane, id, label)
        if not id and not label then
          return -- cancelled
        end

        for _, workspace in ipairs(wezterm.mux.get_workspace_names()) do
          if workspace == label then
            wezterm.mux.set_active_workspace(label)
            return
          end
        end

        window:perform_action(
          action.SwitchToWorkspace({
            name = label,
            spawn = { cwd = id },
          }),
          pane
        )
      end),
      fuzzy = true,
      title = 'Launch a project',
      choices = choices,
      alphabet = '123456789',
      description = 'Choose the project you want to launch in a workspace.',
    }),
    outer_pane
  )
end)

local activate_resize = action.ActivateKeyTable({
  name = 'resize_pane',
  one_shot = false,
})

local activate_passthru = action.Multiple({
  action.ClearKeyTableStack, -- ensure there are no other key tables in the stack
  action.ActivateKeyTable({
    name = 'passthru_mode',
    one_shot = false,
  }),
})

local show_workspaces = action.ShowLauncherArgs({ flags = 'WORKSPACES', title = 'workspaces' })
local clear_selection = action.Multiple({ action.ClearSelection, { CopyMode = 'ClearSelectionMode' } })
local copy_and_clear_selection = action.Multiple({
  { CopyTo = 'ClipboardAndPrimarySelection' },
  action.ClearSelection,
  { CopyMode = 'ClearSelectionMode' },
})

config.key_tables = {
  copy_mode = {
    -- { key = 'e', mods = 'CTRL', action = 'scroll viewport down' }, -- TODO(jared): implement this
    -- { key = 'y', mods = 'CTRL', action = 'scroll viewport up' }, -- TODO(jared): implement this
    { key = '$', mods = 'NONE', action = action.CopyMode('MoveToEndOfLineContent') },
    { key = '$', mods = 'SHIFT', action = action.CopyMode('MoveToEndOfLineContent') },
    { key = ',', mods = 'NONE', action = action.CopyMode('JumpReverse') },
    { key = '/', mods = 'NONE', action = action.CopyMode('EditPattern') },
    { key = '0', mods = 'NONE', action = action.CopyMode('MoveToStartOfLine') },
    { key = ';', mods = 'NONE', action = action.CopyMode('JumpAgain') },
    { key = 'DownArrow', mods = 'NONE', action = action.CopyMode('MoveDown') },
    { key = 'End', mods = 'NONE', action = action.CopyMode('MoveToEndOfLineContent') },
    { key = 'Enter', mods = 'NONE', action = action.CopyMode('MoveToStartOfNextLine') },
    { key = 'Escape', mods = 'NONE', action = clear_selection },
    { key = 'F', mods = 'NONE', action = action.CopyMode({ JumpBackward = { prev_char = false } }) },
    { key = 'F', mods = 'SHIFT', action = action.CopyMode({ JumpBackward = { prev_char = false } }) },
    { key = 'G', mods = 'NONE', action = action.CopyMode('MoveToScrollbackBottom') },
    { key = 'G', mods = 'SHIFT', action = action.CopyMode('MoveToScrollbackBottom') },
    { key = 'H', mods = 'NONE', action = action.CopyMode('MoveToViewportTop') },
    { key = 'H', mods = 'SHIFT', action = action.CopyMode('MoveToViewportTop') },
    { key = 'Home', mods = 'NONE', action = action.CopyMode('MoveToStartOfLine') },
    { key = 'L', mods = 'NONE', action = action.CopyMode('MoveToViewportBottom') },
    { key = 'L', mods = 'SHIFT', action = action.CopyMode('MoveToViewportBottom') },
    { key = 'LeftArrow', mods = 'ALT', action = action.CopyMode('MoveBackwardWord') },
    { key = 'LeftArrow', mods = 'NONE', action = action.CopyMode('MoveLeft') },
    { key = 'M', mods = 'NONE', action = action.CopyMode('MoveToViewportMiddle') },
    { key = 'M', mods = 'SHIFT', action = action.CopyMode('MoveToViewportMiddle') },
    { key = 'O', mods = 'NONE', action = action.CopyMode('MoveToSelectionOtherEndHoriz') },
    { key = 'O', mods = 'SHIFT', action = action.CopyMode('MoveToSelectionOtherEndHoriz') },
    { key = 'PageDown', mods = 'NONE', action = action.CopyMode('PageDown') },
    { key = 'PageUp', mods = 'NONE', action = action.CopyMode('PageUp') },
    { key = 'RightArrow', mods = 'ALT', action = action.CopyMode('MoveForwardWord') },
    { key = 'RightArrow', mods = 'NONE', action = action.CopyMode('MoveRight') },
    { key = 'Space', mods = 'NONE', action = action.CopyMode({ SetSelectionMode = 'Cell' }) },
    { key = 'T', mods = 'NONE', action = action.CopyMode({ JumpBackward = { prev_char = true } }) },
    { key = 'T', mods = 'SHIFT', action = action.CopyMode({ JumpBackward = { prev_char = true } }) },
    { key = 'Tab', mods = 'NONE', action = action.CopyMode('MoveForwardWord') },
    { key = 'Tab', mods = 'SHIFT', action = action.CopyMode('MoveBackwardWord') },
    { key = 'UpArrow', mods = 'NONE', action = action.CopyMode('MoveUp') },
    { key = 'V', mods = 'NONE', action = action.CopyMode({ SetSelectionMode = 'Line' }) },
    { key = 'V', mods = 'SHIFT', action = action.CopyMode({ SetSelectionMode = 'Line' }) },
    { key = '[', mods = 'CTRL', action = clear_selection },
    { key = '^', mods = 'NONE', action = action.CopyMode('MoveToStartOfLineContent') },
    { key = '^', mods = 'SHIFT', action = action.CopyMode('MoveToStartOfLineContent') },
    { key = 'b', mods = 'ALT', action = action.CopyMode('MoveBackwardWord') },
    { key = 'b', mods = 'CTRL', action = action.CopyMode('PageUp') },
    { key = 'b', mods = 'NONE', action = action.CopyMode('MoveBackwardWord') },
    { key = 'c', mods = 'CTRL', action = action.CopyMode('Close') },
    { key = 'd', mods = 'CTRL', action = action.CopyMode({ MoveByPage = 0.5 }) },
    { key = 'e', mods = 'NONE', action = action.CopyMode('MoveForwardWordEnd') },
    { key = 'f', mods = 'ALT', action = action.CopyMode('MoveForwardWord') },
    { key = 'f', mods = 'CTRL', action = action.CopyMode('PageDown') },
    { key = 'f', mods = 'NONE', action = action.CopyMode({ JumpForward = { prev_char = false } }) },
    { key = 'g', mods = 'CTRL', action = action.CopyMode('Close') },
    { key = 'g', mods = 'NONE', action = action.CopyMode('MoveToScrollbackTop') },
    { key = 'h', mods = 'NONE', action = action.CopyMode('MoveLeft') },
    { key = 'j', mods = 'NONE', action = action.CopyMode('MoveDown') },
    { key = 'k', mods = 'NONE', action = action.CopyMode('MoveUp') },
    { key = 'l', mods = 'NONE', action = action.CopyMode('MoveRight') },
    { key = 'm', mods = 'ALT', action = action.CopyMode('MoveToStartOfLineContent') },
    { key = 'o', mods = 'NONE', action = action.CopyMode('MoveToSelectionOtherEnd') },
    { key = 'q', mods = 'NONE', action = action.CopyMode('Close') },
    { key = 't', mods = 'NONE', action = action.CopyMode({ JumpForward = { prev_char = true } }) },
    { key = 'u', mods = 'CTRL', action = action.CopyMode({ MoveByPage = -0.5 }) },
    { key = 'v', mods = 'CTRL', action = action.CopyMode({ SetSelectionMode = 'Block' }) },
    { key = 'v', mods = 'NONE', action = action.CopyMode({ SetSelectionMode = 'Cell' }) },
    { key = 'w', mods = 'NONE', action = action.CopyMode('MoveForwardWord') },
    { key = 'y', mods = 'NONE', action = copy_and_clear_selection },
  },

  resize_pane = {
    { key = 'DownArrow', mods = 'NONE', action = action.AdjustPaneSize({ 'Down', 1 }) },
    { key = 'Escape', mods = 'NONE', action = action.PopKeyTable },
    { key = 'LeftArrow', mods = 'NONE', action = action.AdjustPaneSize({ 'Left', 1 }) },
    { key = 'RightArrow', mods = 'NONE', action = action.AdjustPaneSize({ 'Right', 1 }) },
    { key = 'UpArrow', mods = 'NONE', action = action.AdjustPaneSize({ 'Up', 1 }) },
    { key = '[', mods = 'CTRL', action = action.PopKeyTable },
    { key = 'h', mods = 'NONE', action = action.AdjustPaneSize({ 'Left', 1 }) },
    { key = 'j', mods = 'NONE', action = action.AdjustPaneSize({ 'Down', 1 }) },
    { key = 'k', mods = 'NONE', action = action.AdjustPaneSize({ 'Up', 1 }) },
    { key = 'l', mods = 'NONE', action = action.AdjustPaneSize({ 'Right', 1 }) },
    { key = 'r', mods = 'LEADER', action = action.PopKeyTable },
  },

  search_mode = {
    { key = 'DownArrow', mods = 'NONE', action = action.CopyMode('NextMatch') },
    { key = 'Enter', mods = 'NONE', action = action.CopyMode('PriorMatch') },
    { key = 'Escape', mods = 'NONE', action = action.CopyMode('Close') },
    { key = 'PageDown', mods = 'NONE', action = action.CopyMode('NextMatchPage') },
    { key = 'PageUp', mods = 'NONE', action = action.CopyMode('PriorMatchPage') },
    { key = 'UpArrow', mods = 'NONE', action = action.CopyMode('PriorMatch') },
    { key = 'n', mods = 'CTRL', action = action.CopyMode('NextMatch') },
    { key = 'p', mods = 'CTRL', action = action.CopyMode('PriorMatch') },
    { key = 'r', mods = 'CTRL', action = action.CopyMode('CycleMatchType') },
    { key = 'u', mods = 'CTRL', action = action.CopyMode('ClearPattern') },
  },
}

config.keys = {
  -- { key = "l", mods = "LEADER", action = switch_to_last_active_tab }, -- TODO(jared): implement this
  { key = '"', mods = 'LEADER|SHIFT', action = action.SplitVertical({ domain = 'CurrentPaneDomain' }) },
  { key = '$', mods = 'LEADER|SHIFT', action = rename_workspace },
  { key = '%', mods = 'LEADER|SHIFT', action = action.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
  { key = '&', mods = 'LEADER|SHIFT', action = action.CloseCurrentTab({ confirm = true }) },
  { key = '(', mods = 'LEADER|SHIFT', action = action.SwitchWorkspaceRelative(-1) },
  { key = ')', mods = 'CTRL', action = action.ResetFontSize },
  { key = ')', mods = 'LEADER|SHIFT', action = action.SwitchWorkspaceRelative(1) },
  { key = ')', mods = 'SHIFT|CTRL', action = action.ResetFontSize },
  { key = '+', mods = 'CTRL', action = action.IncreaseFontSize },
  { key = '+', mods = 'SHIFT|CTRL', action = action.IncreaseFontSize },
  { key = ',', mods = 'LEADER', action = rename_tab },
  { key = '-', mods = 'CTRL', action = action.DecreaseFontSize },
  { key = '-', mods = 'SHIFT|CTRL', action = action.DecreaseFontSize },
  { key = '-', mods = 'SUPER', action = action.DecreaseFontSize },
  { key = '/', mods = 'LEADER', action = action.Search('CurrentSelectionOrEmptyString') },
  { key = '0', mods = 'CTRL', action = action.ResetFontSize },
  { key = '0', mods = 'SHIFT|CTRL', action = action.ResetFontSize },
  { key = '0', mods = 'SUPER', action = action.ResetFontSize },
  { key = ';', mods = 'LEADER', action = action.ActivatePaneDirection('Prev') },
  { key = '=', mods = 'CTRL', action = action.IncreaseFontSize },
  { key = '=', mods = 'SHIFT|CTRL', action = action.IncreaseFontSize },
  { key = '=', mods = 'SUPER', action = action.IncreaseFontSize },
  { key = '?', mods = 'LEADER|SHIFT', action = action.ShowLauncher },
  { key = 'C', mods = 'CTRL', action = action.CopyTo('Clipboard') },
  { key = 'C', mods = 'SHIFT|CTRL', action = action.CopyTo('Clipboard') },
  { key = 'Copy', mods = 'NONE', action = action.CopyTo('Clipboard') },
  { key = 'Insert', mods = 'CTRL', action = action.CopyTo('PrimarySelection') },
  { key = 'Insert', mods = 'SHIFT', action = action.PasteFrom('PrimarySelection') },
  { key = 'Paste', mods = 'NONE', action = action.PasteFrom('Clipboard') },
  { key = 'V', mods = 'CTRL', action = action.PasteFrom('Clipboard') },
  { key = 'V', mods = 'SHIFT|CTRL', action = action.PasteFrom('Clipboard') },
  { key = '[', mods = 'LEADER', action = wezterm.action.ActivateCopyMode },
  { key = ']', mods = 'LEADER', action = action.PasteFrom('Clipboard') },
  { key = '_', mods = 'CTRL', action = action.DecreaseFontSize },
  { key = '_', mods = 'SHIFT|CTRL', action = action.DecreaseFontSize },
  { key = 'c', mods = 'LEADER', action = action.SpawnTab('CurrentPaneDomain') },
  { key = 'c', mods = 'SHIFT|CTRL', action = action.CopyTo('Clipboard') },
  { key = 'c', mods = 'SUPER', action = action.CopyTo('Clipboard') },
  { key = 'd', mods = 'LEADER', action = action.DetachDomain({ DomainName = 'unix' }) },
  { key = 'd', mods = 'LEADER|SHIFT', action = action.ShowDebugOverlay },
  { key = 'j', mods = 'LEADER', action = select_project },
  { key = 'l', mods = 'LEADER|SHIFT', action = switch_to_last_active_workspace },
  { key = 'n', mods = 'LEADER', action = action.ActivateTabRelative(1) },
  { key = 'o', mods = 'LEADER', action = action.ActivatePaneDirection('Next') },
  { key = 'p', mods = 'LEADER', action = action.ActivateTabRelative(-1) },
  { key = 'p', mods = 'LEADER|SHIFT', action = activate_passthru },
  { key = 'r', mods = 'LEADER|SHIFT', action = activate_resize },
  { key = 'v', mods = 'SHIFT|CTRL', action = action.PasteFrom('Clipboard') },
  { key = 'v', mods = 'SUPER', action = action.PasteFrom('Clipboard') },
  { key = 'w', mods = 'LEADER', action = show_workspaces },
  { key = 'x', mods = 'LEADER', action = action.CloseCurrentPane({ confirm = true }) },
  { key = 'z', mods = 'LEADER', action = action.TogglePaneZoomState },
  { key = config.leader.key, mods = 'LEADER|CTRL', action = action.SendKey(config.leader) },

  -- some defaults keys:
  -- { key = "F",          mods = "CTRL",           action = action.Search "CurrentSelectionOrEmptyString" },
  -- { key = "F",          mods = "SHIFT|CTRL",     action = action.Search "CurrentSelectionOrEmptyString" },
  -- { key = "K",          mods = "CTRL",           action = action.ClearScrollback "ScrollbackOnly" },
  -- { key = "K",          mods = "SHIFT|CTRL",     action = action.ClearScrollback "ScrollbackOnly" },
  -- { key = "N",          mods = "CTRL",           action = action.SpawnWindow },
  -- { key = "N",          mods = "SHIFT|CTRL",     action = action.SpawnWindow },
  -- { key = "P",          mods = "CTRL",           action = action.ActivateCommandPalette },
  -- { key = "P",          mods = "SHIFT|CTRL",     action = action.ActivateCommandPalette },
  -- { key = "R",          mods = "CTRL",           action = action.ReloadConfiguration },
  -- { key = "R",          mods = "SHIFT|CTRL",     action = action.ReloadConfiguration },
  -- { key = "U",          mods = "CTRL",           action = action.CharSelect { copy_on_select = true, copy_to = "ClipboardAndPrimarySelection" } },
  -- { key = "U",          mods = "SHIFT|CTRL",     action = action.CharSelect { copy_on_select = true, copy_to = "ClipboardAndPrimarySelection" } },
  -- { key = "W",          mods = "CTRL",           action = action.CloseCurrentTab { confirm = true } },
  -- { key = "W",          mods = "SHIFT|CTRL",     action = action.CloseCurrentTab { confirm = true } },
  -- { key = "f",          mods = "SHIFT|CTRL",     action = action.Search "CurrentSelectionOrEmptyString" },
  -- { key = "f",          mods = "SUPER",          action = action.Search "CurrentSelectionOrEmptyString" },
  -- { key = "k",          mods = "SHIFT|CTRL",     action = action.ClearScrollback "ScrollbackOnly" },
  -- { key = "p",          mods = "SHIFT|CTRL",     action = action.ActivateCommandPalette },
  -- { key = "u",          mods = "SHIFT|CTRL",     action = action.CharSelect { copy_on_select = true, copy_to = "ClipboardAndPrimarySelection" } },
  -- { key = "phys:Space", mods = "SHIFT|CTRL",     action = action.QuickSelect },
  -- { key = "PageUp",     mods = "SHIFT",          action = action.ScrollByPage(-1) },
  -- { key = "PageUp",     mods = "CTRL",           action = action.ActivateTabRelative(-1) },
  -- { key = "PageUp",     mods = "SHIFT|CTRL",     action = action.MoveTabRelative(-1) },
  -- { key = "PageDown",   mods = "SHIFT",          action = action.ScrollByPage(1) },
  -- { key = "PageDown",   mods = "CTRL",           action = action.ActivateTabRelative(1) },
  -- { key = "PageDown",   mods = "SHIFT|CTRL",     action = action.MoveTabRelative(1) },
  -- { key = "LeftArrow",  mods = "SHIFT|CTRL",     action = action.ActivatePaneDirection "Left" },
  -- { key = "LeftArrow",  mods = "SHIFT|ALT|CTRL", action = action.AdjustPaneSize { "Left", 1 } },
  -- { key = "RightArrow", mods = "SHIFT|CTRL",     action = action.ActivatePaneDirection "Right" },
  -- { key = "RightArrow", mods = "SHIFT|ALT|CTRL", action = action.AdjustPaneSize { "Right", 1 } },
  -- { key = "UpArrow",    mods = "SHIFT|CTRL",     action = action.ActivatePaneDirection "Up" },
  -- { key = "UpArrow",    mods = "SHIFT|ALT|CTRL", action = action.AdjustPaneSize { "Up", 1 } },
  -- { key = "DownArrow",  mods = "SHIFT|CTRL",     action = action.ActivatePaneDirection "Down" },
  -- { key = "DownArrow",  mods = "SHIFT|ALT|CTRL", action = action.AdjustPaneSize { "Down", 1 } },
}

for i = 1, 9 do
  -- LEADER + number to activate that tab
  table.insert(config.keys, {
    key = tostring(i),
    mods = 'LEADER',
    action = action.ActivateTab(i - 1),
  })
end

-- Define a special mode that passes all keys through to the terminal.
local passthru_mode_keys = {}

for _, key in ipairs(config.keys) do
  table.insert(
    passthru_mode_keys,
    { key = key.key, mods = key.mods or 'NONE', action = action.DisableDefaultAssignment }
  )
end

table.insert(passthru_mode_keys, { key = 'p', mods = 'LEADER|SHIFT', action = action.PopKeyTable })

config.key_tables.passthru_mode = passthru_mode_keys

return config
