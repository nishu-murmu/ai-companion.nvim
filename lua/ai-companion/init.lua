local M = {}

local config = require("ai-companion.config")
local ui = require("ai-companion.ui")
local base = require("ai-companion.base")
local autocmd = require("ai-companion.autocmd")

function M.setup(opts)
  config.setup(opts or {})
  ui.setup()
  autocmd.setup()
  base.setup()
end

return M
