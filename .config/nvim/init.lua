vim.opt.termguicolors = true
vim.opt.clipboard = "unnamedplus"
vim.g.mapleader = " "

vim.wo.number = true

vim.keymap.set('n', '<Tab>', ':bn<CR>')
vim.keymap.set('n', '<S-Tab>', ':bp<CR>')
vim.keymap.set('n', '<C-s>', '"*p', { noremap = true, silent = true })
vim.keymap.set('n', 'cl', ':let @/ = ""<CR>')


vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"


require("config.lazy")
require ('nvim-treesitter')

require("mason").setup()
require("mason-lspconfig").setup()


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



vim.lsp.set_log_level("error")




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

