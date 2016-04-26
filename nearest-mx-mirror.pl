#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Math::Trig qw/great_circle_distance pi/;

my $zone_file = "zone.tab";

my $IGNORE_DEB_TZ = "Canary|Ceuta";

my @DEB_CODES =  qw/at au be bg br by ca ch cl cn cz de dk ee es
    fi fr gr hk hr hu ie ir is it jp kr lt mx nc nl no nz pl pt
    ro ru se si sk sv th tr tw ua uk us/;

my @CITIES;
my $CCODES;
my $BY_TZ;

my $MX_TZ = {

    GR => "Europe/Athens",
    EC => "America/Bogota",
    NZ => "Australia/Brisbane",
    LA => "America/Los_Angeles",
    UT => "America/New_York",
    NL => "Europe/Amsterdam",
    TW => "Asia/Taipei",
};

my @MX_CITIES;

#my $DEB_CITIES;

my $NEAREST;

read_zone_file($zone_file);
my @DEB_CITIES;
for my $deb (@DEB_CODES) {
    exists $CCODES->{$deb} or die "Missing code for deb country $deb";
    push @DEB_CITIES, grep {$_->{tz} !~ /$IGNORE_DEB_TZ/} @{$CCODES->{$deb}};

    #$DEB_CITIES->{$deb} = $CCODES->{$deb};
}

#print Dumper \@CITIES; exit;
#
for my $mx (sort keys %$MX_TZ) {
    #print "$mx $MX_TZ->{$mx}\n";
    my $tz = $MX_TZ->{$mx};
    my $entry = { %{$BY_TZ->{$tz}} } or die "No entry for timezone $tz";
    $entry->{mx} = $mx;
    #print Dumper $entry;
    push @MX_CITIES, $entry;
}

#print Dumper @DEB_CITIES; exit;

for my $city (@CITIES) {
    my $min = 1000000;
    my $near = undef;
    my $region = $city->{region};

    my $mx_dist = [];
    for my $mx (@MX_CITIES) {
        push @$mx_dist, { mx => $mx->{mx}, dist => my_distance($city, $mx) };
    }

    $city->{mx_dist} = [ sort {$a->{dist} <=> $b->{dist}} @$mx_dist ];
    
    #print Dumper $city;
    #exit;

    for my $deb (@DEB_CITIES) {
        $deb->{region} eq $region
            or $region eq "Indian" or $region eq "Arctic" 
            or $region eq "Africa" or next;
        my $dist = my_distance( $city, $deb);
        #printf "%30s %4.2f\n", $deb->{tz}, $dist;
        $dist >= $min and next;
        $min = $dist;
        $near = $deb;
    }

    $city->{deb} = $near->{code};
    #print "$near->{code}\n";
    #
    #printf "%4.2f %-30s %-30s %8.2f %8.2f %8.2f %8.2f\n", 
    #    $min, $city->{tz}, $near->{tz},
    #    $city->{latd}, $city->{lond},
    #    $near->{latd}, $near->{lond};

    #push @{$NEAREST->{$near->{code}}}, $city->{code};
    #die;
}

for my $city (sort { $a->{region} cmp $b->{region} || $a->{lon} <=> $b->{lon} } @CITIES) {
    my $mx_code = join ",", map { $_->{mx} } @{$city->{mx_dist}};

    printf "%35s) deb_code=%s ; mx_order=%s ;;\n", $city->{tz}, $city->{deb}, lc($mx_code);
}


exit;
for my $near (sort keys %$NEAREST) {
    #my @codes = grep  $_ ne $near, unique(@{$NEAREST->{$near}});
    my @codes = unique(@{$NEAREST->{$near}});
    @codes or next;
    while (@codes) {
        my @first = splice @codes, 0, 12;
        
        printf "%43s) ccode=%s;;\n", join("|", @first), $near;
    }
    #my $codes = join "|", @codes;
    #print "$near: @codes\n";
}
#print Dumper( $CCODES) ;

#================================================================================
sub read_zone_file {
    my $fname = shift;
    open my $file, "<", $fname || die "Could not open($fname) $!\n";

    while (<$file>) {
        my $entry = line_to_entry($_);
        $entry or next;
        push @CITIES, $entry;
        my $code = $entry->{code};
        push @{$CCODES->{$code}}, $entry;
        $BY_TZ->{$entry->{tz}} = $entry;
    }

sub xxxx {

        m/^(\w{2})\t([+-]\d+)([+-]\d+)\t([\w\/]+)/ or do {
            #print;
            next;
        };



        my ($code, $lat, $lon, $tz) = ($1, $2, $3, $4);

        my $lat_len = length $lat;
        my $lon_len = length $lon;

        if ($lat_len == 5) {
            $lat /= 100;
        }
        elsif ($lat_len ==7) {
            $lat /= 10000;
        }
        else {
            die "Bad lat: $lat @ $tz"
        }

        if ($lon_len == 6) {
            $lon /= 100;
        }
        elsif ($lon_len == 8) {
            $lon /= 10000;
        }
        else {
            die "Bad lon: $lon @ $tz"
        }

        $code =~ tr/A-Z/a-z/;
        $code eq "gb" and $code = "uk";

        my $region = $tz;
        $region =~ s{/.*}{};

        #print "$code $tz: $lat  $lon\n";
        my $entry = {
            code => $code,
            lat  => pi() / 2 - $lat * pi() / 180,
            lon  => $lon * pi() / 180,
            latd => $lat,
            lond => $lon,
            tz   => $tz,
            region => $region,
        };

        push @CITIES, $entry;
        push @{$CCODES->{$code}}, $entry;
    }
}

sub line_to_entry {
    my $line = shift;

    $line =~ m/^(\w{2})\t([+-]\d+)([+-]\d+)\t([\w\/]+)/ or do {
        #print;
        return;
    };

    return city_entry($1, $2, $3, $4);


}

sub city_entry {
    my ($code, $lat, $lon, $tz) = @_;

    my $lat_len = length $lat;
    my $lon_len = length $lon;

    if ($lat_len == 5) {
        $lat /= 100;
    }
    elsif ($lat_len ==7) {
        $lat /= 10000;
    }
    else {
        die "Bad lat: $lat @ $tz"
    }

    if ($lon_len == 6) {
        $lon /= 100;
    }
    elsif ($lon_len == 8) {
        $lon /= 10000;
    }
    else {
        die "Bad lon: $lon @ $tz"
    }

    $code =~ tr/A-Z/a-z/;
    $code eq "gb" and $code = "uk";

    my $region = $tz;
    $region =~ s{/.*}{};

    #print "$code $tz: $lat  $lon\n";
    my $entry = {
        code => $code,
        lat  => pi() / 2 - $lat * pi() / 180,
        lon  => $lon * pi() / 180,
        latd => $lat,
        lond => $lon,
        tz   => $tz,
        region => $region,
    };

    return $entry;
}

sub my_distance {
    my ($c1, $c2) = @_;
    #print "$c1->{lon}:$c1->{lat}  $c2->{lon}:$c2->{lat}\n";
    return great_circle_distance(
        $c1->{lon},
        $c1->{lat}, 
        $c2->{lon},
        $c2->{lat},
    );
}

sub unique {
    my %hash;
    my @result;
    for (@_) {
        $hash{$_}++ and next;
        push @result, $_,
    }
    return @result;
}
