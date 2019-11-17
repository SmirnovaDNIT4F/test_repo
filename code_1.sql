-- 1.1 Создаем таблицу credit_events_task в БД с требуемым составом полей в нужных форматах

CREATE TABLE public.credit_events_task
(
    "inn" bigint NOT NULL,
    "date" date NOT NULL,
    "event" text NOT NULL
)

WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

-- 1.2 Назначение владельца таблицы
ALTER TABLE public.credit_events_task
    OWNER to postgres;
	
-- 1.3 Импортируем данные из cvs файла в таблицу credit_events_task. Необходимо убедиться, что загружаемый файл находится в папке с публичным 
--доступом (~\User\Public)
copy public.credit_events_task  FROM 'C:\Users\Public\credit_events_task.csv' DELIMITER ';' CSV HEADER;

-- 2.1 Создаем таблицу scale_exp_task в БД с требуемым составом полей в нужных форматах и назначаем столбец grade_id в качестве 
-- первичного ключа

CREATE TABLE public.scale_exp_task
("grade" text NOT NULL,
    "grade_id" smallint NOT NULL,
    CONSTRAINT scale_exp_task_pkey PRIMARY KEY ("grade_id"))
WITH (OIDS = FALSE)
TABLESPACE pg_default;

-- 2.2 Назначение владельца таблицы

ALTER TABLE public.scale_exp_task
    OWNER to postgres;
	
	-- 2.3 Импортируем данные из файла в таблицу scale_exp_task с помощью терминала SQL Shell, предварительно установив 
	-- русскую раскладку.
\! chcp 1251
\copy public.scale_exp_task FROM 'C:\Users\Public\scale_EXP_task.csv' DELIMITER ';' CSV HEADER;


-- 3.1 Создаем таблицу ratings_task в БД с требуемым составом полей в нужных форматах

CREATE TABLE public.ratings_task
("rat_id" smallint NOT NULL,
    "grade" text NOT NULL,
    "outlook" text,
    "change" text NOT NULL,
    "date" date NOT NULL,
    "ent_name" text NOT NULL,
    "okpo" bigint NOT NULL,
    "ogrn" bigint,
    "inn" bigint,
    "finst" bigint,
    "agency_id" text NOT NULL,
    "rat_industry" text,
    "rat_type" text NOT NULL,
    "horizon" text,
    "scale_typer" text,
    "currency" text,
    "backed_flag" text
  )
WITH (OIDS = FALSE)
TABLESPACE pg_default;

-- 3.2 Назначение владельца таблицы

ALTER TABLE public.ratings_task
    OWNER to postgres;
	
-- 3.3 Импортируем данные из cvs файла в таблицу ratings_task. Необходимо убедиться, что загружаемый файл находится в папке с публичным 
--доступом (~\User\Public)
	
copy public.ratings_task FROM 'C:\Users\Public\ratings_task.csv' DELIMITER ';' CSV HEADER;

-- 4.1 Создание отдельной таблицы ratings_info, содержащей информацию о рейтингах, и добавление столба rat_key, содержащего 
-- порядковый номер вида рейтинга, в качестве первичного ключа

CREATE TABLE public.ratings_info
(
	"rat_key" bigint NOT NULL,
    "rat_id" smallint NOT NULL,
    "agency_id" text NOT NULL,
    "rat_industry" text,
    "rat_type" text NOT NULL,
    "horizon" text,
    "scale_typer" text,
    "currency" text,
    "backed_flag" text,
    CONSTRAINT some_name PRIMARY KEY ("rat_key")
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.ratings_info
    OWNER to postgres;
	
-- 4.2 Вынос из таблицы ratings_task информации о каждом виде рейтинга (описание) в отдельную таблицу rating_info, а также заполнение 
-- столбца rat_key числами по порядку

insert into ratings_info select count(*) over (order by "rat_id", "agency_id", "rat_industry", "rat_type", 
											   "horizon", "scale_typer", "currency", "backed_flag") as rate_key,
											   "rat_id", "agency_id", "rat_industry", "rat_type", "horizon", 
											   "scale_typer", "currency", "backed_flag"
from (select distinct "rat_id", "agency_id", "rat_industry", "rat_type", "horizon", "scale_typer", "currency", "backed_flag"
from public.ratings_task)
as tbl;

-- 4.3 Добавление в таблицу ratings_task поля с кодами-ссылками на таблицу ratings_info
alter table ratings_task add column "rat_key" bigint;

-- 4.4 Заполнение поля с кодами-ссылками на таблицу ratings_info
update ratings_task
set rat_key=ratings_info.rat_key
from ratings_info
where ratings_task."rat_id"=ratings_info."rat_id" AND ratings_task."agency_id"=ratings_info."agency_id" 
AND ratings_task."rat_industry"=ratings_info."rat_industry" 
AND ratings_task."rat_type"=ratings_info."rat_type" 
AND ratings_task."horizon"=ratings_info."horizon" 
AND ratings_task."scale_typer"=ratings_info."scale_typer" 
AND ratings_task."currency"=ratings_info."currency";

-- 4.5 Присвоение полю rat_key в таблице ratings_task ограничения внешнего ключа
ALTER TABLE public.ratings_task
ADD CONSTRAINT fr_key_1 FOREIGN KEY (rat_key) REFERENCES public.ratings_info (rat_key);


-- 5.1 Создание отдельной таблицы ent_info, содержащей информацию о рейтингуемом лице, и добавление столба ent_id, содержащего 
-- порядковый номер компании, в качестве первичного ключа

CREATE TABLE public.ent_info
(
    "ent_id" bigint NOT NULL,
    "ent_name" text NOT NULL,
    "okpo" bigint NOT NULL,
    "ogrn" bigint,
    "inn" bigint,
    "finst" bigint,
    CONSTRAINT somename PRIMARY KEY ("ent_id")
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.emitent
    OWNER to postgres;

-- 5.2 Вынос из таблицы ratings_task информации о рейтингуемом лице в отдельную таблицу ent_info, а также заполнение 
-- столбца ent_id числами по порядку

insert into ent_info select count(*) over (order by "ent_name", "okpo", "ogrn", "inn", "finst") as ent_id,
"ent_name", "okpo", "ogrn", "inn", "finst"
from (select distinct "ent_name", "okpo", "ogrn", "inn", "finst"
from public.ratings_task)
 as num;

-- 5.3 Добавление в таблицу ratings_task поля с кодами-ссылками на таблицу ent_info
alter table ratings_task add column "ent_id" bigint;

-- 5.4 Заполнение поля с кодами-ссылками на таблицу ent_info
update ratings_task
set ent_id=ent_info.ent_id
from ent_info
where ratings_task."ent_name"=ent_info."ent_name"
;

-- 5.5 Присвоение полю ent_id в таблице ratings_task ограничения внешнего ключа
ALTER TABLE public.ratings_task
ADD CONSTRAINT fr_key_2 FOREIGN KEY (ent_id) REFERENCES public.ent_info (ent_id);

-- 5.6 Удаление вынесенной информации из исходной таблицы ratings_task, а именно столбцов 
-- "rat_id", "agency_id", "rat_industry", "rat_type", "horizon", "scale_typer", "currency", "backed_flag", 
-- "ent_name", "okpo", "ogrn", "inn", "finst"

alter table public.ratings_task
drop column "rat_id",
drop column "agency_id",
drop column "rat_industry",
drop column "rat_type",
drop column "horizon",
drop column "scale_typer",
drop column "currency",
drop column "backed_flag",
drop column "ent_name",
drop column "okpo",
drop column "ogrn",
drop column "inn",
drop column "finst";

-- 6. Выведение актуальных рейтингов на 11.11.2014 для вида рейтинга с числовым кодом 47.

select "assing_date", "ent_name", "grade"
from (select assing_date, ent_id, public.ent_info."ent_name"
from (select "ent_name", max("date") as assing_date
from public.ent_info INNER JOIN 
	(select *
	from public.ratings_task INNER JOIN public.ratings_info
	ON public.ratings_task."rat_key"=public.ratings_info."rat_key" 
	WHERE "rat_id"=47 AND "change" NOT IN ('снят', 'приостановлен') AND "date" <= '11.11.2014') as first_name
	ON public.ent_info."ent_id"=first_name."ent_id"
GROUP BY "ent_name") as sec_name
INNER JOIN public.ent_info ON sec_name."ent_name"=public.ent_info."ent_name") as thrd_name
INNER JOIN public.ratings_task ON thrd_name."assing_date"=public.ratings_task."date"
AND thrd_name."ent_id"=public.ratings_task."ent_id" 
; 




