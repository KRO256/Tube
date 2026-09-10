import json, os, sys, urllib.parse
from http.server import BaseHTTPRequestHandler, HTTPServer
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "vendor", "yt-dlp"))
from yt_dlp import YoutubeDL
from yt_dlp.version import __version__
class H(BaseHTTPRequestHandler):
    def send_json(self, o):
        b = json.dumps(o).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)
    def do_GET(self):
        u = urllib.parse.urlparse(self.path)
        q = urllib.parse.parse_qs(u.query)
        if u.path == "/api/version":
            self.send_json({"version": __version__})
            return
        if u.path == "/api/search":
            term = q.get("q", [""])[0]
            n = int(q.get("n", ["10"])[0] or 10)
            with YoutubeDL({"quiet": True, "no_warnings": True, "extract_flat": True}) as y:
                info = y.extract_info("ytsearch%d:%s" % (n, term), download=False)
            out = []
            for e in (info.get("entries") or [])[:n]:
                out.append({"id": e.get("id"), "title": e.get("title"), "uploader": e.get("uploader"), "duration": e.get("duration"), "url": e.get("url")})
            self.send_json({"results": out})
            return
        if u.path == "/api/url":
            vid = q.get("id", [""])[0]
            audio = q.get("audio", ["0"])[0] == "1"
            fmt = "bestaudio[ext=m4a]/bestaudio/best" if audio else "best[ext=mp4]/best/best"
            with YoutubeDL({"quiet": True, "no_warnings": True, "format": fmt}) as y:
                info = y.extract_info("https://www.youtube.com/watch?v=%s" % vid, download=False)
            url = info.get("url") or ""
            if not url and info.get("requested_formats"):
                url = info["requested_formats"][0].get("url", "")
            self.send_json({"url": url})
            return
        self.send_response(404); self.end_headers()
    def log_message(self, *a):
        pass
if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    HTTPServer(("0.0.0.0", port), H).serve_forever()
