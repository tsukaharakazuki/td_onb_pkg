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
except ImportError:
    pytd = None

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FormBuilderUsersClient:
    """123FormBuilder API client for fetching users data"""
    
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
    
    def get_users_list(self, page: int = 1, per_page: int = 100) -> Dict[str, Any]:
        """
        Get list of all users (master user and subusers)
        
        Args:
            page: Page number for pagination
            per_page: Number of items per page
            
        Returns:
            Dict containing users data
        """
        params = {
            "page": page,
            "per_page": per_page
        }
        return self._make_request("users", params)
    
    def get_user_details(self, user_id: str) -> Dict[str, Any]:
        """
        Get detailed information for a specific user
        
        Args:
            user_id: The user ID
            
        Returns:
            Dict containing user details
        """
        return self._make_request(f"users/{user_id}")
    
    def get_current_user(self) -> Dict[str, Any]:
        """
        Get current user information (the user associated with the API token)
        
        Returns:
            Dict containing current user data
        """
        return self._make_request("user")
    
    def fetch_all_users_data(self) -> List[Dict[str, Any]]:
        """
        Fetch comprehensive users data including master and subusers
        
        Returns:
            List of dictionaries containing all users data
        """
        all_users_data = []
        
        # First, get current user data
        try:
            logger.info("Fetching current user data")
            current_user_response = self.get_current_user()
            current_user_data = current_user_response.get('data', {})
            
            if current_user_data:
                current_user_data['user_type'] = 'current_user'
                current_user_data['extracted_at'] = None  # Will be set by Treasure Data
                all_users_data.append(current_user_data)
                
        except Exception as e:
            logger.error(f"Error fetching current user: {e}")
        
        # Then, get all users (including subusers)
        page = 1
        
        while True:
            logger.info(f"Fetching users list page {page}")
            try:
                users_response = self.get_users_list(page=page)
                
                if not users_response.get('data'):
                    break
                
                users = users_response.get('data', [])
                if not users:
                    break
                    
                for user in users:
                    user_id = str(user.get('id'))
                    logger.info(f"Processing user ID: {user_id}")
                    
                    try:
                        # Get user details
                        user_details = self.get_user_details(user_id)
                        user_data = user_details.get('data', {})
                        
                        # Add user type information
                        user_data['user_type'] = 'subuser' if user.get('is_subuser') else 'master'
                        
                        # Add metadata
                        user_data['extracted_at'] = None  # Will be set by Treasure Data
                        
                        all_users_data.append(user_data)
                        
                    except Exception as e:
                        logger.error(f"Error processing user {user_id}: {e}")
                        # Add basic user data even if detailed fetch fails
                        user['user_type'] = 'subuser' if user.get('is_subuser') else 'master'
                        user['extracted_at'] = None
                        all_users_data.append(user)
                        continue
                
                # Check if there are more pages
                if len(users) < 100:  # Assuming per_page default is 100
                    break
                page += 1
                
            except Exception as e:
                logger.error(f"Error fetching users page {page}: {e}")
                break
        
        return all_users_data

def main():
    """Main function to fetch users data and output to Treasure Data"""
    
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
    client = FormBuilderUsersClient(
        username=username,
        password=password
    )
    
    try:
        # Fetch all users data
        logger.info("Starting users data extraction")
        users_data = client.fetch_all_users_data()
        
        # Output data
        if users_data:
            logger.info(f"Extracted {len(users_data)} users")
            
            # Try to save to Treasure Data if credentials are available
            if pytd and td_api_key and td_database:
                try:
                    import pandas as pd
                    
                    # Convert to DataFrame and flatten nested JSON
                    df = pd.json_normalize(users_data)
                    
                    # Initialize TD client
                    td_client = pytd.Client(apikey=td_api_key, database=td_database)
                    table_name = 'formbuilder_users'
                    
                    # Upload data to Treasure Data
                    td_client.load_table_from_dataframe(
                        dataframe=df,
                        destination=table_name,
                        writer='bulk_import',
                        if_exists='append'
                    )
                    logger.info(f"Successfully uploaded {len(users_data)} records to {table_name} table")
                    
                except Exception as td_error:
                    logger.error(f"Failed to upload to TD: {td_error}")
                    # Fallback to stdout
                    for user_data in users_data:
                        print(json.dumps(user_data))
            else:
                logger.info("TD credentials not available, outputting to stdout")
                # Output each user as a separate record
                for user_data in users_data:
                    print(json.dumps(user_data))
                
        else:
            logger.warning("No users data extracted")
            
    except Exception as e:
        logger.error(f"Users extraction failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()