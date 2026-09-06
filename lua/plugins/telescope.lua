return {
    "nvim-telescope/telescope.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    cmd = "Telescope",
    keys = {
        {
            "<leader>ff",
            function()
                require("telescope.builtin").find_files()
            end,
            desc = "Find files",
        },
        {
            "<leader>fg",
            function()
                require("telescope.builtin").live_grep()
            end,
            desc = "Live grep",
        },
        {
            "<leader>fb",
            function()
                require("telescope.builtin").buffers()
            end,
            desc = "Buffers",
        },
        {
            "<leader>fh",
            function()
                require("telescope.builtin").help_tags()
            end,
            desc = "Help tags",
        },
        {
            "<leader>fr",
            function()
                require("telescope.builtin").resume()
            end,
            desc = "Resume last picker",
        },
    },
    opts = {
        defaults = {
            -- live_grep / grep_string run through this. --no-ignore and --hidden
            -- are what make gitignored + dotfiles searchable.
            vimgrep_arguments = {
                "rg",
                "--color=never",
                "--no-heading",
                "--with-filename",
                "--line-number",
                "--column",
                "--smart-case",
                "--no-ignore",
                "--hidden",
                "--glob=!**/.git/*",
            },
            file_ignore_patterns = {
                "^%.git/",
                "node_modules/",
                "%.venv/",
                "__pycache__/",
                "%.mypy_cache/",
                "%.ruff_cache/",
                "target/",
                "dist/",
                "%.lock$",
            },
            path_display = { "truncate" },
        },
        pickers = {
            find_files = {
                hidden = true,
                no_ignore = true,
                no_ignore_parent = true,
                -- explicit rg command so behaviour matches live_grep exactly
                find_command = {
                    "rg",
                    "--files",
                    "--hidden",
                    "--no-ignore",
                    "--glob=!**/.git/*",
                },
            },
            grep_string = { additional_args = { "--no-ignore", "--hidden" } },
        },
        extensions = {
            fzf = {
                fuzzy = true,
                override_generic_sorter = true,
                override_file_sorter = true,
                case_mode = "smart_case",
            },
        },
    },
    config = function(_, opts)
        local telescope = require("telescope")
        telescope.setup(opts)
        pcall(telescope.load_extension, "fzf")
    end,
}
