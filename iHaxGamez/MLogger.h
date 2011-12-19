/*
 *  Logger.h
 *  BoardGames
 *
 *  Created by Xiliang Chen on 6/01/11.
 *  Copyright 2011 Xiliang Chen. All rights reserved.
 *
 */

#define MLOG_DEBUG 0
#define MLOG_INFO 1
#define MLOG_WARN 2
#define MLOG_ERROR 3

extern const char * const _MLogLevelName[];

#ifdef DEBUG
#define MLOG_LEVEL MLOG_DEBUG
#else
#define MLOG_LEVEL MLOG_ERROR
#endif

#define MLOG(level, msg, ...) NSLog(@" %s\t %s:%d\t- %@", _MLogLevelName[level], __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:msg, ##__VA_ARGS__])

#if MLOG_LEVEL <= MLOG_DEBUG
#define MDLOG(msg, ...) MLOG(MLOG_DEBUG, msg, ##__VA_ARGS__)
#else
#define MDLOG(msg, ...) do {} while (0)
#endif

#if MLOG_LEVEL <= MLOG_INFO
#define MILOG(msg, ...) MLOG(MLOG_INFO, msg, ##__VA_ARGS__)
#else
#define MILOG(msg, ...) do {} while (0)
#endif

#if MLOG_LEVEL <= MLOG_WARN
#define MWLOG(msg, ...) MLOG(MLOG_WARN, msg, ##__VA_ARGS__)
#else
#define MWLOG(msg, ...) do {} while (0)
#endif

#if MLOG_LEVEL <= MLOG_ERROR
#define MELOG(msg, ...) MLOG(MLOG_ERROR, msg, ##__VA_ARGS__)
#else
#define MELOG(msg, ...) do {} while (0)
#endif

#ifdef DEBUG
int _MIsInDebugger(void);

#define MASSERT(e, msg, ...) \
do { \
if (!(e)) { \
MELOG(@"fail assertion: '%s', %@", #e, [NSString stringWithFormat:msg, ##__VA_ARGS__]); \
if (_MIsInDebugger()) raise(SIGTRAP); \
} \
} while (0)

#define MFAIL(msg, ...) \
do { \
MELOG(msg, ##__VA_ARGS__); \
if (_MIsInDebugger()) raise(SIGTRAP); \
} while (0)

#else
#define MASSERT(e, msg, ...) \
do { \
if (!(e)) { \
MELOG(@"fail assertion: '%s', %@", #e, [NSString stringWithFormat:msg, ##__VA_ARGS__]); \
} \
} while (0)
#define MFAIL(msg, ...) MELog(msg, ##__VA_ARGS__)
#endif

#define MASSERT_SOFT(e) do { \
if (!(e)) { \
MWLOG(@"fail soft assertion: '%s'", #e); \
} \
} while (0)

#define MASSERT_KERN(e) do { \
kern_return_t __kr = (e);\
if (__kr != KERN_SUCCESS) { \
MWLOG(@"kernal function: '%s' returned with error: %s", #e, mach_error_string(__kr)); \
} \
} while (0)