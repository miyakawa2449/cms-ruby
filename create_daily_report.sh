#!/bin/bash

# 日々の作業記録生成スクリプト
# 使用方法: ./create_daily_report.sh [報告書タイトル]

# 現在の日時を取得
current_date=$(date +"%Y-%m-%d")
current_time=$(date +"%H:%M:%S")
current_datetime=$(date +"%Y-%m-%d %H:%M:%S")

# 日付フォルダのパス
reports_dir="reports/${current_date}"

# 日付フォルダが存在しない場合は作成
if [ ! -d "$reports_dir" ]; then
    mkdir -p "$reports_dir"
    echo "📁 作成: $reports_dir"
fi

# 既存のファイル数をカウントして次の番号を決定
file_count=$(ls -1 "$reports_dir"/*.md 2>/dev/null | wc -l | tr -d ' ')
next_number=$((file_count + 1))

# ファイル名を生成
if [ $next_number -eq 1 ]; then
    suffix="1st"
elif [ $next_number -eq 2 ]; then
    suffix="2nd"
elif [ $next_number -eq 3 ]; then
    suffix="3rd"
else
    suffix="${next_number}th"
fi

filename="${reports_dir}/${suffix}.md"

# 最新のgit情報を取得
latest_commit=$(git log -1 --format="%H")
latest_commit_short=$(git log -1 --format="%h")
latest_commit_date=$(git log -1 --format="%ci")
latest_commit_message=$(git log -1 --format="%s")
latest_commit_author=$(git log -1 --format="%an")

# ブランチ情報
current_branch=$(git branch --show-current)

# 変更ファイル情報
changed_files=$(git diff --name-only HEAD~1 HEAD | head -10)

# 報告書タイトル（引数から取得、なければデフォルト）
if [ $# -eq 0 ]; then
    report_title="作業報告 ${suffix}"
else
    report_title="$1"
fi

# 報告書内容を生成
cat > "$filename" << EOF
# ${report_title}

## 📅 基本情報
- **作業日**: ${current_date}
- **報告作成時刻**: ${current_time}
- **報告書番号**: ${suffix}

## 🔧 Git情報
- **ブランチ**: \`${current_branch}\`
- **最新コミット**: \`${latest_commit_short}\`
- **コミットID（フル）**: \`${latest_commit}\`
- **コミット日時**: ${latest_commit_date}
- **コミットメッセージ**: "${latest_commit_message}"
- **コミット作成者**: ${latest_commit_author}

## 📝 変更ファイル一覧
\`\`\`
${changed_files}
\`\`\`

## 🎯 今回の作業内容

### 完了したタスク
- [ ] タスク1
- [ ] タスク2

### 実装・修正内容
- 

### 課題・問題点
- 

### 次回への申し送り
- 

## 📊 プロジェクト状況
- **現在のフェーズ**: 
- **進捗状況**: 

## 💭 所感・学び
- 

---

*この報告書は ${current_datetime} に自動生成されました*
EOF

echo "✅ 作業報告書を作成しました: $filename"
echo "📝 内容を編集してください"

# ファイルをエディタで開く（オプション）
if command -v code >/dev/null 2>&1; then
    echo "🔧 VS Codeで開いています..."
    code "$filename"
elif command -v open >/dev/null 2>&1; then
    echo "📂 ファイルを開いています..."
    open "$filename"
fi

echo ""
echo "📁 今日の報告書一覧:"
ls -la "$reports_dir"