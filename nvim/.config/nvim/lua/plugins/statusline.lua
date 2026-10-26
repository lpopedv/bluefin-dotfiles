local M = {}

local NORMAL = { icon = '󰇀', hl = 'MiniStatuslineModeNormal' }
local INSERT = { icon = '', hl = 'MiniStatuslineModeInsert' }
local VISUAL = { icon = '󰈈', hl = 'MiniStatuslineModeVisual' }
local SELECT = { icon = '', hl = 'MiniStatuslineModeOther' }
local REPLACE = { icon = '󰑐', hl = 'MiniStatuslineModeReplace' }
local COMMAND = { icon = '', hl = 'MiniStatuslineModeCommand' }
local PENDING = { icon = '', hl = 'MiniStatuslineModeOther' }
local PROMPT = { icon = '', hl = 'MiniStatuslineModeOther' }
local SHELL = { icon = '', hl = 'MiniStatuslineModeOther' }
local TERMINAL = { icon = '', hl = 'MiniStatuslineModeOther' }

local CTRL_V, CTRL_S = '\22', '\19'

-- every value `mode()` can return, per :help mode()
local mode_map = {
  n = vim.tbl_extend('force', NORMAL, { label = 'NORMAL' }),
  niI = vim.tbl_extend('force', NORMAL, { label = 'NORMAL' }),
  niR = vim.tbl_extend('force', NORMAL, { label = 'NORMAL' }),
  niV = vim.tbl_extend('force', NORMAL, { label = 'NORMAL' }),
  nt = vim.tbl_extend('force', NORMAL, { label = 'NORMAL' }),
  ntT = vim.tbl_extend('force', NORMAL, { label = 'NORMAL' }),

  no = vim.tbl_extend('force', PENDING, { label = 'O-PENDING' }),
  nov = vim.tbl_extend('force', PENDING, { label = 'O-PENDING' }),
  noV = vim.tbl_extend('force', PENDING, { label = 'O-PENDING' }),
  ['no' .. CTRL_V] = vim.tbl_extend('force', PENDING, { label = 'O-PENDING' }),

  v = vim.tbl_extend('force', VISUAL, { label = 'VISUAL' }),
  vs = vim.tbl_extend('force', VISUAL, { label = 'VISUAL' }),
  V = vim.tbl_extend('force', VISUAL, { label = 'V-LINE' }),
  Vs = vim.tbl_extend('force', VISUAL, { label = 'V-LINE' }),
  [CTRL_V] = vim.tbl_extend('force', VISUAL, { label = 'V-BLOCK' }),
  [CTRL_V .. 's'] = vim.tbl_extend('force', VISUAL, { label = 'V-BLOCK' }),

  s = vim.tbl_extend('force', SELECT, { label = 'SELECT' }),
  S = vim.tbl_extend('force', SELECT, { label = 'S-LINE' }),
  [CTRL_S] = vim.tbl_extend('force', SELECT, { label = 'S-BLOCK' }),

  i = vim.tbl_extend('force', INSERT, { label = 'INSERT' }),
  ic = vim.tbl_extend('force', INSERT, { label = 'INSERT' }),
  ix = vim.tbl_extend('force', INSERT, { label = 'INSERT' }),

  R = vim.tbl_extend('force', REPLACE, { label = 'REPLACE' }),
  Rc = vim.tbl_extend('force', REPLACE, { label = 'REPLACE' }),
  Rx = vim.tbl_extend('force', REPLACE, { label = 'REPLACE' }),
  Rv = vim.tbl_extend('force', REPLACE, { label = 'V-REPLACE' }),
  Rvc = vim.tbl_extend('force', REPLACE, { label = 'V-REPLACE' }),
  Rvx = vim.tbl_extend('force', REPLACE, { label = 'V-REPLACE' }),

  c = vim.tbl_extend('force', COMMAND, { label = 'COMMAND' }),
  cv = vim.tbl_extend('force', COMMAND, { label = 'EX' }),
  ce = vim.tbl_extend('force', COMMAND, { label = 'EX' }),

  r = vim.tbl_extend('force', PROMPT, { label = 'PROMPT' }),
  rm = vim.tbl_extend('force', PROMPT, { label = 'MORE' }),
  ['r?'] = vim.tbl_extend('force', PROMPT, { label = 'CONFIRM' }),

  ['!'] = vim.tbl_extend('force', SHELL, { label = 'SHELL' }),
  t = vim.tbl_extend('force', TERMINAL, { label = 'TERMINAL' }),
}

local function mode()
  local m = vim.api.nvim_get_mode().mode
  local info = mode_map[m] or { icon = '󰇀', label = m:upper(), hl = 'MiniStatuslineModeOther' }
  return string.format('%%#%s# %s %s %%*', info.hl, info.icon, info.label)
end

vim.o.showmode = false

vim.api.nvim_create_autocmd('ModeChanged', {
  group = vim.api.nvim_create_augroup('my.statusline.mode', {}),
  callback = function() vim.cmd.redrawstatus() end,
})

local function refresh_git_branch()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= '' then return end

  local dir = vim.fn.expand('%:p:h')
  if vim.fn.isdirectory(dir) == 0 then return end

  vim.system(
    { 'git', 'branch', '--show-current' },
    { cwd = dir, text = true },
    function(res)
      if res.code ~= 0 then return end
      local branch = vim.trim(res.stdout)
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.b[buf].git_branch = branch
          vim.cmd.redrawstatus()
        end
      end)
    end
  )
end

vim.api.nvim_create_autocmd({ 'BufEnter', 'FocusGained', 'DirChanged' }, {
  group = vim.api.nvim_create_augroup('my.statusline.git', {}),
  callback = refresh_git_branch,
})

local function git_branch()
  local branch = vim.b.git_branch
  return (branch and branch ~= '') and (' %#Comment#  ' .. branch .. '%*') or ''
end

local diagnostic_icons = {
  { vim.diagnostic.severity.ERROR, '', '%#DiagnosticError#' },
  { vim.diagnostic.severity.WARN, '', '%#DiagnosticWarn#' },
  { vim.diagnostic.severity.INFO, '', '%#DiagnosticInfo#' },
  { vim.diagnostic.severity.HINT, '', '%#DiagnosticHint#' },
}

local function diagnostics()
  local counts = vim.diagnostic.count(0)
  local parts = {}
  for _, d in ipairs(diagnostic_icons) do
    local n = counts[d[1]]
    if n and n > 0 then
      table.insert(parts, string.format('%s%s %d%%*', d[3], d[2], n))
    end
  end
  return #parts > 0 and (table.concat(parts, ' ') .. ' ') or ''
end

local function lsp_clients()
  local names = vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({ bufnr = 0 }))
  return #names > 0 and ('│ %#Comment# ' .. table.concat(names, ',') .. '%*') or ''
end

local has_devicons, devicons = pcall(require, 'nvim-web-devicons')

local function filetype()
  local ft = vim.bo.filetype
  if ft == '' then return '' end
  if has_devicons then
    local icon, hl = devicons.get_icon_by_filetype(ft, { default = true })
    if icon then
      return string.format(' %%#%s#%s %%*%s', hl, icon, ft)
    end
  end
  return ' ' .. ft
end

function M.render()
  return table.concat({
    ' ', mode(),
    ' %<%f %h%m%r',
    git_branch(),
    '%=',
    diagnostics(),
    lsp_clients(),
    ' │', filetype(),
    ' │ %-14.(%l,%c%V%) %P ',
  })
end

vim.o.laststatus = 3
vim.o.statusline = "%{%v:lua.require('plugins.statusline').render()%}"

return M
