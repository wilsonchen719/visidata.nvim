---@mod visidata Plugin to render pandas dataframe in nvim-dap using visidata.

local M = {}
local dap = require("dap")
local config = require("iron.config")
local marks = require("iron.marks")
--- Core functions of iron
-- @module core
local core = {}

core.visual_send = function()
    core.send(nil, core.mark_visual())
end

core.mark_visual = function()
    -- HACK Break out of visual mode
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", false, true, true), "nx", false)
    local b_line, b_col
    local e_line, e_col

    local mode = vim.fn.visualmode()

    b_line, b_col = unpack(vim.fn.getpos("'<"), 2, 3)
    e_line, e_col = unpack(vim.fn.getpos("'>"), 2, 3)

    if e_line < b_line or (e_line == b_line and e_col < b_col) then
        e_line, b_line = b_line, e_line
        e_col, b_col = b_col, e_col
    end

    local lines = vim.api.nvim_buf_get_lines(0, b_line - 1, e_line, 0)

    if #lines == 0 then
        return
    end

    if mode == "\22" then
        local b_offset = math.max(1, b_col) - 1
        for ix, line in ipairs(lines) do
            -- On a block, remove all preciding chars unless b_col is 0/negative
            lines[ix] = vim.fn.strcharpart(line, b_offset, math.min(e_col, vim.fn.strwidth(line)))
        end
    elseif mode == "v" then
        local last = #lines
        local line_size = vim.fn.strwidth(lines[last])
        local max_width = math.min(e_col, line_size)
        if max_width < line_size then
            -- If the selected width is smaller then total line, trim the excess
            lines[last] = vim.fn.strcharpart(lines[last], 0, max_width)
        end

        if b_col > 1 then
            -- on a normal visual selection, if the start column is not 1, trim the beginning part
            lines[1] = vim.fn.strcharpart(lines[1], b_col - 1)
        end
    end

    marks.set({
        from_line = b_line - 1,
        from_col = math.max(b_col - 1, 0),
        to_line = e_line - 1,
        to_col = math.min(e_col, vim.fn.strwidth(lines[#lines])) - 1, -- TODO Check whether this is actually true
    })

    if config.ignore_blank_lines then
        local b_lines = {}
        for _, line in ipairs(lines) do
            if line:gsub("^%s*(.-)%s*$", "%1") ~= "" then
                table.insert(b_lines, line)
            end
        end
        return b_lines
    else
        return lines
    end
end

-- local function get_visual_selection()
--     local _, line_start, col_start = unpack(vim.fn.getpos("v"))
--     local _, line_end, col_end = unpack(vim.fn.getpos("."))
--     local selection = vim.api.nvim_buf_get_text(0, line_start - 1, col_start - 1, line_end - 1, col_end, {})
--     return selection
-- end
--
--- Visualize the selected dataframe.
function M.visualize_pandas_df()
    dap.repl.execute("import visidata")
    local selected_dataframe = core.mark_visual()
    dap.repl.execute("visidata.vd.view_pandas(" .. selected_dataframe .. ")")
end

return M
