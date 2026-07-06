---
name: autoware-patent-review
description: Review Autoware or ROS autonomous-driving pull requests for patent-sensitive technical changes. Use when asked to perform IP, patent, freedom-to-operate, infringement-risk, patent-search-keyword, or autonomous-driving technical-feature review of code changes involving planning, control, routing, fallback, MRM, fail-operational behavior, perception-to-planning interactions, maps, traffic signals, vehicles, pedestrians, or infrastructure.
---

# Autoware Patent Review

## Purpose

Produce a technical issue-spotting report for intellectual-property review of Autoware pull requests. Do **not** make a legal conclusion about patent infringement, validity, freedom to operate, or claim coverage. Flag candidate technical features that may merit patent review and explain why.

## Required Output Contract

For each relevant changed feature, output exactly these sections:

1. Technical feature summary
2. Changed packages, files, classes, functions, and ROS nodes
3. Inputs and outputs
4. Algorithmic steps
5. Why the feature may be patent-sensitive
6. English patent search keywords
7. Japanese patent search keywords
8. Possible patent classification hints, if inferable
9. Risk level: High / Medium / Watch / Low
10. Reason for the risk level

If no patent-sensitive autonomous-driving feature is introduced or materially modified, say so and briefly identify what changed.

## Review Scope

Focus on changes that introduce or materially modify autonomous-driving technical behavior, especially:

- Behavior planning and decision making
- Trajectory planning, path generation, path smoothing, optimization, and sampling
- Motion planning, obstacle avoidance, lane changes, parking, stops, pulls over, and merges
- Vehicle control, actuation commands, lateral/longitudinal control, and command arbitration
- Fallback behavior, degraded operation, MRM, fail-safe, and fail-operational behavior
- Route planning, mission planning, rerouting, and goal handling
- Interaction with other vehicles, pedestrians, cyclists, traffic signals, road signs, lane markings, maps, V2X, or infrastructure
- Safety monitors, diagnostics, watchdogs, state machines, mode transitions, and emergency handling
- Perception outputs consumed by planning/control when the change affects downstream behavior

Usually treat these as lower priority unless they alter technical vehicle behavior:

- Build scripts, CI, formatting, dependency pins, documentation-only updates
- Tests that only encode existing behavior
- Launch/config changes that tune a planning/control/fallback algorithm may still be relevant
- Refactors that preserve behavior may be Low or not relevant, but inspect for hidden logic changes

## Workflow

### 1. Establish the Changed Surface

Use repository-local evidence first:

```bash
git status --short
git diff --stat
git diff --name-only <base>...HEAD
git diff <base>...HEAD -- <path>
```

When a PR base is available, compare against the merge base. If no base is specified, inspect the working tree and recent commits. Identify packages by locating nearby `package.xml`, `CMakeLists.txt`, launch files, ROS node executables, and namespaces.

### 2. Map Code to Runtime Concepts

For each changed package, identify:

- ROS nodes/components and executable names
- Subscribed topics, services, actions, parameters, TF frames, and map inputs
- Published topics, commands, diagnostics, markers, and state outputs
- Main classes/functions touched
- Configuration parameters that affect algorithmic behavior

Prefer concrete symbol names from the diff over generic descriptions.

### 3. Extract the Technical Feature

For each behavior change, describe:

- Precondition: when the logic runs
- Inputs: messages, map objects, parameters, perception results, route/lanelet data, vehicle state
- Processing: decision rules, optimization objective, thresholds, state machine transitions, filtering, arbitration
- Outputs: trajectory/path/control command/state/diagnostic/emergency request
- Changed behavior compared with the previous implementation

### 4. Assess Patent Sensitivity

A change is more patent-sensitive when it includes any of the following:

- A concrete autonomous-driving decision algorithm, not merely plumbing
- A new combination of sensed/map/route inputs to produce a driving behavior
- A fallback, MRM, or fail-operational sequence with triggering conditions and control outputs
- A method for negotiating traffic participants or infrastructure
- A trajectory/control optimization or selection method
- A safety-critical state machine or arbitration mechanism
- Parameterized thresholds that define operational design behavior

A change is less patent-sensitive when it is purely mechanical refactoring, logging, visualization, build metadata, or tests without new behavior.

### 5. Assign Risk Level

Use this scale:

- **High**: New or materially changed planning/control/fallback algorithm that affects vehicle motion or safety behavior; or a nontrivial combination of perception/map/route inputs and decision outputs.
- **Medium**: Meaningful modification to an existing autonomous-driving algorithm, state machine, thresholding strategy, or interaction model; likely worth patent review but narrower than High.
- **Watch**: Configuration, interface, test, refactor, visualization, or plumbing change that may expose or slightly alter patent-sensitive behavior but does not clearly add a new algorithm.
- **Low**: Documentation, build, formatting, or behavior-preserving refactor with no apparent autonomous-driving technical feature.

Do not call something infringing. Use phrases such as "may be patent-sensitive," "candidate for IP review," and "search keywords." 

## Patent Search Keyword Guidance

Generate both English and Japanese search terms. Include synonyms for:

- Function: behavior planning, trajectory planning, motion planning, vehicle control, route planning, fallback, minimum risk maneuver
- Inputs: detected object, predicted path, traffic signal, lanelet map, route, occupancy grid, vehicle state, localization, V2X
- Outputs: trajectory, path, steering command, acceleration command, stop decision, lane change approval, emergency stop
- Technique: optimization, sampling, state machine, arbitration, threshold, cost function, collision risk, time-to-collision
- Context: autonomous vehicle, automated driving, advanced driver assistance, self-driving vehicle

For Japanese terms, include both katakana loanwords and common patent phrasing where useful:

- 自動運転, 自律走行, 車両制御, 走行制御
- 経路計画, 軌道計画, 動作計画, 行動計画
- 障害物回避, 衝突判定, 衝突リスク, 車間距離
- 最小リスク状態, ミニマムリスクマヌーバ, 退避制御, フェールセーフ
- 車線変更, 交差点, 信号機, 歩行者, 周辺車両, 地図情報

Read `references/classification-hints.md` when classification hints are needed.

## Reporting Template

Use this template for each feature:

```markdown
### Feature N: <short name>

1. **Technical feature summary**
   - <What changed and what behavior it affects.>
2. **Changed packages, files, classes, functions, and ROS nodes**
   - Package: `<package>`
   - Files: `<path>`
   - Classes/functions: `<symbol>`
   - ROS nodes/components: `<node>` or "not identified"
3. **Inputs and outputs**
   - Inputs: <topics/messages/parameters/maps/state>
   - Outputs: <topics/messages/commands/state>
4. **Algorithmic steps**
   - <Step-by-step method inferred from code.>
5. **Why the feature may be patent-sensitive**
   - <Technical reason; no legal conclusion.>
6. **English patent search keywords**
   - `<keyword group>`; `<keyword group>`
7. **Japanese patent search keywords**
   - `<keyword group>`; `<keyword group>`
8. **Possible patent classification hints, if inferable**
   - <IPC/CPC/FI/F-term hints or "not inferable from the diff">
9. **Risk level**
   - High / Medium / Watch / Low
10. **Reason for the risk level**
   - <Why this level fits.>
```

## Quality Bar

- Cite changed files and line ranges when the host environment requires citations.
- Separate facts observed in code from inferences.
- Be conservative: flag candidates for review, not conclusions.
- Mention uncertainty when ROS nodes, topics, or runtime wiring cannot be determined from the diff.
- Avoid exhaustive patent-law explanations; focus on technical feature extraction and search strategy.
