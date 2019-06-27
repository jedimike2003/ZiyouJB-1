//
//  VarHolder.c
//  tw3lve
//
//  Created by Tanay Findley on 4/7/19.
//  Copyright © 2019 Tanay Findley. All rights reserved.
//
#include <mach/port.h>

mach_port_t tfp0 = MACH_PORT_NULL;
uint64_t kbase;
uint64_t ktask;
uint A12 = 0;


void setA12(uint a12)
{
    A12 = a12;
}
