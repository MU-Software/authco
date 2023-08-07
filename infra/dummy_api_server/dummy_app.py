import pprint

import fastapi
import fastapi.responses as fa_resp


async def handle_404(request: fastapi.Request, exc: fastapi.exceptions.HTTPException) -> fa_resp.JSONResponse:
    print(f"{'=' * 20} [{request.method}] {request.url} {'=' * 20}")
    pprint.pprint(
        object={
            "client": request.client,
            "base_url": request.base_url,
            "query_params": request.query_params,
            "headers": dict(request.headers.items()),
            "cookies": request.cookies,
            "body": await request.body(),
            "state": request.state,
            "scope": request.scope,
        },
        sort_dicts=False,
        width=120,
    )
    return fa_resp.JSONResponse(
        content={
            "client": request.client,
            "method": request.method,
            "url": str(request.url),
            "base_url": str(request.base_url),
            "query_params": dict(request.query_params),
            "headers": dict(request.headers),
            "cookies": request.cookies,
            "body": (await request.body()).decode(errors="ignore"),
        },
        status_code=200,
    )


def create_dummy_app(*args, **kwargs) -> fastapi.FastAPI:
    fastapi_app = fastapi.FastAPI(redirect_slashes=False)
    fastapi_app.add_exception_handler(404, handle_404)
    return fastapi_app
