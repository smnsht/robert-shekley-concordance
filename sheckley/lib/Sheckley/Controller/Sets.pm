package Sheckley::Controller::Sets;
use Mojo::Base 'Mojolicious::Controller';
use List::MoreUtils qw(uniq);

use Moo;
use namespace::clean;

around qw(lines sentences) => sub {
	my $orig = shift;
	my $self = shift;	
	
	my $set = $self->_wordset();	
	my @words = split /,/, $set->{words};
	my $quoted = join ',', map { qq{"$_"} } @words;
	
	$self->stash->{wordset} = $set;
	
	$orig->($self, $quoted);
};

sub index {
	my $self = shift;
	
	$self->render(wordsets => $self->app->db->query('select * from wordsets'));	
}

sub create {
	my $self = shift;
}


sub create_POST {
	my $self = shift;
	
	my ( $v, $words ) = $self->_words();
	
	if ($v->is_valid) {
		$self->app->db->execute(q{INSERT INTO wordsets (name, description, words) VALUES (?,?,?)},
			$v->param('name'),
			$v->param('description'),
			join(',', uniq @$words)
		);
			
		$self->flash(notice => 'Wordset successfully created!');
		$self->redirect_to('/sets');
		return;	
	}
	
	$self->stash->{template} = 'sets/create';
}

sub edit {
	my $self = shift;
		
	$self->stash(wordset => $self->_wordset);
}

sub edit_POST {
	my $self = shift;
	my $id   = $self->param('id');
	
	my ( $v, $words ) = $self->_words();
	
	if ($v->is_valid) {
		$self->app->db->execute(q{UPDATE wordsets SET name=?, description=?, words=? WHERE id = ?},
			$v->param('name'),
			$v->param('description'),
			join(',', uniq @$words),
			$id
		);
			
		$self->flash(notice => 'Wordset successfully updated!');
		$self->redirect_to('/sets');
		return;
	}
	
	$self->edit();
}

sub delete {
	my $self = shift;
	my $set = $self->_wordset();
	
	$self->app->db->execute('DELETE FROM wordsets WHERE id = ?', $set->{id});
	
	$self->flash(notice => 'Wordset successfully deleted!');
	$self->redirect_to('/sets');
}

sub lines {
	my ( $self, $quoted ) = @_;
	
	my $sql = qq{
		SELECT wl.word, l.text_line_no, l.text_raw, w.title
		  FROM word_in_line wl 
		  JOIN lines l ON wl.line_id = l.id
		  JOIN works w ON wl.work_id = w.id
		 WHERE word in ($quoted)
		 ORDER BY wl.word
	};
	
	$self->stash(		
		lines => $self->app->db->query($sql)
	);
}

sub sentences {
	my ( $self, $quoted ) = @_;
	
	my $sql = qq{
		SELECT ws.word, w.title, sen.ordinal, sen.content
		  FROM word_in_sentence ws 
		  JOIN sentences sen ON ws.sentence_id = sen.id
		  JOIN works w ON sen.work_id = w.id
		 WHERE ws.word in ($quoted)
		ORDER BY ws.word, ws.work_id
	};
	
	$self->stash(
		sentences => $self->app->db->query($sql)
	);
}

#################################################

sub _words {
	my $self = shift;
	
	my $v = $self->validation;	
	$v->required('name')->size(4, 50);
	$v->required('description')->size(4, 100);
	
	my @words = ();
	if ($v->is_valid) {		
		foreach ( @{ $self->req->every_param('words') } ) {
			next unless $_;
			s/[^a-zA-Z0-9]//;
			push @words, lc($_);
		}
		
		$v->error('words', 'Word list is empty!')
			unless (scalar @words);	
	}
	
	return ($v, \@words);
}

sub _wordset {
	my $self = shift;
	my $id = $self->param('id');
	
	my $sets = $self->app->db->query('select * from wordsets where id=?', $id)
		or die "can't find wordset by id!";
	
	return $sets->[0];
}

1;