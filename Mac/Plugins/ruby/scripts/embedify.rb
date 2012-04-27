#-------------------------------------------------------------------------
# embedify.rb -- convert a ruby script into a C header file
# Copyright (C) 2003 Jamis Buck (jgb3@email.byu.edu)
#-------------------------------------------------------------------------
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
# This script takes an input file and converts the entire contents into
# a #define in a C header file, suitable for referencing in a C program.
# It will also remove all blank lines, and lines that start with #.
# (It will not remove comments at the end of lines, since the script
# isn't sophisticated enough to recognize whether the # is inside of a
# string or not.)
#
# author: Jamis Buck (jgb3@email.byu.edu)
#-------------------------------------------------------------------------

$in = ARGV[0]
$out = ARGV[1]

if !$in or !$out
  puts "Please specify an input and an output file"
  exit 0
end

$output_macro = $out.gsub( /[- .]/, "_" ).upcase

if $in =~ /(.*)\.[^.]*$/
  $basename = $1
else
  $basename = $in
end

$macro = $basename.gsub( /[- .]/, "_" ).upcase

File.open( $in, "r" ) do |input|
  File.open( $out, "w" ) do |output|
    output.puts "/* this is a generated file.  DO NOT MODIFY IT!  Instead, modify"
    output.puts " * #{$in} and regenerate this file."
    output.puts " */"
    output.puts
    output.puts  "#ifndef __#{$output_macro}__"
    output.puts  "#define __#{$output_macro}__"
    output.puts
    output.print "#define #{$macro} "
    while input.gets
      line = $_
      stripped = line.strip
      next if stripped.length == 0 or stripped[0].chr == '#'
      line = line.gsub( /\\/ ) { "\\\\" } .gsub( /(\n\r|\r\n|\n|\r)/, "\\n" ).gsub( /"/, "\\\"" ).strip
      output.puts "\\"
      output.print "    \"#{line}\" "
    end
    output.puts
    output.puts "\n#endif /* __#{$output_macro}__ */"
  end
end
