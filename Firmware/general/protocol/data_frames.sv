/*

    This module defines the protocol of the time distribution system.

    Copyright (C) 2025, Yves Acremann, ETH Zurich

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

*/


/*
    The data structure for the payload of a frame:
    payoad_type:
        0x01: pulse-ID
        0x02: delay setting
        rest: for future use
        
    data:    The data can either be the pulse-ID (64 bit value) or a delay setting.
*/
typedef struct packed
{
    logic [  7:0] payload_type;
    logic [127:0] data;
} payload_t;


/*
    Structure holding the pulse-id (64 bits)
    The rest is empty
*/
typedef struct packed
{
    logic unsigned [63:0] pulse_id;
    logic          [63:0] empty;
} pulse_id_t;

/*
    Structure of the data for setting a delay:
    
    board:   The address of the board
    channel: The address of the channel on a board (for example a delay output)
    status:  
        0x00: output off
        0x01: output on
    delay:  The delay in clock cycles (80 MHz for the time distribution receivers)
    length: The pusle lendth in clock cycles (80 MHz for the time distribution receivers)
    divider: Frequency divider for the repetition rate
    modulus: A pulse is generated if (pulse_id % divider) == modulus
    
    In order to be compatible to the data dtructure the length MUST be 128 bits!
*/
typedef struct packed
{
    logic           [ 7:0] board;
    logic           [ 7:0] channel;
    logic           [ 7:0] status;
	 // new: longer delays
	 logic unsigned [31:0] delay;
     logic unsigned [31:0] length;
	 // trigger modulus and divider
	 logic unsigned [ 7:0] divider;
	 logic unsigned [ 7:0] modulus;
	 logic          [23:0] empty;
} delay_data_t;


/*
    The data frame (incl. crc)
*/
typedef struct packed
{
    payload_t    payload;
    logic [15:0] crc;
} frame_t;

