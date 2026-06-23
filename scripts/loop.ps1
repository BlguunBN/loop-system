[CmdletBinding()]
param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Args
)

$ErrorActionPreference = 'Stop'
$DefaultGoal = 'Continue improving this project safely and incrementally.'
$DefaultAgent = 'agent'
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Show-Usage {
  @'
Usage:
  loop [--agent NAME] <project_dir> [goal...]
  loop [--agent NAME] install <project_dir> [goal...]  # alias for init
  loop [--agent NAME] bootstrap <project_dir> [goal...] # alias for init
  loop [--agent NAME] setup <project_dir> [goal...]     # alias for init
  loop [--agent NAME] prompt <project_dir> [goal...]    # print the agent prompt
  loop [--agent NAME] readme <project_dir> [goal...]    # write README.md for the project
  loop [--agent NAME] init <project_dir> [goal...]      # create state, README, and prompt
  loop [--agent NAME] {new|start|resume|focus|tick|health|status|stop} <project_dir> [goal...]
  loop list
  loop prune [days]
  loop interval <project_dir> <minutes>
'@
}

function Normalize-ProjectPath {
  param([Parameter(Mandatory = $true)][string]$Path)

  $p = $Path.Trim()
  if ($p.StartsWith('~/') -or $p.StartsWith('~\')) {
    $p = Join-Path $HOME $p.Substring(2)
  }

  try {
    return [System.IO.Path]::GetFullPath($p)
  } catch {
    return $p
  }
}

function Get-HermesHome {
  if ($env:HERMES_HOME) { return $env:HERMES_HOME }
  return (Join-Path $HOME 'AppData\Local\hermes')
}

function Get-StateRoot {
  Join-Path (Get-HermesHome) 'loop-agent'
}

function Get-RegistryPath {
  Join-Path (Get-StateRoot) 'projects.json'
}

function Get-ActiveProjectPath {
  Join-Path (Get-StateRoot) 'active-project.txt'
}

function Get-StatePath {
  param([Parameter(Mandatory = $true)][string]$ProjectDir)
  Join-Path (Join-Path $ProjectDir '.hermes-loop') 'state.json'
}

function Ensure-Directory {
  param([Parameter(Mandatory = $true)][string]$Path)
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Read-JsonFile {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    $Default = $null
  )

  if (Test-Path $Path) {
    try {
      $raw = Get-Content -Raw -Encoding UTF8 $Path
      if ($raw.Trim()) {
        return $raw | ConvertFrom-Json
      }
    } catch {
    }
  }

  return $Default
}

function Save-JsonFile {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)]$Object
  )

  $parent = Split-Path -Parent $Path
  if ($parent) { Ensure-Directory $parent }
  $json = $Object | ConvertTo-Json -Depth 20
  [System.IO.File]::WriteAllText($Path, $json, $Utf8NoBom)
}

function New-Registry {
  [pscustomobject]@{
    cursor = 0
    projects = @()
  }
}

function Load-Registry {
  $registry = Read-JsonFile -Path (Get-RegistryPath) -Default (New-Registry)
  if (-not $registry.PSObject.Properties['cursor']) { $registry | Add-Member NoteProperty cursor 0 }
  if (-not $registry.PSObject.Properties['projects']) { $registry | Add-Member NoteProperty projects @() }
  if ($null -eq $registry.projects) { $registry.projects = @() }
  return $registry
}

function Save-Registry {
  param([Parameter(Mandatory = $true)]$Registry)
  Save-JsonFile -Path (Get-RegistryPath) -Object $Registry
}

function Load-State {
  param([Parameter(Mandatory = $true)][string]$ProjectDir)
  Read-JsonFile -Path (Get-StatePath $ProjectDir) -Default $null
}

function Save-State {
  param(
    [Parameter(Mandatory = $true)][string]$ProjectDir,
    [Parameter(Mandatory = $true)]$State
  )

  Save-JsonFile -Path (Get-StatePath $ProjectDir) -Object $State
}

function Ensure-RegistryEntry {
  param(
    [Parameter(Mandatory = $true)]$Registry,
    [Parameter(Mandatory = $true)][string]$ProjectDir
  )

  $registryProjects = @($Registry.projects)
  if ($registryProjects -notcontains $ProjectDir) {
    $Registry.projects = @($registryProjects + $ProjectDir)
  }
}

function Write-ActiveProject {
  param([Parameter(Mandatory = $true)][string]$ProjectDir)
  Ensure-Directory (Get-StateRoot)
  [System.IO.File]::WriteAllText((Get-ActiveProjectPath), $ProjectDir, $Utf8NoBom)
}

function Register-Project {
  param([Parameter(Mandatory = $true)][string]$ProjectDir)
  $registry = Load-Registry
  Ensure-RegistryEntry -Registry $registry -ProjectDir $ProjectDir
  Save-Registry -Registry $registry
}

function Parse-IsoDate {
  param([string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
  try {
    return [datetime]::Parse($Value, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)
  } catch {
    try { return [datetime]::Parse($Value) } catch { return $null }
  }
}

function Get-PythonCommand {
  $python = Get-Command python -ErrorAction SilentlyContinue
  if ($python) { return @{ Path = $python.Path; Args = @() } }

  $py = Get-Command py -ErrorAction SilentlyContinue
  if ($py) { return @{ Path = $py.Path; Args = @('-3') } }

  $python3 = Get-Command python3 -ErrorAction SilentlyContinue
  if ($python3) { return @{ Path = $python3.Path; Args = @() } }

  return $null
}

function Invoke-Autopilot {
  param(
    [Parameter(Mandatory = $true)][string]$ProjectDir,
    [string]$Goal
  )

  $hermesHome = Get-HermesHome
  $scriptPath = Join-Path (Join-Path $hermesHome 'scripts') 'loop_autopilot.py'
  if (-not (Test-Path -LiteralPath $scriptPath)) {
    Write-Output "TICK: $ProjectDir"
    Write-Output "NOTE: Autopilot script not found at $scriptPath"
    Write-Output "      Loop tick requires the Hermes agent stack for full automation."
    Write-Output "      Run 'loop health' and 'loop focus' manually to proceed."
    exit 0
  }

  $python = Get-PythonCommand
  if (-not $python) {
    Write-Output "TICK: $ProjectDir"
    Write-Output "NOTE: Python not found on PATH (required for Hermes autopilot)."
    Write-Output "      Run 'loop health' and 'loop focus' manually to proceed."
    exit 0
  }

  $previous = $env:HERMES_LOOP_ACTIVE_PROJECT
  $env:HERMES_LOOP_ACTIVE_PROJECT = $ProjectDir
  try {
    $output = & $python.Path @($python.Args + $scriptPath) 2>&1
    $exitCode = $LASTEXITCODE
    if ($output) {
      $output | ForEach-Object { Write-Output $_ }
    }
    exit $exitCode
  } catch {
    Write-Output "TICK: $ProjectDir"
    Write-Output "NOTE: Autopilot encountered an error: $($_.Exception.Message)"
    Write-Output "      Run 'loop health' and 'loop focus' manually to proceed."
    exit 0
  } finally {
    if ($null -ne $previous) {
      $env:HERMES_LOOP_ACTIVE_PROJECT = $previous
    } else {
      Remove-Item Env:HERMES_LOOP_ACTIVE_PROJECT -ErrorAction SilentlyContinue
    }
  }
}

function Get-PromptText {
  param(
    [Parameter(Mandatory = $true)][string]$ProjectDir,
    [string]$Goal,
    [string]$AgentName
  )

  @"
You are the autonomous loop agent for this project.

Compatible runtimes: Hermes, Claude Code, Codex, OpenCode, Cursor, or any other agent that can run shell commands.

Project root: $ProjectDir
Goal: $Goal
Runtime: $AgentName

Rules:
- Use the loop control workflow, not chat-only planning.
- First run health.
- If the project is ready, focus or resume it.
- Then run one safe tick.
- Keep iterating on the next safe step.
- Keep replies short and status-oriented.
- If blocked, report the exact blocker and missing prerequisite.
- Use list/status/focus/tick/interval/prune to manage the loop.

Suggested command sequence:
1. loop health "$ProjectDir"
2. loop focus "$ProjectDir" "$Goal"
3. loop tick "$ProjectDir" "$Goal"
4. loop list
"@
}

function Get-ReadmeText {
  param(
    [Parameter(Mandatory = $true)][string]$ProjectDir,
    [string]$Goal,
    [string]$AgentName
  )

  @"
# Loop Agent README

Project: $ProjectDir
Goal: $Goal
Runtime: $AgentName

## Start here

1. Health check:

    loop health "$ProjectDir"

2. Focus the project:

    loop focus "$ProjectDir" "$Goal"

3. Run one loop tick:

    loop tick "$ProjectDir" "$Goal"

4. Inspect the fleet:

    loop list

## Agent prompt

$(Get-PromptText -ProjectDir $ProjectDir -Goal $Goal -AgentName $AgentName)

## Useful controls

- loop status "$ProjectDir"
- loop interval "$ProjectDir" 30
- loop prune 30
"@
}

function Ensure-ProjectState {
  param(
    [Parameter(Mandatory = $true)][string]$ProjectDir,
    [string]$Goal,
    [switch]$Active,
    [int]$SummaryIntervalMinutes = 30
  )

  $state = Load-State $ProjectDir
  if (-not $state) {
    $state = [pscustomobject]@{
      project_dir = $ProjectDir
      goal = $Goal
      active = [bool]$Active
      started_at = (Get-Date).ToUniversalTime().ToString('o')
      last_resumed_at = (Get-Date).ToUniversalTime().ToString('o')
      last_stopped_at = $null
      summary_interval_minutes = $SummaryIntervalMinutes
      last_sent_at = $null
      last_fingerprint = $null
    }
  } else {
    $state.project_dir = $ProjectDir
    if ($Goal) { $state.goal = $Goal }
    if ($Active) {
      $state.active = $true
      $state.last_resumed_at = (Get-Date).ToUniversalTime().ToString('o')
      if (-not $state.started_at) { $state.started_at = (Get-Date).ToUniversalTime().ToString('o') }
    }
    if (-not $state.summary_interval_minutes) { $state.summary_interval_minutes = $SummaryIntervalMinutes }
    if (-not $state.PSObject.Properties['last_sent_at']) { $state | Add-Member NoteProperty last_sent_at $null }
    if (-not $state.PSObject.Properties['last_fingerprint']) { $state | Add-Member NoteProperty last_fingerprint $null }
  }

  Save-State -ProjectDir $ProjectDir -State $state
  Register-Project -ProjectDir $ProjectDir
  return $state
}

function Get-HealthReport {
  param([Parameter(Mandatory = $true)][string]$ProjectDir)

  $issues = New-Object System.Collections.Generic.List[string]
  if (-not (Test-Path $ProjectDir)) { $issues.Add('project_dir_missing') }

  $stateFile = Get-StatePath $ProjectDir
  $state = Load-State $ProjectDir
  if (-not $state) {
    $issues.Add('state_missing')
  } elseif (-not [bool]$state.active) {
    $issues.Add('inactive')
  }

  [pscustomobject]@{
    project_dir = $ProjectDir
    ok = ($issues.Count -eq 0)
    issues = @($issues)
    state_file = $stateFile
    has_goal = [bool]($state -and $state.goal)
    summary_interval_minutes = if ($state -and $state.summary_interval_minutes) { [int]$state.summary_interval_minutes } else { 30 }
  }
}

$agentName = $DefaultAgent
$remaining = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $Args.Count; $i++) {
  switch -Regex ($Args[$i]) {
    '^--agent$|^--runtime$' {
      if ($i + 1 -lt $Args.Count) {
        $agentName = $Args[$i + 1]
        $i++
      }
      continue
    }
    '^--agent=|^--runtime=' {
      $agentName = $Args[$i].Split('=', 2)[1]
      continue
    }
    '^--$' { continue }
    default { $remaining.Add($Args[$i]) }
  }
}

if ($remaining.Count -lt 1) {
  Show-Usage
  exit 1
}

$action = $remaining[0]
$actionArgs = @($remaining | Select-Object -Skip 1)

switch -Regex ($action) {
  '^(help|-h|--help)$' {
    Show-Usage
    exit 0
  }

  '^(install|bootstrap|setup)$' {
    if ($actionArgs.Count -lt 1) {
      Show-Usage
      exit 1
    }
    $projectDir = Normalize-ProjectPath $actionArgs[0]
    $goal = ($actionArgs | Select-Object -Skip 1) -join ' '
    if (-not $goal) { $goal = $DefaultGoal }
    $state = Ensure-ProjectState -ProjectDir $projectDir -Goal $goal -Active
    Write-Host "INIT: $projectDir"
    Write-Host "STATE: $((Get-StatePath $projectDir))"
    Write-Host (Get-PromptText -ProjectDir $projectDir -Goal $goal -AgentName $agentName)
    exit 0
  }

  '^prompt$' {
    if ($actionArgs.Count -lt 1) {
      Show-Usage
      exit 1
    }
    $projectDir = Normalize-ProjectPath $actionArgs[0]
    $goal = ($actionArgs | Select-Object -Skip 1) -join ' '
    if (-not $goal) { $goal = $DefaultGoal }
    Write-Host (Get-PromptText -ProjectDir $projectDir -Goal $goal -AgentName $agentName)
    exit 0
  }

  '^readme$' {
    if ($actionArgs.Count -lt 1) {
      Show-Usage
      exit 1
    }
    $projectDir = Normalize-ProjectPath $actionArgs[0]
    $goal = ($actionArgs | Select-Object -Skip 1) -join ' '
    if (-not $goal) { $goal = $DefaultGoal }
    Ensure-Directory $projectDir
    $text = Get-ReadmeText -ProjectDir $projectDir -Goal $goal -AgentName $agentName
    $readmePath = Join-Path $projectDir 'README.md'
    [System.IO.File]::WriteAllText($readmePath, $text, $Utf8NoBom)
    Write-Host "README: $readmePath"
    exit 0
  }

  '^init$' {
    if ($actionArgs.Count -lt 1) {
      Show-Usage
      exit 1
    }
    $projectDir = Normalize-ProjectPath $actionArgs[0]
    $goal = ($actionArgs | Select-Object -Skip 1) -join ' '
    if (-not $goal) { $goal = $DefaultGoal }
    Ensure-Directory $projectDir
    $state = Ensure-ProjectState -ProjectDir $projectDir -Goal $goal -Active
    $readmePath = Join-Path $projectDir 'README.md'
    [System.IO.File]::WriteAllText($readmePath, (Get-ReadmeText -ProjectDir $projectDir -Goal $goal -AgentName $agentName), $Utf8NoBom)
    Write-Host "INIT: $projectDir"
    Write-Host "STATE: $((Get-StatePath $projectDir))"
    Write-Host "README: $readmePath"
    Write-Host (Get-PromptText -ProjectDir $projectDir -Goal $goal -AgentName $agentName)
    exit 0
  }

  '^(new|start|resume)$' {
    if ($actionArgs.Count -lt 1) {
      Show-Usage
      exit 1
    }
    $projectDir = Normalize-ProjectPath $actionArgs[0]
    $goal = ($actionArgs | Select-Object -Skip 1) -join ' '
    $state = Ensure-ProjectState -ProjectDir $projectDir -Goal $goal -Active
    Write-ActiveProject $projectDir
    Write-Host "$($action.ToUpperInvariant()): $projectDir"
    exit 0
  }

  '^focus$' {
    if ($actionArgs.Count -lt 1) {
      Show-Usage
      exit 1
    }
    $projectDir = Normalize-ProjectPath $actionArgs[0]
    $goal = ($actionArgs | Select-Object -Skip 1) -join ' '
    $state = Ensure-ProjectState -ProjectDir $projectDir -Goal $goal -Active
    $state.active = $true
    $state.last_resumed_at = (Get-Date).ToUniversalTime().ToString('o')
    Save-State -ProjectDir $projectDir -State $state
    Register-Project -ProjectDir $projectDir
    Write-ActiveProject $projectDir
    Write-Host "FOCUSED: $projectDir"
    exit 0
  }

  '^stop$' {
    if ($actionArgs.Count -lt 1) {
      Show-Usage
      exit 1
    }
    $projectDir = Normalize-ProjectPath $actionArgs[0]
    $goal = ($actionArgs | Select-Object -Skip 1) -join ' '
    $state = Load-State $projectDir
    if (-not $state) { $state = Ensure-ProjectState -ProjectDir $projectDir -Goal $goal }
    $state.active = $false
    $state.last_stopped_at = (Get-Date).ToUniversalTime().ToString('o')
    if ($goal) { $state.goal = $goal }
    Save-State -ProjectDir $projectDir -State $state
    Register-Project -ProjectDir $projectDir
    Write-Host "STOPPED: $projectDir"
    exit 0
  }

  '^interval$' {
    if ($actionArgs.Count -lt 2) {
      Show-Usage
      exit 1
    }
    $projectDir = Normalize-ProjectPath $actionArgs[0]
    $minutes = 30
    try { $minutes = [int]$actionArgs[1] } catch { }
    if ($minutes -lt 1) { $minutes = 1 }
    $state = Ensure-ProjectState -ProjectDir $projectDir -Goal '' -SummaryIntervalMinutes $minutes
    $state.summary_interval_minutes = $minutes
    Save-State -ProjectDir $projectDir -State $state
    Register-Project -ProjectDir $projectDir
    Write-ActiveProject $projectDir
    Write-Host "INTERVAL: $projectDir -> ${minutes}m"
    exit 0
  }

  '^health$' {
    if ($actionArgs.Count -lt 1) {
      Show-Usage
      exit 1
    }
    $projectDir = Normalize-ProjectPath $actionArgs[0]
    Get-HealthReport -ProjectDir $projectDir | ConvertTo-Json -Depth 10 | Write-Output
    exit 0
  }

  '^status$' {
    if ($actionArgs.Count -lt 1) {
      Show-Usage
      exit 1
    }
    $projectDir = Normalize-ProjectPath $actionArgs[0]
    $state = Load-State $projectDir
    if (-not $state) {
      Write-Host "NO STATE: $projectDir"
    } else {
      $state | ConvertTo-Json -Depth 10 | Write-Output
    }
    exit 0
  }

  '^list$' {
    $registry = Load-Registry
    $rows = foreach ($item in @($registry.projects)) {
      $state = Load-State $item
      [pscustomobject]@{
        project_dir = $item
        active = [bool]($state -and $state.active)
        goal = if ($state -and $state.goal) { [string]$state.goal } else { '' }
        summary_interval_minutes = if ($state -and $state.summary_interval_minutes) { [int]$state.summary_interval_minutes } else { 30 }
        started_at = if ($state) { $state.started_at } else { $null }
        last_resumed_at = if ($state) { $state.last_resumed_at } else { $null }
        last_stopped_at = if ($state) { $state.last_stopped_at } else { $null }
      }
    }
    [pscustomobject]@{
      cursor = [int]$registry.cursor
      projects = @($rows)
    } | ConvertTo-Json -Depth 10 | Write-Output
    exit 0
  }

  '^prune$' {
    $days = 30
    if ($actionArgs.Count -ge 1) {
      try { $days = [int]$actionArgs[0] } catch { $days = 30 }
    }
    if ($days -lt 1) { $days = 1 }
    $registry = Load-Registry
    $cutoff = (Get-Date).ToUniversalTime().AddDays(-$days)
    $kept = New-Object System.Collections.Generic.List[string]
    $pruned = New-Object System.Collections.Generic.List[string]

    foreach ($item in @($registry.projects)) {
      $state = Load-State $item
      if (-not $state) {
        $kept.Add($item)
        continue
      }
      if ([bool]$state.active) {
        $kept.Add($item)
        continue
      }
      $stampSource = $state.last_stopped_at
      if (-not $stampSource) { $stampSource = $state.started_at }
      $stamp = Parse-IsoDate $stampSource
      if ($stamp -and $stamp.ToUniversalTime() -lt $cutoff) {
        try {
          Remove-Item -Recurse -Force (Join-Path $item '.hermes-loop') -ErrorAction SilentlyContinue
        } catch {
        }
        $pruned.Add($item)
      } else {
        $kept.Add($item)
      }
    }

    $registry.projects = @($kept)
    if ([int]$registry.cursor -ge [Math]::Max(1, $kept.Count)) { $registry.cursor = 0 }
    Save-Registry -Registry $registry
    [pscustomobject]@{
      days = $days
      pruned = @($pruned)
      kept = @($kept)
    } | ConvertTo-Json -Depth 10 | Write-Output
    exit 0
  }

  '^tick$' {
    if ($actionArgs.Count -lt 1) {
      Show-Usage
      exit 1
    }
    $projectDir = Normalize-ProjectPath $actionArgs[0]
    $goal = ($actionArgs | Select-Object -Skip 1) -join ' '
    $health = Get-HealthReport -ProjectDir $projectDir
    if (-not $health.ok) {
      $health | ConvertTo-Json -Depth 10 | Write-Output
      exit 1
    }
    $state = Load-State $projectDir
    if (-not $state) {
      $state = Ensure-ProjectState -ProjectDir $projectDir -Goal $goal -Active
    } elseif ($goal) {
      $state.goal = $goal
      Save-State -ProjectDir $projectDir -State $state
      Register-Project -ProjectDir $projectDir
    }
    $effectiveGoal = $goal
    if (-not $effectiveGoal) { $effectiveGoal = $state.goal }
    if (-not $effectiveGoal) { $effectiveGoal = $DefaultGoal }
    Invoke-Autopilot -ProjectDir $projectDir -Goal $effectiveGoal
  }

  default {
    Show-Usage
    exit 1
  }
}
Write-Host 'SCRIPT_IS_RUNNING'
