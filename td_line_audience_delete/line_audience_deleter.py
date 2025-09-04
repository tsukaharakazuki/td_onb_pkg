#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LINE Messaging API Audience削除ワークフロー
Treasure Data カスタムスクリプト用

このスクリプトは以下の機能を提供します：
1. 指定したAudienceGroupの削除
2. 削除ステータスの確認
3. エラーハンドリングとログ出力
"""

import os
import sys
import json
import time
import logging
from datetime import datetime
from typing import Optional, Dict, List, Any

import requests
import pytd

# ログ設定
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class LINEAudienceDeleter:
    """LINE Messaging API Audience削除クラス"""
    
    def __init__(self, channel_access_token: str):
        """
        初期化
        
        Args:
            channel_access_token: LINEのChannel Access Token
        """
        self.channel_access_token = channel_access_token
        self.base_url = "https://api.line.me/v2/bot"
        self.headers = {
            "Authorization": f"Bearer {channel_access_token}",
            "Content-Type": "application/json"
        }
    
    def get_audience_groups(self, fetch_all: bool = True) -> List[Dict[str, Any]]:
        """
        すべてのAudienceGroupを取得（ページネーション対応）
        
        Args:
            fetch_all: すべてのページを取得するか（True）、最初のページのみか（False）
            
        Returns:
            AudienceGroupのリスト
        """
        try:
            all_audience_groups = []
            page = 1
            size = 40  # 1ページあたりの取得数（最大40）
            has_next_page = True
            
            while has_next_page:
                # ページネーションパラメータを含むURL
                url = f"{self.base_url}/audienceGroup/list"
                params = {
                    'page': page,
                    'size': size
                }
                
                response = requests.get(url, headers=self.headers, params=params)
                response.raise_for_status()
                
                data = response.json()
                audience_groups = data.get('audienceGroups', [])
                all_audience_groups.extend(audience_groups)
                
                logger.info(f"ページ{page}: {len(audience_groups)}件取得")
                
                # 次のページがあるか確認
                has_next_page = data.get('hasNextPage', False) if fetch_all else False
                page += 1
                
                # APIレート制限対策
                if has_next_page:
                    time.sleep(0.5)
            
            logger.info(f"取得したAudienceGroup総数: {len(all_audience_groups)}")
            return all_audience_groups
            
        except requests.exceptions.RequestException as e:
            logger.error(f"AudienceGroup一覧取得エラー: {e}")
            raise
    
    def delete_audience_group(self, audience_group_id: str) -> bool:
        """
        指定したAudienceGroupを削除
        
        Args:
            audience_group_id: 削除するAudienceGroupのID
            
        Returns:
            削除成功時True、失敗時False
        """
        try:
            url = f"{self.base_url}/audienceGroup/{audience_group_id}"
            response = requests.delete(url, headers=self.headers)
            
            if response.status_code in [200, 202, 204]:
                logger.info(f"AudienceGroup削除成功: {audience_group_id} (ステータス: {response.status_code})")
                return True
            elif response.status_code == 404:
                logger.warning(f"AudienceGroupが見つかりません: {audience_group_id}")
                return False
            else:
                logger.error(f"削除エラー (ステータスコード: {response.status_code}): {response.text}")
                return False
                
        except requests.exceptions.RequestException as e:
            logger.error(f"AudienceGroup削除エラー: {e}")
            return False
    
    def delete_audience(self, audience_id: str) -> bool:
        """
        指定したAudience（個別オーディエンス）を削除
        
        Args:
            audience_id: 削除するAudienceのID
            
        Returns:
            削除成功時True、失敗時False
        """
        try:
            # audience_idを文字列として扱う
            audience_id = str(audience_id).strip()
            url = f"{self.base_url}/audienceGroup/{audience_id}"
            logger.info(f"削除リクエスト送信: {url}")
            response = requests.delete(url, headers=self.headers)
            
            if response.status_code in [200, 202, 204]:
                logger.info(f"Audience削除成功: {audience_id} (ステータス: {response.status_code})")
                return True
            elif response.status_code == 404:
                logger.warning(f"Audienceが見つかりません: {audience_id}")
                return False
            else:
                logger.error(f"削除エラー (ステータスコード: {response.status_code}): {response.text}")
                return False
                
        except requests.exceptions.RequestException as e:
            logger.error(f"Audience削除エラー: {e}")
            return False
    
    def get_audience_group_status(self, audience_group_id: str) -> Optional[Dict[str, Any]]:
        """
        AudienceGroupのステータスを取得
        
        Args:
            audience_group_id: AudienceGroupのID
            
        Returns:
            ステータス情報、見つからない場合はNone
        """
        try:
            url = f"{self.base_url}/audienceGroup/{audience_group_id}"
            response = requests.get(url, headers=self.headers)
            
            if response.status_code == 200:
                return response.json()
            elif response.status_code == 404:
                return None
            else:
                response.raise_for_status()
                
        except requests.exceptions.RequestException as e:
            logger.error(f"AudienceGroupステータス取得エラー: {e}")
            return None
    
    def get_audience_status(self, audience_id: str) -> Optional[Dict[str, Any]]:
        """
        Audienceのステータスを取得
        
        Args:
            audience_id: AudienceのID
            
        Returns:
            ステータス情報、見つからない場合はNone
        """
        try:
            # audience_idを文字列として扱う
            audience_id = str(audience_id).strip()
            url = f"{self.base_url}/audienceGroup/{audience_id}"
            response = requests.get(url, headers=self.headers)
            
            if response.status_code == 200:
                return response.json()
            elif response.status_code == 404:
                return None
            else:
                response.raise_for_status()
                
        except requests.exceptions.RequestException as e:
            logger.error(f"Audienceステータス取得エラー: {e}")
            return None
    
    def delete_multiple_audiences(self, audience_ids: List[str], 
                                audience_type: str = "audience",
                                confirm_deletion: bool = True) -> Dict[str, Any]:
        """
        複数のAudienceまたはAudienceGroupを一括削除
        
        Args:
            audience_ids: 削除するAudienceのIDリスト
            audience_type: "audience" または "audienceGroup"
            confirm_deletion: 削除前に確認するかどうか
            
        Returns:
            削除結果の詳細
        """
        results = {
            "total": len(audience_ids),
            "success": [],
            "failed": [],
            "not_found": [],
            "type": audience_type
        }
        
        logger.info(f"削除対象{audience_type}数: {len(audience_ids)}")
        
        for audience_id in audience_ids:
            # 削除前にステータス確認
            if confirm_deletion:
                if audience_type == "audience":
                    status = self.get_audience_status(audience_id)
                else:
                    status = self.get_audience_group_status(audience_id)
                    
                if status is None:
                    logger.warning(f"削除対象が見つかりません: {audience_id}")
                    results["not_found"].append(audience_id)
                    continue
                
                logger.info(f"削除対象: {audience_id} - {status.get('description', status.get('audienceGroupId', 'N/A'))}")
            
            # 削除実行
            if audience_type == "audience":
                success = self.delete_audience(audience_id)
            else:
                success = self.delete_audience_group(audience_id)
                
            if success:
                results["success"].append(audience_id)
                
                # 削除確認のため少し待機
                time.sleep(1)
                
                # 削除確認
                if audience_type == "audience":
                    check_result = self.get_audience_status(audience_id)
                else:
                    check_result = self.get_audience_group_status(audience_id)
                    
                if check_result is None:
                    logger.info(f"削除確認完了: {audience_id}")
                else:
                    logger.warning(f"削除確認できませんでした: {audience_id}")
            else:
                results["failed"].append(audience_id)
            
            # API制限を考慮した待機
            time.sleep(0.5)
        
        return results


class TreasureDataIntegration:
    """Treasure Dataとの連携クラス"""
    
    def __init__(self, td_client):
        self.td_client = td_client
    
    def log_deletion_results(self, results: Dict[str, Any], database: str, table: str):
        """
        削除結果をTreasure Dataに記録
        
        Args:
            results: 削除結果
            database: データベース名
            table: テーブル名
        """
        try:
            # 結果をレコード形式に変換
            records = []
            timestamp = int(time.time())
            
            # 成功したレコード
            for audience_id in results["success"]:
                records.append({
                    "time": timestamp,
                    "audience_id": audience_id,
                    "type": results.get("type", "unknown"),
                    "status": "success",
                    "message": "削除成功"
                })
            
            # 失敗したレコード
            for audience_id in results["failed"]:
                records.append({
                    "time": timestamp,
                    "audience_id": audience_id,
                    "type": results.get("type", "unknown"),
                    "status": "failed",
                    "message": "削除失敗"
                })
            
            # 見つからなかったレコード
            for audience_id in results["not_found"]:
                records.append({
                    "time": timestamp,
                    "audience_id": audience_id,
                    "type": results.get("type", "unknown"),
                    "status": "not_found",
                    "message": "対象が見つかりません"
                })
            
            # Treasure Dataに挿入（load_table_from_dataframeを使用）
            if records:
                import pandas as pd
                df = pd.DataFrame(records)
                self.td_client.load_table_from_dataframe(df, f"{database}.{table}", if_exists='append')
                logger.info(f"削除結果をTreasure Dataに記録: {len(records)}件")
        
        except Exception as e:
            logger.error(f"Treasure Data記録エラー: {e}")


def main():
    """メイン処理"""
    try:
        # 環境変数から設定を読み込み
        channel_access_token = os.getenv('LINE_CHANNEL_ACCESS_TOKEN')
        if not channel_access_token:
            raise ValueError("LINE_CHANNEL_ACCESS_TOKEN環境変数が設定されていません")
        
        # Treasure Data設定
        td_endpoint = os.getenv('TD_ENDPOINT')
        td_api_key = os.getenv('TD_API_KEY')
        
        # 削除対象のAudience IDを取得（環境変数から）
        audience_ids_str = os.getenv('AUDIENCE_IDS', '')
        
        # 削除タイプを指定（audience または audienceGroup）
        deletion_type = os.getenv('DELETION_TYPE', 'audienceGroup')  # デフォルトはaudienceGroup
        
        if not audience_ids_str:
            logger.error("削除対象のAUDIENCE_IDSが指定されていません")
            return
        
        # カンマ区切りまたは単一のIDをリストに変換
        audience_ids_str = str(audience_ids_str).strip()
        if ',' in audience_ids_str:
            audience_ids = [str(id).strip() for id in audience_ids_str.split(',')]
        else:
            audience_ids = [audience_ids_str]
        
        logger.info(f"処理対象ID: {audience_ids}")
        logger.info(f"削除タイプ: {deletion_type}")
        
        # LINE Audience削除実行
        deleter = LINEAudienceDeleter(channel_access_token)
        
        # 削除前に現在のAudienceGroup一覧を表示
        logger.info("=== 削除前のAudienceGroup一覧 ===")
        current_groups = deleter.get_audience_groups()
        for group in current_groups:
            logger.info(f"ID: {group.get('audienceGroupId')}, "
                       f"名前: {group.get('description', 'N/A')}, "
                       f"ステータス: {group.get('status', 'N/A')}")
        
        # 削除実行
        logger.info(f"=== {deletion_type}削除開始 ===")
        results = deleter.delete_multiple_audiences(
            audience_ids, 
            audience_type=deletion_type,
            confirm_deletion=True
        )
        
        # 結果表示
        logger.info("=== 削除結果 ===")
        logger.info(f"対象数: {results['total']}")
        logger.info(f"成功: {len(results['success'])}件")
        logger.info(f"失敗: {len(results['failed'])}件")
        logger.info(f"見つからない: {len(results['not_found'])}件")
        
        if results['success']:
            logger.info(f"削除成功ID: {', '.join(results['success'])}")
        if results['failed']:
            logger.error(f"削除失敗ID: {', '.join(results['failed'])}")
        if results['not_found']:
            logger.warning(f"見つからないID: {', '.join(results['not_found'])}")
        
        # Treasure Dataに結果を記録（設定されている場合）
        if td_endpoint and td_api_key:
            try:
                td_client = pytd.Client(endpoint=td_endpoint, apikey=td_api_key, database='td_sandbox')
                td_integration = TreasureDataIntegration(td_client)
                
                log_database = os.getenv('TD_LOG_DATABASE', 'td_sandbox')
                log_table = os.getenv('TD_LOG_TABLE', 'line_audience_deletion_log')
                
                td_integration.log_deletion_results(results, log_database, log_table)
            except Exception as e:
                logger.warning(f"Treasure Dataへのログ記録はスキップされました: {e}")
        
        # 削除後のAudienceGroup一覧を表示
        logger.info("=== 削除後のAudienceGroup一覧 ===")
        final_groups = deleter.get_audience_groups()
        for group in final_groups:
            logger.info(f"ID: {group.get('audienceGroupId')}, "
                       f"名前: {group.get('description', 'N/A')}, "
                       f"ステータス: {group.get('status', 'N/A')}")
        
        logger.info("Audience削除ワークフロー完了")
        
    except Exception as e:
        logger.error(f"ワークフロー実行エラー: {e}")
        raise


if __name__ == "__main__":
    main()