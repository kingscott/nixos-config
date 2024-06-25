{ sources }:
''
"--------------------------------------------------------------------
" Fix vim paths so we load the vim-misc directory
let g:vim_home_path = "~/.vim"

" This works on NixOS 21.05
let vim_misc_path = split(&packpath, ",")[0] . "/pack/home-manager/start/vim-misc/vimrc.vim"
if filereadable(vim_misc_path)
  execute "source " . vim_misc_path
endif

" This works on NixOS 21.11
let vim_misc_path = split(&packpath, ",")[0] . "/pack/home-manager/start/vimplugin-vim-misc/vimrc.vim"
if filereadable(vim_misc_path)
  execute "source " . vim_misc_path
endif

" This works on NixOS 22.11
let vim_misc_path = split(&packpath, ",")[0] . "/pack/myNeovimPackages/start/vimplugin-vim-misc/vimrc.vim"
if filereadable(vim_misc_path)
  execute "source " . vim_misc_path
endif

colorscheme rose-pine

lua <<EOF
---------------------------------------------------------------------
-- Append local parsers dir to nvim
vim.opt.runtimepath:append("$HOME/.local/nvim/parsers")

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
-- LSP zero
local lsp_zero = require('lsp-zero')

lsp_zero.on_attach(function(client, bufnr)
  local opts = {buffer = bufnr, remap = false}

  vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
  vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
  vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
  vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
  vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
  vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
  vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
  vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
  vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
  vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
end)

-- to learn how to use mason.nvim with lsp-zero
-- read this: https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guides/integrate-with-mason-nvim.md
require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {'eslint', 'tsserver', 'rust_analyzer'},
  handlers = {
    lsp_zero.default_setup,
    lua_ls = function()
      local lua_opts = lsp_zero.nvim_lua_ls()
      require('lspconfig').lua_ls.setup(lua_opts)
    end,
  }
})

local cmp = require('cmp')
local cmp_select = {behavior = cmp.SelectBehavior.Select}

-- this is the function that loads the extra snippets to luasnip
-- from rafamadriz/friendly-snippets
require('luasnip.loaders.from_vscode').lazy_load()

cmp.setup({
  sources = {
    {name = 'path'},
    {name = 'nvim_lsp'},
    {name = 'nvim_lua'},
    {name = 'luasnip', keyword_length = 2},
    {name = 'buffer', keyword_length = 3},
  },
  formatting = lsp_zero.cmp_format(),
  mapping = cmp.mapping.preset.insert({
    ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
    ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
    ['<C-Space>'] = cmp.mapping.complete(),
  }),
})


---------------------------------------------------------------------
-- Add our custom treesitter config
require('nvim-treesitter.configs').setup {
  -- A list of parser names, or "all" (the five listed parsers should always be installed)
  ensure_installed = { "javascript", "css", "go", "php", "lua", "vim", "vimdoc", "query", "rust", "vim", "vimdoc", },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = false,

  -- List of parsers to ignore installing (or "all")
  --  ignore_install = { "javascript" },

  ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
  parser_install_dir = "$HOME/.local/nvim/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

  highlight = {
    enable = true,

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
}


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

---------------------------------------------------------------------
-- File-specific indentation

vim.cmd([[
	autocmd FileType html setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
	autocmd FileType css setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
	autocmd FileType javascript setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
	autocmd FileType typescript setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
	autocmd FileType go setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4
	autocmd FileType rust setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4
	autocmd FileType lua setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
	autocmd FileType nix setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
	autocmd FileType json setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
]])

EOF
''
