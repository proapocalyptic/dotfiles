vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"
vim.g.mapleader = " "
vim.opt.shell = "/bin/zsh"
vim.wo.number = true

vim.keymap.set('n', '<Tab>', ':bn<CR>')
vim.keymap.set('n', '<S-Tab>', ':bp<CR>')
vim.keymap.set('n', '<C-s>', '"*p', { noremap = true, silent = true })
vim.keymap.set('n', 'cl', ':let @/ = ""<CR>')
vim.keymap.set('n', '<leader>o', '<cmd>Oil<CR>', { desc = 'Open oil' })


vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"


require("config.lazy")



-- Stop highlighting text after column 300 (safely covers HTML/CSS tags, drops Base64 strain)
vim.opt.synmaxcol = 300

require('mini.pairs').setup({})

	require('mini.cursorword').setup({})
	require('mini.icons').setup({})
	require('render-markdown')


	--autocommand to make sudoedit work
	vim.api.nvim_create_autocmd("BufRead", {
	  pattern = "/var/tmp/*",
	  callback = function()
	    vim.opt_local.backupcopy = "yes"
  end,
})

-- sort nvim directory view with symlinks first
vim.g.netrw_sort_sequence = [[[\/]$,@$,*]]



vim.lsp.log.set_level("error")





-- Allow closing Neovim or Oil windows gracefully without blocking on unsaved Oil buffers
local oil_group = vim.api.nvim_create_augroup("OilGracefulQuit", { clear = true })

-- When quitting Neovim, mark all oil buffers as unmodified so Neovim exits cleanly without error
vim.api.nvim_create_autocmd("ExitPre", {
  group = oil_group,
  callback = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "oil" then
        vim.bo[buf].modified = false
      end
    end
  end,
})

-- When closing an oil window with :q, mark it unmodified so it closes without error
vim.api.nvim_create_autocmd("QuitPre", {
  group = oil_group,
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].filetype == "oil" then
      vim.bo[buf].modified = false
    end
  end,
})

-- 2. Bind Ctrl + o to open the Oil buffer for the current directory
vim.keymap.set("n", "<C-o>", function()
  require("oil").open()
end, { desc = "Open Oil file manager" })

vim.keymap.set("n", "<C-S-o>", function()
  require("oil").open("~")
end, { desc = "Open Oil in home directory" })

-- Disable terminal suspension and remap jump-backward history to Ctrl + z to replicate remapped ctrl+0 functionality
vim.keymap.set("n", "<C-z>", "<C-o>", { desc = "Jump backward in history (Replaces native Ctrl+o)" })


require('lualine').setup {
      options = {
        icons_enabled = true,
        theme = 'auto',
        component_separators = { left = '', right = ''},
        section_separators = { left = '', right = ''},
        disabled_filetypes = {
          statusline = {},
          winbar = {},
        },
        ignore_focus = {},
        always_divide_middle = true,
        always_show_tabline = true,
        globalstatus = false,
        refresh = {
          statusline = 1000,
          tabline = 1000,
          winbar = 1000,
          refresh_time = 16, -- ~60fps
          events = {
            'WinEnter',
            'BufEnter',
            'BufWritePost',
            'SessionLoadPost',
            'FileChangedShellPost',
            'VimResized',
            'Filetype',
            'CursorMoved',
            'CursorMovedI',
            'ModeChanged',
          },
        }
      },
      sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {'filename'},
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {'filename'},
        lualine_x = {'location'},
        lualine_y = {},
        lualine_z = {}
      },
      tabline = {},
      winbar = {},
      inactive_winbar = {},
      extensions = {}
    }

