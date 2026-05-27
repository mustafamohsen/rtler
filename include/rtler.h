// Copyright (c) 2026 Mustafa Mohsen
// SPDX-License-Identifier: MIT

#ifndef RTLER_H
#define RTLER_H

#ifdef __cplusplus
extern "C" {
#endif

char *rtler_transform_text(const char *input);
void rtler_free_string(char *ptr);

#ifdef __cplusplus
}
#endif

#endif
