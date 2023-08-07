import datetime
import pprint

import fastapi
import fastapi.openapi.models
import fastapi.responses as fa_resp
import fastapi.staticfiles

import app.route


async def debug_print(request: fastapi.Request, do_print: bool = False) -> dict:
    if do_print:
        print(f"{'=' * 20} [{request.method}] {request.url} {'=' * 20}")
        pprint.pprint(
            object={
                "request_time": datetime.datetime.now().isoformat(),
                "client": request.client,
                "base_url": request.base_url,
                "query_params": request.query_params,
                "headers": dict(request.headers.items()),
                "cookies": request.cookies,
                "body": await request.body(),
                # "state": request.state,
                # "scope": request.scope,
            },
            sort_dicts=False,
            width=120,
        )
    return {
        "client": request.client,
        "method": request.method,
        "url": str(request.url),
        "base_url": str(request.base_url),
        "query_params": dict(request.query_params),
        "headers": dict(request.headers),
        "cookies": request.cookies,
    }


async def on_app_startup() -> None:
    pass
    # await db_module.init_db()
    # await redis_module.init_redis()


async def on_app_shutdown() -> None:
    pass
    # await db_module.close_db_connection()
    # await redis_module.close_redis_connection()


async def handle_exc(request: fastapi.Request, exc: fastapi.exceptions.HTTPException) -> fa_resp.JSONResponse:
    print(exc)
    await debug_print(request, False)
    return fa_resp.JSONResponse(
        content={
            "detail": "Not Found",
            "status_code": 404,
        },
        status_code=404,
    )


async def auth(request: fastapi.Request):
    return fa_resp.JSONResponse(
        content=await debug_print(request, True),
        status_code=200,
        headers={
            "X-Auth-User": "test",
            "X-Auth-Groups": "test",
        },
    )


async def index(request: fastapi.Request):
    return fa_resp.JSONResponse(
        content=await debug_print(request),
        status_code=200,
        headers={
            "X-Auth-User": "test",
            "X-Auth-Groups": "test",
        },
    )


async def signin(request: fastapi.Request):
    return fa_resp.JSONResponse(
        content=await debug_print(request),
        status_code=200,
        headers={
            "X-Auth-User": "test",
            "X-Auth-Groups": "test",
        },
    )


def create_app(*args, **kwargs) -> fastapi.FastAPI:
    print(f"{args=}")
    print(f"{kwargs=}")
    fastapi_app = fastapi.FastAPI(
        *args,
        # servers=[
        #     dict(
        #         fastapi.openapi.models.Server(
        #                 url="http://localhost:8080",
        #                 description="Local Server",
        #         )
        #     ),
        # ],
        # description=(
        #     "AuthCo, "
        #     "An authentication & authorization service "
        #     "for nginx auth_request and other micro-services."
        # ),
        # contact=dict(
        #     fastapi.openapi.models.Contact(
        #         name="MUsoftware",
        #         url="https://mudev.cc",
        #         email="musoftware@mudev.cc",
        #     )
        # ),
        # openapi_tags=[
        #     fastapi.openapi.models.Tag(name="qwe", description="qwe"),
        # ],
        redirect_slashes=False,
        **kwargs,
    )
    fastapi_app.on_event("startup")(on_app_startup)
    fastapi_app.on_event("shutdown")(on_app_shutdown)

    fastapi_app.add_exception_handler(404, handle_exc)
    fastapi_app.add_exception_handler(fastapi.exceptions.HTTPException, handle_exc)

    fastapi_app.mount("/static", fastapi.staticfiles.StaticFiles(directory="app/static"), name="static")
    # app.route.register_route(fastapi_app)
    fastapi_app.get("/dev/", description="index route", tags=["qwe"])(index)
    fastapi_app.get("/dev/ping/", description="index route", tags=["qwe"])(index)
    fastapi_app.get("/dev/auth/", description="auth route", tags=["qwe"])(auth)
    fastapi_app.post("/dev/signin/", description="signin route", tags=["qwe"])(signin)

    return fastapi_app


if __name__ == "__main__":
    import typer

    import app.cli

    cli_app: typer.Typer = typer.Typer()
    app.cli.register_cli(cli_app)
    cli_app()
