vim.bo.commentstring = '// %s'
vim.bo.comments = '://'

require('rotom.treesitter').start_highlight()

if vim.fn.exists('+indentexpr') == 1 and vim.treesitter.query.get('rotom', 'indents') then
  vim.bo.indentexpr = 'v:lua.vim.treesitter.indentexpr()'
end
