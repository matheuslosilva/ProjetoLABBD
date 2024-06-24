### Authors
##Beatriz Vieira da Silva Andrade  13692362 
##Matheus Luis Oliveira da Silva   11847429
##Giovanna Pedrino Belasco         12543287


from app import create_app

app = create_app()

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
