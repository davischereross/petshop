
-- BANCO DE DADOS - ACADEMIA DE GINÁSTICA
-- PostgreSQL
-- DDL + DML + DQL / VIEWS


-- DDL - CRIAÇÃO DAS 5 TABELAS

CREATE TABLE alunos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    cpf CHAR(11) UNIQUE NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE planos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) UNIQUE NOT NULL,
    valor_mensal_base DECIMAL(10,2) NOT NULL
        CHECK (valor_mensal_base > 0)
);


CREATE TABLE modalidades (
    id SERIAL PRIMARY KEY,
    plano_id INTEGER NOT NULL,
    nome VARCHAR(100) NOT NULL,
    sala VARCHAR(50) NOT NULL,
    capacidade_maxima INTEGER NOT NULL
        CHECK (capacidade_maxima > 0),
    disponivel BOOLEAN DEFAULT TRUE,

    CONSTRAINT fk_modalidade_plano
        FOREIGN KEY (plano_id)
        REFERENCES planos(id)
);


CREATE TABLE matriculas (
    id SERIAL PRIMARY KEY,
    aluno_id INTEGER NOT NULL,
    data_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Ativa' NOT NULL,

    CONSTRAINT fk_matricula_aluno
        FOREIGN KEY (aluno_id)
        REFERENCES alunos(id),

    CONSTRAINT check_status_matricula
        CHECK (status IN (
            'Ativa',
            'Cancelada',
            'Trancada'
        ))
);


CREATE TABLE itens_matricula (
    id SERIAL PRIMARY KEY,
    matricula_id INTEGER NOT NULL,
    modalidade_id INTEGER NOT NULL,
    duracao_meses INTEGER NOT NULL
        CHECK (duracao_meses > 0),
    valor_mensal_aplicado DECIMAL(10,2) NOT NULL
        CHECK (valor_mensal_aplicado > 0),
    taxa_adesao DECIMAL(10,2) DEFAULT 0.00
        CHECK (taxa_adesao >= 0),

    CONSTRAINT fk_item_matricula
        FOREIGN KEY (matricula_id)
        REFERENCES matriculas(id),

    CONSTRAINT fk_item_modalidade
        FOREIGN KEY (modalidade_id)
        REFERENCES modalidades(id)
);


-- DML - CARGA DE DADOS


-- 3 PLANOS

INSERT INTO planos (nome, valor_mensal_base)
VALUES
('VIP Premium', 180.00),
('Fitness Standard', 120.00),
('Basic Fit', 80.00);


-- 3 MODALIDADES

INSERT INTO modalidades
(plano_id, nome, sala, capacidade_maxima, disponivel)
VALUES
(1, 'Crossfit Pro', 'Arena 01', 20, TRUE),
(2, 'Pilates Avançado', 'Studio 02', 15, TRUE),
(3, 'Musculação Livre', 'Arena 03', 30, TRUE);


-- 3 ALUNOS

INSERT INTO alunos
(nome, email, cpf, telefone)
VALUES
('Lucas Martins', 'lucas@email.com', '11111111111', '(48) 99911-2233'),
('Mariana Souza', 'mariana@email.com', '22222222222', '(48) 99822-3344'),
('Gabriel Oliveira', 'gabriel@email.com', '33333333333', '(48) 99733-4455');


-- 4 MATRÍCULAS

INSERT INTO matriculas
(aluno_id, data_inicio, status)
VALUES
(1, '2026-01-10 08:00:00', 'Ativa'),
(2, '2026-02-15 09:30:00', 'Ativa'),
(3, '2026-03-01 10:00:00', 'Cancelada'),
(1, '2026-04-05 14:00:00', 'Ativa');


-- 4 ITENS DE MATRÍCULA

INSERT INTO itens_matricula
(matricula_id, modalidade_id, duracao_meses,
 valor_mensal_aplicado, taxa_adesao)
VALUES
(1, 1, 12, 180.00, 100.00),
(2, 2, 6, 120.00, 50.00),
(3, 3, 3, 80.00, 0.00),
(4, 1, 6, 180.00, 75.00);


-- Q1 - VIEW
-- MODALIDADES COM CUSTO ESTIMADO
-- Acréscimo de 10% sobre o valor base do plano

CREATE VIEW vw_modalidades_custo_estimado AS
SELECT
    mo.nome AS modalidade,
    mo.sala,
    p.nome AS plano,
    p.valor_mensal_base,
    p.valor_mensal_base * 1.10 AS valor_mensal_ajustado
FROM modalidades mo
INNER JOIN planos p
    ON mo.plano_id = p.id
ORDER BY valor_mensal_ajustado DESC;


-- Q2 - VIEW
-- MATRÍCULAS ATIVAS

CREATE VIEW vw_matriculas_ativas AS
SELECT
    a.nome AS aluno,
    a.cpf,
    mo.nome AS modalidade,
    mo.sala,
    im.duracao_meses,
    ma.data_inicio
FROM matriculas ma
INNER JOIN alunos a
    ON ma.aluno_id = a.id
INNER JOIN itens_matricula im
    ON ma.id = im.matricula_id
INNER JOIN modalidades mo
    ON im.modalidade_id = mo.id
WHERE ma.status = 'Ativa';


-- Q3 - VIEW
-- ALUNOS VIP
--
-- Cálculo:
-- (valor mensal aplicado × duração) + taxa de adesão
--
-- Somente matrículas ativas
-- Somente alunos com mais de R$ 1.000,00 investidos

CREATE VIEW vw_alunos_vip AS
SELECT
    a.nome AS aluno,
    COUNT(im.id) AS quantidade_contratos_ativos,
    SUM(
        (im.valor_mensal_aplicado * im.duracao_meses)
        + im.taxa_adesao
    ) AS valor_total_investido
FROM alunos a
INNER JOIN matriculas ma
    ON a.id = ma.aluno_id
INNER JOIN itens_matricula im
    ON ma.id = im.matricula_id
WHERE ma.status = 'Ativa'
GROUP BY a.id, a.nome
HAVING SUM(
    (im.valor_mensal_aplicado * im.duracao_meses)
    + im.taxa_adesao
) > 1000.00;


-- Q4 - CONSULTA
-- Capacidade >= 15
-- Plano > R$ 100,00
-- Modalidade disponível

SELECT
    mo.nome AS modalidade,
    mo.sala,
    mo.capacidade_maxima,
    p.nome AS plano,
    p.valor_mensal_base,
    mo.disponivel
FROM modalidades mo
INNER JOIN planos p
    ON mo.plano_id = p.id
WHERE mo.capacidade_maxima >= 15
  AND p.valor_mensal_base > 100.00
  AND mo.disponivel = TRUE
ORDER BY p.valor_mensal_base DESC;


-- Q5 - VIEW
-- FATURAMENTO MÉDIO POR PLANO
--
-- Apenas matrículas ativas

CREATE VIEW vw_faturamento_medio_plano AS
SELECT
    p.nome AS plano,
    SUM(
        (im.valor_mensal_aplicado * im.duracao_meses)
        + im.taxa_adesao
    ) AS faturamento_total,
    AVG(im.duracao_meses) AS media_duracao_meses
FROM planos p
INNER JOIN modalidades mo
    ON p.id = mo.plano_id
INNER JOIN itens_matricula im
    ON mo.id = im.modalidade_id
INNER JOIN matriculas ma
    ON im.matricula_id = ma.id
WHERE ma.status = 'Ativa'
GROUP BY p.id, p.nome
ORDER BY faturamento_total DESC;


-- CONSULTANDO AS VIEWS

SELECT * FROM vw_modalidades_custo_estimado;

SELECT * FROM vw_matriculas_ativas;

SELECT * FROM vw_alunos_vip;

SELECT * FROM vw_faturamento_medio_plano;
