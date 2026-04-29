local M = {}

function M.setup(opts)
  local lspconfig = require("lspconfig")
  local configs = require("lspconfig.configs")

  if not configs.rotom_lsp then
    configs.rotom_lsp = {
      default_config = {
        cmd = { "rotom-lsp" },
        filetypes = { "rotom" },
        root_dir = lspconfig.util.root_pattern("rotom.toml", ".git"),
        settings = {},
      },
    }
  end

  lspconfig.rotom_lsp.setup(opts.lsp or {})
end

return M
