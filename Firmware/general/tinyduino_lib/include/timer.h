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

#ifndef TIMER_H_
#define TIMER_H_

#include <stdint.h>

typedef enum {TIMER_A, TIMER_B, TIMER_C, TIMER_D} tinyduino_timers;

typedef struct
{
  volatile uint32_t CLEARS_TICKS;
  volatile uint32_t LIMIT;
  volatile uint32_t VALUE;
} Timer_Reg;

typedef struct
{
  volatile uint32_t PENDINGS;
  volatile uint32_t MASKS;
} TimerInterruptCtrl_Reg;

extern void init_timer(Timer_Reg *reg);
extern void init_interruptCtrl(void);
extern void init_all_timers(void);
extern uint32_t status_timer(tinyduino_timers timer);
extern void start_timer(tinyduino_timers timer, uint32_t limit, void (*callback));
extern void clear_timer(tinyduino_timers timer);
extern tinyduino_timers timer_interrupt_cause(void);

#endif /* TIMERCTRL_H_ */
