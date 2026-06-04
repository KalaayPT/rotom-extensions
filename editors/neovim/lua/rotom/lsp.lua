local util = require('rotom.util')

local M = {}

M._configured = false

local function show_references(command, ctx)
  local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
  local file_uri, position, references = unpack(command.arguments)

  local quickfix_items = vim.lsp.util.locations_to_items(references --[[@as any]], client.offset_encoding)
  vim.fn.setqflist({}, ' ', {
    title = command.title,
    items = quickfix_items,
    context = {
      command = command,
      bufnr = ctx.bufnr,
    },
  })

  vim.lsp.util.show_document({
    uri = file_uri --[[@as string]],
    range = {
      start = position --[[@as lsp.Position]],
      ['end'] = position --[[@as lsp.Position]],
    },
  }, client.offset_encoding)

  vim.cmd('botright copen')
end

local function default_on_attach(client, bufnr)
  if client:supports_method('textDocument/codeLens') then
    vim.lsp.codelens.enable(true, { bufnr = bufnr })
  end
end

function M.build_config(opts)
  opts = opts or {}
  local user = opts.lsp or {}
  local user_on_attach = user.on_attach

  -- cmd must be string[] here. In Neovim 0.11+, a function cmd is an
  -- in-process LSP server factory, not a path resolver.
  local config = vim.tbl_deep_extend('force', {
    cmd = util.resolve_lsp_cmd(opts),
    filetypes = { 'rotom', 'rotom_text_archive' },
    root_markers = { 'rotom.toml', '.git' },
    commands = {
      ['editor.action.showReferences'] = show_references,
    },
  }, user)

  config.on_attach = function(client, bufnr)
    default_on_attach(client, bufnr)
    if user_on_attach then
      user_on_attach(client, bufnr)
    end
  end

  return config
end

function M.setup_lspconfig(opts)
  local ok, lspconfig = pcall(require, 'lspconfig')
  if not ok then
    return false
  end

  local configs = require('lspconfig.configs')
  local config = M.build_config(opts)
  config.root_dir = lspconfig.util.root_pattern('rotom.toml', '.git')
  config.root_markers = nil

  if not configs.rotom then
    configs.rotom = {
      default_config = config,
    }
  end

  lspconfig.rotom.setup(opts.lsp or {})
  return true
end

function M.setup(opts)
  if M._configured then
    return
  end
  M._configured = true

  opts = opts or {}
  local config = M.build_config(opts)

  if vim.lsp.config then
    vim.schedule(function()
      vim.lsp.config('rotom', config)
      vim.lsp.enable('rotom')
    end)
    return
  end

  if not M.setup_lspconfig(opts) then
    vim.notify(
      'rotom: Neovim 0.11+ or nvim-lspconfig is required for LSP support',
      vim.log.levels.ERROR
    )
  end
end

return M
