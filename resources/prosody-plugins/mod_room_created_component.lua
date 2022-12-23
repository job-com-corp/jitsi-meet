function room_created(event)
    local room = event.room;
    local tenant = getTenantFromRoomName(room.jid);
    local roomname = jid.node(room.jid);
    local URL_EVENT_OCCUPANT_JOINED = api_protocol..'://'..tenant..'.'..api_domain..api_path..'/room-created/'..roomname;
    module:log("info", "POST URL - %s", URL_EVENT_OCCUPANT_JOINED);
    
    async_http_request(URL_EVENT_OCCUPANT_JOINED, {
       headers = http_headers;
       method = "POST";
       body = json.encode({
         ['event'] = 'room-created';
       })
    })

    module:log("info", "room-created - %s", phonenum);
end