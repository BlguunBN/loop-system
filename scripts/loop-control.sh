#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo 'Usage: hermes-loop-control.sh {new|start|stop|resume|focus|interval|health|tick|status|list|prune} PROJECT_DIR [goal text...]' >&2
  exit 1
fi

action=$1
shift || true

if [[ "$action" == "list" || "$action" == "prune" ]]; then
  project_dir=""
else
  project_dir=${1:-}
  if [[ -z "$project_dir" ]]; then
    echo 'Missing PROJECT_DIR' >&2
    exit 1
  fi
  shift || true
  project_dir=$(cd "$project_dir" && pwd)
fi

goal=${*:-}

python - "$action" "$project_dir" "$goal" <<'PY'
import json
import os
import sys
import subprocess
import shutil
from datetime import datetime, timezone
from pathlib import Path

action = sys.argv[1]
project_dir = Path(sys.argv[2]) if sys.argv[2] else None
goal = sys.argv[3]
hermes_home = Path(os.environ.get('HERMES_HOME', Path.home() / 'AppData' / 'Local' / 'hermes'))
state_root = hermes_home / 'loop-agent'
registry_file = state_root / 'projects.json'
active_project_file = state_root / 'active-project.txt'
state_root.mkdir(parents=True, exist_ok=True)


def now():
    return datetime.now(timezone.utc).isoformat()


def load_registry():
    if registry_file.exists():
        try:
            data = json.loads(registry_file.read_text(encoding='utf-8'))
            if isinstance(data, dict):
                data.setdefault('cursor', 0)
                data.setdefault('projects', [])
                if not isinstance(data['projects'], list):
                    data['projects'] = []
                return data
        except Exception:
            pass
    return {'cursor': 0, 'projects': []}


def save_registry(data):
    registry_file.write_text(json.dumps(data, indent=2), encoding='utf-8')


def state_file_for(project_dir: Path) -> Path:
    return project_dir / '.hermes-loop' / 'state.json'


def load_state(path: Path):
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding='utf-8'))
    except Exception:
        return {}


def save_state(path: Path, state: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(state, indent=2), encoding='utf-8')


def ensure_registry_entry(registry, project_dir_str: str):
    if project_dir_str not in registry['projects']:
        registry['projects'].append(project_dir_str)


def mark_active_pointer(project_dir_str: str):
    active_project_file.write_text(project_dir_str, encoding='utf-8')


def parse_iso(value: str | None):
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace('Z', '+00:00'))
    except Exception:
        return None


def prune_threshold_days(raw: str) -> int:
    try:
        days = int(str(raw).strip() or '30')
        return max(1, days)
    except Exception:
        return 30


def health_report(project_dir: Path) -> dict:
    issues = []
    state_file = state_file_for(project_dir)
    state = load_state(state_file)
    if not project_dir.exists():
        issues.append('project_dir_missing')
    if not (project_dir / '.git').exists():
        issues.append('not_a_git_repo')
    try:
        subprocess.run(['git', '-C', str(project_dir), 'rev-parse', '--is-inside-work-tree'], capture_output=True, text=True, check=True)
    except Exception:
        issues.append('git_unavailable_or_not_repo')
    if not state:
        issues.append('state_missing')
    elif not state.get('active', False):
        issues.append('inactive')
    return {
        'project_dir': str(project_dir),
        'ok': not issues,
        'issues': issues,
        'state_file': str(state_file),
        'has_goal': bool(state.get('goal')) if state else False,
        'summary_interval_minutes': state.get('summary_interval_minutes', 30) if state else 30,
    }


if not project_dir and action not in {'list', 'prune'}:
    print('Missing PROJECT_DIR', file=sys.stderr)
    raise SystemExit(1)

registry = load_registry()
project_dir_str = str(project_dir) if project_dir else ''
if project_dir:
    state_path = state_file_for(project_dir)
    state = load_state(state_path)
    ensure_registry_entry(registry, project_dir_str)
else:
    state_path = None
    state = {}

if action == 'prune':
    days = prune_threshold_days(goal)
    cutoff = datetime.now(timezone.utc).timestamp() - days * 86400
    pruned = []
    keep = []
    for item in list(registry.get('projects', [])):
        p = Path(item)
        s = load_state(state_file_for(p))
        if not s:
            keep.append(item)
            continue
        if s.get('active', False):
            keep.append(item)
            continue
        stopped = parse_iso(s.get('last_stopped_at')) or parse_iso(s.get('started_at'))
        if stopped and stopped.timestamp() < cutoff:
            try:
                shutil.rmtree(p / '.hermes-loop', ignore_errors=True)
            except Exception:
                pass
            pruned.append(item)
        else:
            keep.append(item)
    registry['projects'] = keep
    if registry.get('cursor', 0) >= max(1, len(keep)):
        registry['cursor'] = 0
    save_registry(registry)
    print(json.dumps({'days': days, 'pruned': pruned, 'kept': keep}, indent=2))
    raise SystemExit(0)

if action == 'focus':
    if not project_dir:
        print('Missing PROJECT_DIR', file=sys.stderr)
        raise SystemExit(1)
    for item in registry.get('projects', []):
        p = Path(item)
        s = load_state(state_file_for(p))
        if not s:
            continue
        s['active'] = (p == project_dir)
        if p == project_dir:
            s['project_dir'] = project_dir_str
            if goal:
                s['goal'] = goal
            s['last_resumed_at'] = now()
            s.setdefault('started_at', now())
            s.setdefault('summary_interval_minutes', 30)
            s.setdefault('last_sent_at', None)
            s.setdefault('last_fingerprint', None)
        else:
            s['last_stopped_at'] = now()
        save_state(state_file_for(p), s)
    ensure_registry_entry(registry, project_dir_str)
    save_registry(registry)
    mark_active_pointer(project_dir_str)
    print(f'FOCUSED: {project_dir_str}')
    raise SystemExit(0)

if action == 'interval':
    if not project_dir:
        print('Missing PROJECT_DIR', file=sys.stderr)
        raise SystemExit(1)
    try:
        minutes = max(1, int((goal or '30').strip()))
    except Exception:
        print('Invalid interval minutes', file=sys.stderr)
        raise SystemExit(1)
    if not state:
        state = {
            'project_dir': project_dir_str,
            'goal': goal or '',
            'active': True,
            'started_at': now(),
            'summary_interval_minutes': minutes,
            'last_sent_at': None,
            'last_fingerprint': None,
        }
    else:
        state['summary_interval_minutes'] = minutes
    save_state(state_path, state)
    ensure_registry_entry(registry, project_dir_str)
    save_registry(registry)
    mark_active_pointer(project_dir_str)
    print(f'INTERVAL: {project_dir_str} -> {minutes}m')
    raise SystemExit(0)

if action == 'health':
    if not project_dir:
        print('Missing PROJECT_DIR', file=sys.stderr)
        raise SystemExit(1)
    print(json.dumps(health_report(project_dir), indent=2))
    raise SystemExit(0)

if action == 'tick':
    if not project_dir:
        print('Missing PROJECT_DIR', file=sys.stderr)
        raise SystemExit(1)
    health = health_report(project_dir)
    if not health['ok']:
        print(json.dumps(health, indent=2))
        raise SystemExit(1)
    ensure_registry_entry(registry, project_dir_str)
    if not state:
        state = {
            'project_dir': project_dir_str,
            'goal': goal or 'Continue improving the project safely and incrementally.',
            'active': True,
            'started_at': now(),
            'summary_interval_minutes': 30,
            'last_sent_at': None,
            'last_fingerprint': None,
        }
        save_state(state_file_for(project_dir), state)
    autopilot_script = hermes_home / 'scripts' / 'loop_autopilot.py'
    if not autopilot_script.exists():
        print(f'TICK: {project_dir_str}')
        print('NOTE: Autopilot script not found at ' + str(autopilot_script))
        print('      Loop tick requires the Hermes agent stack for full automation.')
        print("      Run 'loop health' and 'loop focus' manually to proceed.")
        raise SystemExit(0)
    env = os.environ.copy()
    env['HERMES_LOOP_ACTIVE_PROJECT'] = project_dir_str
    proc = subprocess.run([sys.executable, str(autopilot_script)], text=True, capture_output=True, env=env)
    if proc.stdout:
        print(proc.stdout, end='')
    if proc.stderr:
        print(proc.stderr, file=sys.stderr, end='')
    raise SystemExit(proc.returncode)

if action in {'new', 'start', 'resume'}:
    if not state:
        state = {
            'project_dir': project_dir_str,
            'goal': goal,
            'active': True,
            'started_at': now(),
            'last_resumed_at': now(),
            'summary_interval_minutes': 30,
            'last_sent_at': None,
            'last_fingerprint': None,
        }
    else:
        state['project_dir'] = project_dir_str
        if goal:
            state['goal'] = goal
        state['active'] = True
        state['last_resumed_at'] = now()
        state.setdefault('started_at', now())
        state.setdefault('summary_interval_minutes', 30)
        state.setdefault('last_sent_at', None)
        state.setdefault('last_fingerprint', None)
    save_state(state_path, state)
    save_registry(registry)
    mark_active_pointer(project_dir_str)
    print(f"{action.upper()}: {project_dir_str}")
    raise SystemExit(0)

if action == 'stop':
    state['project_dir'] = project_dir_str
    state['active'] = False
    state['last_stopped_at'] = now()
    state.setdefault('started_at', now())
    state.setdefault('goal', goal)
    save_state(state_path, state)
    save_registry(registry)
    print(f'STOPPED: {project_dir_str}')
    raise SystemExit(0)

if action == 'list':
    projects = registry.get('projects', [])
    rows = []
    for item in projects:
        p = Path(item)
        s = load_state(state_file_for(p))
        rows.append({
            'project_dir': item,
            'active': bool(s.get('active', False)),
            'goal': s.get('goal', ''),
            'summary_interval_minutes': s.get('summary_interval_minutes', 30),
            'started_at': s.get('started_at'),
            'last_resumed_at': s.get('last_resumed_at'),
            'last_stopped_at': s.get('last_stopped_at'),
        })
    print(json.dumps({'cursor': registry.get('cursor', 0), 'projects': rows}, indent=2))
    raise SystemExit(0)

if action == 'status':
    if not state:
        print(f'NO STATE: {project_dir_str}')
        raise SystemExit(0)
    print(json.dumps(state, indent=2))
    raise SystemExit(0)

print('Usage: hermes-loop-control.sh {new|start|stop|resume|focus|interval|health|tick|status|list|prune} PROJECT_DIR [goal text...]', file=sys.stderr)
raise SystemExit(1)
PY
