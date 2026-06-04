local M = {}

M._setup_done = false

function M.register_filetypes(opts)
  vim.filetype.add({
    extension = {
      rotom = 'rotom',
    },
    pattern = {
      ['.*[/\\]textArchives[/\\].*%.json$'] = 'rotom_text_archive',
      ['.*[/\\]res[/\\]text[/\\].*%.json$'] = 'rotom_text_archive',
    },
  })

  if opts.archive_json == false then
    vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
      group = vim.api.nvim_create_augroup('RotomArchiveFiletype', { clear = true }),
      pattern = '*.json',
      callback = function(ev)
        local path = vim.api.nvim_buf_get_name(ev.buf)
        if require('rotom.util').is_archive_json(path) then
          vim.bo[ev.buf].filetype = 'json'
        end
      end,
    })
  end
end

---@class RotomOpts
---@field lsp_path? string Path to rotom-lsp binary
---@field lsp? table|false Overrides for vim.lsp.config, or false to skip LSP
---@field install_parser? boolean Build tree-sitter-rotom when missing (default true)
---@field archive_json? boolean Detect text archive JSON paths (default true)
---@field treesitter? boolean Enable tree-sitter highlighting (default true)

function M.setup(opts)
  opts = vim.tbl_extend('force', {
    install_parser = true,
    archive_json = true,
    treesitter = true,
  }, opts or {})

  M.register_filetypes(opts)

  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)

  -- Register parser before setting filetype so other FileType hooks (e.g.
  -- kickstart's nvim-treesitter) can load it.
  if opts.treesitter ~= false then
    require('rotom.treesitter').ensure_parser({
      install_parser = opts.install_parser,
    })
  end

  if path ~= '' then
    if path:match('%.rotom$') then
      vim.bo[bufnr].filetype = 'rotom'
    elseif opts.archive_json ~= false and require('rotom.util').is_archive_json(path) then
      vim.bo[bufnr].filetype = 'rotom_text_archive'
    end
  end

  if M._setup_done then
    if opts.treesitter ~= false and vim.bo[bufnr].filetype == 'rotom' then
      require('rotom.treesitter').start_highlight(bufnr)
    end
    return
  end
  M._setup_done = true

  if opts.treesitter ~= false then
    require('rotom.treesitter').setup({
      install_parser = opts.install_parser,
    })
    if vim.bo[bufnr].filetype == 'rotom' then
      require('rotom.treesitter').start_highlight(bufnr)
    end
  end

  if opts.lsp ~= false then
    require('rotom.lsp').setup({
      lsp_path = opts.lsp_path,
      lsp = type(opts.lsp) == 'table' and opts.lsp or {},
    })
  end
end

return M
