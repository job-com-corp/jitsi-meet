--- Component to trigger an HTTP POST call on room created/destroyed events
--
--  Example config:
--
--    Component "sipevents.mydomain.com" "sipevents_component"
--        muc_component = "conference.mydomain.com"
--
--        api_domain = "dev-team.info"
--        api_path = "/api/local/meet-rooms"
--
--        --- The following are all optional
--        api_protocol = "http"
--        api_timeout = 10  -- timeout if API does not respond within 10s
--        retry_count = 5  -- retry up to 5 times
--        api_retry_delay = 1  -- wait 1s between retries
--        api_should_retry_for_code = function (code)
--            return code >= 500 or code == 408
--        end
--

local json = require "util.json";
local jid = require 'util.jid';
local jid_resource = require "util.jid".resource;
local http = require "net.http";
local timer = require 'util.timer';
local is_healthcheck_room = module:require "util".is_healthcheck_room;

local muc_component_host = module:get_option_string("muc_component");
--local api_url = module:get_option("api_url");
local api_protocol = module:get_option("api_protocol");
local api_domain = module:get_option("api_domain");
local api_path = module:get_option("api_path");

local api_timeout = module:get_option("api_timeout", 20);
local api_retry_count = tonumber(module:get_option("api_retry_count", 3));
local api_retry_delay = tonumber(module:get_option("api_retry_delay", 1));

-- Option for user to control HTTP response codes that will result in a retry.
-- Defaults to returning true on any 5XX code or 0
local api_should_retry_for_code = module:get_option("api_should_retry_for_code", function (code)
  return code >= 500;
end)

-- Cannot proceed if "api_path" not configured
if not api_path then
  module:log("error", "api_path not specified. Disabling %s.", module:get_name());
  return;
end

if not api_domain then
  module:log("warning", "api_domain not specified. Disabling %s.", module:get_name());
  return;
end

if not api_protocol then
  module:log("warning", "api_protocol not specified. Using 'https' as default in %s.", module:get_name());
  api_protocol = "https";
end

if muc_component_host == nil then
    log("error", "No muc_component specified. No muc to operate on!");
    return;
end

-- common HTTP headers added to all API calls
local http_headers = {
    ["User-Agent"] = "Prosody ("..prosody.version.."; "..prosody.platform..")";
    ["Content-Type"] = "application/json";
};

local function getTenantFromRoomName(roomjid)
    local pos = string.find(roomjid, '@');
    if pos > 0 then
        local roomname = string.sub(roomjid, 1, pos - 1);
        if string.len(roomname) > 32 then
            local tenant = string.sub(roomname, 33);
            return tenant;
        end
    else
        return nil;
    end
end

local function getJidNode(occupantjid)
    local node, host, resource = jid.split(occupantjid);

    return node;
end

--- Start non-blocking HTTP call
-- @param url URL to call
-- @param options options table as expected by net.http where we provide optional headers, body or method.
-- @param callback if provided, called with callback(response_body, response_code) when call complete.
-- @param timeout_callback if provided, called without args when request times out.
-- @param retries how many times to retry on failure; 0 means no retries.
local function async_http_request(url, options, callback, timeout_callback, retries)
    local completed = false;
    local timed_out = false;
    local retries = retries or api_retry_count;

    local function cb_(response_body, response_code)
        if not timed_out then  -- request completed before timeout
            completed = true;
            if (response_code == 0 or api_should_retry_for_code(response_code)) and retries > 0 then
                module:log("warn", "API Response code %d. Will retry after %ds", response_code, api_retry_delay);
                timer.add_task(api_retry_delay, function()
                    async_http_request(url, options, callback, timeout_callback, retries - 1)
                end)
                return;
            end

            module:log("debug", "%s %s returned code %s", options.method, url, response_code);

            if callback then
                callback(response_body, response_code)
            end
        end
    end

    local request = http.request(url, options, cb_);

    timer.add_task(api_timeout, function ()
        timed_out = true;

        if not completed then
            http.destroy_request(request);
            if timeout_callback then
                timeout_callback()
            end
        end
    end);

end

--- Returns current timestamp
local function now()
    return os.time();
end

--- Checks if event is triggered by healthchecks or focus user.
function is_system_event(event)
    if is_healthcheck_room(event.room.jid) then
        return true;
    end

    if event.occupant and jid.node(event.occupant.jid) == "focus" then
        return true;
    end

    return false;
end

--- Callback when an occupant joins room
function occupant_joined(event)
  if is_system_event(event) then
      return;
  end

  local room = event.room;
  local occupant = event.occupant;
  local occupant_node = jid.node(occupant.jid);
  local occupant_jid = occupant.jid
  if occupant_node != 'jigasi' then
    local phonenum = occupant:get_presence():get_child_text('nick', 'http://jabber.org/protocol/nick');
    local tenant = getTenantFromRoomName(room.jid);
    local roomname = jid.node(room.jid);
    local occupant_jid = occupant.jid
    local jitsi_id = string.match(occupant_jid, "/(.*)")
    local token_id = string.match(occupant_jid, "/[^@]*")
    local URL_EVENT_OCCUPANT_JOINED = api_protocol..'://'..tenant..'.'..api_domain..api_path..'/regular-user-join/'..roomname;
   
    module:log("info", "POST URL - %s", URL_EVENT_OCCUPANT_JOINED);
    
    async_http_request(URL_EVENT_OCCUPANT_JOINED, {
      headers = http_headers;
      method = "POST";
      body = json.encode({
        ['event']     = 'regular-user-joined';
        ['tokenId']   = token_id;
        ['jitsiId']   = jitsi_id;
        ['room-name'] = roomname;
     })
    })
    
    module:log("info", "Regular user joined");
    module:log("info", "jitsiId - %s", occupant_id);
    module:log("info", "tokenId - %s", token_id);
    module:log("info", "room-name - %s", roomname);

  end
end

--- Callback when an occupant has left room
function occupant_left(event)
    local room = event.room;

    if is_system_event(event) then
        return;
    end

    local room = event.room;
    local occupant = event.occupant;
    local occupant_node = jid.node(occupant.jid);
    local occupant_jid = occupant.jid
    if occupant_node != 'jigasi' then
      local phonenum = occupant:get_presence():get_child_text('nick', 'http://jabber.org/protocol/nick');
      local tenant = getTenantFromRoomName(room.jid);
      local roomname = jid.node(room.jid);
      local occupant_jid = occupant.jid
      local jitsi_id = string.match(occupant_jid, "/(.*)")
      local token_id = string.match(occupant_jid, "/[^@]*")
      local URL_EVENT_OCCUPANT_JOINED = api_protocol..'://'..tenant..'.'..api_domain..api_path..'/regular-user-leave/'..roomname;
     
      module:log("info", "POST URL - %s", URL_EVENT_OCCUPANT_JOINED);
      
      async_http_request(URL_EVENT_OCCUPANT_JOINED, {
        headers = http_headers;
        method = "POST";
        body = json.encode({
          ['event']     = 'regular-user-levae';
          ['tokenId']   = token_id;
          ['jitsiId']   = jitsi_id;
          ['room-name'] = roomname;
       })
      })
      
      module:log("info", "Regular user joined");
      module:log("info", "jitsiId - %s", occupant_id);
      module:log("info", "tokenId - %s", token_id);
      module:log("info", "room-name - %s", roomname);
    end
end


--- Register callbacks on muc events when MUC component is connected
function process_host(host)
    if host == muc_component_host then -- the conference muc component
        module:log("info","Hook to muc events on %s", host);

        local muc_module = module:context(host);
        muc_module:hook("muc-occupant-joined", occupant_joined, -1);
        muc_module:hook("muc-occupant-pre-leave", occupant_left, -1);
    end
end

if prosody.hosts[muc_component_host] == nil then
    module:log("info","No muc component found, will listen for it: %s", muc_component_host)

    -- when a host or component is added
    prosody.events.add_handler("host-activated", process_host);
else
    process_host(muc_component_host);
end
