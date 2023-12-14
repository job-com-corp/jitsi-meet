local recordingevents_component
    = module:get_option_string("recordingevents_component", "recordingevents."..module.host);

-- Advertise speaker stats so client can pick up the address and start sending
-- dominant speaker events
module:add_identity("component", "recordingevents", recordingevents_component);
