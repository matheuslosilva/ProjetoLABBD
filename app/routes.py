from flask import Blueprint, request, jsonify, render_template, redirect, url_for
from app.config import Config
import oracledb

main = Blueprint('main', __name__)

@main.route('/')
def index():
    return render_template('login.html')

@main.route('/login', methods=['POST'])
def login():
    username = request.form['username']
    password = request.form['password']

    connection = oracledb.connect(
        user=Config.ORACLE_USER,
        password=Config.ORACLE_PASSWORD,
        dsn=f"{Config.ORACLE_HOST}:{Config.ORACLE_PORT}/{Config.ORACLE_SERVICE_NAME}"
    )
    cursor = connection.cursor()
    result = cursor.callfunc('check_user', int, [username, password])
    cursor.close()
    connection.close()
    print(result)
    if result == 1:
        return redirect(url_for('main.overview', username=username))
    else:
        return "Login Failed", 401

@main.route('/overview/<username>')
def overview(username):
    return render_template('overview.html', username=username)

@main.route('/reports')
def reports():
    return render_template('reports.html')
