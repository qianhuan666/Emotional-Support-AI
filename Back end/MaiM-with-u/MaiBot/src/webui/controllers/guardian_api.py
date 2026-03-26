from typing import Optional

from fastapi import APIRouter, HTTPException, Query

try:
    from plugins.guardian_plugin.models import MicroTraces, UserCompass, initialize_guardian_tables
except ImportError:
    from src.plugins.guardian_plugin.models import MicroTraces, UserCompass, initialize_guardian_tables

router = APIRouter(prefix="/api/guardian", tags=["guardian"])


@router.get("/stats")
async def get_guardian_stats(user_id: Optional[str] = Query(default=None, description="可选：指定用户ID")):
    """返回用户最新心理罗盘和最近 5 条微小痕迹。"""
    try:
        initialize_guardian_tables()

        target_user_id = user_id
        latest_compass = None

        if target_user_id:
            latest_compass = (
                UserCompass.select()
                .where(UserCompass.user_id == target_user_id)
                .order_by(UserCompass.id.desc())
                .first()
            )
        else:
            latest_compass = UserCompass.select().order_by(UserCompass.id.desc()).first()
            if latest_compass:
                target_user_id = latest_compass.user_id

        traces_items = []
        if target_user_id:
            traces_query = (
                MicroTraces.select(
                    MicroTraces.id,
                    MicroTraces.user_id,
                    MicroTraces.text_length,
                    MicroTraces.input_latency,
                    MicroTraces.mood_score,
                    MicroTraces.detected_words,
                    MicroTraces.intervention_action,
                    MicroTraces.recorded_at,
                )
                .where(MicroTraces.user_id == target_user_id)
                .order_by(MicroTraces.recorded_at.desc(), MicroTraces.id.desc())
                .limit(5)
            )
            traces_items = list(traces_query.dicts())
            traces_items.reverse()

        compass_data = None
        if latest_compass:
            compass_data = {
                "user_id": latest_compass.user_id,
                "vitality": latest_compass.vitality,
                "stability": latest_compass.stability,
                "rumination": latest_compass.rumination,
            }

        return {
            "success": True,
            "data": {
                "user_id": target_user_id,
                "user_compass": compass_data,
                "micro_traces": traces_items,
                "guardian_logs": [
                    {
                        "time": item.get("recorded_at"),
                        "action": item.get("intervention_action") or "observe",
                        "words": item.get("detected_words"),
                    }
                    for item in traces_items
                ],
            },
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取 guardian stats 失败: {e}") from e
