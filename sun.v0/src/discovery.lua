-----------------------------------------------------------
-- Jose Augusto Baranauskas
-- 2022 08 30 v1
-----------------------------------------------------------
local log = require('log')
local utils = require('st.utils')

local config = require("config")
-----------------------------------------------------------
local discovery = {}
-----------------------------------------------------------
-- handle discovery events, normally you'd try to discover devices on your
-- network in a loop until calling `should_continue()` returns false.
function discovery.handle_discovery(driver, _should_continue)
  log.info("Starting discovery")
  local metadata = {
    type = "LAN",
    -- the DNI must be unique across your hub, using static ID here so that we
    -- only ever have a single instance of this "device"
    device_network_id = config.device_network_id,
    label = "Sun Virtual Dial",
    profile = "sun.v1",
    manufacturer = "Baranauskas",
    model = "v1",
    vendor_provided_label = nil
  }
  log.info( utils.stringify_table(metadata) )
  -- tell the cloud to create a new device record, will get synced back down
  -- and `device_added` and `device_init` callbacks will be called
--  local tcd = driver:try_create_device( metadata )
--  if tcd then
--    log.info( "Device created successfully" )
--  else
--    log.error( "Device creation failed" )
--  end
  driver:try_create_device( metadata )
end
-----------------------------------------------------------
return discovery
-----------------------------------------------------------
