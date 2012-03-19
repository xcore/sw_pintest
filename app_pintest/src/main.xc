// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <stdio.h>
#include "pin_analyser.h"
#include <platform.h>
#include <xs1.h>

/* this is defined by the build target in the Makefile */
//#define ANALYSE_L2  1

/* use this define to preset an allowable deviation */
#define ALLOWABLE_DEVIATION 20

/* declaire ports and set initial state */
on stdcore[0]: clock k0 = XS1_CLKBLK_1;
on stdcore[0]: pinDescriptors core0ports[NPINS] = {
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

#if ANALYSE_L2 == 1
on stdcore[1]: clock k1 = XS1_CLKBLK_1;
on stdcore[1]: pinDescriptors core1ports[NPINS] = {
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

#endif

static int abs(int x) {
    return x < 0 ? -x : x;
}

static int sqr(int x) {
    return x*x;
}

void incorporate(struct average &a, int x) {
    a.x += x;
    a.n++;
    a.x2 += x*x;
}

int readAllBoards( pinDescriptors ports[] ) {
    int boards = 0;
    while(1) {
        for(int i = 0; i < NPINS; i++) {
            for(int j = 0; j < ports[i].width; j++) {
                int x = inputfile();
                if (x == -1) {
                    return boards;
                }
                ports[i].expectedState[j] = x;
                x = inputfile();
                incorporate(ports[i].averages[j], x);
            }
        }
        boards++;
    }
    return boards;
}

int runtest( int coreId, pinDescriptors ports[], clock k, chanend c, int start, int end )
{
    int boards = 0;
    
    if (!start)
        c :> int _;
    
    if (openfile(coreId)) {
        boards = readAllBoards( ports );
        closefile();
    }
    
    printf("Analysing core %d\n", coreId);
    #ifdef ALLOWABLE_DEVIATION
    printf("Using a defined deviation of +/- %d\n", ALLOWABLE_DEVIATION);
    #endif
    
    if (boards != 0) {
        int issues = 0;
        printf("Analysing board and comparing against %d known good boards\n", boards);
        analysePins( ports, k );
        for(int i = 0; i < NPINS; i++) {
            for(int j = 0; j < ports[i].width; j++) {
                int expectedTiming = ports[i].averages[j].x/ports[i].averages[j].n;
                #ifdef ALLOWABLE_DEVIATION
                int expectedDeviation = ALLOWABLE_DEVIATION;
                #else
                int expectedDeviation = ports[i].averages[j].x2-sqr(ports[i].averages[j].x)/ports[i].averages[j].n;
                #endif
                int portBad = 0;
                int error = ports[i].timing[j] - expectedTiming;
                if (ports[i].state[j] != ports[i].expectedState[j]) {
                    portBad = 1;
                } else if (ports[i].state[j] == FLOATER &&
                           abs(error) > expectedDeviation) {
                    portBad = 1;
                }
                if (portBad) {
                    issues++;
                    printf("Issue: %s%d X%dD%d",ports[i].name, j, coreId, ports[i].pin + j + (ports[i].width == 20 && j >= 10 ? 2 : 0));
                    switch(ports[i].state[j]) {
                    case PULLEDHIGH: printf(": PULLED HIGH\n"); break;
                    case PULLEDLOW:  printf(": PULLED LOW\n"); break;
                    case FLOATER:    printf(": FLOATER %d, expected capacitance %d +/- %d, measured error %d\n",ports[i].timing[j], expectedTiming, expectedDeviation, error); break;
                    case UNKNOWN:    printf(": ?\n"); break;
                    }
                }
            }
        }
        if (issues == 0) {
            printf("\nBoard appears to be in line with other boards\n");
        } else {
            printf("\n%d differences reported.\n", issues);
        }
    } else {
        printf("Analysing board, no comparison data available...\n");
        analysePins( ports, k );
        for(int i = 0; i < NPINS; i++) {
            for(int j = 0; j < ports[i].width; j++) {
                printf("%s%d X%dD%d",ports[i].name, j, coreId, ports[i].pin + j + (ports[i].width == 20 && j >= 10 ? 2 : 0));
                switch(ports[i].state[j]) {
                case PULLEDHIGH: printf(": PULLED HIGH\n"); break;
                case PULLEDLOW:  printf(": PULLED LOW\n"); break;
                case FLOATER:    printf(": FLOATER (%d %%)\n",ports[i].timing[j]); break;
                case UNKNOWN:    printf(": ?\n"); break;
                }
            }
        }
    }
    
    printf("Core %d analysis COMPLETE\n\n",coreId);

    if (!end)
        c <: 1;
    return 0;
    
}

int main() {
    
    chan c0;
    
    par
    {
        #if ANALYSE_L2 == 1
        on stdcore[0]: runtest(0, core0ports, k0, c0, 1, 0);
        on stdcore[1]: runtest(1, core1ports, k1, c0, 0, 1);
        #else // an L1
        on stdcore[0]: runtest(0, core0ports, k0, c0, 1, 1);
        #endif
    }
    
    return 0;
}
