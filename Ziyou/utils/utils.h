//
//  utils.h
//  Slice
//
//  Created by Brandon Plank on 5/8/19.
//  Copyright © 2019 Slice Team. All rights reserved.
//


#ifndef utils_h
#define utils_h

#define showMSG(msg, wait, destructive) showAlert(@"Ziyou", msg, wait, destructive)
#define showPopup(msg, wait, destructive) showThePopup(@"", msg, wait, destructive)
#define __FILENAME__ (__builtin_strrchr(__FILE__, '/') ? __builtin_strrchr(__FILE__, '/') + 1 : __FILE__)
#define _assert(test, message, fatal) do \
if (!(test)) { \
int saved_errno = errno; \
LOG("__assert(%d:%s)@%s:%u[%s]", saved_errno, #test, __FILENAME__, __LINE__, __FUNCTION__); \
} \
while (false)

void runMachswap(void);
void getOffsets(void);
void rootMe(uint64_t proc);
void unsandbox(uint64_t proc);
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
void initInstall(int packagerType);
bool canRead(const char *file);
struct tfp0;

//SETTINGS
BOOL shouldLoadTweaks(void);
int getExploitType(void);
int getPackagerType(void);
void initSettingsIfNotExist(void);
void saveCustomSetting(NSString *setting, int settingResult);
BOOL shouldRestoreFS(void);
BOOL isRootless(void);


//ROOTLESS JB
void createWorkingDir_rootless(void);
void saveOffs_rootless(void);
void uninstallRJB(void);

//EXPLOIT
int autoSelectExploit(void);

//Nonce
void setNonce(const char *nonce, bool shouldSet);
NSString* getBootNonce(void);
bool shouldSetNonce(void);

#endif /* utils_h */
