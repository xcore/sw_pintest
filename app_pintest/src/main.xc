// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <stdio.h>
#include "pin_analyser.h"

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

int readAllBoards(void) {
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

int main() {
    int boards = 0;
    if (openfile()) {
        boards = readAllBoards();
        closefile();
    }
    if (boards != 0) {
        int issues = 0;
        printf("Analysing board and comparing against %d known good boards\n", boards);
        analysePins();
        for(int i = 0; i < NPINS; i++) {
            for(int j = 0; j < ports[i].width; j++) {
                int expectedTiming = ports[i].averages[j].x/ports[i].averages[j].n;
                int expectedDeviation = ports[i].averages[j].x2-sqr(ports[i].averages[j].x)/ports[i].averages[j].n;
                int portBad = 0;
                if (ports[i].state[j] != ports[i].expectedState[j]) {
                    portBad = 1;
                } else if (ports[i].state[j] == FLOATER &&
                           abs(ports[i].timing[j] - expectedTiming) > expectedDeviation) {
                    portBad = 1;
                }
                if (portBad) {
                    issues++;
                    printf("Issue: %s%d X0D%d",ports[i].name, j, ports[i].pin + j + (ports[i].width == 20 && j >= 10 ? 2 : 0));
                    switch(ports[i].state[j]) {
                    case PULLEDHIGH: printf(": PULLED HIGH\n"); break;
                    case PULLEDLOW:  printf(": PULLED LOW\n"); break;
                    case FLOATER:    printf(": FLOATER %d, expected capacitance %d +/- %d\n",ports[i].timing[j], expectedTiming, expectedDeviation); break;
                    case UNKNOWN:    printf(": ?\n"); break;
                    }
                }
            }
        }
        if (issues == 0) {
            printf("Board appears to be in line with other boards\n");
        } else {
            printf("%d differences reported.\n", issues);
        }
    } else {
        printf("Analysing board, no comparison data available...\n");
        analysePins();
        for(int i = 0; i < NPINS; i++) {
            for(int j = 0; j < ports[i].width; j++) {
                printf("%s%d X0D%d",ports[i].name, j, ports[i].pin + j + (ports[i].width == 20 && j >= 10 ? 2 : 0));
                switch(ports[i].state[j]) {
                case PULLEDHIGH: printf(": PULLED HIGH\n"); break;
                case PULLEDLOW:  printf(": PULLED LOW\n"); break;
                case FLOATER:    printf(": FLOATER (%d %%)\n",ports[i].timing[j]); break;
                case UNKNOWN:    printf(": ?\n"); break;
                }
            }
        }
    }

    return 0;
}
