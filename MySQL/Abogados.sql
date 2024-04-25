CREATE DATABASE Abogados;

USE Abogados;

CREATE TABLE Procurador (
	IdProcurador INT NOT NULL AUTO_INCREMENT,
    Nombre VARCHAR(45) NOT NULL,
    DPI VARCHAR(45) NOT NULL,
    Direccion VARCHAR(45) NOT NULL,
    CONSTRAINT PK_Procurador PRIMARY KEY (IdProcurador),
    CONSTRAINT UQ_Procurador_1 UNIQUE (DPI)
) ENGINE = InnoDB DEFAULT CHARSET = UTF8MB4 AUTO_INCREMENT = 1000;

CREATE TABLE Cliente (
	IdCliente INT NOT NULL AUTO_INCREMENT,
    Nombre VARCHAR(45) NOT NULL,
    DPI VARCHAR(45) NOT NULL,
    CONSTRAINT PK_Cliente PRIMARY KEY (IdCliente),
    CONSTRAINT UQ_Cliente_1 UNIQUE (DPI)
) ENGINE = InnoDB DEFAULT CHARSET = UTF8MB4 AUTO_INCREMENT = 1000;

CREATE TABLE Asunto (
	IdAsunto INT NOT NULL AUTO_INCREMENT,
    IdProcurador INT NOT NULL,
    IdCliente INT NOT NULL,
    Caso VARCHAR(45) NOT NULL,
    Fecha_Inicio DATE NOT NULL,
    Fecha_Fin DATE NOT NULL,
    CONSTRAINT PK_ASUNTO PRIMARY KEY (IdAsunto),
    CONSTRAINT FK_ASUNTO_1 FOREIGN KEY (IdProcurador) REFERENCES Procurador(IdProcurador)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
    CONSTRAINT FK_ASUNTO_2 FOREIGN KEY (IdCliente) REFERENCES Cliente(IdCliente)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = UTF8MB4 AUTO_INCREMENT = 1000;

CREATE TABLE Expediente (
	IdExpediente INT NOT NULL AUTO_INCREMENT,
    IdAsunto INT NOT NULL,
    Fecha_Registro DATE NOT NULL,
    CONSTRAINT PK_Expediente PRIMARY KEY (IdExpediente),
    CONSTRAINT FK_Expediente_1 FOREIGN KEY (IdAsunto) REFERENCES Asunto(IdAsunto)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = UTF8 AUTO_INCREMENT = 1000;

INSERT INTO Cliente (Nombre, DPI) VALUES
					('Paulo', '301513015');
INSERT INTO Cliente (Nombre, DPI) VALUES
					('Oscar', '432342552');
INSERT INTO Cliente (Nombre, DPI) VALUES
					('Josue', '345534535');
INSERT INTO Cliente (Nombre, DPI) VALUES
					('Marcos', '435345345');

INSERT INTO Procurador (Nombre, DPI, Direccion) VALUES
					    ('Juan', '3423424', '4ta calle');
INSERT INTO Procurador (Nombre, DPI, Direccion) VALUES
					    ('Maria', '2342424', '5ta calle');
INSERT INTO Procurador (Nombre, DPI, Direccion) VALUES
					    ('Pedro', '34534455', '6ta calle');
                        
CREATE TRIGGER Insertar_Expediente
	AFTER INSERT ON Asunto
    FOR EACH ROW
		INSERT INTO Expediente (IdAsunto, Fecha_Registro) VALUES (NEW.IdAsunto, NEW.Fecha_Inicio);
        
INSERT INTO Asunto (IdProcurador, IdCliente, Caso, Fecha_Inicio, Fecha_Fin) VALUES
					(1000, 1000, 'Demanda 1', DATE("2021-03-10"), DATE("2022-02-22"));
INSERT INTO Asunto (IdProcurador, IdCliente, Caso, Fecha_Inicio, Fecha_Fin) VALUES
					(1001, 1002, 'Denuncia 1', DATE("2022-04-11"), DATE("2022-05-29"));
INSERT INTO Asunto (IdProcurador, IdCliente, Caso, Fecha_Inicio, Fecha_Fin) VALUES
					(1001, 1002, 'Denuncia 2', DATE("2023-04-11"), DATE("2024-04-26"));
INSERT INTO Asunto (IdProcurador, IdCliente, Caso, Fecha_Inicio, Fecha_Fin) VALUES
					(1001, 1002, 'Denuncia 3', NOW(), DATE("2024-04-28"));
INSERT INTO Asunto (IdProcurador, IdCliente, Caso, Fecha_Inicio, Fecha_Fin) VALUES
					(1000, 1000, 'Demanda 2', DATE("2022-05-11"), DATE("2023-07-08"));

-- Query general de todos los datos

SELECT
	e.IdExpediente As "Numero de expediente", 
    e.IdAsunto AS "Numero de asunto",
    a.Caso AS "Caso",
    a.Fecha_Inicio AS "Fecha de registro",
    a.Fecha_Fin AS "Fecha de finalizacion",
    
    CASE
		WHEN ABS(EXTRACT(YEAR FROM a.Fecha_Inicio) - EXTRACT(YEAR FROM a.Fecha_Fin)) <= 0 THEN
			CONCAT(ABS(DATEDIFF(a.Fecha_Inicio, a.Fecha_Fin)), " dias")
		WHEN ABS(EXTRACT(YEAR FROM a.Fecha_Inicio) - EXTRACT(YEAR FROM a.Fecha_Fin)) = 1 THEN
			CONCAT(ABS(DATEDIFF(a.Fecha_Inicio, a.Fecha_Fin)), " dias, ",
				ABS(EXTRACT(YEAR FROM a.Fecha_Inicio) - EXTRACT(YEAR FROM a.Fecha_Fin)), " año")
		WHEN ABS(EXTRACT(YEAR FROM a.Fecha_Inicio) - EXTRACT(YEAR FROM a.Fecha_Fin)) > 1 THEN
			CONCAT(ABS(DATEDIFF(a.Fecha_Inicio, a.Fecha_Fin)), " dias, ",
				ABS(EXTRACT(YEAR FROM a.Fecha_Inicio) - EXTRACT(YEAR FROM a.Fecha_Fin)), " años")
		END AS "Tiempo estimado de duracion del caso",
            
    a.IdCliente AS "Numero de cliente",
    c.Nombre AS "Nombre del cliente",
    p.IdProcurador AS "Numero de procurador",
    p.Nombre AS "Nombre del procurador"
FROM Expediente e
	LEFT JOIN Asunto a ON e.IdAsunto = a.IdAsunto
    LEFT JOIN Cliente c ON a.IdCliente = c.IdCliente
    LEFT JOIN Procurador p ON a.IdProcurador = p.IdProcurador;
    
-- Query de datos de la tabla clientes

SELECT
	c.IdCliente AS "Numero de cliente",
    c.Nombre AS "Nombre del cliente",
    c.DPI AS "Documento de identificacion",
    
    IF (COUNT(a.IdCliente) > 0, 
		COUNT(a.IdCliente), 
        'No tiene registros') AS "Cantidad de expedientes registrados",
	
    IF (COUNT(a.IdCliente) > 0,
		(SELECT COUNT(DATEDIFF(NOW(), a.Fecha_Fin)) 
        FROM Asunto a WHERE c.IdCliente = a.IdCliente AND DATEDIFF(NOW(), a.Fecha_Fin) > 0),
        'No tiene registros') AS "Canditad de expedientes finalizados",
        
	IF (COUNT(a.IdCliente) > 0,
		(SELECT IFNULL(GROUP_CONCAT(a.IdAsunto order by a.IdAsunto separator ', '), 'No hay expedientes finalizados') 
        FROM Asunto a WHERE c.IdCliente = a.IdCliente AND DATEDIFF(NOW(), a.Fecha_Fin) > 0),
        'No tiene registros') AS "Identificador de los Expedientes finalizados",
        
	IF (COUNT(a.IdCliente) > 0,
		(SELECT COUNT(DATEDIFF(NOW(), a.Fecha_Fin)) 
        FROM Asunto a WHERE c.IdCliente = a.IdCliente AND DATEDIFF(NOW(), a.Fecha_Fin) < 0),
        'No tiene registros') AS "Canditad de expedientes en curso",
	
    IF (COUNT(a.IdCliente) > 0,
		(SELECT IFNULL(GROUP_CONCAT(a.IdAsunto order by a.IdAsunto separator ', '), 'No hay expedientes en curso') 
        FROM Asunto a WHERE c.IdCliente = a.IdCliente AND DATEDIFF(NOW(), a.Fecha_Fin) < 0),
        'No tiene registros') AS "Identificador de los Expedientes en curso"
FROM Cliente c
	LEFT JOIN Asunto a ON c.IdCliente = a.IdCliente
    GROUP BY c.IdCliente
ORDER BY COUNT(a.IdCliente) DESC;



