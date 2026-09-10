#pragma once
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <limits.h>
#define ARDESK_PRODUCT_ENVIRONMENT "DPKG_ROOT", "DPKG_DATADIR",

static inline void ardesk_product_environment(void)
{
    const char *root = bionicx_getenv("BIONICX_ROOTFS");
    const char *exe = bionicx_getenv("BIONICX_EXECFN");
    const char *name = exe ? strrchr(exe, '/') : NULL;
    char path[PATH_MAX];
    char perl[PATH_MAX * 5];
    if (!root || root[0] != '/' || !name) return;
    ++name;
    const char *transaction = bionicx_getenv("BIONICX_VIRTUAL_ROOT");
    if ((!transaction || !strcmp(transaction, "0")) && strcmp(name, "apt") && strncmp(name, "apt-", 4) &&
        strcmp(name, "dpkg") && strncmp(name, "dpkg-", 5) &&
        strcmp(name, "update-alternatives")) return;
    setenv("BIONICX_VIRTUAL_ROOT", "1", 1);
    setenv("BIONICX_REWRITE_ABSOLUTE_SYMLINKS", "1", 1);
    setenv("DPKG_ROOT", root, 0);
    if (snprintf(path, sizeof(path), "%s/usr/share/dpkg", root) < (int)sizeof(path))
        setenv("DPKG_DATADIR", path, 0);
    /* apt reads /etc/apt/apt.conf through FHS translation. Exporting
     * APT_CONFIG leaks into maintainer scripts: Chrome uses that name
     * for the apt-config executable, which apt then parses as config. */
    if (snprintf(path, sizeof(path), "%s/usr/share/apt/default-sequoia.config", root) < (int)sizeof(path))
        setenv("SEQUOIA_CRYPTO_POLICY", path, 0);
    if (snprintf(perl, sizeof(perl), "%s/etc/perl:%s/usr/share/perl5:"
                 "%s/usr/lib/aarch64-linux-gnu/perl-base:"
                 "%s/usr/lib/aarch64-linux-gnu/perl/5.40:%s/usr/share/perl/5.40",
                 root, root, root, root, root) < (int)sizeof(perl))
        setenv("PERL5LIB", perl, 0);
}
