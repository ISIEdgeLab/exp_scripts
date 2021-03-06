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

    result = local(cmd, capture=True)

    if result.failed:
        show_err(msg, exit=2)

    show_ok(msg)

@hosts(users)
def getnodes(pid, eid):
    cmd = '/usr/testbed/bin/node_list -v -c -e {},{}'.format(pid, eid)
    msg = 'getting nodenames for experiment...'
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
    print('contacting nodes: {}'.format(nodes))

def restart_magi():
    kill_magi()
    start_magi()

def kill_magi():
    msg = 'Killing and uninstalling Magi on {}'.format(env.host_string)
    with settings(warn_only=True):
        try:
            run('sudo killall mongos mongod magi_daemon.py')
            run('sudo rm -rf /var/log/magi/db /usr/local/lib/python*/dist-packages/magi /tmp/MAGI* /tmp/magi*')
            show_ok(msg)
        except FabricException:
            show_err(msg)

def start_magi(mdir='/proj/edgect/magi/current'):
    msg = 'Installing and starting Magi on {}'.format(env.host_string)
    #mdir = '/proj/edgect/magi/current'
    with settings(warn_only=True):
        try:
            run('sudo {}/magi_bootstrap.py -p {}'.format(mdir, mdir))
            show_ok(msg)
        except FabricException:
            show_err(msg)

def kill_deterdash():
    if exists('/space/deterdash'):
        msg = 'Killing Deterdash on {}'.format(env.host_string)
        with settings(warn_only=True):
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
        with settings(warn_only=True):
            try:
                run('sudo /space/deterdash/start_deterdash.sh')
                show_ok(msg)
            except FabricException:
                show_err(msg)

def kill_click():
    f = '/tmp/vrouter.click'
    if exists(f):
        msg = 'Killing click on {}'.format(env.host_string)
        with settings(warn_only=True):
            try:
                run('sudo click-uninstall')
                show_ok(msg)
            except FabricException:
                show_err(msg)

def start_click():
    f = '/tmp/vrouter.click'
    if exists(f):
        msg = 'Starting click on {}'.format(env.host_string)
        with settings(warn_only=True):
            try:
                run('sudo click-install {}'.format(f))
                show_ok(msg)
            except FabricException:
                show_err(msg)
