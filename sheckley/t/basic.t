use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use Data::Dump qw/pp/;

my $t = Test::Mojo->new('Sheckley');
$t->get_ok('/')->status_is(200)->content_like(qr/Mojolicious/i);

# dbh helper
{
	my $dbh = $t->app->db->dbh;
	
	my $sth = $dbh->prepare("select * from series")
		or die $dbh->errstr;
		
	$sth->execute(@_)
		or die $sth->errstr;
	
	my $series = $sth->fetchall_arrayref({});	
	#pp($series);	
	ok( ref($series) eq 'ARRAY', ref($series) );
}

# db query
{
	can_ok($t->app->db, 'query');
	can_ok($t->app->db, 'execute');	
	
	$t->app->db->execute("insert into phrazes (text) values (?)", 'u popa bila sobaka');	
	
	my $sobaka = $t->app->db->query("select * from phrazes where text like '%sobaka%'");
	
	ok( ref($sobaka) eq 'ARRAY', ref($sobaka) );
	
	$t->app->db->execute("delete from phrazes where text like '%sobaka%'");
}

done_testing();
