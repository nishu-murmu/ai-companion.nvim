local M = {}
local config = require("cursor-inline.config")
local prompts = require("cursor-inline.prompts")
local state = require("cursor-inline.state")
local ui = require("cursor-inline.ui")
local core_utils = require("cursor-inline.core.utils")

local function decode_json(text)
	local ok, data = pcall(vim.json.decode, text)
	if ok then
		return data
	end
end

local function get_api_key(provider)
	local env_name = provider == "openai" and "OPENAI_API_KEY" or "ANTHROPIC_API_KEY"
	local api_key = vim.fn.getenv(env_name)
	if api_key == vim.NIL or api_key == "" then
		core_utils.api_key_missing_notification(provider)
		return
	end
	return api_key
end

local function run_stream(command, handlers, parse_event)
	local pending = ""
	local final_response = ""
	local stderr = ""
	vim.schedule(function()
		ui.start_spinner()
	end)
	local job_id = vim.fn.jobstart(command, {
		stdout_buffered = false,
		stderr_buffered = true,
		on_stdout = function(_, data)
			if not data then
				return
			end
			for _, item in ipairs(data) do
				if item ~= "" then
					pending = pending .. item .. "\n"
				end
			end
			while true do
				local line, rest = pending:match("^([^\n]*)\n(.*)$")
				if not line then
					break
				end
				pending = rest
				local chunk = parse_event(line)
				if chunk and chunk ~= "" then
					final_response = final_response .. chunk
					vim.schedule(function()
						handlers.on_chunk(chunk)
					end)
				end
			end
		end,
		on_stderr = function(_, data)
			stderr = data and table.concat(data, "\n") or stderr
		end,
		on_exit = function(_, code)
			vim.schedule(function()
				ui.stop_spinner()
				if code ~= 0 then
					handlers.on_error(stderr ~= "" and stderr or "Provider request failed")
					return
				end
				handlers.on_done(final_response)
			end)
		end,
	})
	if job_id <= 0 then
		vim.schedule(function()
			ui.stop_spinner()
			handlers.on_error("Failed to start provider request")
		end)
	end
end

---@param input string
---@param on_response function(text string)
local function openai_curl_command(input, handlers)
	local api_key = get_api_key("openai")
	if not api_key then
		state.request.active = false
		return
	end
	local payload = vim.json.encode({
		model = config.provider.model or "gpt-4.1-mini",
		stream = config.streaming.enabled,
		input = {
			{ role = "system", content = prompts.system_prompt },
			{ role = "user", content = input },
		},
	})
	local command = {
		"curl",
		"-s",
		"-N",
		"-X",
		"POST",
		"-H",
		"Content-Type: application/json",
		"-H",
		"Authorization: Bearer " .. api_key,
		"-d",
		payload,
		"https://api.openai.com/v1/responses",
	}
	if config.streaming.enabled then
		run_stream(command, handlers, function(line)
			if line == "data: [DONE]" then
				return
			end
			local json_text = line:match("^data:%s*(.+)$")
			if not json_text then
				return
			end
			local data = decode_json(json_text)
			if data and data.type == "response.output_text.delta" then
				return data.delta
			end
		end)
		return
	end
	vim.schedule(function()
		ui.start_spinner()
	end)
	vim.system(command, {
		text = true,
	}, function(res)
		vim.schedule(function()
			ui.stop_spinner()
		end)
		local data = decode_json(res.stdout or "")
		local response_code = data.output
			and data.output[1]
			and data.output[1].content
			and data.output[1].content[1]
			and data.output[1].content[1].text
		if not response_code then
			vim.schedule(function()
				handlers.on_error("Failed to parse OpenAI response")
			end)
			return
		end
		vim.schedule(function()
			handlers.on_done(response_code)
		end)
	end)
end

---@param input string
---@param on_response function(text string)
local function anthropic_curl_command(input, handlers)
	local api_key = get_api_key("anthropic")
	if not api_key then
		state.request.active = false
		return
	end
	local payload = vim.json.encode({
		model = config.provider.model or "claude-sonnet-4-5-20250929",
		max_tokens = 1024,
		stream = config.streaming.enabled,
		system = prompts.system_prompt,
		messages = {
			{ role = "user", content = input },
		},
	})
	local command = {
		"curl",
		"-s",
		"-N",
		"-X",
		"POST",
		"-H",
		"x-api-key: " .. api_key,
		"-H",
		"anthropic-version: 2023-06-01",
		"-H",
		"Content-Type: application/json",
		"-d",
		payload,
		"https://api.anthropic.com/v1/messages",
	}
	if config.streaming.enabled then
		run_stream(command, handlers, function(line)
			local json_text = line:match("^data:%s*(.+)$")
			if not json_text then
				return
			end
			local data = decode_json(json_text)
			if data and data.type == "content_block_delta" and data.delta and data.delta.type == "text_delta" then
				return data.delta.text
			end
		end)
		return
	end
	vim.schedule(function()
		ui.start_spinner()
	end)
	vim.system(command, {
		text = true,
	}, function(res)
		vim.schedule(function()
			ui.stop_spinner()
		end)
		local data = decode_json(res.stdout or "")
		local response_code = data.content and data.content[1] and data.content[1].text
		if not response_code then
			vim.schedule(function()
				handlers.on_error("Failed to parse Anthropic response")
			end)
			return
		end
		vim.schedule(function()
			handlers.on_done(response_code)
		end)
	end)
end

---@param input string
---@param handlers table
function M.get_current_provider_response(input, handlers)
	local provider = config.provider.name
	local instruction = input
	local selected_text = state.selected_text
	local prompt_text = instruction .. "\n below is the selected code, \n```" .. selected_text .. "```"
	if provider == "openai" then
		openai_curl_command(prompt_text, handlers)
		return
	end
	if provider == "anthropic" then
		anthropic_curl_command(prompt_text, handlers)
		return
	end
	state.request.active = false
	handlers.on_error("Unsupported provider: " .. tostring(provider))
end

return M
