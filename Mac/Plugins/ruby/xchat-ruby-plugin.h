/* this is a generated file.  DO NOT MODIFY IT!  Instead, modify
 * xchat-ruby-plugin.rb and regenerate this file.
 */

#ifndef __XCHAT_RUBY_PLUGIN_H__
#define __XCHAT_RUBY_PLUGIN_H__

#define XCHAT_RUBY_PLUGIN \
    "$xchat_global_eval_binding = binding\n" \
    "class Module\n" \
    "def module_load( file )\n" \
    "$LOAD_PATH.dup.unshift( \"\" ).each do |path|\n" \
    "f = path + ( path.length > 0 ? \"/\" : \"\" ) + file\n" \
    "if File.exist? f\n" \
    "File.open( f, \"r\" ) do |fh|\n" \
    "lines = fh.readlines.join\n" \
    "module_eval lines\n" \
    "end\n" \
    "return true\n" \
    "end\n" \
    "end\n" \
    "raise \"could not load \\\"#{file}\\\"\"\n" \
    "end\n" \
    "def classes\n" \
    "list = []\n" \
    "constants.each do |v|\n" \
    "c = const_get(v.intern)\n" \
    "list.push c if c.class == Class && c.name =~ /#{self.name}/\n" \
    "end\n" \
    "list\n" \
    "end\n" \
    "def Module.new_random_module\n" \
    "name = \"XCHATRUBY_%08X\" % [ rand( 0xFFFFFFFF ) ]\n" \
    "eval \"module #{name} end; #{name}\", $xchat_global_eval_binding\n" \
    "end\n" \
    "end\n" \
    "module XChatRuby\n" \
    "class XChatRubyCallback\n" \
    "attr_reader :name\n" \
    "attr_reader :pri\n" \
    "attr_reader :hook\n" \
    "attr_reader :hook_id\n" \
    "attr_reader :requester\n" \
    "attr_reader :data\n" \
    "def initialize( name, pri, hook, hook_id, requester, data = nil )\n" \
    "@name = name\n" \
    "@pri = pri\n" \
    "@hook = hook\n" \
    "@hook_id = hook_id\n" \
    "@requester = requester\n" \
    "@data = data\n" \
    "end\n" \
    "end\n" \
    "class XChatRubyModule\n" \
    "attr_reader :filename\n" \
    "attr_reader :handle\n" \
    "def initialize( filename, handle )\n" \
    "@filename, @handle = filename, handle\n" \
    "end\n" \
    "end\n" \
    "class XChatRubyEnvironment\n" \
    "@@command_hooks = []\n" \
    "@@print_hooks = []\n" \
    "@@server_hooks = []\n" \
    "@@timer_hooks = []\n" \
    "@@registered = false\n" \
    "@@loaded_modules = []\n" \
    "DEFAULT_LOAD_PLUGIN = <<-EOSTR\n" \
    "def load_plugin\n" \
    "classes.each do |c|\n" \
    "next if not c.ancestors.include? XChatRuby::XChatRubyPlugin\n" \
    "c.new\n" \
    "end\n" \
    "end\n" \
    "EOSTR\n" \
    "DEFAULT_UNLOAD_PLUGIN = <<-EOSTR\n" \
    "def unload_plugin\n" \
    "classes.each do |c|\n" \
    "next if not c.ancestors.include? XChatRuby::XChatRubyPlugin\n" \
    "ObjectSpace.each_object( c ) { |obj| obj.unload_plugin }\n" \
    "end\n" \
    "end\n" \
    "EOSTR\n" \
    "def XChatRubyEnvironment.register\n" \
    "return if @@registered\n" \
    "@@registered = true\n" \
    "initialize_ruby_environment\n" \
    "@@rb_plugin = XChatRubyRBPlugin.new\n" \
    "load_ruby_plugins\n" \
    "end\n" \
    "def XChatRubyEnvironment.unregister\n" \
    "remove_hooks_for( @@rb_plugin )\n" \
    "@@loaded_modules.each { |mod| mod.handle.unload_plugin }\n" \
    "@@command_hooks.each { |hook| internal_xchat_unhook( hook.hook_id ) }\n" \
    "@@print_hooks.each { |hook| internal_xchat_unhook( hook.hook_id ) }\n" \
    "@@server_hooks.each { |hook| internal_xchat_unhook( hook.hook_id ) }\n" \
    "@@timer_hooks.each { |hook| internal_xchat_unhook( hook.hook_id ) }\n" \
    "@@command_hooks = []\n" \
    "@@print_hooks = []\n" \
    "@@server_hooks = []\n" \
    "@@timer_hooks = []\n" \
    "end\n" \
    "def XChatRubyEnvironment.hook_command( name, priority, hook, help, requester, data = nil )\n" \
    "add_new_hook( @@command_hooks, name, priority, hook, requester,\n" \
    "internal_xchat_hook_command( name, priority, help ), data )\n" \
    "end\n" \
    "def XChatRubyEnvironment.hook_print( name, priority, hook, requester, data = nil )\n" \
    "add_new_hook( @@print_hooks, name, priority,\n" \
    "hook, requester, internal_xchat_hook_print( name, priority ), data )\n" \
    "end\n" \
    "def XChatRubyEnvironment.hook_server( name, priority, hook, requester, data = nil )\n" \
    "add_new_hook( @@server_hooks, name, priority,\n" \
    "hook, requester, internal_xchat_hook_server( name, priority ), data )\n" \
    "end\n" \
    "def XChatRubyEnvironment.hook_timer( timeout, hook, requester, data = nil )\n" \
    "now = Time.now\n" \
    "name = \"#{now.to_i}+#{now.usec}\"\n" \
    "add_new_hook( @@timer_hooks, name, 0, hook, requester, internal_xchat_hook_timer( name, timeout ), data )\n" \
    "end\n" \
    "def XChatRubyEnvironment.remove_hooks_for( requester )\n" \
    "@@command_hooks.find_all { |h| h.requester == requester } .each { |h| delete_hook( @@command_hooks, h ) }\n" \
    "@@print_hooks.find_all { |h| h.requester == requester } .each { |h| delete_hook( @@print_hooks, h ) }\n" \
    "@@server_hooks.find_all { |h| h.requester == requester } .each { |h| delete_hook( @@server_hooks, h ) }\n" \
    "@@timer_hooks.find_all { |h| h.requester == requester } .each { |h| delete_hook( @@timer_hooks, h ) }\n" \
    "end\n" \
    "def XChatRubyEnvironment.unhook( hook_id )\n" \
    "@@command_hooks.each do |h|\n" \
    "if h.hook_id == hook_id\n" \
    "delete_hook( @@command_hooks, h )\n" \
    "return\n" \
    "end\n" \
    "end\n" \
    "@@print_hooks.each do |h|\n" \
    "if h.hook_id == hook_id\n" \
    "delete_hook( @@print_hooks, h )\n" \
    "return\n" \
    "end\n" \
    "end\n" \
    "@@server_hooks.each do |h|\n" \
    "if h.hook_id == hook_id\n" \
    "delete_hook( @@server_hooks, h )\n" \
    "return\n" \
    "end\n" \
    "end\n" \
    "@@timer_hooks.each do |h|\n" \
    "if h.hook_id == hook_id\n" \
    "delete_hook( @@timer_hooks, h )\n" \
    "return\n" \
    "end\n" \
    "end\n" \
    "end\n" \
    "def XChatRubyEnvironment.print( *args )\n" \
    "return if args.length < 1\n" \
    "ctx = nil\n" \
    "if args.length == 2\n" \
    "ctx = find_context( nil, args[1] )\n" \
    "elsif args.length == 3\n" \
    "ctx = find_context( args[1], args[2] )\n" \
    "end\n" \
    "set_context( ctx ) if ctx != nil\n" \
    "internal_xchat_print( args[0].to_s )\n" \
    "end\n" \
    "def XChatRubyEnvironment.puts( *args )\n" \
    "args.push \"\" if args.length == 0\n" \
    "args[0] = args[0] + \"\\n\"\n" \
    "print( *args );\n" \
    "end\n" \
    "def XChatRubyEnvironment.load_plugin( filename )\n" \
    "unload_plugin( filename )\n" \
    "mod = Module.new_random_module\n" \
    "mod.module_load filename\n" \
    "if not mod.method_defined? :load_plugin\n" \
    "mod.module_eval DEFAULT_LOAD_PLUGIN\n" \
    "end\n" \
    "if not mod.method_defined? :unload_plugin\n" \
    "mod.module_eval DEFAULT_UNLOAD_PLUGIN\n" \
    "end\n" \
    "@@loaded_modules.push XChatRubyModule.new( filename, mod )\n" \
    "mod.module_eval \"module_function :load_plugin\"\n" \
    "mod.module_eval \"module_function :unload_plugin\"\n" \
    "mod.load_plugin\n" \
    "end\n" \
    "def XChatRubyEnvironment.unload_plugin( filename )\n" \
    "mod = @@loaded_modules.find { |m| m.filename == filename }\n" \
    "return false if !mod\n" \
    "mod.handle.unload_plugin\n" \
    "@@loaded_modules.delete mod\n" \
    "return true\n" \
    "end\n" \
    "def XChatRubyEnvironment.list_commands\n" \
    "puts \"Loaded ruby commands:\"\n" \
    "i = 1\n" \
    "@@command_hooks.each do |hook|\n" \
    "puts \"  #{i}) #{hook.name}\"\n" \
    "i += 1\n" \
    "end\n" \
    "end\n" \
    "def XChatRubyEnvironment.list_modules\n" \
    "if @@loaded_modules.length < 1\n" \
    "puts \"There are no loaded ruby modules.\"\n" \
    "else\n" \
    "puts \"Loaded ruby modules:\"\n" \
    "i = 1\n" \
    "@@loaded_modules.each do |mod|\n" \
    "puts \"  #{i}) #{mod.filename}\"\n" \
    "i += 1\n" \
    "end\n" \
    "end\n" \
    "end\n" \
    "def XChatRubyEnvironment.add_new_hook( hooks, name, pri, hook, requester, id, data )\n" \
    "hooks.push XChatRubyCallback.new( name, pri, hook, id, requester, data )\n" \
    "hooks.sort! { |a,b| -( a.pri <=> b.pri ) }\n" \
    "return id\n" \
    "end\n" \
    "def XChatRubyEnvironment.delete_hook( hooks, hook )\n" \
    "internal_xchat_unhook( hook.hook_id )\n" \
    "hooks.delete hook\n" \
    "end\n" \
    "def XChatRubyEnvironment.process_command_hook( name, words, words_eol )\n" \
    "return process_hook( @@command_hooks, name ) { |h| h.hook.call( words, words_eol, h.data ) }\n" \
    "end\n" \
    "def XChatRubyEnvironment.process_print_hook( name, words )\n" \
    "return process_hook( @@print_hooks, name ) { |h| h.hook.call( words, h.data ) }\n" \
    "end\n" \
    "def XChatRubyEnvironment.process_server_hook( name, words, words_eol )\n" \
    "return process_hook( @@server_hooks, name ) { |h| h.hook.call( words, words_eol, h.data ) }\n" \
    "end\n" \
    "def XChatRubyEnvironment.process_timer_hook( name )\n" \
    "return process_hook( @@timer_hooks, name ) { |h| h.hook.call( h.data ) }\n" \
    "end\n" \
    "def XChatRubyEnvironment.process_hook( hooks, name )\n" \
    "how_to_return = XChatRubyPlugin::XCHAT_EAT_NONE\n" \
    "hooks.each do |hook|\n" \
    "if hook.name.downcase == name.downcase\n" \
    "begin\n" \
    "case ( rc = yield hook )\n" \
    "when XChatRubyPlugin::XCHAT_EAT_ALL, XChatRubyPlugin::XCHAT_EAT_PLUGIN then\n" \
    "return rc\n" \
    "when XChatRubyPlugin::XCHAT_EAT_XCHAT then\n" \
    "how_to_return = rc\n" \
    "end\n" \
    "rescue Exception => detail\n" \
    "puts \"Ruby error executing hook '#{name}': #{detail.message}\"\n" \
    "puts \"  \" + detail.backtrace.join( \"\\n  \" )\n" \
    "end\n" \
    "end\n" \
    "end\n" \
    "return how_to_return\n" \
    "end\n" \
    "def XChatRubyEnvironment.initialize_ruby_environment\n" \
    "envfile = get_info( \"xchatdir\" ) + \"/rubyenv\"\n" \
    "begin\n" \
    "File.open( envfile, \"r\" ) do |file|\n" \
    "file.each do |line|\n" \
    "line.chomp!\n" \
    "$LOAD_PATH.push line\n" \
    "end\n" \
    "end\n" \
    "rescue Exception => detail\n" \
    "puts \"The ruby environment file '#{envfile}' could not be found.\"\n" \
    "puts \"Ruby modules will not be able to access any extension modules.\"\n" \
    "$LOAD_PATH.push \".\"\n" \
    "end\n" \
    "end\n" \
    "def XChatRubyEnvironment.load_ruby_plugins\n" \
    "envdir = get_info( \"xchatdir\" )\n" \
    "Dir.foreach( envdir ) do |f|\n" \
    "next if f !~ /\\.rb$/\n" \
    "begin\n" \
    "load_plugin envdir + \"/\" + f\n" \
    "rescue Exception => detail\n" \
    "puts \"  Couldn't load #{envdir}/#{f} (#{detail.message})\"\n" \
    "end\n" \
    "end\n" \
    "end\n" \
    "private_class_method :add_new_hook, :delete_hook, :process_command_hook\n" \
    "private_class_method :process_print_hook, :process_server_hook, :process_timer_hook\n" \
    "private_class_method :process_hook, :initialize_ruby_environment, :load_ruby_plugins\n" \
    "end\n" \
    "class XChatRubyList\n" \
    "def initialize( name )\n" \
    "@listh = internal_xchat_list_get( name );\n" \
    "end\n" \
    "def next\n" \
    "internal_xchat_list_next( @listh )\n" \
    "end\n" \
    "def str( name )\n" \
    "internal_xchat_list_str( @listh, name )\n" \
    "end\n" \
    "def int( name )\n" \
    "internal_xchat_list_int( @listh, name )\n" \
    "end\n" \
    "end\n" \
    "class XChatRubyPlugin\n" \
    "XCHAT_PRI_HIGHEST  = 127\n" \
    "XCHAT_PRI_HIGH     = 64\n" \
    "XCHAT_PRI_NORM     = 0\n" \
    "XCHAT_PRI_LOW      = -64\n" \
    "XCHAT_PRI_LOWEST   = -128\n" \
    "XCHAT_FD_READ      = 1\n" \
    "XCHAT_FD_WRITE     = 2\n" \
    "XCHAT_FD_EXCEPTION = 4\n" \
    "XCHAT_FD_NOTSOCKET = 8\n" \
    "XCHAT_EAT_NONE     = 0\n" \
    "XCHAT_EAT_XCHAT    = 1\n" \
    "XCHAT_EAT_PLUGIN   = 2\n" \
    "XCHAT_EAT_ALL      = ( XCHAT_EAT_NONE | XCHAT_EAT_XCHAT | XCHAT_EAT_PLUGIN )\n" \
    "def unload_plugin\n" \
    "XChatRubyEnvironment.remove_hooks_for( self )\n" \
    "end\n" \
    "def hook_command( name, priority, hook, help, data = nil )\n" \
    "XChatRubyEnvironment.hook_command( name, priority, hook, help, self, data )\n" \
    "end\n" \
    "def hook_print( name, priority, hook, data = nil )\n" \
    "XChatRubyEnvironment.hook_print( name, priority, hook, self, data )\n" \
    "end\n" \
    "def hook_server( name, priority, hook, data = nil )\n" \
    "XChatRubyEnvironment.hook_server( name, priority, hook, self, data )\n" \
    "end\n" \
    "def hook_timer( timeout, hook, data = nil )\n" \
    "XChatRubyEnvironment.hook_timer( timeout, hook, self, data )\n" \
    "end\n" \
    "def unhook( hook_id )\n" \
    "XChatRubyEnvironment.unhook( hook_id )\n" \
    "end\n" \
    "def print( *args )\n" \
    "XChatRubyEnvironment.print( *args )\n" \
    "end\n" \
    "def puts( *args )\n" \
    "XChatRubyEnvironment.puts( *args )\n" \
    "end\n" \
    "def print_fmt( *args )\n" \
    "return if args.length < 1\n" \
    "args[0] = format( args[0] )\n" \
    "return print( *args )\n" \
    "end\n" \
    "def puts_fmt( *args )\n" \
    "args[0] = ( args[0] ? format( args[0] ) : \"\" )\n" \
    "return puts( *args )\n" \
    "end\n" \
    "def command( command )\n" \
    "XChatRubyEnvironment.command( command )\n" \
    "end\n" \
    "def get_info( id )\n" \
    "XChatRubyEnvironment.get_info( id )\n" \
    "end\n" \
    "def get_prefs( name )\n" \
    "XChatRubyEnvironment.get_pres( name )\n" \
    "end\n" \
    "def nickcmp( s1, s2 )\n" \
    "XChatRubyEnvironment.nickcmp( s1, s2 )\n" \
    "end\n" \
    "def emit_print( event_name, *args )\n" \
    "XChatRubyEnvironment.emit_print( event_name, *args )\n" \
    "end\n" \
    "WHITE = 0\n" \
    "BLACK = 1\n" \
    "BLUE  = 2\n" \
    "NAVY  = 2\n" \
    "GREEN = 3\n" \
    "RED   = 4\n" \
    "BROWN = 5\n" \
    "MAROON = 5\n" \
    "PURPLE = 6\n" \
    "ORANGE = 7\n" \
    "OLIVE = 7\n" \
    "YELLOW = 8\n" \
    "LT_GREEN = 9\n" \
    "LIME = 9\n" \
    "TEAL = 10\n" \
    "LT_CYAN = 11\n" \
    "AQUA = 11\n" \
    "LT_BLUE = 12\n" \
    "ROYAL = 12\n" \
    "PINK = 13\n" \
    "LT_PURPLE = 13\n" \
    "FUCHSIA = 13\n" \
    "GREY = 14\n" \
    "LT_GREY = 15\n" \
    "SILVER = 15\n" \
    "COLORS = { 'white'    => WHITE,\n" \
    "'black'    => BLACK,\n" \
    "'blue'     => BLUE,\n" \
    "'green'    => GREEN,\n" \
    "'red'      => RED,\n" \
    "'brown'    => BROWN,\n" \
    "'purple'   => PURPLE,\n" \
    "'orange'   => ORANGE,\n" \
    "'yellow'   => YELLOW,\n" \
    "'ltgreen'  => LT_GREEN,\n" \
    "'teal'     => TEAL,\n" \
    "'ltcyan'   => LT_CYAN,\n" \
    "'ltblue'   => LT_BLUE,\n" \
    "'pink'     => PINK,\n" \
    "'grey'     => GREY,\n" \
    "'ltgrey'   => LT_GREY }\n" \
    "def format( text )\n" \
    "text.gsub( /!\\[(.*?)\\]/ ) do |match|\n" \
    "codes = $1.downcase\n" \
    "repl = \"\"\n" \
    "i = 0\n" \
    "while i < codes.length\n" \
    "case codes[i].chr\n" \
    "when 'b'\n" \
    "repl << 2.chr\n" \
    "when 'o'\n" \
    "repl << 15.chr\n" \
    "when 'r'\n" \
    "repl << 18.chr\n" \
    "when 'u'\n" \
    "repl << 31.chr\n" \
    "when 'i'\n" \
    "repl << 29.chr\n" \
    "when '|'\n" \
    "repl << 9.chr\n" \
    "when 'c'\n" \
    "bg = nil\n" \
    "i, fg = extract_color( i+1, codes )\n" \
    "i, bg = extract_color( i+1, codes ) if i < codes.length && codes[i].chr == ','\n" \
    "repl << \"\" << ( fg || \"\" )\n" \
    "repl << \",\" << bg if bg\n" \
    "i -= 1\n" \
    "end\n" \
    "i += 1\n" \
    "end\n" \
    "repl\n" \
    "end\n" \
    "end\n" \
    "private\n" \
    "def extract_color( i, s )\n" \
    "return [ i, nil ] if i >= s.length\n" \
    "if s[i].chr == '('\n" \
    "j = s.index( ')', i )\n" \
    "return [ j+1, \"%02d\" % COLORS[ s[i+1..j-1].downcase ] ]\n" \
    "end\n" \
    "j = i\n" \
    "j += 1 while j < s.length && s[j].chr =~ /[0-9]/\n" \
    "j += 1 if j == s.length\n" \
    "return [ j, \"%02d\" % s[i..j-1].to_i ]\n" \
    "end\n" \
    "end\n" \
    "class XChatRubyRBPlugin < XChatRubyPlugin\n" \
    "def initialize\n" \
    "hook_command( \"RB\", XCHAT_PRI_NORM, method( :rb_command_hook ),\n" \
    "\"Usage: /RB LOAD    <filename> : load the given Ruby script as a plugin\\n\" +\n" \
    "\"           UNLOAD  <filename> : unload the given Ruby script\\n\" +\n" \
    "\"           COMMANDS           : show all registered Ruby-plugin commands\\n\" +\n" \
    "\"           LIST               : list all loaded Ruby plugins\\n\" +\n" \
    "\"           EXEC    <command>  : execute the given Ruby code\\n\" +\n" \
    "\"           ABOUT              : describe this plugin\" )\n" \
    "hook_command( \"LOAD\", XCHAT_PRI_NORM, method( :rb_load ),\n" \
    "\"Usage: LOAD <file>, loads a plugin or script\" )\n" \
    "hook_command( \"UNLOAD\", XCHAT_PRI_NORM, method( :rb_unload ),\n" \
    "\"Usage: UNLOAD <file>, unloads a plugin or script\" )\n" \
    "end\n" \
    "def rb_command_hook( words, words_eol, data )\n" \
    "words = \"\" if words == nil\n" \
    "case words[1].downcase\n" \
    "when \"\" then\n" \
    "puts \"You must specify the RB command to invoke\"\n" \
    "when \"load\" then\n" \
    "return rb_command_load( words, words_eol, data )\n" \
    "when \"unload\" then\n" \
    "return rb_command_unload( words, words_eol, data )\n" \
    "when \"list\" then\n" \
    "return rb_plugins_list( words, words_eol, data )\n" \
    "when \"commands\" then\n" \
    "return rb_command_list( words, words_eol, data )\n" \
    "when \"exec\" then\n" \
    "return rb_command_exec( words, words_eol, data )\n" \
    "when \"about\" then\n" \
    "return rb_command_about( words, words_eol, data )\n" \
    "else\n" \
    "puts \"Unknown RB command: #{words[1]}\"\n" \
    "end\n" \
    "return XCHAT_EAT_ALL\n" \
    "end\n" \
    "def rb_load( words, words_eol, data )\n" \
    "f = words_eol[1]\n" \
    "return XCHAT_EAT_NONE if !f or f !~ /\\.rb$/\n" \
    "XChatRubyEnvironment.load_plugin f\n" \
    "return XCHAT_EAT_ALL\n" \
    "end\n" \
    "def rb_unload( words, words_eol, data )\n" \
    "f = words_eol[1]\n" \
    "return XCHAT_EAT_NONE if !f or f !~ /\\.rb$/\n" \
    "if !XChatRubyEnvironment.unload_plugin( f )\n" \
    "puts \"The given plugin (#{f}) does not appear to be loaded.\"\n" \
    "else\n" \
    "puts \"#{f} has been unloaded.\"\n" \
    "end\n" \
    "return XCHAT_EAT_ALL\n" \
    "end\n" \
    "def rb_command_load( words, words_eol, data )\n" \
    "file = words_eol[2]\n" \
    "if !file\n" \
    "puts \"You must specify a file to load.\"\n" \
    "else\n" \
    "XChatRubyEnvironment.load_plugin file\n" \
    "end\n" \
    "return XCHAT_EAT_ALL\n" \
    "end\n" \
    "def rb_command_unload( words, words_eol, data )\n" \
    "file = words_eol[2]\n" \
    "if !file\n" \
    "puts \"You must specify a file to unload (it should be the same filename and path given in /rb list).\"\n" \
    "else\n" \
    "if !XChatRubyEnvironment.unload_plugin( file )\n" \
    "puts \"The given plugin (#{file}) does not appear to be loaded.\"\n" \
    "else\n" \
    "puts \"#{file} has been unloaded.\"\n" \
    "end\n" \
    "end\n" \
    "return XCHAT_EAT_ALL\n" \
    "end\n" \
    "def rb_plugins_list( words, words_eol, data )\n" \
    "XChatRubyEnvironment.list_modules\n" \
    "return XCHAT_EAT_ALL\n" \
    "end\n" \
    "def rb_command_list( words, words_eol, data )\n" \
    "XChatRubyEnvironment.list_commands\n" \
    "return XCHAT_EAT_ALL\n" \
    "end\n" \
    "def rb_command_exec( words, words_eol, data )\n" \
    "if !words_eol[2]\n" \
    "puts \"You must specify some ruby code to execute.\"\n" \
    "else\n" \
    "eval words_eol[2], $xchat_global_binding, \"(/rb exec)\"\n" \
    "end\n" \
    "return XCHAT_EAT_ALL\n" \
    "end\n" \
    "def rb_command_about( words, words_eol, data )\n" \
    "puts\n" \
    "puts format( \"-![c(red)b]*![bc]------------------------------------------------\" )\n" \
    "puts format( \"X-Chat ![bc(red)]Ruby![bc] Interface 1.1\" )\n" \
    "puts\n" \
    "puts format( \"Copyright (c) 2003 ![bc(yellow)]Jamis Buck![bc] <jgb3@email.byu.edu>\" )\n" \
    "puts format( \"------------------------------------------------![bc(red)]*![cb]-\" )\n" \
    "puts\n" \
    "return XCHAT_EAT_ALL\n" \
    "end\n" \
    "end\n" \
    "end\n" 

#endif /* __XCHAT_RUBY_PLUGIN_H__ */
