
function call_taxi_to_player(pid)

    local target_ped = NATIVE.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local target_coords = higurashi.get_player_coords(pid)--NATIVE.GET_ENTITY_COORDS(target_ped, true)
    
    local taxi_model = NAYIVE.GET_HASH_KEY("taxi")
    NATIVE.REQUEST_MODEL(taxi_model)
    while not NATIVE.HAS_MODEL_LOADED(taxi_model) do
        wait(0)
    end
    
    local taxi = NATIVE.CREATE_VEHICLE(taxi_model, target_coords.x, target_coords.y, target_coords.z + 5.0, 0.0, true, false)
    
    local driver_model = joaat("s_m_m_taxidriver_01")
    NATIVE.REQUEST_MODEL(driver_model)
    while not NATIVE.HAS_MODEL_LOADED(driver_model) do
        wait(0)
    end
    
    local driver = NATIVE.CREATE_PED_INSIDE_VEHICLE(taxi, 26, driver_model, -1, true, false)
    
    local waypoint_blip = NATIVE.GET_FIRST_BLIP_INFO_ID(NATIVE.GET_HASH_KEY("BLIP_DESTINATION"))
    if NAYIVE.DOES_BLIP_EXIST(waypoint_blip) then
        local waypoint_coords = NATIVE.GET_BLIP_INFO_ID_COORD(waypoint_blip)
        while true do
            wait(1000)
            if NATIVE.IS_PED_IN_VEHICLE(target_ped, taxi, true) then

                NATIVE.TASK_VEHICLE_DRIVE_TO_COORD(driver, taxi, waypoint_coords.x, waypoint_coords.y, waypoint_coords.z, 20.0, 0, taxi_model, 786603, 5.0, true)
                break
            end
        end
    else
        print("")
    end
end


menu.add_feature("Call Taxi to Player", "action", 0, function(f)

    local selected_pid = 
    call_taxi_to_player(selected_pid)
end)
