require('oil').setup({
  default_file_explorer = true,
  columns = { 'icon' },
  view_options = {
    show_hidden = true,
  },
  keymaps = {
    ['<2-LeftMouse>'] = 'actions.select',
  },
  watch_for_changes = true,
})

vim.keymap.set('n', '<leader>e', '<cmd>Oil<cr>', { desc = 'File explorer' })
vim.keymap.set('n', '-', '<cmd>Oil<cr>', { desc = 'Open parent directory' })

vim.api.nvim_create_autocmd('VimEnter', {
  desc = 'Open Oil when nvim is launched with no file arguments',
  callback = function()
    if vim.fn.argc() == 0 then
      require('oil').open()
      -- BufReadCmd won't fire here (v:vim_did_enter already 1) - force the load, mirroring oil's own workaround
      require('oil').load_oil_buffer(vim.api.nvim_get_current_buf())
    end
  end,
})
