local M = {}

M.TREE_SITTER_REPO = 'https://github.com/KalaayPT/tree-sitter-rotom'
M.TREE_SITTER_REV = '129e909ffaf0a6fbc91738c629f717bf84113f7f'

function M.is_archive_json(path)
  if not path:match('%.json$') then
    return false
  end
  return path:find('/textArchives/') ~= nil
    or path:find('\\textArchives\\') ~= nil
    or path:find('/res/text/') ~= nil
    or path:find('\\res\\text\\') ~= nil
end

function M.file_exists(path)
  return path ~= nil and path ~= '' and vim.fn.filereadable(path) == 1
end

function M.resolve_lsp_cmd(opts, bufnr)
  opts = opts or {}
  if opts.lsp_path and M.file_exists(opts.lsp_path) then
    return { opts.lsp_path }
  end

  local root
  if bufnr and bufnr > 0 and vim.api.nvim_buf_is_valid(bufnr) then
    root = vim.fs.root(bufnr, { 'rotom.toml', '.git' })
  end
  root = root or vim.fs.root(vim.fn.getcwd(), { 'rotom.toml', '.git' })
  if root then
    for _, rel in ipairs({ 'target/debug/rotom-lsp', 'target/release/rotom-lsp' }) do
      local candidate = vim.fs.joinpath(root, rel)
      if M.file_exists(candidate) then
        return { candidate }
      end
    end
  end

  return { 'rotom-lsp' }
end

function M.parser_install_dir()
  return vim.fs.joinpath(vim.fn.stdpath('data'), 'rotom', 'tree-sitter-rotom')
end

function M.parser_so_path()
  return vim.fs.joinpath(M.parser_install_dir(), 'parser.so')
end

return M
