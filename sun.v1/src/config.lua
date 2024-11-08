-----------------------------------------------------------
-- Jose Augusto Baranauskas
-- 2022 08 30 v1
-----------------------------------------------------------
local config = {}
-----------------------------------------------------------
config.schedule = {}
-- schedule period in seconds
function config.schedule.RunEveryRefreshSunPosition()
  return 1 * 60
end

function config.schedule.DelayRefreshSunTimes( timezone )
  return config.date.remainingSecondsToMidnight( os.time(), math.random(10, 50), timezone )
end

function config.schedule.RunEveryRefreshSunTimes()
  return 24 * 60 * 60
end
-----------------------------------------------------------
config.date = {}

function config.date.remainingSecondsToMidnight( osTime, secondsToAdd, timezone )
  osTime = config.math.round( osTime or os.time() )
  secondsToAdd = secondsToAdd or 0
  timezone = timezone or 0

  local localTime = osTime + timezone * 60 * 60
  local now = os.date("!*t", localTime )
  local remainingSeconds = (now.hour * -3600 - now.min * 60 - now.sec) % 86400
  return remainingSeconds + secondsToAdd
end

function config.date.clearTime( osTime )
  osTime = config.math.round( osTime or os.time() )

  local now = os.date("!*t", osTime )
  local midnight = osTime - (3600 * now.hour + 60 * now.min + now.sec)
  return midnight
end

function config.date.toNoon( osTime )
  osTime = config.math.round( osTime or os.time() )

  local noon = config.date.clearTime( osTime ) + 12*60*60
  return noon
end


function config.date.toString( osTime, timezone )
  osTime = config.math.round( osTime or os.time() )
  timezone = timezone or 0
  osTime   = osTime + timezone * 60 * 60 -- local time
  local offset
  if timezone >= 0 then
    offset = string.format( "+%02d", timezone ) -- +HH
  else
    offset = string.format( "%03d", timezone )  -- -HH
  end
  return os.date('%Y-%m-%d %H:%M:%S', osTime ) .. offset
end
-----------------------------------------------------------
config.math = {}

function config.math.round(x) return math.floor( x + 0.5 ) end
-----------------------------------------------------------
config.device_network_id = "Baranauskas-sun-20220829"

config.sensorNames = {"North", "West", "South", "East",
       "EarlyMorning", "LateMorning",
       "EarlyAfternoon", "LateAfternoon",
       "EarlyNight", "LateNight"
      }

config.SunCalcTimes = {"nightEnd", "nauticalDawn", "dawn",
       "sunrise", "sunriseEnd", "goldenHourEnd",
       "midmorning", "solarNoon", "midafternoon",
       "goldenHour", "sunsetStart", "sunset",
       "night", "dusk", "nauticalDusk",
       "nadir"
      }
-----------------------------------------------------------
return config
-----------------------------------------------------------
