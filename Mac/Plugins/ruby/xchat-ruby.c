/* --------------------------------------------------------------------------
 * xchat-ruby.c -- glue code between Ruby interpreter and XChat plugin API
 * Copyright (C) 2003 Jamis Buck (jgb3@email.byu.edu)
 * --------------------------------------------------------------------------
 * This file is part of the XChat-Ruby plugin.
 * 
 * The  XChat-Ruby  plugin  is  free software; you can redistribute it and/or
 * modify  it  under the terms of the GNU General Public License as published
 * by  the  Free  Software  Foundation;  either  version 2 of the License, or
 * (at your option) any later version.
 * 
 * The  XChat-Ruby  plugin is distributed in the hope that it will be useful,
 * but   WITHOUT   ANY   WARRANTY;  without  even  the  implied  warranty  of
 * MERCHANTABILITY  or  FITNESS  FOR  A  PARTICULAR  PURPOSE.   See  the  GNU
 * General Public License for more details.
 * 
 * You  should  have  received  a  copy  of  the  GNU  General Public License
 * along  with  the  XChat-Ruby  plugin;  if  not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 * --------------------------------------------------------------------------
 * This is the glue code between the Ruby interpreter and the XChat plugin
 * API.
 *
 * Author: Jamis Buck (jgb3@email.byu.edu)
 * Date: June 2003
 * -------------------------------------------------------------------------- */

#include <stdio.h>
#include <stdlib.h>

#include <Ruby/Ruby.h>
#include "xchat-plugin.h"
#include "xchat-ruby-plugin.h"  /* this is the ruby code as a #define */

/* ``global'' variables (global to the XChat-Ruby plugin) {{{ */

#define XCHAT_RUBY_VERSION "1.2"

static xchat_plugin *static_plugin_handle = NULL;
static xchat_plugin *ph = NULL;
static int           static_ruby_initialized = 0;

static VALUE         static_xchat_module;

static VALUE         static_xchat_klass;
static VALUE         static_xchat_list_klass;
static VALUE         static_xchat_hook_klass;
static VALUE         static_xchat_context_klass;
static VALUE         static_xchat_list_internal_klass;

static ID            static_xchat_process_command_hook;
static ID            static_xchat_process_print_hook;
static ID            static_xchat_process_server_hook;
static ID            static_xchat_process_timer_hook;

/*}}}*/

/* private method declarations {{{*/

/**
 * Initializes the ruby environment.
 */
static void static_init_ruby_environment( void );

/**
 * Initializes the XChat environment.
 */
static void static_init_xchat_environment( xchat_plugin *plugin_handle,
                                           char **plugin_name,
                                           char **plugin_desc,
                                           char **plugin_version );

/**
 * Ruby callback function for adding a new callback hook for a
 * command.
 */
static VALUE static_ruby_xchat_hook_command( VALUE klass,
                                             VALUE name,
                                             VALUE priority,
                                             VALUE help );

/**
 * Ruby callback function for adding a new callback hook for a
 * print event.
 */
static VALUE static_ruby_xchat_hook_print( VALUE klass,
                                           VALUE name,
                                           VALUE priority );

/**
 * Ruby callback function for adding a new callback hook for a
 * server event.
 */
static VALUE static_ruby_xchat_hook_server( VALUE klass,
                                            VALUE name,
                                            VALUE priority );

/**
 * Ruby callback function for adding a new callback hook for a
 * timer event.
 */
static VALUE static_ruby_xchat_hook_timer( VALUE klass,
                                           VALUE name,
                                           VALUE timeout );

/**
 * Ruby callback function for printing text to an XChat window.
 */
static VALUE static_ruby_xchat_print( VALUE klass,
                                      VALUE text );

/**
 * Ruby callback function for removing a callback hook.
 */
static VALUE static_ruby_xchat_unhook( VALUE klass,
                                       VALUE hook_id );

/**
 * Ruby callback function for invoking a command
 */
static VALUE static_ruby_xchat_command( VALUE klass,
                                        VALUE command );

/**
 * Ruby callback function for searching for a specified context.
 */
static VALUE static_ruby_xchat_find_context( VALUE klass,
                                             VALUE server,
                                             VALUE channel );

/**
 * Ruby callback function for getting the current XChat context.
 */
static VALUE static_ruby_xchat_get_context( VALUE klass );

/**
 * Ruby callback function for getting a named information value.
 */
static VALUE static_ruby_xchat_get_info( VALUE klass,
                                         VALUE id );

/**
 * Ruby callback function for getting a named user preference.
 */
static VALUE static_ruby_xchat_get_prefs( VALUE klass,
                                          VALUE name );

/**
 * Ruby callback function for setting the current XChat context.
 */
static VALUE static_ruby_xchat_set_context( VALUE klass,
                                            VALUE ctx );

/**
 * Ruby callback function for comparing two nicks.
 */
static VALUE static_ruby_xchat_nickcmp( VALUE klass,
                                        VALUE s1,
                                        VALUE s2 );

/**
 * Ruby callback function for getting a named list.
 */
static VALUE static_ruby_xchat_list_get( VALUE klass,
                                         VALUE name );

/**
 * Ruby callback function for moving to the next value in
 * a named list.
 */
static VALUE static_ruby_xchat_list_next( VALUE klass,
                                          VALUE list );

/**
 * Ruby callback function for getting a named field from
 * a list as a string value.
 */
static VALUE static_ruby_xchat_list_str( VALUE klass,
                                         VALUE list,
                                         VALUE name );

/**
 * Ruby callback function for getting a named field from
 * a list as an integer value.
 */
static VALUE static_ruby_xchat_list_int( VALUE klass,
                                         VALUE list,
                                         VALUE name );

/**
 * Ruby callback function for emitting a print event.
 */
static VALUE static_ruby_xchat_emit_print( int    argc,
                                           VALUE *argv,
                                           VALUE  klass );

/**
 * XChat callbook hook for handling a custom command written
 * in Ruby.
 */
static int static_ruby_custom_command_hook( char *word[],
                                            char *word_eol[],
                                            void *userdata );

/**
 * XChat callbook hook for handling a custom print event
 * handler written in Ruby.
 */
static int static_ruby_custom_print_hook( char *word[],
                                          void *userdata );

/**
 * XChat callbook hook for handling a custom server event
 * handler written in Ruby.
 */
static int static_ruby_custom_server_hook( char *word[],
                                           char *word_eol[],
                                           void *userdata );

/**
 * XChat callbook hook for handling a custom timer event
 * handler written in Ruby.
 */
static int static_ruby_custom_timer_hook( void *userdata );

/**
 * Callback for destroying a list when Ruby garbage collects
 * the associated XChatListInternal object.
 */
static void static_free_xchat_list( xchat_list *list );

/*}}}*/

                                             
static void static_init_ruby_environment( void )
{
  /* only initialize the ruby environment once */
  if( static_ruby_initialized ) return;
  static_ruby_initialized = 1;

  ruby_init();

  /* "EMBEDDED_STUFF" is a macro that contains all of the Ruby code needed to
   * define the core XChat-Ruby interface.  Once this has been defined, all we
   * need to do is extract the defined classes and add the C hooks to them.
   */

  rb_eval_string( XCHAT_RUBY_PLUGIN );

  static_xchat_module = rb_eval_string( "XChatRuby" );

  static_xchat_klass = rb_eval_string( "XChatRuby::XChatRubyEnvironment" );
  static_xchat_list_klass = rb_eval_string( "XChatRuby::XChatRubyList" );
  static_xchat_hook_klass = rb_define_class( "XChatRuby::XChatRubyCallback", rb_cObject );

  static_xchat_context_klass = rb_define_class_under( static_xchat_module,
                                                      "XChatContext",
                                                      rb_cObject );

  static_xchat_list_internal_klass = rb_define_class_under( static_xchat_module,
                                                            "XChatListInternal",
                                                            rb_cObject );

  static_xchat_process_command_hook = rb_intern( "process_command_hook" );
  static_xchat_process_print_hook = rb_intern( "process_print_hook" );
  static_xchat_process_server_hook = rb_intern( "process_server_hook" );
  static_xchat_process_timer_hook = rb_intern( "process_timer_hook" );

  rb_define_singleton_method( static_xchat_klass,
                              "internal_xchat_hook_command",
                              static_ruby_xchat_hook_command,
                              3 );

  rb_define_singleton_method( static_xchat_klass,
                              "internal_xchat_hook_print",
                              static_ruby_xchat_hook_print,
                              2 );

  rb_define_singleton_method( static_xchat_klass,
                              "internal_xchat_hook_server",
                              static_ruby_xchat_hook_server,
                              2 );

  rb_define_singleton_method( static_xchat_klass,
                              "internal_xchat_hook_timer",
                              static_ruby_xchat_hook_timer,
                              2 );

  rb_define_singleton_method( static_xchat_klass,
                              "internal_xchat_print",
                              static_ruby_xchat_print,
                              1 );

  rb_define_singleton_method( static_xchat_klass,
                              "internal_xchat_unhook",
                              static_ruby_xchat_unhook,
                              1 );

  rb_define_singleton_method( static_xchat_klass,
                              "command",
                              static_ruby_xchat_command,
                              1 );

  rb_define_singleton_method( static_xchat_klass,
                              "find_context",
                              static_ruby_xchat_find_context,
                              2 );

  rb_define_singleton_method( static_xchat_klass,
                              "get_context",
                              static_ruby_xchat_get_context,
                              0 );

  rb_define_singleton_method( static_xchat_klass,
                              "get_info",
                              static_ruby_xchat_get_info,
                              1 );

  rb_define_singleton_method( static_xchat_klass,
                              "get_prefs",
                              static_ruby_xchat_get_prefs,
                              1 );

  rb_define_singleton_method( static_xchat_klass,
                              "set_context",
                              static_ruby_xchat_set_context,
                              1 );

  rb_define_singleton_method( static_xchat_klass,
                              "nickcmp",
                              static_ruby_xchat_nickcmp,
                              2 );

  rb_define_singleton_method( static_xchat_klass,
                              "emit_print",
                              static_ruby_xchat_emit_print,
                              -1 );


  rb_define_method( static_xchat_list_klass,
                    "internal_xchat_list_get",
                    static_ruby_xchat_list_get,
                    1 );

  rb_define_method( static_xchat_list_klass,
                    "internal_xchat_list_next",
                    static_ruby_xchat_list_next,
                    1 );

  rb_define_method( static_xchat_list_klass,
                    "internal_xchat_list_str",
                    static_ruby_xchat_list_str,
                    2 );

  rb_define_method( static_xchat_list_klass,
                    "internal_xchat_list_int",
                    static_ruby_xchat_list_int,
                    2 );


  rb_funcall( static_xchat_klass,
              rb_intern( "register" ),
              0 );
}


static void static_init_xchat_environment( xchat_plugin *plugin_handle,
                                           char **plugin_name,
                                           char **plugin_desc,
                                           char **plugin_version )
{
  *plugin_name = "XChat-Ruby";
  *plugin_desc = "Allows the Ruby interpreter to be interactively called from XChat, "
                 "and for XChat plugins to be written in Ruby.";
  *plugin_version = XCHAT_RUBY_VERSION;
}


static VALUE static_ruby_xchat_hook_command( VALUE klass,
                                             VALUE name,
                                             VALUE priority,
                                             VALUE help )
{
  char *s_name;
  char *s_help;
  int   i_priority;

  xchat_hook *hook;
  VALUE       v_hook;

  Check_Type( name, T_STRING );
  Check_Type( priority, T_FIXNUM );
  Check_Type( help, T_STRING );

  s_name = STR2CSTR( name );
  i_priority = FIX2INT( priority );
  s_help = STR2CSTR( help );

  hook = xchat_hook_command( static_plugin_handle,
                             s_name,
                             i_priority,
                             static_ruby_custom_command_hook,
                             s_help,
                             NULL );

  v_hook = Data_Wrap_Struct( static_xchat_hook_klass,
                             NULL, NULL,
                             hook );

  return v_hook;
}


static VALUE static_ruby_xchat_hook_print( VALUE klass,
                                           VALUE name,
                                           VALUE priority )
{
  char *s_name;
  int   i_priority;
  xchat_hook *hook;
  VALUE v_hook;

  Check_Type( name, T_STRING );
  Check_Type( priority, T_FIXNUM );

  s_name = STR2CSTR( name );
  i_priority = FIX2INT( priority );

  hook = xchat_hook_print( static_plugin_handle,
                           s_name,
                           i_priority,
                           static_ruby_custom_print_hook,
                           (void*)name );

  v_hook = Data_Wrap_Struct( static_xchat_hook_klass,
                             NULL, NULL,
                             hook );

  return v_hook;
}


static VALUE static_ruby_xchat_hook_server( VALUE klass,
                                            VALUE name,
                                            VALUE priority )
{
  char *s_name;
  int   i_priority;
  xchat_hook *hook;
  VALUE v_hook;

  Check_Type( name, T_STRING );
  Check_Type( priority, T_FIXNUM );

  s_name = STR2CSTR( name );
  i_priority = FIX2INT( priority );

  hook = xchat_hook_server( static_plugin_handle,
                            s_name,
                            i_priority,
                            static_ruby_custom_server_hook,
                            NULL );

  v_hook = Data_Wrap_Struct( static_xchat_hook_klass,
                             NULL, NULL,
                             hook );

  return v_hook;
}


static VALUE static_ruby_xchat_hook_timer( VALUE klass,
                                           VALUE name,
                                           VALUE timeout )
{
  char *s_name;
  int   i_timeout;
  xchat_hook *hook;
  VALUE v_hook;

  Check_Type( name, T_STRING );
  Check_Type( timeout, T_FIXNUM );

  s_name = STR2CSTR( name );
  i_timeout = FIX2INT( timeout );

  hook = xchat_hook_timer( static_plugin_handle,
                           i_timeout,
                           static_ruby_custom_timer_hook,
                           (void*)name );

  v_hook = Data_Wrap_Struct( static_xchat_hook_klass,
                             NULL, NULL,
                             hook );

  return v_hook;
}


static VALUE static_ruby_xchat_print( VALUE klass,
                                      VALUE text )
{
  char *s_text;

  Check_Type( text, T_STRING );

  s_text = STR2CSTR( text );

  xchat_print( static_plugin_handle, s_text );

  return Qnil;
}


static VALUE static_ruby_xchat_unhook( VALUE klass,
                                       VALUE hook_id )
{
  xchat_hook *hook;

  Data_Get_Struct( hook_id, xchat_hook, hook );

  xchat_unhook( static_plugin_handle, hook );

  return Qnil;
}


static VALUE static_ruby_xchat_command( VALUE klass,
                                        VALUE command )
{
  char *cmd;

  Check_Type( command, T_STRING );
  cmd = STR2CSTR( command );

  xchat_command( static_plugin_handle,
                 cmd );

  return Qnil;
}


static VALUE static_ruby_xchat_find_context( VALUE klass,
                                             VALUE server,
                                             VALUE channel )
{
  char *s_server = NULL;
  char *s_channel = NULL;
  xchat_context *ctx;
  VALUE v_ctx;

  if( !NIL_P( server ) ) s_server = STR2CSTR( server );
  if( !NIL_P( channel ) ) s_channel = STR2CSTR( channel );

  ctx = xchat_find_context( static_plugin_handle,
                            s_server,
                            s_channel );

  if( ctx == NULL )
    return Qnil;

  v_ctx = Data_Wrap_Struct( static_xchat_context_klass,
                            NULL, NULL,
                            ctx );

  return v_ctx;
}


static VALUE static_ruby_xchat_get_context( VALUE klass )
{
  xchat_context *ctx;
  VALUE v_ctx;

  ctx = xchat_get_context( static_plugin_handle );

  v_ctx = Data_Wrap_Struct( static_xchat_context_klass,
                            NULL, NULL,
                            ctx );

  return v_ctx;
}


static VALUE static_ruby_xchat_get_info( VALUE klass,
                                         VALUE id )
{
  char *s_id;
  const char *s_info;

  s_id = STR2CSTR( id );

  s_info = xchat_get_info( static_plugin_handle, s_id );

  if( s_info == NULL ) return Qnil;

  return rb_str_new2( s_info );
}


static VALUE static_ruby_xchat_get_prefs( VALUE klass,
                                          VALUE name )
{
  char *s_name;
  char *s_pref;
  int   i_pref;
  int   rc;

  s_name = STR2CSTR( name );

  rc = xchat_get_prefs( static_plugin_handle,
                        s_name,
                        (const char**)&s_pref, &i_pref );

  switch( rc )
  {
    case 0: /* failed */
      return Qnil;
    case 1: /* returned a string */
      return rb_str_new2( s_pref );
    case 2: /* returned an int */
      return INT2FIX( i_pref );
    case 3: /* returned a bool */
      return ( i_pref ? Qtrue : Qfalse );
  }

  return Qnil;
}


static VALUE static_ruby_xchat_set_context( VALUE klass,
                                            VALUE ctx )
{
  xchat_context *context;
  int rc;

  Data_Get_Struct( ctx, xchat_context, context );

  rc = xchat_set_context( static_plugin_handle,
                          context );

  return INT2FIX( rc );
}


static VALUE static_ruby_xchat_nickcmp( VALUE klass,
                                        VALUE s1,
                                        VALUE s2 )
{
  char *s_s1;
  char *s_s2;

  s_s1 = STR2CSTR( s1 );
  s_s2 = STR2CSTR( s2 );

  return INT2FIX( xchat_nickcmp( static_plugin_handle, s_s1, s_s2 ) );
}


static VALUE static_ruby_xchat_list_get( VALUE klass,
                                         VALUE name )
{
  xchat_list *list;
  char *s_name;
  VALUE v_list;

  s_name = STR2CSTR( name );

  list = xchat_list_get( static_plugin_handle, s_name );
  if( list == NULL )
    return Qnil;

  v_list = Data_Wrap_Struct( static_xchat_list_internal_klass,
                             NULL, static_free_xchat_list,
                             list );

  return v_list;
}


static VALUE static_ruby_xchat_list_next( VALUE klass,
                                          VALUE list )
{
  xchat_list *x_list;
  int rc;

  Data_Get_Struct( list, xchat_list, x_list );
  if( x_list == NULL )
    return Qfalse;

  rc = xchat_list_next( static_plugin_handle, x_list );

  return ( rc ? Qtrue : Qfalse );
}


static VALUE static_ruby_xchat_list_str( VALUE klass,
                                         VALUE list,
                                         VALUE name )
{
  xchat_list *x_list;
  char *str;
  char *s_name;

  Data_Get_Struct( list, xchat_list, x_list );
  s_name = STR2CSTR( name );

  str = (char*)xchat_list_str( static_plugin_handle, x_list, (const char*)s_name );
  if( str == NULL )
    return Qnil;

  return rb_str_new2( str );
}


static VALUE static_ruby_xchat_list_int( VALUE klass,
                                         VALUE list,
                                         VALUE name )
{
  xchat_list *x_list;
  int rc;
  char *s_name;

  Data_Get_Struct( list, xchat_list, x_list );
  s_name = STR2CSTR( name );

  rc = xchat_list_int( static_plugin_handle, x_list, s_name );

  return INT2FIX( rc );
}


static VALUE static_ruby_xchat_emit_print( int    argc,
                                           VALUE *argv,
                                           VALUE  klass )
{
  char *event;
  char *parms[16];
  int   i;

printf( "[argc: %d]\n", argc );
  if( argc < 1 )
    return Qfalse;

  event = STR2CSTR( argv[0] );
  for( i = 1; i < 16; i++ )
  {
    if( i >= argc ) parms[i-1] = NULL;
    else parms[i-1] = STR2CSTR( argv[i] );
  }

  i = xchat_emit_print( static_plugin_handle,
                        event,
                        parms[ 0], parms[ 1], parms[ 2], parms[ 3],
                        parms[ 4], parms[ 5], parms[ 6], parms[ 7],
                        parms[ 8], parms[ 9], parms[10], parms[11],
                        parms[12], parms[13], parms[14], parms[15],
                        NULL );

  return ( i ? Qtrue : Qfalse );
}


static int static_ruby_custom_command_hook( char *word[],
                                            char *word_eol[],
                                            void *userdata )
{
  VALUE rb_word;
  VALUE rb_word_eol;
  VALUE rc;
  int   i;

  rb_word = rb_ary_new();
  rb_word_eol = rb_ary_new();

  for( i = 1; word[i][0] != '\0'; i++ )
  {
    rb_ary_push( rb_word, rb_str_new2( word[i] ) );
    rb_ary_push( rb_word_eol, rb_str_new2( word_eol[i] ) );
  }

  rc = rb_funcall( static_xchat_klass,
                   static_xchat_process_command_hook,
                   3,
                   rb_ary_entry( rb_word, 0 ),
                   rb_word,
                   rb_word_eol );

  return FIX2INT( rc );
}


static int static_ruby_custom_print_hook( char *word[],
                                          void *userdata )
{
  VALUE rb_name;
  VALUE rb_word;
  VALUE rc;
  int   i;

  rb_name = (VALUE)userdata;
  rb_word = rb_ary_new();

  for( i = 1; word[i] && word[i][0] != '\0'; i++ )
  {
    rb_ary_push( rb_word, rb_str_new2( word[i] ) );
  }

  rc = rb_funcall( static_xchat_klass,
                   static_xchat_process_print_hook,
                   2,
                   rb_name,
                   rb_word );

  return FIX2INT( rc );
}


static int static_ruby_custom_server_hook( char *word[],
                                           char *word_eol[],
                                           void *userdata )
{
  VALUE rb_word;
  VALUE rb_word_eol;
  VALUE rc;
  int   i;

  rb_word = rb_ary_new();
  rb_word_eol = rb_ary_new();

  for( i = 1; word[i][0] != '\0'; i++ )
  {
    rb_ary_push( rb_word, rb_str_new2( word[i] ) );
    rb_ary_push( rb_word_eol, rb_str_new2( word_eol[i] ) );
  }

  rc = rb_funcall( static_xchat_klass,
                   static_xchat_process_server_hook,
                   3,
                   rb_ary_entry( rb_word, 1 ),
                   rb_word,
                   rb_word_eol );

  return FIX2INT( rc );
}


static int static_ruby_custom_timer_hook( void *userdata )
{
  VALUE rc;
  VALUE name;

  name = (VALUE)userdata;

  rc = rb_funcall( static_xchat_klass,
                   static_xchat_process_timer_hook,
                   1,
                   name );

  return FIX2INT( rc );
}


static void static_free_xchat_list( xchat_list *list )
{
  xchat_list_free( static_plugin_handle, list );
}


int xchat_plugin_init(xchat_plugin *plugin_handle,
                      char **plugin_name,
                      char **plugin_desc,
                      char **plugin_version,
                      char *arg)
{
  ph = static_plugin_handle = plugin_handle;

  static_init_xchat_environment( plugin_handle,
                                 plugin_name,
                                 plugin_desc,
                                 plugin_version );

  static_init_ruby_environment();

  xchat_print( static_plugin_handle,
               "Ruby interface loaded\n" );

  return 1;
}


int xchat_plugin_deinit()
{
  rb_funcall( static_xchat_klass,
              rb_intern( "unregister" ),
              0 );

  return 1;
}
