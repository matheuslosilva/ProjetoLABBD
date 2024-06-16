CREATE OR REPLACE PACKAGE PACKAGE_COMANDANTE AS
    PROCEDURE getFederationByUserId(user_id IN USERS.USER_ID%TYPE, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE getAvailablePlanets(p_cursor OUT SYS_REFCURSOR);
    PROCEDURE manageFederation(user_id IN USERS.USER_ID%TYPE, nome_federacao IN FEDERACAO.NOME%TYPE, acao IN VARCHAR2);
    PROCEDURE getAvailableFederations(p_cursor OUT SYS_REFCURSOR);
    PROCEDURE createAndAssignFederation(user_id IN USERS.USER_ID%TYPE, nome_federacao IN FEDERACAO.NOME%TYPE);
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
        -- Obter a nação do líder
        SELECT LIDER.NACAO INTO nacao_aux
        FROM USERS
        JOIN LIDER ON USERS.ID_LIDER = LIDER.CPI
        WHERE USERS.USER_ID = user_id
        AND ROWNUM = 1;

        IF acao = 'incluir' THEN
            -- Verificar se a nação já possui uma federação
            BEGIN
                SELECT federacao INTO fed_aux FROM NACAO WHERE nome = nacao_aux;
                IF fed_aux IS NOT NULL THEN
                    RAISE_APPLICATION_ERROR(-20001, 'Nação já está em uma federação.');
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    -- Se não encontrou, pode incluir
                    NULL;
            END;

            -- Incluir a nação na federação
            UPDATE NACAO SET federacao = nome_federacao WHERE nome = nacao_aux;
            DBMS_OUTPUT.PUT_LINE('Nação incluída na federação.');
            commit;

        ELSIF acao = 'excluir' THEN
            -- Verificar se a nação está em uma federação
            BEGIN
                SELECT federacao INTO fed_aux FROM NACAO WHERE nome = nacao_aux;
                IF fed_aux IS NULL THEN
                    RAISE_APPLICATION_ERROR(-20002, 'Nação não pertence a nenhuma federação.');
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(-20003, 'Nenhuma federação encontrada para a nação especificada.');
            END;

            -- Excluir a nação da federação
            UPDATE NACAO SET federacao = NULL WHERE nome = nacao_aux;
            DBMS_OUTPUT.PUT_LINE('Nação excluída da federação.');
            commit;
        ELSE
            RAISE_APPLICATION_ERROR(-20004, 'Ação inválida. Utilize "incluir" ou "excluir".');
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20005, 'Nenhuma nação encontrada para o líder especificado.');
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
        cpi_aux LIDER.CPI%TYPE;
    BEGIN
        -- Obter a nação do líder
        SELECT LIDER.NACAO INTO nacao_aux
        FROM USERS
        JOIN LIDER ON USERS.ID_LIDER = LIDER.CPI
        WHERE USERS.USER_ID = user_id
        AND ROWNUM = 1;

        -- Criar nova federação
        INSERT INTO FEDERACAO (NOME, DATA_FUND) VALUES (nome_federacao, SYSDATE);

        -- Associar a nação à nova federação
        UPDATE NACAO SET federacao = nome_federacao WHERE nome = nacao_aux;

        DBMS_OUTPUT.PUT_LINE('Federação criada e nação associada.');
        
        commit;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20005, 'Nenhuma nação encontrada para o líder especificado.');
        WHEN OTHERS THEN
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
        DBMS_OUTPUT.PUT_LINE('Nação: ' || p_nacao);
    
        -- Verificar se o planeta está atualmente sendo dominado
        SELECT COUNT(*)
        INTO v_count
        FROM DOMINANCIA
        WHERE PLANETA = p_planeta
        AND DATA_FIM IS NULL;
    
        IF v_count = 0 THEN
            -- Inserir nova dominância
            INSERT INTO DOMINANCIA (PLANETA, NACAO, DATA_INI, DATA_FIM)
            VALUES (p_planeta, p_nacao, SYSDATE, NULL);
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Nova dominância inserida com sucesso.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Este planeta já está sendo dominado.');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20010, 'Erro ao inserir dominância: ' || SQLERRM);
    END addDominance;

END PACKAGE_COMANDANTE;

BEGIN
    PACKAGE_COMANDANTE.addDominance('Nacao2', 'Planeta7');
END;
