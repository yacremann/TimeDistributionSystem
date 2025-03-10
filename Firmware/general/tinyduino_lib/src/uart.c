/*

MIT License

Copyright (c) 2021 Domenic Wüthrich, Manuel Eggimann, Yves Acremann (ETH Zurich)
Modified 2024 Yves Acremann



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

#include "uart.h"
#include "init.h"
#include "io.h"
#include <stdlib.h>

void uart_send(uint32_t c) {
  volatile char dummyReg;
  while (1) {
    if (((UART->STATUS >> 16) & 0xFF) != 0) {
      break;
    }
  }
  UART->DATA = c;
}

int uart_available(void) {
  return (UART->STATUS >> 24);
}

/*
 * Modified 2024 Yves Acremann
 */
uint32_t uart_recv(void) {
  asm volatile ("" : : : "memory");
  while (1) {
    if (uart_available() > 0) {
      break;
    }
  }
  
  uint32_t data = UART->DATA;
  return data & 0xff;
  
  
  /*
  uint32_t data;
  while(1){
      data = UART->DATA;
      if ((data >> 8) != 0)
        break;
    }
    return (data & 0xff);
    */
  
  /*  
  while (uart_available() == 0) ;
  uint32_t data = UART->DATA;
  return (data & 0xFF); */
}

void uart_init(void) {
  UART->CLOCK_DIVIDER = CORE_HZ/8/BAUD_RATE-1;
	UART->FRAME_CONFIG = ((8-1) << 0) | (0 << 8) | (1 << 16);
}

int uart_interrupt(void) {
  return UART->STATUS & (1 << 9);
}

void enable_uart_interrupt(void (*callback)) {
  setCallbackForUART(callback);
  UART->STATUS = 2;
}

void disable_uart_interrupt(void) {
  setCallbackForUART(0);
  UART->STATUS = 0;
}

char read_char(void) {
  return uart_recv();
}

void read_line(char* buffer, uint16_t maximum) {
  //char* str = malloc(maximum);
  char* p = buffer;
  char next;
  do {
    next = read_char();
    *p++ = next;
  } while (next != 0 && next != '\n' && (p-buffer) < maximum);
  *p = 0;
}
