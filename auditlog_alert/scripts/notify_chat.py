"""
Teams / Google Chat への通知（Custom Script: py> オペレーターから実行）

- 外部ライブラリは使わず、Python 標準ライブラリだけで送信します
- Webhook URL は Workflow の Secret から環境変数で受け取ります
    TEAMS_WEBHOOK_URL       ← ${secret:teams.webhook_url}
    GOOGLE_CHAT_WEBHOOK_URL ← ${secret:google_chat.webhook_url}
- 送信に失敗した場合は例外を投げ、ワークフローのタスクを失敗させます

引数（sub_notify.dig から渡されます）
    title        : 件名（例: [緊急] 【緊急】情報漏洩チェック 3件 - Sample Inc.）
    message      : 本文テキスト（build_message.sql の text_body）
    header_color : 重要度の色（例: #D93025）
    console_url  : TD コンソールの URL
"""

import json
import os
import urllib.error
import urllib.request


def post_teams(title, message, header_color, console_url):
    """Microsoft Teams（Workflows の Incoming Webhook）に Adaptive Card を送信する"""
    webhook_url = _get_env("TEAMS_WEBHOOK_URL")

    # Adaptive Card の色は名前で指定する（緊急/高 → attention、それ以外 → accent）
    title_color = "attention" if header_color in ("#D93025", "#E8710A") else "accent"

    payload = {
        "type": "message",
        "attachments": [
            {
                "contentType": "application/vnd.microsoft.card.adaptive",
                "contentUrl": None,
                "content": {
                    "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                    "type": "AdaptiveCard",
                    "version": "1.4",
                    "msteams": {"width": "Full"},
                    "body": [
                        {
                            "type": "TextBlock",
                            "text": title,
                            "weight": "Bolder",
                            "size": "Medium",
                            "color": title_color,
                            "wrap": True,
                        },
                        {
                            "type": "TextBlock",
                            # Teams の TextBlock は改行2つで段落になるため、行ごとに改行を2つにする
                            "text": message.replace("\n", "\n\n"),
                            "wrap": True,
                        },
                    ],
                    "actions": [
                        {
                            "type": "Action.OpenUrl",
                            "title": "コンソールを開く",
                            "url": console_url,
                        }
                    ],
                },
            }
        ],
    }
    _post_json(webhook_url, payload, "Teams")


def post_google_chat(title, message, header_color, console_url):
    """Google Chat（スペースの Incoming Webhook）にカードを送信する"""
    webhook_url = _get_env("GOOGLE_CHAT_WEBHOOK_URL")

    payload = {
        # 通知（スマホのプッシュ等）に表示されるテキスト
        "text": title,
        "cardsV2": [
            {
                "cardId": "auditlog_alert",
                "card": {
                    "header": {
                        "title": title,
                        "subtitle": "Treasure AI Audit Log Monitor",
                    },
                    "sections": [
                        {
                            "widgets": [
                                {
                                    "textParagraph": {
                                        # Google Chat のカードは <br> で改行する
                                        "text": _escape_html(message).replace("\n", "<br>")
                                    }
                                },
                                {
                                    "buttonList": {
                                        "buttons": [
                                            {
                                                "text": "コンソールを開く",
                                                "onClick": {"openLink": {"url": console_url}},
                                            }
                                        ]
                                    }
                                },
                            ]
                        }
                    ],
                },
            }
        ],
    }
    _post_json(webhook_url, payload, "Google Chat")


# ---------------------------------------------------------------------
# 共通処理
# ---------------------------------------------------------------------

def _get_env(name):
    value = os.environ.get(name, "")
    if not value:
        raise RuntimeError(
            f"環境変数 {name} が設定されていません。Workflow の Secret を登録してください。"
        )
    return value


def _escape_html(text):
    return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def _post_json(url, payload, channel_name):
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=body,
        headers={"Content-Type": "application/json; charset=UTF-8"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            print(f"[{channel_name}] 送信成功: HTTP {response.status}")
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", errors="replace")[:500]
        raise RuntimeError(f"[{channel_name}] 送信失敗: HTTP {e.code} {detail}") from e
