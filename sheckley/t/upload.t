use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::Asset::File;
use Data::Dump qw/pp/;
use lib "../lib";
use Sheckley::Controller::Upload;

my $t      = Test::Mojo->new('Sheckley');
my $dbh    = $t->app->db->dbh;
my $static = $t->app->static;
my $ctrl   = Sheckley::Controller::Upload->new;

$ctrl->app($t->app);

ok( ref($static), ref($static) );

# utils
{	
	my $file = $static->file("text/pg29876.txt");	
	my $dummy_work = {
		series_id => 1,
		type => 'novel',
		pub_date => '1960-10-10',
		title => 'Ghost V'	
	};

	my $work_id = Sheckley::Controller::Upload::_insert_work($dbh, $dummy_work, $file->slurp);
	
	ok( $work_id > 0, "got work id: $work_id" );
	
	$file->handle->seek(0,0);
	
	my $pos = $file->handle->tell;
	
	ok( $pos == 0, "got pos: $pos" );
	
	my @content = (
		'u popa bila sobaka',
		'on eyio lubul',
		'ona s"ela kusok miasa',
		'on eyio ubil'
	);
	
	Sheckley::Controller::Upload::_insert_sentence($dbh, $work_id, 1, \@content);
	
	my $sent_rows = $t->app->db->query('select * from sentences where work_id = ?', $work_id);
	
	ok( ref($sent_rows) eq 'ARRAY', ref($sent_rows) );
	ok( scalar(@$sent_rows) == 4, 'got 4 rows' );
	
	$t->app->db->execute('delete from word_in_sentence where work_id = ?', $work_id);
	$t->app->db->execute('delete from sentences where work_id = ?', $work_id);
	$t->app->db->execute('delete from works where id = ?', $work_id);
}

#_parse_file
{
	last;
	#my $file = $static->file("text/pg29876.txt");	
	my $dummy_work = {
		series_id => 1,
		type => 'novel',
		pub_date => '1960-10-10',
		title => 'Ghost V',
		upload => $static->file("text/pg29876.txt"),
		line_start => 47,
		line_end => 200
	};

	my $work_id = Sheckley::Controller::Upload::_parse_file($dbh, $dummy_work);
	
	ok($work_id > 0, "got workid: $work_id");
}

#

#print "id: $id\n";

#$ctrl->_parse_file($file->handle, 47, 200);

#
#
#
#
#my $handle = $file->handle;
#
#my ($curr_line, $start_line) = (0, 23);
#while (<$handle>) {
#	$curr_line++;
#	next if $curr_line < $start_line;
#	print "$_\n";
#}
#


done_testing();
