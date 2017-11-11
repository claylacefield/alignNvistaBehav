
import numpy, time, pylab
import binascii, csv


import argparse
parser = argparse.ArgumentParser()
parser.add_argument("inputfile", help="Input filename")
parser.add_argument("outputfile", help="Output filename")
#parser.add_argument("--imager", action="store_true", default=False, help="Enable Imager Streaming")
args = parser.parse_args()

bytesRead = open(args.inputfile, "rb").read()


data = []
dataType=0 
metaPkt = 42
packetLength=0 
eventCnt=0 
unixTime=0 
usecTime=0 
ledPower=0 
gpioState=0 
ledState=0 
gpioMode=0
ledMode=0 
row=0
og_max_power=0

metaDataCat=[]
metaDataCatSort=[]
analogFollow=[]

for b in bytesRead:
  data.append(binascii.b2a_hex(b))
  
dataTypeDict = {
  0 : 'NA',
  1 : 'GPIO1',
  2 : 'GPIO2',
  3 : 'GPIO3',
  4 : 'GPIO4',
  5 : 'SYNC',
  6 : 'TRIG',
  7 : 'GPIO4 Analog Input',
  8 : 'EX LED',
  9 : 'OG LED',
  10 : 'DI LED Port',
  54 : 'error',
  55 : 'error',
  84 : 'error',
  118 : 'error',
  133 : 'error',
  85 : 'sync packet'
}
gpioStateMask = 0b10000000

gpioModeDict = {
  0 : 'Output Manual Mode',
  1 : 'TTL Input Mode',
  2 : 'Output Pulse Train Mode',
  3 : 'Output Pulse Train Mode Inverted'
}
gpioModeMask = 0b00000011

ledStatePowerMask = 0b10000000

ledGpioFollowDict = {
  0 : 1,
  32 : 2,
  64 : 3,
  96 : 4
}
ledGpioFollowMask = 0b01100000


ledStateDict = {
  0 : 'Off',
  1 : 'On',
  2 : 'Ramp Up',
  3 : 'Ramp Down'
}
ledStateMask = 0b00000011



ledModeDict = {
  0 : 'Manual Mode',
  1 : 'Manual Mode',
  2 : 'Manual Pulse Train Mode',
  3 : 'NA',
  4 : 'Analog Follow Mode',
  5 : 'GPIO Digital Follow Mode',
  6 : 'GPIO Triggered Pulse Train Mode'
}
ledModeMask = 0b00000111


for i, val in enumerate(data):
  eventPkt=[0,0,0,0,0,0,0]
  if i < len(data) - 32:
    syncPkt = int(data[i]+data[i+1]+data[i+2]+data[i+3]+data[i+4]+data[i+5]+data[i+6],16)
    syncPktNext = int(data[i+7]+data[i+8]+data[i+9]+data[i+10]+data[i+11]+data[i+12]+data[i+13],16)
    if syncPkt == int(0x5555555555555d) and syncPktNext != int(0x5555555555555d):
      metaPkt = i + 7
    elif i == metaPkt:
      dataType = int(data[i],16)
      eventPkt[0] = dataTypeDict.get(dataType,'Unknown')
      
      packetLength = int(data[i+1],16)

      eventCnt = int(data[i+2],16)
      eventPkt[1] = eventCnt
      
      if packetLength == int(0x0b):
        gpioState = int(data[i+3],16)
        if gpioState & gpioStateMask == 0 :
          eventPkt[2] = 'Low'
        else : 
          eventPkt[2] = 'High'

        gpioMode = int(data[i+3],16)
        eventPkt[4] = gpioModeDict[gpioMode & gpioModeMask]

        unixTime = int(data[i+4]+data[i+5]+data[i+6]+data[i+7],16)
        usecTime =  int(data[i+8]+data[i+9]+data[i+10],16)
        eventPkt[3] = unixTime + usecTime/1000000.0
        eventPkt[5] = 0
        eventPkt[6] = 0
        metaDataCat.append(eventPkt)
        print i, eventPkt
        row = row + 1
        metaPkt = metaPkt + 11
      elif packetLength == int(0x0d):
        ledState = int(data[i+4],16)
        eventPkt[2] = ledStateDict[ledState & ledStateMask]

        ledPower =  (int(data[i+3],16)*2 + int(ledState & ledStatePowerMask == 1))/10.0
        eventPkt[5] = ledPower

        ledMode = int(data[i+5],16)
        eventPkt[4] = ledModeDict[ledMode & ledModeMask]

        unixTime = int(data[i+6]+data[i+7]+data[i+8]+data[i+9],16)
        usecTime =  int(data[i+10]+data[i+11]+data[i+12],16)
        eventPkt[3] =  unixTime + usecTime/1000000.0

        eventPkt[6] = ledGpioFollowDict[ledMode & ledGpioFollowMask]

        metaDataCat.append(eventPkt)
        print i, eventPkt
        row = row + 1
        metaPkt = metaPkt + 13
      elif packetLength == int(0x20):

        unixTime = int(data[i+25]+data[i+26]+data[i+27]+data[i+28],16)
        usecTime =  int(data[i+29]+data[i+30]+data[i+31],16)
        afTime =  unixTime + usecTime/1000000.0
        og_max_power = int(data[i+3] + data[i+4],16)
        
        analogFollow.append([eventCnt,afTime,     int((data[i+5] + data[i+6]),16),  int((data[i+5]+data[i+6]  ),16)/655360.0*og_max_power])
        analogFollow.append([eventCnt,afTime+.001,int((data[i+7] + data[i+8]),16),  int((data[i+7]+data[i+8]  ),16)/655360.0*og_max_power])
        analogFollow.append([eventCnt,afTime+.002,int((data[i+9] + data[i+10]),16), int((data[i+9]+data[i+10] ),16)/655360.0*og_max_power])
        analogFollow.append([eventCnt,afTime+.003,int((data[i+11] + data[i+12]),16),int((data[i+11]+data[i+12]),16)/655360.0*og_max_power])
        analogFollow.append([eventCnt,afTime+.004,int((data[i+13] + data[i+14]),16),int((data[i+13]+data[i+14]),16)/655360.0*og_max_power])
        analogFollow.append([eventCnt,afTime+.005,int((data[i+15] + data[i+16]),16),int((data[i+15]+data[i+16]),16)/655360.0*og_max_power])
        analogFollow.append([eventCnt,afTime+.006,int((data[i+17] + data[i+18]),16),int((data[i+17]+data[i+18]),16)/655360.0*og_max_power])
        analogFollow.append([eventCnt,afTime+.007,int((data[i+19] + data[i+20]),16),int((data[i+19]+data[i+20]),16)/655360.0*og_max_power])
        analogFollow.append([eventCnt,afTime+.008,int((data[i+21] + data[i+22]),16),int((data[i+21]+data[i+22]),16)/655360.0*og_max_power])
        analogFollow.append([eventCnt,afTime+.009,int((data[i+23] + data[i+24]),16),int((data[i+23]+data[i+24]),16)/655360.0*og_max_power])

        row = row + 1
        metaPkt = metaPkt + 32

metaDataCatSort = sorted(metaDataCat,key=lambda x: (x[0],x[4],x[5]))

with open(args.outputfile + ".csv", 'wb') as csvfile:
  writer = csv.writer(csvfile, lineterminator='\n')
  writer.writerows(metaDataCatSort)

with open(args.outputfile + "_analog.csv", 'wb') as csvfile:
  writer = csv.writer(csvfile, lineterminator='\n')
  writer.writerows(analogFollow)