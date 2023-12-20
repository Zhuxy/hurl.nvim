---@class CustomModule
local M = {}

M.NVIM_HURL_CONTENT_TYPE = nil
M.NVIM_HURL_HAS_ERROR = nil

M.hurl_request = function(config)
  M.NVIM_HURL_CONTENT_TYPE = "text"
  M.NVIM_HURL_HAS_ERROR = false

  local current_buf = vim.api.nvim_get_current_buf()
  local content = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)

  -- add --verbose to print out http response and capture content-type
  local job_id = vim.fn.jobstart(config.bin .. " --verbose", {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stderr = function(_, data, _)
      if type(data) == "table" and #data == 1 then
        return
      end

      local error_data = {}

      -- find content-type
      for _, value in ipairs(data) do
        -- check if value has "Content-Type" or "content-type"
        if string.find(value, "< Content.Type:") or string.find(value, "< content.type:") then
          if string.find(value, "application/json") then
            M.NVIM_HURL_CONTENT_TYPE = "json"
          end
          if string.find(value, "application/xml") then
            M.NVIM_HURL_CONTENT_TYPE = "xml"
          end
          if string.find(value, "text/html") then
            M.NVIM_HURL_CONTENT_TYPE = "html"
          end
        end

        -- check if value start with "error:"
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
        if M.NVIM_HURL_HAS_ERROR then
          return
        end

        -- check if data is { "" }
        if type(data) == "table" and #data == 1 and data[0] == "" then
          data = {"no response body"}
        end

        -- iterate string in data and remove all '\r',
        -- otherwise it will display a "^M" in buffer
        for i, value in ipairs(data) do
          data[i] = string.gsub(value, "\r", "")
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

M.show_content_in_fload_window = function(content, content_type, config)
  local Popup = require("nui.popup")
  local event = require("nui.utils.autocmd").event

  M.NVIM_HURL_POPUP = Popup(config.popup_style)

  -- mount/open the component
  M.NVIM_HURL_POPUP:mount()

  vim.api.nvim_buf_set_keymap(M.NVIM_HURL_POPUP.bufnr, 'n', '<ESC>', ':lua require("nvim-hurl.module").close_float_window()<CR>', {
    nowait = true,
    noremap = true,
    silent = true,
    expr = false,
  })

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
