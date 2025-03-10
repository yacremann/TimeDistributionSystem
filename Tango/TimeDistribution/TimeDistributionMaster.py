# -*- coding: utf-8 -*-
#
# This file is part of the TimeDistributionMaster project
#
#
#
# Distributed under the terms of the MIT license.
# See LICENSE.txt for more info.

""" Time Distribution Master

Master (transmitter) of th time distribution system

    Copyright (C) 2025  Yves Acremann, ETH Zurich, Switzerland

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

"""

# PyTango imports
import PyTango
from PyTango import DebugIt
from PyTango.server import run
from PyTango.server import Device, DeviceMeta
from PyTango.server import attribute, command
from PyTango.server import device_property
from PyTango import AttrQuality, DispLevel, DevState
from PyTango import AttrWriteType, PipeWriteType
# Additional import
# PROTECTED REGION ID(TimeDistributionMaster.additionnal_import) ENABLED START #
import serial
import time
import threading
# PROTECTED REGION END #    //  TimeDistributionMaster.additionnal_import

__all__ = ["TimeDistributionMaster", "main"]


class TimeDistributionMaster(Device):
    """
    Master (transmitter) of th time distribution system
    """
    __metaclass__ = DeviceMeta
    # PROTECTED REGION ID(TimeDistributionMaster.class_variable) ENABLED START #
    
    """
        Read the tty buffer empty
    """
    def read_empty(self):
        try:
            while(self.ser.readline() != b''):
                time.sleep(0.1)
        except:
            pass
        
        
    """
        Send a command and wait for the answer
    """
    def write_and_read(self, command):
        with self.lock:
            try:
                self.ser.write(command.encode('ascii'))
                return self.ser.readline().decode('ascii')
            except:
                self.set_state(DevState.FAULT)
            
    
    def status_runnable(self):
        self.keep_running = True
        while (self.keep_running):
            try:
                # read the frequency:
                self.frequency_value = int(self.write_and_read('f\n').strip())
                # read the pulse-id:
                result = self.write_and_read('i\n')
                ids = result.split(' ')
                self.pulse_id_value = (int(ids[0], 16) << 32) + int(ids[1].strip(), 16)
                # read the status bits:
                statusBits = int(self.write_and_read('s\n').strip(), 16)
                self.locked_value = (statusBits & 0x02) != 0  
                self.clk80_value  = (statusBits & 0x04) != 0
                self.clk100_value = (statusBits & 0x08) != 0
                # read the inhibit bit
                result = self.write_and_read('t\n')
                self.inhibit_100_Hz = (int(result.strip()) == 1)
                time.sleep(0.5)
            except:
                self.set_state(DevState.FAULT)
                break
    
    # PROTECTED REGION END #    //  TimeDistributionMaster.class_variable

    # -----------------
    # Device Properties
    # -----------------

    tty = device_property(
        dtype='str', default_value="/dev/ttyUSB0"
    )

    # ----------
    # Attributes
    # ----------

    PulseId = attribute(
        dtype='uint64',
        label="Pulse-Id",
        doc="The Pulse-Id",
    )

    Frequency = attribute(
        dtype='double',
        label="Frequency",
        unit="Hz",
        doc="Frequency of the oscillator",
    )

    Locked = attribute(
        dtype='bool',
        label="PLL locked",
        doc="True if the PLL is locked",
    )

    Clk80 = attribute(
        dtype='bool',
        label="80 MHz present",
        doc="True if the oscillator clock is present",
    )

    Clk100 = attribute(
        dtype='bool',
        label="100 Hz present",
        doc="True if the 100 Hz clock is present (amplifier running)",
    )

    Inhibit_100Hz = attribute(
        dtype='bool',
        access=AttrWriteType.READ_WRITE,
        label="Inhibit 100 Hz",
        doc="Inhibit the 100 Hz trigger\n(if set, no triggers are sent to the clients and no new pulse IDs are generated)",
    )

    # ---------------
    # General methods
    # ---------------

    def init_device(self):
        Device.init_device(self)
        # PROTECTED REGION ID(TimeDistributionMaster.init_device) ENABLED START #
        self.frequency_value = 0.0
        self.pulse_id_value  = 0
        self.clk80_value     = False
        self.clk100_value    = False
        self.locked_value    = False
        self.keep_running    = False
        self.inhibit_100_Hz  = False
        self.lock            = threading.Lock()
        self.Open()
        # PROTECTED REGION END #    //  TimeDistributionMaster.init_device

    def always_executed_hook(self):
        # PROTECTED REGION ID(TimeDistributionMaster.always_executed_hook) ENABLED START #
        pass
        # PROTECTED REGION END #    //  TimeDistributionMaster.always_executed_hook

    def delete_device(self):
        # PROTECTED REGION ID(TimeDistributionMaster.delete_device) ENABLED START #
        self.Close()
        # PROTECTED REGION END #    //  TimeDistributionMaster.delete_device

    # ------------------
    # Attributes methods
    # ------------------

    def read_PulseId(self):
        # PROTECTED REGION ID(TimeDistributionMaster.PulseId_read) ENABLED START #
        return self.pulse_id_value
        # PROTECTED REGION END #    //  TimeDistributionMaster.PulseId_read

    def is_PulseId_allowed(self, attr):
        # PROTECTED REGION ID(TimeDistributionMaster.is_PulseId_allowed) ENABLED START #
        return self.get_state() not in [DevState.STANDBY,DevState.FAULT]
        # PROTECTED REGION END #    //  TimeDistributionMaster.is_PulseId_allowed

    def read_Frequency(self):
        # PROTECTED REGION ID(TimeDistributionMaster.Frequency_read) ENABLED START #
        return self.frequency_value
        # PROTECTED REGION END #    //  TimeDistributionMaster.Frequency_read

    def is_Frequency_allowed(self, attr):
        # PROTECTED REGION ID(TimeDistributionMaster.is_Frequency_allowed) ENABLED START #
        return self.get_state() not in [DevState.STANDBY,DevState.FAULT]
        # PROTECTED REGION END #    //  TimeDistributionMaster.is_Frequency_allowed

    def read_Locked(self):
        # PROTECTED REGION ID(TimeDistributionMaster.Locked_read) ENABLED START #
        return self.locked_value
        # PROTECTED REGION END #    //  TimeDistributionMaster.Locked_read

    def is_Locked_allowed(self, attr):
        # PROTECTED REGION ID(TimeDistributionMaster.is_Locked_allowed) ENABLED START #
        return self.get_state() not in [DevState.STANDBY,DevState.FAULT]
        # PROTECTED REGION END #    //  TimeDistributionMaster.is_Locked_allowed

    def read_Clk80(self):
        # PROTECTED REGION ID(TimeDistributionMaster.Clk80_read) ENABLED START #
        return self.clk80_value
        # PROTECTED REGION END #    //  TimeDistributionMaster.Clk80_read

    def is_Clk80_allowed(self, attr):
        # PROTECTED REGION ID(TimeDistributionMaster.is_Clk80_allowed) ENABLED START #
        return self.get_state() not in [DevState.STANDBY,DevState.FAULT]
        # PROTECTED REGION END #    //  TimeDistributionMaster.is_Clk80_allowed

    def read_Clk100(self):
        # PROTECTED REGION ID(TimeDistributionMaster.Clk100_read) ENABLED START #
        return self.clk100_value
        # PROTECTED REGION END #    //  TimeDistributionMaster.Clk100_read

    def is_Clk100_allowed(self, attr):
        # PROTECTED REGION ID(TimeDistributionMaster.is_Clk100_allowed) ENABLED START #
        return self.get_state() not in [DevState.STANDBY,DevState.FAULT]
        # PROTECTED REGION END #    //  TimeDistributionMaster.is_Clk100_allowed

    def read_Inhibit_100Hz(self):
        # PROTECTED REGION ID(TimeDistributionMaster.Inhibit_100Hz_read) ENABLED START #
        return self.inhibit_100_Hz
        # PROTECTED REGION END #    //  TimeDistributionMaster.Inhibit_100Hz_read

    def write_Inhibit_100Hz(self, value):
        # PROTECTED REGION ID(TimeDistributionMaster.Inhibit_100Hz_write) ENABLED START #
        if (value):
            self.write_and_read('T 1\n')
        else:
            self.write_and_read('T 0\n')
        # PROTECTED REGION END #    //  TimeDistributionMaster.Inhibit_100Hz_write

    def is_Inhibit_100Hz_allowed(self, attr):
        # PROTECTED REGION ID(TimeDistributionMaster.is_Inhibit_100Hz_allowed) ENABLED START #
        if attr==attr.READ_REQ:
            return self.get_state() not in [DevState.STANDBY,DevState.FAULT]
        else:
            return self.get_state() not in [DevState.STANDBY,DevState.FAULT]
        # PROTECTED REGION END #    //  TimeDistributionMaster.is_Inhibit_100Hz_allowed


    # --------
    # Commands
    # --------

    @command(
    )
    @DebugIt()
    def Open(self):
        # PROTECTED REGION ID(TimeDistributionMaster.Open) ENABLED START #
        self.ser = serial.Serial(self.tty, 115200, timeout=0.5, stopbits=2)
        self.thread = threading.Thread(target=self.status_runnable)
        self.thread.start()
        self.set_state(DevState.ON)
        # PROTECTED REGION END #    //  TimeDistributionMaster.Open

    def is_Open_allowed(self):
        # PROTECTED REGION ID(TimeDistributionMaster.is_Open_allowed) ENABLED START #
        return self.get_state() not in [DevState.ON,DevState.FAULT]
        # PROTECTED REGION END #    //  TimeDistributionMaster.is_Open_allowed

    @command(
    )
    @DebugIt()
    def Close(self):
        # PROTECTED REGION ID(TimeDistributionMaster.Close) ENABLED START #
        self.set_state(DevState.STANDBY)
        self.keep_running = False
        try:
            self.thread.join()
        except:
            pass
        try:
            self.ser.close()
        except:
            pass
        # PROTECTED REGION END #    //  TimeDistributionMaster.Close

    def is_Close_allowed(self):
        # PROTECTED REGION ID(TimeDistributionMaster.is_Close_allowed) ENABLED START #
        return self.get_state() not in [DevState.STANDBY]
        # PROTECTED REGION END #    //  TimeDistributionMaster.is_Close_allowed

    @command(
    dtype_in='str', 
    dtype_out='str', 
    )
    @DebugIt()
    def send_cmd(self, argin):
        # PROTECTED REGION ID(TimeDistributionMaster.send_cmd) ENABLED START #
        if (self.get_state() not in [DevState.ON]):
            return "not active"
        return self.write_and_read(argin + '\n').strip()
        # PROTECTED REGION END #    //  TimeDistributionMaster.send_cmd

# ----------
# Run server
# ----------


def main(args=None, **kwargs):
    # PROTECTED REGION ID(TimeDistributionMaster.main) ENABLED START #
    return run((TimeDistributionMaster,), args=args, **kwargs)
    # PROTECTED REGION END #    //  TimeDistributionMaster.main

if __name__ == '__main__':
    main()
