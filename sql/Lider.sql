-- Definicao do escopo do package lider
CREATE OR REPLACE PACKAGE package_lider IS
    -- atualiza nome faccao
    PROCEDURE update_faction_name(p_userid IN USERS.USER_ID%TYPE,p_new_name IN VARCHAR2);

    -- altera lider da faccao
    PROCEDURE change_faction_leader(p_userid IN USERS.USER_ID%TYPE,p_new_cpi IN LIDER.CPI%TYPE);

    -- cria comunidade
    PROCEDURE credenciar_comunidade(p_userid IN USERS.USER_ID%TYPE,p_faccao IN FACCAO.NOME%TYPE,p_especie IN ESPECIE.NOME%TYPE,p_comunidade IN COMUNIDADE.NOME%TYPE,p_planeta IN PLANETA.ID_ASTRO%TYPE,p_qtd_habitantes IN NUMBER);
    
    -- adiciona comunidade a faccao
    PROCEDURE add_community_to_faction(p_userid IN USERS.USER_ID%TYPE,p_especie IN ESPECIE.NOME%TYPE,p_comunidade IN COMUNIDADE.NOME%TYPE);
    
    -- remove faccao de nacao
    PROCEDURE remover_faccao_nacao(p_userid IN USERS.USER_ID%TYPE,p_nacao IN NACAO.NOME%TYPE);

    -- busca planetas disponiveis
    PROCEDURE get_valid_planets(p_faccao IN FACCAO.NOME%TYPE,p_cursor OUT SYS_REFCURSOR);

    -- busca comunidades ja existentes
    PROCEDURE get_existing_communities(p_userid IN USERS.USER_ID%TYPE,p_cursor OUT SYS_REFCURSOR);

    -- busca especies
    PROCEDURE get_species(p_cursor OUT SYS_REFCURSOR);

    -- busca nacoes de uma faccao
    PROCEDURE get_nations_by_faction(p_userid IN USERS.USER_ID%TYPE,p_cursor OUT SYS_REFCURSOR);


    FUNCTION is_lider(p_userid IN USERS.USER_ID%TYPE) RETURN BOOLEAN;
END package_lider;


CREATE OR REPLACE PACKAGE BODY package_lider IS
    PROCEDURE update_faction_name(
        p_userid IN USERS.USER_ID%TYPE,
        p_new_name IN VARCHAR2
    ) IS
        v_cpi LIDER.CPI%TYPE;
    BEGIN
        SELECT ID_LIDER INTO v_cpi
        FROM USERS
        WHERE USER_ID = p_userid;

        UPDATE FACCAO
        SET nome = p_new_name
        WHERE lider = v_cpi;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Usu�rio n�o � l�der de nenhuma fac��o.');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20002, 'Erro ao alterar o nome da fac��o: ' || SQLERRM);
    END update_faction_name;

    PROCEDURE change_faction_leader(
        p_userid IN USERS.USER_ID%TYPE,
        p_new_cpi IN LIDER.CPI%TYPE
    ) IS
        v_cpi LIDER.CPI%TYPE;
    BEGIN
        SELECT ID_LIDER INTO v_cpi
        FROM USERS
        WHERE USER_ID = p_userid;

        UPDATE FACCAO
        SET lider = p_new_cpi
        WHERE lider = v_cpi;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Usu�rio n�o � l�der de nenhuma fac��o.');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20004, 'Erro ao indicar novo l�der: ' || SQLERRM);
    END change_faction_leader;

    PROCEDURE credenciar_comunidade(
        p_userid IN USERS.USER_ID%TYPE,
        p_faccao IN FACCAO.NOME%TYPE,
        p_especie IN ESPECIE.NOME%TYPE,
        p_comunidade IN COMUNIDADE.NOME%TYPE,
        p_planeta IN PLANETA.ID_ASTRO%TYPE,
        p_qtd_habitantes IN NUMBER
    ) IS
        v_cpi LIDER.CPI%TYPE;
        v_count INTEGER;
    BEGIN
        SELECT ID_LIDER INTO v_cpi
        FROM USERS
        WHERE USER_ID = p_userid;

        SELECT COUNT(*)
        INTO v_count
        FROM FACCAO
        WHERE NOME = p_faccao AND LIDER = v_cpi;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20005, 'Usu�rio n�o � l�der da fac��o especificada.');
        END IF;

        -- Verifica se a comunidade j� existe
        SELECT COUNT(*) INTO v_count
        FROM COMUNIDADE
        WHERE ESPECIE = p_especie AND NOME = p_comunidade;

        -- Se a comunidade n�o existir, cria a nova comunidade
        IF v_count = 0 THEN
            INSERT INTO COMUNIDADE (ESPECIE, NOME, QTD_HABITANTES)
            VALUES (p_especie, p_comunidade, p_qtd_habitantes);
        END IF;

        -- Insere em PARTICIPA
        INSERT INTO PARTICIPA (FACCAO, ESPECIE, COMUNIDADE)
        VALUES (p_faccao, p_especie, p_comunidade);

        -- Insere em HABITACAO
        INSERT INTO HABITACAO (PLANETA, ESPECIE, COMUNIDADE, DATA_INI)
        VALUES (p_planeta, p_especie, p_comunidade, SYSDATE);

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20006, 'Erro ao credenciar comunidade: ' || SQLERRM);
    END credenciar_comunidade;
    
    PROCEDURE add_community_to_faction(
        p_userid IN USERS.USER_ID%TYPE,
        p_especie IN ESPECIE.NOME%TYPE,
        p_comunidade IN COMUNIDADE.NOME%TYPE
    ) IS
        v_cpi LIDER.CPI%TYPE;
        v_faccao FACCAO.NOME%TYPE;
    BEGIN
        SELECT ID_LIDER INTO v_cpi
        FROM USERS
        WHERE USER_ID = p_userid;

        SELECT NOME INTO v_faccao
        FROM FACCAO
        WHERE LIDER = v_cpi;

        -- Insere em PARTICIPA
        INSERT INTO PARTICIPA (FACCAO, ESPECIE, COMUNIDADE)
        VALUES (v_faccao, p_especie, p_comunidade);
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20010, 'Erro ao cadastrar comunidade na fac��o: ' || SQLERRM);
    END add_community_to_faction;

    PROCEDURE remover_faccao_nacao(
        p_userid IN USERS.USER_ID%TYPE,
        p_nacao IN NACAO.NOME%TYPE
    ) IS
        v_cpi LIDER.CPI%TYPE;
        v_faccao FACCAO.NOME%TYPE;
    BEGIN
        SELECT ID_LIDER INTO v_cpi
        FROM USERS
        WHERE USER_ID = p_userid;

        SELECT NOME INTO v_faccao
        FROM FACCAO
        WHERE LIDER = v_cpi;

        DELETE FROM NACAO_FACCAO
        WHERE FACCAO = v_faccao AND NACAO = p_nacao;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20008, 'Relacionamento entre a fac��o e a na��o n�o existe.');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20009, 'Erro ao remover fac��o da na��o: ' || SQLERRM);
    END remover_faccao_nacao;

    PROCEDURE get_valid_planets(
        p_faccao IN FACCAO.NOME%TYPE,
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
        SELECT DISTINCT d.PLANETA
        FROM DOMINANCIA d
        JOIN NACAO_FACCAO nf ON d.NACAO = nf.NACAO
        WHERE nf.FACCAO = p_faccao
          AND d.DATA_FIM IS NULL;
    END get_valid_planets;

    PROCEDURE get_existing_communities(
        p_userid IN USERS.USER_ID%TYPE,
        p_cursor OUT SYS_REFCURSOR
    ) IS
        v_cpi LIDER.CPI%TYPE;
        v_faccao FACCAO.NOME%TYPE;
    BEGIN
        -- Obter o CPI do usu�rio logado
        SELECT ID_LIDER INTO v_cpi
        FROM USERS
        WHERE USER_ID = p_userid;
    
        -- Obter a fac��o do l�der
        SELECT NOME INTO v_faccao
        FROM FACCAO
        WHERE LIDER = v_cpi;
    
        -- Abrir o cursor para selecionar as comunidades existentes
        OPEN p_cursor FOR
        SELECT C.ESPECIE, C.NOME
        FROM COMUNIDADE C
        WHERE (C.ESPECIE, C.NOME) NOT IN (
            SELECT P.ESPECIE, P.COMUNIDADE
            FROM PARTICIPA P
        )
        AND EXISTS (
            SELECT 1
            FROM HABITACAO H
            WHERE H.ESPECIE = C.ESPECIE
            AND H.COMUNIDADE = C.NOME
            AND H.PLANETA IN (
                SELECT D.PLANETA
                FROM DOMINANCIA D
                WHERE D.NACAO IN (
                    SELECT NF.NACAO
                    FROM NACAO_FACCAO NF
                    WHERE NF.FACCAO = v_faccao
                )
            )
        );
    END get_existing_communities;

    PROCEDURE get_species(
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR
        SELECT NOME FROM ESPECIE;
    END get_species;

    PROCEDURE get_nations_by_faction(
        p_userid IN USERS.USER_ID%TYPE,
        p_cursor OUT SYS_REFCURSOR
    ) IS
        v_cpi LIDER.CPI%TYPE;
        v_faccao FACCAO.NOME%TYPE;
    BEGIN
        SELECT ID_LIDER INTO v_cpi
        FROM USERS
        WHERE USER_ID = p_userid;

        SELECT NOME INTO v_faccao
        FROM FACCAO
        WHERE LIDER = v_cpi;

        OPEN p_cursor FOR
        SELECT NACAO
        FROM NACAO_FACCAO
        WHERE FACCAO = v_faccao;
        
    END get_nations_by_faction;


    FUNCTION is_lider(
        p_userid IN USERS.USER_ID%TYPE
    ) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM FACCAO f
        JOIN USERS u ON f.LIDER = u.ID_LIDER
        WHERE u.USER_ID = p_userid;

        RETURN v_count > 0;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20011, 'Erro ao verificar lideran�a: ' || SQLERRM);
            RETURN FALSE;
    END is_lider;
END package_lider;

