from multiprocessing import Pool
import argparse
import logging
import os
import simplejson as json
import site
import subprocess
import sys
import re


logging.basicConfig(filename='/var/log/check_health.log',
                    level=logging.INFO)

# Activate virtual environment for Rally
logging.info("Start to activate Rally virtual environment......")
virtual_env = '/opt/rally'
activate_this = '/opt/rally/bin/activate_this.py'
execfile(activate_this, dict(__file__=activate_this))
site.addsitedir(virtual_env)
if virtual_env not in sys.path:
    sys.path.append(virtual_env)
logging.info("Activated virtual environment.")


from oslo.config import cfg
from rally import db
from rally.common import version
import requests


CONF = cfg.CONF
PIDFILE = '/tmp/compass_health_check.pid'
REQUEST_HEADER = {'content-type': 'application/json'}


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
    logging.info("[clean_up] status_code: %s" % resp.status_code)


def error_handler_decorator(func):
    def func_wrapper(self, *args, **kwargs):
        try:
            return func(self, *args, **kwargs)

        except HealthException as exc:
            func_name = func.__name__
            err_msg = str(exc)
            error_handler(func_name, err_msg, exc.url)
            sys.exit()

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
    def exec_cli(self, command, max_reties=3):
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
                logging.error(err_msg)
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
        task_name = os.path.basename(task_json_path).split('.')[0]
        print "Start task [%s]...." % task_name

        command = 'rally -v task start %s' % task_json_path
        logging.info(command)
        returncode, output, err = self.exec_cli(command)

        logging.info("task [%s] output is %s" % (task_name, output))
        print "Done task [%s]" % task_name

        print "Start to collect report......"
        catergory = os.path.basename(os.path.dirname(task_json_path))
        self.collect_and_send_report(task_name, catergory, output)

        print "Collecting report for task [%s] is done!" % task_name

    def collect_and_send_report(self, task_name, catergory, task_output):
        """
        {
            "report": {
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
                'errors_info': []
            },
            "catergory": "xxx",
            "raw_output": {...}
        }
        """
        report_url = '/'.join((self.url, task_name))
        match = re.search('Task\s+([\da-f\-]+)\s+is started', task_output)
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
        for result in output['result']:
            if result['atomic_actions'] and not result['error']:
                actions = result['atomic_actions'].keys()
                break

        # Get and set report for each action
        for action in actions:
            action_dur_report = self._get_action_dur_report(action, output)
            report['actions'].setdefault(action, {'duration': {}})
            report['actions'][action]['duration'] = action_dur_report

        # Get and set errors if any
        errors = self._get_errors_info(output)
        report['errors_info'] = errors

        # Set catergory
        report['catergory'] = catergory

        logging.info("task [%s] report is: %s" % (task_name, report))

        final_report = {"results": report, "raw_output": output}
        self.send_report(final_report, report_url)

    def _get_errors_info(self, output):
        results = output['result']
        errors_info = []

        for result in results:
            if result['error']:
                errors_info.append(result['error'])

        return errors_info

    def _get_action_dur_report(self, action, output):
        summary = {
            'min (sec)': 0,
            'avg (sec)': 0,
            'max (sec)': 0,
            'success': 0,
            'errors': 0,
            'total': 0
        }
        data = []

        results = output['result']
        if not results:
            return {
                'summary': summary,
                'data': data
            }

        min_dur = sys.maxint
        max_dur = 0
        errors = 0
        total_dur = 0

        for result in results:
            atomic_actions = result['atomic_actions']
            if action not in atomic_actions or not atomic_actions[action]:
                errors += 1
                data.append(0)
                continue

            duration = atomic_actions[action]
            total_dur += duration
            min_dur = [min_dur, duration][duration < min_dur]
            max_dur = [max_dur, duration][duration > max_dur]
            data.append(duration)

        summary = {}
        summary['min (sec)'] = round(min_dur, 3)
        summary['avg (sec)'] = round(total_dur / (len(results) - errors), 3)
        summary['max (sec)'] = round(max_dur, 3)
        summary['success'] = str(
            float(len(results) - errors) * 100 / float(len(results))
        ) + '%'
        summary['errors'] = errors
        summary['total'] = len(results)

        return {
            'summary': summary,
            'data': data
        }

    def send_report_names(self, tasks):
        names = [os.path.splitext(os.path.basename(task))[0] for task in tasks]
        logging.info("tasks are %s" % names)

        payload = {"report_names": names}
        resp = requests.post(
            self.url, data=json.dumps(payload), headers=REQUEST_HEADER
        )
        logging.info("[send_report_names] response code is %s" %
                     resp.status_code)

    def send_report(self, report, report_url=None):
        if not report_url:
            report_url = self.url

        payload = {
            "report": report,
            "state": "finished"
        }
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
        self.send_report_names(tasks)
        self.init_rally_config()
        self.create_deployment()

        logging.info("Start to run tasks...")
        pool = Pool(processes=2)
        pool.map(run_task, zip([self]*len(tasks), tasks))
        pool.close()
        pool.join()
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
