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
        theme => {
            schema => 'perl::modname_with_optional_args*',
            req => 1,
            pos => 0,
            cmdline_aliases => {m=>{}},
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
    require Module::Load::Util;
    require String::Pad;

    my %args = @_;
    my $width = $args{width} // 80;

    my $theme = Module::Load::Util::instantiate_class_with_optional_args($args{theme});
    my @item_names = $theme->list_items;

    my $reset = Color::ANSI::Util::ansi_reset();
    for my $item_name (@item_names) {
        my $empty_bar = " " x $width;
        my $color0 = $theme->get_item_color($item_name);
        my $color_summary = ref $color0 eq 'HASH' && defined($color0->{summary}) ?
            String::Pad::pad($color0->{summary}, $width, "center", " ", 1) : undef;
        my $fg_color = ref $color0 eq 'HASH' ? $color0->{fg} : $color0;
        my $bg_color = ref $color0 eq 'HASH' ? $color0->{bg} : undef;
        my $color = $fg_color // $bg_color;
        my $text_bar  = String::Pad::pad(
            "$item_name (".($fg_color // "-").(defined $bg_color ? " on $bg_color" : "").")",
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
