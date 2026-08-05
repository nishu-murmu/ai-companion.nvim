local M = {}

local api = vim.api
local state = require("cursor-inline.state")
local providers = require("cursor-inline.core.providers")
local core_utils = require("cursor-inline.core.utils")
local utils = require("cursor-inline.utils")

function M.get_response()
	---@diagnostic disable
	vim.ui.input({ prompt = "Enter prompt:" }, function(input, cb)
		if input and input ~= "" then
			state.request.id = state.request.id + 1
			state.request.active = true
			local request_id = state.request.id
			local response_code = ""
			local preview_started = false
			providers.get_current_provider_response(input, {
				on_chunk = function(chunk)
					if not state.request.active or request_id ~= state.request.id then
						return
					end
					if not preview_started then
						preview_started = true
						core_utils.begin_response_preview()
					end
					response_code = response_code .. chunk
					core_utils.update_response_preview(response_code)
				end,
				on_done = function(final_response)
					if not state.request.active or request_id ~= state.request.id then
						return
					end
					state.request.active = false
					if final_response and final_response ~= "" and not preview_started then
						core_utils.on_response_handler(final_response, function(value)
							cb(value)
						end)
						return
					end
					if final_response and final_response ~= "" and final_response ~= response_code then
						core_utils.update_response_preview(final_response)
					end
					core_utils.finish_response_preview(function(value)
						cb(value)
					end)
				end,
				on_error = function(message)
					if request_id ~= state.request.id then
						return
					end
					state.request.active = false
					vim.schedule(function()
						vim.notify(message, vim.log.levels.ERROR)
						vim.cmd("stopinsert")
						cb(true)
					end)
				end,
			})
		end
	end)
end

function M.accept_api_response()
	local new_sr, new_er = utils.get_code_region("old_code")
	local bufnr = state.main_bufnr
	if new_sr and new_er and bufnr then
		api.nvim_buf_set_lines(bufnr, new_sr, new_er, false, {})
	end
	utils.close_helper_commands_ui()
	core_utils.reset_states()
end

function M.reject_api_response()
	local new_sr, new_er = utils.get_code_region("new_code")
	local bufnr = state.main_bufnr
	if new_sr and new_er and bufnr then
		api.nvim_buf_set_lines(bufnr, new_sr, new_er, false, {})
	end
	utils.close_helper_commands_ui()
	core_utils.reset_states()
end

return M
