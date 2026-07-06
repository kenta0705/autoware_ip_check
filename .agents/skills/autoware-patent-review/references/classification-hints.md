# Patent Classification Hints for Autonomous Driving Reviews

Use these as search aids only. Do not present classifications as definitive unless verified in a patent database.

## Common CPC / IPC Areas

- **B60W**: Conjoint vehicle sub-unit control; road vehicle drive control; autonomous or assisted driving control.
- **B60W 30/00**: Purposes of road vehicle drive control, including collision avoidance, lane keeping, speed control, and path following.
- **B60W 40/00**: Estimation or calculation of vehicle driving parameters, surrounding conditions, or driver/vehicle state.
- **B60W 50/00**: Details of control systems, safety, diagnostics, fault handling, and arbitration.
- **G05D 1/00**: Control of position, course, altitude, or attitude of land/water/air vehicles; often relevant to autonomous navigation and path tracking.
- **G08G 1/00**: Traffic control systems; vehicle-to-infrastructure, signal interaction, traffic flow, and route guidance.
- **G06V / G06T**: Image processing or computer vision when perception outputs are central to the changed driving decision.
- **G06N**: Machine learning / neural-network methods when the changed feature materially uses learned models for driving behavior.
- **B62D 15/00**: Steering control; lane keeping and path tracking may overlap.

## Japanese FI / F-term Search Pointers

Use J-PlatPat to refine actual FI/F-term codes. Initial Japanese keyword combinations often work better than guessing exact F-terms.

Potential Japanese query concepts:

- 自動運転 AND 経路計画 / 軌道計画 / 走行計画
- 自律走行 AND 障害物回避 / 衝突回避 / 衝突リスク
- 車両制御 AND フェールセーフ / 縮退運転 / 退避制御
- 最小リスク状態 OR ミニマムリスクマヌーバ OR MRM
- 車線変更 AND 周辺車両 / 予測軌跡 / 安全確認
- 交差点 AND 信号機 / 歩行者 / 優先判定
- 地図情報 AND レーン / 車線 / 走行可能領域

## Mapping by Feature Type

- Behavior or motion planning: start with B60W 30/00, G05D 1/00, and Japanese terms 行動計画, 動作計画, 軌道生成.
- Trajectory optimization or path tracking: start with G05D 1/00, B60W 30/00, B62D 15/00, and terms 軌道追従, 目標軌道, 最適化.
- Fallback/MRM/fault handling: start with B60W 50/00 and terms フェールセーフ, 異常検知, 退避, 最小リスク状態.
- Traffic signal/infrastructure interaction: start with G08G 1/00 and terms 信号機, 路側機, インフラ協調, V2X.
- Perception-to-planning interaction: combine B60W/G05D with G06V when the perception representation is part of the claimed-style method.
