/*

MIT License

Copyright (c) 2021 Domenic Wüthrich, Manuel Eggimann, Yves Acremann (ETH Zurich)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#ifndef _IO_H_
#define _IO_H_

#define CORE_HZ 40000000


#define UART                ((Uart_Reg*)(0xF0010000))

#define TIMER_PRESCALER     ((Prescaler_Reg*)0xF0020000)
#define TIMER_INTERRUPT     ((TimerInterruptCtrl_Reg*)0xF0020010)
#define TIMER_A_BASE        ((Timer_Reg*)0xF0020040)
#define TIMER_B_BASE        ((Timer_Reg*)0xF0020050)
#define TIMER_C_BASE        ((Timer_Reg*)0xF0020060)
#define TIMER_D_BASE        ((Timer_Reg*)0xF0020070)

#define SPI                 0xF0030000

#define CONTROL_REG         *((volatile uint32_t*)(0xF0000000))
#define STATUS_REG          *((volatile uint32_t*)(0xF0000004))

#define PULSEID_CONTROL_REG    *((volatile uint32_t*)(0xF0000008))
#define PULSEID_WRITE_1        *((volatile uint32_t*)(0xF000000c))
#define PULSEID_WRITE_2        *((volatile uint32_t*)(0xF0000010))
#define PULSEID_READ_1         *((volatile uint32_t*)(0xF0000014))
#define PULSEID_READ_2         *((volatile uint32_t*)(0xF0000018))

#include "type.h"
//#include "soc.h"

static inline u32 read_u32(u32 address){
    return *((volatile u32*) address);
}

static inline void write_u32(u32 data, u32 address){
    *((volatile u32*) address) = data;
}

static inline u16 read_u16(u32 address){
    return *((volatile u16*) address);
}

static inline void write_u16(u16 data, u32 address){
    *((volatile u16*) address) = data;
}

static inline u8 read_u8(u32 address){
    return *((volatile u8*) address);
}

static inline void write_u8(u8 data, u32 address){
    *((volatile u8*) address) = data;
}

static inline void write_u32_ad(u32 address, u32 data){
    *((volatile u32*) address) = data;
}

#define writeReg_u32(name, offset) \
static inline void name(u32 reg, u32 value){ \
    write_u32(value, reg + offset); \
} \

#define readReg_u32(name, offset) \
static inline u32 name(u32 reg){ \
    return read_u32(reg + offset); \
} \


#endif
