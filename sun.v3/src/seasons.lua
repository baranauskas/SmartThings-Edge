local config = require('config')
-----------------------------------------------------------
-- times is a sorted time array
-- finds the index where osTime is in times
local function rangeIndex( osTime, times )
  local index = 0
  for i=1, (#times-1) do
    if (times[i] <= osTime) and (osTime < times[i+1]) then
      index = i
      break
    end
  end
  return index
end
-----------------------------------------------------------
local function seasonNames( isNorth )

-- lastYear, thisYear, nextYear
-- last.decemberSolstice, this.marchEquinox, this.juneSolstice, this.septemberEquinox, this.decemberSolstice, next.marchEquinox
-- range index          1                  2                  3                      4                      5
-- season index         1                  2                  3                      4                      1
-- EquinoxSolstice idx  4                  1                  2                      3                      4
-- South             Summer             Autumn              Winter                 Spring                Summer
-- North             Winter             Spring              Summer                 Autumn                Winter

  local seasons
  local indexEquinoxSolstice  = { 4, 1, 2, 3 }
  if ( isNorth ) then
    seasons = { "winter", "spring", "summer", "autumn" }
  else
    seasons = { "summer", "autumn", "winter", "spring" }
  end
  return seasons, indexEquinoxSolstice
end
-----------------------------------------------------------
-- Julian to Gregorian
local function J2G ( jda )
  local jd = math.floor(jda + 0.5)
  local z = jda - jd + 0.500001
  local tz = jd - 1721117
  if (jd > 2299160) then
    tz = tz + (math.floor((tz + 2) / 36524.25) - math.floor((tz + 2) / 146097) - 2)
  end
  local y = math.floor((tz - 0.2) / 365.25) -- year
  local r = tz - math.floor(y * 365.25)
  local m = math.floor((r - 0.5) / 30.6) -- month
  local d = r - math.floor(m * 30.6 + 0.5) -- day
  m = m + 3
  if (m > 12) then
    m = m - 12
    y = y + 1
  end

  local h1 = z * 24
  local ho = math.floor(h1)
  local mi = math.floor((h1 - ho) * 60)
--  local s = string.format("%04d-%02d-%02d %02d:%02d",y,m,d, ho,mi)
-- return s
  return os.time{year=y, month=m, day=d, hour=ho, min=mi}
end
-----------------------------------------------------------
local astronomicalSeasons = {}
-----------------------------------------------------------
-- with a deviation less than 15 minutes
function astronomicalSeasons.getEquinoxSolstice( year )
  local Y = (year - 2000) / 1000.0
  local equinoxSolstice = {
    marchEquinox = J2G( 2451623.80984 + 365242.37404 * Y + 0.05169 * math.pow(Y,2) - 0.00411 * math.pow(Y,3) - 0.00057 * math.pow(Y,4) ),
    juneSolstice = J2G( 2451716.56767 + 365241.62603 * Y + 0.00325 * math.pow(Y,2) + 0.00888 * math.pow(Y,3) - 0.00030 * math.pow(Y,4) ),
    septemberEquinox = J2G( 2451810.21715 + 365242.01767 * Y - 0.11575 * math.pow(Y,2) + 0.00337 * math.pow(Y,3) + 0.00078 * math.pow(Y,4) ),
    decemberSolstice = J2G( 2451900.05952 + 365242.74049 * Y - 0.06223 * math.pow(Y,2) - 0.00823 * math.pow(Y,3) + 0.00032 * math.pow(Y,4) )
  }
  return equinoxSolstice
end
-----------------------------------------------------------
function astronomicalSeasons.getSeasons( osTime, isNorth )
  local now = config.math.round( osTime or os.time() )
  local year = os.date("!*t", now).year

  local lastYear = astronomicalSeasons.getEquinoxSolstice( year-1 )
  local thisYear = astronomicalSeasons.getEquinoxSolstice( year )
  local nextYear = astronomicalSeasons.getEquinoxSolstice( year+1 )

  local times = {
    lastYear.decemberSolstice,
    thisYear.marchEquinox,
    thisYear.juneSolstice,
    thisYear.septemberEquinox,
    thisYear.decemberSolstice,
    nextYear.marchEquinox
  }

  -- [1,5]
  local rangeIndex = rangeIndex( now, times )
  -- [1,4]
  local seasonIndex = config.ternary( rangeIndex <=4, rangeIndex, 1 )
  -- [1,4]
  local seasonNames, index = seasonNames( isNorth )
  -- [1,4]
  local seasons = {}
  local j, percentage
  for i=1,#seasonNames do
    if (i == seasonIndex) then
      percentage = 100.0 * (now-times[rangeIndex]) / (times[1+rangeIndex]-times[rangeIndex])
    else
      percentage = 0.0
    end
    j = index[i]
    seasons[ seasonNames[i] ] = { osTime = times[1+j], percentage = percentage }
  end
  return seasons
end
-----------------------------------------------------------
return astronomicalSeasons
-----------------------------------------------------------
