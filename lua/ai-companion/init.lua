local M = {}
local config = require("ai-companion.config")
local inputs = require("ai-companion.inputs")
local layouts = require("ai-companion.layouts")

M.setup = function(user_config)
  vim.tbl_deep_extend("force", config, user_config)
end

if config.api_key == "" or config.api_key == nil then
  if os.getenv("OPENAI_API_KEY") == "" or os.getenv("OPENAI_API_KEY") == nil then
    inputs.api_key_input:mount()
  else
    config.api_key = os.getenv("OPENAI_API_KEY")
  end
end

vim.api.nvim_create_user_command("Companion", function(opts)
  local args = opts.args
  if args == "chat" then
    layouts.gpt_prompt_layout:mount()
    vim.api.nvim_set_current_win(inputs.user_prompt_popup.winid)
    vim.api.nvim_win_set_cursor(inputs.user_prompt_popup.winid, { 1, 2 })
  end
end, {
  nargs = 1,
  desc = "AI Companion commands.",
  complete = function()
    return { "chat", "review" }
  end,
})

return M
