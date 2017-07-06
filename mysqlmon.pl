#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use Net::Statsd;
use Time::HiRes;
use Time::Local;
use Sys::Hostname;

my    $host = hostname;
print $host;
# Configure where to send events
# That's where your statsd daemon is listening.
$Net::Statsd::HOST = 'graphite.bigg33k.net';    # Default
$Net::Statsd::PORT = 8125;           # Default

# Connect to the database.
my $start_dbconn_time = [ Time::HiRes::gettimeofday ];
my $dbh = DBI->connect("DBI:mysql:database=test;host=localhost",
                       "root", "",
                       {'RaiseError' => 1});
Net::Statsd::timing('mysqlcanary.'.$host.'.get_dbconn__time', Time::HiRes::tv_interval($start_dbconn_time) * 1000);

# Drop table 'foo'. This may fail, if 'foo' doesn't exist
# Thus we put an eval around it.
my $start_dbdrop_time = [ Time::HiRes::gettimeofday ];
eval { $dbh->do("DROP TABLE foo") };
print "Dropping foo failed: $@\n" if $@;
Net::Statsd::timing('mysqlcanary.'.$host.'.get_dbdrop__time', Time::HiRes::tv_interval($start_dbdrop_time) * 1000);
# Create a new table 'foo'. This must not fail, thus we don't
# catch errors.
my $start_dbcreate_time = [ Time::HiRes::gettimeofday ];
$dbh->do("CREATE TABLE foo (id INTEGER, name VARCHAR(20))");
Net::Statsd::timing('mysqlcanary.'.$host.'.get_dbcreate__time', Time::HiRes::tv_interval($start_dbcreate_time) * 1000);

# INSERT some data into 'foo'. We are using $dbh->quote() for
# quoting the name.
my $start_dbinsert_time = [ Time::HiRes::gettimeofday ];
$dbh->do("INSERT INTO foo VALUES (1, " . $dbh->quote("Tim") . ")");
Net::Statsd::timing('mysqlcanary.'.$host.'.get_dbinsert__time', Time::HiRes::tv_interval($start_dbinsert_time) * 1000);

# same thing, but using placeholders (recommended!)
my $start_dbinsert2_time = [ Time::HiRes::gettimeofday ];
$dbh->do("INSERT INTO foo VALUES (?, ?)", undef, 2, "Jochen");
Net::Statsd::timing('mysqlcanary.'.$host.'.get_dbinsert2__time', Time::HiRes::tv_interval($start_dbinsert2_time) * 1000);

# now retrieve data from the table.
my $start_dbfetch_time = [ Time::HiRes::gettimeofday ];
my $sth = $dbh->prepare("SELECT * FROM foo");
$sth->execute();
while (my $ref = $sth->fetchrow_hashref()) {
;
}
$sth->finish();
Net::Statsd::timing('mysqlcanary.'.$host.'.get_dbfetch__time', Time::HiRes::tv_interval($start_dbfetch_time) * 1000);

# Disconnect from the database.
my $start_dbdisconn_time = [ Time::HiRes::gettimeofday ];
$dbh->disconnect();
Net::Statsd::timing('mysqlcanary.'.$host.'.get_dbdisconn__time', Time::HiRes::tv_interval($start_dbdisconn_time) * 1000);
