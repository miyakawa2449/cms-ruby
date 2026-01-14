---
description: コード品質の自動チェック
---

コード品質をチェックしてください：

1. 直近で変更されたファイルをスキャン（`git diff --name-only HEAD~1` または `git status`）
2. 以下のCoding Standardsへの違反をチェック：

## Coding Standards

### General
- **DRY原則**: 同じロジックを2回書かない
- **KISS原則**: 複雑な実装より、単純で読みやすい実装を優先

### Constraints (Strict)
| 項目 | 制約 | 超過時の対応 |
|------|------|--------------|
| メソッド行数 | 最大20行 | プライベートメソッドに切り出し |
| クラス行数 | 最大100行 | 責務分割（Concern/Service） |

### 命名規則
- 変数名: スネークケース（`user_id`）
- クラス名: キャメルケース（`UserManager`）
- 禁止: 意味のない名前（`temp`, `data`, `a`）

3. 違反がある場合、具体的な修正案を提示
