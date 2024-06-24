-- Definicao do escopo do package cientista (CRUD DE ESTRELAS)
CREATE OR REPLACE PACKAGE package_cientista IS
    PROCEDURE create_estrela(p_id_estrela IN VARCHAR2,p_nome IN VARCHAR2,p_classificacao IN VARCHAR2,p_massa IN NUMBER,p_x IN NUMBER,p_y IN NUMBER,p_z IN NUMBER);

    PROCEDURE read_estrela(p_id_estrela IN VARCHAR2,p_nome OUT VARCHAR2,p_classificacao OUT VARCHAR2,p_massa OUT NUMBER,p_x OUT NUMBER,p_y OUT NUMBER,p_z OUT NUMBER);

    PROCEDURE update_estrela(p_id_estrela IN VARCHAR2,p_nome IN VARCHAR2,p_classificacao IN VARCHAR2,p_massa IN NUMBER,p_x IN NUMBER,p_y IN NUMBER,p_z IN NUMBER);

    PROCEDURE delete_estrela(p_id_estrela IN VARCHAR2);

END package_cientista;


CREATE OR REPLACE PACKAGE BODY package_cientista IS
    PROCEDURE create_estrela(
        p_id_estrela IN VARCHAR2,
        p_nome IN VARCHAR2,
        p_classificacao IN VARCHAR2,
        p_massa IN NUMBER,
        p_x IN NUMBER,
        p_y IN NUMBER,
        p_z IN NUMBER
    ) IS
    BEGIN
        INSERT INTO ESTRELA (ID_ESTRELA, NOME, CLASSIFICACAO, MASSA, X, Y, Z)
        VALUES (p_id_estrela, p_nome, p_classificacao, p_massa, p_x, p_y, p_z);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20001, 'Erro ao criar estrela: ' || SQLERRM);
    END create_estrela;

    PROCEDURE read_estrela(
        p_id_estrela IN VARCHAR2,
        p_nome OUT VARCHAR2,
        p_classificacao OUT VARCHAR2,
        p_massa OUT NUMBER,
        p_x OUT NUMBER,
        p_y OUT NUMBER,
        p_z OUT NUMBER
    ) IS
    BEGIN
        SELECT NOME, CLASSIFICACAO, MASSA, X, Y, Z
        INTO p_nome, p_classificacao, p_massa, p_x, p_y, p_z
        FROM ESTRELA
        WHERE ID_ESTRELA = p_id_estrela;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Estrela n�o encontrada.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20003, 'Erro ao ler estrela: ' || SQLERRM);
    END read_estrela;

    PROCEDURE update_estrela(
        p_id_estrela IN VARCHAR2,
        p_nome IN VARCHAR2,
        p_classificacao IN VARCHAR2,
        p_massa IN NUMBER,
        p_x IN NUMBER,
        p_y IN NUMBER,
        p_z IN NUMBER
    ) IS
    BEGIN
        UPDATE ESTRELA
        SET NOME = p_nome, CLASSIFICACAO = p_classificacao, MASSA = p_massa, X = p_x, Y = p_y, Z = p_z
        WHERE ID_ESTRELA = p_id_estrela;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20006, 'Estrela n�o encontrada para atualiza��o.');
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20004, 'Erro ao atualizar estrela: ' || SQLERRM);
    END update_estrela;

    PROCEDURE delete_estrela(
        p_id_estrela IN VARCHAR2
    ) IS
    BEGIN
        DELETE FROM ESTRELA WHERE ID_ESTRELA = p_id_estrela;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20007, 'Estrela n�o encontrada para exclus�o.');
        END IF;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20005, 'Erro ao deletar estrela: ' || SQLERRM);
    END delete_estrela;
END package_cientista;

