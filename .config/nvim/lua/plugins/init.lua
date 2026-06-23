return {
    {
        "nvim-treesitter/nvim-treesitter",
        tag = "v0.9.3",
        build = ":TSUpdate",
        config = function()
           require("nvim-treesitter.configs").setup({
                ensure_installed = { "lua", "markdown" },
                highlight = { enable = true },
            })
        end
    },
    { "norcalli/nvim-colorizer.lua", config = function()
        require("colorizer").setup()
    end },
{
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' }
},


    {
    "folke/tokyonight.nvim",
    lazy     = false,
    priority = 1000,
    transparent = true,
    config = function()
        vim.cmd("colorscheme tokyonight-night")
    end
},
{
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        require("bufferline").setup({})
    end
},

{
    "hrsh7th/nvim-cmp",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
    },
    config = function()
        local cmp = require("cmp")
        cmp.setup({
            mapping = cmp.mapping.preset.insert({
                ["<C-Space>"] = cmp.mapping.complete(),
                ["<CR>"] = cmp.mapping.confirm({ select = true }),
                ["<Tab>"] = cmp.mapping.select_next_item(),
                ["<S-Tab>"] = cmp.mapping.select_prev_item(),
            }),
            sources = {
                { name = "nvim_lsp" },
                { name = "buffer" },
                { name = "path" },
            },

    
        })
    end
},

{ 'nvim-mini/mini.nvim', version = false },
{
  "mbbill/undotree",
  cmd = "UndotreeToggle",
  keys = {
    { "<leader>u", "<cmd>UndotreeToggleCR", desc = "Undotree" },
  },
},
{
  "xiyaowong/transparent.nvim",
  lazy = false, -- Recommended to avoid flickering or loading after the colorscheme
  config = function()
    require("transparent").setup({
      -- Optional: add extra groups you want to make transparent
      extra_groups = {
        "NormalFloat", 
        "NvimTreeNormal",
      },
      -- Optional: exclude specific groups from being transparent
      exclude_groups = {},
    })
  end
},


{
    "kylechui/nvim-surround",
    version = "^4.0.0", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
},

{
    "mason-org/mason.nvim",
    opts = {}
},

{
    "mason-org/mason-lspconfig.nvim",
    opts = {},
    dependencies = {
        { "mason-org/mason.nvim", opts = {} },
    },
},

{
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' },            -- if you use the mini.nvim suite
    opts = {},
},

{
    "tris203/precognition.nvim",
    --event = "VeryLazy",
    opts = {
    -- startVisible = true,
    -- debounceMs = 0,
    -- showBlankVirtLine = true,
    -- highlightFullVirtLine = false,
    -- highlightColor = { link = "Comment" },
    -- targetedMotionHighlightColor = { link = "PrecognitionTargetedMotionDefault" },
     textObjectHighlightColors = {
	 { link = "comment"},
      --   {link = "DiffText" },
      --   { link = "DiffChange" },
      --   { link = "Visual" },
     },
    -- targetedMotionHints = {
    --     enabled = true,
    --     prio = 1,
    -- },
    -- hints = {
    --      Caret = { text = "^", prio = 2 },
    --      Dollar = { text = "$", prio = 1 },
    --      MatchingPair = { text = "%", prio = 5 },
    --      Zero = { text = "0", prio = 1 },
    --      w = { text = "w", prio = 10 },
    --      b = { text = "b", prio = 9 },
    --      e = { text = "e", prio = 8 },
    --      W = { text = "W", prio = 7 },
    --      B = { text = "B", prio = 6 },
    --      E = { text = "E", prio = 5 },
    -- },
    -- gutterHints = {
    --     G = { text = "G", prio = 10 },
    --     gg = { text = "gg", prio = 9 },
    --     PrevParagraph = { text = "{", prio = 8 },
    --     NextParagraph = { text = "}", prio = 8 },
    -- },
    -- disabled_fts = {
    --     "startify",
    -- },
    },
},


}
