package Tuvix::ExtendedPlerd;
use strict;
use warnings FATAL => 'all';
use Tuvix::ExtendedPlerd::Post;

use Module::Load;
use Try::Tiny;

use Moose;

use base 'Plerd';

has '+posts' => (
    is         => 'ro',
    isa        => 'ArrayRef[Tuvix::ExtendedPlerd::Post]',
    lazy_build => 1
);

has 'extensions' => (
    is  => 'ro',
    isa => 'Maybe[ArrayRef[Str]]'
);

has 'extension_preferences' => (
    is  => 'ro',
    isa => 'Maybe[HashRef]',
);

has 'post_triggers' => (
    is         => 'ro',
    isa        => 'Maybe[HashRef[Str]]',
    lazy_build => 1,
);


sub BUILD {
    my $self = shift;
    foreach my $extension (@{$self->extensions // []}) {
        try {
            load $extension;
        }
        catch {
            my $error = shift || "Unknown error";
            die "Can't load extension: '$extension': $error\n";
        };
    }
}

sub _build_posts {
    my $self = shift;
    my @posts;
    my $triggers = $self->post_triggers;

    foreach my $file (sort {$a->basename cmp $b->basename} $self->source_directory->children) {
        if ($file =~ m/\.(?:markdown|md)$/) {
            push @posts, Tuvix::ExtendedPlerd::Post->new(plerd => $self, source_file => $file)
        }
        else {
            foreach my $trigger (keys %{$triggers}) {
                if ($file =~ m/\.$trigger$/i) {
                    push @posts, $$triggers{$trigger}->new(plerd => $self, source_file => $file);
                    last;
                }
            }
        }
    }
    return [ sort {$b->date <=> $a->date} @posts ];
}

sub _build_post_triggers {
    my $self = shift;
    my %triggers;

    foreach my $classref (@{$self->extensions // []}) {
        if ($classref->can('file_type')) {
            $triggers{ $classref->file_type } = $classref;
        }
    }

    return \%triggers;
}

1;


=head1 NAME

Tuvix::ExtendedPlerd - Extended Plerd with Extension support


=head1 DESCRIPTION

Adding some Extension support to plerd, so that there can be extensions which can
post other types of posts than just .markdown files

=head1 CLASS METHODS

=over


=item * extensions

An arrayref of strings, representing the plugins to load when a new
Tuvix::ExtendedPlerdinstance is created.

=item * extension_preferences

A hashref of config options for extensions. It is up to each individual extension
to decide how to act upon the contents therein.

=item * post_triggers

A hashref that maps extensions to file types. The key is used as a regex to deduce what
source file types the particular Post extension using to render pages.
The value is a reference to that particular extension.


=back


=head1 AUTHOR

Petter H <dr.doddo@gmail.com>