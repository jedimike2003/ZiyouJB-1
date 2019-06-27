//
//  utils.h
//  Slice
//
//  Created by Brandon Plank on 5/8/19.
//  Copyright © 2019 Slice Team. All rights reserved.
//


#ifndef utils_h
#define utils_h

#define showMSG(msg, wait, destructive) showAlert(@"Slice", msg, wait, destructive)
#define __FILENAME__ (__builtin_strrchr(__FILE__, '/') ? __builtin_strrchr(__FILE__, '/') + 1 : __FILE__)
#define _assert(test, message, fatal) do \
if (!(test)) { \
int saved_errno = errno; \
LOG("__assert(%d:%s)@%s:%u[%s]", saved_errno, #test, __FILENAME__, __LINE__, __FUNCTION__); \
} \
while (false)

void runMachswap(void);
void getOffsets(void);
void rootMe(int both, uint64_t proc);
void unsandbox(uint64_t proc);
uint64_t selfproc(void);
void remountFS(bool shouldRestore);
void restoreRootFS(void);
int trust_file(NSString *path);
void installSubstitute(void);
void saveOffs(void);
void createWorkingDir(void);
void installSSH(void);
void xpcFucker(void);
void finish(bool shouldLoadTweaks);
void runVoucherSwap(void);
void runExploit(int expType);
void initInstall(void);
bool canRead(const char *file);
struct tfp0;

#endif /* utils_h */
