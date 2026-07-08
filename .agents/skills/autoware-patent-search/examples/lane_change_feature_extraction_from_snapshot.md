# Lane Change Feature Extraction from Read-only Autoware Snapshot

This document is technical triage for human IP-professional review only. It does **not** make conclusions about infringement, non-infringement, validity, invalidity, or freedom to operate.

## Checkout and snapshot verification

- Current branch verified before extraction: `main`.
- Current commit SHA verified before extraction: `89dffbe3aa8dbf1d4b6638459c05c67ed35e654a` (`Add read-only lane change source snapshot (#8)`).
- Snapshot path verified present: `reference/autoware/planning/behavior_path_planner/autoware_behavior_path_lane_change_module/`.
- Metadata verified present: `reference/autoware/SNAPSHOT_METADATA.md`.
- License verified present: `reference/autoware/AUTOWARE_UNIVERSE_LICENSE`.
- Upstream snapshot evidence from metadata: Autoware Universe `0.51.0`, commit `d4d260983d357e1b2b34291d91933f9f4b53bf94`, copied path `planning/behavior_path_planner/autoware_behavior_path_lane_change_module/`.
- Snapshot restriction honored: `reference/autoware/...` was treated as read-only evidence and was not modified.

## Files reviewed

Implementation-grounded review used the following snapshot files and file groups:

- Snapshot metadata and attribution:
  - `reference/autoware/SNAPSHOT_METADATA.md`
  - `reference/autoware/AUTOWARE_UNIVERSE_LICENSE`
- Package/component metadata:
  - `reference/autoware/planning/behavior_path_planner/autoware_behavior_path_lane_change_module/package.xml`
  - `reference/autoware/planning/behavior_path_planner/autoware_behavior_path_lane_change_module/plugins.xml`
  - `reference/autoware/planning/behavior_path_planner/autoware_behavior_path_lane_change_module/CMakeLists.txt`
- README/design evidence:
  - `reference/autoware/planning/behavior_path_planner/autoware_behavior_path_lane_change_module/README.md`
  - referenced README images/diagrams under `images/` were inventoried but not individually interpreted beyond README/source support.
- Parameters:
  - `reference/autoware/planning/behavior_path_planner/autoware_behavior_path_lane_change_module/config/lane_change.param.yaml`
- Headers:
  - `include/autoware/behavior_path_lane_change_module/base_class.hpp`
  - `include/autoware/behavior_path_lane_change_module/interface.hpp`
  - `include/autoware/behavior_path_lane_change_module/manager.hpp`
  - `include/autoware/behavior_path_lane_change_module/scene.hpp`
  - `include/autoware/behavior_path_lane_change_module/structs/{data.hpp,debug.hpp,parameters.hpp,path.hpp}`
  - `include/autoware/behavior_path_lane_change_module/utils/{calculation.hpp,markers.hpp,path.hpp,utils.hpp}`
- Source:
  - `src/interface.cpp`
  - `src/manager.cpp`
  - `src/scene.cpp`
  - `src/utils/{calculation.cpp,markers.cpp,path.cpp,utils.cpp}`
- Tests/test data:
  - `test/test_behavior_path_planner_node_interface.cpp`
  - `test/test_lane_change_scene.cpp`
  - `test/test_lane_change_utils.cpp`
  - `test/test_planning_factor.cpp`
  - `test_data/*.yaml`

## Key classes, functions, and plugin/component evidence

### Direct implementation evidence

- Package name: `autoware_behavior_path_lane_change_module`.
- Plugin library: `autoware_behavior_path_lane_change_module`.
- Plugin classes exported in `plugins.xml`:
  - `autoware::behavior_path_planner::LaneChangeLeftModuleManager`
  - `autoware::behavior_path_planner::LaneChangeRightModuleManager`
  - Base class: `autoware::behavior_path_planner::SceneModuleManagerInterface`
- Main manager/interface/scene classes:
  - `LaneChangeModuleManager`, `LaneChangeLeftModuleManager`, `LaneChangeRightModuleManager`
  - `LaneChangeInterface : SceneModuleInterface`
  - `LaneChangeBase`
  - `NormalLaneChange : LaneChangeBase`
- Key functions observed in headers/source:
  - Data/update and output: `LaneChangeInterface::updateData`, `postProcess`, `plan`, `planWaitingApproval`, `check_transit_failure`, `updateSteeringFactorPtr`.
  - Lane and transient metrics: `NormalLaneChange::update_lanes`, `update_transient_data`, `update_filtered_objects`, `updateLaneChangeStatus`.
  - Need/path generation: `isLaneChangeRequired`, `getSafePath`, `get_lane_change_paths`, `get_path_using_frenet`, `get_path_using_path_shifter`, `check_candidate_path_safety`, `generateOutput`, `extendPath`, `extendOutputDrivableArea`.
  - Object/safety/collision: `filter_objects`, `filterOncomingObjects`, `get_target_objects`, `isApprovedPathSafe`, `evaluateApprovedPathWithUnsafeHysteresis`, `isLaneChangePathSafe`, `find_colliding_object_if_all_paths_collide`, `is_colliding`, `isValidPath`.
  - Approval/cancel/abort/fallback: `calcAbortPath`, `isAbleToReturnCurrentLane`, `hasFinishedAbort`, `hasMissedLaneChangePath`, `isRequiredStop`, `insert_stop_point`, `insert_stop_point_on_current_lanes`, `set_stop_pose`.
  - Utilities: candidate path construction, lane expansion, predicted-path conversion, lane/object filtering, markers, calculations, and stop-point insertion under `src/utils/*`.

### Interpretation

The snapshot provides a behavior-path lane-change scene module that is loaded as left/right scene-module manager plugins by the larger behavior path planner. The snapshot does not define a standalone executable ROS node. Runtime node name, subscribed topics, and published topics are not fully inferable from this package alone because it depends on the parent behavior path planner framework.

## Inputs and outputs

### Direct implementation evidence

Inputs and internal data sources used by the module include:

- Parent planner data and previous module output: `prev_module_output_`, `PlannerData`, ego pose, ego velocity, current path velocity, route header, operation mode, external velocity limit, vehicle dimensions/common behavior path parameters, drivable-area expansion parameters, RTC state, and turn-signal decider.
- Route/map data: current lanelets, target lanelets, target neighbor lanes, preceding target lanes, current/target lane centerline paths, goal section flags, no-lane-change lines, regulatory elements, intersections, crosswalks, traffic lights, turn-direction lanelets, and lane polygons.
- Perception/prediction data: predicted dynamic objects converted into extended predicted objects with poses, polygons, predicted paths, initial poses, and twists.
- Configuration/thresholds: values from `lane_change.param.yaml` and dynamic parameter update logic in `manager.cpp`.
- Human/cooperation interface signals: RTC approval/force activation/deactivation and module status states.

Outputs include:

- `BehaviorModuleOutput` path, reference path, drivable-area info, turn-signal info, and stop pose context.
- Candidate lane-change path and path reference for RTC display/approval.
- Planning factors, including abort/shift direction, stop reasons, and safety factors.
- Objects-of-interest markers and collision-check debug maps.
- Lane-change states, RTC statuses, virtual walls, and debug marker arrays.

### Interpretation

The patent-searchable behavior is the conversion of route/lanelet, ego-state, predicted-object, and approval-state inputs into a lane-change path and associated safety/fallback outputs.

## Implementation-grounded technical features

### Feature 1: Lane-change necessity gating and route/lanelet context construction

**Implementation evidence**

- `update_lanes` obtains current and target lanes, target-neighbor lanes, centerline paths, preceding target lanes, goal-section flags, lane polygons, and no-lane-change lines.
- `update_transient_data` computes current path segment/velocity, prepare duration, lane-changing length, distance buffers, distances to terminal start/end, target-lane length, ego arc coordinates on current/target lanes, ego footprint, intersection/turn-direction-lane state, distances to no-lane-change lines, previous-intersection distance, stop time, and stuck status.
- `isLaneChangeRequired` rejects lane change when data or lanes are unavailable, ego is too far from the target-lane start relative to maximum prepare length, ego is near regulatory elements, or ego is near terminal end while not in autonomous mode.

**Interpretation**

This feature identifies when lane-change planning should be active by combining map topology, route progress, regulatory-element proximity, operation mode, ego footprint, and kinematic preparation constraints.

**Patent-searchable feature terms**

- Lane-change activation gating using lanelet route topology and ego distance to target-lane start.
- Regulatory-element-aware lane-change suppression near crosswalk/intersection/traffic light.
- Ego footprint and lane-polygon context for lane-change planning.

### Feature 2: Candidate path generation using path shifter and Frenet planner near terminal areas

**Implementation evidence**

- `getSafePath` calls `get_lane_change_paths`, stores valid paths in debug data, and selects the safe path if found or a force candidate otherwise.
- README flowcharts describe candidate generation by calculating lane-change lanes, preparing lane-change paths, checking validity/safety, and using path shifter or Frenet planning depending on terminal proximity and configuration.
- `get_path_using_path_shifter` loops over prepare metrics and lane-changing metrics, obtains a prepare segment, computes lateral shift to the target-lane centerline, computes lane-changing metrics, sets prepare velocity, constructs candidate paths, and checks candidate path safety.
- `get_path_using_frenet` is present for terminal-lane-change path generation when the Frenet planner is enabled; README states this is used to improve flexibility near terminal lane-change endpoints.
- `isValidPath` checks generated path points against expanded drivable lanelets and checks relative path angle.

**Interpretation**

This feature is a concrete lane-change trajectory generation and selection method using sampled longitudinal/lateral phase metrics, target-lane geometry, path shifter, and optional Frenet planning near terminal regions.

**Patent-searchable feature terms**

- Lane-change path generation with sampled prepare duration, longitudinal acceleration, lateral acceleration, jerk, and distance buffers.
- Terminal lane-change path generation using Frenet planner or path shifter.
- Candidate path validation against expanded drivable lanelets and path relative-angle constraints.

### Feature 3: Predicted-object filtering and target-object classification for safety checks

**Implementation evidence**

- README describes filtering predicted objects by class, filtering oncoming predicted objects by ego/object yaw difference, transforming them to extended predicted objects, expanding lanes, and categorizing objects into current lane, target-lane leading, target-lane trailing, target-lane leading stopped, and other lanes.
- `filter_objects`, `filterOncomingObjects`, and `get_target_objects` are declared/implemented for these categories.
- `lane_change.param.yaml` enables/disables object classes (`car`, `truck`, `bus`, `trailer`, `unknown`, `bicycle`, `motorcycle`, `pedestrian`) and sets lane expansion offsets and yaw thresholds.

**Interpretation**

The module does not simply collision-check all predictions; it narrows predicted objects into role-specific groups that determine how each object affects lane-change candidate safety and approved-path monitoring.

**Patent-searchable feature terms**

- Predicted-object categorization for lane-change safety by current lane, target-lane leading, target-lane trailing, stopped object, and other lane.
- Oncoming-object filtering using yaw-difference threshold.
- Lane expansion for object filtering in lane-change planning.

### Feature 4: Collision checking and RSS-style safety-margin selection

**Implementation evidence**

- README states candidate paths are checked against surrounding objects and that the module performs safe braking distance checks against predicted surrounding objects.
- `check_candidate_path_safety` rejects candidates near intersections when overtaking turn-lane objects are present, applies delay-lane-change checks, converts candidate paths to ego predicted paths, checks safety with RSS parameters, stores debug data, and applies target-lane bound checks when configured.
- `isApprovedPathSafe` continuously monitors approved path safety using target objects, overtaking turn-lane object checks, delay-lane-change checks, deceleration-sampled ego predicted paths, and `rss_params_for_abort`.
- `isLaneChangePathSafe` checks trailing objects against the first ego predicted path and leading objects against all sampled ego predicted paths; it distinguishes moving trailing objects.
- `is_colliding` iterates object predicted paths and object pose polygons, selects prepare-phase RSS parameters before prepare duration and parked/execution/abort parameters afterward, calls collision checking with yaw threshold/max safety velocity, and only reports collision when collided polygons fall in current or target lane polygons.

**Interpretation**

This is an implementation-grounded predicted-path collision-checking feature that combines ego predicted paths, object predicted paths, object polygons, lane polygons, yaw thresholds, velocity limits, and phase-specific RSS-style margins.

**Patent-searchable feature terms**

- Lane-change collision check using ego predicted paths and object predicted polygons.
- Phase-dependent RSS safety parameters for prepare, execution, parked, cancel/abort, and stuck cases.
- Collision relevance constrained to current-lane and target-lane polygons.
- Trailing-object and leading-object differentiated safety logic.

### Feature 5: Approval, unsafe hysteresis, cancel, abort, stop, and fallback transitions

**Implementation evidence**

- README states a valid/safe candidate path is executed after approval, approved path safety is continuously monitored, unsafe paths trigger abort attempts, and cancellation/abort/fallback outcomes are available depending on feasibility.
- `LaneChangeInterface::postProcess` evaluates approved-path safety and unsafe hysteresis while running.
- `evaluateApprovedPathWithUnsafeHysteresis` increments `unsafe_hysteresis_count_` on unsafe status, resets it on safe status, and only exposes unsafe status after the count exceeds `cancel.unsafe_hysteresis_threshold`.
- `check_transit_failure` checks conditions including manual mode near terminal, active/finished abort, ego outside current/target lanes, missed lane-change path, waiting approval near regulatory element, invalid path, near terminal, RTC force deactivation while return is possible, safe/unsafe approved path, cancel/abort enable flags, ability to return, abort path availability, and then returns `Cancel`, `Abort`, `Stop`, `Warning`, or `Normal`-related states/reasons.
- `calcAbortPath` generates an abort path using current velocity, selected lane-change path, current lanes, distance buffers, nearest thresholds, path shifting, and abort-related timing/jerk constraints.
- `generateOutput` outputs abort path if in abort state, inserts stop points when needed, extends drivable area, and updates turn-signal information.

**Interpretation**

The module implements a lane-change maneuver state machine with human/cooperation approval and safety fallback. It explicitly separates cancellation during prepare phase from abort during lane-changing phase and has a stop/fallback path when unsafe conditions cannot be resolved by cancel/abort.

**Patent-searchable feature terms**

- Lane-change approval with continuous approved-path safety monitoring.
- Unsafe hysteresis for lane-change abort/cancel decision stabilization.
- Abort path generation returning to current lane using path shifting and lateral jerk constraints.
- RTC force deactivation and return-to-current-lane cancellation.
- Stop fallback when unsafe trailing object and terminal conditions are present.

### Feature 6: Stopped-vehicle buffer, delay lane change, terminal stop, and blocking-object margins

**Implementation evidence**

- README and parameters define delay lane-change behavior, stopped-vehicle buffer behavior, terminal path behavior, and object-aware stop cases.
- `insert_stop_point_on_current_lanes` computes terminal stop distance from terminal start, stopping distance, last-fit-width distance, distance to target-lane start, minimum distance to current-lane object, RSS distance, lane-changing minimum length, backward buffer for blocking objects, and base-link-to-front offset. It sets stop poses either at terminal, at target-lane start, or behind a front object depending on blocking-target-object checks.
- `is_ego_stuck` uses stop velocity/time, current-lane stopped objects, lane-changing maximum length, RSS distance, base-link-front, and a detection-distance margin to determine stuck/blocking status.

**Interpretation**

The module includes object-aware stop and delay behavior for cases where a lane change cannot be safely completed or where stopped/blocking vehicles influence target/current lane feasibility.

**Patent-searchable feature terms**

- Lane-change stop-position insertion behind blocking object using RSS distance and lane-change length margin.
- Delayed lane-change decision for stopped/parked target-lane vehicle.
- Terminal lane-change stop-point selection using last-fit-width and terminal boundary constraints.
- Ego stuck detection due to stopped current-lane object before lane change.

## State transitions and behavior logic

### Direct implementation evidence

State names are represented by `lane_change::States` / `LaneChangeStates`; observed transition outputs and reasons include:

- `Normal`
- `Cancel`
- `Abort`
- `Stop`
- `Warning`
- Reasons from `check_transit_failure` include `ManualModeNearTerminal`, `Aborted`, `Aborting`, `EgoOutOfLanes`, `MissedLaneChangePath`, `CloseToRegElement`, `WaitingForApproval`, `InvalidPath`, `TooNearTerminal`, `ForceDeactivation`, `SafeToLaneChange`, `CancelDisabled`, `SafeToCancel`, `AbortDisabled`, `TooLateToAbort`, `AbortPathNotFound`, and `SafeToAbort`.
- RTC display states include waiting/executing/aborting statuses in `LaneChangeInterface::plan` and `planWaitingApproval`.

### Interpretation

Patent-searchable state-machine logic centers on transitioning from an approved lane-change path to cancel, abort, warning, or stop depending on safety, phase, return feasibility, and RTC/manual-mode constraints.

## Parameters and thresholds

### Direct implementation evidence from `lane_change.param.yaml` and `manager.cpp`

Key parameter groups and default values include:

- General/time/path:
  - `time_limit: 50.0 ms`
  - `backward_lane_length: 200.0 m`
  - `backward_length_buffer_for_end_of_lane: 3.0 m`
  - `backward_length_buffer_for_blocking_object: 3.0 m`
  - `backward_length_from_intersection: 5.0 m`
  - `enable_stopped_vehicle_buffer: true`
  - `min_length_for_turn_signal_activation: 10.0 m`
- Terminal path:
  - `terminal_path.enable: true`
  - `terminal_path.disable_near_goal: true`
  - `terminal_path.stop_at_boundary: false`
- Trajectory generation:
  - `max_prepare_duration: 4.0 s`
  - `min_prepare_duration: 2.0 s`
  - `lateral_jerk: 0.5 m/s^3`
  - `min_longitudinal_acc: -1.0 m/s^2`
  - `max_longitudinal_acc: 1.0 m/s^2`
  - `th_prepare_length_diff: 1.0 m`
  - `th_lane_changing_length_diff: 1.0 m`
  - `min_lane_changing_velocity: 2.78 m/s`
  - `lon_acc_sampling_num: 5`
  - `lat_acc_sampling_num: 3`
  - `lane_changing_decel_factor: 0.5`
  - `th_prepare_curvature: 0.03`
- Frenet near terminal:
  - `frenet.enable: true`
  - `frenet.use_entire_remaining_distance: false`
  - `frenet.th_yaw_diff: 10 deg`
  - `frenet.th_curvature_smoothing: 0.1`
  - `frenet.th_average_curvature: 0.015`
- Safety check:
  - `allow_loose_check_for_cancel: true`
  - `enable_target_lane_bound_check: true`
  - `stopped_object_velocity_threshold: 1.0 m/s`
  - RSS-style groups for `prepare`, `execution`, `parked`, `cancel`, and `stuck`, each with front/rear deceleration, rear reaction time, rear safety time margin, lateral distance threshold, longitudinal minimum distance, longitudinal velocity delta time, and polygon policy.
- Object filtering:
  - lane expansion offsets: `left_offset: 1.0 m`, `right_offset: 1.0 m`
  - target object flags: car/truck/bus/trailer/bicycle/motorcycle/pedestrian true; unknown false.
- Regulations/stuck/collision:
  - regulation checks for crosswalk/intersection/traffic light true.
  - stuck detection: `velocity: 0.5 m/s`, `stop_time: 3.0 s`.
  - collision check: `prediction_time_resolution: 0.5 s`, `th_incoming_object_yaw: 2.3562 rad`, `yaw_diff_threshold: 3.1416 rad`, `check_current_lanes: false`, `check_other_lanes: false`, `use_all_predicted_paths: false`.
- Cancel/abort:
  - `enable_on_prepare_phase: true`
  - `enable_on_lane_changing_phase: true`
  - `delta_time: 1.0 s`
  - `duration: 5.0 s`
  - `max_lateral_jerk: 100.0 m/s^3`
  - `overhang_tolerance: 0.0 m`
  - `unsafe_hysteresis_threshold: 5`
  - `deceleration_sampling_num: 5`
- Finish/path-miss:
  - `lane_change_finish_judge_buffer: 2.0 m`
  - `finish_judge_lateral_threshold: 0.1 m`
  - `finish_judge_lateral_angle_deviation: 1.0 deg`
  - `path_miss.enable_path_miss_detection: false`
  - `path_miss.threshold_longitudinal: 1.0 m`
  - velocity-scaled lateral thresholds from `3.0 m`/`5.0 m`/`1.5 m`/`0.8 m` over velocity points `0.0` to `20.0 m/s`.

### Interpretation

The parameters encode patent-searchable maneuver constraints: acceleration, jerk, duration, sampled acceleration counts, collision-prediction resolution, yaw thresholds, reaction time, safety margins, object-class selection, lane expansion, and stop/terminal margins.

## English patent search keywords derived from evidence

- `autonomous vehicle lane change behavior planning lanelet route target lane`
- `automated driving lane change candidate path sampling prepare phase lateral acceleration longitudinal acceleration`
- `self driving vehicle lane change path shifter frenet terminal lane change`
- `autonomous vehicle lane change predicted object filtering target lane leading trailing stopped object`
- `lane change collision check ego predicted path object predicted path polygon RSS safety distance`
- `automated lane change approved path safety monitoring unsafe hysteresis abort cancel`
- `autonomous driving lane change abort path return to current lane lateral jerk`
- `lane change stop point insertion blocking object RSS distance terminal boundary`
- `lane change regulatory element crosswalk intersection traffic light suppression`
- `RTC approval force deactivation lane change cancellation autonomous vehicle`

## Japanese patent search keywords derived from evidence

- `自動運転 車線変更 行動計画 レーンレット 経路 目標車線`
- `自律走行 車線変更 候補経路 サンプリング 準備区間 横加速度 縦加速度`
- `車線変更 パスシフタ フレネ 終端 車線変更経路`
- `自動運転 車線変更 予測物体 フィルタリング 先行車 後続車 停止物体`
- `車線変更 衝突判定 自車予測経路 物体予測経路 ポリゴン RSS 安全距離`
- `承認済み 車線変更 経路 安全監視 ヒステリシス 中止 キャンセル アボート`
- `自律走行 車線変更 アボート 現在車線 復帰 横ジャーク`
- `車線変更 停止位置 挿入 障害物 安全マージン 終端境界`
- `車線変更 規制要素 横断歩道 交差点 信号機 抑制`
- `自動運転 協調インタフェース 承認 強制解除 車線変更キャンセル`

## Synonyms and CPC/IPC hints

### Synonyms

- Lane change: lane transition, lane-change maneuver, lateral maneuver, merge into target lane, target-lane shift, 車線変更, レーンチェンジ, 車線移行.
- Candidate path: candidate trajectory, sampled path, shifted path, Frenet path, target path, 候補経路, 候補軌道, サンプリング軌道.
- Safety check: collision check, predicted collision, RSS distance, safe braking distance, safety margin, 衝突判定, 衝突リ��ク, 安全距離, 安全マージン.
- Abort/cancel: abort maneuver, cancel maneuver, return-to-lane, fallback, stop fallback, アボート, 中止, キャンセル, 復帰, 退避, フォールバック.
- Predicted object: surrounding vehicle, target-lane leading vehicle, target-lane trailing vehicle, stopped object, predicted path, 周辺車両, 先行車, 後続車, 停止車両, 予測軌跡.

### CPC/IPC hints

Use only as search aids:

- `B60W 30/00`: autonomous/assisted driving purposes including lane change, collision avoidance, and speed/path behavior.
- `B60W 40/00`: estimation/calculation of vehicle driving parameters and surrounding conditions.
- `B60W 50/00`: safety, arbitration, diagnostics, fallback, and control system details.
- `G05D 1/00`: control of position/course/path of vehicles.
- `B62D 15/00`: steering control/path tracking overlaps.
- `G08G 1/00`: traffic/road infrastructure interaction; useful for regulatory-element and traffic-light/intersection-aware searches.

## BigQuery SQL generated

- SQL file: `.agents/skills/autoware-patent-search/examples/lane_change_bigquery_from_snapshot.sql`.
- Data source: Google Patents Public Data BigQuery table `patents-public-data.patents.publications`.
- Execution status: not executed in this environment; BigQuery live execution was intentionally not performed.
- Intended validation: human reviewer with Google Cloud/BigQuery access should run a dry run or a small `LIMIT 10` query before relying on retrieval results.

## Remaining uncertainties and limitations

- This extraction is based on the snapshot package only. The parent behavior path planner integration determines actual runtime node composition, topic names, and launch wiring, which are not fully contained in this snapshot.
- Tests and README were used as corroborating evidence, but candidate patent retrieval was not executed and no candidate patent documents are reported here.
- CPC/IPC hints are not definitive classifications; they are search aids.
- No legal conclusions are made. All generated features, terms, and SQL are candidates for human IP-professional review.
