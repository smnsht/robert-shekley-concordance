package Sheckley::Controller::Root;
use Mojo::Base 'Mojolicious::Controller';

sub index {
	my $self = shift;
	
	$self->stash(
		series => $self->app->db->query('select * from series'),
		w_index => [ map { qq(<a href="/words/$_">$_</a>) } 'A'..'Z' ]
	);	
}

# GET /words/:letter
sub words {
	my $self = shift;
	my $letter = lc($self->param('letter'));
	
	#WHERE substr(word, 1, 1) = ?
	my $sql_l = q{
		SELECT word, count(*) AS count
		  FROM word_in_line 
		 WHERE first_letter = ?
		GROUP BY word
		ORDER BY word
	};
	
	#WHERE substr(word, 1, 1) = ?
	my $sql_s = q{
		SELECT word, count(*) AS count
		  FROM word_in_sentence
		 WHERE first_letter = ?
		GROUP BY word
		ORDER BY word
	};
	
	$self->stash(
		words_l => $self->app->db->query($sql_l, $letter),
		words_s => $self->app->db->query($sql_s, $letter)
	);
}

# GET /words/:word/lines
sub lines {
	my $self = shift;
	my $word = lc($self->param('word'));
	
	my $sql = qq{
		SELECT wl.word, l.text_line_no, l.text_raw, w.title
		  FROM word_in_line wl 
		  JOIN lines l ON wl.line_id = l.id
		  JOIN works w ON wl.work_id = w.id
		 WHERE word = ?
		 ORDER BY wl.word
	};
	
	$self->stash(		
		lines => $self->app->db->query($sql, $word)
	);
}

# GET /words/:word/sentences
sub sentences {
	my ( $self, $quoted ) = @_;
	my $word = lc($self->param('word'));
	
	my $sql = qq{
		SELECT ws.word, w.title, sen.ordinal, sen.content
		  FROM word_in_sentence ws 
		  JOIN sentences sen ON ws.sentence_id = sen.id
		  JOIN works w ON sen.work_id = w.id
		 WHERE ws.word = ?
		ORDER BY ws.word, ws.work_id
	};
	
	$self->stash(
		sentences => $self->app->db->query($sql, $word)
	);
}


1;