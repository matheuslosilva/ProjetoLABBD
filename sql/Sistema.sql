CREATE OR REPLACE PACKAGE sistema_pkg IS
    PROCEDURE insert_user(p_password IN VARCHAR2, p_id_lider IN LIDER.CPI%TYPE);

    FUNCTION check_user(p_userid IN NUMBER, p_password IN VARCHAR2) RETURN NUMBER;

    PROCEDURE insert_log(p_userid IN NUMBER, p_message IN VARCHAR2);

    FUNCTION get_user_cargo(p_userid IN NUMBER) RETURN VARCHAR2;
    
    PROCEDURE get_user_details(p_userid IN USERS.USER_ID%TYPE, p_cursor OUT SYS_REFCURSOR);
    
    PROCEDURE get_all_cpis(p_cursor OUT SYS_REFCURSOR);

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
        
        -- Confirmação da operação
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Usuário inserido com sucesso.');
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Desfazer qualquer mudança caso ocorra um erro
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Erro ao inserir usuário: ' || SQLERRM);
    END insert_user;

    -- Função para login do usuário
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
            RETURN 0; -- Usuário não encontrado
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
            RETURN NULL; -- Usuário ou cargo não encontrado
    END get_user_cargo;
    
    -- Procedimento para inserir na log
    PROCEDURE insert_log(
        p_userid IN NUMBER,       -- parametro1: ID do usuário
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
END sistema_pkg;

