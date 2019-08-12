package Sheckley;
use Mojo::Base 'Mojolicious';
use DBIx::Connector;

my $CONNECTION;

sub startup {
	my $self = shift;
	
	$self->secrets(['AAA Ace Interplanetary Decontamination Corporation']);
	
	$self->plugin('Config');
	
	my $config = $self->plugin('Config');
	
	$CONNECTION = DBIx::Connector->new($config->{DSN}, {
		RaiseError => 1,
		AutoCommit => 1		
	}) or die "cant connect to database!";

	$self->helper('db.dbh' => sub { $CONNECTION->dbh });
	$self->helper('db.connector' => sub { $CONNECTION } );
	$self->helper('db.query' => \&_query);
	$self->helper('db.execute' => \&_execute);
	
	# Router
	my $r = $self->routes;

	# Normal route to controller
	$r->get('/')->to('root#index');
	$r->get('/words/:letter')->to('root#words');
	$r->get('/words/:word/lines')->to('root#lines');
	$r->get('/words/:word/sentences')->to('root#sentences');
	
	$r->get('/works')->to('works#index');
	$r->get('/works/create')->to('works#create');
	$r->post('/works/create')->to('works#create_POST');
	$r->get('/works/:id')->to('works#show');
	$r->post('/works/:id/delete')->to('works#delete');
	$r->get('/works/:id/lines')->to('works#lines');
	$r->get('/works/:id/sentences')->to('works#sentences');
	
	$r->get('/sets')->to('sets#index');
	$r->get('/sets/create')->to('sets#create');
	$r->post('/sets/create')->to('sets#create_POST');
	$r->get('/sets/:id')->to('sets#edit');
	$r->post('/sets/:id')->to('sets#edit_POST');
	$r->post('/sets/:id/delete')->to('sets#delete');
	$r->get('/sets/:id/lines')->to('sets#lines');
	$r->get('/sets/:id/sentences')->to('sets#sentences');
	
	$r->get('/phrases')->to('phrases#index');
	$r->post('/phrases')->to('phrases#create');
	$r->post('/phrases/:id/delete')->to('phrases#delete');
	$r->get('/phrases/:id/search')->to('phrases#search');
}

sub _query {	
	my $self = shift;
	my $sql = shift;
	
	my $dbh = $CONNECTION->dbh;
	
	my $sth = $dbh->prepare($sql)
		or die $dbh->errstr;

	$sth->execute(@_)
		or die $sth->errstr;
		
	$sth->fetchall_arrayref({});		
}

sub _execute {	
	my $self = shift;
	my $sql = shift;
	
	my $dbh = $CONNECTION->dbh;
	
	my $sth = $dbh->prepare($sql)
		or die $dbh->errstr;
	
	$sth->execute(@_)
		or die $sth->errstr;
		
	return $sth->rows;
}

1; 
