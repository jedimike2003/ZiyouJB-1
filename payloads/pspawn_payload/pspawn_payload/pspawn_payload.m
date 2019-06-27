#include <dlfcn.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <spawn.h>
#include <sys/types.h>
#include <errno.h>
#include <stdlib.h>
#include <sys/sysctl.h>
#include <dlfcn.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <pthread.h>
#include <Foundation/Foundation.h>
#include "libproc.h"
#include "proc_info.h"
#include "substitute.h"
#include "jailbreak_daemonUser.h"
#include <mach/host_priv.h>
#include <mach/mach_init.h>
#include <mach/mach_error.h>

enum CurrentProcess {
    PROCESS_LAUNCHD,
    PROCESS_XPCPROXY,
    PROCESS_OTHER
};
int current_process = PROCESS_OTHER;

dispatch_queue_t queue;
FILE *file2LogTo;

kern_return_t bootstrap_look_up(mach_port_t port, const char *service, mach_port_t *server_port);
mach_port_t jbd_port = MACH_PORT_NULL;
dispatch_queue_t queue = NULL;
#define logToFile(fmt, args...)\
do {\
if (file2LogTo == NULL) {\
fprintf(stderr, fmt "\n", ##args); \
file2LogTo = fopen("/var/log/pspawn_payload.log", "a"); \
if (file2LogTo == NULL) break; \
} \
fprintf(file2LogTo, fmt "\n", ##args); \
fflush(file2LogTo); \
} while(0)

#define DYLD_INSERT             "DYLD_INSERT_LIBRARIES="
#define PSPAWN_HOOK_DYLIB "/usr/lib/pspawn_payload.dylib"
#define AMFID_PAYLOAD_DYLIB "/usr/lib/amfid_payload.dylib"
#define SBINJECT_PAYLOAD_DYLIB "/usr/lib/TweakInject.dylib"
#define MAX_INJECT 1

#define JAILBREAKD_COMMAND_ENTITLE                              1
#define JAILBREAKD_COMMAND_ENTITLE_AND_SIGCONT                  2
#define JAILBREAKD_COMMAND_ENTITLE_AND_SIGCONT_FROM_XPCPROXY    3
#define JAILBREAKD_COMMAND_FIXUP_SETUID                         4
#define JAILBREAKD_COMMAND_UNSANDBOX                            5

#define DISABLE_LOADER_FILE     (const char *)("/var/tmp/.pspawn_disable_loader")

#define FLAG_PLATFORMIZE (1 << 1)

/*
const char *xpcproxy_blacklist[] = {
    "cfprefsd",
    "com.apple.diagnosticd",
    "com.apple.ReportCrash",
    "debugserver",
    "diagnosticd",
    "dropbear",
    "FileProvider",
    "jailbreakd",
    "logd",
    "mapspushd",
    "MTLCompilerService",
    "notifyd",
    "OTAPKIAssetTool",
    "securityd"
    "trustd",
    NULL
};
 */
const char *xpcproxy_blacklist[] = {
    "com.apple.diagnosticd",    // syslog
    "com.apple.logd",       // logd - things that log when this is starting end badly so...
    "MTLCompilerService",
    "mapspushd",                // stupid Apple Maps
    "com.apple.notifyd",        // fuck this daemon and everything it stands for
    "OTAPKIAssetTool",
    "FileProvider",             // seems to crash from oosb r/w etc
    "jailbreakd",               // gotta call to this
    "dropbear",
    "cfprefsd",
    "debugserver",
    NULL
};

bool get_jbd_port() {
    if (host_get_special_port(mach_host_self(), HOST_LOCAL_NODE, 15, &jbd_port)) {
        logToFile("[FATAL] ERROR GETTING SPECIAL PORT 15");
        return false;
    }
    
    if (!MACH_PORT_VALID(jbd_port)) {
        logToFile("[FATAL] PORT NOT VALID!! RET: %x", jbd_port);
        return false;
    }
    
    logToFile("[PSPAWN] GOT PORT AT: %x", jbd_port);
    return true;
}

bool is_blacklisted(const char *proc) {
    const char **blacklist = xpcproxy_blacklist;
    
    while (*blacklist) {
        if (strstr(proc, *blacklist)) {
            return true;
        }
        
        blacklist++;
    }
    
    return false;
}

int file_exist(const char *filename) {
    struct stat buffer;
    int r = stat(filename, &buffer);
    return (r == 0);
}

typedef int (*pspawn_t)(pid_t *pid,
                        const char *path,
                        const posix_spawn_file_actions_t *file_actions,
                        posix_spawnattr_t *attrp,
                        const char *argv[],
                        const char *envp[]);

pspawn_t old_pspawn, old_pspawnp;

int fake_posix_spawn_common(pid_t *pid,
                            const char *path,
                            const posix_spawn_file_actions_t *file_actions,
                            posix_spawnattr_t *attrp,
                            const char *argv[],
                            const char *envp[],
                            pspawn_t old) {
    
    int retval = -1, ret = 0, ninject = 0;
    const char *inject[MAX_INJECT] = { NULL };
    
    pid_t child      = 0;
    char **newenvp   = NULL;
    char *insert_str = NULL;
    posix_spawnattr_t attr;
    
    if (!path || !argv || !envp) {
        logToFile("got some bullshit args: %p, %p, %p", path, argv, envp);
        goto out;
    }
    
    if (argv[1]) {
        logToFile("fake_posix_spawn_common: %s (arg1: %s)", path, argv[1]);
    } else {
        logToFile("fake_posix_spawn_common: %s", path);
    }
    
    switch (current_process) {
        case PROCESS_LAUNCHD:
            if (strcmp(path, "/usr/libexec/xpcproxy") == 0 &&
                argv[0] &&
                argv[1] &&
                !is_blacklisted(path) &&
                !is_blacklisted(argv[1])) {
                inject[ninject++] = PSPAWN_HOOK_DYLIB;
            }
            break;
        case PROCESS_XPCPROXY:
            if (strcmp(path, "/usr/libexec/amfid") == 0 && access(AMFID_PAYLOAD_DYLIB, F_OK) == 0) {
                inject[ninject++] = AMFID_PAYLOAD_DYLIB;
                break;
            }
            if (!is_blacklisted(path) && access(SBINJECT_PAYLOAD_DYLIB, F_OK) == 0 && access(DISABLE_LOADER_FILE, F_OK) != 0) {
                inject[ninject++] = SBINJECT_PAYLOAD_DYLIB;
            }
            break;
    }
    
    if (ninject > MAX_INJECT) {
        logToFile("too much inject, yo! (%d)", ninject);
        goto out;
    }
    
    logToFile("Inject count: %d", ninject);
    
    if (ninject > 0) {
        if (!attrp) {
            ret = posix_spawnattr_init(&attr);
            if (ret != 0) {
                logToFile("posix_spawnattr_init: %s", strerror(ret));
                goto out;
            }
            
            attrp = &attr;
        }
        
        short flags;
        ret = posix_spawnattr_getflags(attrp, &flags);
        if (ret != 0) {
            logToFile("posix_spawnattr_getflags: %s", strerror(ret));
            goto out;
        }
        
        ret = posix_spawnattr_setflags(attrp, flags | POSIX_SPAWN_START_SUSPENDED);
        if (ret != 0) {
            logToFile("posix_spawnattr_setflags: %s", strerror(ret));
            goto out;
        }
        
        logToFile("Env:");
        size_t nenv = 0;
        const char *insert = NULL;
        for (const char **ptr = envp; *ptr != NULL; ++ptr, ++nenv) {
            logToFile("\t%s", *ptr);
            if (strncmp(*ptr, DYLD_INSERT, strlen(DYLD_INSERT)) == 0) {
                insert = *ptr;
            }
        }
        
        ++nenv; // NULL
        if (!insert) ++nenv;
        
        newenvp = malloc(nenv * sizeof(*newenvp));
        if (!newenvp) {
            logToFile("malloc newenvp failed");
            goto out;
        }
        
        size_t slen = (insert ? strlen(insert) + 1 : strlen(DYLD_INSERT)) + strlen(inject[0]) + 1;
        for (size_t i = 1; i < ninject; i++) {
            slen += strlen(inject[i]) + 1;
        }
        
        insert_str = malloc(slen);
        if (!insert_str) {
            logToFile("malloc insert_str failed");
            goto out;
        }
        
        insert_str[0] = '\0';
        
        size_t start = 0;
        if (insert) {
            strcat(insert_str, insert);
            start = 0;
        } else {
            strcat(insert_str, DYLD_INSERT);
            strcat(insert_str, inject[0]);
            start = 1;
        }
        
        for (size_t i = start; i < ninject; i++) {
            strcat(insert_str, ":");
            strcat(insert_str, inject[i]);
        }
        
        nenv = 0;
        newenvp[nenv++] = insert_str;
        
        for (const char **ptr = envp; *ptr != NULL; ++ptr) {
            if (*ptr != insert) {
                newenvp[nenv++] = (char *)*ptr;
            }
        }
        newenvp[nenv++] = NULL;
        envp = (const char **)newenvp;
        
        logToFile("New Env:");
        for (const char **ptr = envp; *ptr != NULL; ++ptr) {
            logToFile("\t%s", *ptr);
        }
        
        if (current_process == PROCESS_XPCPROXY) {
            pid_t ourpid = getpid();
            kern_return_t ret = jbd_call(jbd_port, JAILBREAKD_COMMAND_ENTITLE_AND_SIGCONT_FROM_XPCPROXY, ourpid);
            
            if (ret != KERN_SUCCESS) {
                logToFile("jbd_call(xpcproxy, %d): %x (%s)", ourpid, ret, mach_error_string(ret));
            }
        }
    }
    
    // Note: xpcproxy won't return from this call
    ret = old(&child, path, file_actions, attrp, argv, envp);
    if (ret != 0) {
        logToFile("posix_spawn: %s", strerror(ret));
        retval = ret;
        goto out;
    }
    logToFile("Spawned with pid: %d", child);
    
    if (pid) {
        *pid = child;
    }
    
    dispatch_async(queue, ^{
        kern_return_t ret = jbd_call(jbd_port, JAILBREAKD_COMMAND_ENTITLE_AND_SIGCONT, child);
        if (current_process == PROCESS_LAUNCHD && ret == MACH_SEND_INVALID_DEST && get_jbd_port())
            ret = jbd_call(jbd_port, JAILBREAKD_COMMAND_ENTITLE_AND_SIGCONT, child);
        
        if (ret != KERN_SUCCESS) {
            logToFile("jbd_call(launchd, %d): %x (%s)", child, ret, mach_error_string(ret));
        }
    });
    
    retval = 0;
    
    out:;
    if (newenvp    != NULL)  free(newenvp);
    if (insert_str != NULL)  free(insert_str);
    if (attrp      == &attr) posix_spawnattr_destroy(&attr);
    
    return retval;
}

int fake_posix_spawn(pid_t *pid,
                     const char *file,
                     const posix_spawn_file_actions_t *file_actions,
                     posix_spawnattr_t *attrp,
                     const char *argv[],
                     const char *envp[]) {
    return fake_posix_spawn_common(pid, file, file_actions, attrp, argv, envp, old_pspawn);
}

int fake_posix_spawnp(pid_t *pid,
                      const char *file,
                      const posix_spawn_file_actions_t *file_actions,
                      posix_spawnattr_t *attrp,
                      const char *argv[],
                      const char *envp[]) {
    return fake_posix_spawn_common(pid, file, file_actions, attrp, argv, envp, old_pspawnp);
}

void entitle(pid_t pid) {
    jbd_call(jbd_port, JAILBREAKD_COMMAND_ENTITLE, pid);
}

void hook_pspawns(void) {
    entitle(getpid());
    
    void *handle = dlopen("/usr/lib/libsubstitute.dylib", RTLD_NOW);
    if (!handle) {
        logToFile("[FATAL] DLOPEN ERROR: %s", dlerror());
        return;
    }
    int (*substitute_hook_functions)(const struct substitute_function_hook *hooks, size_t nhooks, struct substitute_function_hook_record **recordp, int options) = dlsym(handle, "substitute_hook_functions");
    if (!substitute_hook_functions) {
        logToFile("[FATAL] DLSYM ERROR: %s", dlerror());
        return;
    }
    
    struct substitute_function_hook ps_hook;
    ps_hook.function = posix_spawn;
    ps_hook.replacement = fake_posix_spawn;
    ps_hook.old_ptr = &old_pspawn;
    ps_hook.options = 0;
    substitute_hook_functions(&ps_hook, 1, NULL, SUBSTITUTE_NO_THREAD_SAFETY);
    
    struct substitute_function_hook psp_hook;
    psp_hook.function = posix_spawnp;
    psp_hook.replacement = fake_posix_spawnp;
    psp_hook.old_ptr = &old_pspawnp;
    psp_hook.options = 0;
    substitute_hook_functions(&psp_hook, 1, NULL, SUBSTITUTE_NO_THREAD_SAFETY);
}

__attribute__ ((constructor))
static void ctor(void) {
    queue = dispatch_queue_create("pspawn.queue", NULL);
    
    char pathbuf[PROC_PIDPATHINFO_MAXSIZE];
    bzero(pathbuf, sizeof(pathbuf));
    proc_pidpath(getpid(), pathbuf, sizeof(pathbuf));
    
    
    if (getpid() == 1) {
        current_process = PROCESS_LAUNCHD;
        logToFile("[PSPAWN] WE ARE LAUNCHD!");
    } else if (strcmp(pathbuf, "/usr/libexec/xpcproxy") == 0 || strcmp(pathbuf, "/usr/libexec/xpcproxy.sliced") == 0) {
        current_process = PROCESS_XPCPROXY;
        logToFile("[PSPAWN] WE ARE XPCPROXY!");
    } else {
        current_process = PROCESS_OTHER;
        logToFile("[PSPAWN] WE ARE AN UNKNOWN PROCESS!");
    }
    
    logToFile("[PSPAWN] INIT");
    logToFile("[PSPAWN] PID: %d", getpid());
    
    if (bootstrap_look_up(bootstrap_port, "slice.jailbreakd", &jbd_port)) {
        logToFile("[PSPAWN_ERROR] ERROR GETTING JAILBREAKD PORT");
        return;
    }
    
    if (!MACH_PORT_VALID(jbd_port)) {
        logToFile("[PSPAWN_ERROR] JAILBREAKD PORT NOT VALID! RET: %x", jbd_port);
        return;
    }
    
    logToFile("[PSPAWN] GOT PORT AT: %x", jbd_port);
    
    if (current_process == PROCESS_LAUNCHD) {
        if (get_jbd_port())
            hook_pspawns();
        return;
    }
    
    if (current_process == PROCESS_OTHER) {
        entitle(getpid());
        return;
    }
    
    hook_pspawns();
    int stampfd = open("/var/run/pspawn_hook.ts", O_CREAT|O_WRONLY|O_TRUNC);
    if (stampfd == -1)
        return;
    
    dprintf(stampfd, "%ld", time(NULL));
    close(stampfd);
    chmod("/var/run/pspawn_hook.ts", 0644);
}
