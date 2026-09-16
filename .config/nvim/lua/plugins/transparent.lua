return {
    "xiyaowong/transparent.nvim",
    lazy = false,
    config = function()
        require("transparent").setup({
            extra_groups = {
                "NormalFloat",
                "NvimTreeNormal",
            },
            exclude_groups = {},
        })
    end,
}
