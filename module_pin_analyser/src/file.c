// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <stdio.h>

FILE *fd = NULL;

int openfile(void) {
    fd = fopen("measurements.txt", "r");
    return fd != NULL;
}

int inputfile(void) {
    int i;
    int k = fscanf(fd, " %d", &i);
    if (k != 1) {
        return -1;
    }
    return i;
}

void outputfile(int i) {
    fprintf(fd, " %d", i);
}

void outputfileln(void) {
    fprintf(fd, "\n");
}

void closefile(void) {
    if (fd != NULL) fclose(fd);
}

int appendfile(void) {
    fd = fopen("measurements.txt", "a");
    return fd != NULL;
}
