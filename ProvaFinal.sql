CREATE TABLE jogadores(
id serial primary key,
nickname varchar(50) not null unique,
email varchar(100) not null unique,
senha text not null,
ativo boolean default true,
banido boolean default false
);

CREATE TABLE modalidades(
id serial primary key,
nome varchar(60) not null unique,
categoria varchar(50) not null
);

CREATE TABLE torneios(
id serial primary key,
nome varchar(100) not null,
data_inicio date not null,
data_fim date not null,
check (data_fim >= data_inicio)
);

CREATE TABLE partidas(
id serial primary key,
jogador_id int references jogadores(id),
modalidade_id int references modalidades(id),
torneio_id int references torneios(id),
titulo varchar(100) not null,
data_agendada timestamp not null,
data_criacao timestamp default current_timestamp,
status varchar(20) default 'Agendada'
check (status in ('Agendada','Em andamento','Finalizada','Cancelada'))
);

CREATE TABLE historico_partidas(
id serial primary key,
partida_id int references partidas(id),
acao varchar(50) not null,
descricao text not null,
data_evento timestamp default current_timestamp
);


INSERT INTO jogadores (nickname, email, senha) VALUES
('Player001', 'player001@email.com', 'senha123'),
('GamerX', 'gamerx@email.com', 'senha456'),
('ProPlayer', 'proplayer@email.com', 'senha789');

INSERT INTO modalidades (nome, categoria) VALUES
('Counter-Strike 2', 'FPS'),
('League of Legends', 'MOBA'),
('Street Fighter 6', 'Luta');

INSERT INTO torneios (nome, data_inicio, data_fim) VALUES
('Campeonato de FPS', CURRENT_DATE, CURRENT_DATE + 10),
('Torneio MOBA', CURRENT_DATE, CURRENT_DATE + 15),
('Copa de Luta', CURRENT_DATE, CURRENT_DATE + 20);

INSERT INTO partidas (jogador_id, modalidade_id, torneio_id, titulo, data_agendada) VALUES
(1, 1, 1, 'Player001 vs Adversário A', CURRENT_TIMESTAMP + INTERVAL '2 days'),
(2, 2, 2, 'GamerX vs Adversário B', CURRENT_TIMESTAMP + INTERVAL '5 days'),
(3, 3, 3, 'ProPlayer vs Adversário C', CURRENT_TIMESTAMP + INTERVAL '8 days');


CREATE OR REPLACE FUNCTION fn_validar_partida()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

IF NOT EXISTS (
SELECT 1 FROM jogadores
WHERE id = NEW.jogador_id
AND ativo = true
AND banido = false
) THEN
RAISE EXCEPTION 'Jogador inativo, banido ou não encontrado!';
END IF;

RETURN NEW;

END;
$$;


CREATE TRIGGER trg_validar_partida
BEFORE INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION fn_validar_partida();


CREATE OR REPLACE FUNCTION fn_registrar_historico()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

INSERT INTO historico_partidas (partida_id, acao, descricao)
VALUES (NEW.id, 'Criação', 'Nova partida cadastrada: ' || NEW.titulo);

RETURN NEW;

END;
$$;


CREATE TRIGGER trg_registrar_historico
AFTER INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION fn_registrar_historico();


SELECT
jogadores.nickname,
partidas.titulo,
modalidades.nome,
partidas.data_agendada,
partidas.status
FROM partidas
JOIN jogadores
ON partidas.jogador_id = jogadores.id
JOIN modalidades
ON partidas.modalidade_id = modalidades.id
WHERE partidas.status IN ('Agendada', 'Em andamento');


SELECT
partidas.titulo,
jogadores.nickname,
modalidades.nome,
partidas.data_agendada,
partidas.status
FROM partidas
JOIN jogadores
ON partidas.jogador_id = jogadores.id
JOIN modalidades
ON partidas.modalidade_id = modalidades.id
WHERE partidas.data_agendada > CURRENT_TIMESTAMP
ORDER BY partidas.data_agendada ASC;


SELECT
modalidades.nome,
COUNT(partidas.id) AS total_partidas
FROM partidas
JOIN modalidades
ON partidas.modalidade_id = modalidades.id
GROUP BY modalidades.nome;


CREATE VIEW vw_painel_torneios AS
SELECT
jogadores.nickname,
partidas.titulo,
modalidades.nome AS modalidade,
modalidades.categoria,
torneios.nome AS torneio,
partidas.data_agendada,
partidas.status
FROM partidas
JOIN jogadores
ON partidas.jogador_id = jogadores.id
JOIN modalidades
ON partidas.modalidade_id = modalidades.id
JOIN torneios
ON partidas.torneio_id = torneios.id;


SELECT * FROM vw_painel_torneios;

SELECT * FROM historico_partidas;

SELECT COUNT(*) FROM jogadores;
SELECT COUNT(*) FROM modalidades;
SELECT COUNT(*) FROM torneios;
SELECT COUNT(*) FROM partidas;
SELECT COUNT(*) FROM historico_partidas;


UPDATE jogadores
SET banido = true
WHERE id = 1;
