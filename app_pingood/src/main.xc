// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <stdio.h>
#include "pin_analyser.h"

int main() {
    printf("Analysing pins\n");
    analysePins();
    appendfile();
    for(int i = 0; i < NPINS; i++) {
        for(int j = 0; j < ports[i].width; j++) {
            outputfile(ports[i].state[j]);
            outputfile(ports[i].timing[j]);
        }
    }
    outputfileln();
    closefile();
    printf("Done... Following results added as \"good\"\n");
    for(int i = 0; i < NPINS; i++) {
        for(int j = 0; j < ports[i].width; j++) {
            
            printf("%s%d X0D%d",ports[i].name, j, ports[i].pin + j + (ports[i].width == 20 && j >= 10 ? 2 : 0));
            switch(ports[i].state[j]) {
            case PULLEDHIGH: printf(": PULLED HIGH\n"); break;
            case PULLEDLOW:  printf(": PULLED LOW\n"); break;
            case FLOATER:    printf(": FLOATER %d\n", ports[i].timing[j] ); break;
            case UNKNOWN:    printf(": ?\n"); break;
            }
        }
    }
    return 0;
}
