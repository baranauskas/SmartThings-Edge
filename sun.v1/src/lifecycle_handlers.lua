-----------------------------------------------------------
-- Jose Augusto Baranauskas
-- 2022 08 30 v1
-----------------------------------------------------------
local capabilities = require('st.capabilities')
local log = require('log')

local config = require("config")
local command_handlers = require("command_handlers")
-----------------------------------------------------------
local lifecycle_handlers = {}
-----------------------------------------------------------
-- this is called once a device is added by the cloud and synchronized down to the hub
function lifecycle_handlers.added(driver, device)
  log.info( string.format("adding new device: %s", device.label) )
end
-----------------------------------------------------------
-- this is called both when a device is added (but after `added`) and after a hub reboots.
function lifecycle_handlers.init(driver, device)
  log.info( string.format("initializing device: %s", device.label) )

  device:emit_event( capabilities.presenceSensor.presence.not_present() )
  device:emit_event( capabilities.infraredLevel.infraredLevel( 50 ) )

  lifecycle_handlers.reschedule(driver, device)
  command_handlers.refresh(driver, device)
  device:online()
end
-----------------------------------------------------------
-- this is called when a device is removed by the cloud and synchronized down to the hub
function lifecycle_handlers.removed(driver, device)
  log.info( string.format("removing device: %s", device.label) )
  lifecycle_handlers.unschedule(driver, device)
end
-----------------------------------------------------------
-- this is called when a device preference changes
function lifecycle_handlers.infoChanged(driver, device, event, args)
  log.info("infoChanged")
  local doReschedule = (args.old_st_store.preferences.locationLatitude ~= device.preferences.locationLatitude)
           or (args.old_st_store.preferences.locationLongitude ~= device.preferences.locationLongitude)
  if doReschedule then
    log.info("infoChanged reschedule is necessary")
    lifecycle_handlers.reschedule(driver, device)
  end
  command_handlers.refresh(driver, device)
end
-----------------------------------------------------------
function lifecycle_handlers.unschedule(driver, device)
  log.info( string.format("canceling %d timers", #(device.thread.timers) ) )
  for timer in pairs( device.thread.timers ) do
    device.thread:cancel_timer( timer )
  end
end
-----------------------------------------------------------
function lifecycle_handlers.reschedule(driver, device)
  log.info( "rescheduling" )
  lifecycle_handlers.unschedule(driver, device)
  lifecycle_handlers.scheduleRefreshSunTimes(driver, device)
  lifecycle_handlers.scheduleRefreshSunPosition(driver, device)
end
-----------------------------------------------------------
function lifecycle_handlers.scheduleRefreshSunPosition(driver, device)
  local timer = device.thread:call_on_schedule(
          config.schedule.RunEveryRefreshSunPosition(),
          function ()
            return command_handlers.refreshSunPosition(nil, device)
          end,
          'refreshSunPosition schedule runEvery'
        )
  if timer then
    log.info( "scheduling refreshSunPosition successfully every " ..
             config.schedule.RunEveryRefreshSunPosition() .. " seconds")
  else
    log.info( "scheduling refreshSunPosition failed" )
  end
end
-----------------------------------------------------------
function lifecycle_handlers.scheduleRefreshSunTimes(driver, device)
  local delay = config.schedule.DelayRefreshSunTimes( device.preferences.timezoneOffset )
  -- first run next day
  local timerFirst = device.thread:call_with_delay(
            delay,
            function ()
               command_handlers.refreshSunTimes(nil, device)
            end,
            'refreshSunTimes first schedule delay'
        )
  local data = config.date.toString(os.time() + delay, device.preferences.timezoneOffset )
  if timerFirst then
    log.info( "scheduling first refreshSunTimes successfully at " .. data )
  else
    log.info( "scheduling first refreshSunTimes failed" )
  end

  -- other runs every day after
  local timerOthers = device.thread:call_with_delay(
            delay,
            function ()
              device.thread:call_on_schedule(
                     config.schedule.RunEveryRefreshSunTimes(),
                      function ()
                         command_handlers.refreshSunTimes(nil, device)
                      end,
                      'refreshSunTimes others schedule runEvery'
              )
              end,
              'refreshSunTimes others schedule delay'
        )
  if timerOthers then
    log.info( "scheduling others refreshSunTimes successfully every " ..
               config.schedule.RunEveryRefreshSunTimes() / (60*60) .. " hours" )
  else
    log.info( "scheduling others refreshSunTimes failed" )
  end

end
-----------------------------------------------------------
return lifecycle_handlers
-----------------------------------------------------------
