vim.bo.syntax = 'json'

if vim.treesitter.language.add('json') then
  vim.treesitter.start(vim.api.nvim_get_current_buf(), 'json')
end
