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
 crimson        = 153<<8                       '%00000000_10011001_00000000

 NUM_LEDS       = 768

OBJ

 fds            : "Extended_FDSerial"
 
VAR
  long update           'Controls when LED values are sent (its address gets loaded into Cog 1)      
  long maxAddress       'Address of the last LED in the string                                       
  long cog              'Store cog # (so that the cog can be stopped)                                
  long lock

  long LEDs             'Stores the total number of addressable LEDs
  long lights[NUM_LEDS]      'Reserve a long for each LED address in the string                           
  long receivedLights[NUM_LEDS]
             ' THIS WILL NEED TO BE INCREASED IF YOU ARE CONTROLLING MORE THAN 256 LEDs!!!
  long snapshot[NUM_LEDS]
  long stack[100]

PUB start(OutputPin,NumberOfLEDs, RX, TX) : okay
'' Starts RGB LED Strip driver on a cog, returns false if no cog available
'' Note: Requires at least a 20MHz system clock
'' If RX and TX are not -1, then start another cog that listens for rgb values
'' from a Raspberry Pi to pit on - note it is a *very* specific number
'' It listens for the number of pixels as it has in RGBs, so if it gets less, then it
'' may have unintended consequences.  Use at your own discretion.
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

  if RX <> -1 and TX <> -1               ' If RX and TX values defined
    fds.Start(RX, TX, %1000, 56700)      ' Start full duplex serial - note 56700 max baud rate
    cognew(ImageWaiter, @stack)          ' Start new cog running ImageWaiter 

  lock := LOCKNEW
  stop                                   'Stop the cog (just in case)
  okay:=cog:=cognew(@RGBdriver,@lights)+1'Start PASM RGB LED Strip driver

PUB stop                                ''Stops the RGB LED Strip driver and releases the cog
  if cog
    cogstop(cog~ - 1)


'' PARAMS: 'speed' is how fast to draw the letter.  Values may range from [0,100], where 100 is max speed.  Specifying 0 creates no wait.
PUB Wait(speed)
  if (speed > 0) AND (speed =< 100)
      update:=true
      waitcnt((clkfreq / (speed*2)) + cnt)

'' These methods take in lockNum, which will probably be 0, then do simple
'' manipulation on them.  These are essentially just aliases.
PUB SetLock(lockNum)
  repeat while LOCKSET(lockNum)   ' Wait until the lock is free and take when it is
    next                          ' Immediately go to the next check - constantly checking

'' Alias for LOCKCLR(lockNum)
PUB FreeLock(lockNum)
  LOCKCLR(lockNum)                ' Clear the lock
    

PUB ImageWaiter | i
  repeat
    if fds.rxCheck                               ' If something is in the rx buffer
      repeat i from 0 to NUM_LEDS-1              ' Go through the LEDs
        receivedLights[i] := fds.rxDec           ' Populate received array with received vals
        
      SetLock(lock)                              ' Lock 
      AllOff                            
      waitcnt(clkfreq + cnt)                     ' Wait a second before starting
      repeat i from 0 to NUM_LEDS-1              ' Go through LEDs
        LED(i, Intensity(receivedLights[i], 32)) ' Make LEDs reflect received values
        Wait(50)                                 ' Wait between each LED
      waitcnt(clkfreq*3+cnt)
      AllOff
      FreeLock(lock)

'' PARAMS: 'x' is the x value for the index
'' PARAMS: 'y' is the y value for the index
'' Bottom left is the origin
PUB XY_TO_INDEX(x, y)
  if (x // 2 == 0)
    return (x * 8) + (7 - y)
  else
    return (x * 8) + y

PUB LED(LEDaddress,color)               ''Changes the color of an LED at a specific address 
  lights[LEDaddress]:=color
  update:=true

'' PARAMS: 'letter' is case-insensitive ASCII character ex. "A" or "a"
'' PARAMS: 'baseAddress' is the cell # of the top left LED in the 6x8(WxH) square of the letter. The Font assumes letters are 6 columns wide
'' PARAMS: 'color' is the color to make the letter
'' PARAMS: 'speed' is how fast to draw the letter. Values may range from [0,100], where 100 is max speed. Specifying 0 makes the letter appear all at once.
'' AUTHOR: Alex Ramey and Evan Typanski
PUB LED_LETTER(letter, baseAddress, color, speed) | letterNumber, length, i, offset
  
  '' Map the ASCII letter value to an alphabet index [0,26]
  if (letter => 65) AND (letter =< 90)      '' UPPER case input
    letterNumber := letter - 65
  elseif (letter => 97) AND (letter =< 122) '' lower case input
    letterNumber := letter - 97
  else                                      '' invalid input
    return 0.0

  '' Use the alphabet index to lookup how long the list of positions is for 'letter'
  ''                              A   B   C   D   E   F   G   H   I   J   K   L   M   N   O   P   Q   R   S   T   U   V   W   X   Y   Z
  length := lookupz(letterNumber: 20, 30, 18, 20, 28, 18, 23, 24, 24, 16, 18, 13, 20, 24, 20, 26, 19, 30, 26, 24, 16, 16, 22, 16, 16, 18)

  '' Draw 'letter', taking 'speed' PARAM into account
  repeat i from 0 to (length - 1)
    case (letter)
      "a", "A": offset := lookupz(i: 7, 6, 5, 11, 12, 13, 17, 16, 31, 30, 34, 35, 36, 42, 41, 40, 10, 21, 26, 37)
      "b", "B": offset := lookupz(i: 0, 1, 2, 3, 4, 5, 6, 7, 8, 23, 24, 39, 40, 41, 42, 36, 27, 20, 11, 12, 19, 28, 35, 45, 46, 47, 32, 31, 16, 15)
      "c", "C": offset := lookupz(i: 46, 32, 31, 16, 15, 0, 1, 2, 3, 4, 5, 6, 7, 8, 23, 24, 39, 41)
      "d", "D": offset := lookupz(i: 0, 1, 2, 3, 4, 5, 6, 7, 8, 23, 24, 38, 42, 43, 44, 45, 33, 31, 16, 15)
      "e", "E": offset := lookupz(i: 47, 32, 31, 16, 15, 0, 1, 2, 3, 12, 19, 28, 35, 44, 43, 36, 27, 20, 11, 4, 5, 6, 7, 8, 23, 24, 39, 40)
      "f", "F": offset := lookupz(i: 47, 32, 31, 16, 15, 0, 1, 2, 3, 4, 5, 6, 7, 12, 19, 28, 35, 44)
      "g", "G": offset := lookupz(i: 46, 47, 32, 31, 16, 15, 0, 1, 2, 3, 4, 5, 6, 7, 8, 23, 24, 39, 40, 41, 42, 37, 26)
      "h", "H": offset := lookupz(i: 0, 1, 2, 3, 4, 5, 6, 7, 47, 46, 45, 44, 43, 42, 41, 40, 11, 12, 19, 20, 28, 27, 36, 35)
      "i", "I": offset := lookupz(i: 0, 15, 16, 31, 32, 47, 7, 8, 23, 24, 39, 40, 22, 25, 21, 26, 20, 27, 19, 28, 18, 29, 17, 30)
      "j", "J": offset := lookupz(i: 0, 15, 16, 31, 32, 47, 33, 34, 35, 36, 37, 38, 24, 23, 8, 6)
      "k", "K": offset := lookupz(i: 0, 1, 2, 3, 4, 5, 6, 7, 11, 12, 19, 20, 26, 38, 40, 29, 33, 47)
      "l", "L": offset := lookupz(i: 0, 1, 2, 3, 4, 5, 6, 7, 8, 23, 24, 39, 40)
      "m", "M": offset := lookupz(i: 7, 6, 5, 4, 3, 2, 1, 15, 17, 18, 29, 30, 32, 46, 45, 44, 43, 42, 41, 40)
      "n", "N": offset := lookupz(i: 7, 6, 5, 4, 3, 2, 1, 0, 15, 14, 18, 19, 27, 26, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47)
      "o", "O": offset := lookupz(i: 1, 2, 3, 4, 5, 6, 8, 23, 24, 39, 41, 42, 43, 44, 45, 46, 32, 31, 16, 15)
      "p", "P": offset := lookupz(i: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 31, 32, 33, 46, 45, 34, 35, 28, 19)
      "q", "Q": offset := lookupz(i: 16, 14, 2, 3, 4, 5, 9, 23, 24, 38, 42, 43, 44, 45, 33, 31, 20, 26, 40)
      "r", "R": offset := lookupz(i: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 31, 32, 33, 46, 45, 34, 35, 28, 19, 20, 26, 38, 40)
      "s", "S": offset := lookupz(i: 45, 46, 32, 31, 16, 15, 1, 2, 13, 18, 12, 19, 28, 20, 27, 36, 26, 37, 42, 41, 39, 24, 23, 8, 6, 5)
      "t", "T": offset := lookupz(i: 23, 22, 21, 20, 19, 18, 17, 14, 1, 0, 15, 16, 31, 32, 47, 46, 33, 30, 29, 28, 27, 26, 25, 24)
      "u", "U": offset := lookupz(i: 0, 1, 2, 3, 4, 5, 9, 23, 24, 38, 42, 43, 44, 45, 46, 47)
      "v", "V": offset := lookupz(i: 0, 1, 13, 12, 11, 10, 22, 23, 24, 25, 37, 36, 35, 34, 46, 47)
      "w", "W": offset := lookupz(i: 0, 1, 2, 3, 4, 5, 6, 8, 22, 21, 20, 27, 26, 25, 39, 41, 42, 43, 44, 45, 46, 47)
      "x", "X": offset := lookupz(i: 0, 14, 13, 19, 27, 37, 38, 40, 47, 33, 34, 28, 20, 10, 9, 7)
      "y", "Y": offset := lookupz(i: 0, 1, 13, 12, 20, 21, 22, 23, 24, 25, 26, 27, 35, 34, 46, 47)
      "z", "Z": offset := lookupz(i: 0, 15, 16, 31, 32, 47, 46, 34, 28, 20, 10, 6, 7, 8, 23, 24, 39, 40)

    lights[baseAddress + offset]:=color

    Wait(speed)

  update:=true

''' PARAMS: 'letterSize' is the number of cells to allocate for each letter. This should include spacing that follows. Recommended value is 64.
PUB LED_STRING(ledString, baseAddress, letterSize, color, speed) | size, i, letterHold
  SetLock(lock)
  
  size := STRSIZE(ledString)
  letterHold := 0

  repeat i from 0 to (size - 1)
    BYTEMOVE(@letterHold, ledString + i, 1)
    LED_LETTER(letterHold, baseAddress + (i * letterSize), color, speed)
  FreeLock(lock)
  

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
  waitcnt(clkfreq/1000+cnt)              'Can't send the next update too soon

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


'' PARAMS: 'numFlashes' is the number of times the text goes off and reappears
'' PARAMS: 'speed' refers to how fast the LEDs flash, with higher numbers faster
'' AUTHOR: Alex Ramey and Evan Typanski
'' NOTE: If speed = 0, then waits 2 seconds
PUB Flash(numFlashes, speed) | i, localSpeed                    
  SetLock(lock)
  LONGMOVE(@snapshot, @lights, NUM_LEDS)
  waitcnt(cnt+clkfreq/10)
  if (speed == 0)
    localSpeed := 1
  else
    localSpeed := speed
    
  repeat i from 1 to numFlashes
    AllOff
    waitcnt(clkfreq/localSpeed + cnt)
    if (speed == 0)
      waitcnt(clkfreq/localSpeed + cnt)
    LONGMOVE(@lights, @snapshot, NUM_LEDS)
    update:=true
    waitcnt(clkfreq/localSpeed + cnt)
    if (speed == 0)
      waitcnt(clkfreq/localSpeed + cnt)

  FreeLock(lock)
  

PUB FlipFromMiddle(speed) | color, i
  SetLock(lock)
  color := 64                                
  repeat 3
    repeat i from 0 to maxAddress/2  
      LED(maxAddress/2+i,color)
      LED(maxAddress/2-i,color)     
      Wait(speed) 
    repeat i from 0 to maxAddress/2
      LED(i,off)
      LED(maxAddress-i,off)   
      Wait(speed)
    color := color<<8

  FreeLock(lock)

'' AUTHOR: Evan Typanski
PUB Snake(color, speed, snakeLength) | i
  SetLock(lock)
  repeat i from 0 to maxAddress
    LED(i,color)
    if (i > snakeLength - 1)
      LED(i - snakeLength, off)
    Wait(speed)
  repeat i from maxAddress-snakeLength to maxAddress-1
    LED(i, off)
    Wait(speed)

  FreeLock(lock)
  {  
  repeat i from maxAddress to 0
    LED(i,color)
    if (i < maxAddress - snakeLength)
      LED(snakeLength + i + 1, off)
    Wait(speed)
  repeat i from snakeLength to 0
    LED(i, off)
    Wait(speed)
  }

'' Creates a checkerboard pattern from both sides, but offset such that when they meet
'' in the middle, they start reversing the other side's order
'' PARAMS: 'color1' is the color of the checkerboard starting at index 0
'' PARAMS: 'color2' is the color of the checkerboard starting at index 1
'' PARAMS: 'color3' is the color of the checkerboard that will start at index 0 after 2nd run through
'' PARAMS: 'color4' is the color of the checkerboard that will start at index 1 after 2nd run through
'' AUTHOR: Evan Typanski
PUB Checker(color1, color2, color3, color4, speed) | i                                    
  SetLock(lock)
  repeat i from 0 to maxAddress/2
    if (i // 2 == 0)
      LED(i, color1)
      LED(maxAddress - i, color1)  
    else
      LED(i, color2)
      LED(maxAddress - i, color2)

    Wait(speed)

  repeat i from 383 to 0
    if (i // 2 == 0)
      LED(i, color3)
      LED(maxAddress - i, color3)
    else
      LED(i, color4)
      LED(maxAddress - i, color4)

    Wait(speed)

  FreeLock(lock)

'' Goes along the edges until it reaches the center with each box having different color parameter
'' AUTHOR: Evan Typanski
PUB Box(color1, color2, color3, color4, speed) | c, i, x, y
  SetLock(lock)
  repeat i from 0 to 3
    if (i == 0)
      c := color1
    elseif (i == 1)
      c := color2
    elseif (i == 2)
      c := color3
    else
      c := color4
    repeat x from i to 95-i
      LED(XY_TO_INDEX(x, 7-i), c)
      Wait(speed)
    repeat y from 6-i to i
      LED(XY_TO_INDEX(95-i, y), c)
      Wait(speed)
    repeat x from 95-i to i
      LED(XY_TO_INDEX(x, i), c)
      Wait(speed)
    repeat y from i to 6-i
      LED(XY_TO_INDEX(i, y), c)
      Wait(speed)

    if (i == 3)
      LED(XY_TO_INDEX(3, 3), c)

  FreeLock(lock)

'' Creates a stick figure that walks across the LEDs
'' The man starts at column 5 or so - weird, but unnoticeable
'' AUTHOR: Evan Typanski
PUB StickFigure(color, speed) | x, y
  SetLock(lock)
  repeat x from 2 to 93
    AllOff
    '' Draw head and body - same throughout
    
    LED(XY_TO_INDEX(x-1, 7), color)
    LED(XY_TO_INDEX(x, 7), color)
    LED(XY_TO_INDEX(x+1, 7), color)
    LED(XY_TO_INDEX(x+1, 6), color)
    LED(XY_TO_INDEX(x+1, 5), color)
    LED(XY_TO_INDEX(x, 5), color)
    LED(XY_TO_INDEX(x-1, 5), color)
    LED(XY_TO_INDEX(x-1, 6), color)

    LED(XY_TO_INDEX(x, 4), color)
    LED(XY_TO_INDEX(x, 3), color)
    LED(XY_TO_INDEX(x, 2), color)

    '' Open legs
    if (x // 4 == 2)
      LED(XY_TO_INDEX(x+1, 1), color)
      LED(XY_TO_INDEX(x+2, 0), color)
      LED(XY_TO_INDEX(x-1, 1), color)
      LED(XY_TO_INDEX(x-2, 0), color)

    '' Slightly closed legs
    elseif (x // 4 == 3 OR x // 4 == 1)
      LED(XY_TO_INDEX(x+1, 1), color)
      LED(XY_TO_INDEX(x+1, 0), color)
      LED(XY_TO_INDEX(x-1, 1), color)
      LED(XY_TO_INDEX(x-1, 0), color)

    '' Closed legs
    else
      LED(XY_TO_INDEX(x, 1), color)
      LED(XY_TO_INDEX(x, 0), color)

    Wait(speed)

  FreeLock(lock)
                 
'' Triangles interlocking
'' AUTHOR: Evan Typanski
PUB Triangle(color1, color2, speed) | i, j, x, y
  SetLock(lock)
  repeat j from 0 to 6          ' Number of times through the pattern
    repeat i from 0 to 6        ' Number of triangles
      repeat x from 0 to 14     ' Every triangle takes up 14 x values
        ' Set y value to triangle correctly for top triangle
        if (x + i*14 + j > 95)
          quit
        if ( x < 7)
          y := 7 - x
        else
          y := x - 7

        LED(XY_TO_INDEX(x + i*14 + j, y), color1) ' j is offset from other triangles

        ' Set y value to triangle correctly for bottom triangle
        if (x < 7)
          y := x
        else
          y := 14 - x

        LED(XY_TO_INDEX(x + i*14 + j, y), color2)
      
        Wait(speed)

  FreeLock(lock)

'' Increasing speed stacking pattern
'' No speed for this one: cannot change
PUB StackOn(color1, color2, color3) | i, j, x
  SetLock(lock)
  x:=8
  repeat j from 500 to 1000 step 50                              
    repeat i from 0 to maxAddress-x
      SetSection(i,i+8, color1)    
      waitcnt(clkfreq/j+cnt)
      SetSection(0,maxAddress-x,off)
    x:=x+8
    repeat i from 0 to maxAddress-x
      SetSection(i,i+8,color2)
      waitcnt(clkfreq/j+cnt)
      SetSection(0,maxAddress-x,off) 
    x:=x+8  
    repeat i from 0 to maxAddress-x
      SetSection(i,i+8,color3)
      waitcnt(clkfreq/j+cnt)
      SetSection(0,maxAddress-x,off) 
    x:=x+8
  repeat i from maxAddress-x to maxAddress step 3
    SetSection(i,i+3,off)
    waitcnt(clkfreq/10+cnt)

  FreeLock(lock)

          

PUB FillBackAndForth(color1, color2, color3, color4, speed) | i
  SetLock(lock)
  repeat i from maxAddress to 0
    LED(i,color1)    
    Wait(speed)
  repeat i from 0 to maxAddress-1
    LED(i,color2)    
    Wait(speed)
  repeat i from maxAddress to 0
    LED(i,color3)    
    Wait(speed)
  repeat i from 0 to maxAddress-1
    LED(i,color4)    
    Wait(speed)

  FreeLock(lock)

PUB FlipFlop(color1, color2, color3, speed) | i, j, color
  SetLock(lock)
  repeat j from 0 to 3
    if (j == 0)
      color := color1
    elseif (j == 1)
      color := color2
    elseif (j == 2)
      color := color3
    repeat i from 0 to maxAddress/2  
      LED(maxAddress/2+i,color)
      LED(maxAddress/2-i,color)     
      Wait(speed)
    repeat i from 0 to maxAddress/2
      LED(i,off)
      LED(maxAddress-i,off)   
      Wait(speed)

  FreeLock(lock)

'' Warning: VERY bright, use at own risk
'' Nice, infinite, peacefully-pulsing, random pattern
'' Last portion developed by:
'' AUTHOR: Taylor Hammelman and Ankit Javia
PUB Pulse | x, i, j
  SetLock(lock)
  repeat 10                               
    x:=?cnt>>24                                                            
    repeat j from 0 to 255 step 5       
      repeat  i from 0 to maxAddress step 2                    
        LEDRGB(i,x,255-x,Intensity(j,16))
        LEDRGB(i+1,x,255-x,Intensity(255-j,16))
      waitcnt(clkfreq/30+cnt)

  FreeLock(lock)

'' Fills LEDs then flashes them
'' May be very bright
'' Can only use white
PUB FadeInOut(speed) | i
  SetLock(lock)
  repeat i from 0 to maxAddress/2-1     
    LED(maxAddress/2-1-i, Intensity(white, 8))
    LED(maxAddress/2-1+i, Intensity(white, 8))   
    Wait(speed)
   
  repeat 3
    repeat i from 8 to 0 step 1         'Fade off
      SetAllColors(i<<16+i<<8+i)
      Wait(speed/2)
    repeat i from 0 to 8 step 1         'Fade on
      SetAllColors(i<<16+i<<8+i)
      Wait(speed/2)

  FreeLock(lock)

'' This is very bright.  Therefore, it is unused.
'' Picks random color and makes lights that color and fills it
'' Some other stuff too
PUB RandomPingPong | i, j, x
  SetLock(lock)
  repeat j from 50 to 4000 step 50      'Random-color, ping-pong pattern
    Intensity(Random(0),16)
    repeat i from 0 to maxAddress 
      x:=GetColor(i)                'You can retrieve the color value of any LED
      LED(i+1,x)
      waitcnt(clkfreq/j+cnt)
    Random(maxAddress)              'There's no earthly way of knowing which direction they are going
    repeat i from maxAddress to 1       '      ...There's no knowing where they're rowing... 
      x:=GetColor(i)                'The danger must be growing cause the rowers keep on rowing       
      LED(i-1,Intensity(x,16))                    'And they're certainly not showing any sign that they are slowing!
      waitcnt(clkfreq/j+cnt)            '   (If you are the lest bit epileptic, stop this demo now!) 
  FreeLock(lock)
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
