local util = require('rotom.util')

local M = {}

local function plugin_root()
  local path = debug.getinfo(1, 'S').source:sub(2)
  return vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(path)))
end

-- Remove a cached parser built from a grammar revision other than the pinned
-- TREE_SITTER_REV. register_parser() loads any existing parser.so and returns
-- success before install_parser()'s rebuild can run, so without this a stale
-- parser (e.g. one missing the newline-terminator grammar fix) is reused
-- forever and commands never highlight.
local function purge_stale_parser()
  if not util.file_exists(util.parser_so_path()) then
    return
  end
  local install_dir = util.parser_install_dir()
  local rev_file = vim.fs.joinpath(install_dir, '.rev')
  local cached_rev = util.file_exists(rev_file) and vim.fn.readfile(rev_file)[1] or ''
  if cached_rev ~= util.TREE_SITTER_REV then
    vim.fn.delete(install_dir, 'rf')
  end
end

--- Link tree-sitter captures that many colorschemes leave undefined.
function M.ensure_highlight_groups()
  local links = {
    ['@function'] = 'Function',
    ['@function.call'] = 'Function',
    ['@type'] = 'Type',
  }
  for capture, link in pairs(links) do
    vim.api.nvim_set_hl(0, capture, { link = link, force = true })
  end
end

function M.sync_queries()
  local install_dir = util.parser_install_dir()
  local src = vim.fs.joinpath(plugin_root(), 'queries', 'rotom', 'highlights.scm')
  if not util.file_exists(install_dir) or not util.file_exists(src) then
    return
  end
  local dst_dir = vim.fs.joinpath(install_dir, 'queries')
  vim.fn.mkdir(dst_dir, 'p')
  vim.fn.writefile(vim.fn.readfile(src), vim.fs.joinpath(dst_dir, 'highlights.scm'))
end

function M.register_parser()
  local so = util.parser_so_path()
  local ok
  if util.file_exists(so) then
    ok = vim.treesitter.language.add('rotom', { path = so })
  else
    ok = vim.treesitter.language.add('rotom')
  end
  if ok then
    M.sync_queries()
  end
  return ok
end

function M.install_parser()
  if util.file_exists(util.parser_so_path()) then
    return M.register_parser()
  end

  if vim.fn.executable('tree-sitter') ~= 1 then
    vim.notify(
      'rotom: tree-sitter CLI not found; install it to build the Rotom parser',
      vim.log.levels.WARN
    )
    return false
  end

  local install_dir = util.parser_install_dir()
  local rev_file = vim.fs.joinpath(install_dir, '.rev')
  vim.fn.mkdir(vim.fs.dirname(install_dir), 'p')

  if util.file_exists(install_dir) then
    local cached_rev = util.file_exists(rev_file) and vim.fn.readfile(rev_file)[1] or ''
    if cached_rev ~= util.TREE_SITTER_REV then
      vim.fn.delete(install_dir, 'rf')
    end
  end

  if not util.file_exists(install_dir) then
    -- Fetch the pinned revision directly. `git clone --depth 1` only fetches
    -- the remote tip, so it cannot check out a pinned rev that has moved into
    -- history; fetching the sha shallowly works for any reachable commit.
    vim.fn.mkdir(install_dir, 'p')
    local steps = {
      { 'git', 'init', '-q' },
      { 'git', 'remote', 'add', 'origin', util.TREE_SITTER_REPO },
      { 'git', 'fetch', '--depth', '1', 'origin', util.TREE_SITTER_REV },
      { 'git', 'checkout', '-q', 'FETCH_HEAD' },
    }
    for _, cmd in ipairs(steps) do
      local res = vim.system(cmd, { cwd = install_dir, text = true }):wait()
      if res.code ~= 0 then
        vim.notify('rotom: ' .. table.concat(cmd, ' ') .. ' failed: ' .. (res.stderr or ''), vim.log.levels.ERROR)
        vim.fn.delete(install_dir, 'rf')
        return false
      end
    end
  end

  local build = vim.system({ 'tree-sitter', 'build', '-o', 'parser.so' }, {
    cwd = install_dir,
    text = true,
  }):wait()
  if build.code ~= 0 then
    vim.notify('rotom: tree-sitter build failed: ' .. (build.stderr or ''), vim.log.levels.ERROR)
    return false
  end

  vim.fn.writefile({ util.TREE_SITTER_REV }, rev_file)

  M.sync_queries()
  return M.register_parser()
end

function M.ensure_parser(opts)
  opts = opts or {}
  vim.treesitter.language.register('rotom', 'rotom')
  -- Only purge when we're allowed to rebuild; otherwise a stale-but-working
  -- parser beats no parser at all.
  if opts.install_parser ~= false then
    purge_stale_parser()
  end
  if M.register_parser() then
    return true
  end
  if opts.install_parser == false then
    return false
  end
  return M.install_parser()
end

function M.start_highlight(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype ~= 'rotom' then
    return
  end
  if not M.register_parser() then
    return
  end

  M.ensure_highlight_groups()

  -- Restart so new queries / links apply to an already-open buffer.
  pcall(vim.treesitter.stop, bufnr)
  pcall(vim.treesitter.start, bufnr, 'rotom')
end

function M.setup(opts)
  opts = opts or {}

  M.ensure_highlight_groups()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('RotomHighlight', { clear = true }),
    callback = M.ensure_highlight_groups,
  })

  if not M.ensure_parser(opts) then
    return
  end

  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('RotomTreesitter', { clear = false }),
    pattern = 'rotom',
    callback = function(args)
      M.start_highlight(args.buf)
    end,
  })
end

return M
