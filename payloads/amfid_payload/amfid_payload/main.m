// Massive creds to @theninjaprawn for his async_wake fork & help getting this patch to work :)
// [2018-3-14] big thanks for stek for letting me use his code on proper blob parsing :) -> https://github.com/stek29/electra/blob/amfid_fix/basebinaries/amfid_payload/

#include <dlfcn.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <mach/mach.h>
#include <mach-o/loader.h>
#include <mach-o/fat.h>
#include <mach/error.h>
#include <errno.h>
#include <stdlib.h>
#include <sys/sysctl.h>
#include <dlfcn.h>
#include <sys/mman.h>
#include <spawn.h>
#include <sys/stat.h>
#include <pthread.h>
#include <Foundation/Foundation.h>
#include <CommonCrypto/CommonDigest.h>
#include "cs_blobs.h"
#include "substitute.h"
FILE *file2LogTo;
#define MAX_INJECT 1
#define logToFile(fmt, args...)\
do {\
if (file2LogTo == NULL) {\
fprintf(stderr, fmt "\n", ##args); \
file2LogTo = fopen("/var/log/amfid_payload.log", "a"); \
if (file2LogTo == NULL) break; \
} \
fprintf(file2LogTo, fmt "\n", ##args); \
fflush(file2LogTo); \
} while(0)
int (*old_MISValidateSignatureAndCopyInfo)(NSString* file, NSDictionary* options, NSMutableDictionary** info);
extern int MISValidateSignatureAndCopyInfo(NSString* file, NSDictionary* options, NSMutableDictionary** info);

static unsigned int
hash_rank(const CodeDirectory *cd)
{
    uint32_t type = cd->hashType;
    unsigned int n;
    
    for (n = 0; n < sizeof(hashPriorities) / sizeof(hashPriorities[0]); ++n)
        if (hashPriorities[n] == type)
            return n + 1;
    return 0;    /* not supported */
}

// 0 on success
int get_hash(const CodeDirectory* directory, uint8_t dst[CS_CDHASH_LEN]) {
    uint32_t realsize = ntohl(directory->length);
    
    if (ntohl(directory->magic) != CSMAGIC_CODEDIRECTORY) {
        logToFile("[get_hash] wtf, not CSMAGIC_CODEDIRECTORY?!");
        return 1;
    }
    
    uint8_t out[CS_HASH_MAX_SIZE];
    uint8_t hash_type = directory->hashType;
    
    switch (hash_type) {
        case CS_HASHTYPE_SHA1:
            CC_SHA1(directory, realsize, out);
            break;
            
        case CS_HASHTYPE_SHA256:
        case CS_HASHTYPE_SHA256_TRUNCATED:
            CC_SHA256(directory, realsize, out);
            break;
            
        case CS_HASHTYPE_SHA384:
            CC_SHA384(directory, realsize, out);
            break;
            
        default:
            logToFile("[get_hash] Unknown hash type: 0x%x", hash_type);
            return 2;
    }
    
    memcpy(dst, out, CS_CDHASH_LEN);
    return 0;
}

// see cs_validate_csblob in xnu bsd/kern/ubc_subr.c
// 0 on success
int parse_superblob(uint8_t *code_dir, uint8_t dst[CS_CDHASH_LEN]) {
    int ret = 1;
    const CS_SuperBlob *sb = (const CS_SuperBlob *)code_dir;
    uint8_t highest_cd_hash_rank = 0;
    
    for (int n = 0; n < ntohl(sb->count); n++){
        const CS_BlobIndex *blobIndex = &sb->index[n];
        uint32_t type = ntohl(blobIndex->type);
        uint32_t offset = ntohl(blobIndex->offset);
        if (ntohl(sb->length) < offset) {
            logToFile("offset of blob #%d overflows superblob length", n);
            return 1;
        }
        
        const CodeDirectory *subBlob = (const CodeDirectory *)(code_dir + offset);
        // size_t subLength = ntohl(subBlob->length);
        
        if (type == CSSLOT_CODEDIRECTORY || (type >= CSSLOT_ALTERNATE_CODEDIRECTORIES && type < CSSLOT_ALTERNATE_CODEDIRECTORY_LIMIT)) {
            uint8_t rank = hash_rank(subBlob);
            
            if (rank > highest_cd_hash_rank) {
                ret = get_hash(subBlob, dst);
                highest_cd_hash_rank = rank;
            }
        }
    }
    
    return ret;
}

uint8_t *get_code_directory(const char* name, uint64_t file_off) {
    // XXX use mmap
    FILE* fd = fopen(name, "r");
    uint8_t *rv = NULL;
    
    if (fd == NULL) {
        logToFile("Couldn't open file");
        return NULL;
    }
    
    fseek(fd, 0L, SEEK_END);
    uint64_t file_len = ftell(fd);
    fseek(fd, 0L, SEEK_SET);
    
    if (file_off > file_len){
        logToFile("Error: File offset greater than length.");
        goto out;
    }
    
    uint64_t off = file_off;
    fseek(fd, off, SEEK_SET);
    
    struct mach_header_64 mh;
    fread(&mh, sizeof(struct mach_header_64), 1, fd);
    
    if (mh.magic != MH_MAGIC_64){
        logToFile("Error: Invalid magic");
        goto out;
    }
    
    off += sizeof(struct mach_header_64);
    if (off > file_len){
        logToFile("Error: Unexpected end of file");
        goto out;
    }
    for (int i = 0; i < mh.ncmds; i++) {
        if (off + sizeof(struct load_command) > file_len){
            logToFile("Error: Unexpected end of file");
            goto out;
        }
        
        const struct load_command cmd;
        fseek(fd, off, SEEK_SET);
        fread((void*)&cmd, sizeof(struct load_command), 1, fd);
        if (cmd.cmd == 0x1d) {
            uint32_t off_cs;
            fread(&off_cs, sizeof(uint32_t), 1, fd);
            uint32_t size_cs;
            fread(&size_cs, sizeof(uint32_t), 1, fd);
            
            if (off_cs+file_off+size_cs > file_len){
                logToFile("Error: Unexpected end of file");
                goto out;
            }
            
            rv = malloc(size_cs);
            if (rv != NULL) {
                fseek(fd, off_cs+file_off, SEEK_SET);
                fread(rv, size_cs, 1, fd);
            }
            goto out;
        } else {
            off += cmd.cmdsize;
            if (off > file_len){
                logToFile("Error: Unexpected end of file");
                goto out;
            }
        }
    }
    logToFile("Didnt find the code signature");
    
    out:;
    fclose(fd);
    return rv;
}

int fake_MISValidateSignatureAndCopyInfo(NSString* file, NSDictionary* options, NSMutableDictionary** info) {
    
    // NSString *file = (__bridge NSString *)fileStr;
    // NSDictionary *options = (__bridge NSDictionary*)opts;
    logToFile("We got called! %s", [file UTF8String]);
    
    int origret = old_MISValidateSignatureAndCopyInfo(file, options, info);
    logToFile("We got called! AFTER ACTUAL %s", [file UTF8String]);
    
    if (![*info objectForKey:@"CdHash"]) {
        NSNumber* file_offset = [options objectForKey:@"UniversalFileOffset"];
        uint64_t file_off = [file_offset unsignedLongLongValue];
        
        uint8_t* code_directory = get_code_directory([file UTF8String], file_off);
        if (!code_directory) {
            logToFile("Can't get code_directory");
            return origret;
        }
        
        uint8_t cd_hash[CS_CDHASH_LEN];
        
        if (parse_superblob(code_directory, cd_hash)) {
            NSLog(@"Ours failed");
            return origret;
        }
        
        *info = [[NSMutableDictionary alloc] init];
        [*info setValue:[[NSData alloc] initWithBytes:cd_hash length:sizeof(cd_hash)] forKey:@"CdHash"];
    }
    
    return 0;
}

__attribute__ ((constructor))
static void ctor(void) {
    logToFile("[AMFID] INIT");
    
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
    
    struct substitute_function_hook mvsaci_hook;
    mvsaci_hook.function = MISValidateSignatureAndCopyInfo;
    mvsaci_hook.replacement = fake_MISValidateSignatureAndCopyInfo;
    mvsaci_hook.old_ptr = &old_MISValidateSignatureAndCopyInfo;
    mvsaci_hook.options = 0;
    substitute_hook_functions(&mvsaci_hook, 1, NULL, SUBSTITUTE_NO_THREAD_SAFETY);
    
    logToFile("[AMFID] HOOKED!");
    
    fclose(fopen("/var/tmp/amfid_payload.alive", "w+"));
}
