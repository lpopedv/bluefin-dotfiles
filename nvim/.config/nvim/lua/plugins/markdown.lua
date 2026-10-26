require('render-markdown').setup({
  file_types = { 'markdown' },
})

-- Cursor-line anti-conceal always un-conceals table cell padding (not
-- covered by anti_conceal.ignore), breaking alignment. Disable it only
-- while inside a pipe_table, via render-markdown's internal buffer cache.
local rm_state = require('render-markdown.state')

local function in_table()
  local node = vim.treesitter.get_node()
  while node do
    if node:type() == 'pipe_table' then
      return true
    end
    node = node:parent()
  end
  return false
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function(args)
    if vim.b[args.buf].rm_table_fix then
      return
    end
    vim.b[args.buf].rm_table_fix = true
    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      buffer = args.buf,
      callback = function()
        local cfg = rm_state.cache[args.buf]
        if cfg then
          cfg.anti_conceal.enabled = not in_table()
        end
      end,
    })
  end,
})
