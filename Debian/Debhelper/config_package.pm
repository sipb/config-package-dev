#!/usr/bin/perl

package Debian::Debhelper::config_package;

use warnings;
use strict;

use Exporter;
use vars qw(@ISA @EXPORT);
@ISA=qw(Exporter);
@EXPORT=qw(&encode &decode);

sub encode {
    my $result = "";
    my $input = shift;
    $input =~ s,^/,,;
    foreach (split('', $input)) {
        if (m/[a-z0-9.-]/) {
            $result .= "$_";
        } elsif (m/[A-Z]/) {
            $result .= "+".lc($_)."+";
        } elsif ($_ eq '/') {
            $result .= "++";
        } elsif ($_ eq '_') {
            $result .= "+-+";
        } else{
            $result .= "+x".hex(ord($_))."+";
        }
    }
    return $result;
}

sub unparse {
    $_ = $_[0];
    return "/" unless $_;
    return "_" if $_ eq "-";
    return uc($_) if /^[a-z]$/;
    s/^x//;
    return chr hex $_;
}

sub decode {
    my $input = shift;
    $input =~ s/\+([^+]*)\+/unparse($1)/eg;
    return $input;
}

1
