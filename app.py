from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent
HTML_FILE = BASE_DIR / "preview.html"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        html = HTML_FILE.read_text(encoding="utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(html.encode("utf-8"))

    def log_message(self, format: str, *args) -> None:
        return


def main() -> None:
    if not HTML_FILE.exists():
      raise FileNotFoundError(f"Missing HTML file: {HTML_FILE}")

    try:
        server = HTTPServer(("127.0.0.1", 8000), Handler)
    except PermissionError:
        print(f"HTTP server could not start. Open this file instead: {HTML_FILE}")
        return

    print("Preview: http://127.0.0.1:8000")
    server.serve_forever()


if __name__ == "__main__":
    main()
