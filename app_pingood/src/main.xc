// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <stdio.h>
#include "pin_analyser.h"
#include <platform.h>
#include <xs1.h>

#define ANALYSE_L2  1

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

int runtest( int coreId, pinDescriptors ports[], clock k, chanend c, int start, int end )
{
    int i,j;
    
    if (!start)
        c :> int _;
    
    printf("Analysing pins for core %d\n", coreId);
    analysePins(ports, k);
    appendfile(coreId);
    for(i = 0; i < NPINS; i++) {
        for(j = 0; j < ports[i].width; j++) {
            outputfile(ports[i].state[j]);
            outputfile(ports[i].timing[j]);
        }
    }
    outputfileln();
    closefile();
    printf("Done... Following results added as \"good\"\n");
    for(int i = 0; i < NPINS; i++) {
        for(int j = 0; j < ports[i].width; j++) {
            
            printf("%s%d X%dD%d",ports[i].name, j, coreId, ports[i].pin + j + (ports[i].width == 20 && j >= 10 ? 2 : 0));
            switch(ports[i].state[j]) {
            case PULLEDHIGH: printf(": PULLED HIGH\n"); break;
            case PULLEDLOW:  printf(": PULLED LOW\n"); break;
            case FLOATER:    printf(": FLOATER %d\n", ports[i].timing[j] ); break;
            case UNKNOWN:    printf(": ?\n"); break;
            }
        }
    }
    
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
