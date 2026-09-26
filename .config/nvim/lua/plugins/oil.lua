return {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    opts = {
        float = false,
        skip_confirm_for_simple_edits = true,
        cleanup_delay_ms = false,
        buf_options = {
            buflisted = true,
        },
        confirmation = {
            border = "rounded",
            win_options = {
                winhighlight = "Normal:OilConfirmationNormal,FloatBorder:FloatBorder",
            },
        },
    },
    config = function(_, opts)
        vim.api.nvim_set_hl(0, "OilConfirmationNormal", { bg = "#1e2030", fg = "#c0caf5" })

        vim.api.nvim_create_autocmd("FileType", {
            pattern = "oil_preview",
            callback = function(args)
                vim.keymap.set("n", "<CR>", "y", { buffer = args.buf, remap = true, desc = "Confirm oil actions" })
            end,
        })

        require("oil").setup(opts)
    end,
}

