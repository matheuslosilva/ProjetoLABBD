-- Trigger para alteracao da faccao em nacao faccao
CREATE OR REPLACE TRIGGER trg_update_faccao_name
AFTER UPDATE OF NOME ON FACCAO
FOR EACH ROW
BEGIN
    UPDATE NACAO_FACCAO
    SET FACCAO = :NEW.NOME
    WHERE FACCAO = :OLD.NOME;
END;

-- Trigger para alteracao do nome da faccao na tabela participa
CREATE OR REPLACE TRIGGER trg_update_faccao_name_participa
AFTER UPDATE OF NOME ON FACCAO
FOR EACH ROW
BEGIN
    UPDATE PARTICIPA
    SET FACCAO = :NEW.NOME
    WHERE FACCAO = :OLD.NOME;
END;

-- Trigger para alteracao de federacao na nacao
CREATE OR REPLACE TRIGGER trg_before_nacao_update
BEFORE UPDATE OF federacao ON NACAO
FOR EACH ROW
DECLARE
    v_count INTEGER;
BEGIN
    -- Verificar se a nova federação não é nula
    IF :NEW.federacao IS NOT NULL THEN
        -- Verificar se a federação já existe
        SELECT COUNT(*) INTO v_count
        FROM FEDERACAO
        WHERE NOME = :NEW.federacao;

        -- Inserir nova federação se não existir
        IF v_count = 0 THEN
            INSERT INTO FEDERACAO (NOME, DATA_FUND) VALUES (:NEW.federacao, SYSDATE);
        END IF;
    END IF;
END;


-- Essa view mostra planetas dominado com qtd_comunidades, especies e habitantes
CREATE OR REPLACE VIEW vw_planetas_dominados AS
SELECT 
    d.PLANETA,
    d.NACAO,
    d.DATA_INI,
    d.DATA_FIM,
    (SELECT COUNT(*) FROM HABITACAO h WHERE h.PLANETA = d.PLANETA) AS QTD_COMUNIDADES,
    (SELECT COUNT(DISTINCT e.NOME) 
     FROM HABITACAO h 
     JOIN ESPECIE e ON e.NOME = h.ESPECIE 
     WHERE h.PLANETA = d.PLANETA) AS QTD_ESPECIES,
    (SELECT SUM(c.QTD_HABITANTES) 
     FROM HABITACAO h 
     JOIN COMUNIDADE c ON c.NOME = h.COMUNIDADE 
     WHERE h.PLANETA = d.PLANETA) AS QTD_HABITANTES,
    (SELECT f.NOME 
     FROM FACCAO f 
     JOIN PARTICIPA p ON p.FACCAO = f.NOME 
     WHERE p.COMUNIDADE IN (SELECT h.COMUNIDADE 
                            FROM HABITACAO h 
                            WHERE h.PLANETA = d.PLANETA)
     GROUP BY f.NOME 
     ORDER BY COUNT(p.COMUNIDADE) DESC
     FETCH FIRST 1 ROWS ONLY) AS FACCAO_MAJORITARIA
FROM 
    DOMINANCIA d
WHERE 
    d.DATA_FIM IS NULL;

-- Essa view mostra dados sobre comunidades relacionadas as suas faccoes   
CREATE OR REPLACE VIEW vw_faction_communities AS
SELECT
    F.NOME AS FACCAO,
    N.NOME AS NACAO,
    C.ESPECIE,
    C.NOME AS COMUNIDADE,
    P.ID_ASTRO AS PLANETA,
    S.NOME AS SISTEMA
FROM
    PARTICIPA PA
JOIN
    COMUNIDADE C ON PA.ESPECIE = C.ESPECIE AND PA.COMUNIDADE = C.NOME
JOIN
    FACCAO F ON PA.FACCAO = F.NOME
JOIN
    NACAO_FACCAO NF ON NF.FACCAO = F.NOME
JOIN
    NACAO N ON NF.NACAO = N.NOME
JOIN
    ESPECIE E ON C.ESPECIE = E.NOME
JOIN
    PLANETA P ON P.ID_ASTRO = E.PLANETA_OR
JOIN
    ORBITA_PLANETA OP ON OP.PLANETA = P.ID_ASTRO
JOIN
    ESTRELA E ON E.ID_ESTRELA = OP.ESTRELA
JOIN
    SISTEMA S ON S.ESTRELA = E.ID_ESTRELA;