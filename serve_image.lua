
-- "/images/abcd/10x10/hello.png"

--local socket = require("socket.http")
--local server = require "resty.websocket.server"

local sig, size, path, ext, file_path =
  ngx.var.sig, ngx.var.size, ngx.var.path, ngx.var.ext, ngx.var.file_path

local secret = "hello_world" -- signature secret key
local images_dir = "images/" -- where images come from
local cache_dir = "cache/" -- where images are cached

local function return_not_found(msg)
  ngx.status = ngx.HTTP_NOT_FOUND
  ngx.header["Content-type"] = "text/html"
  ngx.say(msg or "not found")
  ngx.exit(0)
end

--local function calculate_signature(str)
--  return ngx.encode_base64(ngx.hmac_sha1(secret, str))
--    :gsub("[+/=]", {["+"] = "-", ["/"] = "_", ["="] = ","})
--    :sub(1,12)
--end

--if calculate_signature(size .. "/" .. path) ~= sig then
--  return_not_found("invalid signature")
--end

--local s3_loc = "/panoptes-uploads.zooniverse.org/production/subject_location/0e549e06-9c37-431d-9cbd-166c4ed0aaf2.jpeg"

local res = ngx.location.capture("/s3_proxy", {
  method = ngx.HTTP_GET,
--  body = "",
--  vars = {
--    url = s3_loc
--  }
});

--ngx.log(ngx.STDERR, "->>>>  " .. res.status);
if res.body then
    ngx.log(ngx.STDERR, "[Lua] Upstream success");
--    ngx.log(ngx.STDERR, res.body);
end

local source_fname = images_dir .. path
--local source_fname = os.tmpname()

ngx.log(ngx.STDERR, "->>>>  " .. source_fname);

local f = io.open(source_fname, 'wb') -- open in "binary" mode
f:write(res.body)
f:close()

-- make sure the file exists
--local input_file = io.open(source_fname)
--
--if not input_file then
--  ngx.log(ngx.STDERR, "Couldn't find the input file" .. source_fname)
--  return_not_found()
--end
--input_file:close()

local dest_fname = cache_dir .. size .. "_" .. file_path
ngx.log(ngx.STDERR, "->>>>  " .. dest_fname)
ngx.log(ngx.STDERR, "->>>>  " .. size)

-- resize the image
local magick = require("magick")

magick.thumb(source_fname, size, dest_fname)

ngx.log(ngx.STDERR, "->>>>  " .. ngx.var.request_uri)
--ngx.exec(dest_fname)
ngx.exec(ngx.var.request_uri)

