from contextvars import ContextVar
# 创建一个上下文变量，默认值为 None
current_task_id: ContextVar[str | None] = ContextVar("current_task_id", default=None)
