-- This handles post-processing routines for handling of a row entry including linking it
-- to an external address table for quick and easy lookup of information

CREATE OR REPLACE FUNCTION traffic_report.handle_postprocessing_tr_entry(_tr_row bigint) 
    RETURNS void
    LANGUAGE plperlu SECURITY DEFINER
    AS $$

use strict;
use warnings;

use Net::IP;
use Geo::IP2Location;

# First we need to grab the Traffic Report Entry that just got inserted and get it's magic
my $sth = spi_query("SELECT * FROM traffic_report.flattened_traffic_reports WHERE id=$_[0]");
my $tr_row = spi_fetchrow($sth);
spi_cursor_close($sth);

if (! defined $tr_row) {
    elog(ERROR, "unable to find STR row ID $_[0]!");
}

my $src_ip = new Net::IP($tr_row->{'src_ip'}) || elog(ERROR, "Net::IP died on src_ip $tr_row->{'src'}");
my $dst_ip = new Net::IP($tr_row->{'dst_ip'})  || elog(ERROR, "Net::IP died on dst_ip $tr_row->{'dst'}");

# We're only interested in PRIVATE->PUBLIC communications. If we get a PUBLIC-PUBLIC result,
# that means that we're dealing with IPv6, or a non-RFC1918 complaint IPv4 network which we
# currently will explode for due to the fact that we don't have a record of the recorder's
# network CIDRs so we can't determine which end is which as of yet

my $src_ip_type = $src_ip->iptype();
my $dst_ip_type = $dst_ip->iptype();

my $global_ip = undef;
my $local_ip = undef;

# DB idents for IP addresses
my $global_ip_id = undef; 
my $global_hostname_id = undef;
my $local_ip_id = undef;

# Outbound connections
if ($src_ip_type eq 'PRIVATE' && $dst_ip_type eq 'PUBLIC') {
    $global_ip = $dst_ip->ip();
    $global_ip_id = $tr_row->{'dst_ip_id'};
    $global_hostname_id = $tr_row->{'dst_hostname_id'};
    $local_ip = $src_ip->ip();
    $local_ip_id = $tr_row->{'src_ip_id'};
    #elog(WARNING, "Outbound connection");
} elsif ($src_ip_type eq 'PUBLIC' && $dst_ip_type eq 'PRIVATE') {
    $global_ip = $src_ip->ip();
    $global_ip_id = $tr_row->{'src_ip_id'};
    $global_hostname_id = $tr_row->{'src_hostname_id'};
    $local_ip = $dst_ip->ip();
    $local_ip_id = $tr_row->{'dst_ip_id'};
    #elog(WARNING, "Inbound connection");
} elsif ($src_ip_type eq 'PUBLIC' && $dst_ip_type eq 'PUBLIC') {
    elog(ERROR, "PUBLIC-PUBLIC connections not supported!");
} else {
    #elog(WARNING, "Non-internet facing connection, nothing to be done");
    return;
}

#elog(INFO, "Global IP: ".$global_ip);
#elog(INFO, "Local IP: ".$local_ip);

# Load the correct GeoIP database depending on if this a v4 or v6 operation
my $geodb;
my $geodb_version;

# HACK - this paths shouldn't be hardcoded

if ($src_ip->version() == '4') {
    $geodb = Geo::IP2Location->open("/etc/ndr/ip2location/DB7_v4.bin");
    $geodb_version = $geodb->get_database_version();
} elsif ($src_ip->version() == '6') {
    $geodb = Geo::IP2Location->open("/etc/ndr/ip2location/DB7_v6.bin");
    $geodb_version = $geodb->get_database_version();
} else {
    elog(ERROR, "Received impossible IP version");
}

# Get the GeoIP information from the database

# If we get an unknown response from Geo::IP2Location, replace it with a NULL entry
sub replace_unknown_with_null {
    my $value = shift;
    if ($value eq Geo::IP2Location::UNKNOWN) {
        return undef;
    } else {
        return $value;
    }
}

# ARGH!. So when we're using the demo database, shat breaks. Get country() will error out if 
# we query an IP that it doesn't have. Testing, region, and city will return a string like
# This is demo DB7 BIN database. Please evaluate IP address from ...

# The string varies depending on which demo databae and if it's v4 or v6 so right now
# WE MUST EMBRACE THE SUCK. Set the values we care about to undef; that will map to postgrs
# NULL type, then we see if we can get actual return information safely

my $countryshort = undef;
my $countrylong = undef;
my $region = undef;
my $city = undef;
my $isp = undef;
my $domain = undef;

unless ($geodb->get_region($global_ip) =~ "You can evaluate IP address from") {
    $countryshort = replace_unknown_with_null($geodb->get_country_short($global_ip));
    $countrylong = replace_unknown_with_null($geodb->get_country_long($global_ip));
    $region = replace_unknown_with_null($geodb->get_region($global_ip));
    $city = replace_unknown_with_null($geodb->get_city($global_ip));
    $isp = replace_unknown_with_null($geodb->get_isp($global_ip));
    $domain = replace_unknown_with_null($geodb->get_domain($global_ip));

    #elog(INFO, "DB Version ".$geodb_version);
    #elog(INFO, "Country Short: $countryshort");
    #elog(INFO, "Country Long: $countrylong");
    #elog(INFO, "Region: $region");
    #elog(INFO, "City: $city");
    #elog(INFO, "ISP: $isp");
    #elog(INFO, "Domain: $domain");
} else {
    elog(WARNING, "Out of range for demo database.");
}

# If there was a hostname attached with the global IP, we need to register it
if (defined $global_hostname_id) {
    my $register_proc = 'SELECT * FROM traffic_report.register_internet_hostname_from_tr($1, $2, $3)';
    my $register_sp = spi_prepare($register_proc, 'bigint', 'bigint', 'bigint');
    spi_exec_prepared($register_sp, $_[0], $global_ip_id, $global_hostname_id);
}

# Unlike PLPgSQL, inserting safely a bit more effort. We need to create an insert query plan, then
# character replace. It would be NICE if the standard DBI interface was available but what can you
# do?

my $network_outbound_traffic_insert = <<'EOF';
INSERT INTO traffic_report.network_outbound_traffic 
    (traffic_report_id,
     msg_id,
     local_ip_id,
     global_ip_id,
     geoip_database_version,
     country_code,
     country_name,
     region_name,
     city_name,
     isp,
     domain)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
EOF

my $noi_insert_plan = spi_prepare($network_outbound_traffic_insert,
                                  'bigint',
                                  'bigint',
                                  'bigint',
                                  'bigint',
                                  'text',
                                  'text',
                                  'text',
                                  'text',
                                  'text',
                                  'text',
                                  'text');

spi_exec_prepared($noi_insert_plan,
                  $tr_row->{'id'},
                  $tr_row->{'msg_id'},
                  $local_ip_id,
                  $global_ip_id,
                  $geodb_version,
                  $countryshort,
                  $countrylong,
                  $region,
                  $city,
                  $isp,
                  $domain);

$$