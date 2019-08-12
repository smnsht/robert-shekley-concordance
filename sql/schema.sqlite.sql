

CREATE TABLE series (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  title text NOT NULL ,
  description text NOT NULL 
);
 


CREATE TABLE works (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  series_id int,
  type text NOT NULL,		-- novel | short_story | nonfiction
  pub_date TEXT NOT NULL , 
  title TEXT NOT NULL ,
  raw_doc text,
  words_c int, 
  letters_c int
);


CREATE TABLE lines (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  work_id int NOT NULL,
  text_line_no int NOT NULL,
  file_line_no int NOT NULL,
  paragraph_no int NOT NULL,
  text_raw text NOT NULL,
  text_norm text NOT NULL,
  words_c int NOT NULL, 
  letters_c int NOT NULL
);


CREATE TABLE sentences (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  work_id int NOT NULL,  
  ordinal int NOT NULL,
  paragraph_no int NOT NULL,
  content text NOT NULL 
);


CREATE TABLE word_in_line (
  word text NOT NULL ,
  line_id int NOT NULL,
  work_id int NOT NULL
);


CREATE TABLE word_in_sentence (
  word text NOT NULL ,
  sentence_id int NOT NULL,
  work_id int NOT NULL 
);

CREATE TABLE phrazes (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  text text NOT NULL 
);


CREATE TABLE wordsets (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name text NOT NULL ,
  description text NOT NULL ,
  words text NOT NULL 
);


