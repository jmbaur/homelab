-- Bring in desired functionality from vim-rsi (https://github.com/tpope/vim-rsi).

local transpose = function()
	local pos = vim.fn.getcmdpos()

	-- Not in command mode, shouldn't happen.
	if pos == 0 then
		return
	end

	-- Shells don't perform transposition when the cursor is all the way to the
	-- left.
	if pos == 1 then
		return
	end

	-- TODO(jared): vim-rsi has this condition that honestly feels like a bug.
	-- We want to always do the transposition when in command mode.
	-- local cmdtype = vim.fn.getcmdtype()
	--
	-- if cmdtype == "?" or cmdtype == "/" then
	-- 	return "<C-t>"
	-- end

	local pre = ""

	local cmdline = vim.fn.getcmdline()

	if pos > string.len(cmdline) then
		pre = "<Left>"
		pos = pos - 1
	elseif pos <= 1 then
		pre = "<Right>"
		pos = pos + 1
	end

	return pre .. "<BS><Right>" .. vim.fn.matchstr(string.sub(cmdline, 1, pos - 1), ".$")
end

local move_right = function()
	return vim.fn.getcmdpos() > #vim.fn.getcmdline() and vim.opt_local.cedit:get() or "<Right>"
end

local delete_right = function()
	if vim.fn.getcmdpos() > #vim.fn.getcmdline() then
		return "<C-d>"
	else
		return "<Del>"
	end
end

-- vim.keymap.set("c", "<C-k>", TODO)
vim.keymap.set("c", "<C-a>", "<Home>")
vim.keymap.set("c", "<C-b>", "<Left>")
vim.keymap.set("c", "<C-d>", delete_right, { expr = true })
vim.keymap.set("c", "<C-e>", "<End>")
vim.keymap.set("c", "<C-f>", move_right, { expr = true })
vim.keymap.set("c", "<C-t>", transpose, { expr = true })
vim.keymap.set("c", "<C-x><C-a>", "<C-a>")
