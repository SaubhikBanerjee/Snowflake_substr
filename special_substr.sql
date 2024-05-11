/*
The problem statement: Data is coming from source system in varipous languages. The staging table 
is a has varchar(255) column to hold that data. But in the dowstream somewhere only 25 bytes are needed.
Even if we try to do substr(text_col,1,25) the inserttion is failing. The root cause is multi byte characters. UTF-8 characters are counted as a single character in substr even if they are more than one byte.
Table test_substr is created to demostrate this test case.
*/
create or replace table test_substr (
  keyid integer default NULL,
  text_col varchar(255) default NULL);

insert into test_substr(keyid, text_col) values
(1, '56, Briji West Near Gaji Pukur'),
(2, 'P.O: Garia Kolkata 700084'),
(3, '56, Briji West nära Ghazi Pukur'),  
(4, 'ص.ب: جاريا كولكاتا 700084'),
(5, 'P.O: গড়িয়া কলকাতা 700084'),
(6, '邮政信箱：加利亚加尔各答 700084'),
(7, 'Yóuzhèng xìnxiāng: Jiā lì yǎ jiāěrgèdá 700084'),
(8, 'Kolkata Yóuzhèng ريا كول Garia nära'),
(9, 'Briji West in der Nähe von Ghazi Pukur'),
(10, 'Briji West in der Nahe von Ghazi Pukur'),
(11, '邮政信箱：加利亚加尔各答'),
(12, 'ريا كولكاتا ');

create or replace function special_substr(input_str string, input_length integer)
returns string
language python
runtime_version = 3.8
packages = ()
handler = 'udf'
as $$
import string

def udf(input_str, input_length):
    total_length = 0
    substr = ''
    for char in input_str:
        total_length = total_length + len(char.encode('utf-8'))
        if total_length <= input_length:
            substr = substr + char
        else:
            break
    return substr

$$;

select text_col, special_substr(text_col, 25) from test_substr;

-- You can see the difference with this query.
-- Specially look for the non english data!!
select text_col, special_substr(text_col, 25) python_udf
, substr(text_col,1,25 - (octet_length (text_col)-length(text_col))) octet_len
, substr(text_col,1,25) simple_substr
from test_substr;


