#!/bin/bash
# =============================================================================
# notify-with-task.sh
# Task completion / input waiting notification script
# タスク完了・入力待ち通知スクリプト
#
# Extracts issue number from git branch name and speaks via VOICEVOX.
# git ブランチ名から課題番号を抽出し、VOICEVOX で読み上げます。
#
# Usage / 使い方:
#   notify-with-task.sh <event_type> [speaker] [delay_ms] [speed_num] [speed_msg] [int_num] [int_msg]
#
# Arguments / 引数:
#   event_type  - "completed" or "waiting" / "completed" または "waiting"
#   speaker     - VOICEVOX speaker ID (default: 2) / スピーカー ID (デフォルト: 2)
#   delay_ms    - Delay before speech in ms (default: 3000) / 発話前待機時間 (デフォルト: 3000)
#   speed_num   - Speed for number part (default: 0.85) / 数字部分の速度 (デフォルト: 0.85)
#   speed_msg   - Speed for message part (default: 1.0) / メッセージ部分の速度 (デフォルト: 1.0)
#   int_num     - Intonation for number part (default: 1.2) / 数字部分の抑揚 (デフォルト: 1.2)
#   int_msg     - Intonation for message part (default: 1.0) / メッセージ部分の抑揚 (デフォルト: 1.0)
#
# Environment Variables / 環境変数:
#   NOTIFY_LANG - Language for messages: "ja" (default) or "en"
#                 メッセージの言語: "ja" (デフォルト) または "en"
# =============================================================================

EVENT_TYPE="$1"  # "completed" or "waiting"
SPEAKER="${2:-2}"
DELAY="${3:-3000}"
SPEED_NUM="${4:-0.85}"   # Speed for number part / 数字部分の速度
SPEED_MSG="${5:-1.0}"    # Speed for message part / メッセージ部分の速度
INT_NUM="${6:-1.2}"      # Intonation for number part / 数字部分の抑揚
INT_MSG="${7:-1.0}"      # Intonation for message part / メッセージ部分の抑揚

# Language setting (ja or en) / 言語設定 (ja または en)
LANG_SETTING="${NOTIFY_LANG:-ja}"

# -----------------------------------------------------------------------------
# Convert digits to hiragana for natural Japanese speech
# 数字をひらがなに変換（自然な日本語読み上げのため）
# -----------------------------------------------------------------------------
digits_to_hiragana() {
    echo "$1" | sed 's/0/ぜろ/g; s/1/いち/g; s/2/にぃ/g; s/3/さん/g; s/4/よん/g; s/5/ご/g; s/6/ろく/g; s/7/なな/g; s/8/はち/g; s/9/きゅう/g'
}

# -----------------------------------------------------------------------------
# Convert digits to English words for clearer pronunciation in VOICEVOX
# 数字を英単語に変換（VOICEVOX での発音を明確にするため）
# -----------------------------------------------------------------------------
digits_to_english() {
    echo "$1" | sed 's/0/ zero /g; s/1/ one /g; s/2/ two /g; s/3/ three /g; s/4/ four /g; s/5/ five /g; s/6/ six /g; s/7/ seven /g; s/8/ eight /g; s/9/ nine /g' | sed 's/  */ /g; s/^ //; s/ $//'
}

# -----------------------------------------------------------------------------
# Get current branch name / 現在のブランチ名を取得
# -----------------------------------------------------------------------------
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# -----------------------------------------------------------------------------
# Extract issue key (e.g., PROJ-1234, KBC_PER-1234)
# 課題キーを抽出（例: PROJ-1234, KBC_PER-1234）
# Supports Backlog / GitHub Issue formats
# Backlog / GitHub Issue 形式に対応
# -----------------------------------------------------------------------------
TASK_ID=$(echo "$BRANCH" | grep -oE '[A-Z_]+-[0-9]+' | head -1)

# If no task ID found, use branch name or directory name
# タスク ID がなければブランチ名またはディレクトリ名を使用
if [ -z "$TASK_ID" ]; then
    if [ -n "$BRANCH" ] && [ "$BRANCH" != "HEAD" ]; then
        # Use branch name without prefix (issue/, feature/, etc.)
        # ブランチ名を使用（prefix issue/ feature/ 等を除去）
        TASK_ID=$(echo "$BRANCH" | sed 's|^[^/]*/||')
    else
        # Not a git repo or detached HEAD: use directory name
        # Git リポジトリでない、または detached HEAD の場合はディレクトリ名を使用
        REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
        if [ -n "$REPO_ROOT" ]; then
            TASK_ID=$(basename "$REPO_ROOT")
        else
            TASK_ID=$(basename "$(pwd)")
        fi
    fi
fi

# -----------------------------------------------------------------------------
# Extract number part if task ID matches pattern like XXX-1234
# タスク ID が XXX-1234 形式なら数字部分だけ抽出
# -----------------------------------------------------------------------------
IS_NUMBER=false
if [[ "$TASK_ID" =~ ^.+-([0-9]+)$ ]]; then
    TASK_ID="${BASH_REMATCH[1]}"
    IS_NUMBER=true
fi

# Convert pure numbers based on language setting
# 言語設定に基づいて数字を変換
if [[ "$TASK_ID" =~ ^[0-9]+$ ]]; then
    if [ "$LANG_SETTING" = "en" ]; then
        # English: convert to spoken words for clearer pronunciation
        # 英語: 発音を明確にするため単語に変換
        TASK_ID=$(digits_to_english "$TASK_ID")
    else
        # Japanese: convert to hiragana
        # 日本語: ひらがなに変換
        TASK_ID=$(digits_to_hiragana "$TASK_ID")
    fi
    IS_NUMBER=true
fi

# -----------------------------------------------------------------------------
# Build message suffix based on event type and language
# イベントタイプと言語に基づいてメッセージの末尾を構築
# -----------------------------------------------------------------------------
case "$EVENT_TYPE" in
    "completed")
        if [ "$LANG_SETTING" = "en" ]; then
            SUFFIX="has completed"
        else
            SUFFIX="が完了しました"
        fi
        ;;
    "waiting")
        if [ "$LANG_SETTING" = "en" ]; then
            SUFFIX="is waiting for input"
        else
            SUFFIX="が入力待ちです"
        fi
        ;;
    *)
        SUFFIX=""
        ;;
esac

# -----------------------------------------------------------------------------
# Call VOICEVOX via PowerShell
# PowerShell 経由で VOICEVOX を呼び出し
#
# NOTE: Update the path below to match your environment
# 注意: 以下のパスを環境に合わせて更新してください
# -----------------------------------------------------------------------------
VOICEVOX_SCRIPT="C:\\Users\\<USERNAME>\\ClaudeScripts\\voicevox-voice.ps1"

if [ "$IS_NUMBER" = true ] && [ -n "$SUFFIX" ]; then
    # Play number and message with different speed/intonation
    # 数字部分とメッセージ部分を別々の速度・抑揚で再生
    powershell.exe -File "$VOICEVOX_SCRIPT" \
        -Message "$TASK_ID" \
        -Speaker "$SPEAKER" \
        -DelayMilliseconds "$DELAY" \
        -Speed "$SPEED_NUM" \
        -Intonation "$INT_NUM" \
        -Message2 "$SUFFIX" \
        -Speed2 "$SPEED_MSG" \
        -Intonation2 "$INT_MSG"
else
    # Normal playback / 通常再生
    MESSAGE="${TASK_ID} ${SUFFIX}"
    powershell.exe -File "$VOICEVOX_SCRIPT" \
        -Message "$MESSAGE" \
        -Speaker "$SPEAKER" \
        -DelayMilliseconds "$DELAY" \
        -Speed "$SPEED_MSG" \
        -Intonation "$INT_MSG"
fi
