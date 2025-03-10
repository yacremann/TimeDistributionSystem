# -*- coding: utf-8 -*-
#
# This file is part of the TimeDistributionChannel project
#
#
#
# Distributed under the terms of the MIT license.
# See LICENSE.txt for more info.

""" Time Distribution Channel

Trigger channel for the time distribution system

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
# PROTECTED REGION ID(TimeDistributionChannel.additionnal_import) ENABLED START #
import time
import threading
# PROTECTED REGION END #    //  TimeDistributionChannel.additionnal_import

__all__ = ["TimeDistributionChannel", "main"]


class TimeDistributionChannel(Device):
    """
    Trigger channel for the time distribution system
    """
    __metaclass__ = DeviceMeta
    # PROTECTED REGION ID(TimeDistributionChannel.class_variable) ENABLED START #
    
    """
        Set the values in hardware
    """
    def setValues(self):
        if (self.active_value):
            self.set_state(DevState.ON)
        else:
            self.set_state(DevState.STANDBY)
            
        statusValue = 0
        if (self.active_value):
            statusValue = 1
        cmd_str = 'D ' + str(self.board) \
            + ' ' + str(self.channel) \
            + ' ' + str(statusValue) \
            + ' ' + str(self.delay_cycles_value) \
            + ' ' + str(self.length_cycles_value) \
            + ' ' + str(self.divider_value) \
            + ' ' + str(self.reminder_value)
        try:
            self.masterDev.send_cmd(cmd_str)
        except:
            pass
            
    
    """
        Periodically call self.setHardware
    """
    def runnable(self):
        self.keep_running = True
        while(self.keep_running):
            self.setValues()
            time.sleep(10.0)
    
    # PROTECTED REGION END #    //  TimeDistributionChannel.class_variable

    # -----------------
    # Device Properties
    # -----------------

    master = device_property(
        dtype='str',
        mandatory=True
    )

    board = device_property(
        dtype='uint16',
        mandatory=True
    )

    channel = device_property(
        dtype='uint16',
        mandatory=True
    )

    ClkFreq = device_property(
        dtype='double', default_value=80.0
    )

    # ----------
    # Attributes
    # ----------

    DelayCycles = attribute(
        dtype='uint',
        format="%6.0f",
        access=AttrWriteType.READ_WRITE,
        label="Delay (cycles)",
        doc="Delay in 80 MHz clock cycles",
        
        min_value=0,
        max_value=999999,
        memorized=True,
        hw_memorized=True,
    )

    LengthCycles = attribute(
        dtype='uint',
        access=AttrWriteType.READ_WRITE,
        label="Pulse length (cycles)",
        doc="Pulse length in 80 MHz cycles",
    )

    Active = attribute(
        dtype='bool',
        access=AttrWriteType.READ_WRITE,
        label="Active",
        memorized=True,
        hw_memorized=True,
        doc="Pulser output is ON when active = True",
    )

    Divider = attribute(
        dtype='uint16',
        access=AttrWriteType.READ_WRITE,
        label="Divider",
        max_value=255,
        min_value=1,
        memorized=True,
        hw_memorized=True,
        doc="A pulse is generated if PulseID % Divider == Reminder.\nIf divider=0: a value of 1 is set by hardware.",
    )

    Reminder = attribute(
        dtype='uint16',
        access=AttrWriteType.READ_WRITE,
        max_value=254,
        min_value=0,
        memorized=True,
        hw_memorized=True,
        doc="A pulse is generated if PulseID % Divider == Reminder.\nIf Divider < Reminder: no pulse is generated.",
    )

    Delay = attribute(
        dtype='double',
        access=AttrWriteType.READ_WRITE,
        label="Delay",
        unit="ns",
        format="%10.1f",
        min_value=0,
        memorized=True,
        hw_memorized=True,
        doc="Delay in ns. Notice, that it will be rounded in clock cycles. In addition,\ndelays of less than 2 clock cycles are rounded up to 2 cycles.",
    )

    Length = attribute(
        dtype='double',
        access=AttrWriteType.READ_WRITE,
        label="Pulse length",
        unit="ns",
        format="%10.1f",
        min_value=0,
        memorized=True,
        hw_memorized=True,
        doc="Pulse length in ns. Notice, that it will be rounded in clock cycles. In addition,\nlengths of less than 2 clock cycles are rounded up to 2 cycles.",
    )

    # ---------------
    # General methods
    # ---------------

    def init_device(self):
        Device.init_device(self)
        # PROTECTED REGION ID(TimeDistributionChannel.init_device) ENABLED START #
        self.masterDev = PyTango.DeviceProxy(self.master)
        self.delay_cycles_value  = 0
        self.length_cycles_value = 0
        self.divider_value = 1
        self.reminder_value = 0
        self.active_value = False
        
        self.keep_running = True
        self.thread = threading.Thread(target=self.runnable)
        self.thread.start()
        
        self.set_state(DevState.STANDBY)
        # PROTECTED REGION END #    //  TimeDistributionChannel.init_device

    def always_executed_hook(self):
        # PROTECTED REGION ID(TimeDistributionChannel.always_executed_hook) ENABLED START #
        pass
        # PROTECTED REGION END #    //  TimeDistributionChannel.always_executed_hook

    def delete_device(self):
        # PROTECTED REGION ID(TimeDistributionChannel.delete_device) ENABLED START #
        self.keep_running = False
        try:
            self.thread.join()
        except:
            pass
        # PROTECTED REGION END #    //  TimeDistributionChannel.delete_device

    # ------------------
    # Attributes methods
    # ------------------

    def read_DelayCycles(self):
        # PROTECTED REGION ID(TimeDistributionChannel.DelayCycles_read) ENABLED START #
        return self.delay_cycles_value
        # PROTECTED REGION END #    //  TimeDistributionChannel.DelayCycles_read

    def write_DelayCycles(self, value):
        # PROTECTED REGION ID(TimeDistributionChannel.DelayCycles_write) ENABLED START #
        self.delay_cycles_value = value
        self.setValues()
        # PROTECTED REGION END #    //  TimeDistributionChannel.DelayCycles_write

    def read_LengthCycles(self):
        # PROTECTED REGION ID(TimeDistributionChannel.LengthCycles_read) ENABLED START #
        return self.length_cycles_value
        # PROTECTED REGION END #    //  TimeDistributionChannel.LengthCycles_read

    def write_LengthCycles(self, value):
        # PROTECTED REGION ID(TimeDistributionChannel.LengthCycles_write) ENABLED START #
        self.length_cycles_value = value
        self.setValues()
        # PROTECTED REGION END #    //  TimeDistributionChannel.LengthCycles_write

    def read_Active(self):
        # PROTECTED REGION ID(TimeDistributionChannel.Active_read) ENABLED START #
        return self.active_value
        # PROTECTED REGION END #    //  TimeDistributionChannel.Active_read

    def write_Active(self, value):
        # PROTECTED REGION ID(TimeDistributionChannel.Active_write) ENABLED START #
        self.active_value = value
        self.setValues()
        # PROTECTED REGION END #    //  TimeDistributionChannel.Active_write

    def read_Divider(self):
        # PROTECTED REGION ID(TimeDistributionChannel.Divider_read) ENABLED START #
        return self.divider_value
        # PROTECTED REGION END #    //  TimeDistributionChannel.Divider_read

    def write_Divider(self, value):
        # PROTECTED REGION ID(TimeDistributionChannel.Divider_write) ENABLED START #
        self.divider_value = value
        self.setValues()
        # PROTECTED REGION END #    //  TimeDistributionChannel.Divider_write

    def read_Reminder(self):
        # PROTECTED REGION ID(TimeDistributionChannel.Reminder_read) ENABLED START #
        return self.reminder_value
        # PROTECTED REGION END #    //  TimeDistributionChannel.Reminder_read

    def write_Reminder(self, value):
        # PROTECTED REGION ID(TimeDistributionChannel.Reminder_write) ENABLED START #
        self.reminder_value = value
        self.setValues()
        # PROTECTED REGION END #    //  TimeDistributionChannel.Reminder_write

    def read_Delay(self):
        # PROTECTED REGION ID(TimeDistributionChannel.Delay_read) ENABLED START #
        return self.delay_cycles_value/self.ClkFreq/1e6 *1e9
        # PROTECTED REGION END #    //  TimeDistributionChannel.Delay_read

    def write_Delay(self, value):
        # PROTECTED REGION ID(TimeDistributionChannel.Delay_write) ENABLED START #
        self.delay_cycles_value = round(value / 1e9 * self.ClkFreq * 1e6)
        if (self.delay_cycles_value < 2):
            self.delay_cycles_value = 2
        self.setValues()
        # PROTECTED REGION END #    //  TimeDistributionChannel.Delay_write

    def read_Length(self):
        # PROTECTED REGION ID(TimeDistributionChannel.Length_read) ENABLED START #
        return self.length_cycles_value/self.ClkFreq/1e6 *1e9
        # PROTECTED REGION END #    //  TimeDistributionChannel.Length_read

    def write_Length(self, value):
        # PROTECTED REGION ID(TimeDistributionChannel.Length_write) ENABLED START #
        self.length_cycles_value = round(value / 1e9 * self.ClkFreq*1e6)
        if (self.length_cycles_value < 2):
            self.length_cycles_value = 2
        self.setValues()
        # PROTECTED REGION END #    //  TimeDistributionChannel.Length_write


    # --------
    # Commands
    # --------

# ----------
# Run server
# ----------


def main(args=None, **kwargs):
    # PROTECTED REGION ID(TimeDistributionChannel.main) ENABLED START #
    return run((TimeDistributionChannel,), args=args, **kwargs)
    # PROTECTED REGION END #    //  TimeDistributionChannel.main

if __name__ == '__main__':
    main()
