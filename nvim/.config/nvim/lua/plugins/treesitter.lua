require('nvim-treesitter').install({ 'lua', 'typescript', 'elixir', 'markdown', 'markdown_inline', 'prisma' })

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'lua', 'typescript', 'elixir', 'markdown', 'prisma' },
  callback = function() pcall(vim.treesitter.start) end,
})
