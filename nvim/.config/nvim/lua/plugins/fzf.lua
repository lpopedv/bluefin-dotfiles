require('fzf-lua').setup({
  keymap = {
    builtin = {
      ['<C-d>'] = 'preview-page-down',
      ['<C-u>'] = 'preview-page-up',
    },
  },
})

vim.keymap.set('n', '<leader><leader>', '<cmd>FzfLua files<cr>',       { desc = 'Find files' })
vim.keymap.set('n', '<leader>/',        '<cmd>FzfLua live_grep<cr>',   { desc = 'Find live grep' })
vim.keymap.set('n', '<leader>sb',       '<cmd>FzfLua grep_curbuf<cr>', { desc = 'Search in buffer' })
vim.keymap.set('n', '<leader>bb',       '<cmd>FzfLua buffers<cr>',     { desc = 'Find buffers' })
