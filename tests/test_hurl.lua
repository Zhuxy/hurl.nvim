local hurl = require('nvim-hurl')

describe('hurl.nvim', function()
  it('should have a hurl_request function', function()
    assert.is_not_nil(hurl.hurl_request)
  end)

  -- Add more test cases here
end)
