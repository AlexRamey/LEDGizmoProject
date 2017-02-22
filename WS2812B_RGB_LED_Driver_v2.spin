'' WS2812B_RGB_LED_Driver
'' by Gavin T. Garner
'' University of Virginia
'' April 20, 2012
{  This object can be used to control a Red-Green-Blue LED light strip (such as the 1m and 2m 
   ones available from Pololu.com as parts #2540 and #2541). These strips incorporate TM1804 chips by
   Titan Micro (one for each RGB LED) and 24-bit color data is shifted into them using quick pulses
   (~1300ns=Digital_1 and ~700ns=Digital_0). Because these pulses are so quick, they must be generated
   using PASM code. The advantage to this is that they can be updated and changed much more quickly
   than other types of addressable RGB LED strips. Note that this code will not control RGB LED strips
   that use WS2801 chips (such as the ones currently sold by Sparkfun.com).

                                    Instructions for use:
   Wiring:
         Propeller I/O pin (your choice) <---> IN  (silver wire with white stripe on Pololu Part) 
                         Propeller's Vss <---> GND (silver wire with no stripe on Pololu Part)
   NC (both GND terminals are connected) <---> GND (black wire w/dashed white stripe on Pololu Part)
        5V Power Supply (1.25Amps/meter) <---> +VC (black wire with no stripe on Pololu Part)
   Software:
   Insert this RGB_LED_Strip object into your code and call the "start" method. This will
   start the assembly program on a new cog where it will run continuously and take care of
   communication between your spin code and the TM1804 chips. Once this PASM driver is started, you
   can call the methods below such as rgb.ChangeLED(0,255)
   You can also create your own methods, but note that you must set the "update" variable to a
   non-zero value (eg. update:=true) whenever you want the LEDs to change/update
   Note: If you want to control more than 60 LEDs (2 meters), you will need to increase the number
   of longs alotted to the LED variable array below (eg. lights[120] for two 2m strips wired together).
                                       HAVE FUN!!!                                                  }  
CON        'Predefined colors that can be accessed from your code using rgb#constant:
                                               '  green      red      blue              
 off            = 0                            '%00000000_00000000_00000000
 red            = 255<<8                       '%00000000_11111111_00000000
 green          = 255<<16                      '%11111111_00000000_00000000 
 blue           = 255                          '%00000000_00000000_11111111 
 white          = 255<<16+255<<8+255           '%11111111_11111111_11111111 
 cyan           = 255<<16+255                  '%11111111_00000000_11111111 
 magenta        = 255<<8+255                   '%00000000_11111111_11111111 
 yellow         = 255<<16+255<<8               '%11111111_11111111_00000000 
 chartreuse     = 255<<16+127<<8               '%11111111_01111111_00000000
 orange         = 60<<16+255<<8                '%10100101_11111111_11010100        
 aquamarine     = 255<<16+127<<8+212           '%11111111_11111111_11010100
 pink           = 128<<16+255<<8+128           '%10000000_11111111_10000000
 turquoise      = 224<<16+63<<8+192            '%10000000_00111111_10000000
 realwhite      = 255<<16+200<<8+255           '%11100000_11001000_11000000
 indigo         = 170                          '%00000000_00111111_01111111
 violet         = 51<<16+215<<8+255            '%01111111_10111111_10111111
 
VAR
  long update           'Controls when LED values are sent (its address gets loaded into Cog 1)      
  long maxAddress       'Address of the last LED in the string                                       
  long cog              'Store cog # (so that the cog can be stopped)                                
  long LEDs             'Stores the total number of addressable LEDs
  long lights[256]      'Reserve a long for each LED address in the string                           
             '  THIS WILL NEED TO BE INCREASED IF YOU ARE CONTROLLING MORE THAN 256 LEDs!!!
PUB start(OutputPin,NumberOfLEDs) : okay
'' Starts RGB LED Strip driver on a cog, returns false if no cog available
'' Note: Requires at least a 20MHz system clock
  _pin:=OutputPin
  _LEDs:=NumberOfLEDs
  LEDs:=NumberOfLEDs
  maxAddress:=NumberOfLEDs-1 
  _update:=@update                                                    

'LED Strip WS2812B chip
  High1:=61  '0.9us  
  Low1:=19    '0.35us   
  High0:=35  '0.35us   
  Low0:=76   '0.9us   
  reset:=5000 '50microseconds                

  stop                                   'Stop the cog (just in case)
  okay:=cog:=cognew(@RGBdriver,@lights)+1'Start PASM RGB LED Strip driver
  
PUB stop                                ''Stops the RGB LED Strip driver and releases the cog
  if cog
    cogstop(cog~ - 1)

PUB LED(LEDaddress,color)               ''Changes the color of an LED at a specific address 
  lights[LEDaddress]:=color
  update:=true

PUB LEDRGB(LEDaddress,_red,_green,_blue) ''Changes RGB values of an LED at a specific address 
  lights[LEDaddress]:=_red<<16+_green<<8+_blue
  update:=true

PUB LEDint(LEDaddress,color,intense)               ''Changes the color of an LED at a specific address 
  lights[LEDaddress]:=((((color>>16)*intense)/255)<<16) +((((color>>8 & $FF)*intense)/255)<<8)+(((color & $FF)*intense)/255)
  update:=true

PUB Intensity(color,intense) : newvalue              ''Changes the intensity (0-255) of a color 
  newvalue:=((((color>>16)*intense)/255)<<16) +((((color>>8 & $FF)*intense)/255)<<8)+(((color & $FF)*intense)/255)

PUB SetAllColors(setcolor) | i          ''Changes the colors of all LEDs to the same color  
  longfill(@lights,setcolor,maxAddress+1)
  update:=true

PUB AllOff | i                          ''Turns all of the LEDs off
  longfill(@lights,0,maxAddress+1) 
  update:=true
  waitcnt(clkfreq/100+cnt)              'Can't send the next update too soon

PUB SetSection(AddressStart,AddressEnd,setcolor)  ''Changes colors in a section of LEDs to same color
  longfill(@lights[AddressStart],setcolor,AddressEnd-AddressStart+1)'(@lights[AddressEnd]-@lights[AddressStart])/4) 
  update:=true

PUB GetColor(address) : color           ''Returns 24-bit RGB value from specified LED's address
  color:=lights[address]

PUB Random(address) | rand,_red,_green,_blue,timer ''Sets LED at specified address to a "random" color
  rand:=?cnt                                        
  _red:=rand>>24                                     
  rand:=?rand                                        
  _green:=rand>>24                                   
  rand:=?rand                                        
  _blue:=rand>>24                                    
  lights[address]:=_red<<16+_green<<8+_blue        
  update:=true                                     
   
DAT
''This PASM code sends control data to the RGB LEDs on the strip once the "update" variable is set to
'' a value other than 0
              org       0                 
RGBdriver     mov       pinmask,#1          'Set direction of data pin to be an output 
              shl       pinmask,_pin
              mov       dira,pinmask
              mov       index,par           'Set index to LED variable array's base address

StartDataTX   rdlong    check,_update       '                                                  
              tjz       check,#StartDataTX  'Wait for Cog 0 to set "update" to true or 1       
              mov       count,#0            'Start with "index" count=0
                                                                                               
AddressLoop   rdlong    RGBvalue,index      'Fetch RGB[index] value from central Hub RAM       
              mov       shift,#23           'Start with shift=23 (shift to MSB of Red value)   
                                                                                               
BitLoop       mov       outa,pinmask        'Set data pin High
              mov       getbit,RGBvalue     'Store RGBvalue as "getbit"                   
              shr       getbit,shift        'Shift this RGB value right "shift" # of bits 
              and       getbit,#1           'Lop off all bits except LSB                  
              cmp       getbit,#1       wz  'Check if bit=1, if so, set Z flag            
        if_z  jmp       #DigiOne                                                          
DigiZero      mov       counter,cnt         'Output a pulse corresponding to a digital 0 
              'add       counter,High0  
              
              'waitcnt   counter,Low0        'Wait for 0.7us
              add       counter,Low0
              mov       outa,#0             'Set data pin Low 
              waitcnt   counter,#0          'Wait for 1.8us

              tjz       shift,#Increment    'If shift=0, jump down to "Increment"         
              sub       shift,#1            'Decrement shift by 1                         
              jmp       #BitLoop            'Repeat BitLoop if "shift" has not reached 0                                                      

DigiOne       mov       counter,cnt         'Output a pulse corresponding to a digital 1
              add       counter,High1
              waitcnt   counter,Low1        'Wait for 1.3us
              mov       outa,#0             'Set data pin Low
              waitcnt   counter,#0          'Wait for 1.2us
              tjz       shift,#Increment    'If shift=0, jump down to "Increment"         
              sub       shift,#1            'Decrement shift by 1                         
              
              jmp       #BitLoop            'Repeat BitLoop if "shift" has not reached 0 

Increment     add       index,#4            'Increment index by 4 byte addresses (1 long)                             
              add       count,#1            'Increment count by 1
              cmp       count,_LEDs    wz   'Check to see if all LEDs have been set  
        if_nz jmp       #AddressLoop        'If not, repeat AddressLoop for next LED's RGBvalue

              mov       counter,cnt                                                                        
              add       counter,reset                                                                      
              waitcnt   counter,#0          'Wait for 24us (reset datastream)                              
              wrlong    zero,_update        'Set update value to 0, wait for Cog 0 to reset this
              mov       index,par           'Set index to LED variable array's base address
              jmp       #StartDataTX
                      
                                            'Starred values (*) are set before cog is loaded
_update       long      0                   'Hub RAM address of "update" will be stored here*
_pin          long      0                   'Output pin number will be stored here*
_LEDs         long      0                   'Total number of LEDs will be stored here*
High1         long      0                   '~1.3 microseconds(digital 1)*
Low1          long      0                   '~1.2 microseconds*            
High0         long      0                   '~0.7 microseconds(digital 0)* 
Low0          long      0                   '~1.8 microseconds*            
reset         long      0                   '~25 microseconds (the 24us spec doesn't seem to work)*            
zero          long      0
pinmask       res
RGBvalue      res
getbit        res
counter       res
count         res
check         res
index         res
shift         res
last          res
              fit

{Copyright (c) 2012 Gavin Garner, University of Virginia                                                                              
MIT License: Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated             
documentation files (the "Software"), to deal in the Software without restriction, including without limitation the                   
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit                
persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and               
this permission notice shall be included in all copies or substantial portions of the Software. The software is provided              
as is, without warranty of any kind, express or implied, including but not limited to the warrenties of noninfringement.              
In no event shall the author or copyright holder be liable for any claim, damages or other liablility, out of or in                   
connection with the software or the use or other dealings in the software.}                                            