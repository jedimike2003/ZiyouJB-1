//
//  ImportantHolders.h
//  Slice
//
//  Created by Tanay Findley on 5/8/19.
//  Copyright © 2019 Slice Team. All rights reserved.
//

#ifndef ImportantHolders_h
#define ImportantHolders_h

#include <stdio.h>

extern uint A12;
extern mach_port_t tfp0;
extern uint64_t kbase;
extern uint isA12;
extern uint64_t ktask;

void setA12(uint a12);

void set_tfp0(mach_port_t tfp0wo);

#endif /* ImportantHolders_h */
