-- main module file
local module = require("nvim-hurl.module")

---@class Config
---@field bin string the hurl command's path in your system
---@field popup_style see nui.popup()'s arguments
local config = {
  bin = "hurl",
  popup_style = {
    position = "40%",
    size = {
      width = "80%",
      height = "60%",
    },
    enter = true,
    focusable = true,
    zindex = 50,
    relative = "editor",
    border = {
      padding = {
        top = 2,
        bottom = 2,
        left = 2,
        right = 2,
      },
      style = "rounded",
    },
    buf_options = {
      modifiable = true,
      readonly = false,
    },
    win_options = {
      winblend = 10,
      winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
    },
  },
}

---@class MyModule
local M = {}

---@type Config
M.config = config

---@param args Config
M.setup = function(args)
  -- delete some keys in args which cannot be overrided
  local delete_styles = function(obj, style_key)
    if obj and obj.popup_style and obj.popup_style[style_key] then
      obj.popup_style[style_key] = nil
    end
  end
  delete_styles(args, "enter")
  delete_styles(args, "focusable")
  delete_styles(args, "zindex")
  delete_styles(args, "relative")
  delete_styles(args, "buf_options")
  delete_styles(args, "win_options")

  M.config = vim.tbl_deep_extend("force", M.config, args or {})
end

M.hurl_request = function()
  module.hurl_request(M.config)
end

return M
