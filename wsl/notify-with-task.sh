#!/bin/bash
# ~/.claude/scripts/notify-with-task.sh
# タスク完了・入力待ち通知スクリプト
# ブランチ名から課題番号を抽出、なければブランチ名を使用

EVENT_TYPE="$1"  # "completed" or "waiting"
SPEAKER="${2:-2}"
DELAY="${3:-3000}"
SPEED_NUM="${4:-0.85}"   # 数字部分の速度
SPEED_MSG="${5:-1.0}"    # メッセージ部分の速度
INT_NUM="${6:-1.2}"      # 数字部分の抑揚
INT_MSG="${7:-1.0}"      # メッセージ部分の抑揚

# 数字をひらがなに変換する関数
digits_to_hiragana() {
    echo "$1" | sed 's/0/ぜろ/g; s/1/いち/g; s/2/にぃ/g; s/3/さん/g; s/4/よん/g; s/5/ご/g; s/6/ろく/g; s/7/なな/g; s/8/はち/g; s/9/きゅう/g'
}

# 現在のブランチ名を取得
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# Backlog課題キー形式（例: PUBCDEV-1234, KBC_PER-1234）を抽出
TASK_ID=$(echo "$BRANCH" | grep -oE '[A-Z_]+-[0-9]+' | head -1)

# タスクIDがなければブランチ名を使用
if [ -z "$TASK_ID" ]; then
    if [ -n "$BRANCH" ] && [ "$BRANCH" != "HEAD" ]; then
        # ブランチ名をそのまま使用（prefix部分 issue/ feature/ 等を除去）
        TASK_ID=$(echo "$BRANCH" | sed 's|^[^/]*/||')
    else
        # Gitリポジトリでない、またはdetached HEADの場合はディレクトリ名
        REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
        if [ -n "$REPO_ROOT" ]; then
            TASK_ID=$(basename "$REPO_ROOT")
        else
            TASK_ID=$(basename "$(pwd)")
        fi
    fi
fi

# TASK_IDが .+-数字 の形式なら数字部分だけ抽出
IS_NUMBER=false
if [[ "$TASK_ID" =~ ^.+-([0-9]+)$ ]]; then
    TASK_ID="${BASH_REMATCH[1]}"
    IS_NUMBER=true
fi

# 数字だけの場合はひらがなに変換
if [[ "$TASK_ID" =~ ^[0-9]+$ ]]; then
    TASK_ID=$(digits_to_hiragana "$TASK_ID")
    IS_NUMBER=true
fi

# メッセージ構築
case "$EVENT_TYPE" in
    "completed")
        SUFFIX="が完了しました"
        ;;
    "waiting")
        SUFFIX="が入力待ちです"
        ;;
    *)
        SUFFIX=""
        ;;
esac

# VOICEVOX音声通知
if [ "$IS_NUMBER" = true ] && [ -n "$SUFFIX" ]; then
    # 数字部分とメッセージ部分を別々の速度・抑揚で再生
    powershell.exe -File "C:\\Users\\yakura\\ClaudeScripts\\voicevox-voice.ps1" \
        -Message "$TASK_ID" \
        -Speaker "$SPEAKER" \
        -DelayMilliseconds "$DELAY" \
        -Speed "$SPEED_NUM" \
        -Intonation "$INT_NUM" \
        -Message2 "$SUFFIX" \
        -Speed2 "$SPEED_MSG" \
        -Intonation2 "$INT_MSG"
else
    # 通常再生
    MESSAGE="${TASK_ID} ${SUFFIX}"
    powershell.exe -File "C:\\Users\\yakura\\ClaudeScripts\\voicevox-voice.ps1" \
        -Message "$MESSAGE" \
        -Speaker "$SPEAKER" \
        -DelayMilliseconds "$DELAY" \
        -Speed "$SPEED_MSG" \
        -Intonation "$INT_MSG"
fi
