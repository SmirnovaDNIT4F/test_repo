
---------------------------------------------------------------------------------------------------------
-- Создаем таблицу actions, которая будет содержать данные о присвоении рейтинговыми агентствами рейтингов 
-- российским компаниям

CREATE TABLE public.actions
(
    rat_id smallint NOT NULL,
	grade text NOT NULL,
    outlook text,
    change text NOT NULL,
    date date NOT NULL,
    ent_name text NOT NULL,
	okpo integer NOT NULL,
	ogrn bigint,
	inn bigint,
	finst integer,
	agency_id text NOT NULL,
	rat_industry text,
	rat_type text,
	horizon text,
	scale_typer text,
	currency text,
	backed_flag text
)

TABLESPACE pg_default;

ALTER TABLE public.actions OWNER to postgres;
COMMENT ON TABLE public.actions
    IS 'Таблица содержит данные о присвоении рейтинговыми агентствами рейтингов российским компаниям';

---------------------------------------------------------------------------------------------------------
-- Создаем таблицу events, которая будет содержать данные о кредитных событиях, связанных с компаниями

CREATE TABLE public.events

(
    inn bigint NOT NULL,
    date date NOT NULL,
    event text NOT NULL
)

TABLESPACE pg_default;

ALTER TABLE public.events OWNER to postgres;
COMMENT ON TABLE public.events
    IS 'Таблица содержит данные о кредитных событиях, связанных с компаниями';

---------------------------------------------------------------------------------------------------------
-- Создаем таблицу scale_exp, которая будет содержать данные о числовой кодификации агенства Эксперт РА (EXP)

CREATE TABLE public.scale_exp
(
    grade text COLLATE pg_catalog."default" NOT NULL,
    grade_id smallint NOT NULL,
    CONSTRAINT scale_exp_pkey PRIMARY KEY (grade)
)

TABLESPACE pg_default;

ALTER TABLE public.scale_exp OWNER to postgres;
COMMENT ON TABLE public.scale_exp
    IS 'Таблица содержит данные о числовой кодификации агенства Эксперт РА (EXP)';

---------------------------------------------------------------------------------------------------------
-- Импортируем данные из файлов в созданные таблицы

-- ratings_task -> actions
-- credit_events_task -> events
-- scale_EXP_task -> scale_exp

---------------------------------------------------------------------------------------------------------
-- Создаем таблицу rat_info, которая будет содержать информацию о рейтингах

CREATE TABLE public.rat_info
(
    rat_id smallint NOT NULL,
    agency_id text,
	rat_industry text,
	rat_type text,
	horizon text,
	scale_typer text,
	currency text,
	backed_flag text,
    CONSTRAINT rat_info_pkey PRIMARY KEY (rat_id)
)

TABLESPACE pg_default;

ALTER TABLE public.rat_info OWNER to postgres;

---------------------------------------------------------------------------------------------------------
-- Замечаем, что в таблице actions столбец rat_id не сможет являться первичным ключом в таблице rat_info, так как
-- он неоднозначно описывает всю информацию о рейтингах, поэтому удаляем его из таблицы actions

ALTER TABLE actions DROP COLUMN rat_id;

---------------------------------------------------------------------------------------------------------
-- Из таблицы actions запрашиваем информацию о рейтингах, которая содержится в столбцах agency_id, rat_industry,
-- rat_type, horizon, scale_typer, currency, backed_flag, а также создаем первичный ключ rat_id для таблицы 
-- rat_info, чтобы в дальнейшем связать данную таблицу с таблицей actions

INSERT INTO rat_info
SELECT COUNT(*) OVER
(ORDER BY agency_id, rat_industry, rat_type, horizon, scale_typer, currency, backed_flag) AS rat_id,
agency_id, rat_industry, rat_type, horizon, scale_typer, currency, backed_flag
FROM (SELECT DISTINCT agency_id, rat_industry, rat_type, horizon, scale_typer, currency, backed_flag
FROM actions) as sample;

---------------------------------------------------------------------------------------------------------
-- Добавляем в таблицу actions поля с кодами-ссылками на столбец rat_id таблицы rat_info

ALTER TABLE actions ADD COLUMN rat_id smallint;

---------------------------------------------------------------------------------------------------------
-- Заполняем поле с кодами-ссылками rat_id данными из таблицы rat_info

UPDATE actions
SET rat_id = rat_info.rat_id
FROM rat_info
WHERE actions.agency_id = rat_info.agency_id AND
(actions.rat_industry = rat_info.rat_industry 
OR (actions.rat_industry is null and rat_info.rat_industry is null)) AND
(actions.rat_type = rat_info.rat_type 
OR (actions.rat_type is null and rat_info.rat_type is null)) AND
(actions.horizon = rat_info.horizon 
OR (actions.horizon is null and rat_info.horizon is null)) AND
(actions.scale_typer = rat_info.scale_typer 
OR (actions.scale_typer is null and rat_info.scale_typer is null)) AND
(actions.currency = rat_info.currency 
OR (actions.currency is null and rat_info.currency is null)) AND
(actions.backed_flag = rat_info.backed_flag 
OR (actions.backed_flag is null and rat_info.backed_flag is null));

---------------------------------------------------------------------------------------------------------
-- Присваиваем полю rat_id ограничение внешнего ключа

ALTER TABLE public.actions
ADD CONSTRAINT fr_key_2 FOREIGN KEY (rat_id) REFERENCES public.rat_info (rat_id);

---------------------------------------------------------------------------------------------------------
-- Удаляем вынесенную информацию из таблицы actions

alter table public.actions
drop column agency_id,
drop column rat_industry,
drop column rat_type,
drop column horizon,
drop column scale_typer,
drop column currency,
drop column backed_flag;

---------------------------------------------------------------------------------------------------------
-- Создаем таблицу company, которая будет содержать информацию о рейтингуемом лице. Назначаем столбец ent_name 
-- первичным ключом таблицы company, чтобы в дальнейшем связать данную таблицу с таблицей actions

CREATE TABLE public.company
(
    "ent_name" text NOT NULL,
    "okpo" integer NOT NULL,
	"ogrn" bigint,
	"inn" bigint,
	"finst" integer,
	CONSTRAINT company_pkey PRIMARY KEY (ent_name)
)

TABLESPACE pg_default;

ALTER TABLE public.company OWNER to postgres;

---------------------------------------------------------------------------------------------------------
-- Из таблицы actions запрашиваем информацию о рейтингумом лице, которая содержится в столбцах ent_name, okpo,
-- ogrn, inn, finst

INSERT INTO company
SELECT DISTINCT ent_name, okpo, ogrn, inn, finst
FROM actions
ORDER BY ent_name;

---------------------------------------------------------------------------------------------------------
-- Присваиваем полю ent_name в таблице actions ограничение внешнего ключа

ALTER TABLE public.actions
ADD CONSTRAINT fr_key_1 FOREIGN KEY (ent_name) REFERENCES public.company (ent_name);

---------------------------------------------------------------------------------------------------------
-- Удаляем вынесенную информацию из таблицы actions

alter table public.actions
drop column okpo,
drop column ogrn,
drop column inn,
drop column finst;


---------------------------------------------------------------------------------------------------------
-- В сформированной базе данных составляем запрос, который выводит для выбранного вида рейтинга (например, 50) и
-- даты (например, 12.01.2014) в таблице actions актуальные рейтинги. Актуальным рейтингом признается значение
-- присвоенное или подтвержденное последним рейтинговым действием до исследуемой даты при условии, что это было не
-- снятие рейтинга и не его приостановление.

select ent_name, grade, assign_date
from public.actions inner join
(select max(date) as assign_date, ent_name as ent2_name
from public.actions
where rat_id = 50
AND date <= '12-01-2014'
group by ent_name) as zapros1
on public.actions.date = zapros1.assign_date
and public.actions.ent_name = zapros1.ent2_name
where change <> 'снят' 
and change <> 'приостановлен' 
and rat_id = 50;

---------------------------------------------------------------------------------------------------------



