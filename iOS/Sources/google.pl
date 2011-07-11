#!/usr/bin/perl

# Build a char->hex map
for (0..255)
{
    $escapes{chr($_)} = sprintf("%%%02X", $_);
}

sub google
{
    my $query = shift;

    $query =~ s/([^A-Za-z0-9\-_.!~*'()])/$escapes{$1}/g;

    IRC::command ("/browser http://www.google.com/search?q=$query");

    return 1;
}

IRC::register ("google", "1.0", "", "");

IRC::add_command_handler ("google", "google");
