---@mod visidata Plugin to render pandas dataframe in nvim-dap using visidata.

local M = {}
local dap = require("dap")

local function get_visual_selection()
    local _, line_start, col_start = unpack(vim.fn.getpos("v"))
    local _, line_end, col_end = unpack(vim.fn.getpos("."))
    if line_start > line_end or (line_start == line_end and col_start > col_end) then
        line_start, line_end = line_end, line_start
        col_start, col_end = col_end, col_start
    end
    local selection = vim.api.nvim_buf_get_text(0, line_start - 1, col_start - 1, line_end - 1, col_end, {})
    return selection
end
--- Visualize the selected dataframe.
function M.visualize_pandas_df()
    local selected_item = get_visual_selection()[1]
    local code_to_be_executed = {
        "from visidata import vd",
        "try:",
        "   if isinstance(" .. selected_item .. ", pd.DataFrame):",
        "       print(" .. selected_item .. ".head(10))",
        "       print(" .. selected_item .. ".dtypes)",
        "       read_df = input('Do you want to read the dataframe in visidata? (y/n): ')",
        "       if read_df.upper() == 'Y':",
        "           vd.view_pandas(" .. selected_item .. ")",
        "   else:",
        "       print(" .. selected_item .. ")",
        "except Exception as e:",
        "   print(f'{type(" .. selected_item .. ")} does not implement __str__ method', e)",
    }
    dap.repl.execute(table.concat(code_to_be_executed, "\n"))
end

return M
