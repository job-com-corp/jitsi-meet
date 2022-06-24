local recordingevents_component
    = module:get_option_string("roomevents_component", "roomevents."..module.host);

-- Advertise room events component
module:add_identity("component", "roomevents", roomevents_component);
