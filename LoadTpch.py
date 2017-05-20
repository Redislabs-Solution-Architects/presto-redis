import sys, csv, redis, json

def main(argv):
	host = argv[0]
    port = int(argv[1])
    table = argv[2]

    r = redis.StrictRedis(host, port)
    
    with open('/var/presto/data/etc/redis/' + table + '.json') as json_file: 
        data = json.load(json_file)
        with open(table + '.tbl', 'rb') as csvfile:
            reader = csv.reader(csvfile, delimiter='|')
            i = 1
            d = dict()
            for row in reader:
                fields = data['value']['fields']
                for f in range(len(fields)):
                    d[fields[f]['name']] = row[f]
		r.hmset('tpch:' + table + ':' + str(i), d)
                i += 1
            
    

if __name__ == '__main__':
    main(sys.argv[1:])
