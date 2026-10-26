local wk = require('which-key')

wk.setup({
  preset = 'modern',
  delay = 300,
  icons = {
    mappings = true,
  },
  win = {
    border = 'rounded',
    padding = { 1, 2 },
    width = 0.3,
    height = { min = 4, max = 0.9 },
    row = 0,
    col = math.huge,
  },
  layout = {
    width = { min = 20 },
    spacing = 3,
  },
})

wk.add({
  { '<leader>w', group = 'Windows', icon = { icon = '󱂬 ', color = 'blue' } },
  { '<leader>b', group = 'Buffers', icon = { icon = '󰈔 ', color = 'yellow' } },
  { '<leader>f', group = 'Files', icon = { icon = '󰈞 ', color = 'green' } },
  { '<leader>g', group = 'Git', icon = { icon = '󰊢 ', color = 'orange' } },
  { '<leader>z', group = 'Folds', icon = { icon = '󰘖 ', color = 'cyan' } },
})
