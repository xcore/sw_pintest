// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <stdio.h>

FILE *fd = NULL;

int openfile(int coreId) {
    char filename[23];
    sprintf((char *)&filename, "measurements_core%d.txt", coreId);
    printf("Opening \"%s\"\n", filename);
    fd = fopen( filename, "r");
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

int appendfile(int coreId) {
    char filename[23];
    sprintf((char *)&filename, "measurements_core%d.txt", coreId);
    printf("Appending to \"%s\"\n", filename);
    fd = fopen(filename, "a");
    return fd != NULL;
}
