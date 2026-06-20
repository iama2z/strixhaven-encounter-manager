"""
create_test_user.py — Creates a test Firebase Auth user for Strixhaven.

Usage:
    FIREBASE_CREDENTIALS_PATH=/path/to/serviceAccountKey.json python create_test_user.py
"""

import os
import sys

try:
    import firebase_admin
    from firebase_admin import credentials, auth
except ImportError:
    print("ERROR: firebase-admin is not installed.")
    print("Run: pip install firebase-admin")
    sys.exit(1)

cred_path = os.environ.get("FIREBASE_CREDENTIALS_PATH")
if not cred_path:
    print("ERROR: Set FIREBASE_CREDENTIALS_PATH to your service account JSON file.")
    print("Example: FIREBASE_CREDENTIALS_PATH=~/serviceAccountKey.json python create_test_user.py")
    sys.exit(1)

# Initialise Firebase Admin
cred = credentials.Certificate(os.path.expanduser(cred_path))
firebase_admin.initialize_app(cred)

TEST_EMAIL = "test@strixhaven.dev"
TEST_PASSWORD = "TestPass123!"
TEST_NAME = "Strixhaven Test Agent"

try:
    user = auth.create_user(
        email=TEST_EMAIL,
        password=TEST_PASSWORD,
        display_name=TEST_NAME,
    )
    print(f"\n✅ Test user created successfully!")
    print(f"   Email:    {TEST_EMAIL}")
    print(f"   Password: {TEST_PASSWORD}")
    print(f"   UID:      {user.uid}")
    print(f"\nYou can now log in to the app with these credentials.")

except auth.EmailAlreadyExistsError:
    print(f"\n⚠️  A user with email '{TEST_EMAIL}' already exists.")
    print(f"   Try logging in with password: {TEST_PASSWORD}")

except Exception as e:
    print(f"\n❌ Error creating user: {e}")
    sys.exit(1)
