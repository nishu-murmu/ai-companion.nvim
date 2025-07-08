local config = require("ai-companion.config")
local Input = require("nui.input")
local Popup = require("nui.popup")
local M = {}

--- This is API key input UI which is asked initially for API key if it is not set in the environment.
local api_key_input = Input({
  position = "50%",
  size = {
    width = 30,
    height = 10,
  },
  border = {
    style = "rounded",
    text = {
      top = " [Enter API key] ",
      top_align = "center",
    },
  },
  win_options = {
    winhighlight = "Normal:Normal,FloatBorder:Normal",
  },
}, {
  prompt = ">",
  default_value = "",
  on_submit = function(value)
    if vim.startswith(value, "sk-proj") then
      config.api_key = value
      vim.notify("API added successfully", vim.log.levels.SUCCESS, {})
    else
      vim.notify("Please enter valid API key", vim.log.levels.ERROR, { title = "API config" })
    end
  end,
})

local gpt_prompt_popup = Popup({
  position = "50%",
  size = {
    width = 80,
    height = 25,
  },
  focusable = true,
  relative = "editor",
  border = {
    style = "rounded",
    text = {
      top = "[ GPT response ]",
      top_align = "center",
    },
  },
  buf_options = {
    modifiable = false,
    readonly = false,
  },
  win_options = {
    winblend = 10,
    winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
  },
})

local user_prompt_popup = Popup({
  position = "50%",
  size = {
    width = 80,
    height = 2,
  },
  focusable = true,
  relative = "editor",
  border = {
    padding = {
      left = 1,
    },
    style = "rounded",
    text = {
      top = "[ Enter your prompt ]",
      top_align = "left",
    },
  },
  buf_options = {
    modifiable = true,
  },
  win_options = {
    winblend = 10,
    winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
  },
})

M.api_key_input = api_key_input
M.gpt_prompt_popup = gpt_prompt_popup
M.user_prompt_popup = user_prompt_popup

return M
