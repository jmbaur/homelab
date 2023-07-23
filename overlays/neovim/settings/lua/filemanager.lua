require("mini.files").setup({ content = { prefix = function() end } })

vim.keymap.set("n", "-", MiniFiles.open, { desc = "Open parent directory" })

local show_dotfiles = false
local filter_show = function(fs_entry)
	return true
end

local filter_hide = function(fs_entry)
	return not vim.startswith(fs_entry.name, ".")
end

local toggle_dotfiles = function()
	show_dotfiles = not show_dotfiles
	local new_filter = show_dotfiles and filter_show or filter_hide
	MiniFiles.refresh({ content = { filter = new_filter } })
end

vim.api.nvim_create_autocmd("User", {
	pattern = "MiniFilesBufferCreate",
	callback = function(args)
		local buf_id = args.data.buf_id
		-- Tweak left-hand side of mapping to your liking
		vim.keymap.set("n", "g.", toggle_dotfiles, { buffer = buf_id })
	end,
})

local files_set_cwd = function(path)
	-- Works only if cursor is on the valid file system entry
	local cur_entry_path = MiniFiles.get_fs_entry().path
	local cur_directory = vim.fs.dirname(cur_entry_path)
	vim.fn.chdir(cur_directory)
end

vim.api.nvim_create_autocmd("User", {
	pattern = "MiniFilesBufferCreate",
	callback = function(args)
		vim.keymap.set("n", "g~", files_set_cwd, { buffer = args.data.buf_id })
	end,
})
