"""
AI Translation System với Knowledge Graph
==========================================
- Tương thích Gradio 5.x (HF Spaces tự ép version này)
- Dùng Supabase REST API (httpx) thay psycopg2
- Lazy load model, lru_cache cho entity
- Pre-processing: mask tên riêng trước khi dịch để model không dịch sai
"""

import gradio as gr
import os
import re
import logging
import unicodedata
from dataclasses import dataclass, field
from functools import lru_cache

import httpx

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("translation_app")


# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
@dataclass
class AppConfig:
    supabase_url: str = field(
        default_factory=lambda: os.environ.get(
            "SUPABASE_URL",
            "https://jkaazcjahfqozwizhpvk.supabase.co"
        )
    )
    supabase_key: str = field(
        default_factory=lambda: os.environ.get("SUPABASE_KEY", "")
    )
    allowed_types: tuple = (
        "PERSON", "ORG", "LOCATION",
        "TECH", "PROGRAMMING_LANGUAGE", "FRAMEWORK",
        "DATABASE", "CLOUD", "MODEL",
        "PRODUCT", "FOOD",
    )
    min_frequency: int = 2
    ev_model: str = "Dich-Thuat-AI-Nhom-05/en-vi-translator"
    ve_model: str = "Dich-Thuat-AI-Nhom-05/vi-en-translator"


CONFIG = AppConfig()


# ---------------------------------------------------------------------------
# Model – Lazy Loading
# ---------------------------------------------------------------------------
_models: dict = {}


def get_model(direction: str):
    if direction not in _models:
        from transformers import pipeline
        model_id = CONFIG.ev_model if direction == "en->vi" else CONFIG.ve_model
        logger.info(f"Đang load model: {model_id}")
        _models[direction] = pipeline("translation", model=model_id)
        logger.info(f"Model [{direction}] sẵn sàng.")
    return _models[direction]


# ---------------------------------------------------------------------------
# Supabase REST API
# ---------------------------------------------------------------------------
@lru_cache(maxsize=8)
def fetch_entities_from_supabase(lang_code: str) -> dict:
    """
    Lấy toàn bộ entity glossary theo ngôn ngữ từ Supabase REST API.
    Cache bằng lru_cache – chỉ gọi API 1 lần mỗi lang_code.
    """
    if not CONFIG.supabase_key:
        logger.warning("SUPABASE_KEY chưa được cấu hình. KG bị bỏ qua.")
        return {}

    headers = {
        "apikey": CONFIG.supabase_key,
        "Authorization": f"Bearer {CONFIG.supabase_key}",
    }
    params = {
        "select": "entity_name,normalize_name",
        "language": f"eq.{lang_code}",
        "frequency": f"gt.{CONFIG.min_frequency - 1}",
        "entity_type": f"in.({','.join(CONFIG.allowed_types)})",
        "limit": "10000",
    }

    try:
        resp = httpx.get(
            f"{CONFIG.supabase_url}/rest/v1/knowledge_graph_entities",
            headers=headers,
            params=params,
            timeout=10.0,
        )
        resp.raise_for_status()
        entities = {}
        for row in resp.json():
            name = (row.get("entity_name") or "").strip()
            norm = (row.get("normalize_name") or "").strip()
            if name and norm:
                entities[name] = norm
        logger.info(f"Loaded {len(entities)} entities (lang={lang_code}).")
        return entities
    except httpx.HTTPStatusError as e:
        logger.error(f"Supabase HTTP {e.response.status_code}: {e.response.text}")
        return {}
    except Exception as e:
        logger.error(f"Lỗi Supabase API: {e}", exc_info=True)
        return {}


def invalidate_cache():
    fetch_entities_from_supabase.cache_clear()
    logger.info("Entity cache đã xóa.")


# ---------------------------------------------------------------------------
# Smart Replace (post-processing)
# ---------------------------------------------------------------------------
def smart_replace(text: str, entity_dict: dict) -> str:
    if not entity_dict:
        return text
    for ent in sorted(entity_dict, key=len, reverse=True):
        replacement = entity_dict[ent]
        pattern = re.compile(
            rf"(?<!\w){re.escape(ent)}(?!\w)",
            re.IGNORECASE | re.UNICODE,
        )
        text = pattern.sub(replacement, text)
    return text

# Danh sách các Họ phổ biến nhất Việt Nam để làm "mồi" nhận diện
VN_SURNAMES = ["Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Phan", "Vũ", "Võ", "Đặng", "Bùi", "Đỗ", "Hồ", "Ngô", "Dương", "Lý"]

def remove_accents(input_str):
    """Biến 'Lê Hoàng Sơn' thành 'Le Hoang Son'"""
    if not input_str:
        return ""
    # Chuẩn hóa Unicode và loại bỏ các ký tự dấu
    nksel = unicodedata.normalize('NFKD', input_str)
    res = "".join([c for c in nksel if not unicodedata.combining(c)])
    # Thay chữ Đ/đ đặc biệt vì NFKD không xử lý được
    return res.replace('đ', 'd').replace('Đ', 'D')
    
def normalize_text(text):
    """Chuẩn hóa Unicode để tránh lỗi 'Lê' (NFC) khác 'Lê' (NFD)"""
    return unicodedata.normalize('NFC', text) if text else ""

def vni_to_no_accent(text):
    if not text: return ""
    # Chuyển thành không dấu
    s = unicodedata.normalize('NFKD', text).encode('ascii', 'ignore').decode('utf-8')
# ---------------------------------------------------------------------------
# Pre-processing: Mask tên riêng trước khi dịch
# ---------------------------------------------------------------------------
def normalize_vni(text):
    """Chuẩn hóa về cùng một bảng mã để so khớp chính xác 100%"""
    return unicodedata.normalize('NFC', text)

def auto_detect_vn_names(text):
    """
    Tự động tìm các cụm từ viết hoa liên tiếp (khả năng cao là tên riêng)
    không nằm trong KG để bảo vệ.
    """
    # Regex tìm các từ viết hoa chữ cái đầu (2 từ trở lên)
    # Ví dụ: Nguyễn Văn A, Lê Hồng Phong
    pattern = r'\b([A-ZÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠƯ][a-zàáâãèéêìíòóôõùúăđĩũơưạảấầẩẫậắằẳẵặẹẻẽếềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹ]*\s?){2,}\b'
    matches = re.finditer(pattern, text)
    return [m.group().strip() for m in matches]

def mask_entities(text: str, entity_dict: dict) -> tuple[str, dict]:
    text = normalize_text(text)
    placeholder_map = {}
    masked = text
    
    # --- BƯỚC 1: TỰ ĐỘNG NHẬN DIỆN TÊN VIỆT NAM (Dùng quy tắc) ---
    # Regex này tìm: Một trong các Họ phổ biến + 1 đến 3 từ viết hoa đi kèm
    surname_regex = r'\b(' + '|'.join(VN_SURNAMES) + r')\s+([A-ZÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚĂĐĨŨƠƯ][a-zàáâãèéêìíòóôõùúăđĩũơưạảấầẩẫậắằẳẵặẹẻẽếềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹ]*\s?){1,3}\b'
    auto_names = [m.group().strip() for m in re.finditer(surname_regex, text)]

    # --- BƯỚC 2: KẾT HỢP VỚI BẢNG THỰC THỂ (Database) ---
    found_in_db = [name for name in entity_dict.keys() if name in text]
    
    # Gộp cả 2 nguồn lại và sắp xếp từ dài đến ngắn
    all_to_mask = sorted(list(set(auto_names + found_in_db)), key=len, reverse=True)

    for i, name in enumerate(all_to_mask):
        if name in masked:
            # Dùng [ENT_i] làm placeholder (model AI rất khó dịch nhầm cái này)
            token = f"[ENT_{i}]"
            # Nếu tên có trong DB thì lấy giá trị dịch (normalize_name), nếu tự nhận diện thì giữ nguyên tên
            placeholder_map[token] = entity_dict.get(name, name)
            
            # Thay thế chính xác cụm từ (dùng Regex Word Boundary)
            pattern = re.compile(rf"(?<!\w){re.escape(name)}(?!\w)", re.UNICODE)
            masked = pattern.sub(token, masked)
            
    return masked, placeholder_map

def restore_entities(text: str, placeholder_map: dict) -> str:
    for token, correct_name in placeholder_map.items():
        # Tạo regex linh hoạt: chấp nhận [ENT_0], [ ENT_0 ], [ent_0]...
        token_parts = token.replace("[", r"\[").replace("]", r"\]").replace("_", r"\s*_\s*")
        pattern = re.compile(token_parts, re.IGNORECASE)
        text = pattern.sub(correct_name, text)
    return text
    
# ---------------------------------------------------------------------------
# Core Translation Logic
# ---------------------------------------------------------------------------
def translate_logic(text: str, mode: str, use_kg: bool) -> str:
    if not text or not text.strip(): return ""
    
    text = normalize_text(text) # Chuẩn hóa đầu vào ngay lập tức
    direction = "en->vi" if mode == "Anh -> Việt" else "vi->en"
    src_lang = "en" if direction == "en->vi" else "vi"

    if not use_kg:
        return get_model(direction)(text)[0]["translation_text"]

    try:
        # Lấy thực thể từ DB để làm giàu dữ liệu
        db_entities = fetch_entities_from_supabase(src_lang)
        
        # Masking kết hợp (DB + Tự động quét tên Việt)
        masked_text, p_map = mask_entities(text, db_entities)
        
        # Dịch văn bản đã mask
        raw_output = get_model(direction)(masked_text)[0]["translation_text"]
        
        # Khôi phục tên gốc vào kết quả
        final_output = restore_entities(raw_output, p_map)
        
        return final_output
    except Exception as e:
        # Nếu lỗi thì dịch bình thường không qua KG
        return get_model(direction)(text)[0]["translation_text"]


# ---------------------------------------------------------------------------
# Gradio 5.x UI
# ---------------------------------------------------------------------------
with gr.Blocks(theme=gr.themes.Soft(), title="AI Translation + KG") as demo:
    gr.Markdown("# 🚀 Hệ thống Dịch thuật AI tích hợp Knowledge Graph")
    gr.Markdown("Dịch Anh ↔ Việt với bảo vệ thực thể chuyên ngành (PERSON, ORG, TECH…)")

    with gr.Row():
        with gr.Column():
            input_text = gr.Textbox(
                lines=7,
                label="Văn bản gốc",
                placeholder="Nhập câu cần dịch tại đây…",
            )
            mode = gr.Radio(
                choices=["Anh -> Việt", "Việt -> Anh"],
                label="Chiều dịch",
                value="Anh -> Việt",
            )
            use_kg = gr.Checkbox(
                label="Dùng Knowledge Graph để bảo vệ & chuẩn hóa thực thể",
                value=True,
            )
            btn = gr.Button("🔄 Dịch ngay", variant="primary")

        with gr.Column():
            output_text = gr.Textbox(
                lines=7,
                label="Kết quả dịch",
                interactive=False,
            )
            gr.Markdown(
                "**Cách hoạt động khi bật KG:**\n"
                "1. Tên riêng được *ẩn* trước khi gửi vào model\n"
                "2. Model dịch phần còn lại\n"
                "3. Tên riêng được *khôi phục* đúng dạng chuẩn\n\n"
                "→ Tránh lỗi phiên âm sai như `Lê Hoàng Sơn` → `Li Wongshan`"
            )

    with gr.Accordion("⚙️ Quản lý cache (admin)", open=False):
        refresh_btn = gr.Button("🗑️ Xóa entity cache (reload từ Supabase)")
        cache_status = gr.Textbox(label="Trạng thái", interactive=False)

        def do_refresh():
            invalidate_cache()
            return "✅ Cache đã xóa. Entity sẽ được reload ở request tiếp theo."

        refresh_btn.click(fn=do_refresh, outputs=cache_status)

    btn.click(
        fn=translate_logic,
        inputs=[input_text, mode, use_kg],
        outputs=output_text,
    )

if __name__ == "__main__":
    demo.launch()