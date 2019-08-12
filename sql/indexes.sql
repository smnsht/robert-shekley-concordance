
CREATE TABLE word_in_line (
  word text NOT NULL ,
  line_id int NOT NULL,
  work_id int NOT NULL
);

ALTER TABLE word_in_line ADD COLUMN first_letter TEXT;
UPDATE word_in_line SET first_letter = SUBSTR(word, 1, 1);
CREATE INDEX idx_first_letter_word_in_line ON word_in_line(first_letter); 


ALTER TABLE word_in_sentence ADD COLUMN first_letter TEXT;
UPDATE word_in_sentence SET first_letter = SUBSTR(word, 1, 1);
CREATE INDEX idx_first_letter_word_in_sentence ON word_in_sentence(first_letter); 	

CREATE INDEX idx_word_word_in_line ON word_in_line(word); 	


EXPLAIN QUERY PLAN
SELECT word, count(*) AS count
  FROM word_in_line 
 WHERE first_letter = 'a'
 GROUP BY word
ORDER BY word




EXPLAIN QUERY PLAN
SELECT word, count(*) AS count
  FROM word_in_sentence
 WHERE first_letter = 'a'
 GROUP BY word
ORDER BY word


EXPLAIN QUERY PLAN
SELECT wl.word, l.text_line_no, l.text_raw, w.title
  FROM word_in_line wl 
  JOIN lines l ON wl.line_id = l.id
  JOIN works w ON wl.work_id = w.id
 WHERE word = 'danger'
 ORDER BY wl.word
