local M = {}

M.mappings = {
	open_input = "<Space>e",
	accept_response = "<Space>y",
	deny_response = "<Space>n",
	show_inline_hint = true,
}

M.provider = {
	name = "openai",
	model = "gpt-5.4-mini",
}

M.preview = {
	diff = true,
}

M.streaming = {
	enabled = true,
}

M.setup = function(opts)
	local provider = opts.provider or {}
	local mappings = opts.mappings or {}
	local preview = opts.preview or {}
	local streaming = opts.streaming or {}
	M.provider = vim.tbl_deep_extend("force", M.provider, provider)
	M.mappings = vim.tbl_deep_extend("force", M.mappings, mappings)
	M.preview = vim.tbl_deep_extend("force", M.preview, preview)
	M.streaming = vim.tbl_deep_extend("force", M.streaming, streaming)
end

return M
