package Sheckley::Controller::Works;

use Mojo::Base 'Mojolicious::Controller';
use Lingua::EN::Sentence qw(get_sentences);
use List::MoreUtils qw(uniq);

use Moo;
use namespace::clean;

my @work_types = ('novel', 'short_story', 'nonfiction');


before qw/show lines sentences/ => sub {
	my $self = shift;
	
	my $w_id  = $self->param('id');
	my $works = $self->app->db->query('select * from works where id = ?', $w_id)
		or die "can't find work by id: $w_id";
		
	$self->stash->{work} = $works->[0];
};

sub index {
	my $self = shift;
	
	my $sql = q{
		SELECT w.id,
		       w.type,
			   w.pub_date,
			   w.title,
			   w.words_c,
			   w.letters_c,
			   s.title AS ser_title
		  FROM works w
		  LEFT JOIN series s ON w.series_id = s.id
	};
	$self->stash->{works} = $self->app->db->query($sql)
}

sub create {
	my $self = shift;
	
	my $series = $self->app->db->query('SELECT id, title FROM series');
	
	$self->stash(
		template => 'works/create',
		work_types => [ map { [ucfirst($_) => $_] } @work_types ],	
		series => [['--select from list' => ''], map { [$_->{title} => $_->{id} ] } @$series]
	);	
}

sub create_POST {
	my $self = shift;
	
	my $v = $self->validation;
	$v->required('title')->size(5, 100);
	$v->required('type')->in(@work_types);
	$v->required('pub_date')->like(qr/^(\d\d\d\d)-(\d\d)-(\d\d)$/);	
	$v->optional('series_id')->like(qr/^\d+$/);	
	$v->required('line_start')->like(qr/^\d+$/);
	$v->required('line_end')->like(qr/^\d+$/);
	
	if ( $v->is_valid ) {
		
		my $upload = $self->req->upload('upload');
		if ($upload->size) {
			my $work_id;
			$self->app->db->connector->txn(fixup => sub {
				$work_id = _parse_file($_,	$v->output, $upload->slurp);
			});
			
			$self->flash(notice => 'Work successfully parsed and saved!');			
			$self->redirect_to("/works/$work_id");
			return;
		}
		
		$v->error('upload', 'Upload is empty!');		
	}
	
	$self->create();
}

sub show {
	my $self = shift;
	
	my $w_id = $self->param('id');	
	my $work = $self->stash->{work};
	my $raw_lines = "\r\n";
	my $line = 1;
	
	foreach ( split /\r\n/, $work->{raw_doc} ) {		
		$raw_lines .= "$line\t$_\r\n";	
		$line++;
	}
	
	$self->stash(raw_lines => $raw_lines);
	
	if ($work->{series_id}) {
		my $series = $self->app->db->query('SELECT * FROM series where id=?', $work->{series_id});	
		$self->stash(series => $series->[0]);
	}	
}

sub delete {
	my $self = shift;
	my $w_id = int($self->param('id'));
	
	$self->app->db->connector->txn(fixup => sub {
		$_->do("DELETE FROM word_in_sentence WHERE work_id = $w_id");
		$_->do("DELETE FROM word_in_line WHERE work_id = $w_id");
		$_->do("DELETE FROM sentences WHERE work_id = $w_id");
		$_->do("DELETE FROM lines WHERE work_id = $w_id");
		$_->do("DELETE FROM works WHERE id = $w_id");
	});
	
	$self->flash(notice => 'Work successfully deleted!');			
	$self->redirect_to("/works");
}

sub lines {
	my $self = shift;	
	my $w_id = $self->param('id');
	
	my $sql = q{
		SELECT wl.word, l.text_line_no
		  FROM word_in_line wl JOIN lines l
			ON wl.line_id = l.id
		 WHERE wl.work_id = ?
		ORDER BY wl.word
	};
	
	my $rows = $self->app->db->query($sql, $w_id);
	my %index = ();
	
	foreach (@$rows) {
		my ($w, $lno) = ( $_->{word}, $_->{text_line_no} );
		unless (exists $index{$w}) {
			$index{$w} = [];
		}
		push @{ $index{$w} }, $lno;
	}
	
	$self->stash->{index} = \%index;
	$self->stash->{lines} = $self->app->db->query('select * from lines where work_id = ?', $w_id);
}

sub sentences {
	my $self = shift;	
	my $w_id = $self->param('id');
	
	
	my $sql = q{
		SELECT *
		  FROM word_in_sentence			
		 WHERE work_id = ?	
	};
	
	my $rows = $self->app->db->query($sql, $w_id);
	my %index = ();
	
	foreach (@$rows) {
		my ($w, $sid) = ( $_->{word}, $_->{sentence_id} );
		unless (exists $index{$w}) {
			$index{$w} = [];
		}
		push @{ $index{$w} }, $sid;
	}
	
	$self->stash->{index} = \%index;
	$self->stash->{sentences} = $self->app->db->query('select * from sentences where work_id = ?', $w_id);
}

#######################################################################################
my %Skip_Words = (
	0 => 1,
	1 => 1,
	2 => 1,
	3 => 1,
	4 => 1,
	5 => 1,
	6 => 1,
	7 => 1,
	8 => 1,
	9 => 1,
	a => 1,
	i => 1,
	if => 1,
	in => 1,	
	am => 1,
	an => 1,
	is => 1,
	it => 1,
	as => 1,
	at => 1,
	be => 1,
	by => 1,
	do => 1,
	to => 1,
	he => 1,
	me => 1,
	my => 1,
	no => 1,
	of => 1,
	on => 1,
	or => 1,
	so => 1,
	all => 1,
	and => 1,
	any => 1,
	are => 1,
	and => 1,
	for => 1,
	had => 1,
	has => 1,
	not => 1,
	was => 1,
	have => 1,
	him => 1,
	his => 1,
	the => 1,
	yes => 1,
	but => 1,
	you => 1,
	your => 1,
	dont => 1,
	that => 1,
	they => 1,
	with => 1,
	these => 1,
	this => 1,
	been => 1,
	would => 1
);

sub _parse_file {
	my ( $dbh, $output, $content ) = @_;	
	
	my $start = $output->{line_start};			# skip file lines until this line
	my $end = $output->{line_end};				# skip file lines after this line	
	
	my $file_line = 0;							# current file line - including blanks
	my $line_no = 1;							# current non-blank text line no
	my $para_no = 1;							# current para. no
	my $sent_no = 1;							# current sentence no.
	
	my $para_text = '';
	my $line_raw = '';
	
	# insert new work	
	my $work_id = _insert_work($dbh, $output, $content);

	foreach ( split /\r\n/, $content ) {
		$file_line++;
		
		last if ($file_line >= $end);
		next if ($file_line < $start);		
		
		if (m/(?:\s+)\*(?:\s+)\*(?:\s+)\*(?:\s+)\*(?:\s+)\*(?:\s*)/) {
			
			# paragraph end found			
			my $a = get_sentences($para_text);			
			_insert_sentence($dbh, $work_id, $para_no, $a);
			
			$para_no++;					# increment paragraph's ordinal
			$para_text = '';			# reset paragraph
		}
		else {			
			$line_raw = $_;				# preserve raw text line			
			$para_text .= "$_\r\n";		# append line to paragraph
		
			s/[[:punct:]]//g;			# remove punctuation
			s/[\r\n]+$//;				# remove trailing newline chars
			my @words = split /\s+/;
			my $words_c = scalar( @words );
			
			next unless $words_c;
			
			$dbh->do('INSERT INTO lines (work_id, text_line_no, file_line_no, paragraph_no, text_raw, text_norm, words_c, letters_c) VALUES (?,?,?,?,?,?,?,?)',
					 undef,
					 $work_id,
					 $line_no,
					 $file_line,
					 $para_no,
					 $line_raw,
					 lc($_),
					 $words_c,
					 length( join '', @words )
			);
			
			my $line_id = $dbh->last_insert_id(undef, undef, 'lines', 'id')
				or die "can't obtain new line id!";
				
			foreach my $word ( uniq @words ) {
				$word = lc($word);
				
				next if ( exists $Skip_Words{$word} );
				
				$dbh->do('INSERT INTO word_in_line (word, line_id, work_id) VALUES (?,?,?)',
					undef,
					$word, $line_id, $work_id );	
			}			
			
			$line_no++;
		}
	}
	
	# last paragraph
	my $a = get_sentences($para_text);			
	_insert_sentence($dbh, $work_id, $para_no, $a);
		
	$dbh->do(qq{
		UPDATE works SET 
			words_c = (select sum(words_c) from lines where work_id = $work_id),
			letters_c = (select sum(letters_c) from lines where work_id = $work_id)
		WHERE id = $work_id
	});
	
	return $work_id;
}

sub _insert_work {
	my ( $dbh , $output, $raw_doc ) = @_;
	
	my $insert = qq{
		INSERT INTO works (series_id, type, pub_date, title, raw_doc, words_c, letters_c)
		VALUES (?, ?, ?, ?, ?, ?, ?)
	};
	
	$dbh->do($insert, undef,
			 $output->{series_id} || undef,
			 $output->{type},
			 $output->{pub_date},
			 $output->{title},
			 $raw_doc,
			 0, 0
	);
	
	my $work_id = $dbh->last_insert_id(undef, undef, 'lines', 'id')
		or die "can't obtain new work id!";
	
	return $work_id;
}


sub _insert_sentence {
	my ($dbh, $work_id, $para_no, $ary_ref) = @_;
		
	# last sentence ordinal?	
	my $sql = "select coalesce(count(id), 0) from sentences where work_id = $work_id";
	my $ordinal = ($dbh->selectrow_array($sql))[0];
	
	foreach my $content(@$ary_ref) {
		
		$content =~ s/\r\n/ /g;				# replce new line with space
		$ordinal++;							# increment sentence number
		
		$dbh->do('INSERT INTO sentences (work_id, ordinal, paragraph_no, content) VALUES (?, ?, ?, ?)',
			undef,
			$work_id,			
			$ordinal,
			$para_no,
			$content
		);
	
		my $s_id = $dbh->last_insert_id(undef, undef, 'sentences', 'id')
			or die "can't obtain new sentence id!";
		
		$content =~ s/[[:punct:]]//g;			# remove punctuation
		
		foreach ( uniq(split /\s+/, lc($content)) ) {
			next if ( exists $Skip_Words{$_} );
			
			$dbh->do('INSERT INTO word_in_sentence (word, sentence_id, work_id) VALUES (?,?,?)',
				undef,
				$_, $s_id, $work_id
			);
		}		
	}	
}

1;

