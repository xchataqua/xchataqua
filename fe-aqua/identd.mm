/* X-Chat Aqua
 * Copyright (C) 2003 Steve Green
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA */

// N O T E:
// This is not really an identd.  It just opens port 113 and returns it in stdout.
//

// NSGetExecutablePathOnTenOneAndEarlierOnly is taken from sample code courtesy of 
// Apple Computer.

#include <crt_externs.h>
#include <mach-o/dyld.h>
#include <sys/param.h>
#include <fcntl.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/param.h>
#include <sys/uio.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <Security/Authorization.h>
#include <Security/AuthorizationTags.h>

extern int errno;
static char errorstr [128];

struct fd_message
{
    struct cmsghdr  hdr;
    int             fd;
};

int NSGetExecutablePathOnTenOneAndEarlierOnly(char *execPath, size_t *execPathSize)
{    
    char **cursor = (char **) (*(_NSGetArgv()) + *(_NSGetArgc()));
    
    if (*cursor != 0)
        return -1;
    
    cursor += 1;
    
    // Now, skip over the entire kernel-supplied environment, 
    // which is an array of char * terminated by a NULL.
    
    while (*cursor != 0)
        cursor += 1;
    
    // Skip over the NULL terminating the environment.  Actually, 
    // there can be multiple NULLs if the program has called 
    // unsetenv, so we skip along until we find a the next non-NULL.
    
    while (*cursor == 0)
        cursor += 1;

    // Now we have the path that was passed to exec 
    // (not the argv[0] path, but the path that the kernel 
    // actually executed).
    
    char *possiblyRelativePath = *cursor;

    // Convert the possibly relative path to an absolute 
    // path.  We use realpath for expedience, although 
    // the real implementation of _NSGetExecutablePath
    // uses getcwd and can return a path with symbolic links 
    // etc in it.
    
    if (realpath (possiblyRelativePath, execPath) == NULL)
        return -1;
    
    *execPathSize = strlen (execPath);

    return 0;
}

typedef int (*NSGetExecutablePathProcPtr)(char *buf, size_t *bufsize);

const char * get_exec_path ()
{
    NSGetExecutablePathProcPtr proc;
    
    if (NSIsSymbolNameDefined ("__NSGetExecutablePath"))
    {
        proc = (NSGetExecutablePathProcPtr) 
            NSAddressOfSymbol (NSLookupAndBindSymbol ("__NSGetExecutablePath"));
    } 
    else 
    {
        proc = NSGetExecutablePathOnTenOneAndEarlierOnly;
    }
    
    static char path [MAXPATHLEN];
   
    size_t len = sizeof (path);
    int sts = proc (path, &len);
    
    return sts == 0 ? path : NULL;
}

int reexec ()
{
    const char *path = get_exec_path ();
    
    AuthorizationItem requestedItems [1];
    const AuthorizationRights requestedRights = { 1, requestedItems};
    AuthorizationRef authorizationRef;
    OSStatus err = 0;
    requestedItems->name = kAuthorizationRightExecute;
    requestedItems->valueLength = strlen (path);
    requestedItems->value = (void *) path;
    requestedItems->flags = 0;
    
    err = AuthorizationCreate(
        &requestedRights,
        kAuthorizationEmptyEnvironment,
        kAuthorizationFlagPartialRights | kAuthorizationFlagExtendRights,
        &authorizationRef);

    char *args[] = { "reexec", 0 };
    
    FILE *f = NULL;
    err = AuthorizationExecuteWithPrivileges (authorizationRef, path, 0, args,  &f);
    
    int fd;
    
    if (f)
    {
        fd = dup (fileno (f));
        fclose (f);
    }
    else
        fd = -1;
    
    err = AuthorizationFree (authorizationRef, kAuthorizationFlagDestroyRights);
    
    return fd;
}

int send_fd (int fd, const char *message)
{
    struct fd_message control;

    control.hdr.cmsg_len = sizeof (control);
    control.hdr.cmsg_level = SOL_SOCKET;
    control.hdr.cmsg_type = SCM_RIGHTS;
    control.fd = fd;

    struct iovec iov;
    iov.iov_base = (void *) message;  
    iov.iov_len = strlen (message) + 1;

    struct msghdr msg;
    msg.msg_name = NULL;
    msg.msg_namelen = 0;
    msg.msg_iov = &iov;
    msg.msg_iovlen = 1;
    msg.msg_control = (caddr_t) &control;
    msg.msg_controllen = fd >= 0 ? control.hdr.cmsg_len : 0;
    msg.msg_flags = 0;
    
    return sendmsg (3, &msg, 0);
}

void fix_perms ()
{
    const char *path = get_exec_path ();
    if (!path)
        return;
    int fd = open (path, O_RDONLY, 0);
    fchown (fd, 0, -1);
    fchmod (fd, 04755);
}

int get_sock (short port)
{
    int s = socket (AF_INET, SOCK_STREAM, 0);
    
    if (s < 0)
    {
        sprintf (errorstr, "Can't get identd socket\n");
        return -1;
    }

    int len = 1;
    setsockopt (s, SOL_SOCKET, SO_REUSEADDR, (char *) &len, sizeof (len));

    struct sockaddr_in addr;
    memset (&addr, 0, sizeof (addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons (port);

    if (bind (s, (struct sockaddr *) &addr, sizeof (addr)) < 0)
    {
        sprintf (errorstr, "Can't bind to identd port: %s\n", strerror (errno));
        close (s);
        return -1;
    }

    if (listen (s, 5) < 0)
    {
        close (s);
        return -1;
    }

    return s;
}

int main (int argc, char **argv)
{
    errorstr [0] = 0;
    
    bool from_self = argc == 2 && strcmp (argv [1], "reexec") == 0;

    if (geteuid () != 0)
    {
        if (from_self)
            exit (-1);
        else
            reexec ();
        
        exit (0);
    }

    setuid (0);
    
    if (from_self)
        fix_perms ();
    
    int fd = get_sock (113);

	if (0)
	{
		timeval tv;
		tv.tv_sec = 0;
		tv.tv_usec = 0;
		fd_set rfds;
		FD_ZERO (&rfds);
		FD_SET (fd, &rfds);
		int n = select (fd + 1, &rfds, NULL, NULL, &tv);
		printf ("n = %d\n", n);
		fflush (stdout);
	}

    int sent = send_fd (fd, errorstr);
	
	if (sent > 0)
	{
		// Wait for xchat to tell us that he's received the message
		fd_set rfds;
		FD_ZERO (&rfds);
		FD_SET (3, &rfds);
		select (3 + 1, &rfds, NULL, NULL, NULL);
    }
	
    exit (0);
}