local userevents_component
    = module:get_option_string("userevents_component", "userevents."..module.host);

-- Advertise room events component
module:add_identity("component", "userevents", userevents_component);
