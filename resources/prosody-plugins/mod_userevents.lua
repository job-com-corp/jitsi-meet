local userevents_component
    = module:get_option_string("sipevents_component", "sipevents."..module.host);

-- Advertise room events component
module:add_identity("component", "sipevents", sipevents_component);
