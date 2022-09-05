-- require st provided libraries
local capabilities = require('st.capabilities')
local Driver = require('st.driver')
-----------------------------------------------------------
-- require custom handlers from driver package
local command_handlers = require("command_handlers")
local discovery = require("discovery")
local lifecycle_handlers = require("lifecycle_handlers")
-----------------------------------------------------------
-- create the driver object
local myDriver = Driver("sun", {
        discovery = discovery.handle_discovery,
        lifecycle_handlers = {
          added       = lifecycle_handlers.added,
          init        = lifecycle_handlers.init,
          removed     = lifecycle_handlers.removed,
          infoChanged = lifecycle_handlers.infoChanged
        },
        capability_handlers = {
          [capabilities.refresh.ID] = {
            [capabilities.refresh.commands.refresh.NAME] = command_handlers.refresh
          },
          [capabilities.infraredLevel.ID] = {
            [capabilities.infraredLevel.commands.setInfraredLevel.NAME] = command_handlers.setInfraredLevel
          }
        }
      })
-----------------------------------------------------------
-- run the driver
myDriver:run()
-----------------------------------------------------------
