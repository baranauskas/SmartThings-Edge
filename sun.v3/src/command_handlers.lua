-----------------------------------------------------------
-- Jose Augusto Baranauskas
-- 2022 08 30 v1
-----------------------------------------------------------
local capabilities = require('st.capabilities')
local log = require('log')

local config = require('config')
local seasons = require('seasons')
local SunCalc = require('SunCalc')

local capList = {"homeAngles", "sunPosition", "sunTimes2",
                 "seasonsPercentage1", "partsOfTheDay1"}
local cap = config.capabilities.load( capList )
-----------------------------------------------------------
local function boolPresence( b )     return config.ternary(b, "present", "not present")  end
--local function boolContact( b )      return config.ternary(b, "open", "closed")      end
local function boolMotion( b )       return config.ternary(b, "active", "inactive")  end
local function boolAcceleration( b ) return config.ternary(b, "active", "inactive")  end

--  Computes compass arithmetic (in degrees)
local function compassArithmetic( expression )
  --  Tranforms -360 < expression < 360 into [0,360)
  return math.fmod( expression, 360 ) % 360
end

local angle = { sunriseSunset = -0.833,
                dawnDusk      = -6,
                nightEndNight = -18
              }

local SunCalcTimes = {"nightEnd", "nauticalDawn", "dawn",
             "sunrise", "sunriseEnd", "goldenHourEnd",
             "midmorning", "solarNoon", "midafternoon",
             "goldenHour", "sunsetStart", "sunset",
             "night", "dusk", "nauticalDusk",
             "nadir"
            }
-----------------------------------------------------------
local command_handlers = {}
-----------------------------------------------------------
function command_handlers.refresh(driver, device)
--  log.info(string.format("refreshing device: %s", device.label))
  command_handlers.refreshSunTimes(driver, device)
  command_handlers.refreshSunPosition(driver, device)
end
-----------------------------------------------------------
function command_handlers.refreshSunPosition(driver, device)
--  log.info( "refreshSunPosition" )
  local now = os.time()
  local lat = device.preferences.locationLatitude
  local lng = device.preferences.locationLongitude
  -- sun position
  local p = SunCalc.getPosition( now , lat, lng )

--  local msg = ""
--  for key, value in pairs( p ) do --loop through the table
--    msg = msg .. string.format( "Sun Position %s = %f\n", key, value )
--  end
--  log.info( msg )

--[[
    Sun Position
       altitude (elevation): in the range [-90, +90] degrees
       azimuth: in the range [-180, +180] degress
                0 deg = south
                positive values are clockwise from south to north
                negative values are counterclockwise from south to north
       azimuthSunCycle: in the range [0, +360] degress
                0 deg = north
                values are counterclockwise from north to south
       azimuthCompass: in the range [0, +360] degress
                0 deg = north
                values are clockwise from north to south
]]

  local afn = device.preferences.angleFromNorth
  -- azimuthHome = azimuthSunCycle
  local azs = compassArithmetic( 180 - (p.azimuth - afn) )
  -- azimuthCompass
--  local azc = compassArithmetic( 180 + (p.azimuth - afn) )

  -- sun times
  local t = {}
  for k, field in pairs( SunCalcTimes ) do
    t[ field ] = device:get_field( field )
--    log.info( string.format( "getTimes from device %s=%s   %s", k, field, config.date.toString(t[field]) ) )
  end

  local eventVis = { visibility = { displayed = false} }

  -- main component
  local mainSensors = {
    up             = (p.altitude >= angle.sunriseSunset),
    dawnDusk       = (p.altitude >= angle.dawnDusk),
    nightEndNight  = (p.altitude >= angle.nightEndNight)
  }
  device:emit_event( capabilities.presenceSensor.presence( boolPresence( mainSensors.up ) ) )
  device:emit_event( capabilities.motionSensor.motion( boolMotion( mainSensors.dawnDusk ) ) )
  device:emit_event( capabilities.accelerationSensor.acceleration( boolAcceleration( mainSensors.nightEndNight ) ) )

  -- components
  local positionSensors = {
          altitude = p.altitude,
          azimuth  = p.azimuth,
          azimuthHome = azs
    }
  for sensor, state in pairs( positionSensors ) do
    device.profile.components["Position"]:emit_event( cap.sunPosition[sensor]( state, eventVis ) )
  end

  -- home angles
  --[[
    local aoi = device.preferences.angleOfIncidence
    North = sun_up and ((270.0 + aoi) <= azc or  azc < ( 90.0 - aoi)),
    West  = sun_up and ((  0.0 + aoi) <= azc and azc < (180.0 - aoi)),
    South = sun_up and (( 90.0 + aoi) <= azc and azc < (270.0 - aoi)),
    East  = sun_up and ((180.0 + aoi) <= azc and azc < (360.0 - aoi)),
  ]]
--  local azsNorth = config..ternary(270.0<=azs, azs-270.0, config.ternary(azs<90.0,azs+90.0, 0) )
  local angleSensors = {
--          north = config.ternary((270.0 <= azs) or  (azs <  90.0), azsNorth,  0,
          north = config.ternary(270.0<=azs, azs-270.0, config.ternary(azs<90.0,azs+90.0, 0) ),
          west  = config.ternary((  0.0 <= azs) and (azs < 180.0), azs      , 0),
          south = config.ternary(( 90.0 <= azs) and (azs < 270.0), azs- 90.0, 0),
          east  = config.ternary((180.0 <= azs) and (azs < 360.0), azs-180.0, 0)
        }
  for sensor, state in pairs( angleSensors ) do
    device.profile.components["Angles"]:emit_event( cap.homeAngles[sensor]( state, eventVis ) )
  end

--[[
  local componentSensors = {
          EarlyMorning   = (t.sunrise      <= now and now <= t.midmorning),
          LateMorning    = (t.midmorning   <= now and now <= t.solarNoon),
          EarlyAfternoon = (t.solarNoon    <= now and now <= t.midafternoon),
          LateAfternoon  = (t.midafternoon <= now and now <= t.sunset),
          EarlyNight     = (t.sunset       <= now or  now <= t.nadir),
          LateNight      = (t.nadir        <= now and now <= t.sunrise)
        }
  for sensor, state in pairs( componentSensors ) do
    device.profile.components[sensor]:emit_event( capabilities.presenceSensor.presence( boolPresence(state), eventVis ) )
  end
]]

  local potdSensors = {} -- parts of the day
  -- morning
  if (t.sunrise <= now and now <= t.solarNoon) then
    potdSensors.morning = 100 * (now - t.sunrise) / (t.solarNoon - t.sunrise)
  else
    potdSensors.morning = 0
  end
  -- afternoon
  if (t.solarNoon <= now and now <= t.sunset) then
    potdSensors.afternoon = 100 * (now - t.solarNoon) / (t.sunset - t.solarNoon)
  else
    potdSensors.afternoon = 0
  end
  -- night
  if (t.sunset <= now) then
    potdSensors.night = 100 * (      0.5 * (now - t.sunset) / ((t.nadir + 26*60*60) - t.sunset))
  elseif (now <= t.sunrise) then
    potdSensors.night = 100 * (0.5 + 0.5 * math.abs(now - t.nadir) / (t.sunrise - t.nadir))
  else
    potdSensors.night = 0
  end

  for sensor, state in pairs( potdSensors ) do
--    device:emit_event( cap.partsOfTheDay1[sensor]( state, eventVis ) )
    device.profile.components["PartsOfTheDay"]:emit_event( cap.partsOfTheDay1[sensor]( state, eventVis ) )
  end
end
-----------------------------------------------------------
function command_handlers.refreshSunTimes(driver, device)
  log.info( "refreshSunTimes" )
  --
  local now = os.time()
  local noon = config.date.toNoon( now )
  local month = config.date.getMonth( now )
  local lat = device.preferences.locationLatitude
  local lng = device.preferences.locationLongitude
--  local tzo = device.preferences.timezoneOffset

--  log.info( string.format( "now=%s, noon=%s", config.date.toString(now), config.date.toString(noon) ) )
--  log.info( string.format( "now tz=%s, noon tz=%s", config.date.toString(now, device.preferences.timezoneOffset),
--                            config.date.toString(noon, device.preferences.timezoneOffset) )  )

  local t   = SunCalc.getTimes( noon, lat, lng )
  for k,v in pairs( t ) do
--    log.info( string.format( "setTimes to device %s=%s   %s", k, v, config.date.toString(v) ) )
    device:set_field(k, v)
  end

  -- day and night lenghts
  local tm = config.date.clearTime( t.sunset )
  local result = {
          daytime      = tm + (t.sunset - t.sunrise),
          nighttime    = tm + (24*60*60) - (t.sunset - t.sunrise)
        }
  for k,v in pairs( result ) do
    log.info( string.format( "length %s = %s %s", k, v, config.date.toString(v) ) )
--    device:set_field(k, v)
  end

  -- dayLength Percentage
  local dayLength = 100 * (result.daytime - tm) / (24*60*60)
--  log.info( string.format( "dayLength = %6.2f", dayLength ) )
--  device:set_field( "dayLength", dayLength )

--  local daytime = config.date.toStringTime( result.daytime )
--  log.info( string.format( "daytime = %s", daytime ) )

--  local eventVis = { visibility = { displayed = false} }

  device.profile.components["Times"]:emit_event( cap.sunTimes2.dayLength( dayLength ) )
  device.profile.components["Times"]:emit_event( cap.sunTimes2.month( month ) )

  local isNorth = (lat >= 0)
  local seasonSensors = seasons.getSeasons( now, isNorth )
  for sensor, states in pairs( seasonSensors ) do
    local state = states.percentage
    local eventVis = { visibility = { displayed = (state > 0) } }
--    local day = config.date.toString( states.osTime, tzo )
--    log.info( string.format( "season = %s, start=%s, percentage=%6.2f", sensor, day, state ) )
    device.profile.components["Seasons"]:emit_event( cap.seasonsPercentage1[sensor]( state, eventVis ) )
  end
end
-----------------------------------------------------------
return command_handlers
-----------------------------------------------------------
