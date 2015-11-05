local cjson = require "cjson"
local string = require "string"

-- some quick and dirty hacks to get basic routing working
host = ngx.req.get_headers()["Host"]
vhost = ngx.req.get_headers()["Host"]

-- skip ip based hostnames: healthcheck
if string.find(vhost, "%d%d") == 0 then
   ngx.exit(ngx.HTTP_OK)
end

-- can only resolve apps that *don't* contain a period
-- this also impacts route-able app names
vhost = string.gsub(vhost, "%.", "--")


-- ask locally defined nginx upstream aliased under __mesos_dns
resp = ngx.location.capture('/__mesos_dns/v1/services/_' .. vhost .. '._tcp.marathon.mesos')

ngx.log(ngx.INFO, 'vhost:' .. vhost .. ' response: ' .. resp.body)

if string.len(resp.body) == 0 then
   ngx.exit(ngx.HTTP_NOT_FOUND)
else
   backends = cjson.decode(resp.body)
   backend = backends[math.random(#backends)]
   if backend['ip'] == "" then
      ngx.say("[ERROR] nothing resolved for " .. host)
      ngx.exit(ngx.HTTP_OK)
   end
   ngx.var.target = "http://" .. backend['ip'] .. ":"  .. backend['port']
end