---@class CustomModule
local M = {}

local ts_utils = require("nvim-treesitter.ts_utils")

local function format_json_with_treesitter(text)
  local bufnr = vim.api.nvim_create_buf(false, true) -- 创建临时缓冲区
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(text, "\n"))

  local parser = vim.treesitter.get_parser(bufnr, "json")
  local tree = parser:parse()[1]
  local root = tree:root()

  local formatted = ts_utils.get_node_text(root, bufnr)
  vim.api.nvim_buf_delete(bufnr, { force = true }) -- 删除临时缓冲区
  return formatted
end


M.NVIM_HURL_CONTENT_TYPE = nil
M.NVIM_HURL_HAS_ERROR = nil

M.hurl_request = function(config)
  -- Initialize response type and error state
  M.NVIM_HURL_CONTENT_TYPE = "text"
  M.NVIM_HURL_HAS_ERROR = false

  -- Get current buffer content as HTTP request input
  local current_buf = vim.api.nvim_get_current_buf()
  local content = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)

  -- Start async job with verbose mode to capture headers
  local command = string.format("%s --verbose --connect-timeout %d", config.bin, config.timeout)
  local job_id = vim.fn.jobstart(command, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stderr = function(_, data, _)
      -- Skip empty error data
      if type(data) == "table" and #data == 1 then
        return
      end

      local error_data = {}

      -- Parse Content-Type from response headers
      for _, value in ipairs(data) do
        -- check if value has "Content-Type" or "content-type"
        if string.find(value, "< Content.Type:") or string.find(value, "< content.type:") then
          if string.find(value, "application/json") then
            M.NVIM_HURL_CONTENT_TYPE = "json"
          end
          if string.find(value, "text/plain") then
            M.NVIM_HURL_CONTENT_TYPE = "text"
          end
          if string.find(value, "application/javascript") then
            M.NVIM_HURL_CONTENT_TYPE = "javascript"
          end
          if string.find(value, "application/pdf") then
            M.NVIM_HURL_CONTENT_TYPE = "pdf"
          end
          if string.find(value, "application/xml") then
            M.NVIM_HURL_CONTENT_TYPE = "xml"
          end
          if string.find(value, "text/html") then
            M.NVIM_HURL_CONTENT_TYPE = "html"
          end
        end

        -- Detect error patterns in response
        if string.find(value, "^error:") then
          M.NVIM_HURL_HAS_ERROR = true
          table.insert(error_data, value)
        elseif M.NVIM_HURL_HAS_ERROR then
          table.insert(error_data, value)
        end
      end

      vim.fn.setreg("0", data)

      if M.NVIM_HURL_HAS_ERROR then
        print("show error")
        M.show_content_in_fload_window(error_data, M.NVIM_HURL_CONTENT_TYPE, config)
      end
    end,
    on_stdout = function(_, data, _)
      vim.defer_fn(function()
        -- Skip processing if error occurred
        if M.NVIM_HURL_HAS_ERROR then
          return
        end

        -- Handle empty response body
        if type(data) == "table" and #data == 1 and data[0] == "" then
          data = { "no response body" }
        end

        -- Clean up carriage returns from Windows-style line endings
        for i, value in ipairs(data) do
          data[i] = string.gsub(value, "\r", "")
        end

        if M.NVIM_HURL_CONTENT_TYPE == "json" then
          data = format_json_with_treesitter(table.concat(data, "\n"))
        end

        -- add a slight delay to wait for on_stderr to finish
        M.show_content_in_fload_window(data, M.NVIM_HURL_CONTENT_TYPE, config)
      end, 200)
    end,
  })

  vim.fn.chansend(job_id, content)
  vim.fn.chanclose(job_id, "stdin")
end

M.NVIM_HURL_POPUP = nil

-- Display response content in floating window with syntax highlighting
M.show_content_in_fload_window = function(content, content_type, config)
  local Popup = require("nui.popup")
  local event = require("nui.utils.autocmd").event

  M.NVIM_HURL_POPUP = Popup(config.popup_style)

  -- mount/open the component
  M.NVIM_HURL_POPUP:mount()

  vim.api.nvim_buf_set_keymap(
    M.NVIM_HURL_POPUP.bufnr,
    "n",
    "<ESC>",
    ":lua require('nvim-hurl.module').close_float_window()<CR>",
    {
      nowait = true,
      noremap = true,
      silent = true,
      expr = false,
    }
  )

  -- unmount component when cursor leaves buffer
  M.NVIM_HURL_POPUP:on(event.BufLeave, function()
    M.NVIM_HURL_POPUP:unmount()
  end)

  -- set content
  vim.api.nvim_buf_set_lines(M.NVIM_HURL_POPUP.bufnr, 0, 1, false, content)
  vim.api.nvim_buf_set_option(M.NVIM_HURL_POPUP.bufnr, "filetype", content_type)
end

M.close_float_window = function()
  M.NVIM_HURL_POPUP:unmount()
end

return M
