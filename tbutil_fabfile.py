from fabric.api import local, run, sudo
from fabric.colors import red, green, yellow
from fabric.contrib.console import confirm
from fabric.context_managers import quiet, cd, settings
from fabric.decorators import hosts, roles
from fabric.state import env, output
from fabric.contrib.files import exists

users='users.deterlab.net'

# GTL - this can be removed once we've updated fabric to new version.
env.disable_known_hosts = True
env.always_use_pty = False
output['running'] = False

class FabricException(Exception):
    pass

def show_ok(msg):
    print(green('[OK   ]') + ': ' + msg)

def show_warn(msg):
    print(yellow('[WARN ]') + ': ' + msg)

def show_err(msg, exitval=0):
    print(red('[ERROR]') + ': ' + msg)
    if exit:
        exit(exitval)

@hosts(users)
def swapexp(pid, eid, swapin):
    cmd = 'swapexp -e {},{} '.format(pid, eid)
    msg = 'Swapping experiment {},{} in'.format(pid, eid)
    if swapin:
        cmd += 'in'
    else:
        cmd += 'out'

    with quiet():
        result = local(cmd, capture=True)

    if result.failed:
        show_err(msg, exit=2)

    show_ok(msg)

@hosts(users)
def getnodes(pid, eid):
    cmd = '/usr/testbed/bin/node_list -v -c -e {},{}'.format(pid, eid)
    msg = 'getting nodenames for experiment...'
    with quiet():
        result = local(cmd, capture=True)
        if result:
            return result.split()
    
    return None

@hosts(users)
def initenv(pid, eid, parallel=True):
    nodenames = getnodes(pid, eid)
    msg = 'Initializing environment for experiment {},{}'.format(pid, eid)
    if not nodenames:
        show_warn(msg)
        if confirm('Experiment not found. Swap it in?)'):
            swapexp(pid, eid, swapin=True)
        else:
            show_err(msg + ' Exiting.', exitval=1)

    show_ok(msg)
    nodes = ['{}.{}.{}'.format(n, eid, pid) for n in nodenames]
    env.hosts = nodes
    env.parallel = parallel

def restart_magi():
    kill_magi()
    start_magi()

def kill_magi():
    msg = 'Killing and uninstalling Magi on {}'.format(env.host_string)
    with settings(warn_only=True, abort_exception=FabricException), quiet():
        try:
            run('sudo killall mongos mongod magi_daemon.py')
            run('sudo rm -rf /var/log/magi/db /usr/local/lib/python*/dist-packages/magi /tmp/MAGI* /tmp/magi*')
            show_ok(msg)
        except FabricException:
            show_err(msg)

def magi_log_to_space(old="/var/log/", new="/space/var/log/", conf="/var/log/magi/config/experiment.conf"):
    msg = 'Changing MAGI\'s default log dir of {} to {}'.format(old,new)
    # XXX Hack
    if '/space' in new:
        if not exists('/space'):
            show_err('\'/space/\' not set up.')
            return
    try:
        run('sudo mkdir -p {}'.format(new))
    except FabricException:
        show_err(msg)
    if exists(new):
        if exists(conf):
            try:
                file_find_replace(file=conf, old_text=old, new_text=new)
            except FabricException:
                show_err(msg)
        else:
            show_err('Conf file {} does not exist.'.format(conf))
    else:
        show_err('New log directory does not exist.')

def start_magi(mdir='/proj/edgect/magi/current'):
    msg = 'Installing and starting Magi on {}'.format(env.host_string)
    #mdir = '/proj/edgect/magi/current'
    with settings(warn_only=True, abort_exception=FabricException), quiet():
        try:
            run('sudo {}/magi_bootstrap.py -fp {}'.format(mdir, mdir))
#            run('sudo {}/magi_bootstrap.py -fUNp {}'.format(mdir, mdir))
            show_ok(msg)
        except FabricException:
            show_err(msg)

def kill_deterdash():
    if exists('/space/deterdash'):
        msg = 'Killing Deterdash on {}'.format(env.host_string)
        with settings(warn_only=True, abort_exception=FabricException), quiet():
            try:
                run('sudo pkill -f runserver.py')
                run('sudo pkill -f websocketd')
                show_ok(msg)
            except FabricException:
                show_err(msg)

def start_deterdash():
    d = '/space/deterdash'
    if exists(d):
        msg = 'Starting deterdash on {}'.format(env.host_string)
        with settings(warn_only=True, abort_exception=FabricException), quiet():
            try:
                run('sudo /space/deterdash/start_deterdash.sh')
                show_ok(msg)
            except FabricException:
                show_err(msg)

def kill_click():
    f = '/tmp/vrouter.click'
    if exists(f):
        msg = 'Killing click on {}'.format(env.host_string)
        with settings(warn_only=True, abort_exception=FabricException), quiet():
            try:
                run('sudo click-uninstall')
                show_ok(msg)
            except FabricException:
                show_err(msg)

def start_click():
    f = '/tmp/vrouter.click'
    if exists(f):
        msg = 'Starting click on {}'.format(env.host_string)
        with settings(warn_only=True, abort_exception=FabricException), quiet():
            try:
                run('sudo click-install {}'.format(f))
                show_ok(msg)
            except FabricException:
                show_err(msg)

def file_find_replace(file='/tmp/none', old_text='', new_text=''):
    if exists(file):
        msg = 'Replacing {} with {} on {}'.format(old_text, new_text, file)
        with settings(warn_only=True, abort_exception=FabricException), quiet():
            try:
                cmd="sudo sed 's/{}/{}/g' {} > {}.orig".format(old_text, new_text, file, file)
                run(cmd)
                run("mv {}.orig {}".format(file,file))
                show_ok(msg)
            except FabricException:
                show_err(msg)
