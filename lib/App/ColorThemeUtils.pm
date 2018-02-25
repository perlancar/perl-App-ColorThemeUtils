package App::ColorThemeUtils;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{list_color_theme_modules} = {
    v => 1.1,
    summary => 'List color theme modules',
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_color_theme_modules {
    require PERLANCAR::Module::List;

    my %args = @_;

    my @res;
    my %resmeta;

    my $mods = PERLANCAR::Module::List::list_modules(
        "", {list_modules => 1, recurse => 1});
    for my $mod (sort keys %$mods) {
        next unless $mod =~ /::ColorTheme::/;
        push @res, $mod;
    }

    [200, "OK", \@res, \%resmeta];
}

$SPEC{list_color_themes} = {
    v => 1.1,
    args => {
        module => {
            schema => 'perl::modname*',
            pos => 0,
            tags => ['category:filtering'],
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_color_themes {
    no strict 'refs';
    require Color::ANSI::Util;

    my %args = @_;

    my @mods;
    if (defined $args{module}) {
        push @mods, $args{module};
    } else {
        my $mods = PERLANCAR::Module::List::list_modules(
            "", {list_modules => 1, recurse => 1});
        for my $mod (sort keys %$mods) {
            next unless $mod =~ /::ColorTheme::/;
            push @mods, $mod;
        }
    }

    my @res;
    my %resmeta;
    for my $mod (@mods) {
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;
        my $themes = \%{"$mod\::color_themes"};
        for my $name (sort keys %$themes) {
            my $colors = $themes->{$name}{colors};
            my $colorbar = "";
            for my $colorname (sort keys %$colors) {
                my $color = $colors->{$colorname};
                $colorbar .= join(
                    "",
                    (length $colorbar ? "" : ""),
                    ref($color) || !length($color) ? ("   ") :
                        (
                            Color::ANSI::Util::ansibg($color),
                            "   ",
                            "\e[0m",
                        ),
                );
            }
            if ($args{detail}) {
                push @res, {
                    module => $mod,
                    name   => $name,
                    colors => $colorbar,
                };
            } else {
                push @res, "$mod\::$name";
            }
        }
    }

    if ($args{detail}) {
        $resmeta{'table.fields'} = [qw/module name colors/];
    }

    [200, "OK", \@res, \%resmeta];
}

1;
# ABSTRACT: CLI utilities related to color themes

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

# INSERT_EXECS_LIST


=head1 SEE ALSO

L<Color::Theme>

=cut
