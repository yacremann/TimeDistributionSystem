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

#include "gpio.h"
#include "init.h"
#include "io.h"

void gpio_set_direction(Gpio_Reg *reg, uint32_t direction) {
  reg->OUTPUT_ENABLE = direction;
}

uint32_t gpio_read_direction(Gpio_Reg *reg) {
  return reg->OUTPUT_ENABLE;
}

void gpio_write(Gpio_Reg *reg, uint32_t value) {
  reg->OUTPUT = value;
}

uint32_t gpio_read(Gpio_Reg *reg) {
  return reg->INPUT;
}

void gpio_write_bit(Gpio_Reg *reg, uint8_t bit, bool value) {
  uint32_t val = gpio_read(reg) | ((uint32_t)value << bit);
  gpio_write(reg, val);
}

bool gpio_read_bit(Gpio_Reg *reg, uint8_t bit) {
  return (gpio_read(reg) >> bit) & 0x1;
}

void enable_external_interrupt(void (*callback)) {
  setCallbackForExternal(callback);
}

void disable_external_interrupt(void) {
  setCallbackForExternal(0);
}
