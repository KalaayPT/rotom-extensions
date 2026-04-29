local M = {}

function M.setup(opts)
  local ok, configs = pcall(require, "nvim-treesitter.parsers")
  if not ok then
    return
  end

  configs.get_parser_configs().rotom = {
    install_info = {
      url = "https://github.com/KalaayPT/rotom-lang",
      files = { "src/parser.c" },
      branch = "main",
      location = "tree-sitter-rotom",
    },
    filetype = "rotom",
  }

  vim.treesitter.language.register("rotom", "rotom")
end

return M
