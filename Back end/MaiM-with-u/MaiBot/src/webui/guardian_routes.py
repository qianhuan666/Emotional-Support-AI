from typing import Optional

from fastapi import APIRouter, HTTPException, Query

from src.common.logger import get_logger
try:
    from plugins.guardian_plugin.models import MicroTraces, UserCompass, initialize_guardian_tables
except ImportError:
    from src.plugins.guardian_plugin.models import MicroTraces, UserCompass, initialize_guardian_tables

logger = get_logger("guardian_routes")

router = APIRouter(tags=["guardian"])


@router.get("/status")
async def get_guardian_status(user_id: Optional[str] = Query(default=None, description="可选：按用户ID筛选")):
    """获取最近 10 条情绪评分，便于观察波动。"""
    try:
        query = MicroTraces.select(
            MicroTraces.id,
            MicroTraces.user_id,
            MicroTraces.text_length,
            MicroTraces.input_latency,
            MicroTraces.mood_score,
        )
        if user_id:
            query = query.where(MicroTraces.user_id == user_id)

        rows = query.order_by(MicroTraces.id.desc()).limit(10)
        items = list(rows.dicts())
        items.reverse()  # 按时间从旧到新，前端更容易看趋势

        mood_scores = [item.get("mood_score") for item in items]
        return {
            "count": len(items),
            "user_id": user_id,
            "mood_scores": mood_scores,
            "items": items,
        }
    except Exception as e:
        logger.error(f"获取 guardian 状态失败: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="获取 guardian 状态失败") from e


@router.get("/stats")
async def get_guardian_stats(user_id: Optional[str] = Query(default=None, description="可选：指定用户ID")):
    """返回最新 UserCompass + 最近 5 条 MicroTraces。"""
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

        traces_query = MicroTraces.select(
            MicroTraces.id,
            MicroTraces.user_id,
            MicroTraces.text_length,
            MicroTraces.input_latency,
            MicroTraces.mood_score,
            MicroTraces.detected_words,
            MicroTraces.intervention_action,
            MicroTraces.recorded_at,
        )
        if target_user_id:
            traces_query = traces_query.where(MicroTraces.user_id == target_user_id)

        traces_items = list(traces_query.order_by(MicroTraces.recorded_at.desc(), MicroTraces.id.desc()).limit(5).dicts())
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
            },
        }
    except Exception as e:
        logger.error(f"获取 guardian stats 失败: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="获取 guardian stats 失败") from e
