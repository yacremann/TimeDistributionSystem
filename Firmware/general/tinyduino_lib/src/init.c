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

#include "tinyDuino.h"
#include "init.h"

void *timerCallback[4];
void *uartCallback;
void *externalCallback;


void init_tiny() {
    uart_init();
    init_all_timers();
    uartCallback = 0;
    externalCallback = 0;
}

void interruptCallback() {
    int32_t mcause = csr_read(mcause);
    int32_t interrupt = mcause < 0;
    int32_t cause     = mcause & 0xF;
    if(interrupt){
        switch(cause){
        case CAUSE_MACHINE_TIMER: timerInterrupt(); break;
        case CAUSE_MACHINE_EXTERNAL: externalInterrupt(); break;
        default: crash(); break;
        }
    } else {
        crash();
    }
}

void setCallbackForTimer(tinyduino_timers timer, void (*callback)) {
    timerCallback[timer] = callback;
}

void setCallbackForUART(void (*callback)) {
    uartCallback = callback;
}

void setCallbackForExternal(void (*callback)) {
    externalCallback = callback;
}

void timerInterrupt() {
    tinyduino_timers interrupt_cause = timer_interrupt_cause();
    switch(interrupt_cause) {
        case TIMER_A:
        case TIMER_B:
        case TIMER_C:
        case TIMER_D:
            clear_timer(interrupt_cause);
            break;
        default:
            crash();
            return;
    }

    if (timerCallback[interrupt_cause] != 0) {
      void (*f)(void) = (void (*)(void)) timerCallback[interrupt_cause];
      f();
    } else {
        crash();
    }
}

void externalInterrupt() {
    if (uart_interrupt()) {
        if (uartCallback != 0) {
            void (*f)(void) = (void (*)(void)) uartCallback;
            f();
        }
    } else if (externalCallback != 0) {
      void (*f)(void) = (void (*)(void)) externalCallback;
      f();
    }
}

void crash() {
    while(1);
}
