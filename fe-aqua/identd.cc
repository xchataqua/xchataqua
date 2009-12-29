/* X-Chat Aqua
 * Copyright (C) 2002 Steve Green
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

#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/uio.h>
#include <sys/wait.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>

extern "C" {
#undef TYPE_BOOL
#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/text.h"
#include "../common/fe.h"
#undef TYPE_BOOL
}

static int ident_sok = -1;
static int ident_tag = -1;

int identd_start ();
void identd_stop ();

struct two_ints
{
    int sock;
    int tag;
};

static void identd_reply (void *, int, void *cbd)
{
    two_ints *x = (two_ints *) cbd;
    
    char buf [256];
    recv (x->sock, buf, sizeof (buf) - 1, 0);
    buf[sizeof (buf) - 1] = 0;	  /* ensure null termination */

    char *p = strchr (buf, ',');
    if (p)
    {
        char outbuf [256];
        snprintf (outbuf, sizeof (outbuf) - 1, "%d, %d : USERID : UNIX : %s\r\n",
                                    atoi (buf), atoi (p + 1), prefs.username);
        outbuf[sizeof (outbuf) - 1] = 0;	/* ensure null termination */
        send (x->sock, outbuf, strlen (outbuf), 0);
    }

    fe_input_remove (x->tag);
    
    close (x->sock);
    
    delete x;
}

static void identd (void *, int, void *)
{
    struct sockaddr_in addr;
    socklen_t len = sizeof (addr);
    
    int read_sok = accept (ident_sok, (struct sockaddr *) &addr, &len);

    if (read_sok < 0)
	{
		//perror ("accept");
		PrintText (current_sess, "Identd startup error.  Restarting.\n");
		identd_stop ();
		identd_start ();
        return;
	}

    char outbuf [256];
    snprintf (outbuf, sizeof (outbuf), "%%\tServicing ident request from %s\n",
                                inet_ntoa (addr.sin_addr));
    PrintText (current_sess, outbuf);

    two_ints *x = new two_ints;
    x->sock = read_sok;
    x->tag = fe_input_add (read_sok, FIA_READ, (void *) identd_reply, x);
}

int 
launch_identd_helper ()
{
    int fds [2];
    socketpair (AF_UNIX, SOCK_STREAM, 0, fds);

    pid_t pid = vfork ();
    
    if (pid == 0)
    {
        dup2 (fds [0], 3);
        
        close (fds [0]);
        close (fds [1]);
        
        execl ("Plugins/identd", "Plugins/identd", (char *) 0);
        
        _exit (0);
    }
    
    close (fds [0]);

    struct 
    {
        struct cmsghdr hdr;
        int fd;
    } control;

    char buff [128];
    struct iovec iov;        
    iov.iov_base = buff;
    iov.iov_len = sizeof (buff);

    struct msghdr msg;    
    msg.msg_name = NULL;
    msg.msg_namelen = 0;
    msg.msg_iov = &iov;
    msg.msg_iovlen = 1;
    msg.msg_control = (caddr_t) &control;
    msg.msg_controllen = sizeof (control);
    msg.msg_flags = MSG_WAITALL;
    
    int fd = -1;
    
    ssize_t len = recvmsg (fds[1], &msg, 0);
    
    // Send back a byte to tell the helper that we've got the message
    write (fds[0], &fd, 1);
    
    // The presence of a message idicates an error.  The passed fd is invalid.
    // Note we'll always get atleast 1 byte;
    
    if (len > 1)
        PrintText (current_sess, buff);
    else if (len == 1)
        fd = control.fd;
    
    close (fds [1]);
    
    waitpid (pid, NULL, 0);

    return fd;
}

void
identd_really_start ()
{
    if (ident_sok >= 0)
        return;
    
    ident_sok = launch_identd_helper ();
	
    if (ident_sok < 0)
        PrintText (current_sess, "Unable to start identd\n");
    else
    {
        ident_tag = fe_input_add (ident_sok, FIA_READ, (void *) identd, NULL);
        PrintText (current_sess, "identd started\n");
    }
}

int
identd_start ()
{
    // Hack to delay the initial startup of identd.  This is so
    // we get to see the identd startup message.
    
    if (current_sess)
        identd_really_start ();
    else
        fe_timeout_add (0, (void *) identd_start, NULL);
    
    return 0;
}

void
identd_stop ()
{
    if (ident_sok >= 0)
    {
        close (ident_sok);
        ident_sok = -1;
		fe_input_remove(ident_tag);
    }
}