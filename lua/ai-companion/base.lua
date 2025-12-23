local M = {}

local ui = require("ai-companion.ui")
local api_service = require("ai-companion.api")
local config = require("ai-companion.config")

local function open_input_callback()
  ui.close_inline_command()
  vim.ui.input({ prompt = "Enter prompt:" }, function(input)
    if input and input ~= "" then
      api_service.get_response(input)
      vim.cmd("stopinsert")
    end
  end)
end

function M.setup()
  vim.keymap.set("v", config.mappings.open_input, open_input_callback, { desc = "Opening the input input prompt." })
end

return M
