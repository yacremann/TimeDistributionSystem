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

//#define SPI                 0xF0030000


// registers for controlling the AD9543 (bit banging SPI)
// (also used for the 1000Hz trigger inhibit signal (bit 15))
#define CONTROL_REG                 *((volatile uint32_t*)(0xF0000000))
#define STATUS_REG                  *((volatile uint32_t*)(0xF0000004))

// registers to read / write the pulse-id
#define PULSEID_CONTROL_REG         *((volatile uint32_t*)(0xF0000008))
#define PULSEID_WRITE_1             *((volatile uint32_t*)(0xF000000c))
#define PULSEID_WRITE_2             *((volatile uint32_t*)(0xF0000010))
#define PULSEID_READ_1              *((volatile uint32_t*)(0xF0000014))
#define PULSEID_READ_2              *((volatile uint32_t*)(0xF0000018))

// registers to communicate with the delay generators
#define COMM_CONTROL_BOARD_CHANNEL  *((volatile uint32_t*)(0xF000001C))
#define COMM_DELAY 		            *((volatile uint32_t*)(0xF0000020))
#define COMM_LENGTH 		        *((volatile uint32_t*)(0xF0000024))
#define COMM_STATUS    	            *((volatile uint32_t*)(0xF0000028))
#define COMM_MOD_DIV   	            *((volatile uint32_t*)(0xF0000030))

// frequency counter
#define FREQUENCY_REG    	        *((volatile uint32_t*)(0xF000002C))

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
