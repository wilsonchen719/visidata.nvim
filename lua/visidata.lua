---@mod visidata Plugin to render pandas dataframe in nvim-dap using visidata.

local M = {}
local dap = require("dap")

local function get_visual_selection()
    local _, line_start, col_start = unpack(vim.fn.getpos("<"))
    local _, line_end, col_end = unpack(vim.fn.getpos(">"))
    local selection = vim.api.nvim_buf_get_text(0, line_start - 1, col_start - 1, line_end - 1, col_end, {})
    return selection
end
--- Visualize the selected dataframe.
function M.visualize_pandas_df()
    dap.repl.execute("from visidata import vd")
    local selected_item = get_visual_selection()
    dap.repl.execute("print(" .. selected_item .. ")")
    dap.repl.execute("try: vd.view_pandas(" .. selected_item .. ") except: pass")
end

return M
