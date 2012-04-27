#!/usr/bin/perl

sub fix_url
{
    my $url = shift;

    my ($scheme, $authority, $path, $query, $fragment) =
         $url =~ m|^(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;

    # Any URL with a protocol is considered good
    return $url if $scheme;

    # If we have an '@', then it's probably an email address
    return "mailto:$url" if $url =~ /@/;

    # URLs with ftp in their name are probably ftp://
    return "ftp://$url" if $url =~ /^ftp\./;

    # Else, just assume http://
    return "http://$url";
}

sub browser
{
    my $command = shift;

    # Command could be:
    #   <url>
    #   <browser> <url>

    my @args = split (' ', $command);

    my $url = pop (@args);
    my $url = fix_url ($url);

    if ($#args > -1)
    {
	my $browser = join (" ", @args);
	system ("osascript", "-l", "AppleScript", "-e", 'tell application "' . $browser . '" to Çevent WWW!OURLÈ ("' . $url . '")');
    }
    else
    {
	system ("open", $url);
    }

    return 1;
}

IRC::register ("browser", "1.0", "", "");

IRC::add_command_handler ("browser", "browser");
