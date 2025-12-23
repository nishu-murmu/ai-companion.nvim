local M = {}

M.highlight = {
  old_code = {
    start_row = nil,
    end_row = nil,
    hl_group = "OldCode"
  },
  new_code = {
    start_row = nil,
    end_row = nil,
    hl_group = "NewCode"
  }
}

M.selected_text = ""

return M
