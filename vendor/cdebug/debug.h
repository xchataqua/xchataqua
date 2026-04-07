//
//  debug.h
//
//  Created by Jeong YunWon on 12. 10. 2..
//  Copyright 2012 youknowone.org All rights reserved.
//

/*!
 *  @header debug.h Debug tools
 *
 *  Project website: <a href="https://github.com/youknowone/cdebug">https://github.com/youknowone/cdebug</a>
 *  Document website: <a href="http://youknowone.github.com/cdebug">http://youknowone.github.com/cdebug</a>
 *
 *  To take advantage of this feature, do one of below:
 *  1. Insert #define DEBUG 1
 *  2. Add compiler option DDEBUG
 *
 *  See README for more.
 *
 *  Define options if you don't like default
 *  1. DEBUG_WITH_FILE to enable __FILE__ macro (default: enabled)
 *  2. DEBUG_WITH_LINE to enable __LINE__ macro (default: enabled)
 *  3. DEBUG_WITH_TIME to enable runtime timestamp (default: enabled)
 *  4. DEBUG_NEWLINE to enable newline insertion (default: enabled)
 *  5. DEBUG_LOGLEVEL to define dlog trigger level (default: enabled)
 *  6. DEBUG_LOGTEST(LV) to define dlog trigger test. (default: LV >= DEBUG_LOGLEVEL)
 *  7. DEBUG_ASSERT to enable real assert in dassert (default: enabled)
 *  8. DEBUG_PRINTF to define printf function (default: printf in stdio.h)
 *  9. DEBUG_USE_NSLOG to enable automated NSLog flag for objective-c context (default: enabled)
 */

#ifndef __DEBUG_H__
#define __DEBUG_H__

#include <stdio.h>

/*!
 *  @define
 *  @brief Print file name with log or not
 *  @details Default is 1
 */
#ifndef DEBUG_WITH_FILE
    #define DEBUG_WITH_FILE 1
#endif

/*!
 *  @define
 *  @brief Print line number with log or not
 *  @details Default is 1
 */
#ifndef DEBUG_WITH_LINE
    #define DEBUG_WITH_LINE 1
#endif

/*!
 *  @define
 *  @brief Print new line after log or not
 *  @details Default is 1
 */
#ifndef DEBUG_NEWLINE
    #define DEBUG_NEWLINE 1
#endif

/*!
 *  @define
 *  @brief Minimum log level to decide print log or not
 *  @details Default is 1
 */
#ifndef DEBUG_LOGLEVEL
    #define DEBUG_LOGLEVEL 1
#endif

/*!
 *  @define
 *  @brief Log test macro
 *  @param LV
 *      A given level from dlog
 *  @details Default is (LV >= DEBUG_LOGLEVEL)
 */
#ifndef DEBUG_LOGTEST
    #define DEBUG_LOGTEST(LV) ((LV) >= DEBUG_LOGLEVEL)
#endif

/*!
 *  @define
 *  @brief Trigger assert() if dassert
 *  @details Default is 1
 */
#ifndef DEBUG_ASSERT
    #define DEBUG_ASSERT 1
#endif

/*!
 *  @define
 *  @brief Use NSLog if objc or just printf
 *  @details Default is 1
 */
#ifndef DEBUG_USE_NSLOG
    #define DEBUG_USE_NSLOG 1
#endif

/*!
 *  @define
 *  @brief Print time with log or not
 *  @details Default is 1 for printf and 0 for NSLog
 */
#ifndef DEBUG_WITH_TIME
    #if __OBJC__ && DEBUG_USE_NSLOG
        #define DEBUG_WITH_TIME 0
    #else
        #define DEBUG_WITH_TIME 1
    #endif
#endif

#if __OBJC__ && DEBUG_USE_NSLOG
    #import <Foundation/Foundation.h>
    #define DEBUG_DEFAULT_PRINT NSLog
#else
    #define DEBUG_DEFAULT_PRINT printf
#endif

/*!
 *  @define
 *  @brief printf function to use logging
 *  @details Default is printf. If __OBJC__ and DEBUG_USE_NSLOG then NSLog
 */
#ifndef DEBUG_PRINTF
    #define DEBUG_PRINTF DEBUG_DEFAULT_PRINT
#endif

#ifndef NO_DEBUG
    #if defined(DEBUG) || defined(CONFIG_Debug) || defined(CONFIG_Development)
        #define _DEBUG 1
    #else
        #define _DEBUG 0
    #endif
#endif

#if DEBUG_WITH_TIME
    #include <time.h>
#endif

#if DEBUG_WITH_TIME
    #define __dprint_time { \
        char timestr[20];   \
        time_t timestamp;   \
        struct tm* timeinfo;\
        time(&timestamp);   \
        timeinfo = localtime(&timestamp); \
        strftime(timestr, 20, "%d %H:%M:%S", timeinfo); \
        printf("%s ", timestr); \
    }
#else
    #define __dprint_time
#endif

#if DEBUG_WITH_FILE || DEBUG_WITH_LINE
    #if DEBUG_WITH_FILE && DEBUG_WITH_LINE
        #define __dprint_file_line { printf("[%16s:%4d] ", __FILE__, __LINE__); }
    #elif DEBUG_WITH_FILE
        #define __dprint_file_line { printf("[%16s] ", __FILE__); }
    #elif DEBUG_WITH_LINE
        #define __dprint_file_line { printf("ln%4d ", __LINE__); }
    #else
        #define __dprint_file_line
    #endif
#endif

/*!
 *  @define
 *  @brief Assertion only for debug mode.
 *  @param COND
 *      Condition to be passed to assert()
 */
#if _DEBUG && DEBUG_ASSERT
    #include <assert.h>
    #define dassert(COND) assert(COND)
#else
    #define dassert(COND)
#endif

#if _DEBUG
    /*!
     *  @define
     *  @brief Debug mode printf without newline
     *  @param ...
     *      printf params
     */
    #define dprintfnoln(...)        { __dprint_time __dprint_file_line DEBUG_PRINTF(__VA_ARGS__); }
    /*!
     *  @define
     *  @brief Debug mode assert with log without newline
     *  @param COND
     *      assert() condition
     *  @param ...
     *      printf params
     */
    #define dassertlognoln(COND, ...) { if (!(COND)) { dprintfnoln(__VA_ARGS__); dassert(COND);  } }
    /*!
     *  @define
     *  @brief Conditional log with level without newline
     *  @param LEVEL
     *      Log level
     *  @param ...
     *      printf params
     */
    #define dlognoln(LEVEL, ...)    { if (DEBUG_LOGTEST(LEVEL)) dprintfnoln(__VA_ARGS__); }

    /*!
     *  @define
     *  @brief Debug mode printf without newline
     *  @param ...
     *      printf params
     */
    #define dprintfln(...)          { dprintfnoln(__VA_ARGS__); puts(""); }
    /*!
     *  @define
     *  @brief Debug mode assert with log with newline
     *  @param COND
     *      assert() condition
     *  @param ...
     *      printf params
     */
    #define dassertlogln(COND, ...) { if (!(COND)) { dprintfln(__VA_ARGS__); dassert(COND);  } }
    /*!
     *  @define
     *  @brief Conditional log with level with newline
     *  @param LEVEL
     *      Log level
     *  @param ...
     *      printf params
     */
    #define dlogln(LEVEL, ...)      { if (DEBUG_LOGTEST(LEVEL)) dprintfln(__VA_ARGS__); }
#else
    #define dprintfnoln(...)
    #define dassertlognoln(COND, ...)
    #define dlognoln(LEVEL, ...)

    #define dprintfln(...)
    #define dassertlogln(COND, ...)
    #define dlogln(LEVEL, ...)
#endif

/*!
 *  @define
 *  @brief dprintf with or without newline by DEBUG_NEWLINE
 *  @param ...
 *      printf params
 */
#if DEBUG_NEWLINE
    #define dprintf(...)            dprintfln(__VA_ARGS__)
#else
    #define dprintf(...)            dprintfnoln(__VA_ARGS__)
#endif

/*!
 *  @define
 *  @brief dassertlog with or without newline by DEBUG_NEWLINE
 *  @param COND
 *      assert() condition
 *  @param ...
 *      printf params
 */
#if DEBUG_NEWLINE
    #define dassertlog(COND, ...)   dassertlogln(COND, __VA_ARGS__)
#else
    #define dassertlog(COND, ...)   dassertlognoln(COND, __VA_ARGS__)
#endif

/*!
 *  @define
 *  @brief dlog with or without newline by DEBUG_NEWLINE
 *  @param LEVEL
 *      Log level
 *  @param ...
 *      printf params
 */
#if DEBUG_NEWLINE
    #define dlog(LEVEL, ...)        dlogln(LEVEL, __VA_ARGS__)
#else
    #define dlog(LEVEL, ...)        dlognoln(LEVEL, __VA_ARGS__)
#endif

#endif
