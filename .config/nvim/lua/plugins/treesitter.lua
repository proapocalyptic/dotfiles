return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").setup()
        vim.schedule(function()
            require("nvim-treesitter").install({ "lua", "markdown", "css", "html", "javascript", "bash", "zsh" })
        end)
        vim.api.nvim_create_autocmd("FileType", {
            callback = function()
                pcall(vim.treesitter.start)
            end,
        })
    end,
}
