local Layout = require("nui.layout")
local popups = require("ai-companion.inputs")
local M = {}
--
local gpt_prompt_layout = Layout({
	position = "50%",
	size = {
		width = 80,
		height = 20,
	},
}, {
	Layout.Box({
		Layout.Box(popups.gpt_prompt_popup, { size = "90%" }),
		Layout.Box(popups.user_prompt_popup, { size = "10%" }),
	}, { dir = "col", size = "80%" }),
})

M.gpt_prompt_layout = gpt_prompt_layout

return M
