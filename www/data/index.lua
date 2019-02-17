
local json = require("json")
local fname = "data.json"

function send_info()
	mg.write("Date:" .. os.date("! %a, %d %b %Y %H:%M:%S GMT") .. "\r\n")
	mg.write("Connection: close\r\n")
	mg.write("\r\n")
end

function send_ok()
	mg.write("HTTP/1.0 200 OK\r\n")
	mg.write("Content-Type: application/json\r\n")
	mg.write("Cache-Control: no-cache\r\n")
	send_info()
end

function send_error()
	mg.write("HTTP/1.0 500 Internal Server Error\r\n")
	send_info()
end

function encode(data)
	if type(data) == "string" then return data
	elseif type(data) == "table" then
		local s, r = pcall(json.encode, data)
		if s then
			return r
		else
			send_error()
			mg.write(r, "\r\n")
		end
	else return '{"1":0,"-1":0}' end
end

function decode(data)
	if type(data) == "string" then
		local s, r = pcall(json.decode, data)
		if s then
			return r
		else
			send_error()
			mg.write(r, "\r\n")
		end
	else return {["1"] = 0,["-1"] = 0} end
end

function send_json(data)
	data = encode(data)
	if data then
		send_ok()
		mg.write(data)
		mg.write("\r\n")
	end
end

function get_json()
	local f = io.open(fname)
	if f then
		local buf = f:read("*a")
		f:close()
		return decode(buf)
	end
	return decode()
end

if mg.request_info.request_method == "GET" then
	local data = get_json()
	if data then send_json(data) end
elseif mg.request_info.request_method == "POST" then
	local data = get_json()
	local post = decode(mg.read())
	if data and post then
		data["1"] = data["1"] + post["1"]
		data["-1"] = data["-1"] + post["-1"]
		data = encode(data)
		local f, e = io.open(fname, "w")
		if f then
			local s, e = f:write(data)
			f:close()
			if s then
				send_json(data)
			else
				send_error()
				mg.write(e, "\r\n")
			end
		else
			send_error()
			mg.write(e, "\r\n")
		end
	end
else
	mg.write("HTTP/1.0 405 Method Not Allowed\r\n")
	send_info()
end
