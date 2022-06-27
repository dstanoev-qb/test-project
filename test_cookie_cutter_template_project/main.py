import functions_framework
import logger_setup  # noqa: F401, I900
import structlog

LOG = structlog.getLogger()


@functions_framework.http
def func1(request):
    return 'Working!'
