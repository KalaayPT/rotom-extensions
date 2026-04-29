local M = {}

function M.setup(opts)
  opts = opts or {}

  -- Register filetype
  vim.filetype.add({
    extension = {
      rotom = "rotom",
    },
  })

  -- Setup tree-sitter
  require("rotom.treesitter").setup(opts)

  -- Setup LSP
  require("rotom.lsp").setup(opts)
end

return M
