-- DDL - CRIAÇÃO DAS TABELAS


CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    telefone VARCHAR(20) NOT NULL,
    cpf CHAR(11) UNIQUE NOT NULL,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE mecanicos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    especialidade VARCHAR(100) NOT NULL,
    valor_hora DECIMAL(10,2) NOT NULL CHECK (valor_hora > 0)
);


CREATE TABLE veiculos (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER NOT NULL,
    placa CHAR(7) UNIQUE NOT NULL,
    modelo VARCHAR(100) NOT NULL,
    marca VARCHAR(100) NOT NULL,
    ano INTEGER NOT NULL,

    CONSTRAINT fk_veiculo_cliente
        FOREIGN KEY (cliente_id)
        REFERENCES clientes(id)
);


CREATE TABLE ordens_servico (
    id SERIAL PRIMARY KEY,
    veiculo_id INTEGER NOT NULL,
    mecanico_id INTEGER NOT NULL,
    data_abertura TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    valor_mao_obra DECIMAL(10,2) NOT NULL CHECK (valor_mao_obra >= 0),
    status VARCHAR(20) DEFAULT 'Em Aberto' NOT NULL,

    CONSTRAINT fk_os_veiculo
        FOREIGN KEY (veiculo_id)
        REFERENCES veiculos(id),

    CONSTRAINT fk_os_mecanico
        FOREIGN KEY (mecanico_id)
        REFERENCES mecanicos(id),

    CONSTRAINT check_status
        CHECK (status IN (
            'Em Aberto',
            'Em Andamento',
            'Concluida',
            'Cancelada'
        ))
);


CREATE TABLE pecas_os (
    id SERIAL PRIMARY KEY,
    os_id INTEGER NOT NULL,
    nome_peca VARCHAR(100) NOT NULL,
    quantidade INTEGER NOT NULL CHECK (quantidade > 0),
    valor_unitario DECIMAL(10,2) NOT NULL CHECK (valor_unitario > 0),

    CONSTRAINT fk_peca_os
        FOREIGN KEY (os_id)
        REFERENCES ordens_servico(id)
);


-- DML - CARGA DE DADOS


-- 3 CLIENTES
INSERT INTO clientes (nome, email, telefone, cpf)
VALUES
('Fernanda Lima', 'fernanda.lima@email.com', '(48) 99911-2233', '11111111111'),
('Carlos Mendes', 'carlos.mendes@email.com', '(48) 99822-3344', '22222222222'),
('Juliana Souza', 'juliana.souza@email.com', '(48) 99733-4455', '33333333333');


-- 3 MECÂNICOS
INSERT INTO mecanicos (nome, especialidade, valor_hora)
VALUES
('Roberto Silva', 'Motor', 120.00),
('Marcos Oliveira', 'Suspensão', 85.00),
('André Costa', 'Elétrica', 100.00);


-- 3 VEÍCULOS
INSERT INTO veiculos (cliente_id, placa, modelo, marca, ano)
VALUES
(1, 'ABC1D23', 'Civic', 'Honda', 2020),
(2, 'DEF4E56', 'Corolla', 'Toyota', 2021),
(3, 'GHI7F89', 'Onix', 'Chevrolet', 2022);


-- 4 ORDENS DE SERVIÇO
INSERT INTO ordens_servico
    (veiculo_id, mecanico_id, valor_mao_obra, status)
VALUES
(1, 1, 500.00, 'Concluida'),
(2, 2, 350.00, 'Em Andamento'),
(3, 3, 400.00, 'Concluida'),
(1, 1, 250.00, 'Em Aberto');


-- 4 PEÇAS/INSUMOS
INSERT INTO pecas_os
    (os_id, nome_peca, quantidade, valor_unitario)
VALUES
(1, 'Filtro de Óleo', 1, 50.00),
(1, 'Pastilha de Freio', 2, 150.00),
(2, 'Amortecedor', 2, 300.00),
(3, 'Vela de Ignição', 4, 40.00);



-- Q1
-- Veículos ordenados por marca e modelo


SELECT
    v.modelo,
    v.marca,
    v.placa,
    c.nome AS proprietario,
    c.telefone
FROM veiculos v
JOIN clientes c
    ON v.cliente_id = c.id
ORDER BY
    v.marca,
    v.modelo;


-- Q2
-- Ordens de Serviço da cliente Fernanda Lima


SELECT
    os.id AS id_os,
    v.placa,
    v.modelo,
    os.data_abertura,
    m.nome AS mecanico,
    os.status
FROM ordens_servico os
JOIN veiculos v
    ON os.veiculo_id = v.id
JOIN clientes c
    ON v.cliente_id = c.id
JOIN mecanicos m
    ON os.mecanico_id = m.id
WHERE c.nome = 'Fernanda Lima';


-- Valor total de cada Ordem de Serviço
-- Mão de obra + peças


SELECT
    os.id AS id_os,
    v.placa,
    m.nome AS mecanico,
    os.valor_mao_obra,
    COALESCE(SUM(p.quantidade * p.valor_unitario), 0) AS valor_pecas,
    os.valor_mao_obra +
        COALESCE(SUM(p.quantidade * p.valor_unitario), 0) AS valor_total
FROM ordens_servico os
JOIN veiculos v
    ON os.veiculo_id = v.id
JOIN mecanicos m
    ON os.mecanico_id = m.id
LEFT JOIN pecas_os p
    ON os.id = p.os_id
GROUP BY
    os.id,
    v.placa,
    m.nome,
    os.valor_mao_obra
ORDER BY os.id;




-- Mecânicos com valor por hora superior a R$ 90


SELECT
    id,
    nome,
    especialidade,
    valor_hora
FROM mecanicos
WHERE valor_hora > 90.00
ORDER BY valor_hora DESC;


-- Total faturado com mão de obra
-- por especialidade
-- Apenas OS concluídas


SELECT
    m.especialidade,
    SUM(os.valor_mao_obra) AS total_faturado
FROM ordens_servico os
JOIN mecanicos m
    ON os.mecanico_id = m.id
WHERE os.status = 'Concluida'
GROUP BY m.especialidade
ORDER BY total_faturado DESC;