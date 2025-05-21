from flask import Flask, render_template # type: ignore
from prometheus_flask_exporter import PrometheusMetrics # type: ignore

app = Flask(__name__)
metrics = PrometheusMetrics(app, group_by='endpoint')

@app.route("/")
def index():
    return render_template("index.html")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)