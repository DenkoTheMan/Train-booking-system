import mysql.connector
import atexit

CNX = mysql.connector.connect(user='', password='',
                              host='127.0.0.1',
                              database='dv1663')
cursor = CNX.cursor()

def get_stations():
    results = []
    cursor.execute('SELECT id, title FROM stations;')
    for result in cursor:
        results.append(result)
    return results

def search_journey(start_station_id, end_station_id, date):
    cursor.execute("SELECT get_route_from_stations(%s, %s)", (start_station_id, end_station_id))
    for route in cursor:
        route_id = route[0]
    if route_id == None:
        return
    cursor.execute("SELECT DISTINCT trains.id, operator, max_passengers, booked_passengers FROM trains JOIN routes ON routes.id = trains.route_id WHERE CAST(get_train_depart_time(trains.id, %s) AS DATE)=%s AND routes.id=%s;", (start_station_id, date, route_id))
    trains = []
    for train in cursor:
        cursor.execute("SELECT get_train_depart_time(%s, %s);", (train[0], start_station_id))
        for result in cursor:
            depart = result[0]
        cursor.execute("SELECT get_train_arrival_time(%s, %s);", (train[0], end_station_id))
        for result in cursor:
            arrival = result[0]
        trains.append([train[0], train[1], depart, arrival, train[2] - train[3]])
    if (trains.count == 0):
        return
    return trains

def search_costumer(email):
    cursor.execute('SELECT id, f_name, l_name, email FROM customers WHERE email=%s;', (email))
    for result in cursor:
        return result

def search_departure(station_id, date):
    cursor.execute("SELECT DISTINCT trains.id, operator, max_passengers, booked_passengers FROM trains JOIN routes ON routes.id = trains.route_id JOIN tracks ON tracks.id = routes.track_id WHERE CAST(get_train_depart_time(trains.id, %s) AS DATE)=%s AND tracks.start_station=%s;", (station_id, date, station_id))
    trains = []
    for train in cursor:
        cursor.execute("SELECT get_train_depart_time(%s, %s);", (train[0], station_id))
        for result in cursor:
            depart = result[0]
        trains.append([train[0], train[1], depart, train[2] - train[3]])
    if (trains.count == 0):
        return 
    return trains

def search_arrivals(station_id, date):
    cursor.execute("SELECT DISTINCT trains.id, operator, max_passengers, booked_passengers FROM trains JOIN routes ON routes.id = trains.route_id JOIN tracks ON tracks.id = routes.track_id WHERE CAST(get_train_depart_time(trains.id, %s) AS DATE)=%s AND tracks.end_station=%s;", (station_id, date, station_id))
    trains = []
    for train in cursor:
        cursor.execute("SELECT get_train_arrival_time(%s, %s);", (train[0], station_id))
        for result in cursor:
            arrival = result[0]
        trains.append([train[0], train[1], arrival, train[2] - train[3]])
    if (trains.count == 0):
        return 
    return trains

def search_booking(email):
    cursor.execute("SELECT bookings.id, bookings.train_id, customers.email FROM bookings JOIN customers ON customers.id = bookings.customer_id WHERE email=%s;", (email))
    bookings = []
    for booking in cursor:
        bookings.append(booking)
    return bookings

def search_train(train_id):
    cursor.execute('SELECT DISTINCT trains.id, operator, max_passengers, booked_passengers, route_id FROM trains WHERE trains.id=%s;', (train_id))
    train_formatted = []
    for train in cursor:
        stations = cursor.callproc('get_stations_from_route', (train[4], 0, 0))
        train_formatted.append([train[0], train[1], stations[1], stations[2], train[2], train[3]])
    return train_formatted[0]
    
def create_booking(train_id, customer_id):
    cursor.execute('INSERT INTO bookings VALUES (NULL, %s, %s);', (train_id, customer_id))
    CNX.commit()

def create_customer(f_name, l_name, email):
    cursor.execute('INSERT INTO customers VALUES (NULL, %s, %s, %s);', (f_name, l_name, email))
    CNX.commit()

def remove_booking(booking_id):
    cursor.execute("DELETE FROM bookings WHERE id=%s", (booking_id))
    CNX.commit()

def close_handler():
    cursor.close()
    CNX.close()

atexit.register(close_handler)