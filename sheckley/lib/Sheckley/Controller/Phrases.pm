package Sheckley::Controller::Phrases;
use Mojo::Base 'Mojolicious::Controller';

# GET /phrases
sub index {
	my $self = shift;
	
	$self->stash(phrases => $self->app->db->query('SELECT * FROM phrazes'));
}

# POST /phrases 
sub create {
	my $self = shift;
	
	$_ = $self->param('text');
	s/[\r\n<>]//g;
	
	CHECK: {
		unless ($_) {
			$self->flash(error => 'Empty text!');
			last CHECK;
		}
		
		if (length($_) > 100) {
			$self->flash(error => 'Phraze is too long!');
			last CHECK;
		}
		
		$self->app->db->execute('INSERT INTO phrazes (text) VALUES (?)', $_);
		$self->flash(notice => 'New phrase sucessfully saved!');
	};
	
	$self->redirect_to('/phrases');
}

# POST /phrases/:id/delete
sub delete {
	my $self = shift;
	
	$self->app->db->execute('DELETE FROM phrazes WHERE id = ?', int($self->param('id')));
	$self->flash(notice => 'Phrase deleted!');
	
	$self->redirect_to('/phrases');
}

# GET /phrases/:id/search
sub search {
	my $self = shift;	
	
	my $rows = $self->app->db->query('SELECT * FROM phrazes WHERE id = ?', int($self->param('id')))
		or die "can't find prase by id!";
		
	my $text = $rows->[0]->{text};	
	my $sql = qq{
		SELECT content,
		       paragraph_no,			   
			   title
		  FROM sentences join works ON work_id = works.id
		 WHERE content like '%$text%' COLLATE NOCASE
	     ORDER BY work_id
	};
	
	$self->stash(
		phrase => $text,
		lines => $self->app->db->query($sql)
	);
}

1;