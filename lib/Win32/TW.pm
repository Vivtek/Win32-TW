package Win32::TW;

use 5.006;
use strict;
use warnings;

use Win32::GuiTest qw(:ALL);
use Carp;


=head1 NAME

Win32::TW - Automate TRADOS Workbench 2007 using Win32::GuiTest

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

TRADOS Workbench 2007 is a front-end utility for working with translation memories.
It is strictly operated from the GUI, so for scripting we need to "remote
control" the GUI using L<Win32::GuiTest>, truly by far my favorite way of
controlling GUI-based software under Windows.

Essentially, Win32::TW defines a convenient API for manipulating Workbench
from Perl.  There are still significant limitations - Workbench will only
open one TM at a time, for example - but it actually turns out to be
pretty easy to automate it.  This takes care of it for you.

There are two ways to start a session; you can either connect to the
TW instance already open, or you can open one from a specified file.
Note that TW can only have one instance open; this is one of the many
suboptimal things about having to automate a GUI program instead of
having API access to functionality.

To connect to the running instance, use

   use Win32::TW;
   my $tw = Win32::TW->open();
   
This will check that an instance is actually running, and will croak
if not.

To start an instance, use

   use Win32::TW;
   my $tw = Win32::TW->open('filename');
   
Once you have a session set up, you can analyze, translate, or clean
documents using a fileset.  The fileset can either be a string that
specifies some files (that is, a filename or wildcard pattern) or it
can be a L<File::Set::Persist>.  Testing presumes the former, to
reduce dependencies, but in most real-world situations you'll want
the latter.

Note that setting up file lists in TW I<requires> exclusive access
to the keyboard and mouse - so while that part is running, you will
have to keep your hands off.  My recommendation is you set this up
on a separate machine so you're not tempted to start your task and
then go check Facebook - you will regret it if you do.

Once the actual analysis starts, of course, you're safe.

Another limitation of GUI automation is that everything works using
the localized spellings of menus and windows.  If you're not running
English TW, this is likely to suck for you.  If this is a problem,
drop me a line and we can add localization together.


=head1 METHODS

First, a couple of quick utilities to make things easier.

=head2 running()

Returns the running TW window or undef if TW isn't running.

=cut

sub running {
    my $tw;
    ($tw) = FindWindowLike(undef, "SDL Trados Translator's Workbench");
    return $tw;
}

=head2 closetw(window)

Given a window ID, closes it.

=cut

sub closetw {
    my $tw = shift;
    MenuSelect("&File|E&xit", $tw);
}

=head2 menu_and_wait (window, menu, child title)

Sends a menu command to a window that is expected to pop up a child,
waits for the child, and returns the child's handle.

Note: Assumes that the title for the child is unique - if you expect
collisions, you're going to get a rude surprise.

=cut

sub menu_and_wait {
    my ($window, $menu, $child_title) = @_;
    
    MenuSelect($menu, $window);
    my $child;
    ($child) = WaitWindowLike(undef, $child_title, undef, undef, undef, 30);
    $child;
}

=head2 click_and_wait (window, button, child title)

Clicks a named button on a window that is expected to pop up a child,
waits for the child, and returns the child's handle.

Note: Assumes that the title for the child is unique - if you expect
collisions, you're going to get a rude surprise.

=cut

sub click_and_wait {
    my ($window, $button, $child_title) = @_;
    
    PushChildButton ($window, $button);
    my $child;
    ($child) = WaitWindowLike(undef, $child_title, undef, undef, undef, 30);

    $child;
}

=head2 child_by_class (window, class, [count])

Finds the count-th child of window with class name 'class'.
The count parameter naturally defaults to 1.

=cut

sub child_by_class {
    my ($window, $target_class, $count) = @_;
    $count = 1 unless $count;
    
    foreach my $child (GetChildWindows($window)) {
      my $class = GetClassName($child);
      $count -- if $class eq $target_class;
      return $child unless $count;
    }
    return undef;
}
   

=head2 open([FILE])

Establishes a session - if you give it a file, will kill any existing
TW window and start the file (since there's no indication in TW of
what TM is currently open); if you don't, will just use the existing
window, if one is running, and croak otherwise.

=cut

sub open {
    my ($class, $file) = @_;
    my $self = bless {}, $class;
    my $tw = running();
    if ($file) {
        if (!-e $file) {
            croak "file $file does not exist";
        }
        closetw ($tw) if $tw;
        system "start $file";
        ($tw) = WaitWindowLike(undef, "SDL Trados Translator's Workbench");
        $self->{tw} = $tw;
    } else {
        croak ("no Workbench running") unless $tw;
        $self->{tw} = $tw;
    }
    return $self;
}

=head2 close

Closes the TW window associated with an established session.

=cut

sub close {
    my ($self) = @_;
    closetw($self->{tw}) if $self->{tw};
    undef ($self->{tw});
}

=head2 export

Exports a TM into the named file.  This is a simplified
export that ignores the ability to export selected custom
fields, because I've never actually used custom fields.
If you do, drop me a line.

=cut

sub export {
    my ($self, $filename) = @_;
    croak ("no TM open") unless $self->{tw};
    
    my $ew = menu_and_wait ($self->{tw}, "&File|&Export...", "Export");
    my $fw = click_and_wait ($ew, "OK", "Create Export File");

    if ($filename) {
        my $field = child_by_class ($fw, "Edit") or croak "Couldn't find filename field on export dialog";
        WMSetText ($field, $filename);
    }
    
    PushChildButton ($fw, "&Save");

}

=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-win32-tw at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-TW>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Win32::TW


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-TW>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Win32-TW>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Win32-TW>

=item * Search CPAN

L<http://search.cpan.org/dist/Win32-TW/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Win32::TW
