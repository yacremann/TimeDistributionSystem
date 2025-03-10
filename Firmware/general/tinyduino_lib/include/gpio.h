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

#ifndef GPIO_H_
#define GPIO_H_

#include <stdint.h>
#include <stdbool.h>

typedef struct
{
  volatile uint32_t INPUT;
  volatile uint32_t OUTPUT;
  volatile uint32_t OUTPUT_ENABLE;
} Gpio_Reg;

extern void gpio_set_direction(Gpio_Reg *reg, uint32_t direction);
extern uint32_t gpio_read_direction(Gpio_Reg *reg);
extern void gpio_write(Gpio_Reg *reg, uint32_t value);
extern uint32_t gpio_read(Gpio_Reg *reg);
extern void gpio_write_bit(Gpio_Reg *reg, uint8_t bit, bool value);
extern bool gpio_read_bit(Gpio_Reg *reg, uint8_t bit);
extern void enable_external_interrupt(void (*callback));
extern void disable_external_interrupt(void);

#endif /* GPIO_H_ */
