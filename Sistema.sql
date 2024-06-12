-- Procedure para criar usuarios novos
CREATE OR REPLACE PROCEDURE insert_user(
    p_password IN VARCHAR2, -- parametro 1: senha
    p_id_lider IN LIDER.CPI%TYPE -- parametro 2: cpi do lider
) IS
    v_hashed_password RAW(32);
BEGIN

    -- Hash da senha utilizando md5
    v_hashed_password := rawtohex(dbms_obfuscation_toolkit.md5(input => utl_raw.cast_to_raw(p_password)));

   -- Insere
    INSERT INTO USERS (PASSWORD, IDLIDER)
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


-- Login usuario
CREATE OR REPLACE FUNCTION check_user (
    p_userid IN NUMBER,
    p_password IN VARCHAR2
) RETURN NUMBER AS
    v_password VARCHAR2(32);
    v_hashed_password VARCHAR2(32);
BEGIN
    SELECT Password INTO v_password FROM USERS WHERE IdLider = p_userid;
    v_hashed_password := RAWTOHEX(DBMS_OBFUSCATION_TOOLKIT.md5(input => UTL_RAW.CAST_TO_RAW(p_password)));
    IF v_password = v_hashed_password THEN
        RETURN 1; -- Login bem-sucedido
    ELSE
        RETURN 0; -- Falha no login
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0; -- Usuário não encontrado
END;



-- Procedimento para inserir na log
CREATE OR REPLACE PROCEDURE insert_log(
    p_userid IN NUMBER,       -- parametro1: ID do usuário
    p_message IN VARCHAR2     -- parametro2: Mensagem de log
) IS
BEGIN
    -- Inserir registro de log
    INSERT INTO LOG_TABLE (USER_ID, INCLUDED_AT, MESSAGE)
    VALUES (p_userid, SYSTIMESTAMP, p_message);

    -- Confirmar a operação
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Desfazer qualquer mudança caso ocorra um erro
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Erro ao inserir log: ' || SQLERRM);
END insert_log;