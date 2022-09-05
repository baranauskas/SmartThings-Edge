-----------------------------------------------------------
-- Jose Augusto Baranauskas
-- 2022 08 30 v1
-----------------------------------------------------------
local capabilities = require('st.capabilities')
local log = require('log')

local config = require("config")
local SunCalc = require('SunCalc')
-----------------------------------------------------------
local function ternary(a, b, c) if a then return b end return c end

local function boolContact( b )       return ternary( b, "open", "closed" )     end
local function boolMotion( b )        return ternary( b, "active", "inactive")  end
local function boolAcceleration( b )  return ternary( b, "active", "inactive")  end

--  Computes compass arithmetic (in degrees)
local function compassArithmetic( expression )
  --  Tranforms -360 < expression < 360 into [0,360)
  return math.fmod( expression, 360 ) % 360
end

local angle = { sunriseSunset = -0.833,
                dawnDusk      = -6,
                nightEndNight = -18
              }
 -----------------------------------------------------------
local command_handlers = {}
-----------------------------------------------------------
function command_handlers.refresh(driver, device)
  log.info(string.format("refreshing device: %s", device.label))
  command_handlers.refreshSunTimes(driver, device)
  command_handlers.refreshSunPosition(driver, device)

--[[
  local stateValue = device:get_latest_state("main",
        capabilities.motionSensor.ID,
        capabilities.motionSensor.motion.NAME, "vazio1", "vazio2")
  log.info("stateValue=" .. stateValue)
  if stateValue == "active" then
    device:emit_event( capabilities.motionSensor.motion.inactive() )
  else
    device:emit_event( capabilities.motionSensor.motion.active() )
  end
]]
end
-----------------------------------------------------------
function command_handlers.refreshSunPosition(driver, device)
  log.info( "refreshSunPosition" )
--[[  local stateValue = device:get_latest_state("main",
        capabilities.contactSensor.ID,
        capabilities.contactSensor.contact.NAME, "vazio1", "vazio2")
  log.info("stateValue=" .. stateValue)
  if stateValue == "open" then
    device:emit_event( capabilities.contactSensor.contact.closed() )
  else
    device:emit_event( capabilities.contactSensor.contact.open() )
  end
]]
  -- -------------
  local now = os.time()
  local lat = device.preferences.locationLatitude
  local lng = device.preferences.locationLongitude
  -- sun position
  local p = SunCalc.getPosition( now , lat, lng )

  local msg = ""
  for key, value in pairs( p ) do --loop through the table
    msg = msg .. string.format( "Sun Position %s = %f\n", key, value )
  end
  log.info( msg )

  local afn = device.preferences.angleFromNorth
  local aoi = device.preferences.angleOfIncidence
  local azc = compassArithmetic( 180 - p.azimuth + afn )

  local sun_up    = (p.altitude >= angle.sunriseSunset)
  local childPositionSensors = {
          North = sun_up and ((270.0 + aoi) <= azc or  azc < ( 90.0 - aoi)),
          West  = sun_up and ((  0.0 + aoi) <= azc and azc < (180.0 - aoi)),
          South = sun_up and (( 90.0 + aoi) <= azc and azc < (270.0 - aoi)),
          East  = sun_up and ((180.0 + aoi) <= azc and azc < (360.0 - aoi))
        }

  -- sun times
  local t = {}
  for k, field in pairs( config.SunCalcTimes ) do
    t[ field ] = device:get_field( field )
    log.info( string.format( "getTimes from device %s=%s   %s", k, field, config.date.toString(t[field]) ) )
  end
  local childTimeSensors = {
          EarlyMorning   = (t.sunrise      <= now and now <= t.midmorning),
          LateMorning    = (t.midmorning   <= now and now <= t.solarNoon),
          EarlyAfternoon = (t.solarNoon    <= now and now <= t.midafternoon),
          LateAfternoon  = (t.midafternoon <= now and now <= t.sunset),
          EarlyNight     = (t.sunset       <= now or  now <= t.nadir),
          LateNight      = (t.nadir        <= now and now <= t.sunrise)
        }

  -- main component
  device:emit_event( capabilities.contactSensor.contact( boolContact(sun_up) ) )
  device:emit_event( capabilities.motionSensor.motion( boolMotion( p.altitude >= angle.dawnDusk ) ) )
  device:emit_event( capabilities.accelerationSensor.acceleration( boolAcceleration( p.altitude >= angle.nightEndNight ) ) )

  -- child components
  for sensor, state in pairs( childPositionSensors ) do
    device.profile.components[sensor]:emit_event( capabilities.contactSensor.contact( boolContact(state) ) )
  end
  for sensor, state in pairs( childTimeSensors ) do
    device.profile.components[sensor]:emit_event( capabilities.contactSensor.contact( boolContact(state) ) )
  end
end
-----------------------------------------------------------
function command_handlers.refreshSunTimes(driver, device)
  log.info( "refreshSunTimes" )

--[[  local stateValue = device:get_latest_state("main",
        capabilities.presenceSensor.ID,
        capabilities.presenceSensor.presence.NAME, "vazio1", "vazio2")
  log.info("stateValue=" .. stateValue)
  if stateValue == "present" then
    device:emit_event( capabilities.presenceSensor.presence.not_present() )
  else
    device:emit_event( capabilities.presenceSensor.presence.present() )
  end
]]
  --
  local now = os.time()
  local noon = config.date.toNoon( now )
  local lat = device.preferences.locationLatitude
  local lng = device.preferences.locationLongitude
  log.info( string.format( "now=%s, noon=%s", config.date.toString(now), config.date.toString(noon) ) )
  log.info( string.format( "now tz=%s, noon tz=%s", config.date.toString(now, device.preferences.timezoneOffset),
                            config.date.toString(noon, device.preferences.timezoneOffset) )  )

  local t   = SunCalc.getTimes( noon, lat, lng )
  for k,v in pairs( t ) do
    log.info( string.format( "setTimes to device %s=%s   %s", k, v, config.date.toString(v) ) )
    device:set_field(k, v)
  end

  -- day and night lenghts
  local tm = config.date.clearTime( t.sunset )
  local result = {daytime      = tm + (t.sunset - t.sunrise),
                  nighttime    = tm + (24*60*60) - (t.sunset - t.sunrise)
        }
  for k,v in pairs( result ) do
    log.info( string.format( "length %s = %s %s", k, v, config.date.toString(v) ) )
    device:set_field(k, v)
  end

  -- dayNigthRatio
  local dayNigthRatio = (result.daytime - tm) / (24*60*60)
  log.info( string.format( "dayNigthRatio %6.2f", dayNigthRatio * 100.0 ) )
  device:set_field( "dayNigthRatio", dayNigthRatio )
  device:emit_event( capabilities.infraredLevel.infraredLevel( dayNigthRatio * 100.0 ) )
end
-----------------------------------------------------------
return command_handlers
-----------------------------------------------------------
--[[
length nighttime = 1662380041.9215 2022-09-05 12:14:02+00
length daytime   = 1662378358.0785 2022-09-05 11:45:58+00
dayNigthRatio   0.49

]]
