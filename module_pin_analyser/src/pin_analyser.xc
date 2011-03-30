// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>
#include <print.h>
#include <stdio.h>
#include "pin_analyser.h"
#include "sortme.h"

clock k = XS1_CLKBLK_1;

struct  pinDescriptors ports[NPINS] = {
    { XS1_PORT_1A, 1, "PORT_1A", 0, {0}, {UNKNOWN} },
    { XS1_PORT_1B, 1, "PORT_1B", 1, {0}, {UNKNOWN} },
    { XS1_PORT_8A, 8, "PORT_8A", 2, {0}, {UNKNOWN} },
    { XS1_PORT_1C, 1, "PORT_1C", 10, {0}, {UNKNOWN} },
    { XS1_PORT_1D, 1, "PORT_1D", 11, {0}, {UNKNOWN} },
    { XS1_PORT_1E, 1, "PORT_1E", 12, {0}, {UNKNOWN} },
    { XS1_PORT_1F, 1, "PORT_1F", 13, {0}, {UNKNOWN} },
    { XS1_PORT_8B, 8, "PORT_8B", 14, {0}, {UNKNOWN} },
    { XS1_PORT_1G, 1, "PORT_1G", 22, {0}, {UNKNOWN} },
    { XS1_PORT_1H, 1, "PORT_1H", 23, {0}, {UNKNOWN} },
    { XS1_PORT_1I, 1, "PORT_1I", 24, {0}, {UNKNOWN} },
    { XS1_PORT_1J, 1, "PORT_1J", 25, {0}, {UNKNOWN} },
    { XS1_PORT_8C, 8, "PORT_8C", 26, {0}, {UNKNOWN} },
    { XS1_PORT_1K, 1, "PORT_1K", 34, {0}, {UNKNOWN} },
    { XS1_PORT_1L, 1, "PORT_1L", 35, {0}, {UNKNOWN} },
    { XS1_PORT_8D, 8, "PORT_8D", 36, {0}, {UNKNOWN} },
    { XS1_PORT_32A, 20, "PORT_32A", 49, {0}, {UNKNOWN} },
};

#define N 800

void setupNbit(port cap, clock k) {
  stop_clock(k);
  set_clock_div(k, 0);
  configure_in_port(cap, k);
  start_clock(k);
}

void measureNbit(port cap, unsigned int times[], int pullDown, int activateResistor, int width) {
    int values;
    int curCaps, notSeen, newCaps, newBits;
    int t0, t1;
    // int t2;
    int mask = (1<<width) - 1;

    notSeen = mask;                                // Caps that are not yet Low
    curCaps = pullDown ? mask : 0;                 // Caps that are High
    
    for(int curTime = 0; curTime < N && notSeen != 0; curTime++) {
        set_port_drive(cap);
//        asm("setc res[%0], 8" :: "r"(cap));            // reset port - for flipping around
        cap <: pullDown ? ~0 : 0 @ t0;
        t0 += 200;                                      // Charge for 200 clock ticks.
        t1 = t0 + curTime + 10;
        cap @ t0 <: pullDown ? ~0 : 0;
        cap :> void;
//        asm("setc res[%0], 8" :: "r"(cap));            // reset port

        if (activateResistor)  asm("setc res[%0], 0x13" :: "r"(cap));    else set_port_pull_none(cap);
    //    cap :> void @ t2;
        cap @ t1 :> values;
        newCaps = values & mask;       // Extract measurement
        newBits = (curCaps^newCaps)&notSeen;   // Changed caps
  //      printf("%d %08x -> %08x %d %d %d\n", curTime, pullDown ? mask : 0, values, t0, t1, t2);
        if (newBits != 0) {
            for(int j = 0; j < width; j ++) {
                if(((newBits >> j) & 1) != 0) {
                    times[j] = curTime;      // Record time for
                }                          // each changed cap
            }
            notSeen &= ~ newBits;        // And remember that
        }                               // this cap is low
        curCaps = newCaps;
    }
}

void measureAverage(port cap, unsigned int avg[20], int pullDown, int activate, int w) {
    for(int k = 0; k < w; k++) {
        avg[k] = 0;
    }
    for(int i = 0; i < 16; i++) {
        unsigned int t[20];
        for(int k = 0; k < w; k++) {
            t[k] = 0x0000ffff;
        }
        measureNbit(cap, t, pullDown, activate, w);
        for(int k = 0; k < w; k++) {
            avg[k] += t[k];
        }
    }
}

void measureAll(int pullDown, int activate) {
    for(int i = 0; i < NPINS; i++) {
        unsigned int times[20];
        setupNbit(ports[i].p, k);
        measureAverage(ports[i].p, times, pullDown, activate, ports[i].width);
        for(int j = 0; j < ports[i].width; j++) {
            ports[i].timing[j] = times[j];
        }
    }
}

void analysePins(void) {
    unsigned int median;
//    unsigned int times[20];
  //  setupNbit(ports[16].p, k);
  //  measureAverage(ports[16].p, times, 0, 0, ports[16].width);
    unsigned int floats[64];
    int fltCnt = 0;

    measureAll(0, 0);
    for(int i = 0; i < NPINS; i++) {
        for(int j = 0; j < ports[i].width; j++) {
            if (ports[i].state[j] == UNKNOWN && ports[i].timing[j] < 0xffff) {
                ports[i].state[j] = PULLEDHIGH;
            }
        }
    }
    measureAll(1, 0);
    for(int i = 0; i < NPINS; i++) {
        for(int j = 0; j < ports[i].width; j++) {
            if (ports[i].state[j] == UNKNOWN && ports[i].timing[j] < 0xffff) {
                ports[i].state[j] = PULLEDLOW;
            }
        }
    }
    measureAll(1, 1);
    for(int i = 0; i < NPINS; i++) {
        for(int j = 0; j < ports[i].width; j++) {
            if (ports[i].state[j] == UNKNOWN) {
                if (ports[i].pin + j != 43) {
                    ports[i].state[j] = FLOATER;
                    floats[fltCnt++] = ports[i].timing[j];
                }
            }
        }
    }
    sortme(floats, fltCnt);
    median = floats[fltCnt>>1];
    if (fltCnt > 0 && median > 0) {
        for(int i = 0; i < NPINS; i++) {
            for(int j = 0; j < ports[i].width; j++) {
                if (ports[i].state[j] == FLOATER) {
                    ports[i].timing[j] = (ports[i].timing[j] * 100) / median;
                }
            }
        }
    }
}
