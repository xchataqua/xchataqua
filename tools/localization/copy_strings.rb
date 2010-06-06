#!/usr/bin/env ruby -wKU
require 'fileutils'

base = "../../Localization"

Dir.glob("po/*.strings") do |f|
  lang = $1 if f =~ /po\/(.+?)\.strings/
  unless File.exists?(File.join(base, "#{lang}.lproj"))
    Dir.mkdir(File.join(base, "#{lang}.lproj"))
    puts lang
  end
  FileUtils.cp(f, File.join(base, %W(#{lang}.lproj xchat.strings)))
end
