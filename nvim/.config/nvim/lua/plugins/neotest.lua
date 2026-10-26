require('neotest').setup({
  adapters = {
    require('neotest-elixir'),
  },
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'elixir',
  callback = function(ev)
    local neotest = require('neotest')

    local function alt_file()
      local path = vim.fn.expand('%:p')
      if path:match('/test/.+_test%.exs$') then
        return (path:gsub('/test/', '/lib/'):gsub('_test%.exs$', '.ex'))
      elseif path:match('/lib/.+%.ex$') then
        return (path:gsub('/lib/', '/test/'):gsub('%.ex$', '_test.exs'))
      end
    end

    local function open_alt(split_cmd)
      local target = alt_file()
      if not target then
        vim.notify('File does not match the lib/*.ex <-> test/*_test.exs pattern', vim.log.levels.WARN)
        return
      end
      vim.cmd(split_cmd .. ' ' .. vim.fn.fnameescape(target))
    end

    local map = function(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, { buffer = ev.buf, desc = desc })
    end

    local ok_wk, wk = pcall(require, 'which-key')
    if ok_wk then
      wk.add({ '<leader>t', group = 'Tests (Elixir)', icon = { icon = '󰙨 ', color = 'red' }, buffer = ev.buf })
    end

    map('<leader>tt', function() neotest.run.run() end, 'Run nearest test')
    map('<leader>tf', function() neotest.run.run(vim.fn.expand('%')) end, 'Run mix test on this file')
    map('<leader>ta', function() neotest.run.run(vim.fn.getcwd()) end, 'Run whole suite')
    map('<leader>tr', function() neotest.run.run_last() end, 'Rerun last test')
    map('<leader>tp', function() neotest.output_panel.toggle() end, 'Toggle output panel')
    map('<leader>tv', function() open_alt('vsplit') end, 'Open paired file (vsplit)')
    map('<leader>ts', function() open_alt('split') end, 'Open paired file (split)')

    map('<leader>td', function()
      local file = vim.fn.expand('%')
      local line = vim.fn.line('.')
      vim.cmd('botright split')
      vim.cmd('terminal mix test ' .. vim.fn.fnameescape(file) .. ':' .. line)
      vim.cmd('startinsert')
    end, 'Run nearest test in terminal (shows IO.puts)')
  end,
})
