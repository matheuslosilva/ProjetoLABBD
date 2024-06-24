-- Definicao do escopo do package sistema
CREATE OR REPLACE PACKAGE sistema_pkg IS
    -- cria user com base no id do lider
    PROCEDURE insert_user(p_password IN VARCHAR2, p_id_lider IN LIDER.CPI%TYPE);

    -- valida user
    FUNCTION check_user(p_userid IN NUMBER, p_password IN VARCHAR2) RETURN NUMBER;

    -- insere log, tanto de acesso quanto de crud
    PROCEDURE insert_log(p_userid IN NUMBER, p_message IN VARCHAR2);

    -- valida o cargo do user
    FUNCTION get_user_cargo(p_userid IN NUMBER) RETURN VARCHAR2;
    
    -- retorna dados do user
    PROCEDURE get_user_details(p_userid IN USERS.USER_ID%TYPE, p_cursor OUT SYS_REFCURSOR);
    
    -- retorna todos os cpis pra usar em list
    PROCEDURE get_all_cpis(p_cursor OUT SYS_REFCURSOR);

    -- verifica se existe lider sem user e cria automaticamente 
    PROCEDURE insert_missing_users();

END sistema_pkg;


CREATE OR REPLACE PACKAGE BODY sistema_pkg IS
    -- Procedure para criar usuarios novos
    PROCEDURE insert_user(
        p_password IN VARCHAR2, -- parametro 1: senha
        p_id_lider IN LIDER.CPI%TYPE -- parametro 2: cpi do lider
    ) IS
        v_hashed_password RAW(32);
    BEGIN
        -- Hash da senha utilizando md5
        v_hashed_password := rawtohex(dbms_obfuscation_toolkit.md5(input => utl_raw.cast_to_raw(p_password)));
        
        -- Insere
        INSERT INTO USERS (PASSWORD, ID_LIDER)
        VALUES (v_hashed_password, p_id_lider);
        
        -- Confirma��o da opera��o
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Usu�rio inserido com sucesso.');
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Desfazer qualquer mudan�a caso ocorra um erro
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Erro ao inserir usu�rio: ' || SQLERRM);
    END insert_user;

    -- Fun��o para login do usu�rio
    FUNCTION check_user (
        p_userid IN NUMBER,
        p_password IN VARCHAR2
    ) RETURN NUMBER AS
        v_password VARCHAR2(32);
        v_hashed_password VARCHAR2(32);
    BEGIN
        SELECT Password INTO v_password FROM USERS WHERE USER_ID = p_userid;
        v_hashed_password := RAWTOHEX(DBMS_OBFUSCATION_TOOLKIT.md5(input => UTL_RAW.CAST_TO_RAW(p_password)));
        IF v_password = v_hashed_password THEN
            RETURN 1; -- Login bem-sucedido
        ELSE
            RETURN 0; -- Falha no login
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0; -- Usu�rio n�o encontrado
    END check_user;

    FUNCTION get_user_cargo(p_userid IN NUMBER) RETURN VARCHAR2 IS
        v_cargo VARCHAR2(10);
    BEGIN
        SELECT CARGO INTO v_cargo 
        FROM LIDER 
        WHERE CPI = (SELECT ID_LIDER FROM USERS WHERE USER_ID = p_userid);
        RETURN v_cargo;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL; -- Usu�rio ou cargo n�o encontrado
    END get_user_cargo;
    
    -- Procedimento para inserir na log
    PROCEDURE insert_log(
        p_userid IN NUMBER,       -- parametro1: ID do usu�rio
        p_message IN VARCHAR2     -- parametro2: Mensagem de log
    ) IS
    BEGIN
        -- Inserir registro de log
        INSERT INTO LOG_TABLE (USER_ID, INCLUDED_AT, MESSAGE)
        VALUES (p_userid, SYSTIMESTAMP, p_message);
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Erro ao inserir log: ' || SQLERRM);
    END insert_log;
    
    
   PROCEDURE get_user_details(
        p_userid IN USERS.USER_ID%TYPE,
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
        SELECT 
            u.USER_ID,
            u.ID_LIDER,
            l.NOME AS LIDER_NOME,
            l.CARGO,
            l.NACAO,
            l.ESPECIE,
            (SELECT LISTAGG(f.NOME, ',') WITHIN GROUP (ORDER BY f.NOME) FROM FACCAO f WHERE f.LIDER = l.CPI) AS FACCOES,
            f.IDEOLOGIA,
            f.QTD_NACOES,
            n.NOME AS NACAO_NOME,
            n.QTD_PLANETAS,
            e.NOME AS ESPECIE_NOME,
            e.PLANETA_OR,
            e.INTELIGENTE
        FROM USERS u
        LEFT JOIN LIDER l ON u.ID_LIDER = l.CPI
        LEFT JOIN FACCAO f ON l.CPI = f.LIDER
        LEFT JOIN NACAO n ON l.NACAO = n.NOME
        LEFT JOIN ESPECIE e ON l.ESPECIE = e.NOME
        WHERE u.USER_ID = p_userid;
    END get_user_details;
    
    
    PROCEDURE get_all_cpis(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
        SELECT CPI, NOME FROM LIDER;
    END get_all_cpis;

    -- Procedimento para encontrar lideres fora da tabela user
    CREATE OR REPLACE PROCEDURE insert_missing_users IS
    v_hashed_password RAW(32);
    -- Usando cursor explicito
    CURSOR missing_users_cursor IS
        SELECT L.CPI
        FROM LIDER L
        LEFT JOIN USERS U ON L.CPI = U.IdLider
        WHERE U.IdLider IS NULL;
    BEGIN
    -- Definir a senha padrão 
    v_hashed_password := rawtohex(dbms_obfuscation_toolkit.md5(input => utl_raw.cast_to_raw('senha_padrao')));

    -- Loop no cursor
    FOR missing_user IN missing_users_cursor LOOP
        BEGIN
            -- Inserir o líder com a senha padrão
            INSERT INTO USERS (PASSWORD, IDLIDER)
            VALUES (v_hashed_password, missing_user.CPI);

            -- Confirmar a operação
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Usuário inserido para líder com CPI: ' || missing_user.CPI);
        EXCEPTION
            WHEN OTHERS THEN
                -- Desfazer qualquer mudança caso ocorra um erro
                ROLLBACK;
                DBMS_OUTPUT.PUT_LINE('Erro ao inserir usuário para líder com CPI: ' || missing_user.CPI || ' - ' || SQLERRM);
        END;
    END LOOP;
    END insert_missing_users;

END sistema_pkg;

