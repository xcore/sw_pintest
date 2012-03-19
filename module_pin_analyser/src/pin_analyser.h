// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <xs1.h>

#define NPINS 17

enum { UNKNOWN=0, PULLEDHIGH=1, PULLEDLOW=2, FLOATER=3 };

struct average {
    unsigned short x;
    unsigned short n;
    unsigned int x2;
};

typedef struct s_pinDescriptors {
    port p;
    int width;
    char name[9];
    int pin;
    unsigned int timing[20];
    unsigned char state[20];
    struct average averages[20];
    unsigned short expectedTiming[20];
    unsigned short deviation[20];
    unsigned char expectedState[20];
} pinDescriptors;

void analysePins( pinDescriptors ports[], clock k );

int openfile(void);
int inputfile(void);
void outputfile(int i);
void outputfileln(void);
void closefile(void);
int appendfile(void);
