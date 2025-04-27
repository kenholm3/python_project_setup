#!/bin/bash

# ==============================================================================
# Python Project Setup Script
# ==============================================================================
# Description:
#   Automates the creation of a new Python project structure including:
#   - Project directory
#   - Python virtual environment (.venv)
#   - Boilerplate main.py with logging and dotenv
#   - .env file for environment variables
#   - .gitignore file
#   - Git repository initialization
#   - Optional GitHub repository creation and initial push (requires gh CLI)
#
# Usage:
#   ./python_project_setup.sh <project_name>
#
# Example:
#   ./python_project_setup.sh my_awesome_api
#
# Prerequisites:
#   - Python 3 and venv module
#   - Git
#   - GitHub CLI (gh) installed and authenticated (for GitHub repo creation)
#     Run 'gh auth login' once after installing gh.
# ==============================================================================

# --- Configuration ---

# Libraries to import in main.py by default
DEFAULT_PYTHON_IMPORTS=(
    "import os"
    "import sys"
    "import logging"
    "from dotenv import load_dotenv"
    "# Add other common imports here if desired, e.g.:"
    "# import json"
    "# import requests"
)

# Boilerplate code for main.py
DEFAULT_MAIN_CODE=$(cat <<EOF
# Load environment variables from .env file
# Ensure .env file is in the same directory or parent directories
load_dotenv()

# --- Logging Configuration ---
# Basic configuration sets up a handler sending messages to stderr.
# You can customize the level, format, and output (e.g., file handler).
log_level_str = os.getenv("LOG_LEVEL", "INFO").upper()
log_level = getattr(logging, log_level_str, logging.INFO) # Default to INFO if invalid
logging.basicConfig(
    level=log_level,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
# Get a logger for this module
logger = logging.getLogger(__name__)

# --- Main Application Logic ---
def run_application():
    """Encapsulates the main logic of the application."""
    logger.info("Application starting...")

    # Example: Accessing an environment variable loaded from .env
    api_key = os.getenv("MY_API_KEY")
    if not api_key:
        logger.warning("Environment variable 'MY_API_KEY' not found in .env or environment.")
    else:
        # Be careful logging sensitive info, even at DEBUG level
        logger.debug("MY_API_KEY loaded.") # Use debug for potentially sensitive info

    # --- Your main code goes here ---
    print("Hello from the main application!")
    # --- End of your main code ---

    logger.info("Application finished successfully.")

# --- Entry Point ---
if __name__ == "__main__":
    try:
        run_application()
    except Exception as e:
        logger.exception("An unexpected error occurred:") # Logs the exception traceback
        sys.exit(1) # Exit with a non-zero status code to indicate failure
EOF
)

# Content for the .gitignore file
DEFAULT_GITIGNORE_CONTENT=$(cat <<EOF
# Python Bytecode and Cache
__pycache__/
*.py[cod]
*$py.class

# Virtual Environment
.venv/
venv/
ENV/
env/
env.bak/
venv.bak/

# Distribution / Packaging
*.egg-info/
.eggs/
dist/
build/
develop-eggs/
parts/
sdist/
var/
wheels/
pip-wheel-metadata/
share/python-wheels/
*.manifest
*.spec

# Environment Variables File
.env*
!.env.example
!.env.template

# IDE / Editor directories
.vscode/
.idea/
*.sublime-project
*.sublime-workspace

# OS generated files
.DS_Store
Thumbs.db

# Test output
htmlcov/
.tox/
.nox/
.coverage
.coverage.*
.cache
nosetests.xml
coverage.xml
*.cover
*.log
.pytest_cache/

# Secrets (if accidentally committed before .gitignore)
*.key
*.pem
credentials*
*.secret
secrets.*
EOF
)

# --- Script Logic ---

# 1. Validate Input
if [ -z "$1" ]; then
  echo "Error: Project name is required."
  echo "Usage: $0 <project_name>"
  exit 1
fi

PROJECT_NAME="$1"
# Create project in the current directory where the script is run
PROJECT_DIR="./${PROJECT_NAME}"

# 2. Check if Project Directory Exists
if [ -d "$PROJECT_DIR" ]; then
  echo "Error: Directory '$PROJECT_DIR' already exists."
  exit 1
fi

# 3. Create Project Structure
echo "--- Creating project directory: $PROJECT_DIR ---"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR" || { echo "Error: Failed to change directory to $PROJECT_DIR"; exit 1; } # Go into the project directory

echo "--- Setting up Python virtual environment (.venv) ---"
python3 -m venv .venv
if [ $? -ne 0 ]; then
    echo "Error: Failed to create virtual environment."
    cd .. && rm -rf "$PROJECT_DIR" # Clean up created directory
    exit 1
fi

# Activate the virtual environment for subsequent pip commands in this script
source .venv/bin/activate

echo "--- Installing essential packages (python-dotenv) ---"
pip install python-dotenv
# Add other base packages here if needed, e.g.: pip install requests black flake8 pytest

# Deactivate environment (optional, script session ends anyway)
# deactivate

echo "--- Creating main.py ---"
# Combine imports and main code
printf "%s\n" "${DEFAULT_PYTHON_IMPORTS[@]}" > main.py
echo "" >> main.py # Add a newline between imports and code
echo "$DEFAULT_MAIN_CODE" >> main.py

echo "--- Creating .env file ---"
touch .env
echo "# Add sensitive information and environment-specific variables here." >> .env
echo "# Example:" >> .env
echo "# MY_API_KEY=YOUR_SECRET_API_KEY_HERE" >> .env
echo "# DATABASE_URL=postgresql://user:password@host:port/database" >> .env
echo "# LOG_LEVEL=DEBUG" >> .env

echo "--- Creating .gitignore ---"
echo "$DEFAULT_GITIGNORE_CONTENT" > .gitignore

# 4. Initialize Git Repository
echo "--- Initializing Git repository ---"
git init -b main # Use 'main' as the default branch name
git add .
git commit -m "Initial commit: project structure setup"
if [ $? -ne 0 ]; then
    echo "Warning: Git commit failed. Please check Git configuration."
    # Continue without GitHub integration if commit fails
fi

# 5. GitHub Integration (Optional)
# Check if git commit was successful before proceeding
if [ $? -eq 0 ]; then
    if ! command -v gh &> /dev/null; then
        echo "--- GitHub CLI ('gh') not found. Skipping GitHub repository creation. ---"
        echo "Install 'gh' and run 'gh auth login' to enable this feature."
    else
        # Ask user if they want to create a GitHub repo
        read -p "Do you want to create a GitHub repository named '$PROJECT_NAME'? (y/N): " CREATE_GITHUB_REPO

        if [[ "$CREATE_GITHUB_REPO" =~ ^[Yy]$ ]]; then
            echo "--- Creating GitHub repository ---"
            # Creates a public repo by default. Use --private or --internal flags if needed.
            # '--source=.' links the current directory.
            # '--push' automatically pushes the current branch to the new remote.
            gh repo create "$PROJECT_NAME" --source=. --public --description="Python project: $PROJECT_NAME" --push
            if [ $? -eq 0 ]; then
                echo "--- GitHub repository created and initial commit pushed successfully. ---"
            else
                echo "Error: Failed to create or push to GitHub repository."
                echo "You may need to create it manually on GitHub and run:"
                echo "  git remote add origin <your-repo-url>"
                echo "  git push -u origin main"
            fi
        else
            echo "--- Skipping GitHub repository creation. ---"
        fi
    fi
fi

# 6. Completion Message
echo ""
echo "========================================================"
echo " Project '$PROJECT_NAME' setup complete!"
echo " Location: $(pwd)"
echo ""
echo " To activate the virtual environment, run:"
echo "   cd $(basename "$PROJECT_DIR")" # Use basename in case script was run from parent dir
echo "   source .venv/bin/activate"
echo ""
echo " To open this project in VS Code (if not already open):"
echo "   code ."
echo "========================================================"

exit 0

