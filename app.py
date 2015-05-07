##Things to know
#The db column for steps, calories, distance and heart rate will be initilized to -1 on creation of the user
#It is important that when summig the data, etc that we do not pass data in right away on user creation for 0s
#We need to wait until we have like an actual day (x unit of times worth of data)
#@update request form #steps=xx&calories==xx

#Notes for research side, make the researchers make a specific request for what data that want and attach that to columbia
#authentication so that they cant run wild and get any data that they want
#IRB approval


# # #HEROKU STUFF
from flask import Flask, render_template, request, send_from_directory
from flask.ext.sqlalchemy import SQLAlchemy
from sqlalchemy.sql import func
from flask import jsonify
from flask import json
from datetime import datetime
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.sql import text
import json as simplejson
from decimal import *
import os.path
import csv
import sys
import logging
from datetime import timedelta


from flask.ext.heroku import Heroku

app = Flask(__name__)
#app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://localhost/pre-registration'
#app.config['UPLOAD_FOLDER'] #you prob need to do something about this in heroku#############################
#app.config.from_object(os.environ['APP_SETTINGS'])
heroku = Heroku(app)
db = SQLAlchemy(app)

#######################################################

# from flask import Flask, render_template, request, send_from_directory
# from flask.ext.sqlalchemy import SQLAlchemy
# from sqlalchemy.sql import func
# from flask import jsonify
# from flask import json
# from datetime import datetime
# from sqlalchemy import create_engine
# from sqlalchemy.orm import sessionmaker
# from sqlalchemy.sql import text
# import json as simplejson
# from decimal import *
# import os.path
# import csv
# from datetime import timedelta


# app = Flask(__name__, static_url_path='')
# app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://localhost/lions_tracks'
# #app.config['UPLOAD_FOLDER'] #you prob need to do something about this in heroku
# db = SQLAlchemy(app)

######LOCALHOST^^^######################################

class DecimalEncoder(json.JSONEncoder):
    def _iterencode(self, o, markers=None):
        if isinstance(o, decimal.Decimal):
            # wanted a simple yield str(o) in the next line,
            # but that would mean a yield on the line with super(...),
            # which wouldn't work (see my comment below), so...
            return (str(o) for o in [o])
        return super(DecimalEncoder, self)._iterencode(o, markers)

# Create our database model
class User(db.Model):
    __tablename__ = "users"
    id = db.Column(db.Integer, primary_key=True)
    sex = db.Column(db.String(1))
    age = db.Column(db.Integer)
    height = db.Column(db.Integer)
    weight = db.Column(db.Integer)
    activity = db.Column(db.Integer)
    sleep = db.Column(db.Integer)
    health = db.Column(db.Integer)
    created_at = db.Column(db.DateTime, default=func.utcnow())


    def __init__(self, sex, age, height, weight, activity, sleep, health, created_at):
        self.sex = sex
        self.age = age
        self.height = height
        self.weight = weight
        self.activity = activity
        self.sleep = sleep
        self.health = health
        self.created_at = created_at

class Record(db.Model):
    __tablename__ = "records"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer)
    unit = db.Column(db.String(10))
    date = db.Column(db.DateTime, default=func.utcnow())
    data_type = db.Column(db.String(10))
    value = db.Column(db.Integer)

    def __init__(self, uid, unit, data_type, value, date):
        self.user_id = uid
        self.unit = unit
        self.data_type = data_type
        self.value = value
        self.date = date

# Set "homepage" to index.html
@app.route('/')
def index():
    return render_template('dashboard.html')

# Save e-mail to database and send to success page
@app.route('/signup', methods=['POST'])
def signup():
    #email = None
    if request.method == 'POST':
        sex = request.form['sex']
        age = request.form['age']
        height = request.form['height']
        weight = request.form['weight']
        activity = request.form['activity']
        sleep = request.form['sleep']
        health = request.form['health']
        reg = User(sex, age, height, weight, activity, sleep, health, func.now())

        db.session.add(reg)
        db.session.flush()
        users = reg.id
        db.session.commit()

        return jsonify(id = users)

@app.route('/update', methods=['POST'])
def update():
    user_id = request.form['user_id']
    unit = request.form['unit']
    data_type = request.form['data_type']
    value = request.form['value']
    if request.method == 'POST':
        reg = Record(user_id, unit, data_type, value, func.now())
        db.session.add(reg)
        db.session.flush()

    db.session.commit()
    return 'success'

@app.route('/community_mean', methods=['POST'])
def community_mean():
    d_type = request.form['data_type']
    result = db.session.query(func.avg(Record.value)).filter(Record.data_type == d_type) #and val isnt 0
    if result[0][0] is not None:
        return json.dumps({'mean': int(result[0][0])}, cls=DecimalEncoder)
    return jsonify(mean = -99)

@app.route('/past', methods=['POST'])
def past():
    d_type = request.form['data_type']
    result = db.session.query(func.avg(Record.value)).filter(Record.data_type == d_type, Record.date >= datetime.utcnow() - timedelta(days=4))
    if result[0][0] is not None:
        return json.dumps({'mean': int(result[0][0])})
        #, '0day': datetime.utcnow(), '1day': datetime.utcnow() - timedelta(days=1), , '2day': datetime.utcnow() - timedelta(days=2), , '3day': datetime.utcnow() - timedelta(days=3) }, cls=DecimalEncoder)
    return jsonify(mean = 0) 

#This will require authentication
@app.route('/get_csv', methods=['POST'])
def get_csv():
    #The authentication might go here, perhaps a reroute
    #engine = create_engine('postgres://oaxyavpinflxhv:qq0LQZW95XE5rPmuyUXQPyoamA@ec2-54-225-154-5.compute-1.amazonaws.com:5432/d6l3r6o07vdg3s')
    #db = create_engine(db_url)
    connection = engine.connect()
    records = connection.execute('SELECT * FROM records')
    with open('data.csv', 'w+') as f:
        writer = csv.writer(f, delimiter=',')
        for row in records:
            writer.writerow(row)
    return app.send_static_file('data.csv')

if __name__ == '__main__':
    app.debug = True
    app.run()