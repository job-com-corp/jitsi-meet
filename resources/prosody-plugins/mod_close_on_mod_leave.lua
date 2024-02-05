--- Jitsi prosody module to delete room after all moderators left room.
--- Installation:
---  1. Download this script to the Prosody plugins folder (/usr/share/jitsi-meet/prosody-plugins/)
---  2. Enable module in your prosody config. E.g.
---
---        Component "conference.meet.mydomain.com" "muc"
---              modules_enabled = {
---                 ...
---                 ...
---                 "close_on_mod_leave";
---              }
---              room_close_when_no_mod_timeout = 30  -- set your timeout (seconds)
---
---  3. For most scenarios you may want to disable auto-ownership on Jicofo. This assumes you have some other mechanism
---      to determine who becomes moderator e.g. with JWT an https://github.com/jitsi-contrib/prosody-plugins/tree/main/token_affiliation
---
---            hocon -f /etc/jitsi/jicofo/jicofo.conf set jicofo.conference.enable-auto-owner false
---
---  4. Restart prosody and jicofo
---
local LOGLEVEL = "info"
local TIMEOUT = module:get_option_number("room_close_when_no_mod_timeout", 10)

local is_admin = require "core.usermanager".is_admin
local is_healthcheck_room = module:require "util".is_healthcheck_room
local timer = require "util.timer"
module:log(LOGLEVEL, "loaded")

local function _is_admin(jid)
    return is_admin(jid, module.host)
end


module:hook("muc-occupant-left", function (event)
    local room, occupant = event.room, event.occupant

    if is_healthcheck_room(room.jid) or _is_admin(occupant.jid) then
        return
    end

    -- no need to do anything for normal participant
    if room:get_affiliation(occupant.jid) ~= "owner" then
        module:log(LOGLEVEL, "participant left, %s", occupant.jid)
        return
    end

    -- the owner is gone, start to check the room condition

    module:log(LOGLEVEL, "moderator left, %s", occupant.jid)

    -- check if there is any other owner here
    for _, o in room:each_occupant() do
        if not _is_admin(o.jid) then
            if room:get_affiliation(o.jid) == "owner" then
                module:log(LOGLEVEL, "another moderator still in the room, %s", o.jid)
                return
            end
        end
    end

    module:log(LOGLEVEL, "no moderators left in room. Will close room after timeout")
        
    -- since there is no other owner, destroy the room after TIMEOUT secs
    timer.add_task(TIMEOUT, function()
        if is_healthcheck_room(room.jid) then
            return
        end
                       
        -- last check before destroying the room
        -- if the owner is returned, cancel
        for _, o in room:each_occupant() do
            if not _is_admin(o.jid) then
                if room:get_affiliation(o.jid) == "owner" then
                    module:log(LOGLEVEL, "cancelling room close since moderator has rejoined, %s", o.jid)
                    return
                end
            end
        end
                
        module:log(LOGLEVEL, "Moderatorless room timed out. Destroying room")
        room:destroy(nil, "No owner left in room.");
    end)
end)
