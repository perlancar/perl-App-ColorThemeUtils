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

sub _is_rgb_code {
    my $code = shift;
    $code =~ /\A#?[0-9A-Fa-f]{6}\z/;
}

sub _ansi_code_to_color_name {
    my $code = shift;
    $code =~ s/\e\[(.+)m/$1/g;
    "ansi:$code";
}

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
        "ColorTheme::", {list_modules => 1, recurse => 1});
    for my $mod (sort keys %$mods) {
        $mod =~ s/\AColorTheme:://;
        push @res, $mod;
    }

    [200, "OK", \@res, \%resmeta];
}

$SPEC{show_color_theme_swatch} = {
    v => 1.1,
    args => {
        theme => {
            schema => 'perl::colortheme::modname_with_optional_args*',
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

    my $theme = Module::Load::Util::instantiate_class_with_optional_args(
        {ns_prefix=>'ColorTheme'}, $args{theme});
    my @item_names = $theme->list_items;

    my $reset = Color::ANSI::Util::ansi_reset();
    for my $item_name (@item_names) {
        my $empty_bar = " " x $width;
        my $color0 = $theme->get_item_color($item_name);
        my $color_summary = ref $color0 eq 'HASH' && defined($color0->{summary}) ?
            String::Pad::pad($color0->{summary}, $width, "center", " ", 1) : undef;

        my $fg_color_code = ref $color0 eq 'HASH' ? ($color0->{ansi_fg} ? $color0->{ansi_fg} : $color0->{fg}) : $color0;
        my $bg_color_code = ref $color0 eq 'HASH' ? ($color0->{ansi_bg} ? $color0->{ansi_bg} : $color0->{bg}) : undef;
        die "Error in code for color item '$item_name': at least one of bgcolor or fgcolor must be defined"
            unless defined $fg_color_code || defined $bg_color_code;
        my $color_code = $fg_color_code // $bg_color_code;

        my $fg_color_name = !defined($fg_color_code) ? "undef" : _is_rgb_code($fg_color_code) ? "rgb:$fg_color_code" : _ansi_code_to_color_name($fg_color_code);
        my $bg_color_name = !defined($bg_color_code) ? "undef" : _is_rgb_code($bg_color_code) ? "rgb:$bg_color_code" : _ansi_code_to_color_name($bg_color_code);
        my $color_name = $fg_color_name // $bg_color_name;

        my $text_bar  = String::Pad::pad(
            "$item_name ($fg_color_name on $bg_color_name)",
            $width, "center", " ", 1);

        my $bar;
        if ($color_name =~ /^rgb:/) {
            my $bartext_color = Color::RGB::Util::rgb_is_dark($fg_color_code // 'ffffff') ? "ffffff" : "000000";
            $bar = join(
                "",
                Color::ANSI::Util::ansibg($color_code), $empty_bar, $reset, "\n",
                Color::ANSI::Util::ansibg($color_code), Color::ANSI::Util::ansifg($bartext_color), $text_bar, $reset, "\n",
                defined $color_summary ? (
                    Color::ANSI::Util::ansibg($color_code), Color::ANSI::Util::ansifg($bartext_color), $color_summary, $reset, "\n",

                ) : (),
                Color::ANSI::Util::ansibg($color_code), $empty_bar, $reset, "\n",
                $empty_bar, "\n",
            );
        } else {
            # color is ansi
            $bar = join(
                "",
                ($fg_color_code // '').($bg_color_code // ''), $empty_bar, $reset, "\n",
                ($fg_color_code // '').($bg_color_code // ''), $text_bar, $reset, "\n",
                defined $color_summary ? (
                    ($fg_color_code // '').($bg_color_code // ''), $color_summary, $reset, "\n",
                ) : (),
                $empty_bar, "\n",
            );
        }
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

L<ColorTheme>

=cut
