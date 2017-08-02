'' RGB_LED_Demo
'' by Gavin T. Garner
'' University of Virginia
'' April 20, 2012
'' Updated September 2016
{  This program demonstrates how to use my WS2812B_RGB_LED_Driver object and shows how to call its methods.}

CON                          
  _xinfreq=6_250_000          'The system clock is set at 100MHz (you need at least a 20MHz system clock)
  _clkmode=xtal1+pll16x       '(I have been overclocking my Propeller chips with impunity for years!^)    

  TotalLEDs=768   '<---set the maximum number of LEDs you wish to control (eg. 30 for 1m strip, 60 for 2m
                 '    strip, 120 for two 2m strips wired in series, etc.) Code has been tested up to 4m
  LetterOffset=64 '<---set the # of LEDs taken up by a single letter
OBJ
  rgb : "WS2812B_RGB_LED_Driver_v2"           'Include WS2812B_RGB_LED_Driver object and call it "rgb" for short

PUB Demo | i, j, x, maxAddress
  'rgb.start(0,TotalLEDs, -1, -1)  'Start up RGB LED driver on a new cog, set data pin to be P0, 
  rgb.start(0,TotalLEDs, 5, 6)    'Start up RGB LED driver on a new cog, set data pin to be P0,   
                                  ' and specify that there are 60 LEDs in the strip (2 meters)
  maxAddress:=TotalLEDs-1         'LED addresses start with zero so 59 will be the maximum address
repeat
  rgb.AllOff                      'You can turn off all of the LEDs at once
  waitcnt(clkfreq+cnt)

  rgb.AllOff

  rgb.Triangle(rgb.Intensity(rgb#orange, 32), rgb.Intensity(rgb#blue, 32), 20)
  waitcnt(clkfreq + cnt)
  rgb.AllOff

  rgb.LED_STRING(STRING(" go hoos go "), 0, LetterOffset, rgb.Intensity(rgb#orange, 64), 25)
  rgb.Flash(3, 1)

  rgb.Snake(rgb.Intensity(rgb#blue,32), 25, 10)

  rgb.Checker(rgb.Intensity(rgb#orange, 32), rgb.Intensity(rgb#blue, 32), rgb.Intensity(rgb#crimson, 32), rgb.Intensity(rgb#turquoise, 16), 50)
  waitcnt(clkfreq/2+cnt)
  rgb.AllOff

  rgb.FadeInOut(60)
  rgb.AllOff
  
  rgb.LED_STRING(STRING("gizmologists"), 0, LetterOffset, rgb.Intensity(rgb#blue, 64), 25)
  rgb.Flash(3, 1)

  rgb.Snake(rgb.Intensity(rgb#orange,32), 25, 10)

  rgb.StackOn(rgb.Intensity(rgb#red,32), rgb.Intensity(rgb#cyan,16), rgb.Intensity(rgb#white,8))
  rgb.AllOff
  
  rgb.FlipFlop(rgb.Intensity(rgb#red, 32), rgb.Intensity(rgb#blue, 32), rgb.Intensity(rgb#green, 32), 65)
  rgb.AllOff
 
  rgb.AllOff
  rgb.LED_STRING(STRING("  wahoowa   "), 0, LetterOffset, rgb.Intensity(rgb#orange, 64), 25)
  rgb.Flash(3, 1)

  rgb.Snake(rgb.Intensity(rgb#blue,32), 25, 10)

  rgb.FillBackAndForth(rgb.Intensity(rgb#white, 8), rgb.Intensity(rgb#yellow, 16), rgb.Intensity(rgb#green, 32), rgb.Intensity(rgb#crimson, 32), 75)
  waitcnt(clkfreq/2+cnt)
  rgb.AllOff
  
  rgb.Box(rgb.Intensity(rgb#yellow, 16), rgb.Intensity(rgb#magenta, 16), rgb.Intensity(rgb#red, 32), rgb.Intensity(rgb#blue, 32), 50)
  waitcnt(clkfreq+cnt)
  rgb.AllOff
          
  rgb.StickFigure(rgb.Intensity(rgb#red, 64), 10)
  rgb.AllOff                   
  
     

{Copyright (c) 2012 Gavin Garner, University of Virginia                                                                              
MIT License: Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated             
documentation files (the "Software"), to deal in the Software without restriction, including without limitation the                   
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit                
persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and               
this permission notice shall be included in all copies or substantial portions of the Software. The software is provided              
as is, without warranty of any kind, express or implied, including but not limited to the warrenties of noninfringement.              
In no event shall the author or copyright holder be liable for any claim, damages or other liablility, out of or in                   
connection with the software or the use or other dealings in the software.}            
