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

class FormBuilderFormsClient:
    """123FormBuilder API client for fetching forms data"""
    
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
    
    def get_forms_list(self, page: int = 1, per_page: int = 100) -> Dict[str, Any]:
        """
        Get list of all forms
        
        Args:
            page: Page number for pagination
            per_page: Number of items per page
            
        Returns:
            Dict containing forms data
        """
        params = {
            "page": page,
            "per_page": per_page
        }
        return self._make_request("forms", params)
    
    def get_form_details(self, form_id: str) -> Dict[str, Any]:
        """
        Get detailed information for a specific form
        
        Args:
            form_id: The form ID
            
        Returns:
            Dict containing form details
        """
        return self._make_request(f"forms/{form_id}")
    
    def get_form_fields(self, form_id: str) -> Dict[str, Any]:
        """
        Get fields/controls for a specific form
        
        Args:
            form_id: The form ID
            
        Returns:
            Dict containing form fields data
        """
        return self._make_request(f"forms/{form_id}/fields")
    
    def get_form_submissions(self, form_id: str, page: int = 1, per_page: int = 100) -> Dict[str, Any]:
        """
        Get submissions for a specific form
        
        Args:
            form_id: The form ID
            page: Page number for pagination
            per_page: Number of items per page
            
        Returns:
            Dict containing submissions data
        """
        params = {
            "page": page,
            "per_page": per_page
        }
        return self._make_request(f"forms/{form_id}/submissions", params)
    
    def fetch_all_forms_data(self) -> List[Dict[str, Any]]:
        """
        Fetch comprehensive forms data including details, fields, and submissions
        
        Returns:
            List of dictionaries containing all forms data
        """
        all_forms_data = []
        page = 1
        
        while True:
            logger.info(f"Fetching forms list page {page}")
            forms_response = self.get_forms_list(page=page)
            
            if not forms_response.get('data'):
                break
            
            forms = forms_response.get('data', [])
            if not forms:
                break
                
            for form in forms:
                form_id = str(form.get('id'))
                logger.info(f"Processing form ID: {form_id}")
                
                # Get form details
                try:
                    form_details = self.get_form_details(form_id)
                    form_data = form_details.get('data', {})
                    
                    # Get form fields
                    form_fields = self.get_form_fields(form_id)
                    form_data['fields'] = form_fields.get('data', [])
                    
                    # Get form submissions (first page only for data structure)
                    form_submissions = self.get_form_submissions(form_id, per_page=10)
                    form_data['submissions_sample'] = form_submissions.get('data', [])
                    form_data['submissions_count'] = form_submissions.get('total', 0)
                    
                    # Add metadata
                    form_data['extracted_at'] = None  # Will be set by Treasure Data
                    
                    all_forms_data.append(form_data)
                    
                except Exception as e:
                    logger.error(f"Error processing form {form_id}: {e}")
                    continue
            
            # Check if there are more pages
            if len(forms) < 100:  # Assuming per_page default is 100
                break
            page += 1
        
        return all_forms_data

def main():
    """Main function to fetch forms data and output to Treasure Data"""
    
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
    client = FormBuilderFormsClient(
        username=username,
        password=password
    )
    
    try:
        # Fetch all forms data
        logger.info("Starting forms data extraction")
        forms_data = client.fetch_all_forms_data()
        
        # Output data
        if forms_data:
            logger.info(f"Extracted {len(forms_data)} forms")
            
            # Try to save to Treasure Data if credentials are available
            if pytd and td_api_key and td_database:
                try:
                    import pandas as pd
                    
                    # Convert to DataFrame and flatten nested JSON
                    df = pd.json_normalize(forms_data)
                    
                    # Initialize TD client
                    td_client = pytd.Client(apikey=td_api_key, database=td_database)
                    table_name = 'formbuilder_forms'
                    
                    # Upload data to Treasure Data
                    td_client.load_table_from_dataframe(
                        dataframe=df,
                        destination=table_name,
                        writer='bulk_import',
                        if_exists='append'
                    )
                    logger.info(f"Successfully uploaded {len(forms_data)} records to {table_name} table")
                    
                except Exception as td_error:
                    logger.error(f"Failed to upload to TD: {td_error}")
                    # Fallback to stdout
                    for form_data in forms_data:
                        print(json.dumps(form_data))
            else:
                logger.info("TD credentials not available, outputting to stdout")
                # Output each form as a separate record
                for form_data in forms_data:
                    print(json.dumps(form_data))
                
        else:
            logger.warning("No forms data extracted")
            
    except Exception as e:
        logger.error(f"Forms extraction failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()