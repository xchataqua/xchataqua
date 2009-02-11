#ifndef _G_LIB_CONFIG_H
#define _G_LIB_CONFIG_H 1

#include <stdint.h>
#include <sys/types.h>
#include <limits.h>

#define SIZEOF_CHAR     1
#define USE_LIBICONV_GNU

#define G_MINFLOAT      FLT_MIN
#define G_MAXFLOAT      FLT_MAX
#define G_MINDOUBLE     DBL_MIN
#define G_MAXDOUBLE     DBL_MAX
#define G_MINSHORT      SHRT_MIN
#define G_MAXSHORT      SHRT_MAX
#define G_MAXUSHORT     USHRT_MAX
#define G_MININT        INT_MIN
#define G_MAXINT        INT_MAX
#define G_MAXUINT       UINT_MAX
#define G_MINLONG       LONG_MIN
#define G_MAXLONG       LONG_MAX
#define G_MAXULONG      ULONG_MAX

#ifdef __BIG_ENDIAN__
# define G_BYTE_ORDER G_BIG_ENDIAN
#else
# define G_BYTE_ORDER G_LITTLE_ENDIAN
#endif

#define G_GINT16_MODIFIER "h"
#define G_GINT16_FORMAT "hi"
#define G_GUINT16_FORMAT "hu"
#define G_GINT32_MODIFIER ""
#define G_GINT32_FORMAT "i"
#define G_GUINT32_FORMAT "u"
#define G_HAVE_GINT64 1          /* deprecated, always true */

#define G_GINT64_CONSTANT(val)  (G_GNUC_EXTENSION (val##LL))
#define G_GUINT64_CONSTANT(val) (G_GNUC_EXTENSION (val##ULL))
#define G_GINT64_MODIFIER "ll"
#define G_GINT64_FORMAT "lli"
#define G_GUINT64_FORMAT "llu"

#define GLIB_SIZEOF_VOID_P 4
#define GLIB_SIZEOF_LONG   4
#define GLIB_SIZEOF_SIZE_T 4

typedef u_int8_t  guint8;
typedef int8_t    gint8;
typedef u_int32_t guint32;
typedef int32_t   gint32;
typedef int64_t   gint64;
typedef u_int64_t guint64;
typedef int16_t   gint16;
typedef u_int16_t guint16;
typedef size_t    gsize;
typedef ssize_t   gssize;

#include <glib/gmacros.h>

#define G_GSIZE_MODIFIER "l"
#define G_GSSIZE_FORMAT "li"
#define G_GSIZE_FORMAT "lu"

#define G_MAXSIZE       G_MAXULONG

#define GPOINTER_TO_INT(p)      ((gint)   (p))
#define GPOINTER_TO_UINT(p)     ((guint)  (p))

#define GINT_TO_POINTER(i)      ((gpointer)  (i))
#define GUINT_TO_POINTER(u)     ((gpointer)  (u))

#ifdef NeXT /* @#%@! NeXTStep */
# define g_ATEXIT(proc) (!atexit (proc))
#else
# define g_ATEXIT(proc) (atexit (proc))
#endif

#define HAVE_MEMMOVE 1
#define g_memmove(dest,src,len) G_STMT_START { memmove ((dest), (src), (len)); } G_STMT_END

#define GLIB_MAJOR_VERSION 2
#define GLIB_MINOR_VERSION 12
#define GLIB_MICRO_VERSION 13
#define GLIB_INTERFACE_AGE 0
#define GLIB_BINARY_AGE 0

#define G_OS_UNIX

#define G_VA_COPY       va_copy

#ifdef  __cplusplus
#define G_HAVE_INLINE   1
#else   /* !__cplusplus */
#define G_HAVE_INLINE 1
#define G_HAVE___INLINE 1
#define G_HAVE___INLINE__ 1
#endif  /* !__cplusplus */

#ifdef  __cplusplus
#define G_CAN_INLINE    1
#else   /* !__cplusplus */
#define G_CAN_INLINE    1
#endif
#ifndef __cplusplus
# define G_HAVE_ISO_VARARGS 1
#endif
#ifdef __cplusplus
# define G_HAVE_ISO_VARARGS 1
#endif

/* gcc-2.95.x supports both gnu style and ISO varargs, but if -ansi
 * is passed ISO vararg support is turned off, and there is no work
 * around to turn it on, so we unconditionally turn it off.
 */
#if __GNUC__ == 2 && __GNUC_MINOR__ == 95
#  undef G_HAVE_ISO_VARARGS
#endif

#define G_HAVE_GNUC_VARARGS 1
#define G_HAVE_GROWING_STACK 0

#define G_GNUC_INTERNAL

#define G_THREADS_ENABLED
#define G_THREADS_IMPL_POSIX
typedef struct _GStaticMutex GStaticMutex;
struct _GStaticMutex
{
	struct _GMutex *runtime_mutex;
	union {
		char   pad[44];
		double dummy_double;
		void  *dummy_pointer;
		long   dummy_long;
	} static_mutex;
};

#define G_STATIC_MUTEX_INIT     { NULL, { { 50,-86,-85,-89,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} } }
#define g_static_mutex_get_mutex(mutex) \
(g_thread_use_default_impl ? ((GMutex*) ((mutex)->static_mutex.pad)) : \
g_static_mutex_get_mutex_impl_shortcut (&((mutex)->runtime_mutex)))
/* This represents a system thread as used by the implementation. An
 * alien implementaion, as loaded by g_thread_init can only count on
 * "sizeof (gpointer)" bytes to store their info. We however need more
 * for some of our native implementations. */
typedef union _GSystemThread GSystemThread;
union _GSystemThread
{
	char   data[4];
	double dummy_double;
	void  *dummy_pointer;
	long   dummy_long;
};

#define G_ATOMIC_OP_MEMORY_BARRIER_NEEDED 1

#define GINT16_TO_BE(val)       ((gint16) (val))
#define GUINT16_TO_BE(val)      ((guint16) (val))
#define GINT16_TO_LE(val)       ((gint16) GUINT16_SWAP_LE_BE (val))
#define GUINT16_TO_LE(val)      (GUINT16_SWAP_LE_BE (val))
#define GINT32_TO_BE(val)       ((gint32) (val))
#define GUINT32_TO_BE(val)      ((guint32) (val))
#define GINT32_TO_LE(val)       ((gint32) GUINT32_SWAP_LE_BE (val))
#define GUINT32_TO_LE(val)      (GUINT32_SWAP_LE_BE (val))
#define GINT64_TO_BE(val)       ((gint64) (val))
#define GUINT64_TO_BE(val)      ((guint64) (val))
#define GINT64_TO_LE(val)       ((gint64) GUINT64_SWAP_LE_BE (val))
#define GUINT64_TO_LE(val)      (GUINT64_SWAP_LE_BE (val))
#define GLONG_TO_LE(val)        ((glong) GINT32_TO_LE (val))
#define GULONG_TO_LE(val)       ((gulong) GUINT32_TO_LE (val))
#define GLONG_TO_BE(val)        ((glong) GINT32_TO_BE (val))
#define GULONG_TO_BE(val)       ((gulong) GUINT32_TO_BE (val))
#define GINT_TO_LE(val)         ((gint) GINT32_TO_LE (val))
#define GUINT_TO_LE(val)        ((guint) GUINT32_TO_LE (val))
#define GINT_TO_BE(val)         ((gint) GINT32_TO_BE (val))
#define GUINT_TO_BE(val)        ((guint) GUINT32_TO_BE (val))

#define GLIB_SYSDEF_POLLIN =1
#define GLIB_SYSDEF_POLLOUT =4
#define GLIB_SYSDEF_POLLPRI =2
#define GLIB_SYSDEF_POLLHUP =16
#define GLIB_SYSDEF_POLLERR =8
#define GLIB_SYSDEF_POLLNVAL =32

#define G_MODULE_SUFFIX "so"
#define HAVE_UNISTD_H 1

typedef int GPid;

#endif
