#!/usr/bin/env python3

from pyftdi.ftdi import Ftdi
import time
import sys, os
from pyftdi.spi import SpiController
from array import array as Array
import binascii


SR_WIP = 0b00000001  # Busy/Work-in-progress bit
SR_WEL = 0b00000010  # Write enable bit
SR_BP0 = 0b00000100  # bit protect #0
SR_BP1 = 0b00001000  # bit protect #1
SR_BP2 = 0b00010000  # bit protect #2
SR_BP3 = 0b00100000  # bit protect #3
SR_TBP = SR_BP3      # top-bottom protect bit
SR_SP = 0b01000000
SR_BPL = 0b10000000
SR_PROTECT_NONE = 0  # BP[0..2] = 0
SR_PROTECT_ALL = 0b00011100  # BP[0..2] = 1
SR_LOCK_PROTECT = SR_BPL
SR_UNLOCK_PROTECT = 0
SR_BPL_SHIFT = 2

CMD_READ_STATUS = 0x05  # Read status register
CMD_WRITE_ENABLE = 0x06  # Write enable
CMD_WRITE_DISABLE = 0x04  # Write disable
CMD_PROGRAM_PAGE = 0x02  # Write page
CMD_EWSR = 0x50  # Enable write status register
CMD_WRSR = 0x01  # Write status register
CMD_ERASE_SUBSECTOR = 0x20
CMD_ERASE_HSECTOR = 0x52
CMD_ERASE_SECTOR = 0xD8
# CMD_ERASE_CHIP = 0xC7
CMD_ERASE_CHIP = 0x60
CMD_RESET_CHIP = 0x99
CMD_JEDEC_DATA = 0x9f

CMD_READ_LO_SPEED = 0x03  # Read @ low speed
CMD_READ_HI_SPEED = 0x0B  # Read @ high speed
ADDRESS_WIDTH = 3

JEDEC_ID = 0xEF
DEVICES = {0x30: 'W25X', 0x40: 'W25Q'}
SIZES = {0x11: 1 << 17, 0x12: 1 << 18, 0x13: 1 << 19, 0x14: 1 << 20,
         0x15: 2 << 20, 0x16: 4 << 20, 0x17: 8 << 20, 0x18: 16 << 20}
SPI_FREQ_MAX = 104  # MHz
CMD_READ_UID = 0x4B
UID_LEN = 0x8  # 64 bits
READ_UID_WIDTH = 4  # 4 dummy bytes
TIMINGS = {'page': (0.0015, 0.003),  # 1.5/3 ms
           'subsector': (0.200, 0.200),  # 200/200 ms
           'sector': (1.0, 1.0),  # 1/1 s
           'bulk': (32, 64),  # seconds
           'lock': (0.05, 0.1),  # 50/100 ms
           'chip': (4, 11)}
# FEATURES = (SerialFlash.FEAT_SECTERASE |
#             SerialFlash.FEAT_SUBSECTERASE |
#             SerialFlash.FEAT_CHIPERASE)

STRIVE_STREAM_READ = 0x40
STRIVE_STREAM_WRITE = 0x80
STRIVE_REG_READ = 0x48
STRIVE_REG_WRITE = 0x88

spi = SpiController()
spi.configure('ftdi://::/1')
slave = spi.get_port(cs=0, freq=1E4)  # Chip select is 0 -- corresponds to D3

k = ''

def btoint(b):
    return int.from_bytes(b, byteorder='big', signed=False)

# Define the 28-bit trim in the same sequence used by the locking
# algorithm (see digital_pll_controller.v).

trim3 = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,		# 0-6
	 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,		# 7-13
	 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02,		# 14-20
	 0x02, 0x02, 0x02, 0x03, 0x03, 0x03];			# 21-26

trim2 = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,		# 0-6
	 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,		# 7-13
	 0x00, 0x08, 0x88, 0x89, 0xa9, 0xa9, 0xad,		# 14-20
	 0xad, 0xed, 0xef, 0xef, 0xef, 0xff];			# 21-26

trim1 = [0x00, 0x00, 0x00, 0x04, 0x04, 0x05, 0x15,		# 0-6
	 0x15, 0x15, 0x17, 0x17, 0x1f, 0x1f, 0x1f,		# 7-13
	 0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f, 0x3f,		# 14-20
	 0xbf, 0xbf, 0xbf, 0xbf, 0xff, 0xff];			# 21-26

trim0 = [0x00, 0x01, 0x41, 0x41, 0x49, 0x49, 0x49,		# 0-6
	 0x69, 0x6d, 0x6d, 0x7d, 0x7d, 0x7f, 0xff,		# 7-13
	 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,		# 14-20
	 0xff, 0xff, 0xff, 0xff, 0xff, 0xff];			# 21-26

trimidx = 0

while (k != 'q'):

    print("\n-----------------------------------\n")
    print("Select option:")
    print("  (p)   read striVe product codes ")
    print("  (s)   read striVe SPI registers ")
    print("  (r/R) set/clear striVe reset")
    print("  (b/B) set/clear pll bypass")
    print("  (t/T) increment/decrement pll trim 0 to 27")
    print("  (d/D) increment/decrement pll divider 0 to 31")
    print("  (c/C) increment/decrement pll select 0 to 4")
    print("  (m/M) set/clear pll DCO mode")
    print("  (q)   quit")

    print("\n")

    k = input()[0]

    if k == 'p':
        # read striVe product codes
        vendor = slave.exchange([STRIVE_REG_READ, 0x01], 1)
        print("vendor = {}".format(binascii.hexlify(vendor)))

        mfg = slave.exchange([STRIVE_REG_READ, 0x02], 1)
        print("mfg = {}".format(binascii.hexlify(mfg)))

        product = slave.exchange([STRIVE_REG_READ, 0x03], 1)
        print("product = {}".format(binascii.hexlify(product)))

    elif k == 's':
        for reg in [0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e]:
            data = slave.exchange([STRIVE_REG_READ, reg], 1)
            print("reg {} = {}".format(hex(reg), binascii.hexlify(data)))

    elif k == 'r':
        print("Asserting striVe reset.")
        slave.write([STRIVE_REG_WRITE, 0x07, 0x01])

    elif k == 'R':
        print("Clearing striVe reset.")
        slave.write([STRIVE_REG_WRITE, 0x07, 0x00])

    elif k == 'b':
        slave.write([STRIVE_REG_WRITE, 0x05, 0x01])
        pll_bypass = slave.exchange([STRIVE_REG_READ, 0x05], 1)
        print("pll_bypass = {}\n".format(binascii.hexlify(pll_bypass)))

    elif k == 'B':
        slave.write([STRIVE_REG_WRITE, 0x05, 0x00])
        pll_bypass = slave.exchange([STRIVE_REG_READ, 0x05], 1)
        print("pll_bypass = {}\n".format(binascii.hexlify(pll_bypass)))

    elif k == 'm':
        slave.write([STRIVE_REG_WRITE, 0x04, 0x07])
        dco_mode = slave.exchange([STRIVE_REG_READ, 0x04], 1)
        print("dco_mode = {}\n".format(binascii.hexlify(dco_mode)))

    elif k == 'M':
        slave.write([STRIVE_REG_WRITE, 0x04, 0x03])
        dco_mode = slave.exchange([STRIVE_REG_READ, 0x04], 1)
        print("dco_mode = {}\n".format(binascii.hexlify(dco_mode)))

    elif k == 't':
        trimidx = trimidx + 1
        pll_trim0 = trim0[trimidx]
        pll_trim1 = trim1[trimidx]
        pll_trim2 = trim2[trimidx]
        pll_trim3 = trim3[trimidx]

        slave.write([STRIVE_REG_WRITE, 0x09, pll_trim0])
        slave.write([STRIVE_REG_WRITE, 0x0a, pll_trim1])
        slave.write([STRIVE_REG_WRITE, 0x0b, pll_trim2])
        slave.write([STRIVE_REG_WRITE, 0x0c, pll_trim3])

        pll_trim = slave.exchange([STRIVE_STREAM_READ, 0x09], 4)
        print("pll_trim = {} index {}\n".format(binascii.hexlify(pll_trim), trimidx))

    elif k == 'T':
        trimidx = trimidx - 1
        pll_trim0 = trim0[trimidx]
        pll_trim1 = trim1[trimidx]
        pll_trim2 = trim2[trimidx]
        pll_trim3 = trim3[trimidx]

        slave.write([STRIVE_REG_WRITE, 0x09, pll_trim0])
        slave.write([STRIVE_REG_WRITE, 0x0a, pll_trim1])
        slave.write([STRIVE_REG_WRITE, 0x0b, pll_trim2])
        slave.write([STRIVE_REG_WRITE, 0x0c, pll_trim3])

        pll_trim = slave.exchange([STRIVE_STREAM_READ, 0x09], 4)
        print("pll_trim = {} index {}\n".format(binascii.hexlify(pll_trim), trimidx))

    elif k == 'd':
        pll_div = btoint(slave.exchange([STRIVE_REG_READ, 0x0e], 1))
        if pll_div < 31:
            pll_div = pll_div + 1
        slave.write([STRIVE_REG_WRITE, 0x0e, pll_div])
        pll_div = slave.exchange([STRIVE_REG_READ, 0x0e], 1)
        print("pll_div = {}\n".format(binascii.hexlify(pll_div)))

    elif k == 'D':
        pll_div = btoint(slave.exchange([STRIVE_REG_READ, 0x0e], 1))
        if pll_div > 0:
            pll_div = pll_div - 1
        slave.write([STRIVE_REG_WRITE, 0x0e, pll_div])
        pll_div = slave.exchange([STRIVE_REG_READ, 0x0e], 1)
        print("pll_div = {}\n".format(binascii.hexlify(pll_div)))

    elif k == 'c':
        pll_sel = btoint(slave.exchange([STRIVE_REG_READ, 0x0d], 1))
        if pll_sel < 4:
            pll_sel = pll_sel + 1
        slave.write([STRIVE_REG_WRITE, 0x0d, pll_sel])
        pll_sel = slave.exchange([STRIVE_REG_READ, 0x0d], 1)
        print("pll_sel = {}\n".format(binascii.hexlify(pll_sel)))

    elif k == 'C':
        pll_sel = btoint(slave.exchange([STRIVE_REG_READ, 0x0d], 1))
        if pll_sel > 0:
            pll_sel = pll_sel - 1
        slave.write([STRIVE_REG_WRITE, 0x0d, pll_sel])
        pll_sel = slave.exchange([STRIVE_REG_READ, 0x0d], 1)
        print("pll_sel = {}\n".format(binascii.hexlify(pll_sel)))

    elif k == 'q':
        print("Exiting...")

    else:
        print('Selection not recognized.\n')

spi.terminate()

