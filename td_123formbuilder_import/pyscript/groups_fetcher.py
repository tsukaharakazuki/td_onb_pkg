#!/usr/bin/env python

import os
import sys
import json
import requests
from typing import Dict, List, Any, Optional
import logging

# Treasure Data Python SDK for outputting data
try:
    import pytd
    import pandas as pd
except ImportError:
    pytd = None
    pd = None

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FormBuilderGroupsClient:
    """123FormBuilder API client for fetching groups data"""
    
    def __init__(self, username: str, password: str, base_url: str = "https://api.123formbuilder.com/v2"):
        """
        Initialize the client
        
        Args:
            username: 123FormBuilder username
            password: 123FormBuilder password
            base_url: Base URL for the API
        """
        self.base_url = base_url
        self.username = username
        self.password = password
        
        # Login and get JWT token
        self.api_token = self._login()
        
        self.headers = {
            "Authorization": f"Bearer {self.api_token}",
            "Content-Type": "application/json"
        }
    
    def _login(self) -> str:
        """
        Login to 123FormBuilder and get JWT token
        
        Returns:
            JWT token string
        """
        login_url = f"{self.base_url}/token"
        login_data = {
            "username": self.username,
            "password": self.password
        }
        
        try:
            response = requests.post(login_url, json=login_data)
            response.raise_for_status()
            
            token_data = response.json()
            # Try different possible token field names
            token = token_data.get('token') or token_data.get('access_token') or token_data.get('jwt')
            
            if not token:
                raise ValueError(f"No token found in login response: {token_data}")
                
            logger.info("Successfully obtained JWT token")
            return token
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Login failed: {e}")
            raise
    
    def _make_request(self, endpoint: str, params: Optional[Dict] = None) -> Dict[str, Any]:
        """
        Make a request to the 123FormBuilder API
        
        Args:
            endpoint: API endpoint (without base URL)
            params: Optional query parameters
            
        Returns:
            Dict containing the API response
        """
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        
        try:
            response = requests.get(url, headers=self.headers, params=params or {})
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"API request failed: {e}")
            raise
    
    def get_groups_list(self, page: int = 1, per_page: int = 100) -> Dict[str, Any]:
        """
        Get list of all groups
        
        Args:
            page: Page number for pagination
            per_page: Number of items per page
            
        Returns:
            Dict containing groups data
        """
        params = {
            "page": page,
            "per_page": per_page
        }
        return self._make_request("groups", params)
    
    def get_group_details(self, group_id: str) -> Dict[str, Any]:
        """
        Get detailed information for a specific group
        
        Args:
            group_id: The group ID
            
        Returns:
            Dict containing group details
        """
        return self._make_request(f"groups/{group_id}")
    
    def get_group_forms(self, group_id: str, page: int = 1, per_page: int = 100) -> Dict[str, Any]:
        """
        Get forms within a specific group
        
        Args:
            group_id: The group ID
            page: Page number for pagination
            per_page: Number of items per page
            
        Returns:
            Dict containing forms in the group
        """
        params = {
            "page": page,
            "per_page": per_page
        }
        return self._make_request(f"groups/{group_id}/forms", params)
    
    def fetch_all_groups_data(self) -> List[Dict[str, Any]]:
        """
        Fetch comprehensive groups data including details and associated forms
        
        Returns:
            List of dictionaries containing all groups data
        """
        all_groups_data = []
        page = 1
        
        while True:
            logger.info(f"Fetching groups list page {page}")
            groups_response = self.get_groups_list(page=page)
            
            if not groups_response.get('data'):
                break
            
            groups = groups_response.get('data', [])
            if not groups:
                break
                
            for group in groups:
                group_id = str(group.get('id'))
                logger.info(f"Processing group ID: {group_id}")
                
                try:
                    # Get group details
                    group_details = self.get_group_details(group_id)
                    group_data = group_details.get('data', {})
                    
                    # Get forms in this group
                    group_forms_data = []
                    forms_page = 1
                    
                    while True:
                        group_forms = self.get_group_forms(group_id, page=forms_page)
                        forms = group_forms.get('data', [])
                        
                        if not forms:
                            break
                            
                        group_forms_data.extend(forms)
                        
                        # Check if there are more pages
                        if len(forms) < 100:  # Assuming per_page default is 100
                            break
                        forms_page += 1
                    
                    group_data['forms'] = group_forms_data
                    group_data['forms_count'] = len(group_forms_data)
                    
                    # Add metadata
                    group_data['extracted_at'] = None  # Will be set by Treasure Data
                    
                    all_groups_data.append(group_data)
                    
                except Exception as e:
                    logger.error(f"Error processing group {group_id}: {e}")
                    continue
            
            # Check if there are more pages
            if len(groups) < 100:  # Assuming per_page default is 100
                break
            page += 1
        
        return all_groups_data

def main():
    """Main function to fetch groups data and output to Treasure Data"""
    
    # Get credentials from environment variables
    username = os.environ.get('FORMBUILDER_USERNAME')
    password = os.environ.get('FORMBUILDER_PASSWORD')
    td_api_key = os.environ.get('TD_API_KEY')
    td_database = os.environ.get('TD_DATABASE')
    
    # Check if we have username and password
    if not username or not password:
        logger.error("Both FORMBUILDER_USERNAME and FORMBUILDER_PASSWORD environment variables are required")
        sys.exit(1)
    
    # Initialize client
    client = FormBuilderGroupsClient(
        username=username,
        password=password
    )
    
    try:
        # Fetch all groups data
        logger.info("Starting groups data extraction")
        groups_data = client.fetch_all_groups_data()
        
        # Output data
        if groups_data:
            logger.info(f"Extracted {len(groups_data)} groups")
            
            # Try to save to Treasure Data if credentials are available
            if pytd and td_api_key and td_database:
                try:
                    import pandas as pd
                    
                    # Convert to DataFrame and flatten nested JSON
                    df = pd.json_normalize(groups_data)
                    
                    # Initialize TD client
                    td_client = pytd.Client(apikey=td_api_key, database=td_database)
                    table_name = 'formbuilder_groups'
                    
                    # Upload data to Treasure Data
                    td_client.load_table_from_dataframe(
                        dataframe=df,
                        destination=table_name,
                        writer='bulk_import',
                        if_exists='append'
                    )
                    logger.info(f"Successfully uploaded {len(groups_data)} records to {table_name} table")
                    
                except Exception as td_error:
                    logger.error(f"Failed to upload to TD: {td_error}")
                    # Fallback to stdout
                    for group_data in groups_data:
                        print(json.dumps(group_data))
            else:
                logger.info("TD credentials not available, outputting to stdout")
                # Output each group as a separate record
                for group_data in groups_data:
                    print(json.dumps(group_data))
                
        else:
            logger.warning("No groups data extracted")
            
    except Exception as e:
        logger.error(f"Groups extraction failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()