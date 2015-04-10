from multiprocessing import Pool
import argparse
import logging
import multiprocessing
import os
import simplejson as json
import site
import subprocess
import sys
import re


logging.basicConfig(filename='/var/log/check_health.log',
                    level=logging.INFO,
                    format='%(asctime)s;%(levelname)s;%(lineno)s;%(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S')

# Activate virtual environment for Rally
logging.info("Start to activate Rally virtual environment......")
virtual_env = '/opt/rally'
activate_this = '/opt/rally/bin/activate_this.py'
execfile(activate_this, dict(__file__=activate_this))
site.addsitedir(virtual_env)
if virtual_env not in sys.path:
    sys.path.append(virtual_env)
logging.info("Activated virtual environment.")


from oslo_config import cfg
from rally import db
from rally.common import version
import requests


CONF = cfg.CONF
PIDFILE = '/tmp/compass_health_check.pid'
REQUEST_HEADER = {'content-type': 'application/json'}


def round_float(number, d=2):
    return ("%." + str(d) + "f") % number


def get_task_name(task_json_path):
    return os.path.basename(task_json_path).split('.')[0]


def get_report_name(task_name):
    return task_name.replace('_', '-')


def is_process_running():
    if not os.path.isfile(PIDFILE):
        return False

    file = open(PIDFILE, 'r')
    pid = file.readline()
    file.close()

    if os.path.exists('/proc/%s/cmd' % pid):
        return True
    else:
        os.unlink(PIDFILE)

    return False


def clean_pidfile():
    if not is_process_running():
        return
    os.unlink(PIDFILE)


class HealthException(Exception):
    def __init__(self, err_msg, url=None):
        super(HealthException, self).__init__(err_msg)
        self.url = url


def error_handler(func_name, err_msg, url):
    logging.error("%s raise excption: %s" % (func_name, err_msg))
    # Clean pidfile
    clean_pidfile()

    # Send error back to Compass
    payload = {
        "report": {},
        "state": "error",
        "error_message": err_msg
    }
    resp = requests.put(
        url, data=json.dumps(payload), headers=REQUEST_HEADER
    )
    logging.info("[error_handler] status_code: %s" % resp.status_code)


def error_handler_decorator(func):
    def func_wrapper(self, *args, **kwargs):
        try:
            return func(self, *args, **kwargs)

        except HealthException as exc:
            func_name = func.__name__
            err_msg = str(exc)
            error_handler(func_name, err_msg, exc.url)
            logging.error(exc)

    return func_wrapper


def run_task(args, **kwargs):
    return HealthCheck.start_task(*args, **kwargs)


class HealthCheck(object):

    def __init__(self, compass_url, clustername):
        self.url = compass_url
        self.deployment_name = clustername
        self.rally_secnarios_dir = '/opt/compass/rally/scenarios'
        self.rally_deployment_dir = '/opt/compass/rally/deployment'

    def print_dict(self, input_dict):
        print json.dumps(input_dict, indent=4)

    def init_rally_config(self):
        CONF([], project='rally', version=version.version_string())

    @error_handler_decorator
    def exec_cli(self, command, max_reties=1):
        max_reties = max_reties
        output = None
        err_msg = None

        while(max_reties > 0):
            proc = subprocess.Popen(
                command, shell=True,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE
            )
            output, err_msg = proc.communicate()
            if proc.returncode == 0:
                break
            else:
                logging.error('[exec_cli]: %s' % err_msg)
                proc.terminate()
                max_reties -= 1

        return proc.returncode, output, err_msg

    @error_handler_decorator
    def create_deployment(self):
        dpl_file_name = '.'.join((self.deployment_name, 'json'))
        dpl_path = os.path.join(self.rally_deployment_dir, dpl_file_name)
        logging.info('deployment config file path is %s' % dpl_path)

        if not os.path.isfile(dpl_path):
            err_msg = 'Cannot find deployment config file for rally.'
            raise HealthException(err_msg, self.url)

        deployments = db.deployment_list(name=self.deployment_name)
        if deployments:
            # Destroy the previous deployment
            uuid = deployments[0].uuid
            self.delete_deployment_and_tasks(uuid)
            logging.info("Destroy previous deployment!")

        # Create deployment
        command = 'rally deployment create --filename=%s --name=%s' \
                  % (dpl_path, self.deployment_name)

        logging.info(command)
        returncode, output, err_msg = self.exec_cli(command)
        if returncode > 0:
            # Send error message to Compass. Rally failed.
            raise HealthException(err_msg, self.url)

        deployment = db.deployment_list(name=self.deployment_name)[0]

        return deployment.uuid

    @error_handler_decorator
    def delete_deployment_and_tasks(self, deployment_uuid=None):
        if not deployment_uuid:
            deployments = db.deployment_list(name=self.deployment_name)
            if not deployments:
                return

            deployment_uuid = deployments[0].uuid

        self.cleanup_previous_tasks(deployment_uuid)
        command = 'rally deployment destroy --deployment %s'\
                  % self.deployment_name

        returncode, output, err_msg = self.exec_cli(command)
        if returncode > 0:
            raise HealthException(err_msg, self.url)

        logging.info("Destroyed the deployment '%s'" % self.deployment_name)

    def get_all_tasks_config(self):
        tasks = []
        for dirpath, dirs, files in os.walk(self.rally_secnarios_dir):
            for file in files:
                if file.endswith('.json'):
                    tasks.append(os.path.join(dirpath, file))

        logging.info("Get all tasks config are %s" % tasks)
        return tasks

    def get_tasks_uuid_from_db(self, deployment_id):
        tasks = db.task_list(deployment=deployment_id)
        return [task.uuid for task in tasks]

    @error_handler_decorator
    def start_task(self, task_json_path):
        task_name = get_task_name(task_json_path)
        print "Start task [%s]...." % task_name

        command = 'rally -v task start %s' % task_json_path
        logging.info(command)
        returncode, output, err = self.exec_cli(command)

        logging.info("task [%s] output is %s" % (task_name, output))
        print "Done task [%s]" % task_name

        print "Start to collect report......"
        self.collect_and_send_report(task_name, output)

        print "Collecting report for task [%s] is done!" % task_name

    def collect_and_send_report(self, task_name, task_output):
        """
        {
            "results": {
                "actions": {
                     "$action": {
                         "duration": {
                             "summary": {
                                 "min (sec)": xx,
                                 "max (sec)": xx,
                                 "avg (sec)": xx,
                                 "success": xx,
                                 "errors": xx,
                                 "total": xx
                             },
                             "data": [xx,xx,xx]
                         }
                     }
                },
                'total_errors': x
            },
            "category": "xxx",
            "raw_output": {...}
        }
        """
        report_name = get_report_name(task_name)
        report_url = '/'.join((self.url, report_name))
        match = re.search('\s?rally task results\s+([\da-f\-]+)\s?', task_output)
        if not match:
            raise HealthException('Unknown rally internel error!', report_url)

        task_uuid = match.group(1)
        task_obj = db.task_get(task_uuid)
        if task_obj['status'] == 'failed':
            raise HealthException(task_obj['verification_log'], report_url)

        command = "rally task results %s" % task_uuid
        logging.info("[collect_and_send_report] command is %s" % command)

        print "Start to collect report for task [%s]" % task_name
        return_code, task_result, err = self.exec_cli(command)
        if return_code > 0:
            raise HealthException(err, report_url)

        output = json.loads(task_result)[0]
        report = {'actions': {}}
        actions = []

        # Get the name of actions
        actions = []
        if output['result']:
            actions = output['result'][0]['atomic_actions'].keys()

        for result in output['result']:
            if result['error']:
                continue
            actions = result['atomic_actions'].keys()
            break

        if not actions:
            actions.append(report_name)

        # Get and set report for each action
        for action in actions:
            report['actions'].setdefault(action, {'duration': {}})
            report['actions'][action]['duration'] \
                = self._get_action_dur_report(action, output)

        # Get and set errors if any
        errors = self._get_total_errors(output)
        report['total_errors'] = errors

        logging.info("task [%s] report is: %s" % (task_name, report))

        final_report = {"results": report, "raw_output": output}
        self.send_report(final_report, report_url)

    def _get_total_errors(self, output):
        results = output['result']
        if not results:
            return 1
        total_errors = 0

        for result in results:
            if result['error']:
                total_errors += 1

        return total_errors

    def _get_action_dur_report(self, action, output):
        summary = {
            'min (sec)': 0,
            'avg (sec)': 0,
            'max (sec)': 0,
            'success': '0.0%',
            'errors': {},
            'total': 0
        }
        data = []
        errors = {
            'count': 0,
            'details': []
        }
        min_dur = sys.maxint
        max_dur = 0
        total_dur = 0
        no_action = 0

        results = output['result']

        for result in results:
            atomic_actions = result['atomic_actions']

            if atomic_actions and action not in atomic_actions:
                no_action += 1
                data.append(0)
                continue
 
            elif (atomic_actions and not atomic_actions[action]
                  or not atomic_actions and result['error']):
                errors['count'] = errors['count'] + 1
                errors['details'].append(result['error'])
                data.append(0)
                continue

            duration = result['duration']
            if action in atomic_actions:
                duration = atomic_actions[action]

            total_dur += duration
            min_dur = [min_dur, duration][duration < min_dur]
            max_dur = [max_dur, duration][duration > max_dur]
            data.append(duration)

        error_count = errors['count']
        total_exec = output['key']['kw']['runner']['times']

        if not results:
            errors['count'] = total_exec
            errors['details'] = ['Unknown error!']
            summary['errors'] = errors

            return {
                'summary': summary,
                'data': data
            }

        if total_exec == error_count:
            # All actions in this scenario are failed.
            summary['min (sec)'] = 0
            summary['avg (sec)'] = 0
        else:
            summary['min (sec)'] = round_float(min_dur)
            summary['avg (sec)'] = round_float(
                total_dur / (total_exec - error_count - no_action)
            )

        summary['max (sec)'] = round_float(max_dur)
        summary['errors'] = errors
        summary['success'] = round_float(
            float(
                total_exec - error_count - no_action
            ) * 100 / float(len(results)),
            1
        ) + '%'
        summary['total'] = total_exec

        return {
            'summary': summary,
            'data': data
        }

    def create_reports(self, tasks):
        reports_list = []
        for task in tasks:
            temp = {}
            temp['name'] = get_report_name(get_task_name(task))
            temp['category'] = os.path.basename(os.path.dirname(task))
            reports_list.append(temp)

        logging.info("tasks are %s" % reports_list)

        payload = {"report_list": reports_list}
        resp = requests.post(
            self.url, data=json.dumps(payload), headers=REQUEST_HEADER
        )
        logging.info("[create reports] response code is %s" % resp.status_code)

    def send_report(self, report, report_url=None):
        if not report_url:
            logging.error("report_url is None!")
            report_url = self.url

        payload = {
            "report": report,
            "state": "success"
        }
        total_errors = report['results']['total_errors']
        exec_num = report['raw_output']['key']['kw']['runner']['times']

        if total_errors >= exec_num or total_errors == 0 and exec_num > 0:
            payload['state'] = 'error'
            payload['error_message'] = "Actions in this scenario are failed."

        elif total_errors:
            payload['state'] = 'finished'

        resp = requests.put(
            report_url, data=json.dumps(payload), headers=REQUEST_HEADER
        )
        logging.info("Update report reponse is %s" % resp.text)

    def cleanup_previous_tasks(self, deployment_id):
        tasks = self.get_tasks_uuid_from_db(deployment_id)

        for task_id in tasks:
            db.task_delete(task_id)

        logging.info("Delete all tasks of deployment[ID: %s]" % deployment_id)

    def run(self):
        tasks = self.get_all_tasks_config()
        self.create_reports(tasks)
        self.init_rally_config()
        self.create_deployment()

        logging.info("Start to run tasks...")
        process_num = 2
        try:
            cpu_num = multiprocessing.cpu_count()
            process_num = [process_num, cpu_num][process_num < cpu_num]
        except Exception:
            logging.info("cpu_count() has not been implemented!")

        logging.info("The number of processes will be %s." % process_num)
        try:
            pool = Pool(processes=process_num)
            pool.map_async(run_task, zip([self]*len(tasks), tasks))
            pool.close()
            pool.join()
        except Exception as ex:
            logging.info("processing pool get exception: '%s'" % ex)

        finally:
            clean_pidfile()


def main(compass_url, deployment_name):
    logging.info('compass_url is %s' % compass_url)
    if is_process_running():
        logging.info("[%s] already exisits, exit!" % PIDFILE)
        sys.exit()
    else:
        pid = str(os.getpid())
        file(PIDFILE, 'w').write(pid)

    checker = HealthCheck(compass_url, deployment_name)
    checker.run()
    logging.info("Health check is finished!")


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", type=str,
                        help="The URL to send reports back")
    parser.add_argument("--clustername", type=str,
                        help="The Cluster name")
    args = parser.parse_args()

    compass_url = args.url
    deployment_name = args.clustername

    main(compass_url, deployment_name)
