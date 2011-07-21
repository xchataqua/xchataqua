# --------------------------------------------------------------------------
# xchat-ruby-plugin.rb -- core XChat/Ruby interface definition
# Copyright (C) 2003 Jamis Buck (jgb3@email.byu.edu)
# --------------------------------------------------------------------------
# This file is part of the XChat-Ruby plugin.
# 
# The  XChat-Ruby  plugin  is  free software; you can redistribute it and/or
# modify  it  under the terms of the GNU General Public License as published
# by  the  Free  Software  Foundation;  either  version 2 of the License, or
# (at your option) any later version.
# 
# The  XChat-Ruby  plugin is distributed in the hope that it will be useful,
# but   WITHOUT   ANY   WARRANTY;  without  even  the  implied  warranty  of
# MERCHANTABILITY  or  FITNESS  FOR  A  PARTICULAR  PURPOSE.   See  the  GNU
# General Public License for more details.
# 
# You  should  have  received  a  copy  of  the  GNU  General Public License
# along  with  the  XChat-Ruby  plugin;  if  not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# --------------------------------------------------------------------------
# These classes define the "core" XChat/Ruby interface for the plugin.  This
# entire  file  gets  converted  to  a  #define  in  a  header file (see the
# 'embedify.rb'  script  in  the  scripts directory), and then gets embedded
# in the plugin itself.
#
# Author: Jamis Buck (jgb3@email.byu.edu)
# Date: June 2003
# --------------------------------------------------------------------------

$xchat_global_eval_binding = binding

# Add some convenience methods to the Module class

class Module

  # This is necessary because we want to be able to load the contents of a file
  # and have them exist within a specific module.  The 'load' method of Kernel
  # won't do it (it loads it either into the global namespace, or into an
  # anonymous module), and 'eval' won't work either.  This solution, unfortunately,
  # does not preserve the filename for error handling, but works very well,
  # otherwise.

  def module_load( file )
    $LOAD_PATH.dup.unshift( "" ).each do |path|
      f = path + ( path.length > 0 ? "/" : "" ) + file
      if File.exist? f
        File.open( f, "r" ) do |fh|
          lines = fh.readlines.join
          module_eval lines
        end
        return true
      end
    end
    raise "could not load \"#{file}\""
  end

  # This returns a list of all the classes defined under this module.  (Why isn't
  # this a standard Module method?  Beats me...)

  def classes
    list = []
    constants.each do |v|
      c = const_get(v.intern)
      # I'm not sure why the check on c.name is necessary, but for some reason, all classes
      # are coming up, in all XChatRuby modules... :(  This just makes sure that no classes
      # are listed unless they are defined underneath THIS module.
      list.push c if c.class == Class && c.name =~ /#{self.name}/
    end
    list
  end

  # This creates a new, named module with a random name.  This is so that we can reference
  # the module by name.  Module.new, on the other hand, creates anonymous modules, which
  # have no name and hence cannot be referenced other than by their handle.

  def Module.new_random_module
    name = "XCHATRUBY_%08X" % [ rand( 0xFFFFFFFF ) ]
    eval "module #{name} end; #{name}", $xchat_global_eval_binding
  end
end


# This is the module that contains all of the Ruby/XChat interface routines.  Plugins
# may include this module for easier access to the classes defined within it.

module XChatRuby

  # A wrapper for a callback method.
  #   name:      the name of the callback
  #   pri:       the priority of the callback
  #   hook:      the callback itself
  #   hook_id:   the XChatHook object for this hook
  #   requester: the object that requested the hook be set.
  #   data:      custom data to be passed to the hook, when it is called.

  class XChatRubyCallback
    attr_reader :name
    attr_reader :pri
    attr_reader :hook
    attr_reader :hook_id
    attr_reader :requester
    attr_reader :data

    def initialize( name, pri, hook, hook_id, requester, data = nil )
      @name = name
      @pri = pri
      @hook = hook
      @hook_id = hook_id
      @requester = requester
      @data = data
    end
  end


  # Defines a loaded Ruby module
  #   filename: the name of the file that was loaded
  #   handle:   the Module object that encapsulates the loaded file

  class XChatRubyModule
    attr_reader :filename
    attr_reader :handle

    def initialize( filename, handle )
      @filename, @handle = filename, handle
    end
  end

  # This is a singleton that defines the core XChat/Ruby interface.  It keeps track
  # of all of the registered hooks of all of the loaded Ruby modules.  Loading and
  # unloading of Ruby modules is done via this interface.

  class XChatRubyEnvironment
    @@command_hooks = []
    @@print_hooks = []
    @@server_hooks = []
    @@timer_hooks = []

    @@registered = false

    @@loaded_modules = []

    # if a plugin does not define a global 'load_plugin' method, this is the default.
    # It simply instantiates all classes in the module that inherit from
    # XChatRubyPlugin.  This module function gets called when the module is loaded.

    DEFAULT_LOAD_PLUGIN = <<-EOSTR
      def load_plugin
        classes.each do |c|
          next if not c.ancestors.include? XChatRuby::XChatRubyPlugin
          c.new
        end
      end
    EOSTR

    # if a plugin does not define a global 'unload_plugin' method, this is the default.
    # It simply calls the 'unload_plugin' method of all active plugins in the current
    # module.  This module function gets called when the module is unloaded.

    DEFAULT_UNLOAD_PLUGIN = <<-EOSTR
      def unload_plugin
        classes.each do |c|
          next if not c.ancestors.include? XChatRuby::XChatRubyPlugin
          ObjectSpace.each_object( c ) { |obj| obj.unload_plugin }
        end
      end
    EOSTR

    # This is called by the XChat-Ruby plugin itself when it is loaded, to initialize
    # the environment.  It is guarded by a sentry, so it cannot be called more than once.
    # It initializes the ruby environment and creates the default "RB" plugin, with which
    # users can interact with the Ruby plugin.  Lastly, it attempts to load all .rb
    # files in the user's xchat2 directory.

    def XChatRubyEnvironment.register
      return if @@registered
      @@registered = true

      initialize_ruby_environment

      @@rb_plugin = XChatRubyRBPlugin.new

      load_ruby_plugins
    end

    # This is called when the XChat-Ruby plugin gets unloaded.  It basically stops all
    # running ruby plugins and removes all hooks registered by a ruby plugin.

    def XChatRubyEnvironment.unregister
      # unregister the RB plugin
      remove_hooks_for( @@rb_plugin )

      # unregister all other Ruby plugins
      @@loaded_modules.each { |mod| mod.handle.unload_plugin }

      # now, make sure that any remaining hooks got unregistered
      @@command_hooks.each { |hook| internal_xchat_unhook( hook.hook_id ) }
      @@print_hooks.each { |hook| internal_xchat_unhook( hook.hook_id ) }
      @@server_hooks.each { |hook| internal_xchat_unhook( hook.hook_id ) }
      @@timer_hooks.each { |hook| internal_xchat_unhook( hook.hook_id ) }

      @@command_hooks = []
      @@print_hooks = []
      @@server_hooks = []
      @@timer_hooks = []
    end

    # The following routines simply manage the registration of callback hooks.

    def XChatRubyEnvironment.hook_command( name, priority, hook, help, requester, data = nil )
      add_new_hook( @@command_hooks, name, priority, hook, requester,
                    internal_xchat_hook_command( name, priority, help ), data )
    end

    def XChatRubyEnvironment.hook_print( name, priority, hook, requester, data = nil )
      add_new_hook( @@print_hooks, name, priority,
                    hook, requester, internal_xchat_hook_print( name, priority ), data )
    end

    def XChatRubyEnvironment.hook_server( name, priority, hook, requester, data = nil )
      add_new_hook( @@server_hooks, name, priority,
                    hook, requester, internal_xchat_hook_server( name, priority ), data )
    end

    def XChatRubyEnvironment.hook_timer( timeout, hook, requester, data = nil )
      now = Time.now
      name = "#{now.to_i}+#{now.usec}"
      add_new_hook( @@timer_hooks, name, 0, hook, requester, internal_xchat_hook_timer( name, timeout ), data )
    end

    # This removes all registered hooks for the given requester.  It is typically called only by the
    # unload_plugin method of XChatRubyPlugin.

    def XChatRubyEnvironment.remove_hooks_for( requester )
      @@command_hooks.find_all { |h| h.requester == requester } .each { |h| delete_hook( @@command_hooks, h ) }
      @@print_hooks.find_all { |h| h.requester == requester } .each { |h| delete_hook( @@print_hooks, h ) }
      @@server_hooks.find_all { |h| h.requester == requester } .each { |h| delete_hook( @@server_hooks, h ) }
      @@timer_hooks.find_all { |h| h.requester == requester } .each { |h| delete_hook( @@timer_hooks, h ) }
    end

    # This unregisters the given hook.

    def XChatRubyEnvironment.unhook( hook_id )
      @@command_hooks.each do |h|
        if h.hook_id == hook_id
          delete_hook( @@command_hooks, h )
          return
        end
      end

      @@print_hooks.each do |h|
        if h.hook_id == hook_id
          delete_hook( @@print_hooks, h )
          return
        end
      end

      @@server_hooks.each do |h|
        if h.hook_id == hook_id
          delete_hook( @@server_hooks, h )
          return
        end
      end

      @@timer_hooks.each do |h|
        if h.hook_id == hook_id
          delete_hook( @@timer_hooks, h )
          return
        end
      end
    end

    # print( text )
    #   Prints the given text.
    #
    # print( text, channel )
    #   Prints the given text to the tab/window for the given channel
    #
    # print( text, server, channel )
    #   Prints the given text to the tab/window for the given server and channel

    def XChatRubyEnvironment.print( *args )
      return if args.length < 1

      ctx = nil
      if args.length == 2
        ctx = find_context( nil, args[1] )
      elsif args.length == 3
        ctx = find_context( args[1], args[2] )
      end

      set_context( ctx ) if ctx != nil
      internal_xchat_print( args[0].to_s )
    end

    # Same as print (above), but appends a newline.

    def XChatRubyEnvironment.puts( *args )
      args.push "" if args.length == 0
      args[0] = args[0] + "\n"
      print( *args );
    end

    # Loads the given file as a plugin.  If the filename is already loaded, it is unloaded
    # before proceeding, making this a safe way to reload a plugin.

    def XChatRubyEnvironment.load_plugin( filename )
      unload_plugin( filename )

      mod = Module.new_random_module
      mod.module_load filename

      # make sure the load_plugin and unload_plugin methods exist, one way or another.

      if not mod.method_defined? :load_plugin
        mod.module_eval DEFAULT_LOAD_PLUGIN
      end

      if not mod.method_defined? :unload_plugin
        mod.module_eval DEFAULT_UNLOAD_PLUGIN
      end

      @@loaded_modules.push XChatRubyModule.new( filename, mod )

      mod.module_eval "module_function :load_plugin"
      mod.module_eval "module_function :unload_plugin"
      mod.load_plugin
    end

    # Unloads the given plugin, if it is loaded.  Returns false if the plugin was
    # not loaded, and true if it was.

    def XChatRubyEnvironment.unload_plugin( filename )
      mod = @@loaded_modules.find { |m| m.filename == filename }
      return false if !mod
      mod.handle.unload_plugin
      @@loaded_modules.delete mod
      return true
    end

    # Prints the list of available ruby-based commands to the current tab/window.

    def XChatRubyEnvironment.list_commands
      puts "Loaded ruby commands:"
      i = 1
      @@command_hooks.each do |hook|
        puts "  #{i}) #{hook.name}"
        i += 1
      end
    end

    # Prints the list of loaded ruby modules to the current tab/window.

    def XChatRubyEnvironment.list_modules
      if @@loaded_modules.length < 1
        puts "There are no loaded ruby modules."
      else
        puts "Loaded ruby modules:"
        i = 1
        @@loaded_modules.each do |mod|
          puts "  #{i}) #{mod.filename}"
          i += 1
        end
      end
    end

    # -- PRIVATE --------------------------------------------------------------

    def XChatRubyEnvironment.add_new_hook( hooks, name, pri, hook, requester, id, data )
      hooks.push XChatRubyCallback.new( name, pri, hook, id, requester, data )
      hooks.sort! { |a,b| -( a.pri <=> b.pri ) }
      return id
    end

    def XChatRubyEnvironment.delete_hook( hooks, hook )
      internal_xchat_unhook( hook.hook_id )
      hooks.delete hook
    end

    def XChatRubyEnvironment.process_command_hook( name, words, words_eol )
      return process_hook( @@command_hooks, name ) { |h| h.hook.call( words, words_eol, h.data ) }
    end

    def XChatRubyEnvironment.process_print_hook( name, words )
      return process_hook( @@print_hooks, name ) { |h| h.hook.call( words, h.data ) }
    end

    def XChatRubyEnvironment.process_server_hook( name, words, words_eol )
      return process_hook( @@server_hooks, name ) { |h| h.hook.call( words, words_eol, h.data ) }
    end

    def XChatRubyEnvironment.process_timer_hook( name )
      return process_hook( @@timer_hooks, name ) { |h| h.hook.call( h.data ) }
    end

    def XChatRubyEnvironment.process_hook( hooks, name )
      how_to_return = XChatRubyPlugin::XCHAT_EAT_NONE

      hooks.each do |hook|
        if hook.name.downcase == name.downcase
          begin
            case ( rc = yield hook )
              when XChatRubyPlugin::XCHAT_EAT_ALL, XChatRubyPlugin::XCHAT_EAT_PLUGIN then
                return rc
              when XChatRubyPlugin::XCHAT_EAT_XCHAT then
                how_to_return = rc
            end
          rescue Exception => detail
            puts "Ruby error executing hook '#{name}': #{detail.message}"
            puts "  " + detail.backtrace.join( "\n  " )
          end
        end
      end

      return how_to_return
    end

    def XChatRubyEnvironment.initialize_ruby_environment
      envfile = get_info( "xchatdir" ) + "/rubyenv"
      begin
        File.open( envfile, "r" ) do |file|
          file.each do |line|
            line.chomp!
            $LOAD_PATH.push line
          end
        end
      rescue Exception => detail
        puts "The ruby environment file '#{envfile}' could not be found."
        puts "Ruby modules will not be able to access any extension modules."
        $LOAD_PATH.push "."
      end
    end

    def XChatRubyEnvironment.load_ruby_plugins
      envdir = get_info( "xchatdir" )
      Dir.foreach( envdir ) do |f|
        next if f !~ /\.rb$/
        begin
          load_plugin envdir + "/" + f
        rescue Exception => detail
          puts "  Couldn't load #{envdir}/#{f} (#{detail.message})"
        end
      end
    end

    private_class_method :add_new_hook, :delete_hook, :process_command_hook
    private_class_method :process_print_hook, :process_server_hook, :process_timer_hook
    private_class_method :process_hook, :initialize_ruby_environment, :load_ruby_plugins
  end


  # Encapsulates the functionality of the xchat_list API.  (See the XChat2 Plugin documentation
  # for more details.)

  class XChatRubyList
    def initialize( name )
      @listh = internal_xchat_list_get( name );
    end

    def next
      internal_xchat_list_next( @listh )
    end

    def str( name )
      internal_xchat_list_str( @listh, name )
    end

    def int( name )
      internal_xchat_list_int( @listh, name )
    end
  end


  # The base class for all XChat-Ruby plugins.  All plugins should inherit from this
  # class.  The 'initialize' for each plugin should be where all necessary hooks are
  # registered.  If any special functionality is needed when the plugin is unloaded,
  # the 'unload_plugin' method should be extended (but the child class should be sure
  # to call 'super', so that the default functionality is still executed.)

  class XChatRubyPlugin
    XCHAT_PRI_HIGHEST  = 127
    XCHAT_PRI_HIGH     = 64
    XCHAT_PRI_NORM     = 0
    XCHAT_PRI_LOW      = -64
    XCHAT_PRI_LOWEST   = -128

    XCHAT_FD_READ      = 1
    XCHAT_FD_WRITE     = 2
    XCHAT_FD_EXCEPTION = 4
    XCHAT_FD_NOTSOCKET = 8

    XCHAT_EAT_NONE     = 0
    XCHAT_EAT_XCHAT    = 1
    XCHAT_EAT_PLUGIN   = 2
    XCHAT_EAT_ALL      = ( XCHAT_EAT_NONE | XCHAT_EAT_XCHAT | XCHAT_EAT_PLUGIN )

    def unload_plugin
      XChatRubyEnvironment.remove_hooks_for( self )
    end

    def hook_command( name, priority, hook, help, data = nil )
      XChatRubyEnvironment.hook_command( name, priority, hook, help, self, data )
    end

    def hook_print( name, priority, hook, data = nil )
      XChatRubyEnvironment.hook_print( name, priority, hook, self, data )
    end

    def hook_server( name, priority, hook, data = nil )
      XChatRubyEnvironment.hook_server( name, priority, hook, self, data )
    end

    def hook_timer( timeout, hook, data = nil )
      XChatRubyEnvironment.hook_timer( timeout, hook, self, data )
    end

    def unhook( hook_id )
      XChatRubyEnvironment.unhook( hook_id )
    end

    def print( *args )
      XChatRubyEnvironment.print( *args )
    end

    def puts( *args )
      XChatRubyEnvironment.puts( *args )
    end

    # Same as print (above), but formats the text with 'format' (below).

    def print_fmt( *args )
      return if args.length < 1
      args[0] = format( args[0] )
      return print( *args )
    end

    # Same as print_fmt (above), but appends a newline.

    def puts_fmt( *args )
      args[0] = ( args[0] ? format( args[0] ) : "" )
      return puts( *args )
    end

    def command( command )
      XChatRubyEnvironment.command( command )
    end

    def get_info( id )
      XChatRubyEnvironment.get_info( id )
    end

    def get_prefs( name )
      XChatRubyEnvironment.get_pres( name )
    end

    def nickcmp( s1, s2 )
      XChatRubyEnvironment.nickcmp( s1, s2 )
    end

    def emit_print( event_name, *args )
      XChatRubyEnvironment.emit_print( event_name, *args )
    end

    # these are the supported colors

    WHITE = 0
    BLACK = 1
    BLUE  = 2
    NAVY  = 2
    GREEN = 3
    RED   = 4
    BROWN = 5
    MAROON = 5
    PURPLE = 6
    ORANGE = 7
    OLIVE = 7
    YELLOW = 8
    LT_GREEN = 9
    LIME = 9
    TEAL = 10
    LT_CYAN = 11
    AQUA = 11
    LT_BLUE = 12
    ROYAL = 12
    PINK = 13
    LT_PURPLE = 13
    FUCHSIA = 13
    GREY = 14
    LT_GREY = 15
    SILVER = 15
    
    # a reverse mapping, from color name to number

    COLORS = { 'white'    => WHITE,
               'black'    => BLACK,
               'blue'     => BLUE,
               'green'    => GREEN,
               'red'      => RED,
               'brown'    => BROWN,
               'purple'   => PURPLE,
               'orange'   => ORANGE,
               'yellow'   => YELLOW,
               'ltgreen'  => LT_GREEN,
               'teal'     => TEAL,
               'ltcyan'   => LT_CYAN,
               'ltblue'   => LT_BLUE,
               'pink'     => PINK,
               'grey'     => GREY,
               'ltgrey'   => LT_GREY }


    # formats the given text string.  Formatting codes are
    # prefixed with ![ and terminated with ].  Each ![...]
    # block may contain multiple formatting codes.  The supported
    # codes are:
    #
    #   b    : toggle bold
    #   u    : toggle underline
    #   o    : reset all attributes
    #   r    : toggle reverse text
    #   c    : reset text color back to the defaults
    #   i    : toggle italics
    #   |    : (pipe character) puts all preceding text in the gutter
    #   cn   : set the foreground color to #
    #   cn,n : set both the foreground and background colors
    #
    # 'n' (with the c code) may be either a number, or the name
    # of a color in parentheses.  For example:
    #
    #   ![c(red)b]This is bold,red![cb]

    def format( text )
      text.gsub( /!\[(.*?)\]/ ) do |match|
        codes = $1.downcase
        repl = ""
        i = 0
        while i < codes.length
          case codes[i].chr
            when 'b'
              repl << 2.chr
            when 'o'
              repl << 15.chr
            when 'r'
              repl << 18.chr
            when 'u'
              repl << 31.chr
            when 'i'
              repl << 29.chr
            when '|'
              repl << 9.chr
            when 'c'
              bg = nil

              i, fg = extract_color( i+1, codes )
              i, bg = extract_color( i+1, codes ) if i < codes.length && codes[i].chr == ','

              repl << "" << ( fg || "" )
              repl << "," << bg if bg

              i -= 1
          end

          i += 1
        end
        repl
      end
    end

    private

      def extract_color( i, s )
        return [ i, nil ] if i >= s.length

        if s[i].chr == '('
          j = s.index( ')', i )
          return [ j+1, "%02d" % COLORS[ s[i+1..j-1].downcase ] ]
        end

        j = i
        j += 1 while j < s.length && s[j].chr =~ /[0-9]/
        j += 1 if j == s.length
        return [ j, "%02d" % s[i..j-1].to_i ]
      end
  end


  # This is the default "RB" plugin, which supports the "RB", "LOAD", and "UNLOAD" commands.
  # This is the means by which users will interact with the ruby plugin.

  class XChatRubyRBPlugin < XChatRubyPlugin
    def initialize
      hook_command( "RB", XCHAT_PRI_NORM, method( :rb_command_hook ),
                    "Usage: /RB LOAD    <filename> : load the given Ruby script as a plugin\n" +
                    "           UNLOAD  <filename> : unload the given Ruby script\n" +
                    "           COMMANDS           : show all registered Ruby-plugin commands\n" +
                    "           LIST               : list all loaded Ruby plugins\n" +
                    "           EXEC    <command>  : execute the given Ruby code\n" +
                    "           ABOUT              : describe this plugin" )

      hook_command( "LOAD", XCHAT_PRI_NORM, method( :rb_load ),
                    "Usage: LOAD <file>, loads a plugin or script" )

      hook_command( "UNLOAD", XCHAT_PRI_NORM, method( :rb_unload ),
                    "Usage: UNLOAD <file>, unloads a plugin or script" )
    end

    def rb_command_hook( words, words_eol, data )
      words = "" if words == nil
      case words[1].downcase
        when "" then
          puts "You must specify the RB command to invoke"

        when "load" then
          return rb_command_load( words, words_eol, data )

        when "unload" then
          return rb_command_unload( words, words_eol, data )

        when "list" then
          return rb_plugins_list( words, words_eol, data )

        when "commands" then
          return rb_command_list( words, words_eol, data )

        when "exec" then
          return rb_command_exec( words, words_eol, data )

        when "about" then
          return rb_command_about( words, words_eol, data )

        else
          puts "Unknown RB command: #{words[1]}"
      end

      return XCHAT_EAT_ALL
    end

    def rb_load( words, words_eol, data )
      f = words_eol[1]
      return XCHAT_EAT_NONE if !f or f !~ /\.rb$/

      XChatRubyEnvironment.load_plugin f

      return XCHAT_EAT_ALL
    end

    def rb_unload( words, words_eol, data )
      f = words_eol[1]
      return XCHAT_EAT_NONE if !f or f !~ /\.rb$/

      if !XChatRubyEnvironment.unload_plugin( f )
        puts "The given plugin (#{f}) does not appear to be loaded."
      else
        puts "#{f} has been unloaded."
      end

      return XCHAT_EAT_ALL
    end

    def rb_command_load( words, words_eol, data )
      file = words_eol[2]
      if !file
        puts "You must specify a file to load."
      else
        XChatRubyEnvironment.load_plugin file
      end

      return XCHAT_EAT_ALL
    end

    def rb_command_unload( words, words_eol, data )
      file = words_eol[2]
      if !file
        puts "You must specify a file to unload (it should be the same filename and path given in /rb list)."
      else
        if !XChatRubyEnvironment.unload_plugin( file )
          puts "The given plugin (#{file}) does not appear to be loaded."
        else
          puts "#{file} has been unloaded."
        end
      end

      return XCHAT_EAT_ALL
    end

    def rb_plugins_list( words, words_eol, data )
      XChatRubyEnvironment.list_modules

      return XCHAT_EAT_ALL
    end

    def rb_command_list( words, words_eol, data )
      XChatRubyEnvironment.list_commands

      return XCHAT_EAT_ALL
    end

    def rb_command_exec( words, words_eol, data )
      if !words_eol[2]
        puts "You must specify some ruby code to execute."
      else
        eval words_eol[2], $xchat_global_binding, "(/rb exec)"
      end

      return XCHAT_EAT_ALL
    end

    def rb_command_about( words, words_eol, data )
      puts
      puts format( "-![c(red)b]*![bc]------------------------------------------------" )
      puts format( "X-Chat ![bc(red)]Ruby![bc] Interface 1.1" )
      puts
      puts format( "Copyright (c) 2003 ![bc(yellow)]Jamis Buck![bc] <jgb3@email.byu.edu>" )
      puts format( "------------------------------------------------![bc(red)]*![cb]-" )
      puts

      return XCHAT_EAT_ALL
    end
    
  end
end
