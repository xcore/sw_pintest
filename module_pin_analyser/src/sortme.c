// Copyright (c) 2011, XMOS Ltd, All rights reserved
// This software is freely distributable under a derivative of the
// University of Illinois/NCSA Open Source License posted in
// LICENSE.txt and at <http://github.xcore.com/>

#include <stdlib.h>

__attribute__((fptrgroup("stdlib_qsort"))) // <-- Fails at runtime without this line
static int compar(const void *a, const void *b) {
    return *(unsigned int*)a - *(unsigned int*)b;
}

void sortme(unsigned int a[], int n) {
    qsort(a, n, sizeof(int), compar);
}
