-- Definicao do escopo do package relatorios
CREATE OR REPLACE PACKAGE package_relatorios AS
    -- busca comunidades por faccao
    PROCEDURE get_faction_communities(p_userid IN USERS.USER_ID%TYPE, p_cursor OUT SYS_REFCURSOR);
    
    -- busca habitantes de uma nacao
    PROCEDURE get_nation_inhabitants(p_userid IN USERS.USER_ID%TYPE, p_cursor OUT SYS_REFCURSOR);

    -- busca dados de estrelas e ou sistemas
    PROCEDURE get_astronomical_data(p_cursor OUT SYS_REFCURSOR);
    
    -- busca planetas ja dominados
    PROCEDURE get_dominated_planets(p_userid IN USERS.USER_ID%TYPE, p_cursor OUT SYS_REFCURSOR);

    -- busca planetas ainda nao dominados
    PROCEDURE get_expansion_potential_planets(p_userid IN USERS.USER_ID%TYPE, p_cursor OUT SYS_REFCURSOR);
END package_relatorios;


CREATE OR REPLACE PACKAGE BODY package_relatorios AS
    PROCEDURE get_faction_communities(
        p_userid IN USERS.USER_ID%TYPE,
        p_cursor OUT SYS_REFCURSOR
    ) IS
        v_cpi LIDER.CPI%TYPE;
    BEGIN
        -- Obter o CPI do l�der
        SELECT ID_LIDER INTO v_cpi FROM USERS WHERE USER_ID = p_userid;
        
        -- Obter as comunidades da fac��o do l�der agrupadas por planeta
        OPEN p_cursor FOR
        SELECT
            vc.PLANETA,
            vc.NACAO,
            LISTAGG(vc.COMUNIDADE, ', ') WITHIN GROUP (ORDER BY vc.COMUNIDADE) AS COMUNIDADES,
            COUNT(vc.COMUNIDADE) AS QTD_COMUNIDADES,
            vc.SISTEMA,
            LISTAGG(DISTINCT vc.ESPECIE, ', ') WITHIN GROUP (ORDER BY vc.ESPECIE) AS ESPECIES
        FROM
            vw_faction_communities vc
        JOIN
            FACCAO f ON vc.FACCAO = f.NOME
        WHERE
            f.LIDER = v_cpi
        GROUP BY
            vc.PLANETA, vc.NACAO, vc.SISTEMA
        ORDER BY
            vc.NACAO, vc.PLANETA, vc.SISTEMA;
    END get_faction_communities;


    PROCEDURE get_nation_inhabitants(p_userid IN USERS.USER_ID%TYPE, p_cursor OUT SYS_REFCURSOR) IS
    v_nacao NACAO.NOME%TYPE;
BEGIN
    -- Obter a na��o do usu�rio
    SELECT l.NACAO INTO v_nacao 
    FROM LIDER l
    JOIN USERS u ON u.ID_LIDER = l.CPI
    WHERE u.USER_ID = p_userid;

    -- Obter as comunidades, planetas e a quantidade de habitantes na na��o
    OPEN p_cursor FOR
    SELECT 
        n.nome AS nacao,
        p.id_astro AS planeta,
        c.nome AS comunidade,
        c.qtd_habitantes AS qtd_habitantes
    FROM
        DOMINANCIA d
    JOIN
        PLANETA p ON p.id_astro = d.planeta
    JOIN
        HABITACAO h ON h.planeta = p.id_astro
    JOIN
        COMUNIDADE c ON c.nome = h.comunidade AND c.especie = h.especie
    JOIN
        ESPECIE e ON e.nome = c.especie
    JOIN
        FACCAO f ON f.nome = (SELECT faccao FROM PARTICIPA WHERE especie = c.especie AND comunidade = c.nome)
    JOIN
        NACAO_FACCAO nf ON nf.faccao = f.nome
    JOIN
        NACAO n ON nf.nacao = n.nome
    WHERE
        d.nacao = v_nacao
    ORDER BY
        n.nome, p.id_astro, c.nome;
END get_nation_inhabitants;

    PROCEDURE get_dominated_planets(p_userid IN USERS.USER_ID%TYPE, p_cursor OUT SYS_REFCURSOR) IS
        v_nacao NACAO.NOME%TYPE;
    BEGIN
        -- Obter a na��o do usu�rio
        SELECT l.NACAO INTO v_nacao 
        FROM LIDER l
        JOIN USERS u ON u.ID_LIDER = l.CPI
        WHERE u.USER_ID = p_userid;
        
        -- Obter informa��es sobre os planetas dominados
        OPEN p_cursor FOR
        SELECT 
            pd.PLANETA,
            pd.NACAO,
            pd.DATA_INI,
            pd.DATA_FIM,
            pd.QTD_COMUNIDADES,
            pd.QTD_ESPECIES,
            pd.QTD_HABITANTES,
            pd.FACCAO_MAJORITARIA
        FROM 
            vw_planetas_dominados pd
        WHERE
            pd.NACAO = v_nacao;
    END get_dominated_planets;

    PROCEDURE get_expansion_potential_planets(p_userid IN USERS.USER_ID%TYPE, p_cursor OUT SYS_REFCURSOR) IS
        v_nacao NACAO.NOME%TYPE;
    BEGIN
        -- Obter a na��o do usu�rio
        SELECT l.NACAO INTO v_nacao 
        FROM LIDER l
        JOIN USERS u ON u.ID_LIDER = l.CPI
        WHERE u.USER_ID = p_userid;
        
        -- Obter planetas com potencial de expans�o
        OPEN p_cursor FOR
        SELECT 
            p.ID_ASTRO,
            p.CLASSIFICACAO,
            p.MASSA,
            p.RAIO,
            s.NOME AS SISTEMA
        FROM 
            PLANETA p
        LEFT JOIN
            ORBITA_PLANETA op ON p.ID_ASTRO = op.PLANETA
        LEFT JOIN
            SISTEMA s ON op.ESTRELA = s.ESTRELA
        WHERE 
            p.ID_ASTRO NOT IN (SELECT PLANETA FROM DOMINANCIA WHERE DATA_FIM IS NULL);
    END get_expansion_potential_planets;

    PROCEDURE get_astronomical_data(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
        SELECT 
            e.ID_ESTRELA,
            e.NOME AS nome_estrela,
            e.CLASSIFICACAO,
            e.MASSA,
            e.X,
            e.Y,
            e.Z,
            s.NOME AS nome_sistema,
            p.ID_ASTRO AS planeta_orbitado,
            o.DIST_MIN,
            o.DIST_MAX,
            o.PERIODO,
            NVL2(p.ID_ASTRO, 'N�o', 'Sim') AS estrela_sem_planeta,
            (SELECT COUNT(*) FROM ORBITA_PLANETA op WHERE op.ESTRELA = e.ID_ESTRELA) AS qtd_planetas_orbitando,
            CASE 
                WHEN e.CLASSIFICACAO IS NULL THEN 'Classifica��o faltante'
                WHEN e.MASSA IS NULL THEN 'Massa faltante'
                ELSE NULL
            END AS dados_faltantes
        FROM
            ESTRELA e
        LEFT JOIN
            SISTEMA s ON s.ESTRELA = e.ID_ESTRELA
        LEFT JOIN
            ORBITA_PLANETA o ON o.ESTRELA = e.ID_ESTRELA
        LEFT JOIN
            PLANETA p ON p.ID_ASTRO = o.PLANETA;
    END get_astronomical_data;

END package_relatorios;
    