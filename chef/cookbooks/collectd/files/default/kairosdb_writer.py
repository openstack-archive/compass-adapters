#  Copyright 2013 Gregory Durham
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
import collectd
import socket
import re
from string import maketrans
from time import time
from traceback import format_exc

host = None
port = None
prefix = None
types = {}
postfix = None
tags = ""
host_separator = "_"
metric_separator = "."
protocol = "tcp"

def kairosdb_parse_types_file(path):
    global types

    f = open(path, 'r')

    for line in f:
        fields = line.split()
        if len(fields) < 2:
            continue

        type_name = fields[0]

        if type_name[0] == '#':
            continue

        v = []
        for ds in fields[1:]:
            ds = ds.rstrip(',')
            ds_fields = ds.split(':')

            if len(ds_fields) != 4:
                collectd.warning('kairosdb_writer: cannot parse data source %s on type %s' % ( ds, type_name ))
                continue

            v.append(ds_fields)

        types[type_name] = v

    f.close()

def str_to_num(s):
    """
    Convert type limits from strings to floats for arithmetic.
    Will force U[nlimited] values to be 0.
    """

    try:
        n = float(s)
    except ValueError:
        n = 0

    return n

def sanitize_field(field):
    """
    Santize Metric Fields: replace dot and space with metric_separator. Delete
    parentheses. Convert to lower case if configured to do so.
    """
    field = field.strip()
    trans = maketrans(' .', metric_separator * 2)
    field = field.translate(trans, '()')
    if lowercase_metric_names:
        field = field.lower()
    return field

def kairosdb_config(c):
    global host, port, prefix, postfix, host_separator, \
            metric_separator, lowercase_metric_names, protocol, \
            tags

    for child in c.children:
        if child.key == 'KairosDBHost':
            host = child.values[0]
        elif child.key == 'KairosDBPort':
            port = int(child.values[0])
        elif child.key == 'TypesDB':
            for v in child.values:
                kairosdb_parse_types_file(v)
        elif child.key == 'LowercaseMetricNames':
            lowercase_metric_names = True
        elif child.key == 'MetricPrefix':
            prefix = child.values[0]
        elif child.key == 'HostPostfix':
            postfix = child.values[0]
        elif child.key == 'HostSeparator':
            host_separator = child.values[0]
        elif child.key == 'MetricSeparator':
            metric_separator = child.values[0]
        elif child.key == 'KairosDBProtocol':
            protocol = str(child.values[0])
        elif child.key == 'Tags':
            for v in child.values:
                tags += "%s " % (v)

    tags = tags.replace('.', host_separator)

    if not host:
        raise Exception('KairosDBHost not defined')

    if not port:
        raise Exception('KairosDBPort not defined')

    collectd.info('Initializing kairosdb_writer client in %s socket mode.'
                         % protocol.upper() )

def kairosdb_init():
    import threading

    d = {
        'host': host,
        'port': port,
        'lowercase_metric_names': lowercase_metric_names,
        'sock': None,
        'lock': threading.Lock(),
        'values': { },
        'last_connect_time': 0
    }

    kairosdb_connect(d)

    collectd.register_write(kairosdb_write, data=d)

def kairosdb_connect(data):
    result = False

    if not data['sock'] and protocol.lower() == 'tcp':
        # only attempt reconnect every 10 seconds if protocol of type TCP
        now = time()
        if now - data['last_connect_time'] < 10:
            return False

        data['last_connect_time'] = now
        collectd.info('connecting to %s:%s' % ( data['host'], data['port'] ) )
        try:
            data['sock'] = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            data['sock'].connect((host, port))
            result = True
        except:
            result = False
            collectd.warning('error connecting socket: %s' % format_exc())
    else:
        # we're either connected, or protocol does not == tcp. we will send 
        # data via udp/SOCK_DGRAM call.
        result = True

    return result

def kairosdb_write_data(data, s):
    result = False
    data['lock'].acquire()

    try:
        if protocol.lower() == 'tcp':
            data['sock'].sendall(s)
        else:
            # send message to via UDP to the line receiver .
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            sock.sendto(s, (host, port))
        result = True
    except socket.error, e:
        data['sock'] = None
        if isinstance(e.args, tuple):
            collectd.warning('kairosdb_writer: socket error %d' % e[0])
        else:
            collectd.warning('kairosdb_writer: socket error')
    except:
        collectd.warning('kairosdb_writer: error sending data: %s' % format_exc())

    data['lock'].release()
    return result

def kairosdb_write(v, data=None):
    data['lock'].acquire()
    if not kairosdb_connect(data) and protocol.lower() == 'tcp':
        data['lock'].release()
        collectd.warning('kairosdb_writer: no connection to kairosdb server')
        return

    data['lock'].release()

    if v.type not in types:
        collectd.warning('kairosdb_writer: do not know how to handle type %s. do you have all your types.db files configured?' % v.type)
        return

    v_type = types[v.type]

    if len(v_type) != len(v.values):
        collectd.warning('kairosdb_writer: differing number of values for type %s' % v.type)
        return

    metric_fields = []
    if prefix:
        metric_fields.append(prefix)

    if postfix:
        metric_fields.append(postfix)

    metric_fields.append(v.plugin)
    if v.plugin_instance:
        metric_fields.append(sanitize_field(v.plugin_instance))

    metric_fields.append(v.type)
    if v.type_instance:
        metric_fields.append(sanitize_field(v.type_instance))

    time = v.time

    # we update shared recorded values, so lock to prevent race conditions
    data['lock'].acquire()

    lines = []
    i = 0
    for value in v.values:
        ds_name = v_type[i][0]
        ds_type = v_type[i][1]

        path_fields = metric_fields[:]
        path_fields.append(ds_name)

        metric = '.'.join(path_fields)

        new_value = value

        if new_value is not None:
            line = 'put %s %d %f %s' % ( metric, time, new_value, tags)
            collectd.debug(line)
            lines.append(line)

        i += 1

    data['lock'].release()

    lines.append('')
    kairosdb_write_data(data, '\n'.join(lines))

collectd.register_config(kairosdb_config)
collectd.register_init(kairosdb_init)
