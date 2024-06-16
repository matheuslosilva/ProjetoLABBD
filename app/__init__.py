from flask import Flask
from flask_bcrypt import Bcrypt
from app.routes import main

bcrypt = Bcrypt()

def create_app():
    app = Flask(__name__)
    app.config.from_object('app.config.Config')
    app.secret_key = 'secretKey'  # Add this line with a unique and secret key


    bcrypt.init_app(app)
    app.register_blueprint(main)

    return app
