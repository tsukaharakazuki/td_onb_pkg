#!/usr/bin/env python

import os
import sys
import json
import requests
from typing import Dict, List, Any, Optional
import logging
from datetime import datetime, timedelta

# Treasure Data Python SDK for outputting data
try:
    import pytd
except ImportError:
    pytd = None

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FormBuilderSubmissionsClient:
    """123FormBuilder API client for fetching form submissions data"""
    
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
        Get list of all forms to get form IDs
        
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
    
    def get_form_details(self, form_id: str) -> Dict[str, Any]:
        """
        Get form details for context
        
        Args:
            form_id: The form ID
            
        Returns:
            Dict containing form details
        """
        return self._make_request(f"forms/{form_id}")
    
    def fetch_all_submissions_data(self, days_back: int = 30) -> List[Dict[str, Any]]:
        """
        Fetch all form submissions data from all forms
        
        Args:
            days_back: Number of days back to fetch submissions (for filtering)
            
        Returns:
            List of dictionaries containing all submissions data
        """
        all_submissions_data = []
        
        # First, get all forms
        logger.info("Fetching list of forms to get submissions from")
        page = 1
        form_ids = []
        
        while True:
            forms_response = self.get_forms_list(page=page)
            
            if not forms_response.get('data'):
                break
            
            forms = forms_response.get('data', [])
            if not forms:
                break
                
            for form in forms:
                form_ids.append({
                    'id': str(form.get('id')),
                    'name': form.get('name', 'Unknown Form'),
                    'status': form.get('status', 'Unknown')
                })
            
            # Check if there are more pages
            if len(forms) < 100:
                break
            page += 1
        
        logger.info(f"Found {len(form_ids)} forms to check for submissions")
        
        # Now get submissions from each form
        for form_info in form_ids:
            form_id = form_info['id']
            form_name = form_info['name']
            logger.info(f"Fetching submissions for form: {form_name} (ID: {form_id})")
            
            try:
                # Get form details for additional context
                form_details = self.get_form_details(form_id)
                form_data = form_details.get('data', {})
                
                # Get submissions for this form
                submissions_page = 1
                
                while True:
                    submissions_response = self.get_form_submissions(form_id, page=submissions_page, per_page=100)
                    
                    if not submissions_response.get('data'):
                        break
                    
                    submissions = submissions_response.get('data', [])
                    if not submissions:
                        break
                    
                    for submission in submissions:
                        # Enrich submission with form information
                        enriched_submission = {
                            'form_id': form_id,
                            'form_name': form_name,
                            'form_status': form_info['status'],
                            'submission_id': submission.get('id'),
                            'submission_data': submission,
                            'form_created_date': form_data.get('created_date'),
                            'form_modified_date': form_data.get('modified_date'),
                            'extracted_at': None  # Will be set by Treasure Data
                        }
                        
                        all_submissions_data.append(enriched_submission)
                    
                    logger.info(f"Fetched {len(submissions)} submissions from form {form_name} (page {submissions_page})")
                    
                    # Check if there are more pages
                    if len(submissions) < 100:
                        break
                    submissions_page += 1
                
            except Exception as e:
                logger.error(f"Error fetching submissions for form {form_id} ({form_name}): {e}")
                continue
        
        return all_submissions_data

def main():
    """Main function to fetch form submissions data and output to Treasure Data"""
    
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
    client = FormBuilderSubmissionsClient(
        username=username,
        password=password
    )
    
    try:
        # Fetch all submissions data
        logger.info("Starting form submissions data extraction")
        submissions_data = client.fetch_all_submissions_data()
        
        # Output data
        if submissions_data:
            logger.info(f"Extracted {len(submissions_data)} form submissions")
            
            # Try to save to Treasure Data if credentials are available
            if pytd and td_api_key and td_database:
                try:
                    import pandas as pd
                    
                    # Convert to DataFrame and flatten nested JSON
                    df = pd.json_normalize(submissions_data)
                    
                    # Initialize TD client
                    td_client = pytd.Client(apikey=td_api_key, database=td_database)
                    table_name = 'formbuilder_submissions'
                    
                    # Upload data to Treasure Data
                    td_client.load_table_from_dataframe(
                        dataframe=df,
                        destination=table_name,
                        writer='bulk_import',
                        if_exists='append'
                    )
                    logger.info(f"Successfully uploaded {len(submissions_data)} records to {table_name} table")
                    
                except Exception as td_error:
                    logger.error(f"Failed to upload to TD: {td_error}")
                    # Fallback to stdout
                    for submission_data in submissions_data:
                        print(json.dumps(submission_data))
            else:
                logger.info("TD credentials not available, outputting to stdout")
                # Output each submission as a separate record
                for submission_data in submissions_data:
                    print(json.dumps(submission_data))
                
        else:
            logger.warning("No form submissions data extracted")
            
    except Exception as e:
        logger.error(f"Form submissions extraction failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()