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
     Contact Sensor:      sunrise <= sun <= sunset (sun is up)
      Motion Sensor:       dawn <= sun <= dusk
      Acceleration Sensor: night <= sun <= nightEnd
      Infrared Level:      dayNigthRatio

  Child Contact sensors are:
      Sun Position (contact opens in the position)
          SunNorth, SunSouth, SunEast, SunWest
          please refer to settings angleFromNorth and angleOfIncidence
          for ideal configuration for your home for these sensors

  Sun Time Interval (contact opens in the interval)
       SunEarlyMorning:   sunrise <= sun <= midmorning
       SunLateMorning:    midmorning <= sun <= noon
       SunEarlyAfternoon: noon <= sun <= midafternoon
       SunLateAfternoon:  midafternoon <= sun <= sunset
       SunEarlyNight:     sunset <= sun <= nadir (solar midnight)
       SunLateNight:      nadir <= sun <= sunrise
