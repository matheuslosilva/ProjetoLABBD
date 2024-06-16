EXEC DBMS_STATS.GATHER_SCHEMA_STATS(NULL, NULL);

explain plan set statement_id = 'consulta' for
    SELECT 
        n.nome AS nacao,
        p.id_astro AS planeta,
        c.nome AS comunidade,
        Sc.qtd_habitantes
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
        d.nacao = 'Nacao2'
    GROUP BY
        n.nome, p.id_astro, c.nome
    ORDER BY
        n.nome, p.id_astro, c.nome;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE','consulta','ALL'));

-- Create indexes
CREATE INDEX idx_dominancia_nacao_planeta ON DOMINANCIA(NACAO, PLANETA);
CREATE INDEX idx_habitacao_planeta_especie_comunidade ON HABITACAO(PLANETA, ESPECIE, COMUNIDADE);
CREATE INDEX idx_comunidade_nome_especie ON COMUNIDADE(NOME, ESPECIE);
CREATE INDEX idx_lider_cpi_nacao ON LIDER(CPI, NACAO);

-- Enable DBMS_OUTPUT
SET SERVEROUTPUT ON;