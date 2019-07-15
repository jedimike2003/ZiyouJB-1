//
//  runSockPuppet.c
//  Ziyou
//
//  Created by Tanay Findley on 7/11/19.
//  Copyright © 2019 Ziyou Team. All rights reserved.
//

extern "C" {
#include "iosurface.h"
#include "kernel_memory.h"
#include "runSockPuppet.h"
#include "parameters.h"
}

#include "exploit.h"

void runSockPuppet()
{
    IOSurface_init();
    
    parameters_init();
    
    Exploit exploit;
    exploit.GetKernelTaskPort();
    IOSurface_deinit();
}
