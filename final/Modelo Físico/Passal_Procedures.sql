
-- VISTAS
CREATE VIEW Gorganizadores_eventosorganizadores_eventosasto_total AS
	SELECT SUM(Gasto) FROM Eventos;

CREATE VIEW Ordena_eventos AS
	SELECT e.Idevento AS Evento, e.Gasto AS Despesa, c.Designacao AS Categoria 
    FROM Eventos AS e 
		INNER JOIN Categorias AS c ON e.Categoria=c.Idcategoria 
	ORDER BY e.Gasto DESC;

-- queries

-- mostra todos os eventos para cada organizador que o organizou, ordenados pelo numero do evento
SELECT o.Nome, oe.Evento
FROM Organizadores_eventos AS oe 
	INNER JOIN Organizadores AS o
		ON o.Idorganizador = oe.Organizador 
ORDER BY oe.Evento ASC;
-- τ oe.Evento asc π o.Nome, oe.Evento ( ρ oe Organizadores_eventos ⨝ o.Idorganizador = oe.Organizador ρ o Organizadores )

-- Mostra a categoria de todos os eventos que cada realizador que o organizou
SELECT o.Nome, e.Categoria
FROM Organizadores_eventos AS oe 
	INNER JOIN Eventos AS e 
		ON oe.Evento=e.Idevento
	INNER JOIN Organizadores AS o 
		ON o.Idorganizador=oe.Organizador;
-- π o.Nome, e.Categoria ( ( ρ oe Organizadores_eventos ⨝ oe.Evento = e.Idevento ρ e Eventos ) ⨝ o.Idorganizador = oe.Organizador ρ o Organizadores )

-- Mostra a designação da categoria de todos os eventos que cada realizador que o organizou
SELECT o.Nome, c.Designacao 
FROM Organizadores_eventos AS oe 
	INNER JOIN Eventos AS e 
		ON oe.Evento=e.Idevento 
	INNER JOIN Organizadores AS o
		ON o.Idorganizador=oe.Organizador 
	INNER JOIN Categorias AS c
		ON c.Idcategoria=e.Categoria;
-- π o.Nome, c.Designacao ( ( ( ρ oe Organizadores_eventos ⨝ oe.Evento = e.Idevento ρ e Eventos ) ⨝ o.Idorganizador = oe.Organizador ρ o Organizadores ) ⨝ c.Idcategoria = e.Categoria ρ c Categorias )

-- Listar todos os eventos organizados por um determinado organizador
SELECT e.*
	FROM Eventos AS e
		INNER JOIN Organizadores_eventos AS oe 
			ON e.Idevento = oe.Evento
		INNER JOIN Organizadores AS o 
			ON oe.Organizador=o.Idorganizador 
WHERE o.Nome='Fábio Pereira';
-- π e.Idevento, e.Datainicio, e.DataFim, e.Gasto, e.Localizacao, e.Categoria σ o.Nome = 'Fábio Pereira' ( ( ρ e Eventos ⨝ e.Idevento = oe.Evento ρ oe Organizadores_eventos ) ⨝ oe.Organizador = o.Idorganizador ρ o Organizadores )

-- Calcular a media do custo dos eventos organizados para cada funcionario
SELECT o.Nome AS Organizador, AVG(e.Gasto) AS CustoTotal
FROM Eventos AS e
	INNER JOIN Organizadores_eventos AS oe 
		ON e.Idevento = oe.Evento
	INNER JOIN Organizadores as o 
		ON oe.Organizador = o.Idorganizador
GROUP BY o.Nome;
-- ρ Organizador←o.Nome π o.Nome, CustoTotal γ o.Nome; AVG(e.Gasto)→CustoTotal ( ( ρ e Eventos ⨝ e.Idevento = oe.Evento ρ oe Organizadores_eventos ) ⨝ oe.Organizador = o.Idorganizador ρ o Organizadores )

-- Encontrar eventos em que atuem artistas com preço inferior a um certo valor
SELECT DISTINCT e.*
FROM Eventos AS e
JOIN Eventos_artistas as ea ON e.Idevento = ea.Evento
JOIN Artistas as a ON ea.Artista = a.Idartista
WHERE a.Preco < 1000.00;
--  π e.Idevento, e.Datainicio, e.DataFim, e.Gasto, e.Localizacao, e.Categoria σ a.Preco < 1000 ( ( ρ e Eventos ⨝ e.Idevento = ea.Evento ρ ea Eventos_artistas ) ⨝ ea.Artista = a.Idartista ρ a Artistas )


-- PROCEDIMENTOS 

-- 
-- aquando uma insercao dum artista e dum evento na tabela eventos artistas, atualiza a coluna gasto do evento respetivo, com 
-- o preco artista em questao
DELIMITER //
CREATE TRIGGER Update_evento_cost
AFTER INSERT ON Eventos_artistas
FOR EACH ROW
BEGIN
    DECLARE Artista_preco DECIMAL(8, 2);

    SELECT Preco INTO Artista_preco
    FROM Artistas
    WHERE Idartista = NEW.Artista; 

    UPDATE Eventos
    SET Gasto = Gasto + Artista_preco
    WHERE Idevento = NEW.Evento; 
END //
DELIMITER ;


-- dado um evento mostra 3 tabelas:
-- 1. uma com toda a sua informação bem como a informaçao da localizacao aonde ocorreu
-- 2. uma com toda a informaçcao dos organizadores que participaram neste evento
-- 3. uma com toda a informacao dos artistas que participaram neste evento
DELIMITER &&
CREATE PROCEDURE DetalhaEvento(IN Evento INT)
BEGIN
    SELECT E.IDEvento AS Evento, E.DataInicio AS HorarioInicio, E.DataFim AS HorarioFim, E.Gasto AS CustoEvento, C.Designacao AS Categoria, L.Localidade AS Localizacao, L.Rua AS Rua, L.CodPostal AS CodigoPostal, L.Capacidade AS Capacidade
    FROM Eventos AS E
        INNER JOIN Categorias AS C ON E.Categoria = C.IDCategoria
            INNER JOIN Localizacoes AS L ON E.Localizacao = L.IDLocalizacao
    WHERE E.IDEvento = Evento;

    SELECT O.Nome, O.Tipo, O.Email, O.Telemovel
    FROM Organizadores AS O
        INNER JOIN Organizadores_Eventos AS OE ON O.IDOrganizador = OE.Organizador
    WHERE OE.Evento = Evento;

    SELECT A.Nome, A.Preco, A.Descricao, A.Telemovel
    FROM Artistas AS A
        INNER JOIN Eventos_Artistas AS EA ON A.IDArtista = EA.Artista
    WHERE EA.Evento = Evento;
END &&
DELIMITER ;

-- Dado um organizador, ordena os artistas que participaram em eventos que este organizou, por ordem das apariçoes
DELIMITER &&
CREATE PROCEDURE Ordena_Artistas(IN idOrganizador INT)
BEGIN
    SELECT A.nome as Artista, COUNT(A.nome) AS Aparicoes FROM
    organizadores_eventos AS OE INNER JOIN eventos AS E ON OE.evento=E.idevento 
    INNER JOIN eventos_artistas AS EA ON E.idevento=EA.evento
    INNER JOIN artistas AS A ON A.idartista = EA.artista 
    WHERE OE.organizador=idOrganizador
    GROUP BY A.nome ORDER BY Aparicoes DESC;
END &&
DELIMITER ;

-- INDICES
CREATE INDEX Organizador_Nome on Organizadores(Nome);

CREATE INDEX Artista_Nome on Artistas(Nome);

show indexes from localizacoes;
show indexes from Organizadores;
show indexes from localizacoes;



-- backup
CREATE USER 'gerente'@'localhost';
CREATE USER 'colaboradores'@'localhost';

SET PASSWORD FOR 'gerente'@'localhost' = 'chefe';
SET PASSWORD FOR 'colaboradores'@'localhost' = 'users';

GRANT ALL ON Passal.* TO 'gerente'@'localhost';
GRANT SELECT ON Passal.* TO 'colaboradores'@'localhost';