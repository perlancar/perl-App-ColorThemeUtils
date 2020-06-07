package App::ColorThemeUtils;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{list_color_theme_modules} = {
    v => 1.1,
    summary => 'List ColorTheme modules',
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_color_theme_modules {
    require Module::List::Tiny;

    my %args = @_;

    my @res;
    my %resmeta;

    my $mods = Module::List::Tiny::list_modules(
        "", {list_modules => 1, recurse => 1});
    for my $mod (sort keys %$mods) {
        next unless $mod =~ /(\A|::)ColorTheme::/;
        push @res, $mod;
    }

    [200, "OK", \@res, \%resmeta];
}

$SPEC{show_color_theme_swatch} = {
    v => 1.1,
    args => {
        module => {
            schema => 'perl::modname*',
            req => 1,
            pos => 0,
            cmdline_aliases => {m=>{}},
        },
        module_args => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'module_arg',
            schema => ['hash*', of=>'str*'],
            cmdline_aliases => {A=>{}},
        },
        width => {
            schema => 'posint*',
            default => 80,
            cmdline_aliases => {w=>{}},
        },
    },
};
sub show_color_theme_swatch {
    require Color::ANSI::Util;
    require Color::RGB::Util;
    require String::Pad;

    my %args = @_;
    my $width = $args{width} // 80;
    my $mod = $args{module};
    $mod = "ColorTheme::$mod" unless $mod =~ /(\A|::)ColorTheme::/;
    (my $modpm = "$mod.pm") =~ s!::!/!g;
    require $modpm;

    my $ctheme = $mod->new(%{ $args{module_args} // {} });
    my @color_names = $ctheme->get_color_list;

    my $reset = Color::ANSI::Util::ansi_reset();
    for my $color_name (@color_names) {
        my $empty_bar = " " x $width;
        my $color0 = $ctheme->get_color($color_name);
        my $color_summary = ref $color0 eq 'HASH' && defined($color0->{summary}) ?
            String::Pad::pad($color0->{summary}, $width, "center", " ", 1) : undef;
        my $fg_color = ref $color0 eq 'HASH' ? $color0->{fg} : $color0;
        my $bg_color = ref $color0 eq 'HASH' ? $color0->{bg} : undef;
        my $color = $fg_color // $bg_color;
        my $text_bar  = String::Pad::pad(
            "$color_name (".($fg_color // "-").(defined $bg_color ? " on $bg_color" : "").")",
            $width, "center", " ", 1);
        my $bartext_color = Color::RGB::Util::rgb_is_dark($color) ? "ffffff" : "000000";
        my $bar = join(
            "",
            Color::ANSI::Util::ansibg($color), $empty_bar, $reset, "\n",
            Color::ANSI::Util::ansibg($color), Color::ANSI::Util::ansifg($bartext_color), $text_bar, $reset, "\n",
            defined $color_summary ? (
                Color::ANSI::Util::ansibg($color), Color::ANSI::Util::ansifg($bartext_color), $color_summary, $reset, "\n",

            ) : (),
            Color::ANSI::Util::ansibg($color), $empty_bar, $reset, "\n",
            $empty_bar, "\n",
        );
        print $bar;
    }
    [200];
}

1;
# ABSTRACT: CLI utilities related to color themes

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

# INSERT_EXECS_LIST


=head1 SEE ALSO

L<Color::Theme>

=cut
