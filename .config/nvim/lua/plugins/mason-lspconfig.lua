return {
    "mason-org/mason-lspconfig.nvim",
    opts = {
        handlers = {
            function(server_name)
                local capabilities = require("cmp_nvim_lsp").default_capabilities()
                local on_attach = function(client, bufnr)
                    local bufopts = { noremap = true, silent = true, buffer = bufnr }
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
                    vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
                    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, bufopts)
                    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, bufopts)
                    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, bufopts)
                    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, bufopts)
                    vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, bufopts)
                end
                require("lspconfig")[server_name].setup({
                    capabilities = capabilities,
                    on_attach = on_attach,
                })
            end,
        },
    },
    dependencies = {
        "mason-org/mason.nvim",
        "neovim/nvim-lspconfig",
        "hrsh7th/cmp-nvim-lsp",
    },
}
