# Baranauskas Sun based on SunCalc

Sun Edge driver

Copyright 2020 Jose Augusto Baranauskas

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at:

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed
  on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License
  for the specific language governing permissions and limitations under the License.

This device handler implements solar position sensors as well as
time intervals over day and night events.

  The parent sensors are:
      Presence Sensor:     sunrise <= sun <= sunset (sun is up)
      Motion Sensor:       dawn <= sun <= dusk
      Acceleration Sensor: night <= sun <= nightEnd
      Infrared Level:      dayNigthRatio

  Child Presence sensors are:
      Sun Position (present in the position)
          SunNorth, SunSouth, SunEast, SunWest
          please refer to settings angleFromNorth and angleOfIncidence
          for ideal configuration for your home for these sensors

  Sun Time Interval (present in the interval)
       SunEarlyMorning:   sunrise <= sun <= midmorning
       SunLateMorning:    midmorning <= sun <= noon
       SunEarlyAfternoon: noon <= sun <= midafternoon
       SunLateAfternoon:  midafternoon <= sun <= sunset
       SunEarlyNight:     sunset <= sun <= nadir (solar midnight)
       SunLateNight:      nadir <= sun <= sunrise

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


       // Home angles
       // angleFromNorth is the angle (in degrees) of the home from real North
       //                [0,+90] towards East
       //                [0,-90] towards West
       // Use non-zero values only if you want to make some adjustments to facilitate
       // your orientation towards your home with cardinal points
       // Otherwise, use zero for compass values (no correction)
       // Copy from the respective settings value
       attribute "angleFromNorth",         "number"

       // angleOfIncidence is the angle (in degrees) from which the incidence
       // of the sun is considered at each cardinal region
       // For example, assume that the sun is moving towards the west face of your home.
       // If you use 45 degrees then only when the sun reaches 45 degrees
       // or more on the west face will the respective sensor indicate the incidence
       // of sun on that face of your home.
       // Copy from the respective settings value
       attribute "angleOfIncidence",       "number"

       // azimuthCompass: in the range [0, +360] degress (compass convention values)
       //        clockwise from north
       // azimuthCompass  considers azimuth adjustment using angleFromNorth
       // azimuthCompass  simplified formula is (180 - azimuth) + angleFromNorth
       //        negative angles are converted to positive ones using
       //        compass arithmetic
       attribute "azimuthCompass",         "number"
