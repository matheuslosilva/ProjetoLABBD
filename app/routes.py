from flask import Blueprint, request, render_template, redirect, url_for, session, flash
from app.config import Config
import oracledb
import json


## Aqui é definição de rotas e mapeamento pra integrar front e backend


main = Blueprint('main', __name__)


def get_db_connection():
    return oracledb.connect(
        user=Config.ORACLE_USER,
        password=Config.ORACLE_PASSWORD,
        dsn=f"{Config.ORACLE_HOST}:{Config.ORACLE_PORT}/{Config.ORACLE_SERVICE_NAME}"
    )

@main.route('/')
def index():
    return render_template('login.html')

@main.route('/login', methods=['POST'])
def login():
    userid = request.form['userid']
    password = request.form['password']

    connection = oracledb.connect(
        user=Config.ORACLE_USER,
        password=Config.ORACLE_PASSWORD,
        dsn=f"{Config.ORACLE_HOST}:{Config.ORACLE_PORT}/{Config.ORACLE_SERVICE_NAME}"
    )
    cursor = connection.cursor()
    result = cursor.callfunc('sistema_pkg.check_user', int, [userid, password])
    cursor.callproc('sistema_pkg.insert_log', [userid, 'User login attempt'])
    
    if result == 1:
        session['userid'] = userid
        cargo = cursor.callfunc('sistema_pkg.get_user_cargo', str, [userid])
        session['cargo'] = cargo

        cursor.close()
        connection.close()
        return redirect(url_for('main.overview'))
    else:
        cursor.close()
        connection.close()
        flash('Login Failed', 'error')
        return redirect(url_for('main.index'))

@main.route('/overview')
def overview():
    if 'userid' not in session:
        return redirect(url_for('main.index'))

    user_id = session['userid']

    connection = oracledb.connect(
        user=Config.ORACLE_USER,
        password=Config.ORACLE_PASSWORD,
        dsn=f"{Config.ORACLE_HOST}:{Config.ORACLE_PORT}/{Config.ORACLE_SERVICE_NAME}"
    )
    cursor = connection.cursor()
    user_details = {}

    try:
        user_cursor = connection.cursor()
        cursor.callproc('sistema_pkg.get_user_details', [user_id, user_cursor])
        
        user_details_row = user_cursor.fetchone()
        
        if user_details_row:
            user_details = {
                'USER_ID': user_details_row[0],
                'ID_LIDER': user_details_row[1],
                'LIDER_NOME': user_details_row[2],
                'CARGO': user_details_row[3],
                'NACAO': user_details_row[4],
                'ESPECIE': user_details_row[5],
                'FACCOES': user_details_row[6].split(',') if user_details_row[6] else [],
                'IDEOLOGIA': user_details_row[7],
                'QTD_NACOES': user_details_row[8],
                'NACAO_NOME': user_details_row[9],
                'QTD_PLANETAS': user_details_row[10],
                'ESPECIE_NOME': user_details_row[11],
                'PLANETA_OR': user_details_row[12],
                'INTELIGENTE': user_details_row[13]
            }
            session['user_details'] = user_details
    except Exception as e:
        flash(str(e), 'error')
    finally:
        cursor.close()
        connection.close()

    return render_template('overview.html', user_details=user_details)



@main.route('/cientista')
def cientista():
    if 'userid' not in session or session['cargo'] != 'CIENTISTA ':
        return redirect(url_for('main.index'))
    return render_template('cientista.html')

@main.route('/create_estrela', methods=['POST'])
def create_estrela():
    if 'userid' not in session or session['cargo'] != 'CIENTISTA ':
        return redirect(url_for('main.index'))

    id_estrela = request.form['id_estrela']
    nome = request.form['nome']
    classificacao = request.form['classificacao']
    massa = request.form['massa']
    x = request.form['x']
    y = request.form['y']
    z = request.form['z']

    connection = oracledb.connect(
        user=Config.ORACLE_USER,
        password=Config.ORACLE_PASSWORD,
        dsn=f"{Config.ORACLE_HOST}:{Config.ORACLE_PORT}/{Config.ORACLE_SERVICE_NAME}"
    )
    cursor = connection.cursor()
    try:
        cursor.callproc('package_cientista.create_estrela', [id_estrela, nome, classificacao, massa, x, y, z])
        log_message = f'Cientista criou estrela com ID: {id_estrela}'
        cursor.callproc('sistema_pkg.insert_log', [session['userid'], log_message])
        connection.commit()
        flash('Star created successfully!', 'success')
    except Exception as e:
        connection.rollback()
        flash(str(e), 'error')
    finally:
        cursor.close()
        connection.close()

    return redirect(url_for('main.cientista'))

@main.route('/update_estrela', methods=['POST'])
def update_estrela():
    if 'userid' not in session or session['cargo'] != 'CIENTISTA ':
        return redirect(url_for('main.index'))

    id_estrela = request.form['id_estrela']
    nome = request.form['nome']
    classificacao = request.form['classificacao']
    massa = request.form['massa']
    x = request.form['x']
    y = request.form['y']
    z = request.form['z']

    connection = oracledb.connect(
        user=Config.ORACLE_USER,
        password=Config.ORACLE_PASSWORD,
        dsn=f"{Config.ORACLE_HOST}:{Config.ORACLE_PORT}/{Config.ORACLE_SERVICE_NAME}"
    )
    cursor = connection.cursor()
    try:
        cursor.callproc('package_cientista.update_estrela', [id_estrela, nome, classificacao, massa, x, y, z])
        log_message = f'Cientista Atualizou estrela com ID: {id_estrela}'
        cursor.callproc('sistema_pkg.insert_log', [session['userid'], log_message])
        connection.commit()
        flash('Star updated successfully!', 'success')
    except Exception as e:
        connection.rollback()
        flash(str(e), 'error')
    finally:
        cursor.close()
        connection.close()

    return redirect(url_for('main.cientista'))

@main.route('/delete_estrela', methods=['POST'])
def delete_estrela():
    if 'userid' not in session or session['cargo'] != 'CIENTISTA ':
        return redirect(url_for('main.index'))

    id_estrela = request.form['id_estrela']

    connection = oracledb.connect(
        user=Config.ORACLE_USER,
        password=Config.ORACLE_PASSWORD,
        dsn=f"{Config.ORACLE_HOST}:{Config.ORACLE_PORT}/{Config.ORACLE_SERVICE_NAME}"
    )
    cursor = connection.cursor()
    try:
        cursor.callproc('package_cientista.delete_estrela', [id_estrela])
        log_message = f'Cientista Deletou estrela com ID: {id_estrela}'
        cursor.callproc('sistema_pkg.insert_log', [session['userid'], log_message])
        connection.commit()
        flash('Star deleted successfully!', 'success')
    except Exception as e:
        connection.rollback()
        flash(str(e), 'error')
    finally:
        cursor.close()
        connection.close()

    return redirect(url_for('main.cientista'))

@main.route('/read_estrela', methods=['POST'])
def read_estrela():
    if 'userid' not in session or session['cargo'] != 'CIENTISTA ':
        return redirect(url_for('main.index'))

    id_estrela = request.form['id_estrela']

    connection = oracledb.connect(
        user=Config.ORACLE_USER,
        password=Config.ORACLE_PASSWORD,
        dsn=f"{Config.ORACLE_HOST}:{Config.ORACLE_PORT}/{Config.ORACLE_SERVICE_NAME}"
    )
    cursor = connection.cursor()
    try:
        nome = cursor.var(oracledb.STRING)
        classificacao = cursor.var(oracledb.STRING)
        massa = cursor.var(oracledb.NUMBER)
        x = cursor.var(oracledb.NUMBER)
        y = cursor.var(oracledb.NUMBER)
        z = cursor.var(oracledb.NUMBER)

        cursor.callproc('package_cientista.read_estrela', [id_estrela, nome, classificacao, massa, x, y, z])
        estrela = {
            'id_estrela': id_estrela,
            'nome': nome.getvalue(),
            'classificacao': classificacao.getvalue(),
            'massa': massa.getvalue(),
            'x': x.getvalue(),
            'y': y.getvalue(),
            'z': z.getvalue()
        }
        flash('Star details fetched successfully!', 'success')
    except Exception as e:
        flash(str(e), 'error')
        estrela = None
    finally:
        cursor.close()
        connection.close()

    return render_template('cientista.html', estrela=estrela)



@main.route('/lider')
def lider():
    if 'userid' not in session or 'user_details' not in session:
        return redirect(url_for('main.index'))

    user_details = session['user_details']

    connection = oracledb.connect(
        user=Config.ORACLE_USER,
        password=Config.ORACLE_PASSWORD,
        dsn=f"{Config.ORACLE_HOST}:{Config.ORACLE_PORT}/{Config.ORACLE_SERVICE_NAME}"
    )
    cursor = connection.cursor()
    cpis = []
    valid_planets = []
    existing_communities = []
    species = []
    nations = []

    try:
        # Obter CPIs
        cpi_cursor = connection.cursor()
        cursor.callproc('sistema_pkg.get_all_cpis', [cpi_cursor])
        for row in cpi_cursor:
            cpis.append({'cpi': row[0], 'nome': row[1]})

        # Obter planetas válidos
        planet_cursor = connection.cursor()
        cursor.callproc('package_lider.get_valid_planets', [user_details['FACCOES'][0], planet_cursor])
        for row in planet_cursor:
            valid_planets.append(row[0])

        # Obter comunidades existentes
        community_cursor = connection.cursor()
        cursor.callproc('package_lider.get_existing_communities', [session['userid'], community_cursor])
        for row in community_cursor:
            existing_communities.append({'especie': row[0], 'comunidade': row[1]})

        # Obter espécies disponíveis
        species_cursor = connection.cursor()
        cursor.callproc('package_lider.get_species', [species_cursor])
        for row in species_cursor:
            species.append(row[0])

        # Obter nações onde a facção do líder está presente
        nations_cursor = connection.cursor()
        cursor.callproc('package_lider.get_nations_by_faction', [session['userid'], nations_cursor])
        for row in nations_cursor:
            nations.append(row[0])

    except Exception as e:
        flash(str(e), 'error')
    finally:
        cursor.close()
        connection.close()

    no_communities = len(existing_communities) == 0

    return render_template('lider.html', user_details=user_details, cpis=cpis, valid_planets=valid_planets, existing_communities=existing_communities, species=species, nations=nations, no_communities=no_communities)


@main.route('/credenciar_comunidade', methods=['POST'])
def credenciar_comunidade():
    if 'userid' not in session or 'user_details' not in session:
        return redirect(url_for('main.index'))

    user_details = session['user_details']
    action = request.form['action']
    especie = request.form['especie']
    comunidade = request.form['comunidade']
    planeta = request.form['planeta']
    qtd_habitantes = request.form.get('qtd_habitantes')

    connection = oracledb.connect(
        user=Config.ORACLE_USER,
        password=Config.ORACLE_PASSWORD,
        dsn=f"{Config.ORACLE_HOST}:{Config.ORACLE_PORT}/{Config.ORACLE_SERVICE_NAME}"
    )
    cursor = connection.cursor()

    try:
        if action == 'create':
            cursor.callproc('package_lider.credenciar_comunidade', [session['userid'], user_details['FACCOES'][0], especie, comunidade, planeta, qtd_habitantes])
            log_message = f'Lider credenciou comunidade em sua faccao e habitacao de planeta: {comunidade}'
            cursor.callproc('sistema_pkg.insert_log', [session['userid'], log_message])
        else:
            cursor.callproc('package_lider.add_community_to_faction', [session['userid'], especie, comunidade])
            log_message = f'Lider Adicionou comunidade em sua faccao: {comunidade}'
            cursor.callproc('sistema_pkg.insert_log', [session['userid'], log_message])
            
        flash('Comunidade credenciada com sucesso!', 'success')
    except Exception as e:
        flash(str(e), 'error')
    finally:
        cursor.close()
        connection.close()

    return redirect(url_for('main.lider'))


@main.route('/add_comunidades', methods=['POST'])
def add_comunidades():
    if 'userid' not in session or 'user_details' not in session:
        return redirect(url_for('main.index'))

    user_details = session['user_details']
    
    comunidade = request.form['comunidade']
    comunidade, especie = comunidade.split(' - ')

    connection = oracledb.connect(
        user=Config.ORACLE_USER,
        password=Config.ORACLE_PASSWORD,
        dsn=f"{Config.ORACLE_HOST}:{Config.ORACLE_PORT}/{Config.ORACLE_SERVICE_NAME}"
    )
    cursor = connection.cursor()

    try:
        cursor.callproc('package_lider.add_community_to_faction', [session['userid'], especie, comunidade])
        flash('Comunidade adicionada à facção com sucesso!', 'success')
        log_message = f'Lider Adicionou comunidade em sua faccao: {comunidade}'
        cursor.callproc('sistema_pkg.insert_log', [session['userid'], log_message])
    except Exception as e:
        flash(str(e), 'error')
    finally:
        cursor.close()
        connection.close()

    return redirect(url_for('main.lider'))

@main.route('/update_faction_name', methods=['POST'])
def update_faction_name():
    if 'userid' not in session:
        return redirect(url_for('main.index'))

    user_id = session['userid']
    new_name = request.form['new_name']

    connection = oracledb.connect(
        user=Config.ORACLE_USER,
        password=Config.ORACLE_PASSWORD,
        dsn=f"{Config.ORACLE_HOST}:{Config.ORACLE_PORT}/{Config.ORACLE_SERVICE_NAME}"
    )
    cursor = connection.cursor()
    try:
        cursor.callproc('package_lider.update_faction_name', [user_id, new_name])
        connection.commit()
        flash('Nome da facção alterado com sucesso!', 'success')
        log_message = f'Lider mudou nome da sua faccao: {new_name}'
        cursor.callproc('sistema_pkg.insert_log', [session['userid'], log_message])
    except Exception as e:
        connection.rollback()
        flash(str(e), 'error')
        print(e)

    finally:
        cursor.close()
        connection.close()

    return redirect(url_for('main.lider'))

@main.route('/change_faction_leader', methods=['POST'])
def change_faction_leader():
    if 'userid' not in session:
        return redirect(url_for('main.index'))

    user_id = session['userid']
    new_cpi = request.form['new_cpi']

    connection = oracledb.connect(
        user=Config.ORACLE_USER,
        password=Config.ORACLE_PASSWORD,
        dsn=f"{Config.ORACLE_HOST}:{Config.ORACLE_PORT}/{Config.ORACLE_SERVICE_NAME}"
    )
    cursor = connection.cursor()
    try:
        cursor.callproc('package_lider.change_faction_leader', [user_id, new_cpi])
        connection.commit()
        log_message = f'Lider mudou lider da sua faccao: {new_cpi}'
        cursor.callproc('sistema_pkg.insert_log', [session['userid'], log_message])
        flash('Novo líder indicado com sucesso!', 'success')
    except Exception as e:
        connection.rollback()
        flash(str(e), 'error')
    finally:
        cursor.close()
        connection.close()

    return redirect(url_for('main.lider'))

@main.route('/remover_faccao_nacao', methods=['POST'])
def remover_faccao_nacao():
    if 'userid' not in session:
        return redirect(url_for('main.index'))

    user_details = session['user_details']
    user_id = session['userid']
    nacao = request.form['nacao']

    connection = oracledb.connect(
        user=Config.ORACLE_USER,
        password=Config.ORACLE_PASSWORD,
        dsn=f"{Config.ORACLE_HOST}:{Config.ORACLE_PORT}/{Config.ORACLE_SERVICE_NAME}"
    )
    cursor = connection.cursor()
    try:
        cursor.callproc('package_lider.remover_faccao_nacao', [user_id, nacao])
        connection.commit()
        flash('Facção removida da nação com sucesso!', 'success')
        log_message = f'Lider removeu faccao da nacao: {nacao}'
        cursor.callproc('sistema_pkg.insert_log', [session['userid'], log_message])
    except Exception as e:
        connection.rollback()
        flash(str(e), 'error')
    finally:
        cursor.close()
        connection.close()

    return redirect(url_for('main.lider'))

@main.route('/comandante')
def comandante():
    if 'userid' not in session or session['cargo'] != 'COMANDANTE':
        return redirect(url_for('main.index'))

    connection = get_db_connection()
    cursor = connection.cursor()
    federation = None
    available_planets = []
    available_federations = []


    try:
        federation_cursor = connection.cursor()
        cursor.callproc('PACKAGE_COMANDANTE.getFederationByUserId', [session['userid'], federation_cursor])
        federation = federation_cursor.fetchone()[0]

        available_fedarations_cursor = connection.cursor()
        cursor.callproc('PACKAGE_COMANDANTE.getAvailableFederations', [available_fedarations_cursor])
        available_federations = [row[0] for row in available_fedarations_cursor]

        planets_cursor = connection.cursor()
        cursor.callproc('PACKAGE_COMANDANTE.getAvailablePlanets', [planets_cursor])
        available_planets = [row[0] for row in planets_cursor]
    except Exception as e:
        flash(str(e), 'error')
    finally:
        cursor.close()
        connection.close()

    no_planets = len(available_planets) == 0

    return render_template('comandante.html', federation=federation, available_planets=available_planets, available_federations=available_federations, no_planets=no_planets)

@main.route('/manage_federation', methods=['POST'])
def manage_federation():
    if 'userid' not in session or session['cargo'] != 'COMANDANTE':
        return redirect(url_for('main.index'))

    action = request.form['action']
    federation_name = request.form['federation_name'] if action == 'incluir' else None

    connection = get_db_connection()
    cursor = connection.cursor()

    try:

        cursor.callproc('PACKAGE_COMANDANTE.manageFederation', [session['userid'], federation_name, action])
        flash(f'Ação {action} realizada com sucesso!', 'success')
        log_message = f'Comandante fez {action} na federacao: {federation_name}'
        cursor.callproc('sistema_pkg.insert_log', [session['userid'], log_message])

    except Exception as e:
        print(" teste")
        flash(str(e), 'error')
    finally:
        cursor.close()
        connection.close()

    return redirect(url_for('main.comandante'))

@main.route('/create_federation', methods=['POST'])
def create_federation():
    if 'userid' not in session or session['cargo'] != 'COMANDANTE':
        return redirect(url_for('main.index'))

    federation_name = request.form['federation_name']

    connection = get_db_connection()
    cursor = connection.cursor()

    try:
        cursor.callproc('PACKAGE_COMANDANTE.createAndAssignFederation', [session['userid'], federation_name])
        flash('Federação criada e nação associada com sucesso!', 'success')
        log_message = f'Comandante criou federacao: {federation_name}'
        cursor.callproc('sistema_pkg.insert_log', [session['userid'], log_message])
    except Exception as e:
        flash(str(e), 'error')
    finally:
        cursor.close()
        connection.close()

    return redirect(url_for('main.comandante'))

@main.route('/add_dominance', methods=['POST'])
def add_dominance():
    user_id = session['userid']
    print(session['user_details']['NACAO'])

    user_nacao = session['user_details']['NACAO']
    planeta = request.form['planeta']
    connection = get_db_connection()
    cursor = connection.cursor()

    try:
        cursor.callproc('PACKAGE_COMANDANTE.addDominance', [user_id, planeta, user_nacao])
        flash('Dominância adicionada com sucesso!', 'success')
        log_message = f'Comandante dominou planeta: {planeta}'
        cursor.callproc('sistema_pkg.insert_log', [session['userid'], log_message])
    except Exception as e:
        flash(str(e), 'error')
    finally:
        cursor.close()
        connection.close()

    return redirect(url_for('main.comandante'))



@main.route('/official_report')
def official_report():
 
    connection = get_db_connection()
    cursor = connection.cursor()
    inhabitants = []

    try:
        inhabitants_cursor = connection.cursor()
        cursor.callproc('package_relatorios.get_nation_inhabitants', [session['userid'], inhabitants_cursor])
        inhabitants = inhabitants_cursor.fetchall()
    except Exception as e:
        flash(str(e), 'error')
    finally:
        cursor.close()
        connection.close()

    return render_template('relatorioOficial.html', inhabitants=inhabitants)


@main.route('/lider_report')
def lider_report():

    connection = get_db_connection()
    cursor = connection.cursor()
    communities = []

    try:
        communities_cursor = connection.cursor()
        cursor.callproc('package_relatorios.get_faction_communities', [session['userid'], communities_cursor])
        communities = communities_cursor.fetchall()
    except Exception as e:
        flash(str(e), 'error')
    finally:
        cursor.close()
        connection.close()

    return render_template('relatorioLider.html', communities=communities)

@main.route('/comandante_report')
def comandante_report():
    if 'userid' not in session or session['cargo'] != 'COMANDANTE':
        return redirect(url_for('main.index'))

    connection = get_db_connection()
    cursor = connection.cursor()
    dominated_planets = []
    potential_planets = []

    try:
        dominated_cursor = connection.cursor()
        cursor.callproc('package_relatorios.get_dominated_planets', [session['userid'], dominated_cursor])
        dominated_planets = dominated_cursor.fetchall()
        
        potential_cursor = connection.cursor()
        cursor.callproc('package_relatorios.get_expansion_potential_planets', [session['userid'], potential_cursor])
        potential_planets = potential_cursor.fetchall()
    except Exception as e:
        flash(str(e), 'error')
    finally:
        cursor.close()
        connection.close()

    return render_template('relatorioComandante.html', dominated_planets=dominated_planets, potential_planets=potential_planets)


@main.route('/cientista_report')
def cientista_report():
    if 'userid' not in session or session['cargo'] != 'CIENTISTA ':
        return redirect(url_for('main.index'))

    connection = get_db_connection()
    cursor = connection.cursor()
    data = []

    try:
        data_cursor = connection.cursor()
        cursor.callproc('package_relatorios.get_astronomical_data', [data_cursor])
        data = data_cursor.fetchall()
        print(data)
    except Exception as e:
        flash(str(e), 'error')
        print(e)

    finally:
        cursor.close()
        connection.close()

    return render_template('relatorioCientista.html', data=data)

