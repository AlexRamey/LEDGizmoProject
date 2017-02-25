'' WS2812B_RGB_LED_Driver
'' by Gavin T. Garner
'' University of Virginia
'' April 20, 2012
'' test
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
             ' THIS WILL NEED TO BE INCREASED IF YOU ARE CONTROLLING MORE THAN 256 LEDs!!!
  word a_locations[20]
  word b_locations[30]
  word c_locations[18]
  word d_locations[20]
  word e_locations[28]
  word f_locations[18]
  word g_locations[23]
  word h_locations[24]
  word i_locations[24]
  word j_locations[16]
  word k_locations[18]
  word l_locations[13]
  word m_locations[20]
  word n_locations[26]
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

PUB LED_A(LEDaddress,color,waittime) | i
 a_locations[0] := 7
 a_locations[1] := 6
 a_locations[2] := 5
 a_locations[3] := 11
 a_locations[4] := 12
 a_locations[5] := 13
 a_locations[6] := 17
 a_locations[7] := 16
 a_locations[8] := 31
 a_locations[9] := 30
 a_locations[10] := 34
 a_locations[11] := 35
 a_locations[12] := 36
 a_locations[13] := 42
 a_locations[14] := 41
 a_locations[15] := 40
 a_locations[16] := 10
 a_locations[17] := 21
 a_locations[18] := 26
 a_locations[19] := 37   

 repeat i from 0 to 19
    lights[LEDaddress + a_locations[i]]:=color
    update:=true
    waitcnt(cnt + (clkfreq / waittime))

PUB LED_B(LEDaddress,color,waittime) | i
 b_locations[0] := 0
 b_locations[1] := 1
 b_locations[2] := 2
 b_locations[3] := 3
 b_locations[4] := 4
 b_locations[5] := 5
 b_locations[6] := 6
 b_locations[7] := 7
 b_locations[8] := 8
 b_locations[9] := 23
 b_locations[10] := 24
 b_locations[11] := 39
 b_locations[12] := 40
 b_locations[13] := 41
 b_locations[14] := 42
 b_locations[15] := 36
 b_locations[16] := 27
 b_locations[17] := 20
 b_locations[18] := 11
 b_locations[19] := 12
 b_locations[20] := 19
 b_locations[21] := 28
 b_locations[22] := 35
 b_locations[23] := 45
 b_locations[24] := 46
 b_locations[25] := 47
 b_locations[26] := 32
 b_locations[27] := 31
 b_locations[28] := 16
 b_locations[29] := 15   

 repeat i from 0 to 29
    lights[LEDaddress + b_locations[i]]:=color
    update:=true
    waitcnt(cnt + (clkfreq / waittime))

PUB LED_C(LEDaddress,color,waittime) | i
 c_locations[0] := 46
 c_locations[1] := 32
 c_locations[2] := 31
 c_locations[3] := 16
 c_locations[4] := 15
 c_locations[5] := 0
 c_locations[6] := 1
 c_locations[7] := 2
 c_locations[8] := 3
 c_locations[9] := 4
 c_locations[10] := 5
 c_locations[11] := 6
 c_locations[12] := 7
 c_locations[13] := 8
 c_locations[14] := 23
 c_locations[15] := 24
 c_locations[16] := 39
 c_locations[17] := 41

 repeat i from 0 to 17
    lights[LEDaddress + c_locations[i]]:=color
    update:=true
    waitcnt(cnt + (clkfreq / waittime))

PUB LED_D(LEDaddress,color,waittime) | i
 d_locations[0] := 0
 d_locations[1] := 1
 d_locations[2] := 2
 d_locations[3] := 3
 d_locations[4] := 4
 d_locations[5] := 5
 d_locations[6] := 6
 d_locations[7] := 7
 d_locations[8] := 8
 d_locations[9] := 23
 d_locations[10] := 24
 d_locations[11] := 38
 d_locations[12] := 42
 d_locations[13] := 43
 d_locations[14] := 44
 d_locations[15] := 45
 d_locations[16] := 33   
 d_locations[17] := 31
 d_locations[18] := 16
 d_locations[19] := 15   

 repeat i from 0 to 19
    lights[LEDaddress + d_locations[i]]:=color
    update:=true
    waitcnt(cnt + (clkfreq / waittime))

PUB LED_E(LEDaddress,color,waittime) | i
 e_locations[0] := 47
 e_locations[1] := 32
 e_locations[2] := 31
 e_locations[3] := 16
 e_locations[4] := 15
 e_locations[5] := 0
 e_locations[6] := 1
 e_locations[7] := 2
 e_locations[8] := 3
 e_locations[9] := 12
 e_locations[10] := 19
 e_locations[11] := 28
 e_locations[12] := 35
 e_locations[13] := 44
 e_locations[14] := 43
 e_locations[15] := 36
 e_locations[16] := 27
 e_locations[17] := 20
 e_locations[18] := 11
 e_locations[19] := 4
 e_locations[20] := 5
 e_locations[21] := 6
 e_locations[22] := 7
 e_locations[23] := 8
 e_locations[24] := 23
 e_locations[25] := 24
 e_locations[26] := 39
 e_locations[27] := 40  

 repeat i from 0 to 27
    lights[LEDaddress + e_locations[i]]:=color
    update:=true
    waitcnt(cnt + (clkfreq / waittime))

PUB LED_F(LEDaddress,color,waittime) | i
 f_locations[0] := 47
 f_locations[1] := 32
 f_locations[2] := 31
 f_locations[3] := 16
 f_locations[4] := 15
 f_locations[5] := 0
 f_locations[6] := 1
 f_locations[7] := 2
 f_locations[8] := 3
 f_locations[9] := 4
 f_locations[10] := 5
 f_locations[11] := 6
 f_locations[12] := 7
 f_locations[13] := 12
 f_locations[14] := 19
 f_locations[15] := 28
 f_locations[16] := 35
 f_locations[17] := 44 

 repeat i from 0 to 17
    lights[LEDaddress + f_locations[i]]:=color
    update:=true
    waitcnt(cnt + (clkfreq / waittime))

PUB LED_G(LEDaddress,color,waittime) | i
 g_locations[0] := 46
 g_locations[1] := 47
 g_locations[2] := 32
 g_locations[3] := 31
 g_locations[4] := 16
 g_locations[5] := 15
 g_locations[6] := 0
 g_locations[7] := 1
 g_locations[8] := 2
 g_locations[9] := 3
 g_locations[10] := 4
 g_locations[11] := 5
 g_locations[12] := 6
 g_locations[13] := 7
 g_locations[14] := 8
 g_locations[15] := 23
 g_locations[16] := 24
 g_locations[17] := 39
 g_locations[18] := 40
 g_locations[19] := 41
 g_locations[20] := 42
 g_locations[21] := 37
 g_locations[22] := 26
  

 repeat i from 0 to 22
    lights[LEDaddress + g_locations[i]]:=color
    update:=true
    waitcnt(cnt + (clkfreq / waittime))

PUB LED_H(LEDaddress,color,waittime) | i
 h_locations[0] := 0
 h_locations[1] := 1
 h_locations[2] := 2
 h_locations[3] := 3
 h_locations[4] := 4
 h_locations[5] := 5
 h_locations[6] := 6
 h_locations[7] := 7
 h_locations[8] := 47
 h_locations[9] := 46
 h_locations[10] := 45
 h_locations[11] := 44
 h_locations[12] := 43
 h_locations[13] := 42
 h_locations[14] := 41
 h_locations[15] := 40
 h_locations[16] := 11
 h_locations[17] := 12
 h_locations[18] := 19
 h_locations[19] := 20
 h_locations[20] := 28
 h_locations[21] := 27
 h_locations[22] := 36
 h_locations[23] := 35   

 repeat i from 0 to 23
    lights[LEDaddress + h_locations[i]]:=color
    update:=true
    waitcnt(cnt + (clkfreq / waittime))

PUB LED_I(LEDaddress,color,waittime) | i
 i_locations[0] := 0
 i_locations[1] := 15
 i_locations[2] := 16
 i_locations[3] := 31
 i_locations[4] := 32
 i_locations[5] := 47
 i_locations[6] := 7
 i_locations[7] := 8
 i_locations[8] := 23
 i_locations[9] := 24
 i_locations[10] := 39
 i_locations[11] := 40
 i_locations[12] := 22
 i_locations[13] := 25
 i_locations[14] := 21
 i_locations[15] := 26
 i_locations[16] := 20
 i_locations[17] := 27
 i_locations[18] := 19
 i_locations[19] := 28
 i_locations[20] := 18
 i_locations[21] := 29
 i_locations[22] := 17
 i_locations[23] := 30  

 repeat i from 0 to 23
    lights[LEDaddress + i_locations[i]]:=color
    update:=true
    waitcnt(cnt + (clkfreq / waittime))

PUB LED_J(LEDaddress,color,waittime) | i
 j_locations[0] := 0
 j_locations[1] := 15
 j_locations[2] := 16
 j_locations[3] := 31
 j_locations[4] := 32
 j_locations[5] := 47
 j_locations[6] := 33
 j_locations[7] := 34
 j_locations[8] := 35
 j_locations[9] := 36
 j_locations[10] := 37
 j_locations[11] := 38
 j_locations[12] := 24
 j_locations[13] := 23
 j_locations[14] := 8
 j_locations[15] := 6 

 repeat i from 0 to 15
    lights[LEDaddress + j_locations[i]]:=color
    update:=true
    waitcnt(cnt + (clkfreq / waittime))

PUB LED_K(LEDaddress,color,waittime) | i
 k_locations[0] := 0
 k_locations[1] := 1
 k_locations[2] := 2
 k_locations[3] := 3
 k_locations[4] := 4
 k_locations[5] := 5
 k_locations[6] := 6
 k_locations[7] := 7
 k_locations[8] := 11
 k_locations[9] := 12
 k_locations[10] := 19
 k_locations[11] := 20
 k_locations[12] := 26
 k_locations[13] := 38
 k_locations[14] := 40
 k_locations[15] := 29
 k_locations[16] := 33
 k_locations[17] := 47  

 repeat i from 0 to 17
    lights[LEDaddress + k_locations[i]]:=color
    update:=true
    waitcnt(cnt + (clkfreq / waittime))

PUB LED_L(LEDaddress,color,waittime) | i
 l_locations[0] := 0
 l_locations[1] := 1
 l_locations[2] := 2
 l_locations[3] := 3
 l_locations[4] := 4
 l_locations[5] := 5
 l_locations[6] := 6
 l_locations[7] := 7
 l_locations[8] := 8
 l_locations[9] := 23
 l_locations[10] := 24
 l_locations[11] := 39
 l_locations[12] := 40 

 repeat i from 0 to 12
    lights[LEDaddress + l_locations[i]]:=color
    update:=true
    waitcnt(cnt + (clkfreq / waittime))

PUB LED_M(LEDaddress,color,waittime) | i
 m_locations[0] := 7
 m_locations[1] := 6
 m_locations[2] := 5
 m_locations[3] := 4
 m_locations[4] := 3
 m_locations[5] := 2
 m_locations[6] := 1
 m_locations[7] := 15
 m_locations[8] := 17
 m_locations[9] := 18
 m_locations[10] := 29
 m_locations[11] := 30
 m_locations[12] := 32
 m_locations[13] := 46
 m_locations[14] := 45
 m_locations[15] := 44
 m_locations[16] := 43
 m_locations[17] := 42
 m_locations[18] := 41
 m_locations[19] := 40   

 repeat i from 0 to 19
    lights[LEDaddress + m_locations[i]]:=color
    update:=true
    waitcnt(cnt + (clkfreq / waittime))

PUB LED_N(LEDaddress,color,waittime) | i
 n_locations[0] := 7
 n_locations[1] := 6
 n_locations[2] := 5
 n_locations[3] := 4
 n_locations[4] := 3
 n_locations[5] := 2
 n_locations[6] := 1
 n_locations[7] := 0
 n_locations[8] := 15
 n_locations[9] := 14
 n_locations[10] := 17
 n_locations[11] := 18
 n_locations[12] := 19
 n_locations[13] := 28
 n_locations[14] := 27
 n_locations[15] := 26
 n_locations[16] := 37
 n_locations[17] := 38
 n_locations[18] := 39
 n_locations[19] := 41
 n_locations[20] := 42
 n_locations[21] := 43
 n_locations[22] := 44
 n_locations[23] := 45
 n_locations[24] := 46
 n_locations[25] := 47

 repeat i from 0 to 25
    lights[LEDaddress + n_locations[i]]:=color
    update:=true
    waitcnt(cnt + (clkfreq / waittime))   

PUB LED_LETTER(letter, baseAddress, color, speed) | length, i, offset
  ''                        A  B  C  D  E  F  G  H  I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W  X  Y  Z
  length := lookupz(letter: 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0)
  repeat i from 0 to (length - 1)
    case (letter)
      "a", "A": offset := lookupz(i: 7, 6, 5, 11, 12, 13, 17, 16, 31, 30, 34, 35, 36, 42, 41, 40, 10, 21, 26, 37)
      "x", "X": offset := lookupz(i: 0, 14, 13, 19, 27, 37, 38, 40, 47, 33, 34, 28, 20, 10, 9, 7)
    lights[baseAddress + offset]:=color
    update:=true
    waitcnt(cnt + (clkfreq / speed))

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