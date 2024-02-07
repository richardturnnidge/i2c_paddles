#main.py

import utime
from machine import mem32, Pin, ADC
from i2cSlave import i2c_slave

# ------------------------------------------------------------
#
#    SETUP IO PORTS & DEFAULT VALUES
#
# ------------------------------------------------------------

potL = ADC(Pin(26)) # potentiometer input
potR = ADC(Pin(27)) # potentiometer input

btnL = Pin(16, mode=Pin.IN, pull=Pin.PULL_UP) # button input
btnR = Pin(17, mode=Pin.IN, pull=Pin.PULL_UP) # button input

mode=0

s_i2c = i2c_slave(0,sda=0,scl=1,slaveAddress=0x52)

try:
    while True:
        if s_i2c.any():
            print("got request:")
            print(s_i2c.get())
            mode=1
        if s_i2c.anyRead():
            if (mode==1):
                s_i2c.put(int(potL.read_u16()/256) & 0xff)
                print(int(potL.read_u16()/256))
                mode=2
            elif (mode==2):
                s_i2c.put(int(potR.read_u16()/256) & 0xff)
                print(int(potR.read_u16()/256))
                mode=3
            elif (mode==3):
                s_i2c.put(int((btnL.value() * 2) + int(btnR.value())) & 0xff)
                print( str(btnL.value()))  
                mode=0

except KeyboardInterrupt:
    pass

except KeyboardInterrupt:
    pass

