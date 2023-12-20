# hurl.nvim

## Intro

**hurl.nvim** is a lua plugin for Neovim. When launching, it will feed your current buffer's content as a [Hurl file](https://hurl.dev/docs/hurl-file.html) to [Hurl](https://hurl.dev) and show it's response in a float window.

The main goal of this plugin is to quickly test some http(s) requests, not for heavy use cases like API testing or response assertion.

❗❗❗IMPORTANT: This plugin currently has only be tested on Macos.

## Requirements

* Neovim >=0.9.0
* [Hurl](https://hurl.dev)

## Installation

First of first, you need to install hurl. And either put it in your PATH or config it's path (see below).

Then install this plugin in neovim with your favorite package manager.

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "Zhuxy/hurl.nvim",
  dependencies = "MunifTanjim/nui.nvim",
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  },
}
```

## Configuration

default configurations:
```lua
{
  bin = "hurl", -- hurl binary command or it's full path
  popup_style = {  -- style of the popup window
                   -- these are the configurations of nui.popup()
                   -- please check them in https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/popup
    position = "40%",
    size = {
      width = "80%",
      height = "60%",
    },
    border = {
      padding = {
        top = 2,
        bottom = 2,
        left = 2,
        right = 2,
      },
      style = "rounded",
    },
  }
}
```

## Usage

Open up a blank buffer, and add some Hurl scripts in it:

```
GET https://httpbin.org/get
```

Launch vim command: `:HurlRequest`.

Then you will see the http response in a float window like this:

![showcase](https://raw.githubusercontent.com/Zhuxy/hurl.nvim/main/.github/showcase.png)

You can aslo bind this function to a key in lua:

```lua
vim.keymap.set("n", "<leader>rr", "<cmd>lua require('nvim-hurl').hurl_request()<cr>", { desc = "Request with Hurl" })
```

Using `<ESC>` to leave the float window.

## Next Step

Do you need to add some extra arguments to hurl when calling it?
