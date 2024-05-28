import interface
import cmd

class cli(cmd.Cmd):
    intro = 'Welcome to Train Booking System (TBS), use help or ? for a list of commands.\n'
    prompt = '(TBS) '

    def do_list_stations(self, arg):
        'List available stations and their id: list_stations'
        print('\033[1mID - Station\033[0m')
        for station in interface.get_stations():
            print(str(station[0]) + ' - ' + str(station[1]))
    
    def do_search_journey(self, arg):
        'List journeys between two station ids a specified date: search_journey start_station_id end_station_id yyyy-mm-dd'
        trains = interface.search_journey(*parse(arg))
        if (trains == None):
            print('No trains could be found for the specified route and date.')
        print('\033[1mID - Operator - Departure - Arrival - Available seats\033[0m')
        for train in trains:
            print(train[0], train[1], train[2], train[3], train[4], sep=' - ')

    def do_search_departure(self, arg):
        'List departures from a specified station and date: search_departure station_id yyyy-mm-dd'
        trains = interface.search_departure(*parse(arg))
        if (trains == None):
            print('No trains could be found for the specified route and date.')
        print('\033[1mID - Operator - Departure - Available seats\033[0m')
        for train in trains:
            print(train[0], train[1], train[2], train[3], sep=' - ')

    def do_search_arrivals(self, arg):
        'List arrivals to a specified station and date: search_arrival station_id yyyy-mm-dd'
        trains = interface.search_arrivals(*parse(arg))
        if (trains == None):
            print('No trains could be found for the specified route and date.')
        print('\033[1mID - Operator - Arrival - Available seats\033[0m')
        for train in trains:
            print(train[0], train[1], train[2], train[3], sep=' - ')

    def do_search_customer(self, arg):
        'Search for customer in database: search_customer email'
        print('\033[1mID - Name - Email\033[0m')
        result = interface.search_costumer(parse(arg))
        print(result[0], result[1] + ' ' + result[2], result[3], sep=' - ')

    def do_create_customer(self, arg):
        'Create a customer: create_customer f_name l_name email'
        interface.create_customer(*parse(arg))

    def do_create_booking(self, arg):
        'Create booking for a train: create_booking train_id customer_id'
        interface.create_booking(*parse(arg))

    def do_search_booking(self, arg):
        'Search for a booking in database: search_booking email'
        print('\033[1mBooking ID - Train ID - Email\033[0m')
        for booking in interface.search_booking(parse(arg)):
            print(booking[0], booking[1], booking[2], sep=' - ')

    def do_search_train(self, arg):
        'Search for a train in database: search_train train_id'
        print('\033[1mID - Operator - Start station - End station - Available seats\033[0m')
        result = interface.search_train(parse(arg))
        print(result[0], result[1], result[2], result[3], result[4] - result[5], sep=' - ')

    def do_remove_booking(self, arg):
        'Remove specified booking: remove_booking booking_id'
        interface.remove_booking(parse(arg))

def parse(arg):
    return tuple(map(str, arg.split()))

if __name__ == "__main__":
    cli().cmdloop()