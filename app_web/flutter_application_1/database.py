import psycopg2
import urllib.request
import urllib.error
import json
import uuid

# 1. ĐƯỜNG DẪN KẾT NỐI DATABASE CỦA BẠN
DATABASE_URL = "postgresql://postgres.jkaazcjahfqozwizhpvk:Khaiphadulieu@aws-1-ap-northeast-2.pooler.supabase.com:6543/postgres"

# 2. THÔNG TIN API TỪ DASHBOARD SUPABASE
SUPABASE_URL = "https://jkaazcjahfqozwizhpvk.supabase.co"
# ⚠️ BẠN CẦN VÀO SUPABASE -> SETTINGS -> API ĐỂ LẤY 'ANON KEY' VÀ DÁN VÀO ĐÂY:
ANON_KEY = "sb_publishable_Puq34gHiotqH4yBwGTFlzw_FpCqPq0r"

def get_connection():
    """Tạo kết nối đến CSDL Supabase và tự động tắt bảo mật RLS cho bảng translation_history"""
    try:
        conn = psycopg2.connect(DATABASE_URL)
        print("✅ Kết nối CSDL Supabase (Postgres) thành công!")
        
        # Mở khóa RLS cho đúng bảng 'translation_history'
        try:
            cursor = conn.cursor()
            cursor.execute('ALTER TABLE "public"."translation_history" DISABLE ROW LEVEL SECURITY;')
            conn.commit()
            cursor.close()
            print("🔓 Đã mở khóa bảo mật RLS cho bảng 'translation_history' tự động!")
        except Exception as e:
            print(f"⚠️ Lỗi khi mở khóa RLS: {e}")
            
        return conn
    except Exception as e:
        print(f"❌ Lỗi kết nối CSDL: {e}")
        return None

def fetch_translation_history():
    """Lấy dữ liệu từ bảng translation_history"""
    conn = get_connection()
    if conn:
        try:
            cursor = conn.cursor()
            # Câu lệnh tạo bảng tự động chuẩn theo các cột trên web Supabase của bạn
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS translation_history (
                    id UUID PRIMARY KEY,
                    device_id UUID,
                    input_text TEXT,
                    output_text TEXT,
                    model_version VARCHAR
                )
            ''')
            conn.commit()

            # Lấy 10 bản ghi mới nhất (sắp xếp theo ID hoặc cứ lấy ra)
            cursor.execute("SELECT input_text, output_text, model_version FROM translation_history LIMIT 10;")
            records = cursor.fetchall()
            
            print(f"\n--- LẤY DỮ LIỆU TỪ BẢNG 'translation_history' ({len(records)} dòng) ---")
            for row in records:
                print(f"Nguồn: {row[0]}")
                print(f"Dịch : {row[1]}")
                print(f"Model: {row[2]}")
                print("-" * 50)
            
            cursor.close()
        except Exception as e:
            print(f"❌ Lỗi khi truy vấn bảng translation_history: {e}")
        finally:
            conn.close()

def test_api_insert():
    """Giả lập cách ứng dụng Flutter gọi REST API để đẩy lịch sử dịch lên"""
    print("\n--- TEST ĐẨY BẢN DỊCH QUA API GIỐNG FLUTTER ---")
    
    # Sửa đúng tên endpoint thành translation_history
    url = f"{SUPABASE_URL}/rest/v1/translation_history"

    # Dữ liệu giả lập khớp 100% với tên cột trên Supabase của bạn
    data = json.dumps({
        "id": str(uuid.uuid4()),
        "device_id": str(uuid.uuid4()), # Giả lập 1 UUID cho thiết bị
        "input_text": "Câu kiểm tra kết nối API từ Python",
        "output_text": "API Connection Test from Python",
        "model_version": "v1.2"
    }).encode('utf-8')

    headers = {
        'apikey': ANON_KEY,
        'Authorization': f'Bearer {ANON_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation' 
    }

    req = urllib.request.Request(url, data=data, headers=headers, method='POST')
    try:
        response = urllib.request.urlopen(req)
        print("✅ Thành công! Supabase trả về:", response.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        print(f"❌ LỖI API: Supabase chặn vì: {e.code} - {e.reason}")
        print("Chi tiết lỗi:", e.read().decode('utf-8'))
    except Exception as e:
        print("Lỗi không lường trước:", e)

if __name__ == "__main__":
    print("Đang khởi động quy trình Test Backend...")
    # 1. Kết nối qua Python, tự động tạo bảng (nếu chưa có) và mở khóa RLS
    fetch_translation_history()
    # 2. Test bắn API giả lập Flutter
    test_api_insert()