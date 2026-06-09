import os
import time
import uuid
from flask import Flask, jsonify, request, render_template
import mysql.connector
from mysql.connector import Error
import boto3
from botocore.exceptions import ClientError

app = Flask(__name__, template_folder='templates')

# Retrieve configuration from environment variables
DB_HOST = os.environ.get('DB_HOST')
DB_USER = os.environ.get('DB_USER')
DB_PASSWORD = os.environ.get('DB_PASSWORD')
DB_NAME = os.environ.get('DB_NAME')
S3_BUCKET = os.environ.get('S3_BUCKET')
AWS_REGION = os.environ.get('AWS_REGION', 'us-east-1')

def get_db_connection():
    return mysql.connector.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        connection_timeout=5
    )

def init_db():
    """Initializes the database table if it doesn't exist."""
    conn = None
    cursor = None
    try:
        conn = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            connection_timeout=5
        )
        cursor = conn.cursor()
        cursor.execute(f"CREATE DATABASE IF NOT EXISTS {DB_NAME}")
        cursor.execute(f"USE {DB_NAME}")
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS visits (
                id INT AUTO_INCREMENT PRIMARY KEY,
                visitor_name VARCHAR(100) NOT NULL,
                message TEXT,
                visit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.commit()
        print("Database initialized successfully.")
    except Error as e:
        print(f"Error initializing database: {e}")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

# Try to initialize DB on startup
try:
    init_db()
except Exception as e:
    print(f"Startup DB init failed (will retry on request): {e}")

@app.route('/')
def index():
    # Gather system info
    system_info = {
        "db_host": DB_HOST,
        "s3_bucket": S3_BUCKET,
        "aws_region": AWS_REGION
    }
    return render_template('index.html', system_info=system_info)

@app.route('/api/status', methods=['GET'])
def get_status():
    status = {
        "db_connected": False,
        "db_error": None,
        "s3_connected": False,
        "s3_error": None
    }
    
    # Test DB Connection
    try:
        conn = get_db_connection()
        if conn.is_connected():
            status["db_connected"] = True
        conn.close()
    except Exception as e:
        status["db_error"] = str(e)
        
    # Test S3 Connection
    try:
        s3 = boto3.client('s3', region_name=AWS_REGION)
        # Attempt to get bucket location to verify permission and existence
        s3.get_bucket_location(Bucket=S3_BUCKET)
        status["s3_connected"] = True
    except Exception as e:
        status["s3_error"] = str(e)
        
    return jsonify(status)

@app.route('/api/logs', methods=['GET'])
def get_logs():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id, visitor_name, message, DATE_FORMAT(visit_time, '%Y-%m-%d %H:%i:%s') as visit_time FROM visits ORDER BY id DESC LIMIT 10")
        logs = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify({"success": True, "logs": logs})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/api/logs', methods=['POST'])
def add_log():
    data = request.get_json() or {}
    visitor_name = data.get('visitor_name', '').strip()
    message = data.get('message', '').strip()
    
    if not visitor_name:
        return jsonify({"success": False, "error": "Name is required"}), 400
        
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO visits (visitor_name, message) VALUES (%s, %s)",
            (visitor_name, message)
        )
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"success": True, "message": "Log added successfully!"})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/api/s3-files', methods=['GET'])
def get_s3_files():
    try:
        s3 = boto3.client('s3', region_name=AWS_REGION)
        response = s3.list_objects_v2(Bucket=S3_BUCKET)
        files = []
        if 'Contents' in response:
            for obj in response['Contents']:
                files.append({
                    "key": obj['Key'],
                    "size": obj['Size'],
                    "last_modified": obj['LastModified'].strftime('%Y-%m-%d %H:%i:%s')
                })
        return jsonify({"success": True, "files": files})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/api/s3-upload', methods=['POST'])
def upload_s3_file():
    data = request.get_json() or {}
    file_content = data.get('content', 'This is a sample asset file generated by the AWS web application.').strip()
    file_name = data.get('filename', f"sample-{uuid.uuid4().hex[:6]}.txt").strip()
    
    try:
        s3 = boto3.client('s3', region_name=AWS_REGION)
        s3.put_object(
            Bucket=S3_BUCKET,
            Key=file_name,
            Body=file_content,
            ContentType='text/plain'
        )
        return jsonify({"success": True, "message": f"Successfully uploaded {file_name} to S3!"})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/api/s3-delete', methods=['POST'])
def delete_s3_file():
    data = request.get_json() or {}
    file_name = data.get('filename', '').strip()
    
    if not file_name:
        return jsonify({"success": False, "error": "Filename is required"}), 400
        
    try:
        s3 = boto3.client('s3', region_name=AWS_REGION)
        s3.delete_object(Bucket=S3_BUCKET, Key=file_name)
        return jsonify({"success": True, "message": f"Successfully deleted {file_name} from S3!"})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80, debug=False)
