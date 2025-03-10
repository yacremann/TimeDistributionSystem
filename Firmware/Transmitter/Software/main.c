#include <stdint.h>
#include <stdbool.h>


#include "uart.h"
#include "printf.h"
#include <stdlib.h>
#include <string.h>
//#include <stdio.h>
//#include <math.h>

#include "io.h"

#include "ad9543_regs.h"


char line[255];

// set / clear the bit bangign bits for SPI to the AD9543
void set_clk(char clk){
    if (clk > 0)
        CONTROL_REG = CONTROL_REG | 0x01;
    else
        CONTROL_REG = CONTROL_REG & (~0x01);
}

void set_cs(char cs){
    if (cs > 0)
        CONTROL_REG = CONTROL_REG | 0x02;
    else
        CONTROL_REG = CONTROL_REG & (~0x02);
}

void set_data(char data){
    if (data > 0)
        CONTROL_REG = CONTROL_REG | 0x04;
    else
        CONTROL_REG = CONTROL_REG & (~0x04);
}

// SPI by hand (bit banging)
void write_bitbang(uint8_t data){
    set_clk(0);
    for (int i = 0; i < 8; i++){
        set_data((data >> (7-i)) & 0x01);
        set_clk(1);
        set_clk(0);
    }
}

uint8_t read_bitbang(){
    set_clk(0);
    uint8_t result;
    result = 0;
    for (int i = 0; i < 8; i++){
        set_clk(1);
        result = result | ((STATUS_REG & 0x01) << (7-i));
        set_clk(0);
    }
    return(result);
}

void write_register(uint16_t addr, uint8_t value){
    // clear read bit
    uint16_t command = addr & (uint16_t)(~0x8000);
    set_cs(0);
    write_bitbang((uint8_t)((command >> 8) & 0x00ff));
    write_bitbang((uint8_t)(command & 0x00ff));
    write_bitbang(value);
    set_cs(1);
}

uint8_t read_register(uint16_t addr){
    // set read bit
    uint16_t command = addr | 0x8000;
    // send the command
    set_cs(0);
    write_bitbang((uint8_t)((command >> 8) & 0x00ff));
    write_bitbang((uint8_t)(command & 0x00ff));
    // read one byte (the register)
    uint8_t result = read_bitbang();
    set_cs(1);
    return(result);
}


void write_bit(uint16_t addr, uint8_t bit, uint8_t value){
    uint8_t regVal = read_register(addr);
    if (value == 0)
        regVal = regVal & ~(0x01 << bit);
    else
        regVal = regVal | (0x01 << bit);
    write_register(addr, regVal);
}



void io_update(){
    write_register(0x000f, 0x01);
}


void sysclk_calib(){
    int counter = 0;
    write_bit(0x2000, 2, 0);
    io_update();
    write_bit(0x2000, 2, 1);
    io_update();
    for (int i = 0; i < 100; i++);
    uint8_t result = read_register(0x3001);
    while ((counter < 10000) && ((result & 0x03) < 3)){
        result = read_register(0x3001);
        counter++;
    }
}


void pll_calib(int pll_nr){
    uint16_t cal_reg;
    uint16_t lock_reg;
    uint16_t auto_sync_reg;
    uint16_t sync_reg;
    if (pll_nr == 0){
        cal_reg = 0x2100;
        lock_reg = 0x3100;
        auto_sync_reg = 0x10db;
        sync_reg = 0x2101;
    }
    if (pll_nr == 1){
        cal_reg = 0x2200;
        lock_reg = 0x3200;
        auto_sync_reg = 0x14db;
        sync_reg = 0x2201;
    }
    write_bit(cal_reg, 1, 0);
    io_update();
    write_bit(cal_reg, 1, 1);
    io_update();
    
    int counter = 0;
    uint8_t result = read_register(lock_reg);
    
    //printf("Lock PLL reg: %d: %d\n", pll_nr, result);
    while ((counter < 10000) && ((result & 0x08) == 0)){
        result = read_register(lock_reg);
        counter++;
    }
    //printf("Lock PLL %d: %d\n", pll_nr, counter);
    
    write_bit(sync_reg, 3, 1);
    io_update();
    write_bit(sync_reg, 3, 0);
    io_update();
}



/**
 *  setting of the delays
 */
int set_delay(int board, int channel, int delay, int length, bool on, int div, int mod){
    if (COMM_STATUS != 0) return -1;
    // set registers:
    uint32_t control_board_channel = on | (channel << 8) | (board << 16);
    COMM_CONTROL_BOARD_CHANNEL = control_board_channel;
    COMM_DELAY = delay;
    COMM_LENGTH = length;
    COMM_MOD_DIV = (mod << 8) | div;
    // toggle fifo write flag:
    COMM_CONTROL_BOARD_CHANNEL = control_board_channel | (1 << 31);
    COMM_CONTROL_BOARD_CHANNEL = control_board_channel;
    if (div <= 0) div=1;
    return 0;
}

/**
 *  set the pulse-id
 */
void set_pulse_id(uint32_t pulse_id_upper, uint32_t pulse_id_lower){
    PULSEID_CONTROL_REG = 0x00;
    PULSEID_WRITE_1 = pulse_id_lower;
    PULSEID_WRITE_2 = pulse_id_upper;
    for (int i = 0; i < 100; i++);
    PULSEID_CONTROL_REG = 0x01;
    for (int i = 0; i < 100; i++);
    PULSEID_CONTROL_REG = 0x00;
}

/**
 * Set / clear the inhibit bit in the control register
 */
void set_inhibit(char inhibit){
    if (inhibit > 0)
        CONTROL_REG = CONTROL_REG | (0x01 << 15);
    else
        CONTROL_REG = CONTROL_REG & (~(0x01 << 15));
}

/**
 * returns 1 if the inhibit bit is set
 */
char get_inhibit(){
    if (CONTROL_REG & (0x01 << 15))
        return 1;
    return 0;
}


uint64_t read_pulseid(){
    uint64_t last_value, new_value;
    last_value = 0;
    new_value = 1;
    while (last_value != new_value){
        last_value = new_value;
        new_value = (((uint64_t)PULSEID_READ_2) << 32) | (uint64_t)PULSEID_READ_1;
    }
    return new_value;    
}

// Custom strtoi() implementation
// (kind of...) It does not suport hex and does not correctly block blanks.
int strtoint(char *str, char** end, int mode)
{
    int length;
    if (end != NULL)
        length = *end - str;
    else
        length=30;
        
	int val = 0;
	//for (int i = 0; *str != '\0'; *str++)
    for (int i = 0; (i < length) & ( str[i] != '\0') & ( str[i] != '\n'); i++)
	{
		val = val * 10 + *(str + i) - '0';
	}
	return val;
}

/**
 * Interpret the commands
 */
void interpret(char* line){
    char* start;
    char* end;
    
    // delay settings:
    int board;
    int channel;
    int status;
    int delay;
    int length;
    int div;
    int mod;
    
    uint32_t id_lower;
    uint32_t id_upper;
    
    uint64_t pulseid;
    
    char inhibit;
    
    
    switch (line[0]){
        
        // query the device
        case 'q':
            printf("Time Distribution Transmitter\n");
        break;
        
        // set the delay: D <board> <channel> <status (1/0)> <delay> <length> <div> <mod>
        // The delay and length are in clock cycles. In case of the receiver boards: 80 MHz
        case 'D':
            start = &line[2];
            end = strchr(start, ' ');
            board = strtoint(start, &end, 0);
            
            start = end + 1;
            end = strchr(start, ' ');
            channel = strtoint(start, &end, 0);
            
            start = end + 1;
            end = strchr(start, ' ');
            status = strtoint(start, &end, 0);
            
            start = end + 1;
            end = strchr(start, ' ');
            delay = strtoint(start, &end, 0);
            
            start = end + 1;
            end = strchr(start, ' ');
            length = strtoint(start, &end, 0);
            
            start = end + 1;
            end = strchr(start, ' ');
            div = strtoint(start, &end, 0);
            
            start = end + 1;
            mod = strtoint(start, NULL, 0);
            
            printf("board: %d, channel: %d, status: %d delay: %d, length: %d, div: %d, mod: %d\n", board, channel, status, delay, length, div, mod);
            set_delay(board, channel, delay, length, (status == 1), div, mod);
        break;
        
        // read the pulse-id:
        // returns: upper, lower 32 bits as hex
        case 'i':
            
            pulseid = read_pulseid();
            id_upper = (uint32_t)(pulseid >> 32);
            id_lower = (uint32_t)(pulseid & 0x00000000ffffffff);
            printf("0x%08x 0x%08x\n", id_upper, id_lower);
        break;
        
        // set the pulse id (I <upper> <lower>)
        case 'I':
            start = &line[2];
            end = strchr(start, ' ');
            id_upper = strtoint(start, &end, 0);
            
            start = end + 1;
            end = strchr(start, ' ');
            id_lower = strtoint(start, NULL, 0);
            
            set_pulse_id(id_upper, id_lower);
            printf("Pulse ID: upper: %08x, lower: %08x\n", id_upper, id_lower);
        break;
        
        // read the status register:
        //  bit 0: SPI (don't care)
        //  bit 1: PLLs locked
        //  bit 2: 80 MHz present
        //  bit 3: 100 Hz present
        case 's':
            printf("0x%08x\n", STATUS_REG);
        break;
        
        case 'f':
            printf("%d\n", FREQUENCY_REG);
        break;
        
        // read the trigger inhibit flag
        //  if 1: trigger is inhibited
        //  if 0: trigger is active (default state)
        case 't':
            printf("%d\n", get_inhibit());
        break;
        
        // set the trigger inhibit flag:
        //  if 1: trigger is inhibited
        //  if 0: trigger is active (default state)
        case 'T':
            start = &line[2];
            inhibit = strtoint(start, NULL, 0);
            set_inhibit(inhibit);
            printf("Inhibit set to %d\n", get_inhibit());
        break;
        
    }
}



int main (void)
{
    // make sure the pulse-id is not altered
    PULSEID_CONTROL_REG = 0x0;
    
    int i;
    
    // reset the AD9543:
    CONTROL_REG = (0x01 << 3) | (0x01 << 1);
    for (i = 0; i < 100000; i++);
    CONTROL_REG = (0x01 << 1);
    
    // wait a bit
    for (i = 0; i < 100000; i++);
    
    // set SDO line active
    write_register(0x0000, (0x01<<3) | (0x01<<4));
    io_update();
    
    // configure the AD9543
    for (int k = 0; k < ad9543_len; k++){
        write_register(ad9543_addrs[k], ad9543_data[k]);
    }
    io_update();
    
    // calibrate the PLLs
    sysclk_calib();
    pll_calib(0);
    pll_calib(1);
    
    // wait a bit before we trust the clocks (important!!)
    for (int i = 0; i < 1000000; i++);
    
    // the loop for the command line interface:
    for (;;){
        read_line(line, 255);
        interpret(line);
    }
}
