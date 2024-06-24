-- Definicao do escopo do package comandante
CREATE OR REPLACE PACKAGE PACKAGE_COMANDANTE AS
    -- Busca federacao por Userid
    PROCEDURE getFederationByUserId(user_id IN USERS.USER_ID%TYPE, p_cursor OUT SYS_REFCURSOR);
    -- Busca planetas sem dominancia
    PROCEDURE getAvailablePlanets(p_cursor OUT SYS_REFCURSOR);
    -- Crud de federacao
    PROCEDURE manageFederation(user_id IN USERS.USER_ID%TYPE, nome_federacao IN FEDERACAO.NOME%TYPE, acao IN VARCHAR2);
    -- Busca federacoes disponiveis
    PROCEDURE getAvailableFederations(p_cursor OUT SYS_REFCURSOR);
    -- Cria e relaciona federacao
    PROCEDURE createAndAssignFederation(user_id IN USERS.USER_ID%TYPE, nome_federacao IN FEDERACAO.NOME%TYPE);
    -- Cria dominancia
    PROCEDURE addDominance(user_id IN USERS.USER_ID%TYPE,p_planeta IN PLANETA.ID_ASTRO%TYPE,p_nacao IN NACAO.NOME%TYPE);

END PACKAGE_COMANDANTE;


CREATE OR REPLACE PACKAGE BODY PACKAGE_COMANDANTE AS
    PROCEDURE getFederationByUserId(user_id IN USERS.USER_ID%TYPE, p_cursor OUT SYS_REFCURSOR) IS
        nacao_aux NACAO.NOME%TYPE;
        cpi_aux LIDER.CPI%TYPE;
    BEGIN
        OPEN p_cursor FOR
            SELECT NACAO.FEDERACAO
            FROM USERS
            JOIN LIDER ON USERS.ID_LIDER = LIDER.CPI
            JOIN NACAO ON LIDER.NACAO = NACAO.NOME
            WHERE USERS.USER_ID = user_id
            AND ROWNUM = 1;  -- Limitar a um resultado
    END getFederationByUserId;
    
    PROCEDURE getAvailablePlanets(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT P.ID_ASTRO
            FROM PLANETA P
            LEFT JOIN DOMINANCIA D ON P.ID_ASTRO = D.PLANETA AND D.DATA_FIM IS NULL
            WHERE D.PLANETA IS NULL;
    END getAvailablePlanets;

    PROCEDURE manageFederation(user_id IN USERS.USER_ID%TYPE, nome_federacao IN FEDERACAO.NOME%TYPE, acao IN VARCHAR2) IS
        nacao_aux NACAO.NOME%TYPE;
        cpi_aux LIDER.CPI%TYPE;
        fed_aux NACAO.FEDERACAO%TYPE;
    BEGIN
        -- Obter a na��o do l�der
        SELECT LIDER.NACAO INTO nacao_aux
        FROM USERS
        JOIN LIDER ON USERS.ID_LIDER = LIDER.CPI
        WHERE USERS.USER_ID = user_id
        AND ROWNUM = 1;

        IF acao = 'incluir' THEN
            -- Verificar se a na��o j� possui uma federa��o
            BEGIN
                SELECT federacao INTO fed_aux FROM NACAO WHERE nome = nacao_aux;
                IF fed_aux IS NOT NULL THEN
                    RAISE_APPLICATION_ERROR(-20001, 'Na��o j� est� em uma federa��o.');
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    -- Se n�o encontrou, pode incluir
                    NULL;
            END;

            -- Incluir a na��o na federa��o
            UPDATE NACAO SET federacao = nome_federacao WHERE nome = nacao_aux;
            DBMS_OUTPUT.PUT_LINE('Na��o inclu�da na federa��o.');
            commit;

        ELSIF acao = 'excluir' THEN
            -- Verificar se a na��o est� em uma federa��o
            BEGIN
                SELECT federacao INTO fed_aux FROM NACAO WHERE nome = nacao_aux;
                IF fed_aux IS NULL THEN
                    RAISE_APPLICATION_ERROR(-20002, 'Na��o n�o pertence a nenhuma federa��o.');
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(-20003, 'Nenhuma federa��o encontrada para a na��o especificada.');
            END;

            -- Excluir a na��o da federa��o
            UPDATE NACAO SET federacao = NULL WHERE nome = nacao_aux;
            DBMS_OUTPUT.PUT_LINE('Na��o exclu�da da federa��o.');
            commit;
        ELSE
            RAISE_APPLICATION_ERROR(-20004, 'A��o inv�lida. Utilize "incluir" ou "excluir".');
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20005, 'Nenhuma na��o encontrada para o l�der especificado.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Ocorreu um erro inesperado: ' || SQLERRM);
    END manageFederation;

    PROCEDURE getAvailableFederations(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT NOME
            FROM FEDERACAO
            WHERE NOME NOT IN (SELECT FEDERACAO FROM NACAO WHERE FEDERACAO IS NOT NULL);
    END getAvailableFederations;

   PROCEDURE createAndAssignFederation(user_id IN USERS.USER_ID%TYPE, nome_federacao IN FEDERACAO.NOME%TYPE) IS
        nacao_aux NACAO.NOME%TYPE;
    BEGIN
        -- Obter a na��o do l�der
        SELECT LIDER.NACAO INTO nacao_aux
        FROM USERS
        JOIN LIDER ON USERS.ID_LIDER = LIDER.CPI
        WHERE USERS.USER_ID = user_id
        AND ROWNUM = 1;
    
        -- Associar a na��o � nova federa��o (inser��o na tabela FEDERACAO ser� tratada pelo trigger)
        UPDATE NACAO SET federacao = nome_federacao WHERE nome = nacao_aux;
    
        DBMS_OUTPUT.PUT_LINE('Federa��o criada e na��o associada.');
        
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20005, 'Nenhuma na��o encontrada para o l�der especificado.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20006, 'Ocorreu um erro inesperado: ' || SQLERRM);
    END createAndAssignFederation;

    
    PROCEDURE addDominance(
        user_id IN USERS.USER_ID%TYPE,
        p_planeta IN PLANETA.ID_ASTRO%TYPE,
        p_nacao IN NACAO.NOME%TYPE
    ) IS
        v_count INTEGER;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('User ID: ' || user_id);
        DBMS_OUTPUT.PUT_LINE('Na��o: ' || p_nacao);
    
        -- Verificar se o planeta est� atualmente sendo dominado
        SELECT COUNT(*)
        INTO v_count
        FROM DOMINANCIA
        WHERE PLANETA = p_planeta
        AND DATA_FIM IS NULL;
    
        IF v_count = 0 THEN
            -- Inserir nova domin�ncia
            INSERT INTO DOMINANCIA (PLANETA, NACAO, DATA_INI, DATA_FIM)
            VALUES (p_planeta, p_nacao, SYSDATE, NULL);
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Nova domin�ncia inserida com sucesso.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Este planeta j� est� sendo dominado.');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20010, 'Erro ao inserir domin�ncia: ' || SQLERRM);
    END addDominance;

END PACKAGE_COMANDANTE;

BEGIN
    PACKAGE_COMANDANTE.addDominance(3, 'Planeta7', 'Nacao2');
END;
