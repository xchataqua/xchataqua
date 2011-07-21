###################################################
#
# Makefile for libxchat-ruby.so
# Creator [Xcode -> Makefile Ver: Feb 14 2007 09:18:41]
# Created: [Wed Apr 25 09:04:18 2007]
#
###################################################

# Modified by hand: Thu Apr 26 2007

#
# Macros
#

CC = /usr/bin/gcc
CC_OPTIONS = -O -g -isysroot /Developer/SDKs/MacOSX10.5.sdk -arch i386 -arch x86_64 
LNK_OPTIONS = -arch i386 -arch x86_64 -Wl,-single_module -compatibility_version 1 -current_version 1 -install_name /usr/local/lib/libxchat-ruby.so -Wl,-Y,1455 -dynamiclib -mmacosx-version-min=10.5 -undefined dynamic_lookup -isysroot /Developer/SDKs/MacOSX10.5.sdk 

RUBY=ruby

#
# INCLUDE directories for libxchat-ruby.so
#

INCLUDE = -I. -I/usr/lib/ruby/1.8/universal-darwin10.0


#
# Build libxchat-ruby.so
#

.rb.h:
	$(RUBY) ../scripts/embedify.rb $*.rb $*.h

libxchat-ruby.so : \
		./xchat-ruby.o
	$(CC) $(LNK_OPTIONS) \
		./xchat-ruby.o\
		-o libxchat-ruby.so

clean : 
		rm \
		./xchat-ruby.o\
		libxchat-ruby.so

install : libxchat-ruby.so
		cp libxchat-ruby.so libxchat-ruby.so

#
# Build the parts of libxchat-ruby.so
#


# Item # 1 -- xchat-ruby --
./xchat-ruby.o : xchat-ruby.c
	$(CC) $(CC_OPTIONS) xchat-ruby.c -c $(INCLUDE) -o ./xchat-ruby.o


##### END RUN ####
