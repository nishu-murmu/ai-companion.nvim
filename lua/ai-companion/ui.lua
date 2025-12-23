local M = {}

local api = vim.api
local config = require("ai-companion.config")

local bufnr
local win_id
local input_overridden = false

local function override_vim_input()
  if input_overridden then
    return
  end
  input_overridden = true

  vim.ui.input = function(opts, on_confirm)
    opts = opts or {}
    local prompt = opts.prompt
    local default = opts.default or ""

    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, false, { default })
    api.nvim_buf_set_option(buf, "modifiable", true)

    local win = api.nvim_open_win(buf, true, {
      relative = "cursor",
      row = 0,
      col = 1,
      width = 40,
      height = 1,
      style = "minimal",
      border = "rounded",
      title = prompt,
      title_pos = "left",
    })

    vim.keymap.set("i", "<CR>", function()
      local text = table.concat(api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
      api.nvim_win_close(win, true)
      on_confirm(text ~= "" and text or nil)
    end, { buffer = buf })

    vim.keymap.set("i", "<Esc>", function()
      api.nvim_win_close(win, true)
      on_confirm(nil)
      vim.cmd("stopinsert")
    end, { buffer = buf })

    vim.cmd("startinsert")
  end
end

function M.open_inline_command()
  if win_id and api.nvim_win_is_valid(win_id) then
    return
  end

  bufnr = api.nvim_create_buf(false, true)
  local open_input = config.mappings.open_input or ""
  api.nvim_buf_set_lines(bufnr, 0, -1, false, { "Quick Edit (" .. open_input .. ")" })

  win_id = api.nvim_open_win(bufnr, false, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = 24,
    height = 1,
    style = "minimal",
  })
end

function M.move_inline_command()
  if not win_id or not api.nvim_win_is_valid(win_id) then
    return
  end

  api.nvim_win_set_config(win_id, {
    relative = "cursor",
    row = 1,
    col = 0,
  })
end

function M.close_inline_command()
  if win_id and api.nvim_win_is_valid(win_id) then
    api.nvim_win_close(win_id, true)
  end

  if bufnr and api.nvim_buf_is_valid(bufnr) then
    api.nvim_buf_delete(bufnr, { force = true })
  end

  win_id = nil
  bufnr = nil
end

function M.setup()
  override_vim_input()
end

return M
