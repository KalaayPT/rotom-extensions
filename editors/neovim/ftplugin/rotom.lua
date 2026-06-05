vim.bo.commentstring = '// %s'
vim.bo.comments = '://'

require('rotom.treesitter').start_highlight()

local ok, indents = pcall(vim.treesitter.query.get, 'rotom', 'indents')
if vim.fn.exists('+indentexpr') == 1 and ok and indents then
  vim.bo.indentexpr = 'v:lua.vim.treesitter.indentexpr()'
end
