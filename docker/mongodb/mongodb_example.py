"""
MongoDB Connection Example for Python
This script demonstrates how to connect to MongoDB running in Docker
and perform basic operations.

Before running:
1. Ensure MongoDB container is running: docker-compose up -d
2. Install dependencies: pip install pymongo python-dotenv
3. Create a .env file in the same directory with your credentials
   (copy from .env.example and update with your values)

Usage:
    python mongodb_example.py

Environment Variables Required:
    MONGO_ROOT_USER: MongoDB root username
    MONGO_ROOT_PASSWORD: MongoDB root password
    MONGO_HOST: MongoDB host (default: localhost)
    MONGO_PORT: MongoDB port (default: 27017)
    MONGO_DB_NAME: Database name to use
"""

import os
from dotenv import load_dotenv
from pymongo import MongoClient
from pymongo.errors import ServerSelectionTimeoutError, OperationFailure
from datetime import datetime

# Load environment variables from .env file
load_dotenv()

# Configuration from environment variables
MONGO_ROOT_USER = os.getenv('MONGO_ROOT_USER')
MONGO_ROOT_PASSWORD = os.getenv('MONGO_ROOT_PASSWORD')
MONGO_HOST = os.getenv('MONGO_HOST', 'localhost')
MONGO_PORT = os.getenv('MONGO_PORT', '27017')
MONGO_DB_NAME = os.getenv('MONGO_DB_NAME')

# Validate required environment variables
if not MONGO_ROOT_USER or not MONGO_ROOT_PASSWORD or not MONGO_DB_NAME:
    print("✗ Error: Missing required environment variables")
    print("  Please ensure your .env file contains:")
    print("  - MONGO_ROOT_USER")
    print("  - MONGO_ROOT_PASSWORD")
    print("  - MONGO_DB_NAME")
    exit(1)

# Build connection string using environment variables
MONGO_URI = f"mongodb://{MONGO_ROOT_USER}:{MONGO_ROOT_PASSWORD}@{MONGO_HOST}:{MONGO_PORT}/{MONGO_DB_NAME}?authSource=admin"


def connect_to_mongodb():
    """Establish connection to MongoDB using environment variables."""
    try:
        print(f"Connecting to MongoDB at {MONGO_HOST}:{MONGO_PORT}...")
        client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
        
        # Verify connection
        client.admin.command('ping')
        print("✓ Successfully connected to MongoDB!")
        
        return client
    except ServerSelectionTimeoutError:
        print("✗ Failed to connect to MongoDB. Is the container running?")
        print("  Run: docker-compose up -d")
        return None
    except OperationFailure as e:
        print(f"✗ Authentication failed: {e}")
        print("  Verify MONGO_ROOT_USER and MONGO_ROOT_PASSWORD in .env")
        return None


def insert_sample_data(db):
    """Insert sample documents into the database."""
    print("\n--- Inserting Sample Data ---")
    
    collection = db.users
    
    sample_users = [
        {
            "name": "Alice Johnson",
            "email": "alice@example.com",
            "age": 28,
            "city": "New York",
            "created_at": datetime.now()
        },
        {
            "name": "Bob Smith",
            "email": "bob@example.com",
            "age": 35,
            "city": "Los Angeles",
            "created_at": datetime.now()
        },
        {
            "name": "Charlie Brown",
            "email": "charlie@example.com",
            "age": 42,
            "city": "Chicago",
            "created_at": datetime.now()
        }
    ]
    
    result = collection.insert_many(sample_users)
    print(f"✓ Inserted {len(result.inserted_ids)} documents")
    
    return result.inserted_ids


def query_data(db):
    """Demonstrate various query operations."""
    print("\n--- Querying Data ---")
    
    collection = db.users
    
    # Find one
    print("\n1. Find one user:")
    user = collection.find_one({"age": {"$gt": 30}})
    if user:
        print(f"   Found: {user['name']} (Age: {user['age']})")
    
    # Find many
    print("\n2. Find all users older than 25:")
    users = collection.find({"age": {"$gt": 25}}).sort("age", 1)
    for user in users:
        print(f"   - {user['name']}: Age {user['age']}, City: {user['city']}")
    
    # Count
    print("\n3. Count documents:")
    count = collection.count_documents({})
    print(f"   Total users: {count}")
    
    # Find with specific fields
    print("\n4. Find names and emails only:")
    users = collection.find({}, {"name": 1, "email": 1, "_id": 0})
    for user in users:
        print(f"   - {user['name']}: {user['email']}")


def update_data(db):
    """Demonstrate update operations."""
    print("\n--- Updating Data ---")
    
    collection = db.users
    
    # Update one
    result = collection.update_one(
        {"name": "Alice Johnson"},
        {"$set": {"city": "Boston", "updated_at": datetime.now()}}
    )
    print(f"✓ Updated {result.modified_count} document(s)")
    
    # Verify update
    updated_user = collection.find_one({"name": "Alice Johnson"})
    print(f"   Alice now lives in: {updated_user['city']}")


def delete_data(db):
    """Demonstrate delete operations."""
    print("\n--- Deleting Data ---")
    
    collection = db.users
    
    # Delete one
    result = collection.delete_one({"name": "Charlie Brown"})
    print(f"✓ Deleted {result.deleted_count} document(s)")
    
    # Verify deletion
    count = collection.count_documents({})
    print(f"   Remaining users: {count}")


def get_database_stats(client):
    """Display database statistics."""
    print("\n--- Database Statistics ---")
    
    # List all databases
    databases = client.list_database_names()
    print(f"Databases: {', '.join(databases)}")
    
    # Get database
    db = client[MONGO_DB_NAME]
    
    # List collections
    collections = db.list_collection_names()
    print(f"Collections: {', '.join(collections)}")
    
    # Get collection stats
    if 'users' in collections:
        users_collection = db.users
        print(f"Documents in 'users' collection: {users_collection.count_documents({})}")


def main():
    """Main execution flow."""
    print("=" * 50)
    print("MongoDB Python Connection Example")
    print("=" * 50)
    
    # Connect to MongoDB
    client = connect_to_mongodb()
    if not client:
        return
    
    try:
        # Get database
        db = client[MONGO_DB_NAME]
        
        # Clear previous data for fresh demo
        db.users.drop()
        print("✓ Cleared previous 'users' collection")
        
        # Run demonstrations
        insert_sample_data(db)
        query_data(db)
        update_data(db)
        query_data(db)
        delete_data(db)
        get_database_stats(client)
        
        print("\n" + "=" * 50)
        print("✓ All operations completed successfully!")
        print("=" * 50)
        
    except Exception as e:
        print(f"\n✗ Error during operations: {e}")
    
    finally:
        # Close connection
        client.close()
        print("\n✓ Connection closed")


if __name__ == "__main__":
    main()
