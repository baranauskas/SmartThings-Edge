# Baranauskas Sun based on SunCalc

Sun Edge driver

Copyright 2022 Jose Augusto Baranauskas

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at:

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

https://api.smartthings.com/invitation-web/accept?id=355424df-4760-434b-8fa4-c2de4a23e1e5

https://bestow-regional.api.smartthings.com/invite/1PlY1JR7gkle

This edge driver implements solar sensors as well as time intervals over day, night e seasons events.

  The main sensors are:
      Presence Sensor:     sunrise <= sun <= sunset (sun is up)
      Motion Sensor:       dawn <= sun <= dusk
      Acceleration Sensor: night <= sun <= nightEnd

  Components:
      Position: altitude (elevation), azimuth are real sun positions in
      the sky. AzimuthHome adds or subtracts angleFromNorth from azimuth.
         altitude (elevation): in the range [-90, +90] degrees
                  positive values: sun is up
                  negative values: sun is down               
         azimuth: in the range [-180, +180] degrees
                  0 deg = south
                  positive values are clockwise from south to north
                  negative values are counterclockwise from south to north
         azimuthHome: in the range [0, +360] degrees
                  0 deg = north, 90 deg = west, 180 = south, 270 = east
                  values are counterclockwise from north  to south
                  (270,360) or (0,90): north
                  (0,180): west
                  (90,270): south
                  (180,360): east

      Home Angles: Sun azimuth angles [0,180] converted to north, west, south,
      and east sides from your home. Please refer to setting angleFromNorth
      for ideal configuration. Angles are counterclockwise from north to south

      Parts Of The Day: [0,100%]
                  morning: sunrise, midmorning, noon (0%, 50%, 100%)
                  afternoon: noon. midafternoon, sunset (0%, 50%, 100%)
                  night: sunset, nadir (solar midnight), sunrise (0%, 50%, 100%)
          With these sensors, day and night (sub)parts can be easily defined
          EarlyMorning:   sunrise <= sun <= midmorning (0 < morning sensor <= 50%)
          LateMorning:    midmorning <= sun <= noon (50 < morning sensor <= 100%)
          EarlyAfternoon: noon <= sun <= midafternoon (0 < afternoon sensor < 50%)
          LateAfternoon:  midafternoon <= sun <= sunset (50 < afternoon sensor < 100%)
          EarlyNight:     sunset <= sun <= nadir (solar midnight) (0 < night sensor < 50%)
          LateNight:      nadir <= sun <= sunrise (50 < night sensor < 100%)

      Seasons: [0,100%]
                  astronomical seasons of the year: summer, autumn, winter, spring    

      Times: [0,100%]
           dayLength: day length (sun is up) percentage over full daytime (24 hours)

      Preferences:
           angleFromNorth is the angle (in degrees) of the home from real North
                           [0,+90] towards East
                           [0,-90] towards West
           Use non-zero values only if you want to make some adjustments to facilitate
           your orientation towards your home with cardinal points
           Otherwise, use zero for compass values (no correction)
