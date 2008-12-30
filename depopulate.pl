#!/usr/bin/perl
my $version = "1.0";

use strict;
use warnings;
use IO::Socket;

my ($host, $user, $password) = @ARGV;

unless (defined $host && defined $user && defined $password) {
    die <<TEXT

Depopulate $version
Usage: depopulate.pl SERVER USER PASSWORD
Deletes all mail in a given remote POP3 inbox.

DESCRIPTION
    
    This program takes a server, username and password then removes all
    email from the designated POP3 inbox. It only supports PLAIN 
    authentication although it wouldn't be too hard to add other methods.
    It is designed for removing all mail from an inbox exceeding a few
    thousand messages extremely quickly, a situation that every mail 
    client I could find failed horribly in.

EXAMPLES

    depopulate.pl myserver.com jonty secretpassword

        Deletes all mail in the POP3 inbox belonging to "jonty"
        on the server "myserver.com". Simple really.

TEXT
}

my $handle = IO::Socket::INET->new(
	Proto    => "tcp",
	PeerAddr => $host,
	PeerPort => 110
);

die "Could not connect to server '$host'\n" unless $handle;

# Dump the login banner
my $line = <$handle>;

$| = 1;
print "Connected, logging in...\n";

&command("USER $user");
my $login = &command("PASS $password");
die "Login failed: $login" unless ($login =~ /^\+OK/);

print "Logged in ok...\n";

my $stats = &command("STAT");
my ($emailCount) = ($stats =~ /\+OK (\d+) \d+/);

if ($emailCount > 0) {
	print "$emailCount messages being deleted...\n";
} elsif ($emailCount == 0) {
    die "No messages in the box to delete\n";
} else {
	die "Could not get number of messages in the box: $stats";
}

my ($deleted, $failed) = (0, 0);
for (my $count = 1; $count <= $emailCount; $count++) {
    my $status = &command("DELE $count");

    my $statusText;
    if ($status =~ /^\+OK/) {
        $statusText = 'Deleted';
        $deleted++;
    } else {
        $statusText = 'FAILED';
        $failed++;
    }

	print "$count of $emailCount: $statusText\r";
}

&command("QUIT");
print "Done! $deleted messages deleted, $failed failed.\n";

sub command {
	my $command = shift;
	print $handle "$command\r\n";
	my $response = <$handle>;
	return $response;
}
