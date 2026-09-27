
-- MEDCARE - BANCO DE DADOS
-- PostgreSQL
-- DDL + DML + DQ

-- DDL - CRIAÇÃO DAS 5 TABELA

CREATE TABLE pacientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    cpf CHAR(11) UNIQUE NOT NULL,
    data_nascimento DATE NOT NULL,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE especialidades (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) UNIQUE NOT NULL
);


CREATE TABLE medicos (
    id SERIAL PRIMARY KEY,
    especialidade_id INTEGER NOT NULL,
    nome VARCHAR(100) NOT NULL,
    crm VARCHAR(20) UNIQUE NOT NULL,
    valor_consulta DECIMAL(10,2) NOT NULL
        CHECK (valor_consulta > 0),

    FOREIGN KEY (especialidade_id)
        REFERENCES especialidades(id)
);


CREATE TABLE consultas (
    id SERIAL PRIMARY KEY,
    medico_id INTEGER NOT NULL,
    paciente_id INTEGER NOT NULL,
    data_hora TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'Agendada' NOT NULL,

    FOREIGN KEY (medico_id)
        REFERENCES medicos(id),

    FOREIGN KEY (paciente_id)
        REFERENCES pacientes(id),

    CHECK (status IN (
        'Agendada',
        'Realizada',
        'Cancelada'
    ))
);


CREATE TABLE exames_consulta (
    id SERIAL PRIMARY KEY,
    consulta_id INTEGER NOT NULL,
    nome_exame VARCHAR(150) NOT NULL,
    valor_exame DECIMAL(10,2) NOT NULL
        CHECK (valor_exame >= 0),

    FOREIGN KEY (consulta_id)
        REFERENCES consultas(id)
);

-- DML - CARGA DE DADO


-- 3 ESPECIALIDADES

INSERT INTO especialidades (nome)
VALUES
('Cardiologia'),
('Pediatria'),
('Dermatologia');


-- 3 MÉDICOS

INSERT INTO medicos
(especialidade_id, nome, crm, valor_consulta)
VALUES
(1, 'Dr. Roberto Almeida', 'CRM12345', 350.00),
(2, 'Dra. Mariana Costa', 'CRM23456', 250.00),
(3, 'Dr. Felipe Santos', 'CRM34567', 400.00);


-- 3 PACIENTES

INSERT INTO pacientes
(nome, email, cpf, data_nascimento)
VALUES
('Carlos Silva', 'carlos@email.com', '11111111111', '1990-05-15'),
('Ana Oliveira', 'ana@email.com', '22222222222', '1985-08-20'),
('Pedro Souza', 'pedro@email.com', '33333333333', '2010-03-10');


-- 4 CONSULTAS

INSERT INTO consultas
(medico_id, paciente_id, data_hora, status)
VALUES
(1, 1, '2026-09-20 09:00:00', 'Realizada'),
(2, 2, '2026-09-21 10:30:00', 'Realizada'),
(3, 3, '2026-09-22 14:00:00', 'Agendada'),
(1, 1, '2026-09-23 16:00:00', 'Realizada');


-- 4 EXAMES

INSERT INTO exames_consulta
(consulta_id, nome_exame, valor_exame)
VALUES
(1, 'Eletrocardiograma', 120.00),
(1, 'Hemograma Completo', 80.00),
(2, 'Exame de Sangue', 70.00),
(4, 'Teste Ergométrico', 150.00);

-- Q1
-- MÉDICOS DO MAIS CARO PARA O MAIS BARAT

SELECT
    m.nome AS medico,
    m.crm,
    e.nome AS especialidade,
    m.valor_consulta
FROM medicos m
INNER JOIN especialidades e
    ON m.especialidade_id = e.id
ORDER BY m.valor_consulta DESC;

-- Q2
-- CONSULTAS DO PACIENTE CARLOS SILV

SELECT
    c.id AS id_consulta,
    c.data_hora,
    m.nome AS medico,
    e.nome AS especialidade,
    c.status
FROM consultas c
INNER JOIN pacientes p
    ON c.paciente_id = p.id
INNER JOIN medicos m
    ON c.medico_id = m.id
INNER JOIN especialidades e
    ON m.especialidade_id = e.id
WHERE p.nome = 'Carlos Silva'
ORDER BY c.data_hora;

-- Q3
-- VALOR TOTAL DE CADA CONSULTA
-- VALOR DA CONSULTA + SOMA DOS EXAME

SELECT
    c.id AS id_consulta,
    p.nome AS paciente,
    m.nome AS medico,
    m.valor_consulta +
    COALESCE(SUM(ec.valor_exame), 0) AS valor_total
FROM consultas c
INNER JOIN pacientes p
    ON c.paciente_id = p.id
INNER JOIN medicos m
    ON c.medico_id = m.id
LEFT JOIN exames_consulta ec
    ON c.id = ec.consulta_id
GROUP BY
    c.id,
    p.nome,
    m.nome,
    m.valor_consulta
ORDER BY c.id;

-- Q4
-- MÉDICOS COM VALOR DE CONSULTA SUPERIOR A R$ 300,0

SELECT
    m.id,
    m.nome,
    m.crm,
    m.valor_consulta
FROM medicos m
WHERE m.valor_consulta > 300.00
ORDER BY m.valor_consulta DESC;

-- Q5
-- TOTAL FATURADO POR ESPECIALIDADE
-- SOMENTE CONSULTAS REALIZADA

SELECT
    e.nome AS especialidade,
    SUM(m.valor_consulta) AS total_faturado
FROM consultas c
INNER JOIN medicos m
    ON c.medico_id = m.id
INNER JOIN especialidades e
    ON m.especialidade_id = e.id
WHERE c.status = 'Realizada'
GROUP BY e.nome
ORDER BY total_faturado DESC;
