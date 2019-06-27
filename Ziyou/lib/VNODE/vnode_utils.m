//
//  *.c
//  async_wake_ios
//
//  Created by George on 18/12/17.
//  Copyright © 2017 Ian Beer. All rights reserved.
//

#import "patchfinder64.h"
#import "offsets.h"
#import <stdlib.h>
#include "kernel_call.h"
#import <stdio.h>
#include "KernelUtils.h"
#include "PFOffs.h"
#include "kernel_slide.h"
#include "kernel_exec.h"
#include "kernel_memory.h"
#include "OffsetHolder.h"

// thx Siguza
typedef struct {
    uint64_t prev;
    uint64_t next;
    uint64_t start;
    uint64_t end;
} kmap_hdr_t;

uint64_t zm_fix_addr(uint64_t addr) {
    static kmap_hdr_t zm_hdr = {0, 0, 0, 0};
    if (zm_hdr.start == 0) {
        // xxx ReadKernel64(0) ?!
        // uint64_t zone_map_ref = find_zone_map_ref();
        LOG("zone_map_ref: %llx ", GETOFFSET(zone_map_ref));
        uint64_t zone_map = ReadKernel64(GETOFFSET(zone_map_ref));
        LOG("zone_map: %llx ", zone_map);
        // hdr is at offset 0x10, mutexes at start
        size_t r = kreadOwO(zone_map + 0x10, &zm_hdr, sizeof(zm_hdr));
        LOG("zm_range: 0x%llx - 0x%llx (read 0x%zx, exp 0x%zx)", zm_hdr.start, zm_hdr.end, r, sizeof(zm_hdr));
        
        if (r != sizeof(zm_hdr) || zm_hdr.start == 0 || zm_hdr.end == 0) {
            LOG("kread of zone_map failed!");
            exit(EXIT_FAILURE);
        }
        
        if (zm_hdr.end - zm_hdr.start > 0x100000000) {
            LOG("zone_map is too big, sorry.");
            exit(EXIT_FAILURE);
        }
    }
    
    uint64_t zm_tmp = (zm_hdr.start & 0xffffffff00000000) | ((addr) & 0xffffffff);
    
    return zm_tmp < zm_hdr.start ? zm_tmp + 0x100000000 : zm_tmp;
}


uint64_t _vfs_context() {
    static uint64_t vfs_context = 0;
    if (vfs_context == 0) {
        vfs_context = kexecute2(GETOFFSET(vfs_context_current), 1, 0, 0, 0, 0, 0, 0);
        vfs_context = zm_fix_addr(vfs_context);
    }
    return vfs_context;
}

int _vnode_lookup(const char *path, int flags, uint64_t *vpp, uint64_t vfs_context){
    size_t len = strlen(path) + 1;
    uint64_t vnode = kmem_alloc(sizeof(uint64_t));
    uint64_t ks = kmem_alloc(len);
    kwriteOwO(ks, path, len);
    int ret = (int)kexecute2(GETOFFSET(vnode_lookup), ks, 0, vnode, vfs_context, 0, 0, 0);
    if (ret != ERR_SUCCESS) {
        return -1;
    }
    *vpp = ReadKernel64(vnode);
    kmem_free(ks, len);
    kmem_free(vnode, sizeof(uint64_t));
    return 0;
}

uint64_t vnodeForPath(const char *path) {
    uint64_t vfs_context = 0;
    uint64_t *vpp = NULL;
    uint64_t vnode = 0;
    vfs_context = _vfs_context();
    if (!ISADDR(vfs_context)) {
        LOG("Failed to get vfs_context.");
        goto out;
    }
    vpp = malloc(sizeof(uint64_t));
    if (vpp == NULL) {
        LOG("Failed to allocate memory.");
        goto out;
    }
    if (_vnode_lookup(path, O_RDONLY, vpp, vfs_context) != ERR_SUCCESS) {
        LOG("Failed to get vnode at path \"%s\".", path);
        goto out;
    }
    vnode = *vpp;
    out:
    if (vpp != NULL) {
        free(vpp);
        vpp = NULL;
    }
    return vnode;
}

int _vnode_put(uint64_t vnode){
    return (int)kexecute2(GETOFFSET(vnode_put), vnode, 0, 0, 0, 0, 0, 0);
}




uint64_t vnodeForSnapshot(int fd, char *name) {
    uint64_t rvpp_ptr = 0;
    uint64_t sdvpp_ptr = 0;
    uint64_t ndp_buf = 0;
    uint64_t vfs_context = 0;
    uint64_t sdvpp = 0;
    uint64_t sdvpp_v_mount = 0;
    uint64_t sdvpp_v_mount_mnt_data = 0;
    uint64_t snap_meta_ptr = 0;
    uint64_t old_name_ptr = 0;
    uint32_t ndp_old_name_len = 0;
    uint64_t ndp_old_name = 0;
    uint64_t snap_meta = 0;
    uint64_t snap_vnode = 0;
    rvpp_ptr = kmem_alloc(sizeof(uint64_t));
    LOG("rvpp_ptr = " ADDR, rvpp_ptr);
    if (!ISADDR(rvpp_ptr)) {
        goto out;
    }
    sdvpp_ptr = kmem_alloc(sizeof(uint64_t));
    LOG("sdvpp_ptr = " ADDR, sdvpp_ptr);
    if (!ISADDR(sdvpp_ptr)) {
        goto out;
    }
    ndp_buf = kmem_alloc(816);
    LOG("ndp_buf = " ADDR, ndp_buf);
    if (!ISADDR(ndp_buf)) {
        goto out;
    }
    vfs_context = _vfs_context();
    LOG("vfs_context = " ADDR, vfs_context);
    if (!ISADDR(vfs_context)) {
        goto out;
    }
    if (kexecute2(GETOFFSET(vnode_get_snapshot), fd, rvpp_ptr, sdvpp_ptr, (uint64_t)name, ndp_buf, 2, vfs_context) != ERR_SUCCESS) {
        goto out;
    }
    sdvpp = ReadKernel64(sdvpp_ptr);
    LOG("sdvpp = " ADDR, sdvpp);
    if (!ISADDR(sdvpp)) {
        goto out;
    }
    sdvpp_v_mount = ReadKernel64(sdvpp + koffset(KSTRUCT_OFFSET_VNODE_V_MOUNT));
    LOG("sdvpp_v_mount = " ADDR, sdvpp_v_mount);
    if (!ISADDR(sdvpp_v_mount)) {
        goto out;
    }
    sdvpp_v_mount_mnt_data = ReadKernel64(sdvpp_v_mount + koffset(KSTRUCT_OFFSET_MOUNT_MNT_DATA));
    LOG("sdvpp_v_mount_mnt_data = " ADDR, sdvpp_v_mount_mnt_data);
    if (!ISADDR(sdvpp_v_mount_mnt_data)) {
        goto out;
    }
    snap_meta_ptr = kmem_alloc(sizeof(uint64_t));
    LOG("snap_meta_ptr = " ADDR, snap_meta_ptr);
    if (!ISADDR(snap_meta_ptr)) {
        goto out;
    }
    old_name_ptr = kmem_alloc(sizeof(uint64_t));
    LOG("old_name_ptr = " ADDR, old_name_ptr);
    if (!ISADDR(old_name_ptr)) {
        goto out;
    }
    ndp_old_name_len = ReadKernel32(ndp_buf + 336 + 48);
    LOG("ndp_old_name_len = 0x%x", ndp_old_name_len);
    ndp_old_name = ReadKernel64(ndp_buf + 336 + 40);
    LOG("ndp_old_name = " ADDR, ndp_old_name);
    if (!ISADDR(ndp_old_name)) {
        goto out;
    }
    if (kexecute2(GETOFFSET(fs_lookup_snapshot_metadata_by_name_and_return_name), sdvpp_v_mount_mnt_data, ndp_old_name, ndp_old_name_len, snap_meta_ptr, old_name_ptr, 0, 0) != ERR_SUCCESS) {
        goto out;
    }
    snap_meta = ReadKernel64(snap_meta_ptr);
    LOG("snap_meta = " ADDR, snap_meta);
    if (!ISADDR(snap_meta)) {
        goto out;
    }
    snap_vnode = kexecute2(GETOFFSET(apfs_jhash_getvnode), sdvpp_v_mount_mnt_data, ReadKernel32(sdvpp_v_mount_mnt_data + 440), ReadKernel64(snap_meta + 8), 1, 0, 0, 0);
    snap_vnode = zm_fix_addr(snap_vnode);
    LOG("snap_vnode = " ADDR, snap_vnode);
    if (!ISADDR(snap_vnode)) {
        goto out;
    }
    out:
    if (ISADDR(sdvpp)) {
        _vnode_put(sdvpp);
    }
    if (ISADDR(sdvpp_ptr)) {
        kmem_free(sdvpp_ptr, sizeof(uint64_t));
    }
    if (ISADDR(ndp_buf)) {
        kmem_free(ndp_buf, 816);
    }
    if (ISADDR(snap_meta_ptr)) {
        kmem_free(snap_meta_ptr, sizeof(uint64_t));
    }
    if (ISADDR(old_name_ptr)) {
        kmem_free(old_name_ptr, sizeof(uint64_t));
    }
    return snap_vnode;
}
