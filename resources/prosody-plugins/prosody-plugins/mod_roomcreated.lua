local roomcreated_component
    = module:get_option_string("roomcreated_component", "roomcreated."..module.host);

-- Advertise room events component
module:add_identity("component", "roomcreated", roomcreated_component);
