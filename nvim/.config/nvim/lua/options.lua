vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.o.mouse = 'a'
vim.o.relativenumber = true
vim.o.number = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.confirm = true
vim.o.ttimeoutlen = 1
vim.o.foldlevelstart = 99
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.softtabstop = 2
vim.o.signcolumn = 'yes'

vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

vim.o.autocomplete = true
vim.o.completeopt = 'menu,menuone,noselect,popup'

vim.diagnostic.config({
  severity_sort = true,
  update_in_insert = false,
  float = { source = 'if_many' },
  jump = { float = true },
})
