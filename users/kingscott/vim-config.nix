{ sources }:
''
colorscheme rose-pine

lua <<EOF
---------------------------------------------------------------------
-- Remap keys for less keystrokes
vim.g.mapleader = " "
vim.keymap.set("n", ";", ":")
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

---------------------------------------------------------------------
-- Standard formatting
vim.opt.guicursor = ""
vim.opt.nu = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

---------------------------------------------------------------------
-- Fugitive formatting
vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
vim.keymap.set("n", "<leader>gb", function ()
	vim.cmd.Git('blame')
end)

---------------------------------------------------------------------
-- Gitsigns config
require('gitsigns').setup()
vim.keymap.set("n", "<leader>gp", function()
	vim.cmd.Gitsigns("preview_hunk")
end)
vim.keymap.set("n", "<leader>rh", function() 
	vim.cmd.Gitsigns("reset_hunk")
end)
vim.keymap.set("n", "<leader>glb", function() 
	vim.cmd.Gitsigns("toggle_current_line_blame")
end)

---------------------------------------------------------------------
-- Harpoon config
local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

vim.keymap.set("n", "<leader>a", mark.add_file)
vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)

vim.keymap.set("n", "<C-h>", function() ui.nav_file(1) end)
vim.keymap.set("n", "<C-t>", function() ui.nav_file(2) end)  
vim.keymap.set("n", "<C-n>", function() ui.nav_file(3) end)  
vim.keymap.set("n", "<C-s>", function() ui.nav_file(4) end)  

---------------------------------------------------------------------
-- Add our custom treesitter config

---------------------------------------------------------------------
-- add telescope config
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>ps', function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") });
end)

---------------------------------------------------------------------
-- add undotree config
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)


---------------------------------------------------------------------
-- Alphavim config

local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")

-- Set the kingscott dragon of flames
-- TODO

-- Send config to alpha
alpha.setup(dashboard.opts)

vim.cmd([[
    autocmd FileType alpha setlocal nofoldenable
]])


EOF
''
