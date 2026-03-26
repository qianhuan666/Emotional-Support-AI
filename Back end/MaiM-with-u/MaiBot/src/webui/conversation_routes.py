"""会话管理路由：支持历史会话恢复。"""

import json
import time
import uuid
from pathlib import Path
from typing import Optional, List, Dict, Any

from fastapi import APIRouter, Depends, Cookie, Header, HTTPException
from pydantic import BaseModel, Field

from src.common.logger import get_logger
from src.common.database.database_model import Messages
from src.webui.auth import verify_auth_token_from_cookie_or_header

logger = get_logger("webui.conversations")

router = APIRouter(prefix="/api/conversations", tags=["Conversations"])

DATA_FILE = Path(__file__).parent.parent.parent / "data" / "webui_conversations.json"


def require_auth(
    maibot_session: Optional[str] = Cookie(None),
    authorization: Optional[str] = Header(None),
) -> bool:
    return verify_auth_token_from_cookie_or_header(maibot_session, authorization)


class ConversationCreateRequest(BaseModel):
    user_id: str = Field(..., description="用户ID")
    title: Optional[str] = Field(default=None, description="会话标题")


def _load_conversations() -> List[Dict[str, Any]]:
    if not DATA_FILE.exists():
        return []
    try:
        return json.loads(DATA_FILE.read_text(encoding="utf-8"))
    except Exception:
        return []


def _save_conversations(items: List[Dict[str, Any]]) -> None:
    DATA_FILE.parent.mkdir(parents=True, exist_ok=True)
    DATA_FILE.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding="utf-8")


def _latest_message_preview(conversation_id: str) -> Optional[str]:
    msg = (
        Messages.select(Messages.processed_plain_text, Messages.display_message, Messages.time)
        .where(Messages.chat_info_group_id == conversation_id)
        .order_by(Messages.time.desc())
        .first()
    )
    if not msg:
        return None
    return (msg.processed_plain_text or msg.display_message or "")[:120]


@router.post("")
async def create_conversation(request: ConversationCreateRequest, _auth: bool = Depends(require_auth)):
    conv_id = f"webui_conv_{uuid.uuid4().hex[:12]}"
    now = time.time()
    item = {
        "id": conv_id,
        "user_id": request.user_id,
        "title": request.title or "新会话",
        "created_at": now,
        "updated_at": now,
        "archived": False,
    }
    items = _load_conversations()
    items.append(item)
    _save_conversations(items)
    return {"success": True, "conversation": item}


@router.get("")
async def list_conversations(user_id: str, _auth: bool = Depends(require_auth)):
    items = [x for x in _load_conversations() if x.get("user_id") == user_id and not x.get("archived")]
    for item in items:
        item["last_message_preview"] = _latest_message_preview(item["id"])
    items.sort(key=lambda x: x.get("updated_at", 0), reverse=True)
    return {"success": True, "conversations": items}


@router.get("/{conversation_id}")
async def get_conversation_detail(conversation_id: str, _auth: bool = Depends(require_auth)):
    items = _load_conversations()
    target = next((x for x in items if x.get("id") == conversation_id), None)
    if not target:
        raise HTTPException(status_code=404, detail="会话不存在")

    messages = (
        Messages.select(
            Messages.message_id,
            Messages.time,
            Messages.user_id,
            Messages.user_nickname,
            Messages.processed_plain_text,
            Messages.display_message,
        )
        .where(Messages.chat_info_group_id == conversation_id)
        .order_by(Messages.time.asc())
        .limit(200)
    )
    data = []
    for m in messages:
        data.append(
            {
                "id": m.message_id,
                "timestamp": m.time,
                "sender_id": m.user_id,
                "sender_name": m.user_nickname,
                "content": m.processed_plain_text or m.display_message or "",
            }
        )
    return {"success": True, "conversation": target, "messages": data}


@router.delete("/{conversation_id}")
async def archive_conversation(conversation_id: str, _auth: bool = Depends(require_auth)):
    items = _load_conversations()
    changed = False
    for item in items:
        if item.get("id") == conversation_id:
            item["archived"] = True
            item["updated_at"] = time.time()
            changed = True
            break
    if not changed:
        raise HTTPException(status_code=404, detail="会话不存在")
    _save_conversations(items)
    return {"success": True, "message": "会话已归档"}
