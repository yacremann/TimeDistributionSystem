#include <stdint.h>
#include <stdbool.h>


#include "uart.h"
#include "printf.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>

//#include "spi.h"
#include "io.h"

#include "ad9544_regs.h"



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

// SPI von Hand
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
    //int cal_count = 0;
    int counter = 0;
    write_bit(0x2000, 2, 0);
    io_update();
    write_bit(0x2000, 2, 1);
    io_update();
    for (int i = 0; i < 100; i++);
    uint8_t result = read_register(0x3001);
    printf("sysclk result: %d\n", result);
    while ((counter < 10000) && ((result & 0x03) < 3)){
        //for (int i = 0; i < 100; i++);
        result = read_register(0x3001);
        counter++;
    }
    printf("sysclk: %d\n", counter);
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
    
    printf("Lock PLL reg: %d: %d\n", pll_nr, result);
    while ((counter < 10000) && ((result & 0x08) == 0)){
        result = read_register(lock_reg);
        counter++;
    }
    printf("Lock PLL %d: %d\n", pll_nr, counter);
    
    write_bit(sync_reg, 3, 1);
    io_update();
    write_bit(sync_reg, 3, 0);
    io_update();
}

int main (void)
{
    //init();
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
    
    
    
    
    
    printf("Receiver config\n");
    
    // configure the AD9543
    for (int k = 0; k < ad9543_len; k++){
        write_register(ad9543_addrs[k], ad9543_data[k]);
    }
    for (int i = 0; i < 100000; i++);
    io_update();
    // read back the values
    int regNr = 0;
    for (regNr = 0; regNr < ad9543_len; regNr++)
        printf("reg addr: %04x soll: %d ist: %d\n", ad9543_addrs[regNr], ad9543_data[regNr], read_register(ad9543_addrs[regNr]));
    
    //for (int i = 0; i < 100000; i++);
    sysclk_calib();
    //for (int i = 0; i < 100000; i++);
    pll_calib(0);
    //for (int i = 0; i < 100000; i++);
    pll_calib(1);
    for (int i = 0; i < 1000000; i++);
    
    
    
    
    
    printf("done\n");
    for (;;);    
   
    
    /*
    for (;;){
        for (int i = 0; i < 100000; i++);
        printf("refA   : status  %02x\n", read_register(0x3005));
        printf("general: status  %02x\n", read_register(0x3002));
        printf("PLL0   : profile %02x\n", read_register(0x3009));
    }
    */
    
}
