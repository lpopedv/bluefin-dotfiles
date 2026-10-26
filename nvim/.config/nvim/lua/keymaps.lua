vim.keymap.set('n', '<leader>wh', '<C-w>h', { desc = 'Move to left window' })
vim.keymap.set('n', '<leader>wj', '<C-w>j', { desc = 'Move to bottom window' })
vim.keymap.set('n', '<leader>wk', '<C-w>k', { desc = 'Move to top window' })
vim.keymap.set('n', '<leader>wl', '<C-w>l', { desc = 'Move to right window' })
vim.keymap.set('n', '<leader>wv', '<C-w>v', { desc = 'Vertical split' })
vim.keymap.set('n', '<leader>ws', '<C-w>s', { desc = 'Horizontal split' })
vim.keymap.set('n', '<leader>wH', '<C-w>H', { desc = 'Move window far left' })
vim.keymap.set('n', '<leader>wJ', '<C-w>J', { desc = 'Move window far bottom' })
vim.keymap.set('n', '<leader>wK', '<C-w>K', { desc = 'Move window far top' })
vim.keymap.set('n', '<leader>wL', '<C-w>L', { desc = 'Move window far right' })
vim.keymap.set('n', '<leader>q', '<cmd>q<cr>', { desc = 'Close window' })

vim.keymap.set({ 'n', 'i', 'v' }, '<C-s>', '<Esc><cmd>w<cr>', { desc = 'Save buffer' })
vim.keymap.set('n', '<leader>bn', '<cmd>enew<cr>', { desc = 'New buffer' })
vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<cr>', { desc = 'Delete buffer' })
vim.keymap.set('n', '<leader>r', function()
  vim.cmd('checktime')
  if vim.bo.filetype == 'oil' then
    require('oil.actions').refresh.callback({ force = true })
  end
  vim.notify('Buffers refreshed')
end, { desc = 'Refresh buffers from disk' })
vim.keymap.set('n', '<leader>fY', function()
  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':.')
  vim.fn.setreg('+', path)
  vim.notify('Copied: ' .. path)
end, { desc = 'Copy relative file path' })

vim.keymap.set('n', '<leader>fj', ':%!python3 -m json.tool<CR>', { desc = 'Format JSON' })

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<cr>', { desc = 'Clear search highlights' })

vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Show diagnostics' })

vim.keymap.set('n', '<leader>zo', 'zo', { desc = 'Open fold' })
vim.keymap.set('n', '<leader>zc', 'zc', { desc = 'Close fold' })
vim.keymap.set('n', '<leader>zO', 'zO', { desc = 'Open all folds recursively' })
vim.keymap.set('n', '<leader>zC', 'zC', { desc = 'Close all folds recursively' })

vim.keymap.set({ 'n', 'v' }, '<Tab>', '%', { desc = 'Jump to matching pair' })
vim.keymap.set('i', '<C-h>', '<Left>',  { desc = 'Move cursor left' })
vim.keymap.set('i', '<C-j>', '<Down>',  { desc = 'Move cursor down' })
vim.keymap.set('i', '<C-k>', '<Up>',    { desc = 'Move cursor up' })
vim.keymap.set('i', '<C-l>', '<Right>', { desc = 'Move cursor right' })

vim.keymap.set('n', '<leader>gg', function()
  vim.cmd.tabnew()
  vim.bo.bufhidden = 'wipe'
  vim.api.nvim_buf_set_name(0, 'lazygit')
  vim.fn.termopen('lazygit', {
    on_exit = function()
      vim.schedule(function()
        if vim.fn.tabpagenr('$') > 1 then
          vim.cmd.tabclose()
        else
          vim.cmd.enew()
        end
      end)
    end,
  })
  vim.cmd.startinsert()
end, { desc = 'Open lazygit' })

vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function() vim.highlight.on_yank() end,
})
